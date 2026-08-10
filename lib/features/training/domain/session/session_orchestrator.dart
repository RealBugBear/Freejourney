import 'dart:async';

import '../models/exercise.dart';
import '../models/training_session.dart';

/// Every user-visible and externally observable state of an active training.
///
/// Timed stages are advanced exclusively through [SessionOrchestrator.advance].
/// Audio, widgets, haptics and persistence must never maintain a second timer.
enum TrainingSessionStage {
  preflight,
  exerciseAnnouncement,
  preparation,
  activeMovement,
  recovery,
  exerciseTransition,
  paused,
  interrupted,
  completed,
  cancelled,
  failure,
}

enum TrainingPauseReason { user, lifecycle, audioInterruption }

enum TrainingSessionSignalType {
  exerciseAnnouncement,
  preparationStarted,
  phaseStarted,
  beat,
  repetitionCompleted,
  sideSwitch,
  recoveryStarted,
  exerciseCompleted,
  paused,
  resumed,
  sessionCompleted,
  cancelled,
}

class TrainingSessionSignal {
  const TrainingSessionSignal({
    required this.type,
    required this.exerciseIndex,
    required this.repetitionIndex,
    required this.phaseIndex,
    this.beat,
    this.isReplay = false,
  });

  final TrainingSessionSignalType type;
  final int exerciseIndex;
  final int repetitionIndex;
  final int phaseIndex;
  final int? beat;
  final bool isReplay;
}

class TrainingSessionState {
  const TrainingSessionState({
    required this.sessionId,
    required this.packageId,
    required this.contentVersion,
    required this.mode,
    required this.stage,
    required this.exerciseIndex,
    required this.repetitionIndex,
    required this.phaseIndex,
    required this.stepElapsed,
    required this.stepDuration,
    required this.completedExerciseIds,
    this.requiresSideSwitch = false,
    this.pauseReason,
    this.resumeStage,
    this.failureMessage,
  });

  factory TrainingSessionState.initial({
    required String sessionId,
    required String packageId,
    required String contentVersion,
    required TrainingSessionMode mode,
  }) {
    return TrainingSessionState(
      sessionId: sessionId,
      packageId: packageId,
      contentVersion: contentVersion,
      mode: mode,
      stage: TrainingSessionStage.preflight,
      exerciseIndex: 0,
      repetitionIndex: 0,
      phaseIndex: 0,
      stepElapsed: Duration.zero,
      stepDuration: Duration.zero,
      completedExerciseIds: const [],
    );
  }

  final String sessionId;
  final String packageId;
  final String contentVersion;
  final TrainingSessionMode mode;
  final TrainingSessionStage stage;

  /// Zero-based index of the exercise currently shown.
  final int exerciseIndex;

  /// Zero-based index of the repetition currently being performed.
  final int repetitionIndex;

  /// Zero-based phase index for phased exercises.
  final int phaseIndex;
  final Duration stepElapsed;
  final Duration stepDuration;
  final List<String> completedExerciseIds;
  final bool requiresSideSwitch;
  final TrainingPauseReason? pauseReason;

  /// The stage to restore after pause/interruption.
  final TrainingSessionStage? resumeStage;
  final String? failureMessage;

  Duration get remaining {
    final value = stepDuration - stepElapsed;
    return value.isNegative ? Duration.zero : value;
  }

  double get stepProgress {
    if (stepDuration <= Duration.zero) return 0;
    return (stepElapsed.inMicroseconds / stepDuration.inMicroseconds)
        .clamp(0.0, 1.0);
  }

  bool get isPaused =>
      stage == TrainingSessionStage.paused ||
      stage == TrainingSessionStage.interrupted;

  bool get isTerminal =>
      stage == TrainingSessionStage.completed ||
      stage == TrainingSessionStage.cancelled ||
      stage == TrainingSessionStage.failure;

