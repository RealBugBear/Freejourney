import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Moro training contract', () {
    test('keeps the released 5 → 3 → 4 → 1 → 2 → 6 → 7 order', () {
      expect(
        moroExercises.map((exercise) => exercise.id),
        const [
          'moro_ex1',
          'moro_ex2',
          'moro_ex3',
          'moro_ex4',
          'moro_ex5',
          'moro_ex6',
          'moro_ex7',
        ],
      );
      expect(
        moroExercises.map((exercise) => exercise.titleDe),
        const [
          'Moro 5',
          'Moro 3 – Halber Frosch',
          'Moro 4 – Frosch',
          'Moro 1',
          'Moro 2',
          'Moro 6 – Isometrischer Gegendruck',
          'Moro 7 – Überkreuzter Gegendruck',
        ],
      );
      expect(
        moroExercises.map((exercise) => exercise.sequenceNumber),
        orderedEquals(const [1, 2, 3, 4, 5, 6, 7]),
      );
    });

    test('keeps released repetition and phase timing', () {
      expect(
        moroExercises.map((exercise) => exercise.repetitions),
        orderedEquals(const [3, 3, 3, 3, 3, 6, 6]),
      );
      expect(
        moroExercises
            .map(
              (exercise) => exercise.phases
                  .map((phase) => phase.durationSeconds)
                  .toList(growable: false),
            )
            .toList(growable: false),
        equals(const [
          [3, 1, 3],
          [3, 3],
          [3, 3],
          [3, 3, 3, 3],
          [1, 3, 1, 2],
          <int>[],
          <int>[],
        ]),
      );
      expect(moroExercises[5].holdSeconds, 7);
      expect(moroExercises[6].holdSeconds, 7);
      expect(moroExercises[5].restSeconds, 3);
      expect(moroExercises[6].restSeconds, 3);
    });
  });
}
