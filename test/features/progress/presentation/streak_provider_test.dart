// test/features/progress/presentation/streak_provider_test.dart
import 'package:corejourney/core/database/app_database.dart';
import 'package:corejourney/features/progress/data/repositories/streak_credits_repository.dart';
import 'package:corejourney/features/progress/presentation/providers/streak_provider.dart';
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

  Future<void> trainOn(List<DateTime> dates) async {
    for (var i = 0; i < dates.length; i++) {
      await db.into(db.trainingSessionsTable).insert(
            TrainingSessionsTableCompanion.insert(
              id: 'session-$i',
              userId: 'user-1',
              subjectProfileId: const Value('child-1'),
              enrollmentId: 'enrollment-1',
              sessionDate: dates[i],
              dayNumber: i + 1,
              completedExerciseIds: '[]',
              isCompleted: const Value(true),
            ),
          );
    }
  }

  test('earns a credit, spends it on the gap and persists the result',
      () async {
    await trainOn([
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 2),
      DateTime(2026, 8, 3),
    ]);

    final service = StreakService(
      repository: repository,
      now: () => DateTime(2026, 8, 5, 10),
    );
    final result = await service.evaluate(
      userId: 'user-1',
      subjectProfileId: 'child-1',
    );

    expect(result.length, 4);
    expect(result.newlyRescued, {DateTime(2026, 8, 4)});

    final stored = await repository.loadCredits(
      userId: 'user-1',
      subjectProfileId: 'child-1',
    );
    expect(stored.available, 0);
    expect(stored.rescuedDays, {DateTime(2026, 8, 4)});
  });

  test('a second evaluation reports nothing newly rescued', () async {
    await trainOn([
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 2),
      DateTime(2026, 8, 3),
    ]);

    final service = StreakService(
      repository: repository,
      now: () => DateTime(2026, 8, 5, 10),
    );
    await service.evaluate(userId: 'user-1', subjectProfileId: 'child-1');
    final second =
        await service.evaluate(userId: 'user-1', subjectProfileId: 'child-1');

    expect(second.newlyRescued, isEmpty);
    expect(second.length, 4);
  });

  test('mirrors the derived series into progress_entries', () async {
    await db.into(db.progressEntriesTable).insert(
          ProgressEntriesTableCompanion.insert(
            id: 'progress-1',
            userId: 'user-1',
            subjectProfileId: const Value('child-1'),
            enrollmentId: 'enrollment-1',
          ),
        );
    await trainOn([DateTime(2026, 8, 2), DateTime(2026, 8, 3)]);

    final service = StreakService(
      repository: repository,
      now: () => DateTime(2026, 8, 3, 10),
    );
    await service.evaluate(userId: 'user-1', subjectProfileId: 'child-1');

    final progress = await (db.select(db.progressEntriesTable)
          ..where((t) => t.id.equals('progress-1')))
        .getSingle();
    expect(progress.dailyStreak, 2);
  });
}
