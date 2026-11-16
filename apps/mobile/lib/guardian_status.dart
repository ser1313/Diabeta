/// Interpreta la respuesta de GET /guardian/check.
///
/// La API devuelve `level` con uno de estos valores: unknown (sin lecturas),
/// normal, low, high, falling o rising. Solo los cuatro últimos requieren
/// atención; sin datos no se muestra ninguna alerta.
const _attentionLevels = {'low', 'high', 'falling', 'rising'};

bool guardianNeedsAttention(Map<String, dynamic> status) {
  return _attentionLevels.contains(status['level']);
}

/// Texto de la HbA1c estimada que devuelve GET /metrics/summary
/// en el campo `estimatedHbA1c`.
String formatEstimatedHbA1c(Map<String, dynamic> metrics) {
  final value = metrics['estimatedHbA1c'];
  return '${value ?? '--'} %';
}
