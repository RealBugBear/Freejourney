import 'dart:io';

import 'package:corejourney/features/training/domain/content/moro_media_manifest.dart';
import 'package:corejourney/features/training/domain/content/training_content_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('canonical Moro content snapshot', () {
    test('pins version, IDs, order, repetitions and timing', () {
      expect(moroContentSnapshot.packageId, 'moro');
      expect(moroContentSnapshot.version, 'moro-2026.08.10-v2');
      expect(
        moroContentSnapshot.exercises.map((exercise) => exercise.id),
        orderedEquals(const [
          'moro_ex1',
          'moro_ex2',
          'moro_ex3',
          'moro_ex4',
          'moro_ex5',
          'moro_ex6',
          'moro_ex7',
        ]),
      );
      expect(
        moroContentSnapshot.exercises
            .map((exercise) => exercise.sequenceNumber),
        orderedEquals(const [1, 2, 3, 4, 5, 6, 7]),
      );
      expect(
        moroContentSnapshot.exercises.map((exercise) => exercise.titleDe),
        orderedEquals(const [
          'Moro 5',
          'Moro 3 – Halber Frosch',
          'Moro 4 – Frosch',
          'Moro 1',
          'Moro 2',
          'Moro 6 – Isometrischer Gegendruck',
          'Moro 7 – Überkreuzter Gegendruck',
        ]),
      );
      expect(
        moroContentSnapshot.exercises.map((exercise) => exercise.repetitions),
        orderedEquals(const [3, 3, 3, 3, 3, 6, 6]),
      );
      expect(
        moroContentSnapshot.exercises
            .map((exercise) => exercise.durationSeconds),
        orderedEquals(const [40, 40, 35, 45, 30, 90, 90]),
      );
      expect(
        moroContentSnapshot.exercises
            .map(
              (exercise) => exercise.phases
                  .map((phase) => phase.durationSeconds)
                  .toList(),
            )
            .toList(),
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
      expect(
        moroContentSnapshot.exercises
            .skip(5)
            .map((exercise) => exercise.holdSeconds),
        everyElement(7),
      );
      expect(
        moroContentSnapshot.exercises
            .skip(5)
            .map((exercise) => exercise.restSeconds),
        everyElement(3),
      );
    });

    test('has concise and equivalent DE/EN guidance fields', () {
      for (final exercise in moroContentSnapshot.exercises) {
        expect(
          exercise.positionInstructionsDe,
          isNotEmpty,
          reason: '${exercise.id} needs German position guidance.',
        );
        expect(exercise.positionInstructionsDe.length, lessThanOrEqualTo(3));
        expect(exercise.positionInstructionsEn.length, lessThanOrEqualTo(3));
        expect(
          exercise.positionInstructionsEn.length,
          exercise.positionInstructionsDe.length,
        );
        expect(
          exercise.movementInstructionsEn.length,
          exercise.movementInstructionsDe.length,
        );
        expect(exercise.orientationDe.trim(), isNotEmpty);
        expect(exercise.orientationEn.trim(), isNotEmpty);
        expect(exercise.breathingDe?.trim(), isNotEmpty);
        expect(exercise.breathingEn?.trim(), isNotEmpty);
        expect(exercise.routineCueDe.trim(), isNotEmpty);
        expect(exercise.routineCueEn.trim(), isNotEmpty);
        expect(exercise.safetyNoteDe, contains('Stoppe'));
        expect(exercise.safetyNoteEn, contains('Stop'));

        final allCopy = <String>[
          ...exercise.positionInstructionsDe,
          ...exercise.positionInstructionsEn,
          ...exercise.movementInstructionsDe,
          ...exercise.movementInstructionsEn,
          ...?exercise.hintsDe,
          ...?exercise.hintsEn,
          exercise.executionGuideDe,
          exercise.executionGuideEn,
          exercise.orientationDe,
          exercise.orientationEn,
          exercise.routineCueDe,
          exercise.routineCueEn,
        ].join(' ');
        expect(allCopy.toLowerCase(), isNot(contains('range of motion')));
      }
    });
  });

  group('Moro media manifest', () {
    test('maps released images and declares no bundled videos', () {
      expect(
        moroMediaManifest.map((media) => media.bundledImagePath),
        orderedEquals(const [
          moroExercise1ImagePath,
          moroExercise2ImagePath,
          moroExercise3ImagePath,
          moroExercise4ImagePath,
          moroExercise5ImagePath,
          moroExercise6ImagePath,
          moroExercise7ImagePath,
        ]),
      );
      expect(
        moroMediaManifest.map((media) => media.bundledVideoPath),
        everyElement(isNull),
      );
      expect(
        moroContentSnapshot.exercises.map((exercise) => exercise.videoPath),
        everyElement(isNull),
      );
      expect(moroContentSnapshot.exercises.last.hasBundledImage, isTrue);
      expect(
        moroContentSnapshot.exercises.last.imagePath,
        moroExercise7ImagePath,
      );
    });

    test('every declared bundled image exists', () {
      for (final media in moroMediaManifest) {
        final path = media.bundledImagePath;
        if (path == null) continue;
        expect(
          File(path).existsSync(),
          isTrue,
          reason: '${media.exerciseId} references missing asset "$path".',
        );
      }
    });

    test('prepared backend migration carries the same media contract', () {
      final migration = File(
        'supabase/migrations/2026081001_finalized_training_images.sql',
      ).readAsStringSync();

      for (final path in const [
        moroExercise1ImagePath,
        moroExercise2ImagePath,
        moroExercise3ImagePath,
        moroExercise4ImagePath,
        moroExercise5ImagePath,
        moroExercise6ImagePath,
        moroExercise7ImagePath,
      ]) {
        expect(migration, contains(path));
      }
      expect(migration, isNot(contains('assets/videos/moro')));
      expect(migration.toLowerCase(), isNot(contains('range of motion')));
    });
  });
}
