import 'package:diabeta/education/glucose_education_content.dart';
import 'package:diabeta/education/glucose_education_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {double textScale = 1.0}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: child,
      ),
    );

EducationModule _moduleWith(List<String> steps, {String title = 'Módulo', ReviewStatus status = ReviewStatus.pendingClinicalReview}) =>
    EducationModule(
      title: title,
      disclaimer: 'Aviso',
      reviewStatus: status,
      sections: [EducationSection(id: 'a', title: 'A', summary: 'Resumen', steps: steps)],
    );

const _reviewed = EducationModule(
  title: 'Revisado',
  disclaimer: 'Aviso',
  reviewStatus: ReviewStatus.clinicallyReviewed,
  sections: [EducationSection(id: 'a', title: 'A', summary: 'a', steps: ['Paso'])],
);

void main() {
  group('Contenido educativo por defecto', () {
    test('supera la validación', () {
      expect(validateEducationModule(glucoseMeterEducation), isEmpty);
    });

    test('sigue pendiente de revisión sanitaria y no es publicable', () {
      expect(glucoseMeterEducation.reviewStatus, ReviewStatus.pendingClinicalReview);
      expect(isEducationModulePublishable(glucoseMeterEducation), isFalse);
    });

    test('cubre preparación, configuración, errores, registro y ayuda', () {
      final ids = glucoseMeterEducation.sections.map((s) => s.id).toSet();
      expect(ids, containsAll(['preparacion', 'configuracion', 'errores', 'registro', 'ayuda']));
    });

    test('la única cifra presente es el 112', () {
      final all = glucoseMeterEducation.sections.expand((s) => [s.title, s.summary, ...s.steps]).join(' ');
      final numbers = RegExp(r'\d+').allMatches(all).map((m) => m.group(0)).toSet();
      expect(numbers, {'112'});
    });
  });

  group('Validador: contenido prohibido', () {
    final forbidden = <String, String>{
      'dosis': 'Ajusta la dosis antes de comer',
      'DOSIS en mayúsculas': 'REVISA LA DOSIS',
      'insulina': 'Revisa tu insulina rápida',
      'bolo': 'Calcula el bolo',
      'corrección con tilde': 'Aplica una corrección',
      'ratio': 'Usa tu ratio habitual',
      'factor de sensibilidad': 'Consulta tu factor de sensibilidad',
      'umbral con mg/dL': 'Por debajo de 70 mg/dL',
      'mg/dL sin espacio': 'Valor 70mg/dl',
      'mmol/L con decimal': 'Valor de 5,5 mmol/L',
      'cifra sin unidad': 'Si baja de 70 come algo',
      'unidades con cifra': 'Pon 4 unidades',
      'porcentaje': 'Objetivo de 7 %',
      'inyecta': 'Inyecta antes de comer',
      'inyéctate con tilde': 'INYÉCTATE antes de dormir',
      'inyectar': 'Debes inyectar más',
      'administrar': 'Administrar con la comida',
      'pínchate': 'Pínchate en el abdomen',
      'ponte': 'Ponte la pauta',
      'aumenta': 'Aumenta la cantidad',
      'reduce': 'Reduce la cantidad',
      'suspende': 'Suspende el tratamiento',
    };

    forbidden.forEach((name, text) {
      test('rechaza $name', () {
        expect(findForbiddenClinicalContent(text), isNotEmpty, reason: text);
        expect(validateEducationModule(_moduleWith([text])), isNotEmpty);
      });
    });

    test('detecta contenido prohibido en título y resumen de sección', () {
      const m = EducationModule(
        title: 'Guía',
        disclaimer: 'Aviso',
        reviewStatus: ReviewStatus.pendingClinicalReview,
        sections: [EducationSection(id: 'a', title: 'Tu dosis', summary: 'Hasta 180', steps: ['Paso'])],
      );
      expect(validateEducationModule(m).length, 2);
    });

    test('detecta contenido prohibido en el título del módulo', () {
      expect(validateEducationModule(_moduleWith(['Paso'], title: 'Dosis de insulina')), isNotEmpty);
    });

    test('no analiza el aviso legal, que niega dar dosis', () {
      const m = EducationModule(
        title: 'Guía',
        disclaimer: 'No contiene recomendaciones de dosis.',
        reviewStatus: ReviewStatus.pendingClinicalReview,
        sections: [EducationSection(id: 'a', title: 'A', summary: 'a', steps: ['Paso'])],
      );
      expect(validateEducationModule(m), isEmpty);
    });
  });

  group('Validador: contenido permitido', () {
    final allowed = [
      'Diabeta guarda los valores en mg/dL.',
      'Ante una emergencia, llama al 112.',
      'Lávate las manos con agua y jabón.',
      'Comprueba qué unidad muestra el medidor.',
      'Coloca una lanceta nueva en cada medición.',
    ];
    for (final text in allowed) {
      test('acepta "$text"', () {
        expect(findForbiddenClinicalContent(text), isEmpty);
      });
    }

    test('normaliza mayúsculas y tildes', () {
      expect(normalizeForValidation('INYÉCTATE Corrección Ñ'), 'inyectate correccion n');
    });
  });

  group('Validador: estructura', () {
    test('detecta título, aviso, duplicados, pasos y textos vacíos', () {
      const m = EducationModule(
        title: ' ',
        disclaimer: '',
        reviewStatus: ReviewStatus.pendingClinicalReview,
        sections: [
          EducationSection(id: 'a', title: 'A', summary: 'a', steps: []),
          EducationSection(id: 'a', title: '', summary: 'a', steps: ['  ']),
          EducationSection(id: '', title: 'C', summary: 'c', steps: ['ok']),
        ],
      );
      final problems = validateEducationModule(m);
      expect(problems, containsAll([
        'El módulo no tiene título.',
        'Falta el aviso legal.',
        'Sección duplicada: a.',
        'Sección a sin pasos.',
        'Sección a sin título.',
        'Texto vacío en a.',
        'Sección sin identificador.',
      ]));
    });

    test('un módulo sin secciones no es válido', () {
      const m = EducationModule(title: 'T', disclaimer: 'A', reviewStatus: ReviewStatus.clinicallyReviewed, sections: []);
      expect(validateEducationModule(m), contains('El módulo no tiene secciones.'));
      expect(isEducationModulePublishable(m), isFalse);
    });
  });

  group('Publicación', () {
    test('el contenido pendiente solo es visible en vista previa', () {
      expect(isEducationModuleVisible(glucoseMeterEducation, previewEnabled: false), isFalse);
      expect(isEducationModuleVisible(glucoseMeterEducation, previewEnabled: true), isTrue);
    });

    test('el contenido revisado y válido es visible siempre', () {
      expect(isEducationModuleVisible(_reviewed, previewEnabled: false), isTrue);
    });

    test('el contenido inválido nunca es visible, aunque esté revisado', () {
      final bad = _moduleWith(['Inyecta 4 unidades'], status: ReviewStatus.clinicallyReviewed);
      expect(isEducationModuleVisible(bad, previewEnabled: true), isFalse);
      expect(isEducationModulePublishable(bad), isFalse);
    });

    testWidgets('sin vista previa, la pantalla no muestra contenido pendiente', (tester) async {
      await tester.pumpWidget(_wrap(const GlucoseEducationPage(previewEnabled: false)));
      expect(find.byKey(const Key('education-content-unavailable')), findsOneWidget);
      expect(find.text(glucoseMeterEducation.sections.first.title), findsNothing);
    });
  });

  group('GlucoseEducationPage', () {
    testWidgets('muestra aviso, borrador y todas las secciones', (tester) async {
      await tester.pumpWidget(_wrap(const GlucoseEducationPage(previewEnabled: true)));
      expect(find.text(glucoseMeterEducation.disclaimer), findsOneWidget);
      expect(find.byKey(const Key('pending-review-banner')), findsOneWidget);
      for (final s in glucoseMeterEducation.sections) {
        await tester.scrollUntilVisible(find.text(s.title), 200);
        expect(find.text(s.title), findsOneWidget);
      }
    });

    testWidgets('al expandir una sección muestra sus pasos', (tester) async {
      await tester.pumpWidget(_wrap(const GlucoseEducationPage(previewEnabled: true)));
      final first = glucoseMeterEducation.sections.first;
      expect(find.text(first.steps.first), findsNothing);
      await tester.tap(find.text(first.title));
      await tester.pumpAndSettle();
      expect(find.text(first.steps.first), findsOneWidget);
    });

    testWidgets('contenido inválido muestra un estado de error seguro', (tester) async {
      final bad = _moduleWith(['Inyecta 4 unidades'], status: ReviewStatus.clinicallyReviewed);
      await tester.pumpWidget(_wrap(GlucoseEducationPage(module: bad, previewEnabled: true)));
      expect(find.byKey(const Key('education-content-error')), findsOneWidget);
      expect(find.text('Inyecta 4 unidades'), findsNothing);
    });

    testWidgets('sin banner de borrador cuando está revisado', (tester) async {
      await tester.pumpWidget(_wrap(const GlucoseEducationPage(module: _reviewed, previewEnabled: false)));
      expect(find.text('A'), findsOneWidget);
      expect(find.byKey(const Key('pending-review-banner')), findsNothing);
    });
  });

  group('Accesibilidad', () {
    testWidgets('los pasos tienen etiqueta numerada propia', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const GlucoseEducationPage(previewEnabled: true)));
      final first = glucoseMeterEducation.sections.first;
      await tester.tap(find.text(first.title));
      await tester.pumpAndSettle();
      for (var i = 0; i < first.steps.length; i++) {
        expect(
          find.bySemanticsLabel('Paso ${i + 1} de ${first.steps.length}: ${first.steps[i]}'),
          findsOneWidget,
        );
      }
      handle.dispose();
    });

    testWidgets('los títulos de sección se anuncian como encabezados', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const GlucoseEducationPage(previewEnabled: true)));
      final title = glucoseMeterEducation.sections.first.title;
      final node = tester.getSemantics(find.text(title));
      expect(node.getSemanticsData().hasFlag(SemanticsFlag.isHeader), isTrue);
      handle.dispose();
    });

    testWidgets('los iconos decorativos no se anuncian', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const GlucoseEducationPage(previewEnabled: true)));
      expect(find.bySemanticsLabel(RegExp('info_outline|rate_review')), findsNothing);
      handle.dispose();
    });

    testWidgets('cumple las guías de tamaño de toque y etiquetas', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const GlucoseEducationPage(previewEnabled: true)));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testWidgets('cumple la guía de contraste de texto', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(const GlucoseEducationPage(previewEnabled: true)));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('con texto al 200 % no hay desbordamientos', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_wrap(const GlucoseEducationPage(previewEnabled: true), textScale: 2.0));
      expect(tester.takeException(), isNull);
      final first = glucoseMeterEducation.sections.first;
      await tester.scrollUntilVisible(find.text(first.title), 200);
      await tester.tap(find.text(first.title));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(find.text(first.steps.last), 200);
      expect(tester.takeException(), isNull);
    });

    testWidgets('el estado de error también es accesible', (tester) async {
      final handle = tester.ensureSemantics();
      final bad = _moduleWith(['Dosis']);
      await tester.pumpWidget(_wrap(GlucoseEducationPage(module: bad, previewEnabled: true)));
      expect(find.bySemanticsLabel(RegExp('no está disponible')), findsOneWidget);
      handle.dispose();
    });
  });
}
