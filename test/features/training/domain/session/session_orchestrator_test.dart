import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:corejourney/features/training/domain/models/training_session.dart';
import 'package:corejourney/features/training/domain/session/session_orchestrator.dart';
import 'package:flutter_test/flutter_test.dart';

const _phased = Exercise(
  id: 'one',
  packageId: 'test',
  sequenceNumber: 1,
  titleDe: 'Eins',
  titleEn: 'One',
  positionInstructionsDe: [],
  positionInstructionsEn: [],
  movementInstructionsDe: [],
  movementInstructionsEn: [],
  executionGuideDe: '',
  executionGuideEn: '',
  durationSeconds: 9,
  repetitions: 2,
  imagePath: '',
  rhythmType: RhythmType.phased,
  phases: [
    ExercisePhase(labelDe: 'Hoch', labelEn: 'Up', durationSeconds: 2),
    ExercisePhase(labelDe: 'Runter', labelEn: 'Down', durationSeconds: 1),
  ],
  hasRepSwitch: true,
  restSeconds: 3,
);

const _hold = Exercise(
  id: 'two',
  packageId: 'test',
  sequenceNumber: 2,
  titleDe: 'Zwei',
  titleEn: 'Two',
  positionInstructionsDe: [],
  positionInstructionsEn: [],
  movementInstructionsDe: [],
  movementInstructionsEn: [],
  executionGuideDe: '',
  executionGuideEn: '',
  durationSeconds: 9,
  repetitions: 2,
  imagePath: '',
  rhythmType: RhythmType.holdRest,
  holdSeconds: 2,
  restSeconds: 1,
);

SessionOrchestrator _orchestrator({
  TrainingSessionMode mode = TrainingSessionMode.routine,
  TrainingSessionState? restoredState,
}) {
  return SessionOrchestrator(
    exercises: const [_phased, _hold],
    sessionId: restoredState?.sessionId ?? 'session-1',
    packageId: 'test',
    contentVersion: 'v1',
    mode: mode,
    routinePreparationDuration: const Duration(seconds: 5),
    restoredState: restoredState,
  );
}

void _finishRoutine(SessionOrchestrator orchestrator) {
  var safety = 0;
  while (orchestrator.state.stage != TrainingSessionStage.completed) {
    expect(safety++, lessThan(100), reason: 'state machine did not converge');
    switch (orchestrator.state.stage) {
      case TrainingSessionStage.preflight:
        orchestrator.start();
        continue;
      case TrainingSessionStage.exerciseAnnouncement:
        orchestrator.announcementFinished();
        continue;
      case TrainingSessionStage.preparation:
      case TrainingSessionStage.activeMovement:
      case TrainingSessionStage.recovery:
      case TrainingSessionStage.exerciseTransition:
        orchestrator.advance(orchestrator.state.remaining);
        continue;
      case TrainingSessionStage.paused:
      case TrainingSessionStage.interrupted:
        orchestrator.resume();
        continue;
      case TrainingSessionStage.completed:
      case TrainingSessionStage.cancelled:
      case TrainingSessionStage.failure:
        return;
    }
  }
}

