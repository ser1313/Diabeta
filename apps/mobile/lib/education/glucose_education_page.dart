import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'glucose_education_content.dart';

/// Pantalla educativa sobre uso y registro de glucómetros.
/// No hace llamadas de red ni guarda datos personales.
class GlucoseEducationPage extends StatelessWidget {
  final EducationModule module;
  const GlucoseEducationPage({super.key, this.module = glucoseMeterEducation});

  @override
  Widget build(BuildContext context) {
    final problems = validateEducationModule(module);
    return Scaffold(
      appBar: AppBar(title: Text(module.title.isEmpty ? 'Educación' : module.title)),
      body: problems.isNotEmpty
          ? _ContentError(problems: problems)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _NoticeCard(
                  icon: Icons.info_outline,
                  text: module.disclaimer,
                ),
                if (module.reviewStatus == ReviewStatus.pendingClinicalReview)
                  const _NoticeCard(
                    key: Key('pending-review-banner'),
                    icon: Icons.rate_review_outlined,
                    text: 'Borrador pendiente de revisión por profesionales sanitarios.',
                  ),
                const SizedBox(height: 8),
                for (final s in module.sections) _SectionTile(section: s),
              ],
            ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  final IconData icon;
  final String text;
  const _NoticeCard({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ListTile(
          leading: ExcludeSemantics(child: Icon(icon)),
          title: Text(text),
        ),
      );
}

class _SectionTile extends StatelessWidget {
  final EducationSection section;
  const _SectionTile({required this.section});

  @override
  Widget build(BuildContext context) => Card(
        child: ExpansionTile(
          key: PageStorageKey('education-${section.id}'),
          title: Semantics(header: true, child: Text(section.title)),
          subtitle: Text(section.summary),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < section.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Semantics(
                  container: true,
                  label: 'Paso ${i + 1} de ${section.steps.length}: ${section.steps[i]}',
                  excludeSemantics: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${i + 1}. '),
                      Expanded(child: Text(section.steps[i])),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
}

class _ContentError extends StatelessWidget {
  final List<String> problems;
  const _ContentError({required this.problems});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Este contenido no está disponible. Consulta el manual de tu medidor o a tu equipo sanitario.',
                key: Key('education-content-error'),
                textAlign: TextAlign.center,
              ),
              // Los detalles solo se muestran en depuración para no exponer
              // textos rechazados al usuario final.
              if (kDebugMode)
                Text('${problems.length} problema(s) de validación', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}
