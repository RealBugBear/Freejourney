import '../content/training_content_snapshot.dart';
import '../models/exercise.dart';

enum TrainingContentSource {
  bundledSnapshot,
  validatedCache,
  unavailable,
}

enum TrainingContentIssueCode {
  unknownPackage,
  emptyCache,
  invalidCache,
  cacheReadFailed,
}

class TrainingContentIssue {
  const TrainingContentIssue({
    required this.code,
    required this.message,
  });

  final TrainingContentIssueCode code;
  final String message;
}

enum TrainingContentValidationCode {
  empty,
  countMismatch,
  duplicateId,
  packageMismatch,
  idMismatch,
  sequenceMismatch,
  durationMismatch,
  repetitionsMismatch,
  rhythmMismatch,
  phaseTimingMismatch,
  holdTimingMismatch,
  switchMismatch,
  mediaMismatch,
  invalidRemoteMedia,
}

class TrainingContentValidationIssue {
  const TrainingContentValidationIssue({
    required this.code,
    required this.message,
    this.exerciseId,
  });

  final TrainingContentValidationCode code;
  final String message;
  final String? exerciseId;
}

class TrainingContentValidationResult {
  const TrainingContentValidationResult(this.issues);

  final List<TrainingContentValidationIssue> issues;

  bool get isValid => issues.isEmpty;
}

class TrainingContentResolution {
  const TrainingContentResolution({
    required this.packageId,
    required this.version,
    required this.exercises,
    required this.source,
    required this.isCachePending,
    this.issue,
    this.validationIssues = const [],
  });

  final String packageId;
  final String? version;
  final List<Exercise> exercises;
  final TrainingContentSource source;
  final bool isCachePending;
  final TrainingContentIssue? issue;
  final List<TrainingContentValidationIssue> validationIssues;

  bool get hasContent => exercises.isNotEmpty;
}

class TrainingContentValidator {
  const TrainingContentValidator();

  TrainingContentValidationResult validateSnapshotCache({
    required TrainingContentSnapshot snapshot,
    required List<Exercise> cachedExercises,
  }) {
    final issues = <TrainingContentValidationIssue>[];
    if (cachedExercises.isEmpty) {
      issues.add(
        const TrainingContentValidationIssue(
          code: TrainingContentValidationCode.empty,
          message: 'The cached package contains no exercises.',
        ),
      );
      return TrainingContentValidationResult(List.unmodifiable(issues));
    }

    if (cachedExercises.length != snapshot.exercises.length) {
      issues.add(
        TrainingContentValidationIssue(
          code: TrainingContentValidationCode.countMismatch,
          message: 'Expected ${snapshot.exercises.length} exercises, found '
              '${cachedExercises.length}.',
        ),
      );
    }

    final seenIds = <String>{};
    for (final exercise in cachedExercises) {
      if (!seenIds.add(exercise.id)) {
        issues.add(
          TrainingContentValidationIssue(
            code: TrainingContentValidationCode.duplicateId,
            exerciseId: exercise.id,
            message: 'Exercise ID "${exercise.id}" occurs more than once.',
          ),
        );
      }
    }

    final comparedCount = cachedExercises.length < snapshot.exercises.length
        ? cachedExercises.length
        : snapshot.exercises.length;
    for (var index = 0; index < comparedCount; index++) {
      final expected = snapshot.exercises[index];
      final cached = cachedExercises[index];
      _validateExercise(
        snapshot: snapshot,
        expected: expected,
        cached: cached,
        issues: issues,
      );
    }

    return TrainingContentValidationResult(
      List.unmodifiable(issues),
    );
  }

  void _validateExercise({
    required TrainingContentSnapshot snapshot,
    required Exercise expected,
    required Exercise cached,
    required List<TrainingContentValidationIssue> issues,
  }) {
    void add(TrainingContentValidationCode code, String message) {
      issues.add(
        TrainingContentValidationIssue(
          code: code,
          exerciseId: cached.id,
          message: message,
        ),
      );
    }

    if (cached.packageId != snapshot.packageId) {
      add(
        TrainingContentValidationCode.packageMismatch,
        'Expected package "${snapshot.packageId}", found '
        '"${cached.packageId}".',
      );
    }
    if (cached.id != expected.id) {
      add(
        TrainingContentValidationCode.idMismatch,
        'Expected exercise "${expected.id}" at sequence '
        '${expected.sequenceNumber}, found "${cached.id}".',
      );
    }
    if (cached.sequenceNumber != expected.sequenceNumber) {
      add(
        TrainingContentValidationCode.sequenceMismatch,
        'Expected sequence ${expected.sequenceNumber}, found '
        '${cached.sequenceNumber}.',
      );
    }
    if (cached.durationSeconds != expected.durationSeconds) {
      add(
        TrainingContentValidationCode.durationMismatch,
        'Expected duration ${expected.durationSeconds}, found '
        '${cached.durationSeconds}.',
      );
    }
    if (cached.repetitions != expected.repetitions) {
      add(
        TrainingContentValidationCode.repetitionsMismatch,
        'Expected ${expected.repetitions} repetitions, found '
        '${cached.repetitions}.',
      );
    }
    if (cached.rhythmType != expected.rhythmType) {
      add(
        TrainingContentValidationCode.rhythmMismatch,
        'Expected rhythm ${expected.rhythmType.name}, found '
        '${cached.rhythmType.name}.',
      );
    }
    if (!_samePhaseTiming(cached.phases, expected.phases)) {
      add(
        TrainingContentValidationCode.phaseTimingMismatch,
        'Cached phase timing does not match the released snapshot.',
      );
    }
    if (cached.holdSeconds != expected.holdSeconds ||
        cached.restSeconds != expected.restSeconds) {
      add(
        TrainingContentValidationCode.holdTimingMismatch,
        'Expected hold/rest ${expected.holdSeconds}/'
        '${expected.restSeconds}, found ${cached.holdSeconds}/'
        '${cached.restSeconds}.',
      );
    }
    if (cached.hasRepSwitch != expected.hasRepSwitch ||
        cached.halfwaySwitch != expected.halfwaySwitch) {
      add(
        TrainingContentValidationCode.switchMismatch,
        'Cached side or halfway switch semantics do not match.',
      );
    }
    // Local paths in the remote/cache row are legacy metadata and are never
    // trusted. The resolver always takes bundled paths from the canonical
    // snapshot, while the separate asset contract verifies those files.
    if (!_isValidOptionalRemote(cached.imageUrl) ||
        !_isValidOptionalRemote(cached.duoImageUrl) ||
        !_isValidOptionalRemote(cached.videoUrl)) {
      add(
        TrainingContentValidationCode.invalidRemoteMedia,
        'Cached remote media must use an absolute HTTPS URL.',
      );
    }
  }