  TrainingSessionState copyWith({
    TrainingSessionStage? stage,
    int? exerciseIndex,
    int? repetitionIndex,
    int? phaseIndex,
    Duration? stepElapsed,
    Duration? stepDuration,
    List<String>? completedExerciseIds,
    bool? requiresSideSwitch,
    TrainingPauseReason? pauseReason,
    bool clearPauseReason = false,
    TrainingSessionStage? resumeStage,
    bool clearResumeStage = false,
    String? failureMessage,
    bool clearFailure = false,
  }) {
    return TrainingSessionState(
      sessionId: sessionId,
      packageId: packageId,
      contentVersion: contentVersion,
      mode: mode,
      stage: stage ?? this.stage,
      exerciseIndex: exerciseIndex ?? this.exerciseIndex,
      repetitionIndex: repetitionIndex ?? this.repetitionIndex,
      phaseIndex: phaseIndex ?? this.phaseIndex,
      stepElapsed: stepElapsed ?? this.stepElapsed,
      stepDuration: stepDuration ?? this.stepDuration,
      completedExerciseIds: completedExerciseIds ?? this.completedExerciseIds,
      requiresSideSwitch: requiresSideSwitch ?? this.requiresSideSwitch,
      pauseReason: clearPauseReason ? null : pauseReason ?? this.pauseReason,
      resumeStage: clearResumeStage ? null : resumeStage ?? this.resumeStage,
      failureMessage:
          clearFailure ? null : failureMessage ?? this.failureMessage,
    );
  }

  Map<String, Object?> toJson() => {
        'sessionId': sessionId,
        'packageId': packageId,
        'contentVersion': contentVersion,
        'mode': mode.name,
        'stage': stage.name,
        'exerciseIndex': exerciseIndex,
        'repetitionIndex': repetitionIndex,
        'phaseIndex': phaseIndex,
        'stepElapsedUs': stepElapsed.inMicroseconds,
        'stepDurationUs': stepDuration.inMicroseconds,
        'completedExerciseIds': completedExerciseIds,
        'requiresSideSwitch': requiresSideSwitch,
        'pauseReason': pauseReason?.name,
        'resumeStage': resumeStage?.name,
        'failureMessage': failureMessage,
      };

  factory TrainingSessionState.fromJson(Map<String, dynamic> json) {
    T enumByName<T extends Enum>(List<T> values, String name) =>
        values.firstWhere((value) => value.name == name);

    final rawCompleted = json['completedExerciseIds'];
    return TrainingSessionState(
      sessionId: json['sessionId'] as String,
      packageId: json['packageId'] as String,
      contentVersion: json['contentVersion'] as String,
      mode: enumByName(
        TrainingSessionMode.values,
        json['mode'] as String,
      ),
      stage: enumByName(
        TrainingSessionStage.values,
        json['stage'] as String,
      ),
      exerciseIndex: json['exerciseIndex'] as int,
      repetitionIndex: json['repetitionIndex'] as int,
      phaseIndex: json['phaseIndex'] as int,
      stepElapsed: Duration(
        microseconds: json['stepElapsedUs'] as int,
      ),
      stepDuration: Duration(
        microseconds: json['stepDurationUs'] as int,
      ),
      completedExerciseIds: List<String>.unmodifiable(
        (rawCompleted as List<dynamic>).cast<String>(),
      ),
      requiresSideSwitch: json['requiresSideSwitch'] as bool? ?? false,
      pauseReason: json['pauseReason'] == null
          ? null
          : enumByName(
              TrainingPauseReason.values,
              json['pauseReason'] as String,
            ),
      resumeStage: json['resumeStage'] == null
          ? null
          : enumByName(
              TrainingSessionStage.values,
              json['resumeStage'] as String,
            ),
      failureMessage: json['failureMessage'] as String?,
    );
  }
}

