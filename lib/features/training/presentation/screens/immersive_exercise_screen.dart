import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/adaptive_tempo_settings.dart';
import '../../../../core/training/in_app_music_settings.dart';
import '../../../../core/training/training_feedback_settings.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/exercise.dart';
import '../../domain/services/audio_announcement_service.dart';
import '../../domain/services/metronome_service.dart';
import '../services/in_app_music_service.dart';
import '../widgets/music_picker_sheet.dart';
import '../widgets/pendulum_animation_widget.dart';
import '../widgets/rep_segments_widget.dart';

class ImmersiveExerciseScreen extends StatefulWidget {
  final Exercise exercise;
  final int exerciseIndex; // 0-based
  final int totalExercises;
  final bool isRoutineMode;
  final VoidCallback onComplete;

  const ImmersiveExerciseScreen({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.totalExercises,
    required this.isRoutineMode,
    required this.onComplete,
  });

  @override
  State<ImmersiveExerciseScreen> createState() =>
      _ImmersiveExerciseScreenState();
}

class _ImmersiveExerciseScreenState extends State<ImmersiveExerciseScreen> {
  MetronomeService? _metronome;
  final _subs = <StreamSubscription>[];

  int _currentBeat = 0;
  int _currentRepIndex = 0;
  int _phaseCueIndex = 0;
  bool _isResting = false;
  bool _halfwayAnnounce = false;
  bool _isPaused = false;
  bool _musicActive = false;

