List<Map<String, String>> buildRecentHistory(
  List<dynamic> glucose,
  List<dynamic> insulin, {
  int limit = 5,
}) {
  final recent = <Map<String, String>>[
    for (final item in glucose.take(limit))
      {
        'kind': 'Glucosa',
        'value': '${item['value'] ?? '--'} mg/dL',
        'recordedAt': item['recordedAt']?.toString() ?? '',
      },
    for (final item in insulin.take(limit))
      {
        'kind': 'Insulina',
        'value': "${item['units'] ?? '--'} U · ${item['insulinType'] ?? 'tipo no indicado'}",
        'recordedAt': item['recordedAt']?.toString() ?? '',
      },
  ];
  recent.sort((a, b) {
    final dateA = DateTime.tryParse(a['recordedAt'] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final dateB = DateTime.tryParse(b['recordedAt'] ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return dateB.compareTo(dateA);
  });
  return recent.take(limit).toList(growable: false);
}

bool isValidGlucoseEntry(double? value) =>
    value != null && value.isFinite && value >= 20 && value <= 1000;

bool isValidInsulinEntry(double? units) =>
    units != null && units.isFinite && units >= 0 && units <= 200;
