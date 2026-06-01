import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/training/first_run_settings.dart';
import '../../../../core/training/transition_duration_settings.dart';
import '../../../../core/training/training_feedback_settings.dart';
import '../../domain/models/exercise.dart';
import '../../domain/services/audio_announcement_service.dart';
import '../widgets/exercise_transition_widget.dart';
import 'immersive_exercise_screen.dart';

enum _Phase { transition, exercise }

class ImmersiveSessionScreen extends StatefulWidget {
  final List<Exercise> exercises;
  final bool isRoutineMode;
  final String packageId;
  final List<String> companionSubjectProfileIds;
  final void Function(List<String> completedExerciseIds) onComplete;

  const ImmersiveSessionScreen({
    super.key,
    required this.exercises,
    required this.isRoutineMode,
    required this.packageId,
    this.companionSubjectProfileIds = const [],
    required this.onComplete,
  });

  @override
  State<ImmersiveSessionScreen> createState() => _ImmersiveSessionScreenState();
}

class _ImmersiveSessionScreenState extends State<ImmersiveSessionScreen> {
  int _exerciseIndex = 0;
  _Phase _phase = _Phase.transition;
  final List<String> _completedIds = [];
  int _transitionDuration = 10;
  bool _isFirstRun = false;
  late bool _announcementReady;

  @override
  void initState() {
    super.initState();
    _announcementReady = !widget.isRoutineMode;
    _loadTransitionDuration();
    _loadFirstRun();
    if (widget.isRoutineMode && widget.exercises.isNotEmpty) {
      unawaited(_announceExercise(widget.exercises.first));
    }
  }

  Future<void> _announceExercise(Exercise exercise) async {
    final isDuo = widget.companionSubjectProfileIds.isNotEmpty;
    await AudioAnnouncementService.instance.queue([
      'sounds/announcements/de/exercises/${exercise.id}_name.mp3',
      'sounds/announcements/de/exercises/${exercise.id}_position${isDuo ? '_duo' : ''}.mp3',
    ]);
    if (!mounted) return;
    setState(() => _announcementReady = true);
  }

  Future<void> _loadTransitionDuration() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _transitionDuration = TransitionDurationSettings.durationSeconds(prefs);
    });
  }

  Future<void> _loadFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isFirstRun = FirstRunSettings.isFirstRun(prefs, widget.packageId);
    });
  }

  @override
  void dispose() {
    AudioAnnouncementService.instance.stop();
    super.dispose();
  }

  void _onTransitionComplete() {
    setState(() => _phase = _Phase.exercise);
  }

  Future<void> _onExerciseComplete() async {
    final exercise = widget.exercises[_exerciseIndex];
    _completedIds.add(exercise.id);

    if (_exerciseIndex >= widget.exercises.length - 1) {
      if (_isFirstRun) {
        final prefs = await SharedPreferences.getInstance();
        await FirstRunSettings.markComplete(prefs, widget.packageId);
      }
      widget.onComplete(List.unmodifiable(_completedIds));
      return;
    }

    // Play exercise-switch tone unless hapticOnly mode
    final prefs = await SharedPreferences.getInstance();
    final mode = TrainingFeedbackSettings.feedbackMode(prefs);
    if (mode != TrainingFeedbackMode.hapticOnly) {
      final player = AudioPlayer();
      try {
        final ctx = AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build();
        await player.setAudioContext(ctx);
        await player.setPlayerMode(PlayerMode.lowLatency);
        await player.play(AssetSource('sounds/rhythm_hold_end.wav'),
            mode: PlayerMode.lowLatency);
      } catch (_) {}
      await player.dispose();
    }

    if (!mounted) return;
    final nextExercise = widget.exercises[_exerciseIndex + 1];
    setState(() {
      _exerciseIndex++;
      _phase = _Phase.transition;
      _announcementReady = !widget.isRoutineMode;
    });

    if (widget.isRoutineMode) {
      await _announceExercise(nextExercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    final exercise = widget.exercises[_exerciseIndex];
    final locale = Localizations.localeOf(context).languageCode;

    return switch (_phase) {
      _Phase.transition => ExerciseTransitionWidget(
          key: ValueKey('transition_${_exerciseIndex}_$_announcementReady'),
          exercise: exercise,
          exerciseIndex: _exerciseIndex,
          totalExercises: widget.exercises.length,
          isRoutineMode: widget.isRoutineMode,
          transitionDurationSeconds:
              widget.isRoutineMode ? 5 : _transitionDuration,
          packageId: widget.packageId,
          isFirstRun: _isFirstRun,
          locale: locale,
          isDuo: widget.companionSubjectProfileIds.isNotEmpty,
          enableCountdown: _announcementReady,
          onStart: _onTransitionComplete,
        ),
      _Phase.exercise => ImmersiveExerciseScreen(
          key: ValueKey('exercise_$_exerciseIndex'),
          exercise: exercise,
          exerciseIndex: _exerciseIndex,
          totalExercises: widget.exercises.length,
          isRoutineMode: widget.isRoutineMode,
          onComplete: _onExerciseComplete,
        ),
    };
  }
}
