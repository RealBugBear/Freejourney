// test/features/dashboard/mark_today_complete_test.dart
import 'package:corejourney/core/database/app_database.dart';
import 'package:corejourney/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.inMemory());
  tearDown(() => db.close());

  test('logging a day writes one session row per selected profile', () async {
    for (final id in ['child-1', 'child-2']) {
      await db.into(db.enrollmentsTable).insert(
            EnrollmentsTableCompanion.insert(
              id: 'enrollment-$id',
              userId: 'user-1',
              subjectProfileId: Value(id),
              packageId: 'moro',
              assignedDurationWeeks: 4,
              startDate: DateTime(2026, 8, 1),
              targetCompletionDate: DateTime(2026, 8, 29),
            ),
          );
      await db.into(db.progressEntriesTable).insert(
            ProgressEntriesTableCompanion.insert(
              id: 'progress-$id',
              userId: 'user-1',
              subjectProfileId: Value(id),
              enrollmentId: 'enrollment-$id',
            ),
          );
    }

    await logTrainingDayForProfiles(
      db: db,
      syncService: null,
      userId: 'user-1',
      packageId: 'moro',
      subjectProfileIds: const ['child-1', 'child-2'],
      now: DateTime(2026, 8, 20, 19),
    );

    final rows = await db.select(db.trainingSessionsTable).get();
    expect(rows, hasLength(2));
    expect(
      rows.map((row) => row.subjectProfileId).toSet(),
      {'child-1', 'child-2'},
    );
  });

  test('a profile that already trained today is skipped', () async {
    await db.into(db.enrollmentsTable).insert(
          EnrollmentsTableCompanion.insert(
            id: 'enrollment-1',
            userId: 'user-1',
            subjectProfileId: const Value('child-1'),
            packageId: 'moro',
            assignedDurationWeeks: 4,
            startDate: DateTime(2026, 8, 1),
            targetCompletionDate: DateTime(2026, 8, 29),
          ),
        );
    await db.into(db.progressEntriesTable).insert(
          ProgressEntriesTableCompanion.insert(
            id: 'progress-1',
            userId: 'user-1',
            subjectProfileId: const Value('child-1'),
            enrollmentId: 'enrollment-1',
          ),
        );
    await db.into(db.trainingSessionsTable).insert(
          TrainingSessionsTableCompanion.insert(
            id: 'existing',
            userId: 'user-1',
            subjectProfileId: const Value('child-1'),
            enrollmentId: 'enrollment-1',
            sessionDate: DateTime(2026, 8, 20),
            dayNumber: 1,
            completedExerciseIds: '[]',
            isCompleted: const Value(true),
          ),
        );

    await logTrainingDayForProfiles(
      db: db,
      syncService: null,
      userId: 'user-1',
      packageId: 'moro',
      subjectProfileIds: const ['child-1'],
      now: DateTime(2026, 8, 20, 19),
    );

    expect(await db.select(db.trainingSessionsTable).get(), hasLength(1));
  });
}
