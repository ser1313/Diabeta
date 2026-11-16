import 'package:diabeta/guardian_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('guardianNeedsAttention', () {
    test('requiere atención con glucosa baja', () {
      expect(guardianNeedsAttention({'level': 'low', 'message': 'Glucosa baja'}), isTrue);
    });

    test('requiere atención con glucosa alta, bajando o subiendo', () {
      for (final level in ['high', 'falling', 'rising']) {
        expect(guardianNeedsAttention({'level': level}), isTrue, reason: level);
      }
    });

    test('no requiere atención cuando el nivel es normal', () {
      expect(guardianNeedsAttention({'level': 'normal'}), isFalse);
    });

    test('no inventa una alerta sin lecturas (unknown) ni si falta el nivel', () {
      expect(guardianNeedsAttention({'level': 'unknown'}), isFalse);
      expect(guardianNeedsAttention({}), isFalse);
    });
  });

  group('formatEstimatedHbA1c', () {
    test('muestra el valor que envía la API', () {
      expect(formatEstimatedHbA1c({'estimatedHbA1c': 6.8}), '6.8 %');
    });

    test('muestra -- si no hay datos', () {
      expect(formatEstimatedHbA1c({'estimatedHbA1c': null}), '-- %');
    });
  });
}
