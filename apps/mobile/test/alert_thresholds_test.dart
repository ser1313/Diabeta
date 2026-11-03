import 'package:flutter_test/flutter_test.dart';
import 'package:diabeta/alert_thresholds.dart';

void main() {
  group('normalizeAlertThresholds', () {
    test('keeps valid values', () {
      expect(normalizeAlertThresholds(70, 180), (low: 70.0, high: 180.0));
    });

    test('uses defaults for non-finite and unparseable values', () {
      expect(normalizeAlertThresholds(double.nan, 'bad'), (low: 70.0, high: 180.0));
      expect(normalizeAlertThresholds(double.infinity, double.negativeInfinity),
          (low: 70.0, high: 180.0));
    });

    test('clamps out-of-range values and preserves ordering', () {
      expect(normalizeAlertThresholds(500, 40), (low: 100.0, high: 110.0));
      expect(normalizeAlertThresholds(-5, 999), (low: 40.0, high: 300.0));
    });
  });

  group('areAlertThresholdsValid', () {
    test('accepts valid ordered thresholds', () {
      expect(areAlertThresholdsValid(70, 180), isTrue);
    });

    test('rejects equal, reversed, out-of-range, and non-finite thresholds', () {
      expect(areAlertThresholdsValid(100, 100), isFalse);
      expect(areAlertThresholdsValid(90, 80), isFalse);
      expect(areAlertThresholdsValid(20, 180), isFalse);
      expect(areAlertThresholdsValid(70, double.infinity), isFalse);
      expect(areAlertThresholdsValid(double.nan, 180), isFalse);
    });
  });
}
