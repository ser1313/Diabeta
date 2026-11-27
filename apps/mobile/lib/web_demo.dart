import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
    if (await _saveReading(reading) && mounted) _value.clear();
  }

  Future<bool> _saveReading(int reading, {String? sensor}) async {
    if (!_ready || _saving) return false;
    final now = DateTime.now();
    final date = MaterialLocalizations.of(context).formatShortDate(now);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(now));
    final source = sensor == null ? '' : ' · $sensor (simulado)';
    final entries = ['$date $time$source · $reading mg/dL', ..._entries];
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _storage.setStringList(_key, entries);
      if (mounted) setState(() => _entries = entries);
      return true;
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo guardar el registro. Inténtalo de nuevo.');
      }
      return false;
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
                      builder: (_) => section.title == 'Entrenamiento'
                          ? const _TrainingDemo()
                          : _DemoSectionPage(
                              section: section,
                              glucoseEntries: _entries,
                              importSensor: (sensor, value) => _saveReading(value, sensor: sensor),
                            ),
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
  _DemoSection('Entrenamiento', Icons.fitness_center, {}),
  _DemoSection('Comidas y carbohidratos', Icons.restaurant, {
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
    'SOS': 'Vista previa del flujo. La demo no llama ni envía mensajes.',
  }),
  _DemoSection('Perfil y sincronización', Icons.manage_accounts_outlined, {
    'Sincronización': 'Vista de ejemplo para revisar datos guardados y su estado de sincronización.',
  }),
];

class _DemoSectionPage extends StatelessWidget {
  const _DemoSectionPage({
    required this.section,
    required this.glucoseEntries,
    required this.importSensor,
  });

  final Future<bool> Function(String, int) importSensor;

  static const _sensorExamples = {
    'FreeStyle Libre 2': 112,
    'FreeStyle Libre 3': 126,
    'Dexcom ONE+': 118,
    'Dexcom G7': 115,
  };

  final _DemoSection section;
  final List<String> glucoseEntries;

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
            if (section.title == 'Alertas y emergencias') ...[
              const _AlertDemo(),
              const _EmergencyQrDemo(),
            ],
            if (section.title == 'Perfil y sincronización') const _ProfileDemo(),
            if (section.title == 'AI Guardian')
              _GuardianDemo(entries: glucoseEntries),
            if (section.title == 'Tendencias e informes')
              _DemoGlucoseSummary(entries: glucoseEntries),
            if (section.title == 'Plumas e insulina') const _PenDemo(),
            if (section.title == 'Comidas y carbohidratos') const _MealDiary(),
            for (final entry in section.entries.entries)
              Card(
                child: ExpansionTile(
                  title: Text(entry.key),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.value),
                            if (section.title == 'Sensores de glucosa' &&
                                _sensorExamples.containsKey(entry.key))
                              TextButton(
                                onPressed: () async {
                                  final saved = await importSensor(
                                    entry.key,
                                    _sensorExamples[entry.key]!,
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(saved
                                        ? 'Lectura simulada guardada en el historial.'
                                        : 'No se pudo guardar la lectura.')),
                                  );
                                },
                                child: const Text('Importar lectura simulada'),
                              ),
                          ],
                        ),
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

class _TrainingDemo extends StatefulWidget {
  const _TrainingDemo();

  @override
  State<_TrainingDemo> createState() => _TrainingDemoState();
}

class _TrainingDemoState extends State<_TrainingDemo> {
  static const _key = 'diabeta.demo.training.v1';
  static const _goalKey = 'diabeta.demo.training.goal.v1';
  static const _plans = {
    'Perder grasa': ['Lunes · Caminata', 'Miércoles · Fuerza general', 'Viernes · Bicicleta'],
    'Ganar volumen': ['Lunes · Tren superior', 'Miércoles · Tren inferior', 'Viernes · Cuerpo completo'],
    'Definición': ['Lunes · Fuerza', 'Miércoles · Actividad aeróbica', 'Viernes · Fuerza'],
    'Resistencia': ['Lunes · Bicicleta', 'Miércoles · Caminata', 'Sábado · Sesión aeróbica'],
  };