/// Pure, deterministic state machine for a complete training session.
///
/// Production passes monotonic deltas from a [Stopwatch]. Tests call [advance]
/// directly, which makes an entire session complete without waiting.
class SessionOrchestrator {
  SessionOrchestrator({
    required List<Exercise> exercises,
    required String sessionId,
    required String packageId,
    required String contentVersion,
    required TrainingSessionMode mode,
    required Duration routinePreparationDuration,
    Map<String, double> tempoSecondsByExerciseId = const {},
    TrainingSessionState? restoredState,
  })  : _exercises = List.unmodifiable(exercises),
        _routinePreparationDuration = routinePreparationDuration,
        _tempoSecondsByExerciseId = Map.of(tempoSecondsByExerciseId),
        _state = restoredState ??
            TrainingSessionState.initial(
              sessionId: sessionId,
              packageId: packageId,
              contentVersion: contentVersion,
              mode: mode,
            ) {
    if (_exercises.isEmpty) {
      throw ArgumentError.value(exercises, 'exercises', 'must not be empty');
    }
    _validateExerciseContract();
    if (restoredState != null) {
      _validateRestoredState(
        restoredState,
        sessionId: sessionId,
        packageId: packageId,
        contentVersion: contentVersion,
        mode: mode,
      );
      if (!restoredState.isTerminal) {
        final stageToResume = restoredState.isPaused
            ? restoredState.resumeStage
            : restoredState.stage;
        _state = restoredState.copyWith(
          stage: TrainingSessionStage.paused,
          pauseReason: TrainingPauseReason.user,
          resumeStage: stageToResume,
        );
      }
    }
  }

  final List<Exercise> _exercises;
  final Duration _routinePreparationDuration;
  final Map<String, double> _tempoSecondsByExerciseId;
  final StreamController<TrainingSessionState> _states =
      StreamController<TrainingSessionState>.broadcast(sync: true);
  final StreamController<TrainingSessionSignal> _signals =
      StreamController<TrainingSessionSignal>.broadcast(sync: true);

  TrainingSessionState _state;
  bool _disposed = false;
  bool _completionSignalEmitted = false;
  int _lastEmittedBeat = 0;

  TrainingSessionState get state => _state;
  Stream<TrainingSessionState> get states => _states.stream;
  Stream<TrainingSessionSignal> get signals => _signals.stream;
  Exercise get currentExercise => _exercises[_state.exerciseIndex];
  List<Exercise> get exercises => _exercises;

  double get sessionProgress {
    final exercise = currentExercise;
    if (_state.stage == TrainingSessionStage.completed) return 1;
    if (_state.completedExerciseIds.contains(exercise.id)) {
      return ((_state.exerciseIndex + 1) / _exercises.length).clamp(0.0, 1.0);
    }
    final effectiveStage = _state.isPaused ? _state.resumeStage : _state.stage;
    double activeRepetitionProgress;
    if (effectiveStage == TrainingSessionStage.recovery) {
      activeRepetitionProgress = 1;
    } else if (effectiveStage == TrainingSessionStage.activeMovement &&
        exercise.rhythmType == RhythmType.phased) {
      final totalPhaseBeats = exercise.phases.fold<int>(
        0,
        (total, phase) => total + phase.durationSeconds,
      );
      final completedPhaseBeats = exercise.phases
          .take(_state.phaseIndex)
          .fold<int>(0, (total, phase) => total + phase.durationSeconds);
      final currentPhaseBeats =
          exercise.phases[_state.phaseIndex].durationSeconds;
      activeRepetitionProgress = totalPhaseBeats == 0
          ? 0
          : (completedPhaseBeats + currentPhaseBeats * _state.stepProgress) /
              totalPhaseBeats;
    } else if (effectiveStage == TrainingSessionStage.activeMovement) {
      activeRepetitionProgress = _state.stepProgress;
    } else {
      activeRepetitionProgress = 0;
    }
    final repFraction = exercise.repetitions == 0
        ? 0.0
        : (_state.repetitionIndex + activeRepetitionProgress) /
            exercise.repetitions;
    return ((_state.exerciseIndex + repFraction) / _exercises.length)
        .clamp(0.0, 1.0);
  }

  int get currentBeat {
    if (_state.stage != TrainingSessionStage.activeMovement) return 0;
    final beatUs = _beatDuration(currentExercise).inMicroseconds;
    if (beatUs <= 0) return 0;
    final raw = _state.stepElapsed.inMicroseconds ~/ beatUs + 1;
    return raw.clamp(1, beatsInCurrentStep);
  }

  int get beatsInCurrentStep {
    final beatUs = _beatDuration(currentExercise).inMicroseconds;
    if (beatUs <= 0) return 0;
    return (_state.stepDuration.inMicroseconds / beatUs).round().clamp(1, 999);
  }

