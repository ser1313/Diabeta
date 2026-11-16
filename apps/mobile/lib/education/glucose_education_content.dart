/// Contenido educativo, no clínico, sobre el uso y registro de glucómetros.
///
/// Reglas de este módulo (ver issue #58 y SECURITY.md):
/// - No incluye dosis, umbrales de glucosa ni pautas de tratamiento.
/// - No reproduce vídeos ni textos de terceros: el interés por el tema se
///   midió con NexLev, pero esas métricas NO aportan validez médica.
/// - Todo el contenido está en estado [ReviewStatus.pendingClinicalReview]
///   hasta que un profesional sanitario lo revise con fuentes oficiales.
library;

enum ReviewStatus { pendingClinicalReview, clinicallyReviewed }

class EducationSection {
  final String id;
  final String title;
  final String summary;
  final List<String> steps;

  const EducationSection({
    required this.id,
    required this.title,
    required this.summary,
    required this.steps,
  });
}

class EducationModule {
  final String title;
  final String disclaimer;
  final ReviewStatus reviewStatus;
  final List<EducationSection> sections;

  const EducationModule({
    required this.title,
    required this.disclaimer,
    required this.reviewStatus,
    required this.sections,
  });
}

const glucoseMeterEducation = EducationModule(
  title: 'Aprende a usar tu glucómetro',
  disclaimer:
      'Contenido educativo general. No sustituye las instrucciones del fabricante '
      'de tu medidor ni las indicaciones de tu equipo sanitario. No contiene '
      'recomendaciones de dosis ni de tratamiento.',
  reviewStatus: ReviewStatus.pendingClinicalReview,
  sections: [
    EducationSection(
      id: 'preparacion',
      title: 'Antes de medir',
      summary: 'Prepara el material y revisa que todo esté en buen estado.',
      steps: [
        'Lávate las manos con agua y jabón y sécalas bien.',
        'Ten a mano el medidor, una tira reactiva, el dispositivo de punción y una lanceta nueva.',
        'Comprueba la fecha de caducidad de las tiras y que son las indicadas para tu modelo de medidor.',
        'Guarda las tiras en su envase original y bien cerrado.',
      ],
    ),
    EducationSection(
      id: 'configuracion',
      title: 'Configurar el medidor',
      summary: 'Una fecha y hora correctas hacen que tu historial sea fiable.',
      steps: [
        'Sigue el manual de tu modelo para ajustar la fecha y la hora.',
        'Revisa la configuración después de cambiar las pilas: algunos modelos la pierden.',
        'Comprueba qué unidad muestra el medidor. Si tienes dudas, consulta a tu equipo sanitario o farmacia; no cambies la unidad por tu cuenta.',
      ],
    ),
    EducationSection(
      id: 'puncion',
      title: 'Usar el dispositivo de punción',
      summary: 'Cada dispositivo es distinto: el manual del fabricante es la referencia.',
      steps: [
        'Coloca una lanceta nueva en cada medición, tal como indica el fabricante.',
        'Ajusta la profundidad según las instrucciones del dispositivo.',
        'Desecha las lancetas usadas en un contenedor adecuado.',
        'No compartas el dispositivo de punción ni las lancetas con otras personas.',
      ],
    ),
    EducationSection(
      id: 'solucion-control',
      title: 'Solución de control',
      summary: 'Sirve para comprobar que el medidor y las tiras funcionan correctamente.',
      steps: [
        'Usa solo la solución de control compatible con tu medidor.',
        'Sigue el manual para saber cuándo y cómo hacer la prueba.',
        'Compara el resultado con el rango impreso en el envase de las tiras. Si no coincide, contacta con el fabricante o tu farmacia.',
      ],
    ),
    EducationSection(
      id: 'errores',
      title: 'Mensajes y códigos de error',
      summary: 'Cada fabricante usa sus propios códigos: no los interpretes por tu cuenta.',
      steps: [
        'Busca el código exacto en el manual de tu modelo.',
        'Repite la medición con una tira nueva si el manual lo indica.',
        'Si el error se repite, contacta con el servicio de atención del fabricante o con tu farmacia.',
      ],
    ),
    EducationSection(
      id: 'registro',
      title: 'Registrar el resultado en Diabeta',
      summary: 'Anota el valor tal como lo muestra el medidor.',
      steps: [
        'Desde la pantalla principal, pulsa «Registrar glucosa».',
        'Diabeta guarda los valores en mg/dL. Si tu medidor usa otra unidad, consulta a tu equipo sanitario antes de registrar.',
        'Registra la medición en el momento: la app guarda la fecha y la hora actuales.',
      ],
    ),
    EducationSection(
      id: 'ayuda',
      title: 'Cuándo pedir ayuda',
      summary: 'Esta guía no sirve para valorar tu estado de salud.',
      steps: [
        'Si un resultado no encaja con cómo te encuentras, contacta con tu equipo sanitario.',
        'Ante una emergencia, llama al 112.',
      ],
    ),
  ],
);

/// Patrones que no deben aparecer en contenido educativo no revisado:
/// dosis, unidades de insulina o cifras de glucosa con unidad.
final List<RegExp> forbiddenClinicalPatterns = [
  RegExp(r'\bdosis\b', caseSensitive: false),
  RegExp(r'\bunidades de insulina\b', caseSensitive: false),
  RegExp(r'\d+(?:[.,]\d+)?\s*(?:mg/dl|mmol/l)', caseSensitive: false),
  RegExp(r'\b(?:inyecta|administra|aumenta|reduce)\b', caseSensitive: false),
];

/// Devuelve la lista de problemas encontrados. Vacía = contenido válido.
List<String> validateEducationModule(EducationModule module) {
  final problems = <String>[];
  if (module.title.trim().isEmpty) problems.add('El módulo no tiene título.');
  if (module.disclaimer.trim().isEmpty) problems.add('Falta el aviso legal.');
  if (module.sections.isEmpty) problems.add('El módulo no tiene secciones.');

  final ids = <String>{};
  for (final s in module.sections) {
    if (!ids.add(s.id)) problems.add('Sección duplicada: ${s.id}.');
    if (s.title.trim().isEmpty) problems.add('Sección ${s.id} sin título.');
    if (s.steps.isEmpty) problems.add('Sección ${s.id} sin pasos.');
    for (final text in [s.title, s.summary, ...s.steps]) {
      if (text.trim().isEmpty) problems.add('Texto vacío en ${s.id}.');
      for (final p in forbiddenClinicalPatterns) {
        if (p.hasMatch(text)) {
          problems.add('Contenido clínico no permitido en ${s.id}: "$text"');
        }
      }
    }
  }
  return problems;
}
