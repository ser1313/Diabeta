typedef AlertThresholds = ({double low, double high});

double _finiteNumberOrDefault(Object? value, double fallback) {
  final parsed = value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');
  return parsed != null && parsed.isFinite ? parsed : fallback;
}

AlertThresholds normalizeAlertThresholds(Object? lowValue, Object? highValue) {
  final low = _finiteNumberOrDefault(lowValue, 70).clamp(40, 100).toDouble();
  var high = _finiteNumberOrDefault(highValue, 180).clamp(100, 300).toDouble();
  if (low >= high) {
    high = (low + 10).clamp(100, 300).toDouble();
  }
  return (low: low, high: high);
}

bool areAlertThresholdsValid(double low, double high) =>
    low.isFinite &&
    high.isFinite &&
    low >= 40 &&
    low <= 100 &&
    high >= 100 &&
    high <= 300 &&
    low < high;
