import '../models/exercise.dart';

/// Immutable, versioned exercise content used for one training contract.
class TrainingContentSnapshot {
  const TrainingContentSnapshot({
    required this.packageId,
    required this.version,
    required this.exercises,
  });

  final String packageId;
  final String version;
  final List<Exercise> exercises;
}

/// Increment this only when released Moro guidance or timing changes.
const moroContentVersion = 'moro-2026.08.10-v2';

/// Canonical Moro contract for offline use and cache validation.
const moroContentSnapshot = TrainingContentSnapshot(
  packageId: 'moro',
  version: moroContentVersion,
  exercises: moroExercises,
);
