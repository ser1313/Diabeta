import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'insights.dart';
import 'settings.dart';

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
    const secure = FlutterSecureStorage();
    final token = await secure.read(key: 'token');
    if (token == null) {
      final legacy = await SharedPreferences.getInstance();
      final oldToken = legacy.getString('token');
      if (oldToken != null) {
        await secure.write(key: 'token', value: oldToken);
        await legacy.remove('token');
      }
    }
    final migratedToken = await secure.read(key: 'token');
    if (mounted) setState(() => ready = migratedToken != null);
  }
  void loggedIn() { setState(() => ready = true); }
  Future<void> logout() async {
    const secure = FlutterSecureStorage();
    await secure.delete(key: 'token');
    if (mounted) setState(() => ready = false);
  }
  @override Widget build(BuildContext c) =>
      ready ? Dashboard(onLogout: logout) : Login(onLogin: loggedIn);
}

class Login extends StatefulWidget {
  final VoidCallback onLogin;
  const Login({super.key, required this.onLogin});
  @override State<Login> createState() => _LoginState();
}
class _LoginState extends State<Login> {
  final email = TextEditingController();
  final pass = TextEditingController();
  final firstName = TextEditingController();
  final api = ApiClient();
  String error = '';
  bool register = false;

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    firstName.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    try {
      final r = await api.post(
        register ? '/auth/register' : '/auth/login',
        {'email': email.text.trim(), 'password': pass.text, 'firstName': firstName.text.trim().isEmpty ? 'Usuario' : firstName.text.trim()},
      );
      const secure = FlutterSecureStorage();
      await secure.write(key: 'token', value: r['accessToken'].toString());
      widget.onLogin();
    } catch (_) {
      if (mounted) setState(() => error = 'No se pudo iniciar sesión. Comprueba los datos.');
    }
  }

  @override Widget build(BuildContext c) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.monitor_heart, size: 72),
            Text('Diabeta', style: Theme.of(c).textTheme.headlineMedium),
            Text(register ? 'Crear cuenta' : 'Iniciar sesión'),
            if (register) TextField(controller: firstName, decoration: const InputDecoration(labelText: 'Nombre')),
            TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: pass, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
            if (error.isNotEmpty) Text(error),
            FilledButton(onPressed: submit, child: Text(register ? 'Crear cuenta' : 'Entrar')),
            TextButton(
              onPressed: () => setState(() => register = !register),
              child: Text(register ? 'Ya tengo cuenta' : 'Crear una cuenta'),
            ),
          ],
        ),
      ),
    ),
  );
}

class Dashboard extends StatefulWidget {
  final Future<void> Function() onLogout;
  const Dashboard({super.key, required this.onLogout});
  @override State<Dashboard> createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard> {
  final api = ApiClient();
  List<dynamic> glucose = [];
  List<dynamic> insulin = [];
  String status = 'Cargando...';

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final g = await api.getList('/glucose');
      final i = await api.getList('/insulin');
      if (mounted) {
        setState(() { glucose = g; insulin = i; status = 'Datos sincronizados'; });
      }
    } catch (_) {
      if (mounted) setState(() => status = 'No se han podido cargar los datos.');
    }
  }

  Future<void> _recordGlucose() async {
    final x = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Glucosa'),
        content: TextField(
          controller: x,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'mg/dL'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final v = double.tryParse(x.text);
              if (v != null) {
                await api.post('/glucose', {
                  'value': v,
                  'recordedAt': DateTime.now().toUtc().toIso8601String(),
                });
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    await load();
  }

  Future<void> _recordInsulin() async {
    final x = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Insulina rápida'),
        content: TextField(
          controller: x,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'unidades'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final v = double.tryParse(x.text);
              if (v != null) {
                await api.post('/insulin', {
                  'units': v,
                  'insulinType': 'rapid',
                  'recordedAt': DateTime.now().toUtc().toIso8601String(),
                });
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
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
    final recent = <Map<String, String>>[
      for (final item in glucose.take(5))
        {
          'kind': 'Glucosa',
          'value': '${item['value'] ?? '--'} mg/dL',
          'recordedAt': item['recordedAt']?.toString() ?? '',
        },
      for (final item in insulin.take(5))
        {
          'kind': 'Insulina',
          'value': '${item['units'] ?? '--'} U · ${item['insulinType'] ?? 'tipo no indicado'}',
          'recordedAt': item['recordedAt']?.toString() ?? '',
        },
    ]..sort((a, b) {
        final dateA = DateTime.tryParse(a['recordedAt'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['recordedAt'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return dateB.compareTo(dateA);
      });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diabeta'),
        actions: [IconButton(onPressed: widget.onLogout, icon: const Icon(Icons.logout))],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Glucosa actual'),
            Text('$latest mg/dL', style: Theme.of(c).textTheme.displaySmall),
            Text(status),
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
