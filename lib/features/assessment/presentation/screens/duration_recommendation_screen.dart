import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/reflex_questionnaire.dart';
import '../../domain/services/training_duration_recommendation_service.dart';
import '../providers/reflex_profile_provider.dart';
import '../../../onboarding/presentation/providers/entry_points_provider.dart';
import '../../../progress/presentation/providers/progress_provider.dart';

class DurationRecommendationScreen extends ConsumerStatefulWidget {
  const DurationRecommendationScreen({super.key});

  @override
  ConsumerState<DurationRecommendationScreen> createState() =>
      _DurationRecommendationScreenState();
}

class _DurationRecommendationScreenState
    extends ConsumerState<DurationRecommendationScreen> {
  late int _selectedWeeks;
  late String _packageId;
  bool _hadTrainer = false;
  bool _reflexProfileSkipped = false;
  bool _showManualAdjust = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _packageId = extra?['packageId'] as String? ?? 'moro';
    _hadTrainer = extra?['hadIsometricWithTrainer'] as bool? ?? false;
    _reflexProfileSkipped = extra?['reflexProfileStatus'] == 'skipped';
    final assessment =
        ref.read(latestReflexProfileForSelectedSubjectProvider).valueOrNull;
    _selectedWeeks = recommendTrainingDuration(
      packageId: _packageId,
      hadIsometricWithTrainer: _hadTrainer,
      assessment: _reflexProfileSkipped ? null : assessment,
    ).weeks;
  }

  Future<void> _confirm() async {
    setState(() => _saving = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final enrollmentId = await createEnrollment(
        db: ref.read(databaseProvider),
        syncService: ref.read(syncServiceProvider),
        userId: userId,
        subjectProfileId: ref.read(selectedSubjectProfileProvider)?.id,
        packageId: _packageId,
        durationWeeks: _selectedWeeks,
      );
      final assessment =
          ref.read(latestReflexProfileForSelectedSubjectProvider).valueOrNull;
      final recommendation = recommendTrainingDuration(
        packageId: _packageId,
        hadIsometricWithTrainer: _hadTrainer,
        assessment: _reflexProfileSkipped ? null : assessment,
      );

      await createIntakeAssessment(
        db: ref.read(databaseProvider),
        syncService: ref.read(syncServiceProvider),
        enrollmentId: enrollmentId,
        hadIsometricWithTrainer: _hadTrainer,
        recommendedDurationWeeks: recommendation.weeks,
        userAcceptedRecommendation: _selectedWeeks == recommendation.weeks,
        finalDurationWeeks: _selectedWeeks,
        entryPoints: ref.read(entryPointsProvider),
      );

      // Update the selected package so the dashboard shows this enrollment
      ref.read(selectedPackageIdProvider.notifier).select(_packageId);

      if (mounted) context.go(Routes.dashboard);
    } catch (_) {
      if (mounted) {
        showErrorSnackBar(context, AppLocalizations.of(context).errorGeneric);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final assessment =
        ref.watch(latestReflexProfileForSelectedSubjectProvider).valueOrNull;
    final recommendation = recommendTrainingDuration(
      packageId: _packageId,
      hadIsometricWithTrainer: _hadTrainer,
      assessment: _reflexProfileSkipped ? null : assessment,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.adjustDuration)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.durationRecommendation(_selectedWeeks),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.daysCount(_selectedWeeks * 7),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _RecommendationInfo(
                text: _recommendationText(recommendation),
              ),
              if (recommendation.usedAssessment &&
                  recommendation.consideredPercents.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ReflexTendencyList(recommendation: recommendation),
              ],
              const SizedBox(height: 28),
              if (_showManualAdjust) ...[
                Slider(
                  value: _selectedWeeks.toDouble(),
                  min: 4,
                  max: 8,
                  divisions: 4,
                  label: l10n.weeksCount(_selectedWeeks),
                  onChanged: (v) => setState(() => _selectedWeeks = v.round()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l10n.weeksCount(4),
                        style: Theme.of(context).textTheme.bodySmall),
                    Text(l10n.weeksCount(8),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showManualAdjust = true),
                  icon: const Icon(Icons.tune_outlined),
                  label: const Text('Dauer anpassen'),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: _saving ? null : _confirm,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_showManualAdjust
                        ? l10n.confirm
                        : 'Empfehlung übernehmen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _recommendationText(TrainingDurationRecommendation recommendation) {
    if (!recommendation.usedAssessment) {
      return 'Du hast das Reflexprofil übersprungen oder es liegt für dieses Profil noch keine Auswertung vor. Die Empfehlung nutzt deshalb die Standardlogik anhand deiner Angabe zum isometrischen Partnertraining.';
    }
    final range =
        recommendation.hadIsometricWithTrainer ? '4 bis 6' : '6 bis 8';
    if (_packageId == 'moro') {
      return 'Diese Empfehlung basiert auf deiner persönlichen Reflexprofil-Auswertung.\n\nFür das Moro-Paket betrachten wir sowohl Moro als auch FLR, weil beide in dieser Auswertung relevant sind. Der stärkere Hinweis liegt bei ${_formatPercent(recommendation.strongestPercent)} und bestimmt die Dauerstufe.\n\nDa du ${recommendation.hadIsometricWithTrainer ? 'bereits' : 'noch nicht'} isometrisches Partnertraining mit einer Fachperson gemacht hast, verwenden wir den Empfehlungsbereich $range Wochen. Du kannst die Empfehlung übernehmen oder die Dauer manuell anpassen.';
    }
    return 'Diese Empfehlung basiert auf deiner persönlichen Reflexprofil-Auswertung. Aufgrund deiner ermittelten Reflex-Tendenz empfehlen wir für dieses Paket eine Dauer von ${recommendation.weeks} Wochen.\n\nDa du ${recommendation.hadIsometricWithTrainer ? 'bereits' : 'noch nicht'} isometrisches Partnertraining mit einer Fachperson gemacht hast, verwenden wir den Empfehlungsbereich $range Wochen.';
  }
}

class _ReflexTendencyList extends StatelessWidget {
  const _ReflexTendencyList({required this.recommendation});

  final TrainingDurationRecommendation recommendation;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final reflex in recommendation.consideredReflexes)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${_reflexLabel(reflex)}-Tendenz: ${_formatPercent(recommendation.consideredPercents[reflex])}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            if (recommendation.consideredReflexes.length > 1)
              Text(
                'Für die Dauer zählt der stärkere Hinweis.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

String _formatPercent(double? percent) {
  if (percent == null) return 'keine ausreichenden Daten';
  final rounded = percent.roundToDouble() == percent
      ? percent.toStringAsFixed(0)
      : percent.toStringAsFixed(1);
  return '$rounded%';
}

String _reflexLabel(PrimitiveReflex reflex) => switch (reflex) {
      PrimitiveReflex.moro => 'Moro',
      PrimitiveReflex.flr => 'FLR',
      PrimitiveReflex.spinalGalant => 'Spinaler Galant',
      PrimitiveReflex.tlr => 'TLR',
      PrimitiveReflex.atnr => 'ATNR',
      PrimitiveReflex.stnr => 'STNR',
      PrimitiveReflex.babkin => 'Babkin',
      PrimitiveReflex.palmar => 'Palmar',
      PrimitiveReflex.plantar => 'Plantar',
      PrimitiveReflex.rootingSucking => 'Such-Saug',
      PrimitiveReflex.babinski => 'Babinski',
      PrimitiveReflex.landau => 'Landau',
      _ => reflex.name,
    };

class _RecommendationInfo extends StatelessWidget {
  const _RecommendationInfo({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
