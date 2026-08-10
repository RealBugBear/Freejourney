import 'dart:async';

import 'package:corejourney/core/database/app_database.dart';
import 'package:corejourney/core/sync/exercises_sync_service.dart';
import 'package:corejourney/features/training/domain/content/training_content_snapshot.dart';
import 'package:corejourney/features/training/domain/models/exercise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ExercisesSyncService service;

  setUp(() {
    db = AppDatabase.inMemory();
    service = ExercisesSyncService(db);
  });

  tearDown(() => db.close());

  test('rejects an empty or changed Moro response before cache mutation',
      () async {
    expect(
      () => ExercisesSyncService.validateRemoteSnapshotForCache(const []),
      throwsStateError,
    );
    final changed = _moroRows();
    changed.first['sequence_number'] = 7;
    expect(
      () => ExercisesSyncService.validateRemoteSnapshotForCache(changed),
      throwsStateError,
    );
  });

  test('validated refresh atomically removes stale rows', () async {
    final withStale = [
      ..._moroRows(),
      _rowFor(moroContentSnapshot.exercises.first)
        ..['id'] = 'stale'
        ..['package_id'] = 'legacy'
        ..['sequence_number'] = 1,
    ];
    await service.replaceCacheWithValidatedSnapshot(withStale);
    expect(await db.select(db.exercisesTable).get(), hasLength(8));

    await service.replaceCacheWithValidatedSnapshot(_moroRows());
    final rows = await db.select(db.exercisesTable).get();
    expect(rows, hasLength(7));
    expect(rows.any((row) => row.id == 'stale'), isFalse);
  });

  test('validation failure leaves the previous snapshot untouched', () async {
    await service.replaceCacheWithValidatedSnapshot(_moroRows());
    final before = await db.select(db.exercisesTable).get();
    final changed = _moroRows();
    changed.first['sequence_number'] = 7;

    await expectLater(
      service.replaceCacheWithValidatedSnapshot(changed),
      throwsStateError,
    );

    final after = await db.select(db.exercisesTable).get();
    expect(after.map((row) => row.id), before.map((row) => row.id));
    expect(
      after.map((row) => row.sequenceNumber),
      before.map((row) => row.sequenceNumber),
    );
  });

  test('failed replacement rolls back deletion and partial inserts', () async {
    await service.replaceCacheWithValidatedSnapshot(_moroRows());
    final malformed = <String, dynamic>{
      'id': 'malformed',
      'package_id': 'legacy',
    };

    await expectLater(
      service.replaceCacheWithValidatedSnapshot([
        ..._moroRows(),
        malformed,
      ]),
      throwsA(anything),
    );

    final rows = await db.select(db.exercisesTable).get();
    expect(rows, hasLength(7));
    expect(
      rows.map((row) => row.id),
      containsAll(moroContentSnapshot.exercises.map((exercise) => exercise.id)),
    );
  });

  test('parallel validated replacements never expose a mixed snapshot',
      () async {
    final firstSnapshot = [
      ..._moroRows(),
      _legacyRow(id: 'overlay-a'),
    ];
    final secondSnapshot = [
      ..._moroRows(),
      _legacyRow(id: 'overlay-b'),
    ];

    await Future.wait([
      service.replaceCacheWithValidatedSnapshot(firstSnapshot),
      service.replaceCacheWithValidatedSnapshot(secondSnapshot),
    ]);

    final ids =
        (await db.select(db.exercisesTable).get()).map((row) => row.id).toSet();
    final canonicalIds =
        moroContentSnapshot.exercises.map((exercise) => exercise.id).toSet();
    expect(ids.length, canonicalIds.length + 1);
    expect(ids.containsAll(canonicalIds), isTrue);
    expect(
      ids.difference(canonicalIds),
      anyOf(
        equals({'overlay-a'}),
        equals({'overlay-b'}),
      ),
    );
  });

  test('syncIfNeeded repairs a non-empty partial Moro cache', () async {
    await db.into(db.exercisesTable).insert(
          ExercisesTableCompanion.insert(
            id: 'partial',
            packageId: 'moro',
            sequenceNumber: 1,
            titleDe: 'Teil',
            titleEn: 'Partial',
            positionInstructionsDe: '[]',
            positionInstructionsEn: '[]',
            movementInstructionsDe: '[]',
            movementInstructionsEn: '[]',
            executionGuideDe: '',
            executionGuideEn: '',
            durationSeconds: 1,
            repetitions: 1,
            imagePath: '',
          ),
        );
    var loads = 0;
    service = ExercisesSyncService(
      db,
      isConnected: () async => true,
      loadRemoteRows: () async {
        loads++;
        return _moroRows();
      },
    );

    await service.syncIfNeeded();

    expect(loads, 1);
    expect(await db.select(db.exercisesTable).get(), hasLength(7));
  });

  test('syncIfNeeded repairs a cache row with malformed serialized fields',
      () async {
    await db.into(db.exercisesTable).insert(
          ExercisesTableCompanion.insert(
            id: 'corrupt',
            packageId: 'moro',
            sequenceNumber: 1,
            titleDe: 'Defekt',
            titleEn: 'Corrupt',
            positionInstructionsDe: 'not-json',
            positionInstructionsEn: '[]',
            movementInstructionsDe: '[]',
            movementInstructionsEn: '[]',
            executionGuideDe: '',
            executionGuideEn: '',
            durationSeconds: 1,
            repetitions: 1,
            imagePath: '',
          ),
        );
    var loads = 0;
    service = ExercisesSyncService(
      db,
      isConnected: () async => true,
      loadRemoteRows: () async {
        loads++;
        return _moroRows();
      },
    );

    await service.syncIfNeeded();

    expect(loads, 1);
    expect(await db.select(db.exercisesTable).get(), hasLength(7));
  });

  test('syncIfNeeded skips a fully validated Moro cache', () async {
    await service.replaceCacheWithValidatedSnapshot(_moroRows());
    var loads = 0;
    service = ExercisesSyncService(
      db,
      isConnected: () async => true,
      loadRemoteRows: () async {
        loads++;
        return _moroRows();
      },
    );

    await service.syncIfNeeded();

    expect(loads, 0);
  });

  test('overlapping refresh requests share one remote generation', () async {
    final response = Completer<List<dynamic>>();
    var loads = 0;
    service = ExercisesSyncService(
      db,
      isConnected: () async => true,
      loadRemoteRows: () {
        loads++;
        return response.future;
      },
    );

    final first = service.forceSync();
    final second = service.forceSync();
    await Future<void>.delayed(Duration.zero);
    expect(loads, 1);

    response.complete(_moroRows());
    await Future.wait([first, second]);

    expect(await db.select(db.exercisesTable).get(), hasLength(7));
  });
}

List<Map<String, dynamic>> _moroRows() =>
    moroContentSnapshot.exercises.map(_rowFor).toList();

Map<String, dynamic> _rowFor(Exercise exercise) {
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
    'duration_seconds': exercise.durationSeconds,
    'repetitions': exercise.repetitions,
    'image_path': exercise.imagePath,
    'video_path': exercise.videoPath,
    'duo_image_path': exercise.duoImagePath,
    'image_url': exercise.imageUrl,
    'duo_image_url': exercise.duoImageUrl,
    'video_url': exercise.videoUrl,
    'audio_cue_path': exercise.audioCuePath,
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
  };
}

Map<String, dynamic> _legacyRow({required String id}) {
  return _rowFor(moroContentSnapshot.exercises.first)
    ..['id'] = id
    ..['package_id'] = 'legacy'
    ..['sequence_number'] = 1;
}
