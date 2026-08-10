import 'dart:convert';

import 'package:corejourney/core/database/app_database.dart';
import 'package:corejourney/features/training/data/repositories/training_completion_repository.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late TrainingCompletionRepository repository;

  setUp(() {
    db = AppDatabase.inMemory();
    repository = TrainingCompletionRepository(db);
  });

  tearDown(() => db.close());

  test('parallel and repeated completion advances progress exactly once',
      () async {
    await _seedEnrollmentAndProgress(db);
    final completedAt = DateTime(2026, 7, 23, 10, 30);

    final results = await Future.wait([
      repository.completeSession(
        sessionId: 'session-1',
        userId: 'user-1',
        enrollmentId: 'enrollment-1',
        completedExerciseIds: const ['exercise-a', 'exercise-b'],
        completedAt: completedAt,
      ),
      repository.completeSession(
        sessionId: 'session-1',
        userId: 'user-1',
        enrollmentId: 'enrollment-1',
        completedExerciseIds: const ['exercise-a', 'exercise-b'],
        completedAt: completedAt,
      ),
    ]);

    expect(results.where((result) => result.createdSession), hasLength(1));
    expect(results.where((result) => !result.createdSession), hasLength(1));
    expect(results.where((result) => result.progressApplied), hasLength(1));
    expect(await db.select(db.trainingSessionsTable).get(), hasLength(1));

    var progress = await (db.select(db.progressEntriesTable)
          ..where((table) => table.id.equals('progress-1')))
        .getSingle();
    expect(progress.currentDay, 4);
    expect(progress.dailyStreak, 7);
    expect(progress.trainingsThisWeek, 3);
    expect(progress.totalSessionsSinceDisclaimer, 10);
    expect(await db.select(db.syncJobsTable).get(), hasLength(2));

    final retry = await repository.completeSession(
      sessionId: 'session-1',
      userId: 'user-1',
      enrollmentId: 'enrollment-1',
      completedExerciseIds: const ['exercise-a', 'exercise-b'],
      completedAt: completedAt.add(const Duration(minutes: 2)),
    );

    expect(retry.createdSession, isFalse);
    expect(retry.progressApplied, isFalse);
    expect(await db.select(db.trainingSessionsTable).get(), hasLength(1));
    progress = await (db.select(db.progressEntriesTable)
          ..where((table) => table.id.equals('progress-1')))
        .getSingle();
    expect(progress.currentDay, 4);
    expect(progress.totalSessionsSinceDisclaimer, 10);
    expect(await db.select(db.syncJobsTable).get(), hasLength(2));
  });

  test('commits deterministic session and progress outbox jobs', () async {
    await _seedEnrollmentAndProgress(db);
    final completedAt = DateTime(2026, 7, 23, 10, 30);

    final result = await repository.completeSession(
      sessionId: 'session-outbox',
      userId: 'user-1',
      enrollmentId: 'enrollment-1',
      completedExerciseIds: const ['exercise-a', 'exercise-b'],
      completedAt: completedAt,
    );

    expect(
      result.sessionOutboxJobId,
      'completion:session-outbox:training_sessions',
    );
    expect(
      result.progressOutboxJobId,
      'completion:session-outbox:progress_entries',
    );

    final jobs = await (db.select(db.syncJobsTable)
          ..orderBy([(table) => OrderingTerm.asc(table.id)]))
        .get();
    expect(jobs, hasLength(2));

    final sessionJob = jobs.singleWhere(
      (job) => job.id == result.sessionOutboxJobId,
    );
    expect(sessionJob.action, 'upsert');
    expect(sessionJob.tableName_, 'training_sessions');
    expect(sessionJob.recordId, 'session-outbox');
    final sessionPayload =
        jsonDecode(sessionJob.payload) as Map<String, dynamic>;
    expect(sessionPayload, {
      'id': 'session-outbox',
      'user_id': 'user-1',
      'subject_profile_id': 'subject-1',
      'enrollment_id': 'enrollment-1',
      'session_date': '2026-07-23',
      'day_number': 3,
      'completed_exercise_ids': ['exercise-a', 'exercise-b'],
      'is_completed': true,
      'completed_at': completedAt.toIso8601String(),
    });

    final progressJob = jobs.singleWhere(
      (job) => job.id == result.progressOutboxJobId,
    );
    expect(progressJob.action, 'upsert');
    expect(progressJob.tableName_, 'progress_entries');
    expect(progressJob.recordId, 'progress-1');
    final progressPayload =
        jsonDecode(progressJob.payload) as Map<String, dynamic>;
    expect(progressPayload, {
      'id': 'progress-1',
      'user_id': 'user-1',
      'subject_profile_id': 'subject-1',
      'enrollment_id': 'enrollment-1',
      'current_day': 4,
      'last_activity_date': '2026-07-23',
      'consecutive_inactive_days': 0,
      'daily_streak': 7,
      'weekly_streak': 4,
      'trainings_this_week': 3,
      'last_training_week_start': '2026-07-20',
      'weekly_goal': 5,
      'total_sessions_since_disclaimer': 10,
      'updated_at': completedAt.toIso8601String(),
    });
  });

  test('missing enrollment is an explicit error with no partial writes',
      () async {
    final future = repository.completeSession(
      sessionId: 'session-missing-enrollment',
      userId: 'user-1',
      enrollmentId: 'missing-enrollment',
      completedExerciseIds: const ['exercise-a'],
      completedAt: DateTime(2026, 7, 23, 10, 30),
    );

    await expectLater(
      future,
      throwsA(_completionError(
        TrainingCompletionErrorCode.missingEnrollment,
      )),
    );
    expect(await db.select(db.trainingSessionsTable).get(), isEmpty);
    expect(await db.select(db.syncJobsTable).get(), isEmpty);
  });

  test('missing progress is an explicit error with no partial writes',
      () async {
    await _seedEnrollment(db);

    final future = repository.completeSession(
      sessionId: 'session-missing-progress',
      userId: 'user-1',
      enrollmentId: 'enrollment-1',
      completedExerciseIds: const ['exercise-a'],
      completedAt: DateTime(2026, 7, 23, 10, 30),
    );

    await expectLater(
      future,
      throwsA(_completionError(
        TrainingCompletionErrorCode.missingProgress,
      )),
    );
    expect(await db.select(db.trainingSessionsTable).get(), isEmpty);
    expect(await db.select(db.syncJobsTable).get(), isEmpty);
  });

  test('outbox conflict rolls back session and progress atomically', () async {
    await _seedEnrollmentAndProgress(db);
    final completedAt = DateTime(2026, 7, 23, 10, 30);
    final conflictingJobId =
        TrainingCompletionRepository.progressOutboxJobIdFor(
      'session-rollback',
    );
    await db.into(db.syncJobsTable).insert(
          SyncJobsTableCompanion.insert(
            id: conflictingJobId,
            action: 'upsert',
            tableName_: 'progress_entries',
            recordId: 'some-other-progress',
            payload: '{"preexisting":true}',
          ),
        );

    await expectLater(
      repository.completeSession(
        sessionId: 'session-rollback',
        userId: 'user-1',
        enrollmentId: 'enrollment-1',
        completedExerciseIds: const ['exercise-a'],
        completedAt: completedAt,
      ),
      throwsA(anything),
    );

    expect(await db.select(db.trainingSessionsTable).get(), isEmpty);
    final progress = await (db.select(db.progressEntriesTable)
          ..where((table) => table.id.equals('progress-1')))
        .getSingle();
    expect(progress.currentDay, 3);
    expect(progress.dailyStreak, 6);
    expect(progress.trainingsThisWeek, 2);
    expect(progress.totalSessionsSinceDisclaimer, 9);

    final jobs = await db.select(db.syncJobsTable).get();
    expect(jobs, hasLength(1));
    expect(jobs.single.id, conflictingJobId);
    expect(
      jobs.any(
        (job) =>
            job.id ==
            TrainingCompletionRepository.sessionOutboxJobIdFor(
              'session-rollback',
            ),
      ),
      isFalse,
    );
  });

  test('companion validation failure rolls back the whole completion group',
      () async {
    await _seedEnrollmentAndProgress(db);
    await db.into(db.enrollmentsTable).insert(
          EnrollmentsTableCompanion.insert(
            id: 'enrollment-2',
            userId: 'user-1',
            subjectProfileId: const Value('subject-2'),
            packageId: 'package-1',
            assignedDurationWeeks: 8,
            startDate: DateTime(2026, 7, 1),
            targetCompletionDate: DateTime(2026, 8, 26),
            needsSync: const Value(false),
            updatedAt: Value(DateTime(2026, 7, 1)),
          ),
        );
    final completedAt = DateTime(2026, 7, 23, 10, 30);

    await expectLater(
      repository.completeSessionsAtomically(
        requests: [
          TrainingCompletionRequest(
            sessionId: 'session-primary',
            userId: 'user-1',
            enrollmentId: 'enrollment-1',
            completedExerciseIds: const ['exercise-a'],
            completedAt: completedAt,
          ),
          TrainingCompletionRequest(
            sessionId: 'session-companion',
            userId: 'user-1',
            enrollmentId: 'enrollment-2',
            completedExerciseIds: const ['exercise-a'],
            completedAt: completedAt,
          ),
        ],
      ),
      throwsA(_completionError(TrainingCompletionErrorCode.missingProgress)),
    );

    expect(await db.select(db.trainingSessionsTable).get(), isEmpty);
    expect(await db.select(db.syncJobsTable).get(), isEmpty);
    final primaryProgress = await (db.select(db.progressEntriesTable)
          ..where((table) => table.id.equals('progress-1')))
        .getSingle();
    expect(primaryProgress.currentDay, 3);
    expect(primaryProgress.totalSessionsSinceDisclaimer, 9);
  });

  test('disclaimer acceptance is idempotent and committed with its outbox',
      () async {
    await _seedEnrollmentAndProgress(db);
    final acceptedAt = DateTime(2026, 7, 23, 9);

    expect(
      await repository.acceptDisclaimer(
        progressId: 'progress-1',
        userId: 'user-1',
        acceptedAt: acceptedAt,
      ),
      isTrue,
    );
    expect(
      await repository.acceptDisclaimer(
        progressId: 'progress-1',
        userId: 'user-1',
        acceptedAt: acceptedAt.add(const Duration(minutes: 1)),
      ),
      isFalse,
    );

    final progress = await (db.select(db.progressEntriesTable)
          ..where((table) => table.id.equals('progress-1')))
        .getSingle();
    expect(progress.totalSessionsSinceDisclaimer, 0);
    expect(progress.lastDisclaimerAcceptedAt, acceptedAt);
    final jobs = await db.select(db.syncJobsTable).get();
    expect(jobs, hasLength(1));
    expect(
      jobs.single.id,
      TrainingCompletionRepository.disclaimerOutboxJobIdFor('progress-1'),
    );
    final payload = jsonDecode(jobs.single.payload) as Map<String, dynamic>;
    expect(payload['last_disclaimer_accepted_at'], acceptedAt.toIso8601String());
  });
}

