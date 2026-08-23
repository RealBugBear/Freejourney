// test/features/progress/data/streak_credits_repository_test.dart
import 'dart:io';

import 'package:corejourney/config/launch_flags.dart';
import 'package:corejourney/core/database/app_database.dart';
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

  test('the server sync gate is open now that the table exists', () {
    // Flipped 2026-08-23 after public.streak_credits was created and verified
    // on live — see docs/evidence/serie-freischeine/live-apply-2026-08-23.md.
    // Never set this true while the table is missing anywhere: the outbox job
    // would fail forever and rehydrate() would abort before the later tables.
    expect(kStreakCreditsServerSyncEnabled, isTrue);
    expect(
      File('supabase/migrations/2026082301_streak_credits.sql').existsSync(),
      isTrue,
      reason: 'the migration that creates the table must stay in the repo',
    );
  });

  // The outbox write itself is not unit-tested: enqueueUpsert fires drain()
  // straight away, which needs an initialised Supabase. Proof that it reaches
  // the server is the live verification in docs/evidence/serie-freischeine/.
}
