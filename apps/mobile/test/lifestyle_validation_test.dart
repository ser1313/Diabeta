import 'package:flutter_test/flutter_test.dart';
import 'package:diabeta/lifestyle_validation.dart';

void main() {
  group('validateMealEntry', () {
    test('accepts a named meal with optional or valid decimal carbs', () {
      expect(validateMealEntry('  Desayuno ', ''), isNull);
      expect(validateMealEntry('Desayuno', '42,5'), isNull);
      expect(validateMealEntry('Desayuno', '0'), isNull);
    });

    test('rejects missing or oversized meal names', () {
      expect(validateMealEntry('   ', '20'), isNotNull);
      expect(validateMealEntry('x' * 201, '20'), isNotNull);
    });

    test('rejects invalid, non-finite, negative and excessive carbs', () {
      for (final value in ['abc', 'NaN', 'Infinity', '-1', '1000.1']) {
        expect(validateMealEntry('Comida', value), isNotNull, reason: value);
      }
    });
  });

  group('validateActivityEntry', () {
    test('accepts trimmed activity names and inclusive duration bounds', () {
      expect(validateActivityEntry(' Caminar ', '1'), isNull);
      expect(validateActivityEntry('Correr', '1440'), isNull);
    });

    test('rejects empty/oversized types and invalid durations', () {
      expect(validateActivityEntry(' ', '30'), isNotNull);
      expect(validateActivityEntry('x' * 101, '30'), isNotNull);
      for (final value in ['0', '-1', '1441', '1.5', 'abc']) {
        expect(validateActivityEntry('Caminar', value), isNotNull, reason: value);
      }
    });
  });
}