Matcher _completionError(TrainingCompletionErrorCode code) {
  return isA<TrainingCompletionException>().having(
    (error) => error.code,
    'code',
    code,
  );
}

Future<void> _seedEnrollmentAndProgress(AppDatabase db) async {
  await _seedEnrollment(db);
  await db.into(db.progressEntriesTable).insert(
        ProgressEntriesTableCompanion.insert(
          id: 'progress-1',
          userId: 'user-1',
          subjectProfileId: const Value('subject-1'),
          enrollmentId: 'enrollment-1',
          currentDay: const Value(3),
          lastActivityDate: Value(DateTime(2026, 7, 22)),
          consecutiveInactiveDays: const Value(2),
          dailyStreak: const Value(6),
          weeklyStreak: const Value(4),
          trainingsThisWeek: const Value(2),
          lastTrainingWeekStart: Value(DateTime(2026, 7, 20)),
          weeklyGoal: const Value(5),
          totalSessionsSinceDisclaimer: const Value(9),
          needsSync: const Value(false),
          updatedAt: Value(DateTime(2026, 7, 22, 10)),
        ),
      );
}

Future<void> _seedEnrollment(AppDatabase db) {
  return db.into(db.enrollmentsTable).insert(
        EnrollmentsTableCompanion.insert(
          id: 'enrollment-1',
          userId: 'user-1',
          subjectProfileId: const Value('subject-1'),
          packageId: 'package-1',
          assignedDurationWeeks: 8,
          startDate: DateTime(2026, 7, 1),
          targetCompletionDate: DateTime(2026, 8, 26),
          needsSync: const Value(false),
          updatedAt: Value(DateTime(2026, 7, 1)),
        ),
      );
}
