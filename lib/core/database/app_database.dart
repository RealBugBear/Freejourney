import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'backup_exclusion.dart';
import 'tables/enrollments_table.dart';
import 'tables/exercises_table.dart';
import 'tables/training_sessions_table.dart';
import 'tables/progress_entries_table.dart';
import 'tables/mood_checkins_table.dart';
import 'tables/sync_jobs_table.dart';
import 'tables/intake_assessments_table.dart';
import 'tables/completion_questionnaires_table.dart';
import 'tables/journal_entries_table.dart';
import 'tables/streak_credits_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  EnrollmentsTable,
  ExercisesTable,
  TrainingSessionsTable,
  ProgressEntriesTable,
  MoodCheckinsTable,
  SyncJobsTable,
  IntakeAssessmentsTable,
  CompletionQuestionnairesTable,
  JournalEntriesTable,
  StreakCreditsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal(super.executor);

  /// Opens the database at the correct persistent path.
  ///
  /// Uses [getApplicationSupportDirectory] — the correct location for app data
  /// on all platforms (not user-visible, persists across launches). The DB
  /// lives in a `local_store` subdirectory that is flagged as excluded from
  /// device backups: it holds health-adjacent data and must not leave the
  /// device in an iCloud/Finder backup (Android backups are disabled app-wide
  /// via android:allowBackup="false"). Storage failure aborts startup: training
  /// must never appear saved in an accidental, nonpersistent memory database.
  static Future<AppDatabase> open(
      {Future<Directory> Function()? supportDirectory}) async {
    try {
      final dir = await (supportDirectory ?? getApplicationSupportDirectory)();
      final storeDir = Directory(p.join(dir.path, 'local_store'));
      await storeDir.create(recursive: true);
      await _moveLegacyDatabaseFiles(from: dir.path, to: storeDir.path);
      // Best-effort: a failure to flag the directory must not block startup.
      await BackupExclusion().excludeFromBackup(storeDir.path);
      final file = File(p.join(storeDir.path, 'corejourney_db.sqlite'));
      final database = AppDatabase._internal(
        NativeDatabase.createInBackground(file),
      );
      try {
        await database.customSelect('SELECT 1').get();
        return database;
      } catch (_) {
        await database.close();
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Installs older than the backup-exclusion change kept the DB directly in
  /// Application Support. Move the SQLite file (and its WAL/SHM companions)
  /// into the excluded subdirectory exactly once.
  static Future<void> _moveLegacyDatabaseFiles({
    required String from,
    required String to,
  }) async {
    for (final suffix in const ['', '-wal', '-shm']) {
      final legacy = File(p.join(from, 'corejourney_db.sqlite$suffix'));
      final target = File(p.join(to, 'corejourney_db.sqlite$suffix'));
      if (await legacy.exists() && !await target.exists()) {
        await legacy.rename(target.path);
      }
    }
  }

  /// In-memory database for unit tests.
  AppDatabase.inMemory() : super(NativeDatabase.memory());

  /// Deletes all user-specific rows from every table.
  /// Called on sign-out to prevent data leaking to the next user session.
  Future<void> clearUserData() async {
    await transaction(() async {
      await delete(enrollmentsTable).go();
      await delete(trainingSessionsTable).go();
      await delete(progressEntriesTable).go();
      await delete(moodCheckinsTable).go();
      await delete(syncJobsTable).go();
      await delete(intakeAssessmentsTable).go();
      await delete(completionQuestionnairesTable).go();
      await delete(journalEntriesTable).go();
      await delete(streakCreditsTable).go();
      // exercisesTable is shared content (not user-specific) — keep it.
    });
  }

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(journalEntriesTable);
          }
          if (from < 3) {
            await m.createTable(exercisesTable);
          }
          if (from < 4) {
            // journal_entries schema extended — drop and recreate (was dead code,
            // no live rows existed before this version).
            await m.deleteTable('journal_entries');
            await m.createTable(journalEntriesTable);
          }
          if (from < 5) {
            await m.addColumn(
                moodCheckinsTable, moodCheckinsTable.subjectProfileId);
            await m.addColumn(
                journalEntriesTable, journalEntriesTable.subjectProfileId);
          }
          if (from < 6) {
            await m.addColumn(
                enrollmentsTable, enrollmentsTable.subjectProfileId);
            await m.addColumn(
                progressEntriesTable, progressEntriesTable.subjectProfileId);
            await m.addColumn(
                trainingSessionsTable, trainingSessionsTable.subjectProfileId);
          }
          if (from < 7) {
            await m.addColumn(completionQuestionnairesTable,
                completionQuestionnairesTable.subjectProfileId);
          }
          if (from < 8) {
            // Drop and recreate exercises so the next syncIfNeeded() fetches
            // fresh rows that include the new URL columns.
            await m.deleteTable('exercises');
            await m.createTable(exercisesTable);
          }
          if (from < 9) {
            await m.createTable(streakCreditsTable);
          }
        },
      );
}
