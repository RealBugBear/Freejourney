import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';

/// Why an atomic training completion could not be persisted.
enum TrainingCompletionErrorCode {
  invalidArgument,
  missingEnrollment,
  enrollmentUserMismatch,
  missingProgress,
  progressUserMismatch,
  inconsistentProgress,
  sessionConflict,
}

/// A domain-level persistence error that callers can handle explicitly.
class TrainingCompletionException implements Exception {
  const TrainingCompletionException(this.code, this.message);

  final TrainingCompletionErrorCode code;
  final String message;

  @override
  String toString() => 'TrainingCompletionException($code): $message';
}

/// Describes the work performed by one completion request.
class TrainingCompletionResult {
  const TrainingCompletionResult({
    required this.sessionId,
    required this.createdSession,
    required this.progressApplied,
    required this.sessionOutboxJobId,
    required this.progressOutboxJobId,
  });

  final String sessionId;

  /// False when the same completed session was already persisted.
  final bool createdSession;

  /// False for an idempotent retry or a second training on the same local day.
  final bool progressApplied;

  final String sessionOutboxJobId;
  final String? progressOutboxJobId;
}

class TrainingCompletionRequest {
  const TrainingCompletionRequest({
    required this.sessionId,
    required this.userId,
    required this.enrollmentId,
    required this.completedExerciseIds,
    required this.completedAt,
  });

  final String sessionId;
  final String userId;
  final String enrollmentId;
  final List<String> completedExerciseIds;
  final DateTime completedAt;
}

/// Persists one completed training and its sync intent as a single unit.
///
/// The caller owns [sessionId] and [userId]. Retrying with the same values is
/// safe: an already completed, matching session is returned as a no-op.
///
/// This repository deliberately writes the outbox directly instead of calling
/// `SyncService.enqueueUpsert`, because enqueueing outside this transaction
/// could leave local progress without a corresponding sync job. The caller may
/// ask SyncService to drain after this method succeeds.
class TrainingCompletionRepository {
  TrainingCompletionRepository(this._db);

  final AppDatabase _db;

  static String sessionOutboxJobIdFor(String sessionId) =>
      'completion:$sessionId:training_sessions';

  static String progressOutboxJobIdFor(String sessionId) =>
      'completion:$sessionId:progress_entries';

  static String disclaimerOutboxJobIdFor(String progressId) =>
      'disclaimer:$progressId:progress_entries';

  /// Records the first safety-disclaimer acceptance with its sync intent.
  Future<bool> acceptDisclaimer({
    required String progressId,
    required String userId,
    required DateTime acceptedAt,
  }) async {
    _validateIdentifier('progressId', progressId);
    _validateIdentifier('userId', userId);
    return _db.transaction(() async {
      final progress = await (_db.select(_db.progressEntriesTable)
            ..where((table) => table.id.equals(progressId)))
          .getSingleOrNull();
      if (progress == null) {
        throw TrainingCompletionException(
          TrainingCompletionErrorCode.missingProgress,
          'Progress "$progressId" does not exist.',
        );
      }
      if (progress.userId != userId) {
        throw TrainingCompletionException(
          TrainingCompletionErrorCode.progressUserMismatch,
          'Progress "$progressId" does not belong to user "$userId".',
        );
      }
      if (progress.lastDisclaimerAcceptedAt != null) return false;

      final updatedRows = await (_db.update(_db.progressEntriesTable)
            ..where((table) => table.id.equals(progressId)))
          .write(
        ProgressEntriesTableCompanion(
          totalSessionsSinceDisclaimer: const Value(0),
          lastDisclaimerAcceptedAt: Value(acceptedAt),
          needsSync: const Value(true),
          updatedAt: Value(acceptedAt),
        ),
      );
      if (updatedRows != 1) {
        throw TrainingCompletionException(
          TrainingCompletionErrorCode.missingProgress,
          'Progress "$progressId" disappeared during disclaimer acceptance.',
        );
      }

      await _insertOutboxJob(
        id: disclaimerOutboxJobIdFor(progressId),
        tableName: 'progress_entries',
        recordId: progressId,
        completedAt: acceptedAt,
        payload: {
          'id': progress.id,
          'user_id': userId,
          if (progress.subjectProfileId != null)
            'subject_profile_id': progress.subjectProfileId,
          'enrollment_id': progress.enrollmentId,
          'current_day': progress.currentDay,
          if (progress.lastActivityDate != null)
            'last_activity_date': _dateString(progress.lastActivityDate!),
          'total_sessions_since_disclaimer': 0,
          'last_disclaimer_accepted_at': acceptedAt.toIso8601String(),
          'updated_at': acceptedAt.toIso8601String(),
        },
      );
      return true;
    });
  }

  Future<TrainingCompletionResult> completeSession({
    required String sessionId,
    required String userId,
    required String enrollmentId,
    required List<String> completedExerciseIds,
    required DateTime completedAt,
  }) async {
    final results = await completeSessionsAtomically(
      requests: [
        TrainingCompletionRequest(
          sessionId: sessionId,
          userId: userId,
          enrollmentId: enrollmentId,
          completedExerciseIds: completedExerciseIds,
          completedAt: completedAt,
        ),
      ],
    );
    return results.single;
  }

