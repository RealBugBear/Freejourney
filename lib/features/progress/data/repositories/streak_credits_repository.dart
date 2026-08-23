import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../config/launch_flags.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/streak/streak_credits.dart';

/// Reads training days, and loads/stores the Freischein ledger.
///
/// [syncService] may be null in tests that do not exercise the outbox.
class StreakCreditsRepository {
  StreakCreditsRepository(this._db, this._syncService);

  final AppDatabase _db;
  final SyncService? _syncService;

  static String _rowId(String userId, String subjectProfileId) =>
      '$userId::$subjectProfileId';

  static String _encodeDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static DateTime _decodeDay(String value) {
    final parts = value.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Local calendar days with at least one finished session for this profile.
  Future<Set<DateTime>> trainingDaysFor({
    required String subjectProfileId,
    required DateTime since,
  }) async {
    final rows = await (_db.select(_db.trainingSessionsTable)
          ..where((t) => t.subjectProfileId.equals(subjectProfileId))
          ..where((t) => t.isCompleted.equals(true))
          ..where((t) => t.sessionDate.isBiggerOrEqualValue(since)))
        .get();
    return {for (final row in rows) dateOnly(row.sessionDate)};
  }

  Future<StreakCredits> loadCredits({
    required String userId,
    required String subjectProfileId,
  }) async {
    final row = await (_db.select(_db.streakCreditsTable)
          ..where((t) => t.id.equals(_rowId(userId, subjectProfileId)))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return StreakCredits.empty;

    final decoded = jsonDecode(row.rescuedDays);
    final rescued = decoded is List
        ? {for (final value in decoded) _decodeDay(value as String)}
        : <DateTime>{};

    return StreakCredits(
      available: row.available,
      progressToNext: row.progressToNext,
      lastCountedDay: row.lastCountedDay,
      rescuedDays: rescued,
    );
  }

  Future<void> saveCredits({
    required String userId,
    required String subjectProfileId,
    required StreakCredits credits,
  }) async {
    final id = _rowId(userId, subjectProfileId);
    final rescued = credits.rescuedDays.map(_encodeDay).toList()..sort();
    final now = DateTime.now();

    await _db.into(_db.streakCreditsTable).insertOnConflictUpdate(
          StreakCreditsTableCompanion.insert(
            id: id,
            userId: userId,
            subjectProfileId: subjectProfileId,
            available: Value(credits.available),
            progressToNext: Value(credits.progressToNext),
            lastCountedDay: Value(credits.lastCountedDay),
            rescuedDays: Value(jsonEncode(rescued)),
            needsSync: const Value(true),
            updatedAt: Value(now),
          ),
        );

    if (!kStreakCreditsServerSyncEnabled) return;

    await _syncService?.enqueueUpsert(
      tableName: 'streak_credits',
      recordId: id,
      payload: {
        'id': id,
        'user_id': userId,
        'subject_profile_id': subjectProfileId,
        'available': credits.available,
        'progress_to_next': credits.progressToNext,
        'last_counted_day': credits.lastCountedDay == null
            ? null
            : _encodeDay(credits.lastCountedDay!),
        'rescued_days': rescued,
        'updated_at': now.toIso8601String(),
      },
    );
  }

  /// Writes the derived series into `progress_entries.daily_streak` so the
  /// existing trainer RPC keeps returning a number (spec §8). The column is a
  /// mirror from here on, never a source.
  Future<void> mirrorStreak({
    required String subjectProfileId,
    required int length,
  }) async {
    final progress = await (_db.select(_db.progressEntriesTable)
          ..where((t) => t.subjectProfileId.equals(subjectProfileId))
          ..limit(1))
        .getSingleOrNull();
    if (progress == null || progress.dailyStreak == length) return;

    await (_db.update(_db.progressEntriesTable)
          ..where((t) => t.id.equals(progress.id)))
        .write(
      ProgressEntriesTableCompanion(
        dailyStreak: Value(length),
        needsSync: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await _syncService?.enqueueUpsert(
      tableName: 'progress_entries',
      recordId: progress.id,
      payload: {
        'id': progress.id,
        'user_id': progress.userId,
        'enrollment_id': progress.enrollmentId,
        'daily_streak': length,
      },
    );
  }
}
