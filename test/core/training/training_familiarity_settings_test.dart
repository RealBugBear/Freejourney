import 'package:corejourney/core/training/training_familiarity_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/rejecting_shared_preferences_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('progression is scoped by profile, package and content version',
      () async {
    final prefs = await SharedPreferences.getInstance();

    await TrainingFamiliaritySettings.recordCompletion(
      prefs,
      profileId: 'profile-a',
      packageId: 'moro',
      contentVersion: 'v1',
    );

    expect(
      TrainingFamiliaritySettings.completedSessions(
        prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      1,
    );
    expect(
      TrainingFamiliaritySettings.completedSessions(
        prefs,
        profileId: 'profile-b',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      0,
    );
    expect(
      TrainingFamiliaritySettings.completedSessions(
        prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v2',
      ),
      0,
    );
  });

  test('records the same persisted session only once', () async {
    final prefs = await SharedPreferences.getInstance();

    for (var attempt = 0; attempt < 2; attempt++) {
      await TrainingFamiliaritySettings.recordCompletion(
        prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v1',
        sessionId: 'session-1',
      );
    }

    expect(
      TrainingFamiliaritySettings.completedSessions(
        prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      1,
    );
  });

  test('parallel retries of the same persisted session remain idempotent',
      () async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      TrainingFamiliaritySettings.recordCompletion(
        prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v1',
        sessionId: 'session-1',
      ),
      TrainingFamiliaritySettings.recordCompletion(
        prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v1',
        sessionId: 'session-1',
      ),
    ]);

    expect(
      TrainingFamiliaritySettings.completedSessions(
        prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      1,
    );
  });

  test('parallel distinct persisted sessions are both retained', () async {
    final prefs = await SharedPreferences.getInstance();

    await Future.wait([
      TrainingFamiliaritySettings.recordCompletion(
        prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v1',
        sessionId: 'session-1',
      ),
      TrainingFamiliaritySettings.recordCompletion(
        prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v1',
        sessionId: 'session-2',
      ),
    ]);

    expect(
      TrainingFamiliaritySettings.completedSessions(
        prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      2,
    );
  });

  test('does not report completion when the platform rejects the ledger write',
      () async {
    installRejectingSharedPreferencesStore(rejectWrites: true);
    final prefs = await SharedPreferences.getInstance();

    await expectLater(
      TrainingFamiliaritySettings.recordCompletion(
        prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v1',
        sessionId: 'session-1',
      ),
      throwsStateError,
    );
  });

  test('a rejected ledger write is retried instead of trusted from RAM',
      () async {
    final platform =
        installRejectingSharedPreferencesStore(rejectNextWrites: 1);
    final prefs = await SharedPreferences.getInstance();

    Future<int> record() => TrainingFamiliaritySettings.recordCompletion(
          prefs,
          profileId: 'profile-a',
          packageId: 'moro',
          contentVersion: 'v1',
          sessionId: 'session-1',
        );

    await expectLater(record(), throwsStateError);
    expect(platform.setValueCalls, 1);

    expect(await record(), 1);
    expect(platform.setValueCalls, 2);

    SharedPreferences.resetStatic();
    final reloaded = await SharedPreferences.getInstance();
    expect(
      TrainingFamiliaritySettings.completedSessions(
        reloaded,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v1',
      ),
      1,
    );
  });

  test('recommends routine only after two completed sessions', () {
    expect(TrainingFamiliaritySettings.shouldRecommendRoutine(0), isFalse);
    expect(TrainingFamiliaritySettings.shouldRecommendRoutine(1), isFalse);
    expect(TrainingFamiliaritySettings.shouldRecommendRoutine(2), isTrue);
  });
}
