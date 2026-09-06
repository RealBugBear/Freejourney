import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';

/// Manages [JournalEntriesTable] — the canonical store for user-written notes.
///
/// Creation and updates are handled by [MoodRepository] as a dual-write
/// alongside mood_checkins. This repository provides read access and the
/// ability to delete standalone journal entries.
class JournalRepository {
  final AppDatabase _db;
  final SyncService _syncService;

  JournalRepository(this._db, this._syncService);

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  /// Returns all journal entries for [enrollmentId] in descending date order,
  /// filtered to the [from]–[to] window.
  Future<List<JournalEntriesTableData>> getEntriesInRange({
    required String enrollmentId,
    required DateTime from,
    required DateTime to,
    String? subjectProfileId,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    final query = _db.select(_db.journalEntriesTable)
      ..where((t) =>
          t.userId.equals(userId) &
          t.enrollmentId.equals(enrollmentId) &
          t.createdAt.isBiggerOrEqualValue(from) &
          t.createdAt.isSmallerOrEqualValue(to))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.createdAt)]);

    if (subjectProfileId != null) {
      query.where(
        (t) =>
            t.subjectProfileId.equals(subjectProfileId) |
            t.subjectProfileId.isNull(),
      );
    }

    return query.get();
  }

  /// Fetches the mood_checkin linked to a journal entry, if any.
  Future<MoodCheckinsTableData?> getLinkedCheckin(String checkinId) async {
    return (_db.select(_db.moodCheckinsTable)
          ..where((t) => t.id.equals(checkinId))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Deletes a journal entry and queues a server-side delete.
  /// Also clears the note on the linked mood_checkin so the two stay in sync.
  Future<void> deleteEntry(String journalEntryId) async {
    return _db.transaction(() async {
      final entry = await (_db.select(_db.journalEntriesTable)
            ..where((t) => t.id.equals(journalEntryId))
            ..limit(1))
          .getSingleOrNull();

      if (entry == null) return;

      // Clear note on the linked checkin if present
      if (entry.checkinId != null) {
        await (_db.update(_db.moodCheckinsTable)
              ..where((t) => t.id.equals(entry.checkinId!)))
            .write(const MoodCheckinsTableCompanion(
          note: drift.Value(null),
          needsSync: drift.Value(true),
        ));
        final checkin = await (_db.select(_db.moodCheckinsTable)
              ..where((t) => t.id.equals(entry.checkinId!))
              ..limit(1))
            .getSingleOrNull();
        if (checkin != null) {
          await _syncService.enqueueUpsert(
            tableName: 'mood_checkins',
            recordId: checkin.id,
            payload: {
              'id': checkin.id,
              'user_id': checkin.userId,
              'enrollment_id': checkin.enrollmentId,
              'recorded_at': checkin.recordedAt.toIso8601String(),
              'day_key': checkin.dayKey,
              'mood': checkin.mood,
              'energy': checkin.energy,
              'stress': checkin.stress,
              'note': null,
              'source': checkin.source,
              if (checkin.subjectProfileId != null)
                'subject_profile_id': checkin.subjectProfileId,
            },
          );
        }
      }

      await (_db.delete(_db.journalEntriesTable)
            ..where((t) => t.id.equals(journalEntryId)))
          .go();

      await _syncService.enqueueDelete(
        tableName: 'journal_entries',
        recordId: journalEntryId,
      );
    });
  }
}