  /// Target duration of the exercise's canonical reference phase.
  ///
  /// For phased movements this is the duration of a configured three-second
  /// movement; for hold/rest movements it is the configured hold duration.
  /// Therefore the persisted legacy defaults (3 s and 7 s) reproduce the
  /// released timings exactly instead of acting as multipliers.
  double tempoSecondsFor(String exerciseId) {
    final exercise = _exerciseById(exerciseId);
    return (_tempoSecondsByExerciseId[exerciseId] ??
            _canonicalTempoSeconds(exercise))
        .clamp(
      minTempoSecondsFor(exerciseId),
      maxTempoSecondsFor(exerciseId),
    );
  }

  double minTempoSecondsFor(String exerciseId) =>
      _exerciseById(exerciseId).rhythmType == RhythmType.holdRest ? 2.0 : 1.0;

  double maxTempoSecondsFor(String exerciseId) =>
      _exerciseById(exerciseId).rhythmType == RhythmType.holdRest ? 12.0 : 7.0;

  /// Changes pace without introducing another clock.
  ///
  /// If the current phase is running, elapsed time is rescaled to preserve the
  /// exact fractional phase progress. No beat, phase or repetition is skipped.
  void setTempoSeconds(String exerciseId, double seconds) {
    _guardNotDisposed();
    if (!_exercises.any((exercise) => exercise.id == exerciseId)) {
      throw ArgumentError.value(
        exerciseId,
        'exerciseId',
        'is not part of this session',
      );
    }
    final clamped = seconds.clamp(
      minTempoSecondsFor(exerciseId),
      maxTempoSecondsFor(exerciseId),
    );
    if (_state.stage == TrainingSessionStage.activeMovement &&
        currentExercise.id == exerciseId) {
      final progress = _state.stepProgress;
      _tempoSecondsByExerciseId[exerciseId] = clamped;
      final exercise = currentExercise;
      final beats = exercise.rhythmType == RhythmType.phased
          ? exercise.phases[_state.phaseIndex].durationSeconds
          : exercise.holdSeconds;
      final nextDuration = _scaledBeatDuration(exercise, beats);
      final nextElapsed = Duration(
        microseconds: (nextDuration.inMicroseconds * progress).round(),
      );
      _replaceState(
        _state.copyWith(
          stepElapsed: nextElapsed,
          stepDuration: nextDuration,
        ),
      );
      _lastEmittedBeat = currentBeat;
      return;
    }
    _tempoSecondsByExerciseId[exerciseId] = clamped;
  }

  void start() {
    _guardNotDisposed();
    if (_state.stage != TrainingSessionStage.preflight) return;
    _enterAnnouncement();
  }

  /// Called only after all required preparation audio has ended.
  void announcementFinished() {
    _guardNotDisposed();
    if (_state.stage != TrainingSessionStage.exerciseAnnouncement) return;
    if (_state.mode == TrainingSessionMode.tutorial) return;
    _enterPreparation(_routinePreparationDuration);
  }

  /// Explicit confirmation in learning mode.
  void confirmReady() {
    _guardNotDisposed();
    if (_state.stage != TrainingSessionStage.exerciseAnnouncement ||
        _state.mode != TrainingSessionMode.tutorial) {
      return;
    }
    _enterPreparation(const Duration(seconds: 3));
  }

  /// Voluntary shortcut. This is never wired to an undifferentiated full-screen
  /// tap target, so a scroll gesture cannot start an exercise.
  void startNow() {
    _guardNotDisposed();
    if (_state.stage == TrainingSessionStage.preparation) {
      _enterActiveMovement();
    }
  }

  void repeatCurrentInstruction() {
    _guardNotDisposed();
    if (_state.isTerminal) return;
    _emitSignal(
      TrainingSessionSignalType.exerciseAnnouncement,
      isReplay: true,
    );
  }

  void pause({TrainingPauseReason reason = TrainingPauseReason.user}) {
    _guardNotDisposed();
    if (!_isPausableStage(_state.stage)) return;
    final target = reason == TrainingPauseReason.user
        ? TrainingSessionStage.paused
        : TrainingSessionStage.interrupted;
    final previousStage = _state.stage;
    _replaceState(
      _state.copyWith(
        stage: target,
        pauseReason: reason,
        resumeStage: previousStage,
      ),
    );
    _emitSignal(TrainingSessionSignalType.paused);
  }