  /// Commits a primary and any companion completions in one DB transaction.
  ///
  /// If one enrollment, progress row or outbox write is invalid, every session
  /// in the group is rolled back. Retrying the same stable request IDs is safe.
  Future<List<TrainingCompletionResult>> completeSessionsAtomically({
    required List<TrainingCompletionRequest> requests,
  }) async {
    if (requests.isEmpty) {
      throw const TrainingCompletionException(
        TrainingCompletionErrorCode.invalidArgument,
        'At least one completion request is required.',
      );
    }
    for (final request in requests) {
      _validateIdentifier('sessionId', request.sessionId);
      _validateIdentifier('userId', request.userId);
      _validateIdentifier('enrollmentId', request.enrollmentId);
    }

    return _db.transaction(() async {
      final results = <TrainingCompletionResult>[];
      for (final request in requests) {
        results.add(await _completeSessionInTransaction(request));
      }
      return List<TrainingCompletionResult>.unmodifiable(results);
    });
  }

  Future<TrainingCompletionResult> _completeSessionInTransaction(
    TrainingCompletionRequest request,
  ) async {
    final sessionId = request.sessionId;
    final userId = request.userId;
    final enrollmentId = request.enrollmentId;
    final completedAt = request.completedAt;
    final exerciseIds = List<String>.unmodifiable(request.completedExerciseIds);
    final sessionJobId = sessionOutboxJobIdFor(sessionId);

    final existingSession = await (_db.select(_db.trainingSessionsTable)
          ..where((table) => table.id.equals(sessionId)))
        .getSingleOrNull();

    if (existingSession != null) {
      _verifyIdempotentRetry(
        existingSession: existingSession,
        userId: userId,
        enrollmentId: enrollmentId,
        completedExerciseIds: exerciseIds,
      );
      return TrainingCompletionResult(
        sessionId: sessionId,
        createdSession: false,
        progressApplied: false,
        sessionOutboxJobId: sessionJobId,
        progressOutboxJobId: null,
      );
    }

    final enrollment = await (_db.select(_db.enrollmentsTable)
          ..where((table) => table.id.equals(enrollmentId)))
        .getSingleOrNull();
    if (enrollment == null) {
      throw TrainingCompletionException(
        TrainingCompletionErrorCode.missingEnrollment,
        'Enrollment "$enrollmentId" does not exist.',
      );
    }
    if (enrollment.userId != userId) {
      throw TrainingCompletionException(
        TrainingCompletionErrorCode.enrollmentUserMismatch,
        'Enrollment "$enrollmentId" does not belong to user "$userId".',
      );
    }

    final progressRows = await (_db.select(_db.progressEntriesTable)
          ..where((table) => table.enrollmentId.equals(enrollmentId)))
        .get();
    if (progressRows.isEmpty) {
      throw TrainingCompletionException(
        TrainingCompletionErrorCode.missingProgress,
        'Enrollment "$enrollmentId" has no progress entry.',
      );
    }
    if (progressRows.length > 1) {
      throw TrainingCompletionException(
        TrainingCompletionErrorCode.inconsistentProgress,
        'Enrollment "$enrollmentId" has ${progressRows.length} progress '
        'entries; exactly one is required.',
      );
    }

    final progress = progressRows.single;
    if (progress.userId != userId) {
      throw TrainingCompletionException(
        TrainingCompletionErrorCode.progressUserMismatch,
        'Progress "${progress.id}" does not belong to user "$userId".',
      );
    }

    final sessionDate = _localDate(completedAt);
    final progressUpdate = _calculateProgressUpdate(
      progress: progress,
      sessionDate: sessionDate,
    );

    await _db.into(_db.trainingSessionsTable).insert(
          TrainingSessionsTableCompanion.insert(
            id: sessionId,
            userId: userId,
            subjectProfileId: Value(enrollment.subjectProfileId),
            enrollmentId: enrollmentId,
            sessionDate: sessionDate,
            dayNumber: progress.currentDay,
            completedExerciseIds: jsonEncode(exerciseIds),
            isCompleted: const Value(true),
            completedAt: Value(completedAt),
          ),
        );

    if (progressUpdate != null) {
      final updatedRows = await (_db.update(_db.progressEntriesTable)
            ..where((table) => table.id.equals(progress.id)))
          .write(
        ProgressEntriesTableCompanion(
          currentDay: Value(progressUpdate.currentDay),
          lastActivityDate: Value(sessionDate),
          totalSessionsSinceDisclaimer:
              Value(progressUpdate.totalSessionsSinceDisclaimer),
          needsSync: const Value(true),
          updatedAt: Value(completedAt),
        ),
      );
      if (updatedRows != 1) {
        throw TrainingCompletionException(
          TrainingCompletionErrorCode.missingProgress,
          'Progress "${progress.id}" disappeared during completion.',
        );
      }
    }

    await _insertOutboxJob(
      id: sessionJobId,
      tableName: 'training_sessions',
      recordId: sessionId,
      completedAt: completedAt,
      payload: {
        'id': sessionId,
        'user_id': userId,
        if (enrollment.subjectProfileId != null)
          'subject_profile_id': enrollment.subjectProfileId,
        'enrollment_id': enrollmentId,
        'session_date': _dateString(sessionDate),
        'day_number': progress.currentDay,
        'completed_exercise_ids': exerciseIds,
        'is_completed': true,
        'completed_at': completedAt.toIso8601String(),
      },
    );

    String? progressJobId;
    if (progressUpdate != null) {
      progressJobId = progressOutboxJobIdFor(sessionId);
      await _insertOutboxJob(
        id: progressJobId,
        tableName: 'progress_entries',
        recordId: progress.id,
        completedAt: completedAt,
        payload: {
          'id': progress.id,
          'user_id': userId,
          if (progress.subjectProfileId != null)
            'subject_profile_id': progress.subjectProfileId,
          'enrollment_id': enrollmentId,
          'current_day': progressUpdate.currentDay,
          'last_activity_date': _dateString(sessionDate),
          'total_sessions_since_disclaimer':
              progressUpdate.totalSessionsSinceDisclaimer,
          if (progress.lastDisclaimerAcceptedAt != null)
            'last_disclaimer_accepted_at':
                progress.lastDisclaimerAcceptedAt!.toIso8601String(),
          'updated_at': completedAt.toIso8601String(),
        },
      );
    }

    return TrainingCompletionResult(
      sessionId: sessionId,
      createdSession: true,
      progressApplied: progressUpdate != null,
      sessionOutboxJobId: sessionJobId,
      progressOutboxJobId: progressJobId,
    );
  }

