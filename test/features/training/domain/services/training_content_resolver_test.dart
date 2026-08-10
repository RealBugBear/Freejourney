import 'package:corejourney/features/training/domain/content/training_content_snapshot.dart';
import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:corejourney/features/training/domain/models/training_session.dart';
import 'package:corejourney/features/training/domain/services/training_content_resolver.dart';
import 'package:corejourney/features/training/presentation/providers/training_flow_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = TrainingContentResolver();

  group('TrainingContentValidator', () {
    test('accepts the exact released Moro contract', () {
      final validation = const TrainingContentValidator().validateSnapshotCache(
        snapshot: moroContentSnapshot,
        cachedExercises: moroContentSnapshot.exercises,
      );

      expect(validation.isValid, isTrue);
      expect(validation.issues, isEmpty);
    });

    test('rejects changed order and timing', () {
      final wrongOrder = [...moroContentSnapshot.exercises];
      final first = wrongOrder.removeAt(0);
      wrongOrder.insert(1, first);
      var validation = const TrainingContentValidator().validateSnapshotCache(
        snapshot: moroContentSnapshot,
        cachedExercises: wrongOrder,
      );

      expect(validation.isValid, isFalse);
      expect(
        validation.issues.map((issue) => issue.code),
        contains(TrainingContentValidationCode.idMismatch),
      );

      final wrongTiming = [...moroContentSnapshot.exercises];
      wrongTiming[0] = _fromCanonical(
        wrongTiming[0],
        durationSeconds: wrongTiming[0].durationSeconds + 1,
      );
      validation = const TrainingContentValidator().validateSnapshotCache(
        snapshot: moroContentSnapshot,
        cachedExercises: wrongTiming,
      );

      expect(validation.isValid, isFalse);
      expect(
        validation.issues.map((issue) => issue.code),
        contains(TrainingContentValidationCode.durationMismatch),
      );
    });
  });

  group('TrainingContentResolver', () {
    test('serves stable bundled Moro content while cache is empty', () {
      final resolution = resolver.resolve(
        packageId: 'moro',
        cachedExercises: const [],
      );

      expect(resolution.exercises, same(moroContentSnapshot.exercises));
      expect(resolution.version, moroContentVersion);
      expect(resolution.source, TrainingContentSource.bundledSnapshot);
      expect(resolution.issue?.code, TrainingContentIssueCode.emptyCache);
    });

    test('uses validated cache only as secure remote media overlay', () {
      final cached = <Exercise>[
        Exercise.fromRow(
          _rowFor(
            moroContentSnapshot.exercises.first,
            imagePath: 'assets/images/trainings/moro/deleted-legacy.png',
            videoPath: 'assets/videos/moro/not-bundled.mov',
            imageUrl: 'https://cdn.example.test/moro-5.png',
            videoUrl: 'https://cdn.example.test/moro-5.mp4',
          ),
        ),
        ...moroContentSnapshot.exercises.skip(1),
      ];

      final resolution = resolver.resolve(
        packageId: 'moro',
        cachedExercises: cached,
      );

      expect(resolution.source, TrainingContentSource.validatedCache);
      expect(resolution.issue, isNull);
      expect(
        resolution.exercises.first.imageUrl,
        'https://cdn.example.test/moro-5.png',
      );
      expect(
        resolution.exercises.first.videoUrl,
        'https://cdn.example.test/moro-5.mp4',
      );
      expect(
        resolution.exercises.first.positionInstructionsDe,
        moroContentSnapshot.exercises.first.positionInstructionsDe,
        reason: 'Cached copy must not replace canonical guidance.',
      );
      expect(
        resolution.exercises.first.imagePath,
        moroContentSnapshot.exercises.first.imagePath,
      );
      expect(resolution.exercises.first.videoPath, isNull);
    });

    test('invalid cache falls back to the canonical Moro snapshot', () {
      final invalidCache = [...moroContentSnapshot.exercises.reversed];

      final resolution = resolver.resolve(
        packageId: 'moro',
        cachedExercises: invalidCache,
      );

      expect(resolution.source, TrainingContentSource.bundledSnapshot);
      expect(resolution.issue?.code, TrainingContentIssueCode.invalidCache);
      expect(resolution.validationIssues, isNotEmpty);
      expect(
        resolution.exercises.map((exercise) => exercise.id),
        orderedEquals(
          moroContentSnapshot.exercises.map((exercise) => exercise.id),
        ),
      );
    });

    test('empty or unknown package never falls back to Moro', () {
      for (final packageId in ['', 'not-released']) {
        final resolution = resolver.resolve(
          packageId: packageId,
          cachedExercises: moroContentSnapshot.exercises,
        );

        expect(resolution.exercises, isEmpty);
        expect(resolution.version, isNull);
        expect(resolution.source, TrainingContentSource.unavailable);
        expect(
          resolution.issue?.code,
          TrainingContentIssueCode.unknownPackage,
        );
      }
    });

    test('rejects insecure and malformed remote media URLs', () {
      final http = Exercise.fromRow(
        _rowFor(
          moroContentSnapshot.exercises.first,
          imageUrl: 'http://cdn.example.test/moro.png',
          videoUrl: 'relative/video.mp4',
        ),
      );
      final https = Exercise.fromRow(
        _rowFor(
          moroContentSnapshot.exercises.first,
          imageUrl: '  https://cdn.example.test/moro.png  ',
        ),
      );

      expect(http.imageUrl, isNull);
      expect(http.videoUrl, isNull);
      expect(https.imageUrl, 'https://cdn.example.test/moro.png');
    });
  });

  group('TrainingFlowNotifier content boundary', () {
    test('exposes unavailable state without advancing an empty flow', () {
      final unavailable = resolver.resolve(
        packageId: 'not-released',
        cachedExercises: const [],
      );
      final notifier = TrainingFlowNotifier.fromResolution(
        resolution: unavailable,
        mode: TrainingSessionMode.routine,
        requiresDisclaimer: false,
      );

      expect(notifier.state.hasContent, isFalse);
      expect(notifier.state.currentExerciseOrNull, isNull);
      expect(
        notifier.state.contentIssue?.code,
        TrainingContentIssueCode.unknownPackage,
      );

      notifier.startSession();
      notifier.exerciseComplete();

      expect(notifier.state.step, TrainingFlowStep.intro);
      expect(notifier.state.completedExerciseIds, isEmpty);
    });

    test('does not replace exercises after the flow has started', () {
      final initial = resolver.resolve(
        packageId: 'moro',
        cacheLoading: true,
      );
      final notifier = TrainingFlowNotifier.fromResolution(
        resolution: initial,
        mode: TrainingSessionMode.routine,
        requiresDisclaimer: false,
      );
      notifier.startSession();

      notifier.applyContentResolution(
        TrainingContentResolution(
          packageId: 'moro',
          version: moroContentVersion,
          exercises: [...moroContentSnapshot.exercises.reversed],
          source: TrainingContentSource.validatedCache,
          isCachePending: false,
        ),
      );

      expect(notifier.state.step, TrainingFlowStep.movement);
      expect(
        notifier.state.exercises.map((exercise) => exercise.id),
        orderedEquals(
          moroContentSnapshot.exercises.map((exercise) => exercise.id),
        ),
      );
      expect(
        notifier.state.contentSource,
        TrainingContentSource.bundledSnapshot,
      );
    });
  });
}

