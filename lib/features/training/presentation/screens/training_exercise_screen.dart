import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/adaptive_tempo_settings.dart';
import '../../../../core/training/handsfree_setup_settings.dart';
import '../../../../core/training/training_feedback_settings.dart';
import '../../../../core/training/training_tempo_defaults.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import '../widgets/animated_progress_bar.dart';
import '../widgets/premium_glassmorphic_card.dart';
import '../widgets/rhythm_visualizer.dart';
import '../widgets/parallel_lines_visualizer.dart';
import '../widgets/arc_swap_visualizer.dart';
import '../widgets/exercise_image_widget.dart';

class TrainingExerciseScreen extends ConsumerStatefulWidget {
  final Exercise exercise;
  final VoidCallback onComplete;
  final bool isLastExercise;
  final bool routineMode;
  final bool deferAutoplayForAnnouncement;

  const TrainingExerciseScreen({
    super.key,
    required this.exercise,
    required this.onComplete,
    this.isLastExercise = false,
    this.routineMode = false,
    this.deferAutoplayForAnnouncement = false,
  });

  @override
  ConsumerState<TrainingExerciseScreen> createState() =>
      _TrainingExerciseScreenState();
}

class _TrainingExerciseScreenState
    extends ConsumerState<TrainingExerciseScreen> {
  late double _intervalSeconds;
  bool _enableRhythmAudio = false;
  TrainingFeedbackMode _feedbackMode = TrainingFeedbackMode.voiceAndCues;
  bool _isAdaptiveTempo = false;
  bool _isCompleting = false;
  static const double _stepSizeSeconds = 0.5;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise.exerciseNumber;
    _intervalSeconds = defaultTempoForExercise(ex);
    _loadUserTrainingSettings();
  }

  @override
  void didUpdateWidget(covariant TrainingExerciseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.exerciseNumber != widget.exercise.exerciseNumber) {
      _intervalSeconds =
          defaultTempoForExercise(widget.exercise.exerciseNumber);
      _isAdaptiveTempo = false;
      _loadUserTrainingSettings();
    }
  }

  Future<void> _loadUserTrainingSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = TrainingFeedbackSettings.feedbackMode(prefs);
    final defaultTempo =
        HandsfreeSetupSettings.defaultTempoSecondsOrNull(prefs);
    final adaptiveTempo = AdaptiveTempoSettings.tempoForExerciseOrNull(
      prefs,
      widget.exercise.exerciseNumber,
    );
    final resolvedTempo = resolveInitialTempoSeconds(
      exerciseNumber: widget.exercise.exerciseNumber,
      persistedTempoSeconds: adaptiveTempo ?? defaultTempo,
    );
    if (!mounted) return;
    setState(() {
      _feedbackMode = mode;
      _enableRhythmAudio = mode == TrainingFeedbackMode.voiceAndCues;
      _intervalSeconds = resolvedTempo;
      _isAdaptiveTempo = adaptiveTempo != null;
    });
  }

  Future<void> _completeAndPersistTempo() async {
    if (_isCompleting) return;
    setState(() => _isCompleting = true);
    final prefs = await SharedPreferences.getInstance();
    try {
      await AdaptiveTempoSettings.saveTempoForExercise(
        prefs,
        exerciseNumber: widget.exercise.exerciseNumber,
        tempoSeconds: _intervalSeconds,
      );
      if (!mounted) return;
      widget.onComplete();
    } finally {
      if (mounted) {
        setState(() => _isCompleting = false);
      }
    }
  }

  Future<void> _setFeedbackMode(TrainingFeedbackMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await TrainingFeedbackSettings.setFeedbackMode(prefs, mode);
    if (!mounted) return;
    setState(() {
      _feedbackMode = mode;
      _enableRhythmAudio = mode == TrainingFeedbackMode.voiceAndCues;
    });
    _announceForAccessibility(
      AppLocalizations.of(context).trainingFeedbackModeActivated(
        _feedbackLabel(mode),
      ),
    );
  }

  TrainingFeedbackMode _nextFeedbackMode(TrainingFeedbackMode current) {
    return switch (current) {
      TrainingFeedbackMode.voiceAndCues => TrainingFeedbackMode.hapticOnly,
      TrainingFeedbackMode.hapticOnly => TrainingFeedbackMode.silent,
      TrainingFeedbackMode.silent => TrainingFeedbackMode.voiceAndCues,
    };
  }

  String _feedbackLabel(TrainingFeedbackMode mode) {
    final l10n = AppLocalizations.of(context);
    return switch (mode) {
      TrainingFeedbackMode.voiceAndCues => l10n.trainingFeedbackVoice,
      TrainingFeedbackMode.hapticOnly => l10n.trainingFeedbackHaptics,
      TrainingFeedbackMode.silent => l10n.trainingFeedbackSilent,
    };
  }

  IconData _feedbackIcon(TrainingFeedbackMode mode) {
    return switch (mode) {
      TrainingFeedbackMode.voiceAndCues => Icons.record_voice_over_outlined,
      TrainingFeedbackMode.hapticOnly => Icons.vibration_outlined,
      TrainingFeedbackMode.silent => Icons.volume_off_outlined,
    };
  }

  void _changeTempo({
    required double delta,
    required double min,
    required double max,
  }) {
    setState(() {
      _intervalSeconds =
          ((_intervalSeconds + delta) / _stepSizeSeconds).round() *
              _stepSizeSeconds;
      _intervalSeconds = _intervalSeconds.clamp(min, max);
    });
    HapticFeedback.selectionClick();
    _announceForAccessibility(
      AppLocalizations.of(context).trainingTempoAnnouncement(
        _formattedTempo,
      ),
    );
  }

  String get _formattedTempo => _intervalSeconds.toStringAsFixed(
        _intervalSeconds.truncateToDouble() == _intervalSeconds ? 0 : 1,
      );

  void _announceForAccessibility(String message) {
    if (!mounted) return;
    SemanticsService.announce(message, Directionality.of(context));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final exercise = widget.exercise;
    final isLastExercise = widget.isLastExercise;
    final isRoutineMode = widget.routineMode;

    final exId = exercise.id;
    final isLongBreathExercise = exId == 'ex6' || exId == 'ex7';
    final isEarly = !isLongBreathExercise;
    final min = isEarly ? 1.0 : 2.0;
    final max = isEarly ? 7.0 : 12.0;
    final intervalDuration =
        Duration(milliseconds: (_intervalSeconds * 1000).round());
    final isVeryFastTempo =
        isEarly ? _intervalSeconds <= 1.5 : _intervalSeconds <= 2.5;
    final autoplayDelay = widget.deferAutoplayForAnnouncement &&
            _feedbackMode == TrainingFeedbackMode.voiceAndCues
        ? const Duration(milliseconds: 4500)
        : Duration.zero;
    final reps = isLongBreathExercise ? 6 : 3;

    final visual = switch (exId) {
      'ex3' => ParallelLinesVisualizer(
          moveDuration: intervalDuration,
          holdDuration: const Duration(seconds: 1),
          repetitions: 3,
          simultaneous: false,
          autoplay: true,
        ),
      'ex4' => ParallelLinesVisualizer(
          moveDuration: intervalDuration,
          holdDuration: const Duration(seconds: 1),
          repetitions: 3,
          simultaneous: true,
          autoplay: true,
        ),
      'ex5' => ArcSwapVisualizer(
          interval: intervalDuration,
          holdDuration: const Duration(seconds: 2),
          repetitions: 3,
          autoplay: true,
        ),
      _ => RhythmVisualizer(
          config: RhythmConfig(
            pattern: (exId == 'ex1') ? RhythmPattern.v : RhythmPattern.i,
            interval: intervalDuration,
            repetitions: reps,
            // Stable by exercise id:
            // - ex2: hold at top fixed to 1s
            // - ex6/ex7: holdTop 1s, moveUp 7s, moveDown 3s
            holdTop: (exId == 'ex2' || exId == 'ex6' || exId == 'ex7')
                ? const Duration(seconds: 1)
                : null,
            moveUp: (exId == 'ex6' || exId == 'ex7')
                ? const Duration(seconds: 7)
                : null,
            moveDown: (exId == 'ex6' || exId == 'ex7')
                ? const Duration(seconds: 3)
                : null,
          ),
          enableAudio: _enableRhythmAudio,
          autoplay: true,
          autoplayDelay: autoplayDelay,
          height: 180,
        ),
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
          tooltip: l10n.back,
        ),
        // Slim progress bar between back and close buttons
        title: Semantics(
          label: l10n.trainingProgressSemantics(
            (exercise.exerciseNumber - 1) * 3 + 3,
            21,
          ),
          child: AnimatedProgressBar(
            currentStep: (exercise.exerciseNumber - 1) * 3 + 3,
            totalSteps: 21,
            compact: true,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showCancelDialog(context),
            tooltip: l10n.trainingExitTooltip,
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.3),
              theme.colorScheme.secondaryContainer.withOpacity(0.2),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Timer Display - Compact and elegant
                        Semantics(
                          label: l10n.trainingExerciseDurationSemantics(
                            exercise.durationSeconds,
                            exercise.repetitions,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 24,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${exercise.durationSeconds}s',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                l10n.trainingRepeatCount(exercise.repetitions),
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Semantics(
                          label: l10n.trainingAnimationSemantics,
                          child: PremiumGlassmorphicCard(
                            blur: 18,
                            opacity: 0.10,
                            borderRadius: 20,
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                visual,
                                if (isRoutineMode) ...[
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: AspectRatio(
                                      aspectRatio: 16 / 9,
                                      child: ExerciseImageWidget(
                                          exercise: exercise,
                                          fit: BoxFit.cover),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.trainingAutoplayHint,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    l10n.trainingTempoFeedbackSummary(
                                      _formattedTempo,
                                      _feedbackLabel(_feedbackMode),
                                    ),
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                if (isVeryFastTempo && !isRoutineMode) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.orange.withOpacity(0.28),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange[700],
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            l10n.trainingFastTempoWarning,
                                            style: theme.textTheme.labelMedium
                                                ?.copyWith(
                                              color: Colors.orange[900],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_isAdaptiveTempo &&
                                    !isVeryFastTempo &&
                                    !isRoutineMode) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.trainingAdaptiveSuggestion,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!isRoutineMode) ...[
                          // Execution Guide - HERO! Main focus
                          PremiumGlassmorphicCard(
                            blur: 25,
                            opacity: 0.15,
                            borderRadius: 20,
                            padding: const EdgeInsets.all(28.0),
                            child: Center(
                              child: Text(
                                exercise.executionGuide(
                                  Localizations.localeOf(context).languageCode,
                                ),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  height: 1.8,
                                  fontWeight: FontWeight.w400,
                                  fontSize: 22,
                                  letterSpacing: 0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 66,
                          child: Semantics(
                            button: true,
                            label: l10n.trainingTempoSlowerSemantics,
                            value: l10n.trainingSecondsValue(_formattedTempo),
                            child: FilledButton.tonalIcon(
                              onPressed: _intervalSeconds >= max
                                  ? null
                                  : () => _changeTempo(
                                        delta: _stepSizeSeconds,
                                        min: min,
                                        max: max,
                                      ),
                              icon: const Icon(Icons.remove, size: 24),
                              label: Text(
                                l10n.trainingSlower,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 66,
                          child: Semantics(
                            button: true,
                            label: l10n.trainingTempoFasterSemantics,
                            value: l10n.trainingSecondsValue(_formattedTempo),
                            child: FilledButton.tonalIcon(
                              onPressed: _intervalSeconds <= min
                                  ? null
                                  : () => _changeTempo(
                                        delta: -_stepSizeSeconds,
                                        min: min,
                                        max: max,
                                      ),
                              icon: const Icon(Icons.add, size: 24),
                              label: Text(
                                l10n.trainingFaster,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 66,
                          child: Semantics(
                            button: true,
                            label: l10n.trainingFeedbackChangeSemantics,
                            value: _feedbackLabel(_feedbackMode),
                            child: FilledButton.tonalIcon(
                              onPressed: () {
                                _setFeedbackMode(
                                  _nextFeedbackMode(_feedbackMode),
                                );
                                HapticFeedback.selectionClick();
                              },
                              icon:
                                  Icon(_feedbackIcon(_feedbackMode), size: 24),
                              label: Text(
                                _feedbackLabel(_feedbackMode),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.trainingControlsHint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.62),
                  ),
                ),
                const SizedBox(height: 12),
                // Always visible, one-handed primary action.
                SizedBox(
                  width: double.infinity,
                  height: 78,
                  child: Semantics(
                    button: true,
                    label: isLastExercise
                        ? l10n.trainingCompleteExercise
                        : l10n.trainingContinueNextExercise,
                    child: FilledButton(
                      onPressed:
                          _isCompleting ? null : _completeAndPersistTempo,
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 4,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _isCompleting
                              ? l10n.loading
                              : isLastExercise
                                  ? l10n.trainingCompleteExercise
                                  : l10n.trainingContinueNextExercise,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.trainingAbortTitle),
        content: Text(l10n.trainingAbortBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.trainingAbortStay),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close training
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n.trainingAbortConfirm),
          ),
        ],
      ),
    );
  }
}