  Future<void> _insertOutboxJob({
    required String id,
    required String tableName,
    required String recordId,
    required DateTime completedAt,
    required Map<String, Object?> payload,
  }) {
    return _db.into(_db.syncJobsTable).insert(
          SyncJobsTableCompanion.insert(
            id: id,
            action: 'upsert',
            tableName_: tableName,
            recordId: recordId,
            payload: jsonEncode(payload),
            createdAt: Value(completedAt),
          ),
        );
  }

  static void _validateIdentifier(String name, String value) {
    if (value.trim().isEmpty) {
      throw TrainingCompletionException(
        TrainingCompletionErrorCode.invalidArgument,
        '$name must not be empty.',
      );
    }
  }

  static void _verifyIdempotentRetry({
    required TrainingSessionsTableData existingSession,
    required String userId,
    required String enrollmentId,
    required List<String> completedExerciseIds,
  }) {
    final existingExerciseIds =
        _decodeExerciseIds(existingSession.completedExerciseIds);
    final matches = existingSession.isCompleted &&
        existingSession.completedAt != null &&
        existingSession.userId == userId &&
        existingSession.enrollmentId == enrollmentId &&
        existingExerciseIds != null &&
        _sameStrings(existingExerciseIds, completedExerciseIds);

    if (!matches) {
      throw TrainingCompletionException(
        TrainingCompletionErrorCode.sessionConflict,
        'Session "${existingSession.id}" already exists with different or '
        'incomplete data.',
      );
    }
  }

  static List<String>? _decodeExerciseIds(String encoded) {
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return null;
      final result = <String>[];
      for (final value in decoded) {
        if (value is! String) return null;
        result.add(value);
      }
      return result;
    } on FormatException {
      return null;
    }
  }

  static bool _sameStrings(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static _ProgressUpdate? _calculateProgressUpdate({
    required ProgressEntriesTableData progress,
    required DateTime sessionDate,
  }) {
    final lastActivityDate = progress.lastActivityDate == null
        ? null
        : _localDate(progress.lastActivityDate!);
    if (lastActivityDate != null &&
        _isSameDate(lastActivityDate, sessionDate)) {
      return null;
    }

    // The series is derived from training_sessions (spec §4.1) — this path
    // only advances the package day counter.
    return _ProgressUpdate(
      currentDay: progress.currentDay + 1,
      totalSessionsSinceDisclaimer: progress.totalSessionsSinceDisclaimer + 1,
    );
  }

  static DateTime _localDate(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  static bool _isSameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  static String _dateString(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

class _ProgressUpdate {
  const _ProgressUpdate({
    required this.currentDay,
    required this.totalSessionsSinceDisclaimer,
  });

  final int currentDay;
  final int totalSessionsSinceDisclaimer;
}

/// Convenience API for callers that do not retain a repository instance.
Future<TrainingCompletionResult> saveCompletedSessionAtomically({
  required AppDatabase db,
  required String sessionId,
  required String userId,
  required String enrollmentId,
  required List<String> completedExerciseIds,
  required DateTime completedAt,
}) {
  return TrainingCompletionRepository(db).completeSession(
    sessionId: sessionId,
    userId: userId,
    enrollmentId: enrollmentId,
    completedExerciseIds: completedExerciseIds,
    completedAt: completedAt,
  );
}