  bool _samePhaseTiming(
    List<ExercisePhase> left,
    List<ExercisePhase> right,
  ) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index].durationSeconds != right[index].durationSeconds) {
        return false;
      }
    }
    return true;
  }

  bool _isValidOptionalRemote(String? value) =>
      value == null || validatedRemoteMediaUrl(value) == value;
}

class TrainingContentResolver {
  const TrainingContentResolver({
    this.validator = const TrainingContentValidator(),
  });

  final TrainingContentValidator validator;

  TrainingContentResolution resolve({
    required String packageId,
    List<Exercise>? cachedExercises,
    bool cacheLoading = false,
    Object? cacheError,
  }) {
    final normalizedPackageId = packageId.trim();
    final bundled = _bundledSnapshot(normalizedPackageId);
    if (bundled == null) {
      return TrainingContentResolution(
        packageId: normalizedPackageId,
        version: null,
        exercises: const [],
        source: TrainingContentSource.unavailable,
        isCachePending: false,
        issue: TrainingContentIssue(
          code: TrainingContentIssueCode.unknownPackage,
          message: normalizedPackageId.isEmpty
              ? 'No training package was selected.'
              : 'Training package "$normalizedPackageId" is not released.',
        ),
      );
    }

    if (cacheLoading) {
      return _bundledResolution(
        snapshot: bundled,
        isCachePending: true,
      );
    }
    if (cacheError != null) {
      return _bundledResolution(
        snapshot: bundled,
        issue: const TrainingContentIssue(
          code: TrainingContentIssueCode.cacheReadFailed,
          message: 'The local exercise cache could not be read.',
        ),
      );
    }
    if (cachedExercises == null || cachedExercises.isEmpty) {
      return _bundledResolution(
        snapshot: bundled,
        issue: const TrainingContentIssue(
          code: TrainingContentIssueCode.emptyCache,
          message: 'The local exercise cache is empty; bundled content is in '
              'use.',
        ),
      );
    }

    final validation = validator.validateSnapshotCache(
      snapshot: bundled,
      cachedExercises: cachedExercises,
    );
    if (!validation.isValid) {
      return _bundledResolution(
        snapshot: bundled,
        issue: const TrainingContentIssue(
          code: TrainingContentIssueCode.invalidCache,
          message: 'The local exercise cache does not match the released '
              'content contract; bundled content is in use.',
        ),
        validationIssues: validation.issues,
      );
    }

    final resolvedExercises = <Exercise>[];
    for (var index = 0; index < bundled.exercises.length; index++) {
      final canonical = bundled.exercises[index];
      final cached = cachedExercises[index];
      resolvedExercises.add(
        canonical.withRemoteMedia(
          imageUrl: cached.imageUrl,
          duoImageUrl: cached.duoImageUrl,
          videoUrl: cached.videoUrl,
        ),
      );
    }

    return TrainingContentResolution(
      packageId: bundled.packageId,
      version: bundled.version,
      exercises: List.unmodifiable(resolvedExercises),
      source: TrainingContentSource.validatedCache,
      isCachePending: false,
    );
  }

  TrainingContentResolution _bundledResolution({
    required TrainingContentSnapshot snapshot,
    bool isCachePending = false,
    TrainingContentIssue? issue,
    List<TrainingContentValidationIssue> validationIssues = const [],
  }) {
    return TrainingContentResolution(
      packageId: snapshot.packageId,
      version: snapshot.version,
      exercises: snapshot.exercises,
      source: TrainingContentSource.bundledSnapshot,
      isCachePending: isCachePending,
      issue: issue,
      validationIssues: validationIssues,
    );
  }

  TrainingContentSnapshot? _bundledSnapshot(String packageId) {
    switch (packageId) {
      case 'moro':
        return moroContentSnapshot;
      case 'spinal_galant':
        return const TrainingContentSnapshot(
          packageId: 'spinal_galant',
          version: 'spinal-galant-legacy-v1',
          exercises: spinalGalantExercises,
        );
      case 'tlr':
        return const TrainingContentSnapshot(
          packageId: 'tlr',
          version: 'tlr-legacy-v1',
          exercises: tlrExercises,
        );
      case 'vorrunde':
        return const TrainingContentSnapshot(
          packageId: 'vorrunde',
          version: 'vorrunde-legacy-v1',
          exercises: vorrundeExercises,
        );
      default:
        return null;
    }
  }
}
