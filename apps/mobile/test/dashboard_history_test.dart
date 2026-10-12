import 'package:flutter_test/flutter_test.dart';
import 'package:diabeta/dashboard_history.dart';

void main() {
  group('buildRecentHistory', () {
    test('sorts mixed glucose and insulin records newest first', () {
      final result = buildRecentHistory(
        [
          {'value': 105, 'recordedAt': '2026-10-10T08:00:00Z'},
          {'value': 112, 'recordedAt': '2026-10-12T08:00:00Z'},
        ],
        [
          {'units': 3, 'insulinType': 'rapid', 'recordedAt': '2026-10-11T08:00:00Z'},
        ],
      );
      expect(result.map((item) => item['kind']).toList(),
          ['Glucosa', 'Insulina', 'Glucosa']);
      expect(result.first['value'], '112 mg/dL');
    });

    test('limits the combined list to five by default and supports custom limits', () {
      final glucose = List.generate(4, (i) => {
        'value': i + 1,
        'recordedAt': '2026-10-${(i + 1).toString().padLeft(2, '0')}T08:00:00Z',
      });
      final insulin = List.generate(4, (i) => {
        'units': i + 1,
        'insulinType': 'rapid',
        'recordedAt': '2026-10-${(i + 1).toString().padLeft(2, '0')}T09:00:00Z',
      });
      expect(buildRecentHistory(glucose, insulin), hasLength(5));
      expect(buildRecentHistory(glucose, insulin, limit: 2), hasLength(2));
    });
  });

  group('glucose and insulin entry validation', () {
    test('accepts valid glucose and zero insulin', () {
      expect(isValidGlucoseEntry(20), isTrue);
      expect(isValidGlucoseEntry(1000), isTrue);
      expect(isValidInsulinEntry(0), isTrue);
      expect(isValidInsulinEntry(200), isTrue);
    });

    test('rejects out-of-range, NaN, and infinite values', () {
      for (final value in <double?>[null, 19, 1001, double.nan, double.infinity]) {
        expect(isValidGlucoseEntry(value), isFalse);
      }
      for (final value in <double?>[null, -1, 201, double.nan, double.infinity]) {
        expect(isValidInsulinEntry(value), isFalse);
      }
    });
  });
}
