import 'package:diabeta/beta_config.dart';
import 'package:diabeta/insights.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _enterGlucoseAndCalculate(WidgetTester tester, String value) async {
  await tester.enterText(find.widgetWithText(TextField, 'Glucosa actual (mg/dL)'), value);
  await tester.ensureVisible(find.text('Calcular'));
  await tester.tap(find.text('Calcular'));
  await tester.pumpAndSettle();
}

void main() {
  test('interruptores desactivados por defecto', () {
    expect(clinicalCalculatorEnabled, isFalse);
    expect(isBetaBuild, isFalse);
    expect(hypoglycemiaThresholdMgDl, 70);
  });

  testWidgets('por defecto la calculadora muestra que está deshabilitada', (tester) async {
    await tester.pumpWidget(_wrap(const InsulinCalculatorPage()));
    expect(find.byKey(const Key('calculator-disabled')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text('Calcular'), findsNothing);
  });

  group('CalculatorResultView', () {
    testWidgets('con hipoglucemia muestra el aviso en rojo y ninguna dosis', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: CalculatorResultView(result: {
        'hypoglycemia': true,
        'calculatedUnits': 0,
        'warning': 'Glucosa baja: no se aconseja administrar insulina.',
      }))));
      final card = tester.widget<Card>(find.byKey(const Key('hypoglycemia-warning')));
      expect(card.color, Colors.red.shade700);
      expect(find.textContaining('no se aconseja administrar insulina'), findsOneWidget);
      expect(find.textContaining(' U'), findsNothing);
      expect(find.textContaining('Resultado matemático'), findsNothing);
    });

    testWidgets('sin aviso del servidor usa un texto seguro por defecto', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: CalculatorResultView(result: {'hypoglycemia': true}))));
      expect(find.textContaining('Glucosa baja'), findsOneWidget);
    });

    testWidgets('regresión: con glucosa normal muestra el resultado como antes', (tester) async {
      await tester.pumpWidget(_wrap(const Scaffold(body: CalculatorResultView(result: {
        'hypoglycemia': false,
        'calculatedUnits': 5,
        'mealComponent': 6,
        'correctionComponent': -1,
        'activeInsulinDeduction': 0,
        'disclaimer': 'Cálculo matemático orientativo.',
      }))));
      expect(find.byKey(const Key('hypoglycemia-warning')), findsNothing);
      expect(find.text('Resultado matemático: 5 U'), findsOneWidget);
      expect(find.text('Componente corrección: -1 U'), findsOneWidget);
    });
  });

  group('protección en la app (calculadora habilitada solo en la prueba)', () {
    testWidgets('69.9 mg/dL: aviso sin llamar a la API', (tester) async {
      await tester.pumpWidget(_wrap(const InsulinCalculatorPage(enabled: true)));
      await _enterGlucoseAndCalculate(tester, '69.9');
      expect(find.byKey(const Key('hypoglycemia-warning')), findsOneWidget);
      expect(find.textContaining('Resultado matemático'), findsNothing);
    });

    testWidgets('70 mg/dL: no muestra el aviso (se pide el cálculo)', (tester) async {
      await tester.pumpWidget(_wrap(const InsulinCalculatorPage(enabled: true)));
      await _enterGlucoseAndCalculate(tester, '70');
      expect(find.byKey(const Key('hypoglycemia-warning')), findsNothing);
      // Sin el resto de parámetros la petición no se envía y se informa del error.
      expect(find.text('Revisa todos los parámetros.'), findsOneWidget);
    });
  });
}
