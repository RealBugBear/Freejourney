import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/training/training_feedback_settings.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import '../../domain/session/session_orchestrator.dart';
import '../widgets/exercise_motion_visualizer.dart';
import '../widgets/rep_segments_widget.dart';

/// State-driven active movement UI.
///
/// The widget deliberately owns no clock, animation controller or completion
/// logic. Every value is a projection of [TrainingSessionState].
class ImmersiveExerciseScreen extends StatelessWidget {
  const ImmersiveExerciseScreen({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.isRoutineMode,
    required this.state,
    required this.sessionProgress,
    required this.currentBeat,
    required this.beatsInCurrentStep,
    required this.tempoSeconds,
    required this.feedbackMode,
    required this.reducedMotion,
    required this.onPause,
    required this.onResume,
    required this.onSlower,
    required this.onFaster,
    required this.onCycleFeedback,
    required this.onRepeatInstruction,
    required this.onEndSession,
  });

  final Exercise exercise;
  final int exerciseIndex;
  final int totalExercises;
  final bool isRoutineMode;
  final TrainingSessionState state;
  final double sessionProgress;
  final int currentBeat;
  final int beatsInCurrentStep;
  final double tempoSeconds;
  final TrainingFeedbackMode feedbackMode;
  final bool reducedMotion;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onSlower;
  final VoidCallback onFaster;
  final VoidCallback onCycleFeedback;
  final VoidCallback onRepeatInstruction;
  final VoidCallback onEndSession;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context);
    final remainingSeconds =
        (state.remaining.inMilliseconds / 1000).ceil().clamp(0, 999);
    final action = _currentAction(context, locale);
    final side = _sideLabel(context);
    final isRecovery = _effectiveStage == TrainingSessionStage.recovery;
    final completedReps =
        isRecovery ? state.repetitionIndex + 1 : state.repetitionIndex;
    final movementProgress =
        isRecovery ? 1.0 : state.stepProgress.clamp(0.0, 1.0);

    return ColoredBox(
      color: AppColors.backgroundDark,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(14) >= 21;
            final landscape = constraints.maxWidth >= 720 &&
                constraints.maxWidth > constraints.maxHeight &&
                !largeText;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    const SizedBox(height: 12),
                    Semantics(
                      label: l10n.trainingProgressSemantics(
                        exerciseIndex + 1,
                        totalExercises,
                      ),
                      value:
                          '${(sessionProgress * 100).round().clamp(0, 100)}%',
                      child: LinearProgressIndicator(
                        value: sessionProgress.clamp(0.0, 1.0),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(999),
                        backgroundColor: Colors.white12,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (landscape)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _visual(
                              context,
                              movementProgress: movementProgress,
                              isRecovery: isRecovery,
                            ),
                          ),
                          const SizedBox(width: 32),
                          Expanded(
                            child: _status(
                              context,
                              action: action,
                              side: side,
                              remainingSeconds: remainingSeconds,
                              completedReps: completedReps,
                              movementProgress: movementProgress,
                            ),
                          ),
                        ],
                      )
                    else ...[
                      _visual(
                        context,
                        movementProgress: movementProgress,
                        isRecovery: isRecovery,
                      ),
                      const SizedBox(height: 18),
                      _status(
                        context,
                        action: action,
                        side: side,
                        remainingSeconds: remainingSeconds,
                        completedReps: completedReps,
                        movementProgress: movementProgress,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _controls(context),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.trainingExerciseOfTotal(
            exerciseIndex + 1,
            totalExercises,
          ),
          style: const TextStyle(
            color: AppColors.primaryLight,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          exercise.title(Localizations.localeOf(context).languageCode),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
    final modePill = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          isRoutineMode ? l10n.routineMode : l10n.tutorialMode,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final largeText = MediaQuery.textScalerOf(context).scale(14) >= 21;
        if (largeText || constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 10),
              modePill,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title),
            const SizedBox(width: 12),
            modePill,
          ],
        );
      },
    );
  }

  Widget _visual(
    BuildContext context, {
    required double movementProgress,
    required bool isRecovery,
  }) {
    return Center(
      child: SizedBox.square(
        dimension: 236,
        child: _supportsMoroVisualizer
            ? ExerciseMotionVisualizer(
                exerciseId: exercise.id,
                phaseIndex:
                    isRecovery && exercise.rhythmType == RhythmType.holdRest
                        ? 1
                        : state.phaseIndex,
                repetitionIndex: state.repetitionIndex,
                phaseProgress: movementProgress,
                reducedMotion: reducedMotion,
              )
            : Semantics(
                label: exercise.title(
                  Localizations.localeOf(context).languageCode,
                ),
                image: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.accessibility_new_rounded,
                    size: 96,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _status(
    BuildContext context, {
    required String action,
    required String side,
    required int remainingSeconds,
    required int completedReps,
    required double movementProgress,
  }) {
    final l10n = AppLocalizations.of(context);
    final phaseCount = exercise.phases.isEmpty ? 1 : exercise.phases.length;

    return Semantics(
      liveRegion: true,
      container: true,
      label: [
        action,
        l10n.trainingRepetitionOf(
          (state.repetitionIndex + 1).clamp(1, exercise.repetitions),
          exercise.repetitions,
        ),
        l10n.trainingTimeRemaining(remainingSeconds),
        if (side.isNotEmpty) side,
      ].join('. '),
      child: Column(
        children: [
          if (side.isNotEmpty)
            Text(
              side,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.primaryLight,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          Text(
            action.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$remainingSeconds',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 64,
              height: 1,
              fontFeatures: [FontFeature.tabularFigures()],
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.trainingTimeRemaining(remainingSeconds),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 18),
          if (exercise.phases.isNotEmpty)
            Text(
              l10n.trainingPhaseOf(state.phaseIndex + 1, phaseCount),
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          const SizedBox(height: 8),
          RepSegmentsWidget(
            totalReps: exercise.repetitions,
            completedReps: completedReps.clamp(0, exercise.repetitions),
            beatProgress: movementProgress,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.trainingRepetitionOf(
              (state.repetitionIndex + 1).clamp(1, exercise.repetitions),
              exercise.repetitions,
            ),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (_effectiveStage == TrainingSessionStage.activeMovement &&
              beatsInCurrentStep > 0) ...[
            const SizedBox(height: 6),
            Text(
              exercise.rhythmType == RhythmType.holdRest
                  ? l10n.trainingSecondsOf(beatsInCurrentStep)
                  : l10n.trainingBeatsOf(beatsInCurrentStep),
              style: const TextStyle(color: Colors.white60, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _controls(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paused = state.isPaused;
    final largeText = MediaQuery.textScalerOf(context).scale(14) >= 21;
    final slowerButton = OutlinedButton(
      onPressed: onSlower,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
      ),
      child: Text(
        l10n.trainingSlower,
        textAlign: TextAlign.center,
      ),
    );
    final tempoIndicator = Semantics(
      label: l10n.trainingTempoAnnouncement(
        tempoSeconds.toStringAsFixed(1),
      ),
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          l10n.trainingSecondsPerBeat(
            tempoSeconds.toStringAsFixed(1),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    final fasterButton = OutlinedButton(
      onPressed: onFaster,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
      ),
      child: Text(
        l10n.trainingFaster,
        textAlign: TextAlign.center,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (largeText) ...[
          tempoIndicator,
          const SizedBox(height: 10),
          slowerButton,
          const SizedBox(height: 10),
          fasterButton,
        ] else
          Row(
            children: [
              Expanded(child: slowerButton),
              const SizedBox(width: 10),
              Expanded(child: tempoIndicator),
              const SizedBox(width: 10),
              Expanded(child: fasterButton),
            ],
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCycleFeedback,
                icon: Icon(_feedbackIcon),
                label: Text(_feedbackLabel(context)),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: paused ? onResume : onPause,
                icon: Icon(
                  paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
                label: Text(paused ? l10n.trainingResume : l10n.trainingPause),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (largeText) ...[
          OutlinedButton.icon(
            onPressed: onRepeatInstruction,
            icon: const Icon(Icons.replay_rounded),
            label: Text(l10n.trainingRepeatInstruction),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onEndSession,
            icon: const Icon(Icons.close_rounded),
            label: Text(l10n.trainingExitTooltip),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ] else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRepeatInstruction,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l10n.trainingRepeatInstruction),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextButton.icon(
                  onPressed: onEndSession,
                  icon: const Icon(Icons.close_rounded),
                  label: Text(l10n.trainingExitTooltip),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.error,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
        if (paused) ...[
          const SizedBox(height: 14),
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.45),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    l10n.trainingInterruptedTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.trainingInterruptedBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  TrainingSessionStage? get _effectiveStage =>
      state.isPaused ? state.resumeStage : state.stage;

  String _currentAction(BuildContext context, String locale) {
    final l10n = AppLocalizations.of(context);
    if (state.isPaused) return l10n.trainingInterruptedTitle;
    if (_effectiveStage == TrainingSessionStage.recovery) {
      return state.requiresSideSwitch
          ? (exercise.halfwaySwitch
              ? l10n.trainingSwitchArmCross
              : l10n.trainingSwitchCue)
          : l10n.trainingRest;
    }
    if (exercise.rhythmType == RhythmType.phased &&
        exercise.phases.isNotEmpty) {
      return exercise.phases[state.phaseIndex].label(locale);
    }
    final cue = locale == 'en' ? exercise.holdCueEn : exercise.holdCueDe;
    return cue.isEmpty ? l10n.trainingHoldCueUpper : cue;
  }

  String _sideLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (exercise.halfwaySwitch) {
      final number = state.repetitionIndex < exercise.repetitions ~/ 2 ? 1 : 2;
      return l10n.trainingArmCrossNumber(number);
    }
    if (exercise.hasRepSwitch) {
      return l10n.trainingSideNumber((state.repetitionIndex % 2) + 1);
    }
    return '';
  }

  String _feedbackLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (feedbackMode) {
      TrainingFeedbackMode.voiceAndCues => l10n.trainingFeedbackSounds,
      TrainingFeedbackMode.hapticOnly => l10n.trainingFeedbackHaptics,
      TrainingFeedbackMode.silent => l10n.trainingFeedbackSilent,
    };
  }

  IconData get _feedbackIcon => switch (feedbackMode) {
        TrainingFeedbackMode.voiceAndCues => Icons.volume_up_outlined,
        TrainingFeedbackMode.hapticOnly => Icons.vibration_rounded,
        TrainingFeedbackMode.silent => Icons.volume_off_outlined,
      };

  bool get _supportsMoroVisualizer => const {
        'moro_ex1',
        'moro_ex2',
        'moro_ex3',
        'moro_ex4',
        'moro_ex5',
        'moro_ex6',
        'moro_ex7',
      }.contains(exercise.id);
}
