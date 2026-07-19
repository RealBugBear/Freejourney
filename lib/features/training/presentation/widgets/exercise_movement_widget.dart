import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/localized_content.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import '../services/training_feedback_service.dart';

class ExerciseMovementWidget extends ConsumerStatefulWidget {
  final Exercise exercise;
  final int exerciseIndex;
  final int totalExercises;
  final VoidCallback onComplete;

  const ExerciseMovementWidget({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.onComplete,
  });

  @override
  ConsumerState<ExerciseMovementWidget> createState() =>
      _ExerciseMovementWidgetState();
}

// ── State machine phases ───────────────────────────────────────────────────────

enum _TickPhase { holding, resting }

class _ExerciseMovementWidgetState extends ConsumerState<ExerciseMovementWidget>
    with SingleTickerProviderStateMixin {
  // Initialized with a silent no-op default; replaced in _initFeedback.
  TrainingFeedbackService _feedback = TrainingFeedbackService(
    mode: TrainingFeedbackMode.silent,
    locale: 'de',
  );
  late AnimationController _pulseController;
  Timer? _timer;

  // Shared state
  int _currentRep = 1; // 1-based

  // holdRest state
  _TickPhase _phase = _TickPhase.holding;
  int _secondsLeft = 0;

  // phased state
  int _phaseIndex = 0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Feedback service created after first frame so we have context/locale
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFeedback());
  }

  Future<void> _initFeedback() async {
    if (!mounted) return;
    final settings = ref.read(settingsProvider);
    final locale = settings.languageCode;
    _feedback =
        TrainingFeedbackService(mode: settings.feedbackMode, locale: locale);
    await _feedback.init();
    if (!mounted) return;
    _feedback.hapticHeavy();
    _startRep(_currentRep, isFirstRep: true);
  }

  // ── Rep / phase start ────────────────────────────────────────────────────────

  void _startRep(int rep, {bool isFirstRep = false}) {
    if (!mounted) return;
    final ex = widget.exercise;
    if (ex.rhythmType == RhythmType.phased) {
      _phaseIndex = 0;
      _startPhasedPhase(isFirst: isFirstRep);
    } else {
      _phase = _TickPhase.holding;
      setState(() => _secondsLeft = ex.holdSeconds);
      _feedback.speak(
        pickLocalized(_feedback.locale, de: ex.holdCueDe, en: ex.holdCueEn),
      );
      _feedback.hapticLight();
      _startTick();
    }
  }

  void _startPhasedPhase({bool isFirst = false}) {
    if (!mounted) return;
    final phase = widget.exercise.phases[_phaseIndex];
    setState(() => _secondsLeft = phase.durationSeconds);
    if (!isFirst || _phaseIndex > 0) {
      // Always announce each phase label
    }
    _feedback.speak(phase.label(_feedback.locale));
    _feedback.hapticLight();
    _startTick();
  }

  // ── Tick ─────────────────────────────────────────────────────────────────────

  void _startTick() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        _onPhaseEnd();
      }
    });
  }

  void _onPhaseEnd() {
    final ex = widget.exercise;

    if (ex.rhythmType == RhythmType.phased) {
      _phaseIndex++;
      if (_phaseIndex < ex.phases.length) {
        _startPhasedPhase();
      } else {
        _onRepComplete();
      }
    } else {
      // holdRest
      if (_phase == _TickPhase.holding) {
        _phase = _TickPhase.resting;
        setState(() => _secondsLeft = ex.restSeconds);
        // "Und wieder" announces the next rep coming
        if (_currentRep < ex.repetitions) {
          _feedback.speak(AppLocalizations.of(context).trainingAndAgain);
        }
        _feedback.hapticMedium();
        _startTick();
      } else {
        // rest ended → rep complete
        _onRepComplete();
      }
    }
  }

  void _onRepComplete() {
    final ex = widget.exercise;
    _feedback.hapticMedium();

    if (_currentRep >= ex.repetitions) {
      // All done
      _feedback.hapticHeavy();
      Future.microtask(() {
        if (mounted) widget.onComplete();
      });
      return;
    }

    // Check for halfway switch (e.g. Moro 6+7: "Armkreuz wechseln")
    final halfway = ex.repetitions ~/ 2;
    if (ex.halfwaySwitch && _currentRep == halfway) {
      _feedback.speak(AppLocalizations.of(context).trainingSwitchArmCross);
      _feedback.hapticHeavy();
    } else if (ex.hasRepSwitch) {
      _feedback.speak(AppLocalizations.of(context).trainingSwitchCue);
      _feedback.hapticLight();
    }

    setState(() => _currentRep++);
    _startRep(_currentRep);
  }

  // ── Dispose ──────────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _feedback.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = ref.watch(settingsProvider).languageCode;
    final ex = widget.exercise;

    final (label, phaseProgress, ringColor) = _currentDisplay(ex, locale, l10n);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: exercise counter + rep counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.exerciseIndex + 1} / ${widget.totalExercises}',
                style:
                    TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
              ),
              Text(
                '${l10n.exerciseReps(_currentRep)} / ${ex.repetitions}',
                style:
                    TextStyle(color: AppColors.textSecondaryDark, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Exercise name
          Text(
            ex.title(locale),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),

          // Central rhythm circle
          Expanded(
            child: Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  final scale = 1.0 + _pulseController.value * 0.04;
                  return Transform.scale(scale: scale, child: child);
                },
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress ring
                      CustomPaint(
                        size: const Size(220, 220),
                        painter: _TimerRingPainter(
                          progress: phaseProgress,
                          color: ringColor,
                          trackColor: Colors.white12,
                        ),
                      ),
                      // Inner content
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Phase label
                          Text(
                            label,
                            style: TextStyle(
                              color: ringColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Countdown
                          Text(
                            '$_secondsLeft',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 56,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -2,
                            ),
                          ),
                          Text(
                            l10n.trainingSecondsAbbreviation,
                            style: TextStyle(
                              color: AppColors.textSecondaryDark,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Execution guide
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              ex.executionGuide(locale),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),

          // Skip / done button
          TextButton(
            onPressed: () {
              _timer?.cancel();
              widget.onComplete();
            },
            child: Text(
              l10n.done,
              style: TextStyle(color: AppColors.textSecondaryDark),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns (label, phaseProgress 0..1, ringColor) for the current state.
  (String, double, Color) _currentDisplay(
    Exercise ex,
    String locale,
    AppLocalizations l10n,
  ) {
    if (ex.rhythmType == RhythmType.phased) {
      if (_phaseIndex >= ex.phases.length) {
        return ('', 1.0, AppColors.primary);
      }
      final phase = ex.phases[_phaseIndex];
      final progress =
          1 - (_secondsLeft / phase.durationSeconds).clamp(0.0, 1.0);
      return (phase.label(locale), progress, AppColors.primary);
    }

    // holdRest
    if (_phase == _TickPhase.holding) {
      final progress = 1 - (_secondsLeft / ex.holdSeconds).clamp(0.0, 1.0);
      final label =
          pickLocalized(locale, de: ex.holdCueDe, en: ex.holdCueEn);
      return (label, progress, AppColors.primary);
    } else {
      // resting
      final progress = 1 - (_secondsLeft / ex.restSeconds).clamp(0.0, 1.0);
      return (l10n.trainingRest, progress, AppColors.textSecondaryDark);
    }
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    const strokeWidth = 8.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TimerRingPainter old) =>
      old.progress != progress || old.color != color;
}