  double _tempoSeconds = 1.0;
  int _holdSecondsOverride = 7;
  TrainingFeedbackMode _feedbackMode = TrainingFeedbackMode.voiceAndCues;
  static const double _stepSize = 0.5;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndStart();
  }

  Future<void> _loadSettingsAndStart() async {
    final prefs = await SharedPreferences.getInstance();
    final feedback = TrainingFeedbackSettings.feedbackMode(prefs);
    final persistedTempo = AdaptiveTempoSettings.tempoForExerciseOrNull(
        prefs, widget.exercise.sequenceNumber);
    final musicTrack = InAppMusicSettings.selectedTrack(prefs);

    if (!mounted) return;
    setState(() {
      _feedbackMode = feedback;
      _tempoSeconds = persistedTempo ?? 1.0;
      _musicActive = musicTrack != null;
      _holdSecondsOverride = widget.exercise.holdSeconds;
    });
    if (musicTrack != null) {
      unawaited(InAppMusicService.instance.loadFromPrefs());
    }
    _startMetronome();
  }

  void _startMetronome() {
    // hapticOnly = haptic per beat, no beat audio, structural tones off
    // silent    = no haptic, no beat audio, but structural tones (start/end) on
    // voiceAndCues = full audio
    final enableAudio = _feedbackMode != TrainingFeedbackMode.hapticOnly;
    final enableBeatAudio = _feedbackMode == TrainingFeedbackMode.voiceAndCues;
    final svc = MetronomeService(
      tempoSeconds: _tempoSeconds,
      restDuration: const Duration(seconds: 3),
      enableAudio: enableAudio,
      enableBeatAudio: enableBeatAudio,
    );
    _metronome = svc;
    svc.playStartTone(); // start marker for silent/minimal mode

    _subs.add(svc.beatStream.listen((beat) {
      if (mounted) {
        setState(() {
          _currentBeat = beat;
          _isResting = false;
          _halfwayAnnounce = false;
        });
      }
      if (_feedbackMode == TrainingFeedbackMode.hapticOnly) {
        HapticFeedback.lightImpact();
      }
    }));

    _subs.add(svc.repIndexStream.listen((idx) {
      if (mounted) {
        setState(() {
          _currentRepIndex = idx;
          _phaseCueIndex = 0;
        });
      }
    }));

    _subs.add(svc.repComplete.listen((_) {
      if (!mounted) return;
      final justCompletedRep =
          _currentRepIndex; // 0-based rep that just finished
      final isHalfway = widget.exercise.halfwaySwitch &&
          widget.exercise.repetitions == 6 &&
          justCompletedRep == 2; // rep 3 (0-based index 2)
      setState(() {
        _isResting = true;
        _halfwayAnnounce = isHalfway;
      });
      if (_feedbackMode != TrainingFeedbackMode.silent) {
        HapticFeedback.mediumImpact();
      }
      if (widget.isRoutineMode &&
          _feedbackMode == TrainingFeedbackMode.voiceAndCues &&
          (widget.exercise.hasRepSwitch || isHalfway)) {
        unawaited(AudioAnnouncementService.instance
            .play('sounds/announcements/de/wechsel.mp3'));
      }
    }));

    _subs.add(svc.phaseTransition.listen((_) {
      if (!mounted ||
          !widget.isRoutineMode ||
          _feedbackMode != TrainingFeedbackMode.voiceAndCues ||
          widget.exercise.phases.isEmpty) {
        return;
      }
      final nextPhaseCueIndex = _phaseCueIndex + 1;
      _phaseCueIndex = nextPhaseCueIndex >= widget.exercise.phases.length
          ? widget.exercise.phases.length - 1
          : nextPhaseCueIndex;
      unawaited(AudioAnnouncementService.instance.play(
        'sounds/announcements/de/exercises/${widget.exercise.id}_phase_${_phaseCueIndex + 1}.mp3',
      ));
    }));

    _subs.add(svc.allRepsComplete.listen((_) async {
      if (!mounted) return;
      if (_feedbackMode != TrainingFeedbackMode.silent) {
        HapticFeedback.heavyImpact();
      }
      final prefs = await SharedPreferences.getInstance();
      await AdaptiveTempoSettings.saveTempoForExercise(
        prefs,
        exerciseNumber: widget.exercise.sequenceNumber,
        tempoSeconds: _tempoSeconds,
      );
      if (mounted) widget.onComplete();
    }));

    unawaited(svc.startExercise(widget.exercise));
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _metronome?.dispose();
    super.dispose();
  }

  Future<void> _togglePause() async {
    if (_isPaused) {
      if (widget.isRoutineMode &&
          _feedbackMode == TrainingFeedbackMode.voiceAndCues) {
        await AudioAnnouncementService.instance
            .play('sounds/announcements/de/weiter.mp3');
      }
      await _metronome?.resume();
    } else {
      await _metronome?.pause();
      if (widget.isRoutineMode &&
          _feedbackMode == TrainingFeedbackMode.voiceAndCues) {
        await AudioAnnouncementService.instance
            .play('sounds/announcements/de/pause.mp3');
      }
    }
    if (mounted) setState(() => _isPaused = !_isPaused);
    HapticFeedback.selectionClick();
  }

  void _changeTempo(double delta) {
    final newTempo = (_tempoSeconds + delta).clamp(0.5, 3.0);
    final snapped = (newTempo / _stepSize).round() * _stepSize;
    if (mounted) setState(() => _tempoSeconds = snapped);
    _metronome?.tempoSeconds = snapped;
    HapticFeedback.selectionClick();
  }

  void _changeHoldSeconds(int delta) {
    final min = widget.exercise.holdSeconds;
    final newVal = (_holdSecondsOverride + delta).clamp(min, 60);
    if (newVal == _holdSecondsOverride) return;
    if (mounted) setState(() => _holdSecondsOverride = newVal);
    _metronome?.holdSecondsOverride = newVal;
    HapticFeedback.selectionClick();
  }

  Future<void> _cycleFeedbackMode() async {
    final next = switch (_feedbackMode) {
      TrainingFeedbackMode.voiceAndCues => TrainingFeedbackMode.hapticOnly,
      TrainingFeedbackMode.hapticOnly => TrainingFeedbackMode.silent,
      TrainingFeedbackMode.silent => TrainingFeedbackMode.voiceAndCues,
    };
    final prefs = await SharedPreferences.getInstance();
    await TrainingFeedbackSettings.setFeedbackMode(prefs, next);
    if (mounted) setState(() => _feedbackMode = next);
    HapticFeedback.selectionClick();
  }

  void _openMusicPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF12121e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => MusicPickerSheet(
        onMusicActiveChanged: (active) {
          if (mounted) setState(() => _musicActive = active);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ex = widget.exercise;
    final isHoldRest = ex.rhythmType == RhythmType.holdRest;
    final beatsPerRep = isHoldRest ? _holdSecondsOverride : ex.holdSeconds;
    final beatProgress =
        beatsPerRep > 0 ? (_currentBeat / beatsPerRep).clamp(0.0, 1.0) : 0.0;
    final sessionProgress =
        widget.exerciseIndex / widget.totalExercises.toDouble();
    final locale = Localizations.localeOf(context).languageCode;
    final cueWord = _halfwayAnnounce
        ? l10n.trainingSwitchCueUpper
        : _isResting
            ? l10n.trainingPauseCue
            : ((locale == 'de' ? ex.holdCueDe : ex.holdCueEn).isNotEmpty
                ? (locale == 'de' ? ex.holdCueDe : ex.holdCueEn).toUpperCase()
                : l10n.trainingHoldCueUpper);
    final beatInterval = Duration(milliseconds: (_tempoSeconds * 1000).round());

    return Scaffold(
      backgroundColor: const Color(0xFF080810),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.trainingExerciseOfTotalCompact(
                      widget.exerciseIndex + 1,
                      widget.totalExercises,
                    ),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 10,
                        letterSpacing: 0.12),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366f1).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color:
                              const Color(0xFF6366f1).withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      widget.isRoutineMode
                          ? l10n.routineMode
                          : l10n.tutorialMode,
                      style: const TextStyle(
                          color: Color(0xFFa5b4fc),
                          fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

            // ── Session progress bar ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: LinearProgressIndicator(
                  value: sessionProgress,
                  minHeight: 2,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF6366f1)),
                ),
              ),
            ),

            // ── Center content ───────────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  PendulumAnimationWidget(
                    beatInterval: beatInterval,
                    beat: _currentBeat,
                    isActive: !_isResting && !_isPaused,
                  ),
                  const SizedBox(height: 16),

                  // Big beat number
                  Text(
                    '$_currentBeat',
                    style: TextStyle(
                      color: _isResting
                          ? const Color(0xFFa5b4fc).withValues(alpha: 0.4)
                          : const Color(0xFFa5b4fc),
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                      shadows: _isResting
                          ? []
                          : const [
                              Shadow(
                                color: Color(0x66a5b4fc),
                                blurRadius: 30,
                              ),
                            ],
                    ),
                  ),
                  Text(
                    _isResting
                        ? l10n.trainingRest
                        : isHoldRest
                            ? l10n.trainingSecondsOf(_holdSecondsOverride)
                            : l10n.trainingBeatsOf(ex.holdSeconds),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.25),
                        fontSize: 11),
                  ),
                  const SizedBox(height: 12),

                  // Cue word
                  Text(
                    cueWord,
                    style: TextStyle(
                      color: (_isResting || _halfwayAnnounce)
                          ? Colors.white.withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.85),
                      fontSize: _isResting ? 14 : 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Rep segments
                  RepSegmentsWidget(
                    totalReps: ex.repetitions,
                    completedReps: _currentRepIndex,
                    beatProgress: beatProgress,
                  ),
                  const SizedBox(height: 8),

                  // Exercise title
                  Text(
                    ex.title(locale),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11),
                  ),
                ],
              ),
            ),

            // ── Bottom controls ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  // Duration / tempo row
                  Row(
                    children: [
                      Expanded(
                        child: _tempoBtn(
                          '−',
                          isHoldRest
                              ? (_holdSecondsOverride > ex.holdSeconds
                                  ? () => _changeHoldSeconds(-1)
                                  : null)
                              : () => _changeTempo(-_stepSize),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF6366f1).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: const Color(0xFF6366f1)
                                    .withValues(alpha: 0.2)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            isHoldRest
                                ? l10n.trainingHoldTime(_holdSecondsOverride)
                                : l10n.trainingSecondsPerBeat(
                                    _tempoSeconds.toStringAsFixed(
                                      _tempoSeconds.truncateToDouble() ==
                                              _tempoSeconds
                                          ? 0
                                          : 1,
                                    ),
                                  ),
                            style: const TextStyle(
                                color: Color(0xFFa5b4fc),
                                fontSize: 12,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _tempoBtn(
                          '+',
                          isHoldRest
                              ? () => _changeHoldSeconds(1)
                              : () => _changeTempo(_stepSize),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Icon controls row
                  Row(
                    children: [
                      Expanded(
                        child: _iconBtn(
                          _musicActive ? '♫' : '♪',
                          _musicActive
                              ? l10n.trainingMusicOn
                              : l10n.trainingMusic,
                          _openMusicPicker,
                          active: _musicActive,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _iconBtn(
                          _feedbackIcon(_feedbackMode),
                          _feedbackLabel(_feedbackMode),
                          _cycleFeedbackMode,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _iconBtn(
                          _isPaused ? '▶' : '⏸',
                          _isPaused ? l10n.trainingResume : l10n.trainingPause,
                          _togglePause,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tempoBtn(String label, VoidCallback? onTap) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.06 : 0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.white.withValues(alpha: enabled ? 0.1 : 0.04)),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: enabled ? 0.6 : 0.2),
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _iconBtn(String icon, String label, VoidCallback onTap,
          {bool active = false}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFF22c55e).withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: active
                    ? const Color(0xFF22c55e).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08)),
          ),
          alignment: Alignment.center,
          child: Text(
            '$icon $label',
            style: TextStyle(
                color: active
                    ? const Color(0xFF86efac)
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 9,
                fontWeight: FontWeight.w600),
          ),
        ),
      );

  String _feedbackLabel(TrainingFeedbackMode mode) {
    final l10n = AppLocalizations.of(context);
    return switch (mode) {
      TrainingFeedbackMode.voiceAndCues => l10n.trainingFeedbackSounds,
      TrainingFeedbackMode.hapticOnly => l10n.trainingFeedbackHaptics,
      TrainingFeedbackMode.silent => l10n.trainingFeedbackSilent,
    };
  }

  String _feedbackIcon(TrainingFeedbackMode mode) => switch (mode) {
        TrainingFeedbackMode.voiceAndCues => '🔊',
        TrainingFeedbackMode.hapticOnly => '📳',
        TrainingFeedbackMode.silent => '🔇',
      };
}
