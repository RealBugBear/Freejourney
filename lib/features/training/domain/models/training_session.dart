enum TrainingSessionMode { tutorial, routine }

class TrainingSessionResult {
  final String id;
  final String enrollmentId;
  final DateTime sessionDate;
  final int dayNumber;
  final List<String> completedExerciseIds;
  final bool isCompleted;
  final DateTime? completedAt;

  const TrainingSessionResult({
    required this.id,
    required this.enrollmentId,
    required this.sessionDate,
    required this.dayNumber,
    required this.completedExerciseIds,
    this.isCompleted = false,
    this.completedAt,
  });
}