  final _storage = SharedPreferencesAsync();
  Set<String> _done = {};
  String _goal = _plans.keys.first;
  bool _busy = true;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await _storage.getStringList(_key) ?? const <String>[];
      final goal = await _storage.getString(_goalKey);
      if (!mounted) return;
      setState(() {
        _done = saved.toSet();
        if (goal != null && _plans.containsKey(goal)) _goal = goal;
        _ready = true;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo recuperar el progreso.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _selectGoal(String? goal) async {
    if (goal == null || !_ready || _busy || goal == _goal) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _storage.setString(_goalKey, goal);
      if (mounted) setState(() => _goal = goal);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo guardar el objetivo.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(String session, bool checked) async {
    if (_busy || !_ready) return;
    final key = '$_goal/$session';
    final next = {..._done};
    if (checked) {
      next.add(key);
    } else {
      next.remove(key);
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _storage.setStringList(_key, next.toList());
      if (mounted) setState(() => _done = next);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo guardar el progreso.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessions = _plans[_goal]!;
    final completed = sessions.where((session) => _done.contains('$_goal/$session')).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamiento')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Planes de ejemplo. El progreso se guarda en este navegador.'),
          const SizedBox(height: 16),
          DropdownButton<String>(
            value: _goal,
            isExpanded: true,
            items: [
              for (final goal in _plans.keys)
                DropdownMenuItem(value: goal, child: Text(goal)),
            ],
            onChanged: _busy || !_ready ? null : _selectGoal,
          ),
          if (_ready) Text('$completed de ${sessions.length} sesiones completadas'),
          if (_error != null) Text(_error!),
          for (final session in sessions)
            CheckboxListTile(
              title: Text(session),
              value: _done.contains('$_goal/$session'),
              onChanged: _busy || !_ready ? null : (value) => _toggle(session, value ?? false),
            ),
          const ListTile(
            title: Text('Glucosa y actividad'),
            subtitle: Text('Ejemplo ficticio: antes 135, durante 123 y después 117 mg/dL.'),
          ),
        ],
      ),
    );
  }
}

class _MealDiary extends StatefulWidget {
  const _MealDiary();

  @override
  State<_MealDiary> createState() => _MealDiaryState();
}

class _MealDiaryState extends State<_MealDiary> {
  static const _key = 'diabeta.demo.meals.v1';
  final _storage = SharedPreferencesAsync();
  final _name = TextEditingController();
  final _carbs = TextEditingController();
  List<String>? _entries;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await _storage.getStringList(_key) ?? const <String>[];
      if (mounted) setState(() => _entries = entries);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo recuperar el diario.');
    }
  }

  Future<void> _save() async {
    final entries = _entries;
    if (_saving || entries == null) return;
    final name = _name.text.trim();
    final grams = double.tryParse(_carbs.text.trim().replaceAll(',', '.'));
    if (name.isEmpty || grams == null || !grams.isFinite || grams < 0) {
      setState(() => _error = 'Indica la comida y los gramos de carbohidratos.');
      return;
    }
    final now = DateTime.now();
    final local = MaterialLocalizations.of(context);
    final date = local.formatShortDate(now);
    final time = local.formatTimeOfDay(TimeOfDay.fromDateTime(now));
    final next = ['$date $time · $name · $grams g', ...entries];
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _storage.setStringList(_key, next);
      if (!mounted) return;
      _name.clear();
      _carbs.clear();
      setState(() => _entries = next);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo guardar la comida.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _carbs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _entries != null && !_saving;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Diario de comidas', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: _name,
          enabled: enabled,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'Comida ficticia'),
        ),
        TextField(
          controller: _carbs,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Carbohidratos (g)'),
        ),
        if (_error != null) Text(_error!),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: enabled ? _save : null,
          child: const Text('Guardar comida'),
        ),
        for (final entry in _entries ?? const <String>[])
          ListTile(title: Text(entry)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _DemoGlucoseSummary extends StatelessWidget {
  const _DemoGlucoseSummary({required this.entries});

  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    final values = <int>[];
    final readingPattern = RegExp(r' · ([0-9]+) mg/dL$');
    for (final entry in entries) {
      if (entry == 'Hoy, 08:30 · 112 mg/dL') continue;
      final value = int.tryParse(readingPattern.firstMatch(entry)?.group(1) ?? '');
      if (value != null) values.add(value);
    }
    if (values.isEmpty) {
      return const ListTile(
        title: Text('Tus registros de prueba'),
        subtitle: Text('Guarda una lectura ficticia para ver el resumen.'),
      );
    }
    final average = values.reduce((a, b) => a + b) / values.length;
    return Card(
      child: ListTile(
        title: const Text('Tus registros de prueba'),
        subtitle: Text(
          'Lecturas guardadas: ${values.length}\n'
          'Media: ${average.toStringAsFixed(1)} mg/dL\n'
          'Última lectura: ${values.first} mg/dL',
        ),
      ),
    );
  }
}

class _PenDemo extends StatefulWidget {
  const _PenDemo();

  @override
  State<_PenDemo> createState() => _PenDemoState();
}