void main() {
  group('SessionOrchestrator', () {
    test('waits for the announcement before starting the countdown', () {
      final orchestrator = _orchestrator();
      orchestrator.start();

      expect(
        orchestrator.state.stage,
        TrainingSessionStage.exerciseAnnouncement,
      );
      orchestrator.advance(const Duration(minutes: 1));
      expect(
        orchestrator.state.stage,
        TrainingSessionStage.exerciseAnnouncement,
      );

      orchestrator.announcementFinished();
      expect(orchestrator.state.stage, TrainingSessionStage.preparation);
      expect(orchestrator.state.remaining, const Duration(seconds: 5));
    });

    test('learning mode requires a conscious ready action', () {
      final orchestrator = _orchestrator(mode: TrainingSessionMode.tutorial);
      orchestrator.start();
      orchestrator.announcementFinished();

      expect(
        orchestrator.state.stage,
        TrainingSessionStage.exerciseAnnouncement,
      );

      orchestrator.confirmReady();
      expect(orchestrator.state.stage, TrainingSessionStage.preparation);
      expect(orchestrator.state.remaining, const Duration(seconds: 3));
    });

    test('an interrupted announcement must be resumed deliberately', () {
      final orchestrator = _orchestrator();
      orchestrator.start();

      orchestrator.pause(reason: TrainingPauseReason.audioInterruption);
      expect(orchestrator.state.stage, TrainingSessionStage.interrupted);
      expect(
        orchestrator.state.resumeStage,
        TrainingSessionStage.exerciseAnnouncement,
      );

      orchestrator.announcementFinished();
      expect(orchestrator.state.stage, TrainingSessionStage.interrupted);
      orchestrator.resume();
      expect(
        orchestrator.state.stage,
        TrainingSessionStage.exerciseAnnouncement,
      );
    });

    test('pause and resume preserve the exact remaining timeline', () {
      final orchestrator = _orchestrator();
      orchestrator.start();
      orchestrator.announcementFinished();
      orchestrator.advance(const Duration(seconds: 5));
      orchestrator.advance(const Duration(milliseconds: 750));
      final beforePause = orchestrator.state;

      orchestrator.pause();
      orchestrator.advance(const Duration(hours: 3));

      expect(orchestrator.state.stepElapsed, beforePause.stepElapsed);
      expect(orchestrator.state.remaining, beforePause.remaining);
      expect(orchestrator.state.repetitionIndex, 0);
      expect(orchestrator.state.phaseIndex, 0);

      orchestrator.resume();
      orchestrator.advance(beforePause.remaining);
      expect(orchestrator.state.phaseIndex, 1);
      expect(orchestrator.state.repetitionIndex, 0);
    });

    test('rapid pause-resume calls are balanced and never advance time', () {
      final orchestrator = _orchestrator();
      final signals = <TrainingSessionSignalType>[];
      orchestrator.signals.listen((signal) => signals.add(signal.type));
      orchestrator.start();
      orchestrator.announcementFinished();
      orchestrator.advance(const Duration(seconds: 5));
      orchestrator.advance(const Duration(milliseconds: 750));
      final before = orchestrator.state;
      final beatCountBefore = signals
          .where((type) => type == TrainingSessionSignalType.beat)
          .length;

      for (var cycle = 0; cycle < 50; cycle++) {
        orchestrator.pause();
        orchestrator.pause(reason: TrainingPauseReason.lifecycle);
        orchestrator.advance(const Duration(hours: 1));
        expect(orchestrator.state.stepElapsed, before.stepElapsed);
        expect(orchestrator.state.remaining, before.remaining);

        orchestrator.resume();
        orchestrator.resume();
      }

      expect(orchestrator.state.stage, before.stage);
      expect(orchestrator.state.stepElapsed, before.stepElapsed);
      expect(orchestrator.state.remaining, before.remaining);
      expect(orchestrator.state.pauseReason, isNull);
      expect(orchestrator.state.resumeStage, isNull);
      expect(
        signals.where((type) => type == TrainingSessionSignalType.paused),
        hasLength(50),
      );
      expect(
        signals.where((type) => type == TrainingSessionSignalType.resumed),
        hasLength(50),
      );
      expect(
        signals.where((type) => type == TrainingSessionSignalType.beat),
        hasLength(beatCountBefore),
      );

      orchestrator.advance(before.remaining);
      expect(orchestrator.state.phaseIndex, 1);
      expect(orchestrator.state.repetitionIndex, 0);
    });

    test('cancel is terminal, clears pause metadata and emits exactly once',
        () {
      final orchestrator = _orchestrator();
      final states = <TrainingSessionState>[];
      final signals = <TrainingSessionSignalType>[];
      orchestrator.states.listen(states.add);
      orchestrator.signals.listen((signal) => signals.add(signal.type));
      orchestrator.start();
      orchestrator.announcementFinished();
      orchestrator.advance(const Duration(seconds: 2));
      orchestrator.pause(reason: TrainingPauseReason.lifecycle);

      orchestrator.cancel();
      final cancelled = orchestrator.state;
      orchestrator.cancel();
      orchestrator.resume();
      orchestrator.start();
      orchestrator.announcementFinished();
      orchestrator.repeatCurrentInstruction();
      orchestrator.advance(const Duration(days: 1));

      expect(orchestrator.state.toJson(), cancelled.toJson());
      expect(orchestrator.state.stage, TrainingSessionStage.cancelled);
      expect(orchestrator.state.pauseReason, isNull);
      expect(orchestrator.state.resumeStage, isNull);
      expect(
        states.where(
          (state) => state.stage == TrainingSessionStage.cancelled,
        ),
        hasLength(1),
      );
      expect(
        signals.where((type) => type == TrainingSessionSignalType.cancelled),
        hasLength(1),
      );
      expect(
        signals,
        isNot(contains(TrainingSessionSignalType.sessionCompleted)),
      );
    });

    test('pace change preserves fractional phase progress', () {
      final orchestrator = _orchestrator();
      orchestrator.start();
      orchestrator.announcementFinished();
      orchestrator.advance(const Duration(seconds: 5));
      orchestrator.advance(const Duration(milliseconds: 500));

      expect(orchestrator.state.stepProgress, 0.25);
      expect(orchestrator.tempoSecondsFor('one'), 3);
      orchestrator.setTempoSeconds('one', 6);

      expect(orchestrator.state.stepProgress, 0.25);
      expect(orchestrator.state.stepDuration, const Duration(seconds: 4));
      expect(orchestrator.state.stepElapsed, const Duration(seconds: 1));
      expect(orchestrator.currentBeat, 1);
    });

    test('released Moro tempo defaults preserve exact configured phases', () {
      final orchestrator = SessionOrchestrator(
        exercises: moroExercises,
        sessionId: 'moro-timing',
        packageId: 'moro',
        contentVersion: 'moro-v1',
        mode: TrainingSessionMode.routine,
        routinePreparationDuration: const Duration(seconds: 10),
      );

      orchestrator.start();
      orchestrator.announcementFinished();
      orchestrator.advance(const Duration(seconds: 10));

      expect(orchestrator.tempoSecondsFor('moro_ex1'), 3);
      expect(orchestrator.state.stepDuration, const Duration(seconds: 3));
      expect(orchestrator.beatsInCurrentStep, 3);

      orchestrator.advance(const Duration(seconds: 3));
      expect(orchestrator.state.phaseIndex, 1);
      expect(orchestrator.state.stepDuration, const Duration(seconds: 1));

      orchestrator.advance(const Duration(seconds: 1));
      expect(orchestrator.state.phaseIndex, 2);
      expect(orchestrator.state.stepDuration, const Duration(seconds: 3));
    });

    test('hold/rest tempo is the hold duration, never a multiplier', () {
      const holdSeven = Exercise(
        id: 'hold-seven',
        packageId: 'hold-package',
        sequenceNumber: 1,
        titleDe: 'Halten',
        titleEn: 'Hold',
        positionInstructionsDe: [],
        positionInstructionsEn: [],
        movementInstructionsDe: [],
        movementInstructionsEn: [],
        executionGuideDe: '',
        executionGuideEn: '',
        durationSeconds: 17,
        repetitions: 2,
        imagePath: '',
        rhythmType: RhythmType.holdRest,
        holdSeconds: 7,
        restSeconds: 3,
      );
      final orchestrator = SessionOrchestrator(
        exercises: const [holdSeven],
        sessionId: 'hold-timing',
        packageId: 'hold-package',
        contentVersion: 'v1',
        mode: TrainingSessionMode.routine,
        routinePreparationDuration: const Duration(seconds: 1),
        tempoSecondsByExerciseId: const {'hold-seven': 7},
      );

      orchestrator.start();
      orchestrator.announcementFinished();
      orchestrator.advance(const Duration(seconds: 1));

      expect(orchestrator.tempoSecondsFor('hold-seven'), 7);
      expect(orchestrator.state.stepDuration, const Duration(seconds: 7));
      expect(orchestrator.beatsInCurrentStep, 7);

      orchestrator.advance(const Duration(seconds: 7));
      expect(orchestrator.state.stage, TrainingSessionStage.recovery);
      expect(orchestrator.state.stepDuration, const Duration(seconds: 3));
    });

    test('session progress is monotonic across phases and recovery', () {
      final orchestrator = _orchestrator();
      orchestrator.start();
      orchestrator.announcementFinished();
      orchestrator.advance(const Duration(seconds: 5));
      orchestrator.advance(const Duration(seconds: 1));
      final halfwayThroughFirstPhase = orchestrator.sessionProgress;

      orchestrator.advance(const Duration(seconds: 1));
      final atSecondPhase = orchestrator.sessionProgress;
      orchestrator.advance(const Duration(seconds: 1));
      final inRecovery = orchestrator.sessionProgress;
      orchestrator.advance(const Duration(seconds: 2));
      final laterInRecovery = orchestrator.sessionProgress;

      expect(atSecondPhase, greaterThan(halfwayThroughFirstPhase));
      expect(inRecovery, greaterThan(atSecondPhase));
      expect(laterInRecovery, inRecovery);
    });

    test('lifecycle interruption remains paused after foregrounding', () {
      final orchestrator = _orchestrator();
      orchestrator.start();
      orchestrator.announcementFinished();
      orchestrator.advance(const Duration(seconds: 2));

      orchestrator.pause(reason: TrainingPauseReason.lifecycle);
      expect(orchestrator.state.stage, TrainingSessionStage.interrupted);
      expect(
        orchestrator.state.pauseReason,
        TrainingPauseReason.lifecycle,
      );

      orchestrator.advance(const Duration(minutes: 10));
      expect(orchestrator.state.stage, TrainingSessionStage.interrupted);
      orchestrator.resume();
      expect(orchestrator.state.stage, TrainingSessionStage.preparation);
      expect(orchestrator.state.remaining, const Duration(seconds: 3));
    });

    test('never announces a side switch after the last repetition', () {
      final orchestrator = _orchestrator();
      var switchCount = 0;
      orchestrator.signals.listen((signal) {
        if (signal.type == TrainingSessionSignalType.sideSwitch) {
          switchCount++;
        }
      });

      _finishRoutine(orchestrator);

      // Exercise one has two repetitions, so exactly one in-between switch.
      // Exercise two has no switch.
      expect(switchCount, 1);
    });

    test('emits side switch before the recovery cue', () {
      final orchestrator = _orchestrator();
      final signals = <TrainingSessionSignalType>[];
      orchestrator.signals.listen((signal) => signals.add(signal.type));

      orchestrator.start();
      orchestrator.announcementFinished();
      orchestrator.advance(const Duration(seconds: 5));
      orchestrator.advance(const Duration(seconds: 2));
      orchestrator.advance(const Duration(seconds: 1));

      final switchIndex = signals.indexOf(TrainingSessionSignalType.sideSwitch);
      final recoveryIndex =
          signals.indexOf(TrainingSessionSignalType.recoveryStarted);
      expect(switchIndex, greaterThanOrEqualTo(0));
      expect(recoveryIndex, greaterThan(switchIndex));
    });

    test('emits completion exactly once', () {
      final orchestrator = _orchestrator();
      var completionCount = 0;
      orchestrator.signals.listen((signal) {
        if (signal.type == TrainingSessionSignalType.sessionCompleted) {
          completionCount++;
        }
      });

      _finishRoutine(orchestrator);
      orchestrator.advance(const Duration(days: 1));
      orchestrator.start();
      orchestrator.cancel();

      expect(orchestrator.state.completedExerciseIds, ['one', 'two']);
      expect(orchestrator.state.stage, TrainingSessionStage.completed);
      expect(completionCount, 1);
    });

    test('dispose is idempotent, closes streams and rejects later mutations',
        () async {
      final orchestrator = _orchestrator();
      var stateDoneCount = 0;
      var signalDoneCount = 0;
      orchestrator.states.listen(
        (_) {},
        onDone: () => stateDoneCount++,
      );
      orchestrator.signals.listen(
        (_) {},
        onDone: () => signalDoneCount++,
      );
      orchestrator.start();

      final firstDispose = orchestrator.dispose();
      expect(orchestrator.start, throwsStateError);
      expect(orchestrator.announcementFinished, throwsStateError);
      expect(orchestrator.confirmReady, throwsStateError);
      expect(orchestrator.startNow, throwsStateError);
      expect(orchestrator.repeatCurrentInstruction, throwsStateError);
      expect(orchestrator.pause, throwsStateError);
      expect(orchestrator.resume, throwsStateError);
      expect(orchestrator.cancel, throwsStateError);
      expect(
        () => orchestrator.advance(const Duration(seconds: 1)),
        throwsStateError,
      );
      expect(
        () => orchestrator.setTempoSeconds('one', 3),
        throwsStateError,
      );

      await firstDispose;
      await orchestrator.dispose();

      expect(stateDoneCount, 1);
      expect(signalDoneCount, 1);
    });

    test('restores a checkpoint paused at the exact position', () {
      final original = _orchestrator();
      original.start();
      original.announcementFinished();
      original.advance(const Duration(seconds: 5));
      original.advance(const Duration(milliseconds: 1200));
      final serialized = original.state.toJson();

      final restored = _orchestrator(
        restoredState: TrainingSessionState.fromJson(serialized),
      );

      expect(restored.state.stage, TrainingSessionStage.paused);
      expect(
        restored.state.resumeStage,
        TrainingSessionStage.activeMovement,
      );
      expect(
        restored.state.stepElapsed,
        const Duration(milliseconds: 1200),
      );
      restored.resume();
      expect(
        restored.state.stage,
        TrainingSessionStage.activeMovement,
      );
      expect(
        restored.state.remaining,
        const Duration(milliseconds: 800),
      );
    });

    test('restores a checkpoint during the exercise transition', () {
      final original = _orchestrator();
      original.start();
      original.announcementFinished();
      original.advance(const Duration(seconds: 5));
      original.advance(const Duration(seconds: 2));
      original.advance(const Duration(seconds: 1));
      original.advance(const Duration(seconds: 3));
      original.advance(const Duration(seconds: 2));
      original.advance(const Duration(seconds: 1));

      expect(
        original.state.stage,
        TrainingSessionStage.exerciseTransition,
      );
      expect(original.state.completedExerciseIds, ['one']);

      final restored = _orchestrator(
        restoredState: TrainingSessionState.fromJson(original.state.toJson()),
      );

      expect(restored.state.stage, TrainingSessionStage.paused);
      expect(
        restored.state.resumeStage,
        TrainingSessionStage.exerciseTransition,
      );
      expect(restored.state.completedExerciseIds, ['one']);
    });

    test('accepts a completed checkpoint for idempotent persistence retry', () {
      final original = _orchestrator();
      _finishRoutine(original);

      final restored = _orchestrator(
        restoredState: TrainingSessionState.fromJson(original.state.toJson()),
      );

      expect(restored.state.stage, TrainingSessionStage.completed);
      expect(restored.state.completedExerciseIds, ['one', 'two']);
    });

    test('runs the full released Moro routine with fake elapsed time', () {
      final orchestrator = SessionOrchestrator(
        exercises: moroExercises,
        sessionId: 'moro-session',
        packageId: 'moro',
        contentVersion: 'moro-v1',
        mode: TrainingSessionMode.routine,
        routinePreparationDuration: const Duration(seconds: 10),
      );
      var completionCount = 0;
      orchestrator.signals.listen((signal) {
        if (signal.type == TrainingSessionSignalType.sessionCompleted) {
          completionCount++;
        }
      });

      _finishRoutine(orchestrator);

      expect(
        orchestrator.state.completedExerciseIds,
        moroExercises.map((exercise) => exercise.id),
      );
      expect(completionCount, 1);
    });
  });
}
