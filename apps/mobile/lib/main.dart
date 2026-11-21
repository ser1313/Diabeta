import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'auth_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'insights.dart';
import 'dashboard_history.dart';
import 'offline_glucose_queue.dart';
import 'settings.dart';
import 'beta_config.dart';
import 'education/glucose_education_content.dart';
import 'education/glucose_education_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DiabetaApp());
}

class DiabetaApp extends StatelessWidget {
  const DiabetaApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Diabeta',
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
    home: const AuthGate(),
    builder: (context, child) => isBetaBuild
        ? Banner(message: 'BETA', location: BannerLocation.topEnd, color: Colors.deepOrange, child: child ?? const SizedBox.shrink())
        : child ?? const SizedBox.shrink(),
  );
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override State<AuthGate> createState() => _AuthGateState();
}
class _AuthGateState extends State<AuthGate> {
  bool ready = false;
  @override void initState() { super.initState(); _check(); }
  Future<void> _check() async {
    try {
      const secure = FlutterSecureStorage();
      var token = await secure.read(key: 'token');
      if (token == null || token.isEmpty) {
        final legacy = await SharedPreferences.getInstance();
        final oldToken = legacy.getString('token');
        if (oldToken != null && oldToken.isNotEmpty) {
          await secure.write(key: 'token', value: oldToken);
          await legacy.remove('token');
          token = oldToken;
        }
      }
      if (mounted) setState(() => ready = token?.isNotEmpty == true);
    } catch (error) {
      debugPrint('Diabeta: no se pudo recuperar la sesión (' + error.runtimeType.toString() + ').');
      if (mounted) setState(() => ready = false);
    }
  }
  void loggedIn() { setState(() => ready = true); }
  Future<void> logout() async {
    const secure = FlutterSecureStorage();
    await secure.delete(key: 'token');
    if (mounted) setState(() => ready = false);
  }

  Future<void> _authenticate({
    required String email,
    required String password,
    required bool register,
    String? firstName,
  }) async {
    final payload = <String, dynamic>{
      'email': email.trim().toLowerCase(),
      'password': password,
    };
    // El DTO de login rechaza cualquier campo adicional: firstName solo se
    // incluye en el endpoint de registro.
    if (register) payload['firstName'] = firstName?.trim() ?? '';

    final result = await ApiClient().post(
      register ? '/auth/register' : '/auth/login',
      payload,
    );
    final token = result['accessToken'];
    if (token is! String || token.trim().isEmpty) {
      throw const FormatException('La API no devolvió un token de sesión válido.');
    }
    const secure = FlutterSecureStorage();
    await secure.write(key: 'token', value: token);
  }

  @override Widget build(BuildContext c) =>
      ready ? Dashboard(onLogout: logout) : LoginScreen(onAuthenticate: _authenticate, onLogin: loggedIn);
}

class Dashboard extends StatefulWidget {
  final Future<void> Function() onLogout;
  const Dashboard({super.key, required this.onLogout});
  @override State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  final api = ApiClient();
  List<dynamic> glucose = [];
  List<dynamic> insulin = [];
  String status = 'Cargando...';

