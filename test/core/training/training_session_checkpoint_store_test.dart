import 'package:corejourney/core/training/training_session_checkpoint_store.dart';
import 'package:corejourney/features/training/domain/models/training_session.dart';
import 'package:corejourney/features/training/domain/session/session_orchestrator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/rejecting_shared_preferences_store.dart';

TrainingSessionState _state({
  String contentVersion = 'v1',
  TrainingSessionStage stage = TrainingSessionStage.activeMovement,
}) {
  return TrainingSessionState(
    sessionId: 'session',
    packageId: 'moro',
    contentVersion: contentVersion,
    mode: TrainingSessionMode.routine,
    stage: stage,
    exerciseIndex: 2,
    repetitionIndex: 1,
    phaseIndex: 0,
    stepElapsed: const Duration(milliseconds: 1750),
    stepDuration: const Duration(seconds: 3),
    completedExerciseIds: const ['moro_ex1', 'moro_ex2'],
  );
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('round-trips exact remaining state', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = TrainingSessionCheckpointStore(prefs);

    await store.save(profileId: 'profile-a', state: _state());
    final restored = store.load(
      profileId: 'profile-a',
      packageId: 'moro',
      contentVersion: 'v1',
    );

    expect(restored, isNotNull);
    expect(restored!.sessionId, 'session');
    expect(restored.exerciseIndex, 2);
    expect(restored.repetitionIndex, 1);
    expect(restored.remaining, const Duration(milliseconds: 1250));
  });

  test('is isolated by profile, package and content version', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = TrainingSessionCheckpointStore(prefs);
    await store.save(profileId: 'profile-a', state: _state());

    expect(
      store.load(
        profileId: 'profile-b',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      isNull,
    );
    expect(
      store.load(
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v2',
      ),
      isNull,
    );
  });

  test('completed state remains until persistence succeeds', () async {
    final prefs = await SharedPreferences.getInstance();
    final store = TrainingSessionCheckpointStore(prefs);
    await store.save(profileId: 'profile-a', state: _state());

    await store.save(
      profileId: 'profile-a',
      state: _state(stage: TrainingSessionStage.completed),
    );

    final loaded = store.load(
      profileId: 'profile-a',
      packageId: 'moro',
      contentVersion: 'v1',
    );
    expect(loaded?.stage, TrainingSessionStage.completed);

    await store.clear(
      profileId: 'profile-a',
      packageId: 'moro',
      contentVersion: 'v1',
    );
    expect(
        store.load(
          profileId: 'profile-a',
          packageId: 'moro',
          contentVersion: 'v1',
        ),
        isNull);
  });

  test('surfaces a platform-rejected checkpoint write', () async {
    installRejectingSharedPreferencesStore(rejectWrites: true);
    final prefs = await SharedPreferences.getInstance();
    final store = TrainingSessionCheckpointStore(prefs);

    await expectLater(
      store.save(profileId: 'profile-a', state: _state()),
      throwsStateError,
    );
  });

  test('surfaces a platform-rejected checkpoint clear', () async {
    installRejectingSharedPreferencesStore(rejectRemovals: true);
    final prefs = await SharedPreferences.getInstance();
    final store = TrainingSessionCheckpointStore(prefs);

    await expectLater(
      store.clear(
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      throwsStateError,
    );
  });

  test('a failed best-effort write does not poison later checkpoints',
      () async {
    var calls = 0;
    final saved = <TrainingSessionState>[];
    final writer = TrainingSessionCheckpointWriteQueue(
      save: (state) async {
        calls++;
        if (calls == 1) throw StateError('temporary storage failure');
        saved.add(state);
      },
    );

    writer.enqueue(_state());
    await writer.flush();
    expect(writer.lastBestEffortError, isA<StateError>());

    final later = _state(contentVersion: 'v2');
    writer.enqueue(later);
    await writer.flush();

    expect(calls, 2);
    expect(saved, [later]);
    expect(writer.lastBestEffortError, isNull);
  });

  test('a required completed checkpoint can be retried after failure',
      () async {
    var shouldFail = true;
    final writer = TrainingSessionCheckpointWriteQueue(
      save: (_) async {
        if (shouldFail) throw StateError('disk busy');
      },
    );
    final completed = _state(stage: TrainingSessionStage.completed);

    await expectLater(writer.saveRequired(completed), throwsStateError);
    shouldFail = false;
    await writer.saveRequired(completed);
  });
}
