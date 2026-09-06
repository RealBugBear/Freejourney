import 'package:drift/drift.dart' as drift;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/time/app_clock.dart';
import '../../domain/models/mood_daily_aggregate.dart';

const _uuid = Uuid();

class MoodRepository {
  final AppDatabase _db;
  final SyncService _syncService;
  final AppClock _clock;

  MoodRepository(this._db, this._syncService, this._clock);

  String? get _userId => Supabase.instance.client.auth.currentUser?.id;

  Future<List<MoodCheckinsTableData>> getCheckinsInRange({
    required String enrollmentId,
    required DateTime from,
    required DateTime to,
    String? subjectProfileId,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    final q = _db.select(_db.moodCheckinsTable)
      ..where((t) =>
          t.userId.equals(userId) &
          t.enrollmentId.equals(enrollmentId) &
          t.recordedAt.isBiggerOrEqualValue(from) &
          t.recordedAt.isSmallerOrEqualValue(to))
      ..orderBy([(t) => drift.OrderingTerm.asc(t.recordedAt)]);
    if (subjectProfileId != null) {
      q.where((t) => t.subjectProfileId.equals(subjectProfileId));
    }
    return q.get();
  }

  Future<List<MoodCheckinsTableData>> getNotesInRange({
    required String enrollmentId,
    required DateTime from,
    required DateTime to,
    String? subjectProfileId,
  }) async {
    final userId = _userId;
    if (userId == null) return [];

    final q = _db.select(_db.moodCheckinsTable)
      ..where((t) =>
          t.userId.equals(userId) &
          t.enrollmentId.equals(enrollmentId) &
          t.recordedAt.isBiggerOrEqualValue(from) &
          t.recordedAt.isSmallerOrEqualValue(to) &
          t.note.isNotNull() &
          t.note.isNotValue(''))
      ..orderBy([(t) => drift.OrderingTerm.desc(t.recordedAt)]);
    if (subjectProfileId != null) {
      q.where((t) => t.subjectProfileId.equals(subjectProfileId));
    }
    return q.get();
  }

  Future<List<MoodDailyAggregate>> getDailyAggregatesInRange({
    required String enrollmentId,
    required DateTime from,
    required DateTime to,
    String? subjectProfileId,
  }) async {
    final checkins = await getCheckinsInRange(
      enrollmentId: enrollmentId,
      from: from,
      to: to,
      subjectProfileId: subjectProfileId,
    );

    final grouped = <int, List<MoodCheckinsTableData>>{};
    for (final checkin in checkins) {
      grouped.putIfAbsent(checkin.dayKey, () => []).add(checkin);
    }

    final dayKeys = grouped.keys.toList()..sort();
    return dayKeys.map((dayKey) {
      final values = grouped[dayKey]!;
      return MoodDailyAggregate(
        dayKey: dayKey,
        day: DateTime(1970).add(Duration(days: dayKey)),
        mood: _avg(values.map((e) => e.mood)),
        energy: _avg(values.map((e) => e.energy)),
        stress: _avg(values.map((e) => e.stress)),
      );
    }).toList();
  }

  Future<String> createCheckin({
    required String enrollmentId,
    int? mood,
    int? energy,
    int? stress,
    String? note,
    required String source,
    String? subjectProfileId,
  }) async {
    return _db.transaction(() async {
      final userId = _userId;
      if (userId == null) return '';

      final now = _clock.now();
      final checkinId = _uuid.v4();
      final dayKey = now.difference(DateTime(1970)).inDays;
      final normalizedNote = _normalizeNote(note);

      await _db.into(_db.moodCheckinsTable).insert(
            MoodCheckinsTableCompanion.insert(
              id: checkinId,
              userId: userId,
              enrollmentId: enrollmentId,
              recordedAt: now,
              dayKey: dayKey,
              mood: drift.Value(mood),
              energy: drift.Value(energy),
              stress: drift.Value(stress),
              note: drift.Value(normalizedNote),
              source: source,
              subjectProfileId: drift.Value(subjectProfileId),
            ),
          );

      await _syncService.enqueueUpsert(
        tableName: 'mood_checkins',
        recordId: checkinId,
        payload: {
          'id': checkinId,
          'user_id': userId,
          'enrollment_id': enrollmentId,
          'recorded_at': now.toIso8601String(),
          'day_key': dayKey,
          'mood': mood,
          'energy': energy,
          'stress': stress,
          'note': normalizedNote,
          'source': source,
          if (subjectProfileId != null) 'subject_profile_id': subjectProfileId,
        },
      );

      // ── Dual-write: create a linked journal entry when note is present ────────
      // journal_entries is the canonical store for user text; mood_checkins keeps
      // the note for backward-compat but the journal feature reads journal_entries.
      if (normalizedNote != null) {
        final journalId = _uuid.v4();
        await _db.into(_db.journalEntriesTable).insert(
              JournalEntriesTableCompanion.insert(
                id: journalId,
                userId: userId,
                enrollmentId: drift.Value(enrollmentId),
                checkinId: drift.Value(checkinId),
                content: normalizedNote,
                mood: drift.Value(mood),
                energy: drift.Value(energy),
                stress: drift.Value(stress),
                dayKey: dayKey,
                subjectProfileId: drift.Value(subjectProfileId),
              ),
            );

        await _syncService.enqueueUpsert(
          tableName: 'journal_entries',
          recordId: journalId,
          payload: {
            'id': journalId,
            'user_id': userId,
            'enrollment_id': enrollmentId,
            // checkin_id intentionally omitted from the Supabase payload:
            // mood_checkins and journal_entries sync independently; sending
            // a FK reference risks a violation if the checkin hasn't landed yet.
            // The link is maintained locally in Drift for the edit flow.
            'content': normalizedNote,
            'mood': mood,
            'energy': energy,
            'stress': stress,
            'day_key': dayKey,
            'created_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
            if (subjectProfileId != null)
              'subject_profile_id': subjectProfileId,
          },
        );
      }
      return checkinId;
    });
  }

  Future<void> updateCheckin({
    required String id,
    int? mood,
    int? energy,
    int? stress,
    String? note,
  }) async {
    return _db.transaction(() async {
      final userId = _userId;
      if (userId == null) return;

      final normalizedNote = _normalizeNote(note);

      await (_db.update(_db.moodCheckinsTable)..where((t) => t.id.equals(id)))
          .write(
        MoodCheckinsTableCompanion(
          mood: drift.Value(mood),
          energy: drift.Value(energy),
          stress: drift.Value(stress),
          note: drift.Value(normalizedNote),
          needsSync: const drift.Value(true),
        ),
      );

      final updated = await (_db.select(_db.moodCheckinsTable)
            ..where((t) => t.id.equals(id))
            ..limit(1))
          .getSingleOrNull();
      if (updated == null) return;

      await _syncService.enqueueUpsert(
        tableName: 'mood_checkins',
        recordId: id,
        payload: {
          'id': id,
          'user_id': userId,
          'enrollment_id': updated.enrollmentId,
          'session_id': updated.sessionId,
          'recorded_at': updated.recordedAt.toIso8601String(),
          'day_key': updated.dayKey,
          'mood': updated.mood,
          'energy': updated.energy,
          'stress': updated.stress,
          'note': updated.note,
          'source': updated.source,
          if (updated.subjectProfileId != null)
            'subject_profile_id': updated.subjectProfileId,
        },
      );

      // ── Update or create the linked journal entry ─────────────────────────────
      final existingJournal = await (_db.select(_db.journalEntriesTable)
            ..where((t) => t.checkinId.equals(id))
            ..limit(1))
          .getSingleOrNull();

      if (normalizedNote != null) {
        final now = _clock.now();
        if (existingJournal != null) {
          // Update existing journal entry
          await (_db.update(_db.journalEntriesTable)
                ..where((t) => t.id.equals(existingJournal.id)))
              .write(JournalEntriesTableCompanion(
            content: drift.Value(normalizedNote),
            mood: drift.Value(mood),
            energy: drift.Value(energy),
            stress: drift.Value(stress),
            updatedAt: drift.Value(now),
            needsSync: const drift.Value(true),
          ));
          await _syncService.enqueueUpsert(
            tableName: 'journal_entries',
            recordId: existingJournal.id,
            payload: {
              'id': existingJournal.id,
              'user_id': userId,
              'enrollment_id': updated.enrollmentId,
              // checkin_id omitted — no FK on Supabase side; local Drift keeps it
              'content': normalizedNote,
              'mood': mood,
              'energy': energy,
              'stress': stress,
              'day_key': updated.dayKey,
              'updated_at': now.toIso8601String(),
              if (updated.subjectProfileId != null)
                'subject_profile_id': updated.subjectProfileId,
            },
          );
        } else {
          // No linked journal entry yet — create one (e.g. note added on edit)
          final journalId = _uuid.v4();
          await _db.into(_db.journalEntriesTable).insert(
                JournalEntriesTableCompanion.insert(
                  id: journalId,
                  userId: userId,
                  enrollmentId: drift.Value(updated.enrollmentId),
                  checkinId: drift.Value(id),
                  content: normalizedNote,
                  mood: drift.Value(mood),
                  energy: drift.Value(energy),
                  stress: drift.Value(stress),
                  dayKey: updated.dayKey,
                  subjectProfileId: drift.Value(updated.subjectProfileId),
                ),
              );
          await _syncService.enqueueUpsert(
            tableName: 'journal_entries',
            recordId: journalId,
            payload: {
              'id': journalId,
              'user_id': userId,
              'enrollment_id': updated.enrollmentId,
              // checkin_id omitted — no FK on Supabase side; local Drift keeps it
              'content': normalizedNote,
              'mood': mood,
              'energy': energy,
              'stress': stress,
              'day_key': updated.dayKey,
              'created_at': now.toIso8601String(),
              'updated_at': now.toIso8601String(),
              if (updated.subjectProfileId != null)
                'subject_profile_id': updated.subjectProfileId,
            },
          );
        }
      } else if (existingJournal != null) {
        // Note was cleared — delete the journal entry
        await (_db.delete(_db.journalEntriesTable)
              ..where((t) => t.id.equals(existingJournal.id)))
            .go();
        await _syncService.enqueueDelete(
          tableName: 'journal_entries',
          recordId: existingJournal.id,
        );
      }
    });
  }

  Future<void> deleteCheckin({required String id}) async {
    return _db.transaction(() async {
      // Find and delete linked journal entry first (FK ON DELETE SET NULL in
      // Supabase, so we clean up locally and queue a delete for the journal entry)
      final linkedJournal = await (_db.select(_db.journalEntriesTable)
            ..where((t) => t.checkinId.equals(id))
            ..limit(1))
          .getSingleOrNull();
      if (linkedJournal != null) {
        await (_db.delete(_db.journalEntriesTable)
              ..where((t) => t.id.equals(linkedJournal.id)))
            .go();
        await _syncService.enqueueDelete(
          tableName: 'journal_entries',
          recordId: linkedJournal.id,
        );
      }

      await (_db.delete(_db.moodCheckinsTable)..where((t) => t.id.equals(id)))
          .go();
      await _syncService.enqueueDelete(
          tableName: 'mood_checkins', recordId: id);
    });
  }

  /// True if any check-in for this user in [window] has mood ≤ 2 (scale 1–5).
  Future<bool> hasLowMoodInWindow({
    required Duration window,
    int maxMood = 2,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    final from = _clock.now().toUtc().subtract(window);
    final row = await (_db.select(_db.moodCheckinsTable)
          ..where(
            (t) =>
                t.userId.equals(userId) &
                t.recordedAt.isBiggerOrEqualValue(from) &
                t.mood.isNotNull() &
                t.mood.isSmallerOrEqualValue(maxMood),
          )
          ..limit(1))
        .getSingleOrNull();
    return row != null;
  }

  String? _normalizeNote(String? input) {
    final trimmed = input?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  double? _avg(Iterable<int?> values) {
    final nonNull = values.whereType<int>().toList();
    if (nonNull.isEmpty) return null;
    final sum = nonNull.reduce((a, b) => a + b);
    return sum / nonNull.length;
  }
}
