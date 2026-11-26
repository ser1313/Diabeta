import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WebDemo extends StatefulWidget {
  const WebDemo({super.key});

  @override
  State<WebDemo> createState() => _WebDemoState();
}

class _WebDemoState extends State<WebDemo> {
  static const _key = 'diabeta.demo.glucose.v1';
  final _storage = SharedPreferencesAsync();
  final _value = TextEditingController();
  List<String> _entries = const [];
  bool _ready = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await _storage.getStringList(_key);
      if (mounted) {
        setState(() {
          _entries = entries ?? const ['Hoy, 08:30 · 112 mg/dL'];
          _ready = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'El navegador no permite guardar el historial.');
      }
    }
  }

  Future<void> _save() async {
    if (!_ready || _saving) return;
    final reading = int.tryParse(_value.text.trim());
    if (reading == null || reading <= 0) {
      setState(() => _error = 'Introduce un número entero positivo.');
      return;
    }
    final now = DateTime.now();
    final date = MaterialLocalizations.of(context).formatShortDate(now);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(now));
    final entries = ['$date $time · $reading mg/dL', ..._entries];
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _storage.setStringList(_key, entries);
      if (!mounted) return;
      _value.clear();
      setState(() => _entries = entries);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar el registro. Inténtalo de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Diabeta · Demo')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Usa solo valores ficticios. El historial se guarda en este navegador.'),
            const SizedBox(height: 20),
            TextField(
              controller: _value,
              enabled: _ready && !_saving,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Glucosa ficticia (mg/dL)',
                border: const OutlineInputBorder(),
                errorText: _error,
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _ready && !_saving ? _save : null,
              child: const Text('Guardar registro'),
            ),
            const SizedBox(height: 24),
            Text('Historial', style: Theme.of(context).textTheme.titleLarge),
            for (final entry in _entries) ListTile(title: Text(entry)),
          ],
        ),
      ),
    ),
  );
}
