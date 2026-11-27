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
            const SizedBox(height: 16),
            for (final section in _sections)
              Card(
                child: ListTile(
                  leading: Icon(section.icon),
                  title: Text(section.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => _DemoSectionPage(section: section),
                    ),
                  ),
                ),
              ),
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

class _DemoSection {
  const _DemoSection(this.title, this.icon, this.entries);

  final String title;
  final IconData icon;
  final Map<String, String> entries;
}

const _sections = [
  _DemoSection('Sensores de glucosa', Icons.sensors, {
    'FreeStyle Libre 2': 'Ejemplo de historial importado: 112, 118 y 126 mg/dL.',
    'FreeStyle Libre 3': 'Ejemplo de lectura del sensor: 126 mg/dL.',
    'Dexcom ONE+': 'Ejemplo de lectura del sensor: 118 mg/dL.',
    'Dexcom G7': 'Ejemplo de curva: 102, 110 y 115 mg/dL.',
    'Otros modelos': 'La conexión real se valida por modelo.',
  }),
  _DemoSection('Plumas e insulina', Icons.vaccines_outlined, {
    'NovoPen Echo Plus': 'Ejemplo de un registro importado con hora y tipo de insulina.',
    'Otras marcas': 'Aquí se mostraría la compatibilidad por modelo. Puedes explorar el ejemplo de registro manual.',
    'Insulina rápida': 'Ejemplo de historial: comida · 14:15.',
    'Insulina basal': 'Ejemplo de historial: noche · 22:00.',
  }),
  _DemoSection('Tendencias e informes', Icons.show_chart, {
    'Tiempo en rango': 'Informe ficticio de 14 días: 78 % en rango, 20 % por encima y 2 % por debajo.',
    'Perfil AGP': 'Ejemplo de lectura del informe: el tramo de mayor variación aparece por la tarde.',
    'GMI': 'En un informe del sensor se mostraría como un indicador calculado a partir de la glucosa media.',
    'HbA1c de laboratorio': 'Ejemplo de seguimiento: 7,4 % en junio y 7,1 % en septiembre.',
  }),
  _DemoSection('Entrenamiento', Icons.fitness_center, {
    'Perder grasa': 'Ejemplo de semana: lunes caminata, miércoles fuerza general y viernes bicicleta.',
    'Ganar volumen': 'Ejemplo de semana: lunes tren superior, miércoles tren inferior y viernes cuerpo completo.',
    'Definición': 'Ejemplo de semana: lunes fuerza, miércoles actividad aeróbica y viernes fuerza.',
    'Mejorar resistencia': 'Ejemplo de semana: lunes bicicleta, miércoles caminata y sábado sesión aeróbica.',
    'Glucosa y actividad': 'Sesión ficticia: antes 135, durante 123 y después 117 mg/dL.',
  }),
  _DemoSection('Comidas y carbohidratos', Icons.restaurant, {
    'Diario de comidas': 'Ejemplo guardado: yogur natural y manzana · 08:30.',
    'Estimar por foto': 'Resultado simulado: se detectan arroz, pollo y verduras. La porción se revisaría antes de guardar.',
    'Glucosa después de comer': 'Ejemplo ficticio: 108 mg/dL antes y 145 mg/dL dos horas después.',
  }),
  _DemoSection('AI Guardian', Icons.shield_outlined, {
    'Patrón de glucosa': 'Análisis simulado: en tres días del ejemplo la glucosa subió después de la merienda.',
    'Pregunta de ejemplo': '«¿Qué cambió esta semana?» En el ejemplo, la mediana de la tarde bajó respecto a la semana anterior.',
    'Calculadora de insulina': 'Deshabilitada para esta demo.',
  }),
  _DemoSection('Alertas y emergencias', Icons.health_and_safety_outlined, {
    'Alertas de glucosa': 'Bandeja ficticia de avisos por glucosa baja, alta o pérdida de señal.',
    'Ficha médica QR': 'Vista de ejemplo: persona de prueba, contacto de emergencia ficticio y tipo de diabetes.',
    'SOS': 'Vista previa del flujo. La demo no llama ni envía mensajes.',
  }),
  _DemoSection('Perfil y sincronización', Icons.manage_accounts_outlined, {
    'Perfil': 'Ejemplos de perfiles: tipo 1, tipo 2, gestacional, prediabetes y deportista.',
    'Sincronización': 'Vista de ejemplo para revisar datos guardados y su estado de sincronización.',
  }),
];

class _DemoSectionPage extends StatelessWidget {
  const _DemoSectionPage({required this.section});

  final _DemoSection section;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(section.title)),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Demostración con datos ficticios'),
            const SizedBox(height: 12),
            for (final entry in section.entries.entries)
              Card(
                child: ExpansionTile(
                  title: Text(entry.key),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(entry.value),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
