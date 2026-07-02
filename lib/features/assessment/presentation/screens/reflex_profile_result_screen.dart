import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/reflex_profile_assessment.dart';
import '../../domain/services/reflex_profile_pdf_service.dart';
import '../../domain/reflex_questionnaire.dart';
import '../providers/reflex_profile_provider.dart';
import '../widgets/reflex_radar_chart.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';
import 'reflex_profile_result_helpers.dart';

class ReflexProfileResultScreen extends ConsumerWidget {
  const ReflexProfileResultScreen({super.key});

  String _packageId(BuildContext context) {
    final extra = GoRouterState.of(context).extra;
    if (extra is String) return extra;
    if (extra is Map<String, dynamic>) {
      return extra['packageId'] as String? ?? 'moro';
    }
    return 'moro';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Accept a specific assessment passed via navigation extra (e.g. from the
    // Verlauf profile card). Falls back to the latest for the active profile.
    final extra = GoRouterState.of(context).extra;
    final passedAssessment = extra is Map<String, dynamic>
        ? extra['assessment'] as ReflexProfileAssessment?
        : null;

    final fallbackAsync =
        ref.watch(latestReflexProfileForSelectedSubjectProvider);
    final assessmentAsync = passedAssessment != null
        ? AsyncValue<ReflexProfileAssessment?>.data(passedAssessment)
        : fallbackAsync;

    final connections =
        ref.watch(clientTrainerConnectionsProvider).valueOrNull ?? const [];
    final activeConnection =
        connections.where((connection) => connection.isActive).firstOrNull;
    final packageId = _packageId(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reflexprofil-Auswertung')),
      body: SafeArea(
        child: assessmentAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Auswertung konnte nicht geladen werden: $error'),
            ),
          ),
          data: (assessment) {
            if (assessment == null || !assessment.isCompleted) {
              return _EmptyResult(packageId: packageId);
            }
            return _ResultContent(
              assessment: assessment,
              packageId: packageId,
              activeConnection: activeConnection,
            );
          },
        ),
      ),
    );
  }
}

class _ResultContent extends ConsumerWidget {
  const _ResultContent({
    required this.assessment,
    required this.packageId,
    this.activeConnection,
  });

  final ReflexProfileAssessment assessment;
  final String packageId;
  final ClientTrainerConnection? activeConnection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final scores = _scoreRows(assessment);
    final topScores = scores.toList();
    final radarScores = topScores
        .map((s) => ReflexRadarScore(
              label: s.label,
              shortLabel: s.shortLabel,
              percent: s.percent,
            ))
        .toList();
    final warningCount = assessment.warningConfirmations.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Text(
          'Hinweistärken',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Diese Auswertung zeigt Antwortmuster und ersetzt keine medizinische '
          'oder therapeutische Diagnose.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.4,
              ),
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.25,
                  child: ReflexRadarChart(scores: radarScores),
                ),
                const SizedBox(height: 12),
                Text(
                  'Die Grafik zeigt die stärksten Reflexbereiche aus deinem '
                  'Antwortmuster.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (warningCount > 0) ...[
          const SizedBox(height: 14),
          Card(
            color: AppColors.warning.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_information_outlined,
                      color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Du hast $warningCount Hinweis${warningCount == 1 ? '' : 'e'} '
                      'bestätigt, bei denen wir dringend Rücksprache mit Arzt, '
                      'Therapeut oder Psychologe empfehlen. Eine Trainerbegleitung '
                      'ist in deinem Fall besonders sinnvoll.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (activeConnection != null &&
            assessment.subjectProfileId != null) ...[
          const SizedBox(height: 14),
          _TrainerShareCard(
            assessment: assessment,
            connection: activeConnection!,
          ),
        ],
        const SizedBox(height: 18),
        Text(
          'Reflexbereiche',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 10),
        for (final score in scores) _ScoreTile(score: score),
        const SizedBox(height: 18),
        Text(
          'Ergänzende Angaben',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        _RelevanteAngaben(
          groups: buildRelevanteAngaben(assessment),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () => _sharePdf(context, assessment),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('PDF-Zusammenfassung teilen'),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => context.go(Routes.dashboard),
          icon: const Icon(Icons.dashboard_outlined),
          label: const Text('Zum Dashboard'),
        ),
      ],
    );
  }

  Future<void> _sharePdf(
    BuildContext context,
    ReflexProfileAssessment assessment,
  ) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      final screenSize = MediaQuery.of(context).size;
      final file =
          await const ReflexProfilePdfService().createSummaryPdf(assessment);
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.fromLTWH(
              screenSize.width / 4,
              screenSize.height * 0.75,
              screenSize.width / 2,
              50,
            );
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Reflex Journey Reflexprofil',
        text: 'Reflex Journey Reflexprofil-Zusammenfassung',
        sharePositionOrigin: origin,
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF konnte nicht erstellt werden: $error')),
        );
      }
    }
  }
}

class _TrainerShareCard extends ConsumerWidget {
  const _TrainerShareCard({
    required this.assessment,
    required this.connection,
  });

