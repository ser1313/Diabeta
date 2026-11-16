import 'package:diabeta/education/glucose_education_content.dart';
import 'package:diabeta/education/glucose_education_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  group('Contenido educativo', () {
    test('el módulo por defecto supera la validación', () {
      expect(validateEducationModule(glucoseMeterEducation), isEmpty);
    });

    test('sigue pendiente de revisión clínica', () {
      expect(glucoseMeterEducation.reviewStatus, ReviewStatus.pendingClinicalReview);
    });

    test('cubre preparación, configuración, errores, registro y ayuda', () {
      final ids = glucoseMeterEducation.sections.map((s) => s.id).toSet();
      expect(ids, containsAll(['preparacion', 'configuracion', 'errores', 'registro', 'ayuda']));
    });

    test('rechaza dosis y cifras de glucosa con unidad', () {
      const bad = EducationModule(
        title: 'x',
        disclaimer: 'x',
        reviewStatus: ReviewStatus.pendingClinicalReview,
        sections: [
          EducationSection(id: 'a', title: 'A', summary: 'Ajusta la dosis', steps: ['Por debajo de 70 mg/dL']),
          EducationSection(id: 'b', title: 'B', summary: 'b', steps: ['Valor de 5,5 mmol/L']),
        ],
      );
      final problems = validateEducationModule(bad);
      expect(problems.where((p) => p.contains('no permitido')).length, 3);
    });

    test('permite mencionar la unidad sin cifra', () {
      const ok = EducationModule(
        title: 'x',
        disclaimer: 'x',
        reviewStatus: ReviewStatus.pendingClinicalReview,
        sections: [
          EducationSection(id: 'a', title: 'A', summary: 'a', steps: ['Diabeta guarda los valores en mg/dL.']),
        ],
      );
      expect(validateEducationModule(ok), isEmpty);
    });

    test('detecta estructura incompleta', () {
      const empty = EducationModule(
        title: ' ',
        disclaimer: '',
        reviewStatus: ReviewStatus.pendingClinicalReview,
        sections: [
          EducationSection(id: 'a', title: 'A', summary: 'a', steps: []),
          EducationSection(id: 'a', title: '', summary: 'a', steps: ['ok']),
        ],
      );
      final problems = validateEducationModule(empty);
      expect(problems, contains('El módulo no tiene título.'));
      expect(problems, contains('Falta el aviso legal.'));
      expect(problems, contains('Sección duplicada: a.'));
      expect(problems, contains('Sección a sin pasos.'));
      expect(problems, contains('Sección a sin título.'));
    });
  });

  group('GlucoseEducationPage', () {
    testWidgets('muestra aviso, borrador y todas las secciones', (tester) async {
      await tester.pumpWidget(_wrap(const GlucoseEducationPage()));
      expect(find.text(glucoseMeterEducation.disclaimer), findsOneWidget);
      expect(find.byKey(const Key('pending-review-banner')), findsOneWidget);
      for (final s in glucoseMeterEducation.sections) {
        await tester.scrollUntilVisible(find.text(s.title), 200);
        expect(find.text(s.title), findsOneWidget);
      }
    });

    testWidgets('al expandir una sección muestra sus pasos', (tester) async {
      await tester.pumpWidget(_wrap(const GlucoseEducationPage()));
      final first = glucoseMeterEducation.sections.first;
      expect(find.text(first.steps.first), findsNothing);
      await tester.tap(find.text(first.title));
      await tester.pumpAndSettle();
      expect(find.text(first.steps.first), findsOneWidget);
    });

    testWidgets('los pasos tienen etiqueta accesible numerada', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const GlucoseEducationPage()));
      final first = glucoseMeterEducation.sections.first;
      await tester.tap(find.text(first.title));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Paso 1 de ${first.steps.length}: ${first.steps.first}'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('contenido inválido muestra un estado de error seguro', (tester) async {
      const bad = EducationModule(
        title: 'Prueba',
        disclaimer: 'x',
        reviewStatus: ReviewStatus.clinicallyReviewed,
        sections: [EducationSection(id: 'a', title: 'A', summary: 'a', steps: ['Inyecta 4 unidades'])],
      );
      await tester.pumpWidget(_wrap(const GlucoseEducationPage(module: bad)));
      expect(find.byKey(const Key('education-content-error')), findsOneWidget);
      expect(find.text('Inyecta 4 unidades'), findsNothing);
    });

    testWidgets('sin banner de borrador cuando está revisado', (tester) async {
      const reviewed = EducationModule(
        title: 'Revisado',
        disclaimer: 'Aviso',
        reviewStatus: ReviewStatus.clinicallyReviewed,
        sections: [EducationSection(id: 'a', title: 'A', summary: 'a', steps: ['Paso'])],
      );
      await tester.pumpWidget(_wrap(const GlucoseEducationPage(module: reviewed)));
      expect(find.byKey(const Key('pending-review-banner')), findsNothing);
    });
  });
}
