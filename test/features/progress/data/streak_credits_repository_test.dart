// test/features/progress/data/streak_credits_repository_test.dart
import 'package:corejourney/config/launch_flags.dart';
import 'package:corejourney/core/database/app_database.dart';
import 'package:corejourney/core/sync/sync_service.dart';
import 'package:corejourney/features/progress/data/repositories/streak_credits_repository.dart';
import 'package:corejourney/features/progress/domain/streak/streak_credits.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StreakCreditsRepository repository;

  setUp(() {
    db = AppDatabase.inMemory();
    repository = StreakCreditsRepository(db, null);
  });

  tearDown(() => db.close());

  Future<void> insertSession({
    required String id,
    required String subjectProfileId,
    required DateTime date,
    bool completed = true,
  }) {
    return db.into(db.trainingSessionsTable).insert(
          TrainingSessionsTableCompanion.insert(
            id: id,
            userId: 'user-1',
            subjectProfileId: Value(subjectProfileId),
            enrollmentId: 'enrollment-1',
            sessionDate: date,
            dayNumber: 1,
            completedExerciseIds: '[]',
            isCompleted: Value(completed),
          ),
        );
  }

  test('collapses several sessions on one day into a single training day',
      () async {
    await insertSession(
      id: 's1',
      subjectProfileId: 'child-1',
      date: DateTime(2026, 8, 3, 9),
    );
    await insertSession(
      id: 's2',
      subjectProfileId: 'child-1',
      date: DateTime(2026, 8, 3, 18),
    );

    final days = await repository.trainingDaysFor(
      subjectProfileId: 'child-1',
      since: DateTime(2026, 1, 1),
    );
    expect(days, {DateTime(2026, 8, 3)});
  });

  test('keeps profiles apart', () async {
    await insertSession(
      id: 's1',
      subjectProfileId: 'child-1',
      date: DateTime(2026, 8, 3),
    );
    await insertSession(
      id: 's2',
      subjectProfileId: 'child-2',
      date: DateTime(2026, 8, 4),
    );

    expect(
      await repository.trainingDaysFor(
        subjectProfileId: 'child-1',
        since: DateTime(2026, 1, 1),
      ),
      {DateTime(2026, 8, 3)},
    );
  });

  test('ignores unfinished sessions', () async {
    await insertSession(
      id: 's1',
      subjectProfileId: 'child-1',
      date: DateTime(2026, 8, 3),
      completed: false,
    );
    expect(
      await repository.trainingDaysFor(
        subjectProfileId: 'child-1',
        since: DateTime(2026, 1, 1),
      ),
      isEmpty,
    );
  });

  test('an unknown profile loads an empty ledger', () async {
    final credits = await repository.loadCredits(
      userId: 'user-1',
      subjectProfileId: 'child-1',
    );
    expect(credits.available, 0);
    expect(credits.rescuedDays, isEmpty);
  });

  test('saved credits survive a reload', () async {
    await repository.saveCredits(
      userId: 'user-1',
      subjectProfileId: 'child-1',
      credits: StreakCredits.empty.copyWith(
        available: 2,
        progressToNext: 1,
        lastCountedDay: DateTime(2026, 8, 3),
        rescuedDays: {DateTime(2026, 8, 2)},
      ),
    );

    final loaded = await repository.loadCredits(
      userId: 'user-1',
      subjectProfileId: 'child-1',
    );
    expect(loaded.available, 2);
    expect(loaded.progressToNext, 1);
    expect(loaded.lastCountedDay, DateTime(2026, 8, 3));
    expect(loaded.rescuedDays, {DateTime(2026, 8, 2)});
  });

  test('saving twice updates instead of duplicating', () async {
    await repository.saveCredits(
      userId: 'user-1',
      subjectProfileId: 'child-1',
      credits: StreakCredits.empty.copyWith(available: 1),
    );
    await repository.saveCredits(
      userId: 'user-1',
      subjectProfileId: 'child-1',
      credits: StreakCredits.empty.copyWith(available: 2),
    );

    final rows = await db.select(db.streakCreditsTable).get();
    expect(rows, hasLength(1));
    expect(rows.single.available, 2);
  });

  group('server sync gate', () {
    test('an off gate keeps the ledger out of the outbox', () async {
      // The server table only exists after 2026082301_streak_credits.sql is
      // applied. Until the flag flips, a queued upsert would retry five times
      // and then sit in sync_jobs forever.
      expect(kStreakCreditsServerSyncEnabled, isFalse);

      final syncing = StreakCreditsRepository(db, SyncService(db));
      await syncing.saveCredits(
        userId: 'user-1',
        subjectProfileId: 'child-1',
        credits: StreakCredits.empty.copyWith(available: 1),
      );

      final jobs = await db.select(db.syncJobsTable).get();
      expect(
        jobs.where((job) => job.tableName_ == 'streak_credits'),
        isEmpty,
      );

      // ...but the ledger is still stored locally.
      final stored = await syncing.loadCredits(
        userId: 'user-1',
        subjectProfileId: 'child-1',
      );
      expect(stored.available, 1);
    });

    // The mirror's outbox write is not covered here: enqueueUpsert kicks
    // off drain() straight away, which needs an initialised Supabase.
    // Its local column write is covered in streak_provider_test.dart.
  });
}
