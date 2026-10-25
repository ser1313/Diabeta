import 'package:flutter/material.dart';
import 'api_client.dart';
import 'guardian_status.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});
  @override State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final api = ApiClient();
  Map<String, dynamic>? metrics;
  Map<String, dynamic>? guardian;
  String? error;

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final results = await Future.wait([api.getMap('/metrics/summary'), api.getMap('/guardian/check')]);
      if (mounted) setState(() { metrics = results[0]; guardian = results[1]; error = null; });
    } catch (_) {
      if (mounted) setState(() => error = 'No se pudieron cargar los indicadores.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = metrics ?? {};
    final g = guardian ?? {};
    return Scaffold(
      appBar: AppBar(title: const Text('Indicadores y Guardian')),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (error != null) Text(error!),
            Card(child: ListTile(
              leading: Icon(guardianNeedsAttention(g) ? Icons.warning_amber : Icons.shield_outlined),
              title: Text(guardianNeedsAttention(g) ? 'Guardian: atención' : 'Guardian: sin alerta'),
              subtitle: Text(g['message']?.toString() ?? 'Sin información disponible.'),
            )),
            Card(child: ListTile(title: const Text('Tiempo en rango (70–180 mg/dL)'), trailing: Text('${m['timeInRangePercent'] ?? '--'} %'))),
            Card(child: ListTile(title: const Text('Glucosa media'), trailing: Text('${m['averageGlucose'] ?? '--'} mg/dL'))),
            Card(child: ListTile(title: const Text('HbA1c estimada'), trailing: Text(formatEstimatedHbA1c(m)))),
            const SizedBox(height: 12),
            const Text('Estos indicadores son informativos y no constituyen diagnóstico ni sustituyen las indicaciones de tu equipo sanitario.'),
          ],
        ),
      ),
    );
  }
}

class InsulinCalculatorPage extends StatefulWidget {
  const InsulinCalculatorPage({super.key});
  @override State<InsulinCalculatorPage> createState() => _InsulinCalculatorPageState();
}

class _InsulinCalculatorPageState extends State<InsulinCalculatorPage> {
  final api = ApiClient();
  final carbs = TextEditingController();
  final ratio = TextEditingController();
  final current = TextEditingController();
  final target = TextEditingController();
  final factor = TextEditingController();
  final active = TextEditingController(text: '0');
  Map<String, dynamic>? result;
  String? error;

  Future<void> calculate() async {
    try {
      final r = await api.post('/calculator/insulin', {
        'carbsGrams': double.parse(carbs.text),
        'insulinToCarbRatio': double.parse(ratio.text),
        'currentGlucose': double.parse(current.text),
        'targetGlucose': double.parse(target.text),
        'correctionFactor': double.parse(factor.text),
        'activeInsulinUnits': double.parse(active.text),
      });
      if (mounted) setState(() { result = r; error = null; });
    } catch (_) {
      if (mounted) setState(() => error = 'Revisa todos los parámetros.');
    }
  }

  @override
  void dispose() {
    for (final c in [carbs, ratio, current, target, factor, active]) { c.dispose(); }
    super.dispose();
  }

  Widget field(TextEditingController c, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Calculadora informativa')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Introduce únicamente los parámetros que te haya indicado tu equipo sanitario. Diabeta no establece pautas clínicas.'),
        const SizedBox(height: 14),
        field(carbs, 'Carbohidratos (g)'),
        field(ratio, 'Relación insulina/carbohidratos'),
        field(current, 'Glucosa actual (mg/dL)'),
        field(target, 'Glucosa objetivo (mg/dL)'),
        field(factor, 'Factor de corrección'),
        field(active, 'Insulina activa (U)'),
        FilledButton.icon(onPressed: calculate, icon: const Icon(Icons.calculate), label: const Text('Calcular')),
        if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!)),
        if (result != null) Card(
          margin: const EdgeInsets.only(top: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Resultado matemático: ${result!['calculatedUnits']} U', style: Theme.of(context).textTheme.titleLarge),
                Text('Componente comida: ${result!['mealComponent']} U'),
                Text('Componente corrección: ${result!['correctionComponent']} U'),
                Text('Descuento de insulina activa: ${result!['activeInsulinDeduction']} U'),
                const SizedBox(height: 10),
                Text(result!['disclaimer']?.toString() ?? ''),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}


class LifestylePage extends StatefulWidget {
  const LifestylePage({super.key});
  @override State<LifestylePage> createState() => _LifestylePageState();
}

class _LifestylePageState extends State<LifestylePage> {
  final api = ApiClient();
  List<dynamic> meals = [];
  List<dynamic> activities = [];
  String status = 'Cargando...';

  @override
  void initState() { super.initState(); load(); }

  Future<void> load() async {
    try {
      final results = await Future.wait([api.getList('/nutrition'), api.getList('/activity')]);
      if (mounted) setState(() {
        meals = results[0];
        activities = results[1];
        status = 'Datos sincronizados';
      });
    } catch (_) {
      if (mounted) setState(() => status = 'No se pudieron cargar los datos.');
    }
  }

  Future<void> addMeal() async {
    final name = TextEditingController();
    final carbs = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir comida'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Comida')),
          TextField(controller: carbs, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Carbohidratos (g)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () async {
            await api.post('/nutrition', {'name': name.text.trim(), 'carbs': double.tryParse(carbs.text)});
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Guardar')),
        ],
      ),
    );
    name.dispose(); carbs.dispose(); await load();
  }

  Future<void> addActivity() async {
    final type = TextEditingController();
    final minutes = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir actividad'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: type, decoration: const InputDecoration(labelText: 'Tipo de actividad')),
          TextField(controller: minutes, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Minutos')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () async {
            final min = int.tryParse(minutes.text);
            if (min != null && min > 0) {
              await api.post('/activity', {'type': type.text.trim(), 'minutes': min});
            }
            if (ctx.mounted) Navigator.pop(ctx);
          }, child: const Text('Guardar')),
        ],
      ),
    );
    type.dispose(); minutes.dispose(); await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Nutrición y actividad')),
    body: RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(status),
          Card(child: ListTile(leading: const Icon(Icons.restaurant), title: const Text('Registrar comida'), onTap: addMeal)),
          Card(child: ListTile(leading: const Icon(Icons.fitness_center), title: const Text('Registrar actividad'), onTap: addActivity)),
          const SizedBox(height: 8),
          Text('Últimas comidas', style: Theme.of(context).textTheme.titleMedium),
          ...meals.take(10).map((m) => ListTile(
            title: Text(m['name']?.toString() ?? 'Comida'),
            subtitle: Text('Carbohidratos: ${m['carbs'] ?? '--'} g'),
          )),
          const SizedBox(height: 8),
          Text('Últimas actividades', style: Theme.of(context).textTheme.titleMedium),
          ...activities.take(10).map((a) => ListTile(
            title: Text(a['type']?.toString() ?? 'Actividad'),
            subtitle: Text('${a['minutes'] ?? '--'} minutos'),
          )),
        ],
      ),
    ),
  );
}
