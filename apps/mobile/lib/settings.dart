import 'package:flutter/material.dart';
import 'api_client.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final api = ApiClient();
  final name = TextEditingController();
  String language = 'es';
  bool alerts = true;
  double low = 70;
  double high = 180;
  List<dynamic> sensors = [];
  bool loading = true;
  String? message;

  @override void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        api.getMap('/profile'), api.getMap('/settings/alerts'), api.getList('/sensors'),
      ]);
      final p = results[0], s = results[1];
      name.text = p['firstName']?.toString() ?? '';
      if (mounted) setState(() {
        language = p['language']?.toString() ?? 'es';
        alerts = s['alertsEnabled'] != false;
        low = (s['lowThreshold'] ?? 70).toDouble();
        high = (s['highThreshold'] ?? 180).toDouble();
        sensors = results[2] as List<dynamic>;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() { loading = false; message = 'No se pudieron cargar los ajustes.'; });
    }
  }

  Future<void> save() async {
    try {
      await api.patch('/profile', {'firstName': name.text.trim(), 'language': language});
      await api.patch('/settings/alerts', {'alertsEnabled': alerts, 'lowThreshold': low, 'highThreshold': high});
      if (mounted) setState(() => message = 'Ajustes guardados.');
    } catch (_) {
      if (mounted) setState(() => message = 'No se pudieron guardar los ajustes.');
    }
  }

  Future<void> connect(String provider) async {
    try {
      await api.post('/sensors/connect', {'provider': provider});
      await load();
      if (mounted) setState(() => message = 'Conexión preparada. La sincronización real requiere credenciales/API autorizadas del proveedor.');
    } catch (_) {
      if (mounted) setState(() => message = 'No se pudo preparar la conexión.');
    }
  }

  @override void dispose() { name.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text('Perfil', style: Theme.of(context).textTheme.titleLarge),
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
        DropdownButtonFormField<String>(
          value: language,
          decoration: const InputDecoration(labelText: 'Idioma'),
          items: const [
            DropdownMenuItem(value: 'es', child: Text('Español')),
            DropdownMenuItem(value: 'en', child: Text('English')),
          ],
          onChanged: (v) => setState(() => language = v ?? 'es'),
        ),
        const SizedBox(height: 20),
        Text('Alertas Guardian', style: Theme.of(context).textTheme.titleLarge),
        SwitchListTile(title: const Text('Activar alertas'), value: alerts, onChanged: (v) => setState(() => alerts = v)),
        Text('Límite bajo: ' + low.round().toString() + ' mg/dL'),
        Slider(min: 40, max: 100, divisions: 60, value: low, onChanged: (v) => setState(() => low = v)),
        Text('Límite alto: ' + high.round().toString() + ' mg/dL'),
        Slider(min: 100, max: 300, divisions: 100, value: high, onChanged: (v) => setState(() => high = v)),
        const SizedBox(height: 12),
        Text('Sensores', style: Theme.of(context).textTheme.titleLarge),
        ListTile(
          title: const Text('FreeStyle Libre'),
          subtitle: Text(sensors.any((x) => x['provider'] == 'freestyle_libre') ? 'Conexión preparada' : 'No conectado'),
          trailing: FilledButton(onPressed: () => connect('freestyle_libre'), child: const Text('Conectar')),
        ),
        ListTile(
          title: const Text('Dexcom'),
          subtitle: Text(sensors.any((x) => x['provider'] == 'dexcom') ? 'Conexión preparada' : 'No conectado'),
          trailing: FilledButton(onPressed: () => connect('dexcom'), child: const Text('Conectar')),
        ),
        const SizedBox(height: 12),
        if (message != null) Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(message!)),
        FilledButton.icon(onPressed: save, icon: const Icon(Icons.save), label: const Text('Guardar ajustes')),
        const SizedBox(height: 16),
        const Text('Las conexiones de sensores son una capa de integración. La sincronización directa requiere APIs/SDK y credenciales autorizadas del fabricante.'),
      ]),
    );
  }
}
