import 'package:corejourney/core/training/adaptive_tempo_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('scopes tempo by profile, package, content and exercise', () async {
    final prefs = await SharedPreferences.getInstance();
    await AdaptiveTempoSettings.saveScopedTempo(
      prefs: prefs,
      profileId: 'profile-a',
      packageId: 'moro',
      contentVersion: 'v2',
      exerciseId: 'moro_ex1',
      exerciseNumber: 1,
      tempoSeconds: 1.5,
    );

    expect(
      AdaptiveTempoSettings.tempoForExercise(
        prefs: prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v2',
        exerciseId: 'moro_ex1',
        legacyExerciseNumber: 1,
      ),
      1.5,
    );
    expect(
      AdaptiveTempoSettings.tempoForExercise(
        prefs: prefs,
        profileId: 'profile-b',
        packageId: 'moro',
        contentVersion: 'v2',
        exerciseId: 'moro_ex1',
        legacyExerciseNumber: 2,
      ),
      isNull,
    );
  });

  test('reads the legacy sequence key as a compatibility fallback', () async {
    final prefs = await SharedPreferences.getInstance();
    await AdaptiveTempoSettings.saveTempoForExercise(
      prefs,
      exerciseNumber: 1,
      tempoSeconds: 2,
    );

    expect(
      AdaptiveTempoSettings.tempoForExercise(
        prefs: prefs,
        profileId: 'profile-a',
        packageId: 'moro',
        contentVersion: 'v2',
        exerciseId: 'moro_ex1',
        legacyExerciseNumber: 1,
      ),
      2,
    );
  });
}
