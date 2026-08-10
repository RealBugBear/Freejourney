import 'package:shared_preferences/shared_preferences.dart';

import 'training_tempo_defaults.dart';

class AdaptiveTempoSettings {
  static const String _tempoKeyPrefix = 'adaptive_tempo_exercise_';
  static const String _scopedTempoKeyPrefix = 'training.adaptiveTempo.v2';

  static String _tempoKey(int exerciseNumber) =>
      '$_tempoKeyPrefix$exerciseNumber';

  static double? tempoForExerciseOrNull(
    SharedPreferences prefs,
    int exerciseNumber,
  ) {
    return prefs.getDouble(_tempoKey(exerciseNumber));
  }

  static String _scopedKey({
    required String profileId,
    required String packageId,
    required String contentVersion,
    required String exerciseId,
  }) {
    return [
      _scopedTempoKeyPrefix,
      Uri.encodeComponent(profileId),
      Uri.encodeComponent(packageId),
      Uri.encodeComponent(contentVersion),
      Uri.encodeComponent(exerciseId),
    ].join('.');
  }

  /// Returns a profile- and content-scoped tempo.
  ///
  /// The old sequence-only value is read as a one-way fallback so existing
  /// users keep their preferred pace. New writes always use the scoped key.
  static double? tempoForExercise({
    required SharedPreferences prefs,
    required String profileId,
    required String packageId,
    required String contentVersion,
    required String exerciseId,
    required int legacyExerciseNumber,
  }) {
    return prefs.getDouble(
          _scopedKey(
            profileId: profileId,
            packageId: packageId,
            contentVersion: contentVersion,
            exerciseId: exerciseId,
          ),
        ) ??
        tempoForExerciseOrNull(prefs, legacyExerciseNumber);
  }

  static Future<void> saveScopedTempo({
    required SharedPreferences prefs,
    required String profileId,
    required String packageId,
    required String contentVersion,
    required String exerciseId,
    required int exerciseNumber,
    required double tempoSeconds,
  }) {
    final clamped = tempoSeconds.clamp(
      minTempoForExercise(exerciseNumber),
      maxTempoForExercise(exerciseNumber),
    );
    return prefs.setDouble(
      _scopedKey(
        profileId: profileId,
        packageId: packageId,
        contentVersion: contentVersion,
        exerciseId: exerciseId,
      ),
      clamped,
    );
  }

  static Future<void> saveTempoForExercise(
    SharedPreferences prefs, {
    required int exerciseNumber,
    required double tempoSeconds,
  }) {
    final clamped = tempoSeconds.clamp(
      minTempoForExercise(exerciseNumber),
      maxTempoForExercise(exerciseNumber),
    );
    return prefs.setDouble(_tempoKey(exerciseNumber), clamped);
  }
}