  final ReflexProfileAssessment assessment;
  final ClientTrainerConnection connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final subjectId = assessment.subjectProfileId!;
    final lookup = ReflexTrainerShareLookup(
      subjectProfileId: subjectId,
      trainerId: connection.trainerId,
    );
    final shareAsync = ref.watch(reflexProfileTrainerShareProvider(lookup));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.supervisor_account_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mit Trainer teilen',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Du kannst ${connection.displayName} dein vollständiges '
                        'Reflexprofil freigeben. Das hilft bei der gemeinsamen '
                        'Begleitung und kann später widerrufen werden.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            shareAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text(
                'Freigabe konnte nicht geladen werden: $error',
                style: const TextStyle(color: AppColors.error),
              ),
              data: (isShared) => Align(
                alignment: Alignment.centerLeft,
                child: isShared
                    ? OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            await revokeReflexProfileTrainerShare(
                              ref,
                              subjectProfileId: subjectId,
                              trainerId: connection.trainerId,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Freigabe wurde widerrufen.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Freigabe konnte nicht widerrufen werden: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.visibility_off_outlined),
                        label: const Text('Freigabe widerrufen'),
                      )
                    : FilledButton.icon(
                        onPressed: () async {
                          try {
                            await grantReflexProfileTrainerShare(
                              ref,
                              subjectProfileId: subjectId,
                              trainerId: connection.trainerId,
                              relationshipId: connection.relationshipId,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Reflexprofil wurde freigegeben.'),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Reflexprofil konnte nicht freigegeben werden: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('Trainer darf Auswertung sehen'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile({required this.score});

  final _ScoreRow score;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    score.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Text(
                  '${score.percent.round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _bandColor(score.band,
                            secondaryColor: cs.onSurfaceVariant),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _bandLabel(score.band),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _bandColor(score.band,
                        secondaryColor: cs.onSurfaceVariant),
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (score.percent / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                color:
                    _bandColor(score.band, secondaryColor: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${score.yesCount} von ${score.answeredCount} beantworteten '
              'zugeordneten Fragen wurden mit Ja beantwortet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelevanteAngaben extends StatelessWidget {
  const _RelevanteAngaben({required this.groups});

  final List<(ReflexQuestionModule, List<RelevantAnswerItem>)> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Keine weiteren Angaben vorhanden.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups)
          _ModuleGroup(module: group.$1, items: group.$2),
      ],
    );
  }
}

class _ModuleGroup extends StatelessWidget {
  const _ModuleGroup({required this.module, required this.items});

  final ReflexQuestionModule module;
  final List<RelevantAnswerItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            reflexModuleLabel(module).toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.84,
                ),
          ),
        ),
        for (int i = 0; i < items.length; i++) ...[
          _RelevantAnswerCard(item: items[i]),
          if (i < items.length - 1) const SizedBox(height: 6),
        ],
        const SizedBox(height: 14),
      ],
    );
  }
}

class _RelevantAnswerCard extends StatelessWidget {
  const _RelevantAnswerCard({required this.item});

  final RelevantAnswerItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasFreeText = item.freeText != null;
    final hasMonths = item.months != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.question.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            if (hasFreeText) ...[
              const SizedBox(height: 8),
              Text(
                '„${item.freeText}"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: cs.onSurface.withValues(alpha: 0.70),
                      height: 1.45,
                    ),
              ),
            ],
            if (hasMonths) ...[
              SizedBox(height: hasFreeText ? 4 : 8),
              Text(
                '${item.months} Monate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyResult extends StatelessWidget {
  const _EmptyResult({required this.packageId});

  final String packageId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.assignment_outlined, size: 42),
            const SizedBox(height: 12),
            const Text('Noch keine abgeschlossene Auswertung vorhanden.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () =>
                  context.go(Routes.reflexProfile, extra: packageId),
              child: const Text('Reflexprofil starten'),
            ),
          ],
        ),
      ),
    );
  }
}

List<_ScoreRow> _scoreRows(ReflexProfileAssessment assessment) {
  final rows = <_ScoreRow>[];
  for (final entry in assessment.scores.entries) {
    final raw = entry.value;
    if (raw is! Map) continue;
    final percent = (raw['percent'] as num?)?.toDouble() ?? 0;
    final bandName = raw['band'] as String? ?? 'insufficientData';
    rows.add(
      _ScoreRow(
        reflexKey: entry.key,
        label: reflexLabel(entry.key),
        shortLabel: reflexShortLabel(entry.key),
        percent: percent,
        band: _scoreBandFromName(bandName),
        yesCount: raw['yes_count'] as int? ?? 0,
        answeredCount: raw['answered_count'] as int? ?? 0,
      ),
    );
  }
  rows.sort((a, b) => b.percent.compareTo(a.percent));
  return rows;
}

class _ScoreRow {
  const _ScoreRow({
    required this.reflexKey,
    required this.label,
    required this.shortLabel,
    required this.percent,
    required this.band,
    required this.yesCount,
    required this.answeredCount,
  });

  final String reflexKey;
  final String label;
  final String shortLabel;
  final double percent;
  final ReflexScoreBand band;
  final int yesCount;
  final int answeredCount;
}

ReflexScoreBand _scoreBandFromName(String name) {
  return ReflexScoreBand.values.firstWhere(
    (band) => band.name == name,
    orElse: () => ReflexScoreBand.insufficientData,
  );
}

String _bandLabel(ReflexScoreBand band) => switch (band) {
      ReflexScoreBand.strong => 'stark ausgeprägt',
      ReflexScoreBand.elevated => 'auffällig',
      ReflexScoreBand.indication => 'Anzeichen',
      ReflexScoreBand.inconspicuous => 'unauffällig',
      ReflexScoreBand.insufficientData => 'zu wenig Daten',
    };

Color _bandColor(ReflexScoreBand band, {required Color secondaryColor}) =>
    switch (band) {
      ReflexScoreBand.strong => AppColors.error,
      ReflexScoreBand.elevated => AppColors.warning,
      ReflexScoreBand.indication => AppColors.primary,
      ReflexScoreBand.inconspicuous => AppColors.success,
      ReflexScoreBand.insufficientData => secondaryColor,
    };