  void resume() {
    _guardNotDisposed();
    if (!_state.isPaused || _state.resumeStage == null) return;
    final resumeStage = _state.resumeStage!;
    _replaceState(
      _state.copyWith(
        stage: resumeStage,
        clearPauseReason: true,
        clearResumeStage: true,
      ),
    );
    _emitSignal(TrainingSessionSignalType.resumed);
  }

  void cancel() {
    _guardNotDisposed();
    if (_state.isTerminal) return;
    _replaceState(
      _state.copyWith(
        stage: TrainingSessionStage.cancelled,
        clearPauseReason: true,
        clearResumeStage: true,
      ),
    );
    _emitSignal(TrainingSessionSignalType.cancelled);
  }

  /// Advances the canonical timeline by a monotonic duration.
  void advance(Duration elapsed) {
    _guardNotDisposed();
    if (elapsed <= Duration.zero || !_isTimedStage(_state.stage)) return;

    var pendingUs = elapsed.inMicroseconds;
    while (pendingUs > 0 && _isTimedStage(_state.stage)) {
      final remainingUs = _state.remaining.inMicroseconds;
      if (remainingUs <= 0) {
        _finishTimedStage();
        continue;
      }

      final consumedUs = pendingUs < remainingUs ? pendingUs : remainingUs;
      final previousBeat = currentBeat;
      _replaceState(
        _state.copyWith(
          stepElapsed: _state.stepElapsed + Duration(microseconds: consumedUs),
        ),
      );
      pendingUs -= consumedUs;
      _emitCrossedBeats(previousBeat);

      if (_state.remaining <= Duration.zero) {
        _finishTimedStage();
      }
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _states.close();
    await _signals.close();
  }

  void _enterAnnouncement() {
    _lastEmittedBeat = 0;
    _replaceState(
      _state.copyWith(
        stage: TrainingSessionStage.exerciseAnnouncement,
        repetitionIndex: 0,
        phaseIndex: 0,
        stepElapsed: Duration.zero,
        stepDuration: Duration.zero,
        requiresSideSwitch: false,
        clearPauseReason: true,
        clearResumeStage: true,
      ),
    );
    _emitSignal(TrainingSessionSignalType.exerciseAnnouncement);
  }

  void _enterPreparation(Duration duration) {
    _lastEmittedBeat = 0;
    _replaceState(
      _state.copyWith(
        stage: TrainingSessionStage.preparation,
        stepElapsed: Duration.zero,
        stepDuration: duration <= Duration.zero
            ? const Duration(microseconds: 1)
            : duration,
        requiresSideSwitch: false,
      ),
    );
    _emitSignal(TrainingSessionSignalType.preparationStarted);
  }

  void _enterActiveMovement() {
    final exercise = currentExercise;
    final phaseDuration = exercise.rhythmType == RhythmType.phased
        ? exercise.phases[_state.phaseIndex].durationSeconds
        : exercise.holdSeconds;
    final duration = _scaledBeatDuration(exercise, phaseDuration);
    _lastEmittedBeat = 1;
    _replaceState(
      _state.copyWith(
        stage: TrainingSessionStage.activeMovement,
        stepElapsed: Duration.zero,
        stepDuration: duration,
        requiresSideSwitch: false,
      ),
    );
    _emitSignal(TrainingSessionSignalType.phaseStarted);
    _emitSignal(TrainingSessionSignalType.beat, beat: 1);
  }

  void _enterRecovery({required bool requiresSwitch}) {
    final seconds = currentExercise.restSeconds;
    _lastEmittedBeat = 0;
    _replaceState(
      _state.copyWith(
        stage: TrainingSessionStage.recovery,
        stepElapsed: Duration.zero,
        stepDuration: Duration(seconds: seconds),
        requiresSideSwitch: requiresSwitch,
      ),
    );
    if (requiresSwitch) {
      _emitSignal(TrainingSessionSignalType.sideSwitch);
    }
    _emitSignal(TrainingSessionSignalType.recoveryStarted);
  }

  void _enterExerciseTransition() {
    _lastEmittedBeat = 0;
    _replaceState(
      _state.copyWith(
        stage: TrainingSessionStage.exerciseTransition,
        stepElapsed: Duration.zero,
        stepDuration: const Duration(seconds: 2),
        requiresSideSwitch: false,
      ),
    );
  }

  void _finishTimedStage() {
    switch (_state.stage) {
      case TrainingSessionStage.preparation:
        _enterActiveMovement();
        return;
      case TrainingSessionStage.activeMovement:
        _finishActiveMovement();
        return;
      case TrainingSessionStage.recovery:
        _replaceState(
          _state.copyWith(
            repetitionIndex: _state.repetitionIndex + 1,
            phaseIndex: 0,
            requiresSideSwitch: false,
          ),
        );
        _enterActiveMovement();
        return;
      case TrainingSessionStage.exerciseTransition:
        _replaceState(
          _state.copyWith(
            exerciseIndex: _state.exerciseIndex + 1,
            repetitionIndex: 0,
            phaseIndex: 0,
          ),
        );
        _enterAnnouncement();
        return;
      case TrainingSessionStage.preflight:
      case TrainingSessionStage.exerciseAnnouncement:
      case TrainingSessionStage.paused:
      case TrainingSessionStage.interrupted:
      case TrainingSessionStage.completed:
      case TrainingSessionStage.cancelled:
      case TrainingSessionStage.failure:
        return;
    }
  }

  void _finishActiveMovement() {
    final exercise = currentExercise;
    if (exercise.rhythmType == RhythmType.phased &&
        _state.phaseIndex < exercise.phases.length - 1) {
      _replaceState(
        _state.copyWith(phaseIndex: _state.phaseIndex + 1),
      );
      _enterActiveMovement();
      return;
    }

    final completedRepCount = _state.repetitionIndex + 1;
    _emitSignal(TrainingSessionSignalType.repetitionCompleted);
    final isLastRepetition = completedRepCount >= exercise.repetitions;
    if (!isLastRepetition) {
      final halfwaySwitch = exercise.halfwaySwitch &&
          completedRepCount == exercise.repetitions ~/ 2;
      final requiresSwitch = exercise.hasRepSwitch || halfwaySwitch;
      _replaceState(_state.copyWith(phaseIndex: 0));
      _enterRecovery(requiresSwitch: requiresSwitch);
      return;
    }

    final completed = List<String>.unmodifiable([
      ..._state.completedExerciseIds,
      exercise.id,
    ]);
    _replaceState(
      _state.copyWith(
        completedExerciseIds: completed,
        stepElapsed: Duration.zero,
        stepDuration: Duration.zero,
        requiresSideSwitch: false,
      ),
    );
    _emitSignal(TrainingSessionSignalType.exerciseCompleted);

    if (_state.exerciseIndex >= _exercises.length - 1) {
      _completeSession();
    } else {
      _enterExerciseTransition();
    }
  }

  void _completeSession() {
    if (_state.stage == TrainingSessionStage.completed) return;
    _replaceState(
      _state.copyWith(
        stage: TrainingSessionStage.completed,
        clearPauseReason: true,
        clearResumeStage: true,
      ),
    );
    if (_completionSignalEmitted) return;
    _completionSignalEmitted = true;
    _emitSignal(TrainingSessionSignalType.sessionCompleted);
  }

  void _emitCrossedBeats(int previousBeat) {
    if (_state.stage != TrainingSessionStage.activeMovement) return;
    final targetBeat = currentBeat;
    final first = previousBeat < 1 ? 1 : previousBeat + 1;
    for (var beat = first; beat <= targetBeat; beat++) {
      if (beat <= _lastEmittedBeat) continue;
      _lastEmittedBeat = beat;
      _emitSignal(TrainingSessionSignalType.beat, beat: beat);
    }
  }

  Duration _scaledBeatDuration(Exercise exercise, int beats) {
    final beatUs = _beatDuration(exercise).inMicroseconds;
    return Duration(microseconds: beatUs * beats);
  }

  Duration _beatDuration(Exercise exercise) {
    final scale =
        tempoSecondsFor(exercise.id) / _canonicalTempoSeconds(exercise);
    return Duration(
      microseconds: (scale * Duration.microsecondsPerSecond).round(),
    );
  }

  double _canonicalTempoSeconds(Exercise exercise) =>
      exercise.rhythmType == RhythmType.holdRest
          ? exercise.holdSeconds.toDouble()
          : 3.0;

  Exercise _exerciseById(String exerciseId) => _exercises.firstWhere(
        (exercise) => exercise.id == exerciseId,
        orElse: () => throw ArgumentError.value(
          exerciseId,
          'exerciseId',
          'is not part of this session',
        ),
      );

  bool _isTimedStage(TrainingSessionStage stage) =>
      stage == TrainingSessionStage.preparation ||
      stage == TrainingSessionStage.activeMovement ||
      stage == TrainingSessionStage.recovery ||
      stage == TrainingSessionStage.exerciseTransition;

  bool _isPausableStage(TrainingSessionStage stage) =>
      stage == TrainingSessionStage.exerciseAnnouncement ||
      _isTimedStage(stage);

  void _replaceState(TrainingSessionState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  void _emitSignal(
    TrainingSessionSignalType type, {
    int? beat,
    bool isReplay = false,
  }) {
    if (_signals.isClosed) return;
    _signals.add(
      TrainingSessionSignal(
        type: type,
        exerciseIndex: _state.exerciseIndex,
        repetitionIndex: _state.repetitionIndex,
        phaseIndex: _state.phaseIndex,
        beat: beat,
        isReplay: isReplay,
      ),
    );
  }

  void _validateExerciseContract() {
    final ids = <String>{};
    for (var index = 0; index < _exercises.length; index++) {
      final exercise = _exercises[index];
      if (!ids.add(exercise.id)) {
        throw ArgumentError('duplicate exercise id: ${exercise.id}');
      }
      if (exercise.packageId != _state.packageId) {
        throw ArgumentError(
          'exercise ${exercise.id} belongs to ${exercise.packageId}, '
          'expected ${_state.packageId}',
        );
      }
      if (exercise.sequenceNumber != index + 1) {
        throw ArgumentError(
          'exercise ${exercise.id} has invalid sequence '
          '${exercise.sequenceNumber}',
        );
      }
      if (exercise.repetitions <= 0 ||
          exercise.holdSeconds <= 0 ||
          exercise.restSeconds < 0) {
        throw ArgumentError('invalid timing for ${exercise.id}');
      }
      if (exercise.rhythmType == RhythmType.phased &&
          (exercise.phases.isEmpty ||
              exercise.phases.any((phase) => phase.durationSeconds <= 0))) {
        throw ArgumentError('invalid phases for ${exercise.id}');
      }
    }
  }

  void _validateRestoredState(
    TrainingSessionState restored, {
    required String sessionId,
    required String packageId,
    required String contentVersion,
    required TrainingSessionMode mode,
  }) {
    if (restored.sessionId != sessionId ||
        restored.packageId != packageId ||
        restored.contentVersion != contentVersion ||
        restored.mode != mode) {
      throw ArgumentError('checkpoint does not match package content');
    }
    if (restored.exerciseIndex < 0 ||
        restored.exerciseIndex >= _exercises.length ||
        restored.repetitionIndex < 0 ||
        restored.repetitionIndex >=
            _exercises[restored.exerciseIndex].repetitions ||
        restored.stepElapsed < Duration.zero ||
        restored.stepElapsed > restored.stepDuration) {
      throw ArgumentError('checkpoint contains an invalid timeline position');
    }
    final effectiveStage =
        restored.isPaused ? restored.resumeStage : restored.stage;
    final completedCount = switch (effectiveStage) {
      TrainingSessionStage.completed => _exercises.length,
      TrainingSessionStage.exerciseTransition => restored.exerciseIndex + 1,
      _ => restored.exerciseIndex,
    };
    final expectedCompleted =
        _exercises.take(completedCount).map((exercise) => exercise.id);
    if (!_listEquals(restored.completedExerciseIds, expectedCompleted)) {
      throw ArgumentError('checkpoint completed exercises do not match order');
    }
  }

  bool _listEquals(Iterable<String> a, Iterable<String> b) {
    final first = a.iterator;
    final second = b.iterator;
    while (true) {
      final hasFirst = first.moveNext();
      final hasSecond = second.moveNext();
      if (hasFirst != hasSecond) return false;
      if (!hasFirst) return true;
      if (first.current != second.current) return false;
    }
  }

  void _guardNotDisposed() {
    if (_disposed) throw StateError('SessionOrchestrator is disposed');
  }
}