  int pendingGlucose = 0;
  int _refreshGeneration = 0;
  bool _signingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_signingOut) load();
  }

  String? _accountFromToken(String? token) {
    if (token == null) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
      if (payload is Map && payload['sub'] is String && (payload['sub'] as String).isNotEmpty) {
        return jsonEncode([api.baseUrl, payload['sub']]);
      }
    } on FormatException {
      return null;
    }
    return null;
  }

  Future<void> load() async {
    final generation = ++_refreshGeneration;
    var remaining = pendingGlucose;
    try {
      final token = await api.token();
      final account = _accountFromToken(token);
      if (token == null || account == null || !mounted || _signingOut) return;
      final queue = OfflineGlucoseQueue.forAccount(account);
      remaining = (await queue.pending()).length;
      if (mounted && !_signingOut && generation == _refreshGeneration) {
        setState(() => pendingGlucose = remaining);
      }
      if (remaining > 0) {
        final sync = await queue.drain(
          (reading) async {
            if (!mounted || _signingOut || await api.token() != token) {
              throw StateError('La sesión ha cambiado.');
            }
            if (!mounted || _signingOut) throw StateError('La sesión ha cambiado.');
            await api.post('/glucose', reading.toPayload(), sessionToken: token);
          },
          shouldContinue: () => mounted && !_signingOut && generation == _refreshGeneration,
          shouldPause: (error) =>
              error is TimeoutException ||
              error is http.ClientException ||
              error is StateError ||
              (error is ApiException &&
                  (error.statusCode == 401 ||
                      error.statusCode == 408 ||
                      error.statusCode == 429 ||
                      error.statusCode >= 500)),
        );
        remaining = sync.remaining;
      }
      if (!mounted || _signingOut || await api.token() != token) return;
      final data = await Future.wait([
        api.getList('/glucose', sessionToken: token),
        api.getList('/insulin', sessionToken: token),
      ]);
      if (mounted && !_signingOut && generation == _refreshGeneration) {
        setState(() {
          glucose = data[0];
          insulin = data[1];
          pendingGlucose = remaining;
          status = remaining == 0 ? 'Datos sincronizados' : 'Datos actualizados';
        });
      }
    } catch (_) {
      if (mounted && !_signingOut && generation == _refreshGeneration) {
        setState(() {
          pendingGlucose = remaining;
          status = 'No se han podido actualizar los datos.';
        });
      }
    }
  }

  Future<void> _logout() async {
    if (_signingOut) return;
    setState(() => _signingOut = true);
    try {
      await widget.onLogout();
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cerrar la sesión.')),
      );
    }
  }

  Future<void> _recordGlucose() async {
    var input = '';
    var saving = false;
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => PopScope(
          canPop: !saving,
          child: AlertDialog(
            title: const Text('Registrar glucosa'),
            content: TextField(
              onChanged: (value) => input = value,
              enabled: !saving,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'mg/dL'),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: saving ? null : () async {
                  final value = double.tryParse(input.trim().replaceAll(',', '.'));
                  if (value == null || !isValidGlucoseEntry(value)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Introduce una lectura válida entre 20 y 1000 mg/dL.')),
                    );
                    return;
                  }
                  setDialogState(() => saving = true);
                  try {
                    final account = _accountFromToken(await api.token());
                    if (!mounted || _signingOut || account == null) {
                      throw StateError('No hay una sesión disponible.');
                    }
                    await OfflineGlucoseQueue.forAccount(account).enqueue(value, DateTime.now().toUtc());
                    if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                  } catch (_) {
                    if (dialogContext.mounted) setDialogState(() => saving = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No se pudo guardar la lectura en el dispositivo.')),
                      );
                    }
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true && mounted) await load();
  }

  Future<void> _recordInsulin() async {
    final x = TextEditingController();
    String insulinType = 'rapid';
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Registrar insulina'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: x,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'unidades'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: insulinType,
                decoration: const InputDecoration(labelText: 'Tipo de insulina'),
                items: const [
                  DropdownMenuItem(value: 'rapid', child: Text('Rápida')),
                  DropdownMenuItem(value: 'basal', child: Text('Basal / lenta')),
                  DropdownMenuItem(value: 'mixed', child: Text('Mezcla')),
                  DropdownMenuItem(value: 'other', child: Text('Otra')),
                ],
                onChanged: (value) =>
                    setDialogState(() => insulinType = value ?? 'rapid'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                final v = double.tryParse(x.text.replaceAll(',', '.'));
                if (!isValidInsulinEntry(v)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Introduce una cantidad válida entre 0 y 200 unidades.'),
                    ),
                  );
                  return;
                }
                try {
                  await api.post('/insulin', {
                    'units': v,
                    'insulinType': insulinType,
                    'recordedAt': DateTime.now().toUtc().toIso8601String(),
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No se pudo guardar el registro de insulina.')),
                    );
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    x.dispose();
    await load();
  }

  Future<void> _medical() async {
    try {
      final m = await api.getMap('/medical');
      if (!mounted) return;
      final token = m['qrToken']?.toString() ?? '';
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Tarjeta médica'),
          content: SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(data: '${api.baseUrl}/medical/card/$token', size: 200),
                const Text('QR de acceso a la tarjeta médica pública. En producción debe utilizar HTTPS y una URL accesible.'),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
          ],
        ),
      );
    } catch (_) {
      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Tarjeta médica'),
            content: Text('Primero completa tu perfil médico.'),
          ),
        );
      }
    }
  }

  Future<void> _sos() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('SOS'),
        content: const Text(
          'Si existe una emergencia, llama a los servicios de emergencia. '
          'La app no realiza una alerta automática.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cerrar')),
          FilledButton.icon(
            onPressed: () async {
              await launchUrl(Uri(scheme: 'tel', path: '112'));
            },
            icon: const Icon(Icons.phone),
            label: const Text('Llamar 112'),
          ),
        ],
      ),
    );
  }

  String _formatRecordedAt(dynamic raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '');
    if (parsed == null) return 'Fecha desconocida';
    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month · $hour:$minute';
  }

  @override Widget build(BuildContext c) {
    final latest = glucose.isEmpty ? '--' : glucose.first['value'].toString();
    final recent = buildRecentHistory(glucose, insulin);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diabeta'),
        actions: [IconButton(onPressed: _signingOut ? null : _logout, icon: const Icon(Icons.logout))],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Glucosa actual'),
            Text('$latest mg/dL', style: Theme.of(c).textTheme.displaySmall),
            Text(status),
            if (pendingGlucose > 0)
              Text('Lecturas de glucosa pendientes de sincronizar: $pendingGlucose'),
            const SizedBox(height: 12),
            Text('Últimos registros', style: Theme.of(c).textTheme.titleMedium),
            if (recent.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Todavía no hay registros'),
                  subtitle: Text('Los datos aparecerán aquí cuando registres glucosa o insulina.'),
                ),
              )
            else
              ...recent.take(5).map(
                (entry) => Card(
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      entry['kind'] == 'Glucosa'
                          ? Icons.water_drop_outlined
                          : Icons.medication_outlined,
                    ),
                    title: Text('${entry['kind']} · ${entry['value']}'),
                    subtitle: Text(_formatRecordedAt(entry['recordedAt'])),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Card(child: ListTile(title: const Text('Registrar glucosa'), onTap: _recordGlucose)),
            Card(child: ListTile(title: const Text('Registrar insulina'), onTap: _recordInsulin)),
            Card(child: ListTile(title: const Text('Tarjeta médica QR'), onTap: _medical)),
            Card(child: ListTile(title: const Text('Indicadores + AI Guardian'), leading: const Icon(Icons.insights), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const InsightsPage())))),
            if (isEducationModuleVisible(glucoseMeterEducation))
              Card(child: ListTile(title: const Text('Aprende a usar tu glucómetro'), leading: const Icon(Icons.school_outlined), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const GlucoseEducationPage())))),
            if (clinicalCalculatorEnabled)
              Card(child: ListTile(title: const Text('Calculadora informativa'), leading: const Icon(Icons.calculate), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const InsulinCalculatorPage())))),
            Card(child: ListTile(title: const Text('Nutrición y actividad'), leading: const Icon(Icons.restaurant_menu), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const LifestylePage())))),
            Card(child: ListTile(title: const Text('Ajustes, alertas y sensores'), leading: const Icon(Icons.settings), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const SettingsPage())))),
            Card(child: ListTile(title: const Text('SOS'), onTap: _sos)),
            Text('${glucose.length} glucosa · ${insulin.length} insulina'),
          ],
        ),
      ),
    );
  }
}
