import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import '../../domain/session/session_orchestrator.dart';
import 'exercise_image_widget.dart';
import 'exercise_video_widget.dart';

/// Pure presentation for an exercise announcement or preparation countdown.
///
/// Time belongs exclusively to [SessionOrchestrator]. This widget intentionally
/// owns no timer and has no full-screen tap target.
class ExerciseTransitionWidget extends StatelessWidget {
  const ExerciseTransitionWidget({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.isRoutineMode,
    required this.locale,
    required this.isDuo,
    required this.stage,
    required this.remainingSeconds,
    required this.voiceGuidanceAvailable,
    this.compactGuidance = false,
    required this.onConfirmReady,
    required this.onStartNow,
    required this.onRepeatInstruction,
    this.onEndSession,
  });

  final Exercise exercise;
  final int exerciseIndex;
  final int totalExercises;
  final bool isRoutineMode;
  final String locale;
  final bool isDuo;
  final TrainingSessionStage stage;
  final int remainingSeconds;
  final bool voiceGuidanceAvailable;
  final bool compactGuidance;
  final VoidCallback onConfirmReady;
  final VoidCallback onStartNow;
  final VoidCallback onRepeatInstruction;
  final VoidCallback? onEndSession;

  bool get _isPreparing => stage == TrainingSessionStage.preparation;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.backgroundDark,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final landscape = constraints.maxWidth >= 720 &&
                constraints.maxWidth > constraints.maxHeight;
            if (landscape) {
              return Row(
                children: [
                  Expanded(child: _mediaPane(context)),
                  const VerticalDivider(width: 1, color: Colors.white12),
                  Expanded(child: _instructionPane(context)),
                ],
              );
            }
            return Column(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.32,
                  ),
                  child: _mediaPane(context),
                ),
                Expanded(child: _instructionPane(context)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _mediaPane(BuildContext context) {
    final hasVideo = exercise.videoUrl?.isNotEmpty == true ||
        exercise.videoPath?.isNotEmpty == true;
    return Stack(
      fit: StackFit.expand,
      children: [
        ExerciseImageWidget(
          exercise: exercise,
          isDuo: isDuo,
          fit: BoxFit.contain,
        ),
        if (hasVideo && !isRoutineMode)
          Positioned(
            right: 16,
            bottom: 16,
            child: FilledButton.tonalIcon(
              onPressed: () => _showVideo(context),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(AppLocalizations.of(context).trainingVideo),
            ),
          ),
      ],
    );
  }

  Widget _instructionPane(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final position = exercise.positionInstructionsFor(locale, duo: isDuo);
    final movement = exercise.movementInstructionsFor(locale, duo: isDuo);
    final hints = exercise.hints(locale) ?? const <String>[];

    return Scrollbar(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.trainingExerciseOfTotal(exerciseIndex + 1, totalExercises),
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Semantics(
            header: true,
            child: Text(
              exercise.title(locale),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                height: 1.12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(l10n.trainingRepetitionsAbbreviated(exercise.repetitions)),
              _chip(
                exercise.rhythmType == RhythmType.holdRest
                    ? l10n.trainingSecondsPerRep(exercise.holdSeconds)
                    : l10n.trainingPhaseOf(1, exercise.phases.length),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (!compactGuidance) ...[
            _labeledCallout(
              title: l10n.trainingOrientationLabel,
              icon: Icons.explore_outlined,
              text: exercise.orientation(locale),
              color: AppColors.primaryLight,
            ),
            const SizedBox(height: 18),
          ],
          _section(context, l10n.trainingPositionLabel, position),
          const SizedBox(height: 18),
          _section(context, l10n.exerciseMovement, movement),
          if (hints.isNotEmpty && !compactGuidance) ...[
            const SizedBox(height: 18),
            _section(context, l10n.trainingHintTitle, hints),
          ],
          const SizedBox(height: 20),
          _labeledCallout(
            title: isRoutineMode
                ? l10n.trainingRoutineCueLabel
                : l10n.trainingHintTitle,
            icon: Icons.graphic_eq_rounded,
            text: isRoutineMode
                ? exercise.routineCue(locale)
                : exercise.executionGuide(locale),
            color: AppColors.primaryLight,
          ),
          if (exercise.breathing(locale) case final breathing?) ...[
            const SizedBox(height: 12),
            _labeledCallout(
              title: l10n.trainingBreathingLabel,
              icon: Icons.air_rounded,
              text: breathing,
              color: AppColors.success,
            ),
          ],
          const SizedBox(height: 12),
          _labeledCallout(
            title: l10n.trainingSafetyLabel,
            icon: Icons.health_and_safety_outlined,
            text: exercise.safetyNote(locale),
            color: AppColors.warning,
          ),
          if (isRoutineMode && !voiceGuidanceAvailable) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: _labeledCallout(
                title: l10n.trainingAudioContentUnavailableTitle,
                icon: Icons.record_voice_over_outlined,
                text: l10n.trainingAudioContentUnavailableBody,
                color: AppColors.warning,
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_isPreparing)
            _preparationActions(context)
          else if (isRoutineMode)
            _routineAnnouncementActions(context)
          else
            _learningActions(context),
          if (onEndSession case final endSession?) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: endSession,
              icon: const Icon(Icons.close_rounded),
              label: Text(l10n.trainingExitTooltip),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _learningActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            l10n.trainingReadyForMovement,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.trainingReadyBody,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: onConfirmReady,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(l10n.trainingStartExercise),
          ),
        ),
      ],
    );
  }

  Widget _routineAnnouncementActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (voiceGuidanceAvailable)
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.trainingAnnouncementPlaying,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRepeatInstruction,
          icon: const Icon(Icons.replay_rounded),
          label: Text(l10n.trainingRepeatInstruction),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }

  Widget _preparationActions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      liveRegion: true,
      label: l10n.trainingPreparationCountdown(remainingSeconds),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.trainingPreparationCountdown(remainingSeconds),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: onStartNow,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(l10n.trainingStartNow),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    BuildContext context,
    String title,
    List<String> items,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: 6,
                      height: 6,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _labeledCallout({
    required String title,
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVideo(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.72,
          child: ExerciseVideoWidget(
            exercise: exercise,
            onReady: () {},
          ),
        ),
      ),
    );
  }
}
