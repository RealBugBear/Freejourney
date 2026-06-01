import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:corejourney/features/training/domain/models/training_session.dart';
import 'package:corejourney/features/training/presentation/providers/training_flow_provider.dart';

Exercise _exercise(String id, int sequenceNumber) => Exercise(
      id: id,
      packageId: 'moro',
      sequenceNumber: sequenceNumber,
      titleDe: 'Uebung $sequenceNumber',
      titleEn: 'Exercise $sequenceNumber',
      positionInstructionsDe: const ['Position'],
      positionInstructionsEn: const ['Position'],
      movementInstructionsDe: const ['Bewegung'],
      movementInstructionsEn: const ['Movement'],
      executionGuideDe: 'Anleitung',
      executionGuideEn: 'Guide',
      durationSeconds: 30,
      repetitions: 1,
      imagePath: 'assets/test.png',
    );

void main() {
  final exercises = [_exercise('one', 1), _exercise('two', 2)];

  TrainingFlowNotifier notifier({
    TrainingSessionMode mode = TrainingSessionMode.tutorial,
    bool requiresDisclaimer = false,
  }) {
    return TrainingFlowNotifier(
      exercises: exercises,
      mode: mode,
      requiresDisclaimer: requiresDisclaimer,
    );
  }

  group('TrainingFlowNotifier regression', () {
    test('routine starts movement after intro', () {
      final flow = notifier(mode: TrainingSessionMode.routine);

      expect(flow.state.step, TrainingFlowStep.intro);

      flow.startSession();

      expect(flow.state.mode, TrainingSessionMode.routine);
      expect(flow.state.step, TrainingFlowStep.movement);
      expect(flow.state.currentExerciseIndex, 0);
    });

    test('tutorial starts with video and advances to position', () {
      final flow = notifier();

      flow.startSession();
      expect(flow.state.step, TrainingFlowStep.video);

      flow.videoReady();
      expect(flow.state.step, TrainingFlowStep.position);
      expect(flow.state.currentExerciseIndex, 0);
    });

    test('tutorial readiness steps reach movement', () {
      final flow = notifier();

      flow.startSession();
      flow.videoReady();
      flow.positionReady();
      expect(flow.state.step, TrainingFlowStep.preparation);

      flow.preparationReady();
      expect(flow.state.step, TrainingFlowStep.movement);
    });

    test('non-last exercise completion moves to rest and next exercise', () {
      final flow = notifier(mode: TrainingSessionMode.routine);

      flow.startSession();
      flow.exerciseComplete();

      expect(flow.state.completedExerciseIds, ['one']);
      expect(flow.state.currentExerciseIndex, 1);
      expect(flow.state.step, TrainingFlowStep.rest);
      expect(flow.state.isComplete, isFalse);
    });

    test('last exercise completion moves to outro and marks complete', () {
      final flow = notifier(mode: TrainingSessionMode.routine);

      flow.startSession();
      flow.exerciseComplete();
      flow.restComplete();
      flow.exerciseComplete();

      expect(flow.state.completedExerciseIds, ['one', 'two']);
      expect(flow.state.step, TrainingFlowStep.outro);
      expect(flow.state.isComplete, isTrue);
    });

    test('disclaimer starts before intro when required', () {
      final flow = notifier(requiresDisclaimer: true);

      expect(flow.state.showDisclaimer, isTrue);
      expect(flow.state.step, TrainingFlowStep.disclaimer);

      flow.acceptDisclaimer();

      expect(flow.state.showDisclaimer, isFalse);
      expect(flow.state.step, TrainingFlowStep.intro);
    });
  });
}