Exercise _fromCanonical(
  Exercise exercise, {
  required int durationSeconds,
}) {
  return Exercise.fromRow(
    _rowFor(exercise, durationSeconds: durationSeconds),
  );
}

Map<String, Object?> _rowFor(
  Exercise exercise, {
  int? durationSeconds,
  String? imagePath,
  String? videoPath,
  String? imageUrl,
  String? videoUrl,
}) {
  return {
    'id': exercise.id,
    'package_id': exercise.packageId,
    'sequence_number': exercise.sequenceNumber,
    'title_de': exercise.titleDe,
    'title_en': exercise.titleEn,
    'position_instructions_de': exercise.positionInstructionsDe,
    'position_instructions_en': exercise.positionInstructionsEn,
    'movement_instructions_de': exercise.movementInstructionsDe,
    'movement_instructions_en': exercise.movementInstructionsEn,
    'hints_de': exercise.hintsDe,
    'hints_en': exercise.hintsEn,
    'execution_guide_de': exercise.executionGuideDe,
    'execution_guide_en': exercise.executionGuideEn,
    'duration_seconds': durationSeconds ?? exercise.durationSeconds,
    'repetitions': exercise.repetitions,
    'image_path': imagePath ?? exercise.imagePath,
    'video_path': videoPath ?? exercise.videoPath,
    'rhythm_type': exercise.rhythmType.name,
    'phases_json': exercise.phases
        .map(
          (phase) => {
            'labelDe': phase.labelDe,
            'labelEn': phase.labelEn,
            'durationSeconds': phase.durationSeconds,
          },
        )
        .toList(),
    'has_rep_switch': exercise.hasRepSwitch,
    'hold_cue_de': exercise.holdCueDe,
    'hold_cue_en': exercise.holdCueEn,
    'hold_seconds': exercise.holdSeconds,
    'rest_seconds': exercise.restSeconds,
    'halfway_switch': exercise.halfwaySwitch,
    'image_url': imageUrl,
    'video_url': videoUrl,
  };
}