class _PenDemoState extends State<_PenDemo> {
  static const _key = 'diabeta.demo.pen.v1';
  final _storage = SharedPreferencesAsync();
  List<String>? _entries;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await _storage.getStringList(_key) ?? const <String>[];
      if (mounted) setState(() => _entries = entries);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo abrir el historial de plumas.');
    }
  }

  Future<void> _import() async {
    final entries = _entries;
    if (_saving || entries == null) return;
    final now = DateTime.now();
    final local = MaterialLocalizations.of(context);
    final date = local.formatShortDate(now);
    final time = local.formatTimeOfDay(TimeOfDay.fromDateTime(now));
    final next = ['$date $time · NovoPen Echo Plus · Insulina rápida (simulada)', ...entries];
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _storage.setStringList(_key, next);
      if (mounted) setState(() => _entries = next);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo guardar la importación.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton(
        onPressed: _entries == null || _saving ? null : _import,
        child: const Text('Importar registro simulado de NovoPen'),
      ),
      if (_error != null) Text(_error!),
      if (_entries?.isNotEmpty ?? false)
        const ListTile(title: Text('Historial de importaciones simuladas')),
      for (final entry in _entries ?? const <String>[])
        ListTile(title: Text(entry)),
    ],
  );
}

class _GuardianDemo extends StatefulWidget {
  const _GuardianDemo({required this.entries});

  final List<String> entries;

  @override
  State<_GuardianDemo> createState() => _GuardianDemoState();
}

class _GuardianDemoState extends State<_GuardianDemo> {
  bool _showSummary = false;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Guardian de prueba · resumen local de lecturas ficticias'),
      const SizedBox(height: 8),
      if (_showSummary)
        _DemoGlucoseSummary(entries: widget.entries)
      else
        FilledButton(
          onPressed: () => setState(() => _showSummary = true),
          child: const Text('Ver resumen de mis lecturas de prueba'),
        ),
    ],
  );
}

class _AlertDemo extends StatelessWidget {
  const _AlertDemo();

  static const _examples = {
    'Glucosa baja': 'Lectura baja ficticia. Simulación de un aviso en pantalla.',
    'Glucosa alta': 'Lectura alta ficticia. Simulación de un aviso en pantalla.',
    'Pérdida de señal': 'Sensor ficticio sin lecturas nuevas. Simulación de una interrupción.',
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Prueba de avisos en pantalla'),
      Wrap(
        spacing: 8,
        children: [
          for (final example in _examples.entries)
            OutlinedButton(
              child: Text(example.key),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text('Prueba · ${example.key}'),
                  content: Text(example.value),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 12),
    ],
  );
}

class _EmergencyQrDemo extends StatelessWidget {
  const _EmergencyQrDemo();

  static const _sample = 'DIABETA | FICHA FICTICIA\n'
      'Nombre: Persona de prueba\n'
      'Perfil: diabetes tipo 1 (ejemplo)\n'
      'Contacto: Contacto de prueba (sin telefono)';

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: const Text('Ficha médica QR de prueba'),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text('Ficha ficticia. Escanea el código con otro dispositivo para leerla.'),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: QrImageView(
            data: _sample,
            size: 180,
            backgroundColor: Colors.white,
            semanticsLabel: 'Código QR con una ficha ficticia de Diabeta',
          ),
        ),
      ],
    ),
  );
}

class _ProfileDemo extends StatefulWidget {
  const _ProfileDemo();

  @override
  State<_ProfileDemo> createState() => _ProfileDemoState();
}

class _ProfileDemoState extends State<_ProfileDemo> {
  static const _key = 'diabeta.demo.profile.v1';
  static const _profiles = ['Tipo 1', 'Tipo 2', 'Gestacional', 'Prediabetes', 'Deportista'];
  final _storage = SharedPreferencesAsync();
  String? _selected;
  String? _error;
  bool _ready = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final saved = await _storage.getString(_key);
      if (!mounted) return;
      setState(() {
        _selected = _profiles.contains(saved) ? saved : null;
        _ready = true;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo recuperar el perfil.');
    }
  }

  Future<void> _select(String? value) async {
    if (value == null || !_ready || _saving || value == _selected) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _storage.setString(_key, value);
      if (mounted) setState(() => _selected = value);
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo guardar el perfil.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      DropdownButton<String>(
        isExpanded: true,
        hint: const Text('Elige un perfil de prueba'),
        value: _selected,
        items: [
          for (final profile in _profiles)
            DropdownMenuItem(value: profile, child: Text(profile)),
        ],
        onChanged: _ready && !_saving ? _select : null,
      ),
      if (_saving)
        const Text('Guardando perfil…')
      else if (_selected != null && _error == null)
        const Text('Perfil de prueba guardado en este navegador.'),
      if (_error != null) Text(_error!),
      const SizedBox(height: 12),
    ],
  );
}
