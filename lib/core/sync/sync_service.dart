import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../config/launch_flags.dart';
import '../database/app_database.dart';
import '../logging/app_logger.dart';
import 'connectivity_service.dart';
import 'sync_status.dart';
import '../../features/trainer/domain/services/trainer_notification_service.dart';

const _uuid = Uuid();

class SyncService {
  final AppDatabase _db;
  Timer? _periodicTimer;
  bool _isSyncing = false;
  DateTime? _lastSyncAt;

  final _statusController = StreamController<SyncStatus>.broadcast();
  Stream<SyncStatus> get statusStream => _statusController.stream;

  // ── Rehydration state ─────────────────────────────────────────────────────
  // Tracks whether a rehydrate() call is currently in-flight.
  // Exposed as a broadcast stream so UI can gate decisions on completion.
  // Initial value: false (not rehydrating). Emits true when rehydration starts,
  // false when it ends (success, skip, or error).
  bool _isRehydrating = false;
  bool get isRehydrating => _isRehydrating;

  final _rehydrationController = StreamController<bool>.broadcast();
  Stream<bool> get rehydrationStream => _rehydrationController.stream;

  SyncService(this._db);

  void start() {
    _periodicTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => drain(),
    );
    // Flush any jobs that were stuck in backoff from a previous session
    // (e.g. Supabase table didn't exist yet, network was down, etc.).
    // Resets retryCount so they're processed on the next drain() cycle.
    unawaited(_resetStalledJobs());
    _emitStatus();
  }

  /// Resets retry count on jobs that have been failing but not yet exhausted
  /// (retryCount 1–4). Called on app start so previously-stuck jobs get a
  /// fresh attempt once the underlying issue is resolved (e.g. a missing
  /// Supabase table that has now been created).
  Future<void> _resetStalledJobs() async {
    try {
      await (_db.update(_db.syncJobsTable)
            ..where((t) =>
                t.retryCount.isBiggerThanValue(0) &
                t.retryCount.isSmallerThanValue(5)))
          .write(const SyncJobsTableCompanion(
        retryCount: Value(0),
        lastAttemptAt: Value(null),
      ));
      await drain();
    } catch (_) {}
  }

  void stop() {
    _periodicTimer?.cancel();
    _statusController.close();
    _rehydrationController.close();
  }

  Future<void> drain() async {
    if (_isSyncing) return;
    if (!await ConnectivityService.isConnected()) return;

    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) return;

    _isSyncing = true;
    _emitStatus();
    try {
      await _processPendingJobs(client);
      _lastSyncAt = DateTime.now();
    } finally {
      _isSyncing = false;
      _emitStatus();
    }
  }

  Future<void> _processPendingJobs(SupabaseClient client) async {
    final jobs = await (_db.select(_db.syncJobsTable)
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();

    // Coalesce: for each (table, recordId), keep only the latest job
    // and delete superseded older jobs immediately
    final supersededIds = <String>[];
    final coalesced = <String, SyncJobsTableData>{};
    for (final job in jobs) {
      final key = '${job.tableName_}:${job.recordId}';
      if (coalesced.containsKey(key)) {
        supersededIds.add(coalesced[key]!.id);
      }
      coalesced[key] = job;
    }

    if (supersededIds.isNotEmpty) {
      await (_db.delete(_db.syncJobsTable)
            ..where((t) => t.id.isIn(supersededIds)))
          .go();
      appLogger.d('Deleted ${supersededIds.length} superseded sync jobs');
    }

    for (final job in coalesced.values) {
      if (job.retryCount >= 5) {
        appLogger.w('Sync job ${job.id} exceeded max retries — skipping');
        continue;
      }

      // Exponential backoff: 30s, 60s, 120s, 240s, 480s
      if (job.retryCount > 0 && job.lastAttemptAt != null) {
        final backoffSeconds =
            min(30 * pow(2, job.retryCount - 1).toInt(), 1800);
        final nextRetryAt =
            job.lastAttemptAt!.add(Duration(seconds: backoffSeconds));
        if (DateTime.now().isBefore(nextRetryAt)) continue;
      }

      try {
        if (job.action == 'upsert') {
          final payload = jsonDecode(job.payload) as Map<String, dynamic>;
          await client.from(job.tableName_).upsert(payload);
          // Notify trainer after training session syncs
          if (job.tableName_ == 'training_sessions' &&
              payload['is_completed'] == true) {
            final traineeId = payload['user_id'] as String?;
            final dayNumber = payload['day_number'] as int?;
            if (traineeId != null && dayNumber != null) {
              unawaited(
                TrainerNotificationService.instance.checkAndNotifyTrainer(
                  traineeId,
                  dayNumber,
                ),
              );
            }
          }
        } else if (job.action == 'delete') {
          await client.from(job.tableName_).delete().eq('id', job.recordId);
        }

        await (_db.delete(_db.syncJobsTable)..where((t) => t.id.equals(job.id)))
            .go();

        appLogger.d('Synced ${job.tableName_}:${job.recordId}');
      } on PostgrestException catch (e, st) {
        final recovered = await _recoverFromServerConflict(
            job: job, error: e, client: client);
        if (recovered) {
          appLogger.w(
            'Recovered sync conflict for ${job.tableName_}:${job.recordId}',
          );
          continue;
        }
        appLogger.e('Sync error for job ${job.id}', error: e, stackTrace: st);
        await (_db.update(_db.syncJobsTable)..where((t) => t.id.equals(job.id)))
            .write(SyncJobsTableCompanion(
          retryCount: Value(job.retryCount + 1),
          lastAttemptAt: Value(DateTime.now()),
        ));
      } on AuthException {
        appLogger.w('Auth error during sync — pausing');
        _isSyncing = false;
        return;
      } catch (e, st) {
        appLogger.e('Sync error for job ${job.id}', error: e, stackTrace: st);
        await (_db.update(_db.syncJobsTable)..where((t) => t.id.equals(job.id)))
            .write(SyncJobsTableCompanion(
          retryCount: Value(job.retryCount + 1),
          lastAttemptAt: Value(DateTime.now()),
        ));
      }
    }
  }

  Future<bool> _recoverFromServerConflict({
    required SyncJobsTableData job,
    required PostgrestException error,
    required SupabaseClient client,
  }) async {
    final payload = jsonDecode(job.payload) as Map<String, dynamic>;
    final message = error.message.toString();
    final details = error.details?.toString() ?? '';

    final isEnrollmentConflict = job.tableName_ == 'enrollments' &&
        job.action == 'upsert' &&
        error.code == '23505' &&
        (message.contains('enrollments_user_package_active_unique') ||
            details.contains('enrollments_user_package_active_unique') ||
            message.contains('enrollments_subject_profile_active_unique') ||
            details.contains('enrollments_subject_profile_active_unique') ||
            message.contains('enrollments_legacy_user_package_active_unique') ||
            details.contains('enrollments_legacy_user_package_active_unique'));

    final isOrphanProgressConflict = job.tableName_ == 'progress_entries' &&
        job.action == 'upsert' &&
        error.code == '23503' &&
        (message.contains('progress_entries_enrollment_id_fkey') ||
            details.contains('progress_entries_enrollment_id_fkey'));

    if (!isEnrollmentConflict && !isOrphanProgressConflict) {
      return false;
    }

    final userId = payload['user_id'] as String?;
    final enrollmentId = isEnrollmentConflict
        ? job.recordId
        : payload['enrollment_id'] as String?;
    if (userId == null || enrollmentId == null) return false;

    await _discardLocalEnrollmentGraph(enrollmentId);
    await (_db.delete(_db.syncJobsTable)..where((t) => t.id.equals(job.id)))
        .go();

    if (client.auth.currentUser?.id == userId) {
      await rehydrate(userId);
    }
    return true;
  }

  Future<void> _discardLocalEnrollmentGraph(String enrollmentId) async {
    final progressIds = (await (_db.select(_db.progressEntriesTable)
              ..where((t) => t.enrollmentId.equals(enrollmentId)))
            .get())
        .map((row) => row.id)
        .toList();
    final sessionIds = (await (_db.select(_db.trainingSessionsTable)
              ..where((t) => t.enrollmentId.equals(enrollmentId)))
            .get())
        .map((row) => row.id)
        .toList();
    final moodIds = (await (_db.select(_db.moodCheckinsTable)
              ..where((t) => t.enrollmentId.equals(enrollmentId)))
            .get())
        .map((row) => row.id)
        .toList();
    final journalIds = (await (_db.select(_db.journalEntriesTable)
              ..where((t) => t.enrollmentId.equals(enrollmentId)))
            .get())
        .map((row) => row.id)
        .toList();
    final questionnaireIds =
        (await (_db.select(_db.completionQuestionnairesTable)
                  ..where((t) => t.enrollmentId.equals(enrollmentId)))
                .get())
            .map((row) => row.id)
            .toList();

    await _db.transaction(() async {
      await (_db.delete(_db.progressEntriesTable)
            ..where((t) => t.enrollmentId.equals(enrollmentId)))
          .go();
      await (_db.delete(_db.trainingSessionsTable)
            ..where((t) => t.enrollmentId.equals(enrollmentId)))
          .go();
      await (_db.delete(_db.moodCheckinsTable)
            ..where((t) => t.enrollmentId.equals(enrollmentId)))
          .go();
      await (_db.delete(_db.journalEntriesTable)
            ..where((t) => t.enrollmentId.equals(enrollmentId)))
          .go();
      await (_db.delete(_db.completionQuestionnairesTable)
            ..where((t) => t.enrollmentId.equals(enrollmentId)))
          .go();
      await (_db.delete(_db.enrollmentsTable)
            ..where((t) => t.id.equals(enrollmentId)))
          .go();

      final orphanRecordIds = <String>[
        enrollmentId,
        ...progressIds,
        ...sessionIds,
        ...moodIds,
        ...journalIds,
        ...questionnaireIds,
      ];
      if (orphanRecordIds.isNotEmpty) {
        await (_db.delete(_db.syncJobsTable)
              ..where((t) => t.recordId.isIn(orphanRecordIds)))
            .go();
      }
    });
  }

  // ── Server → Local rehydration ──────────────────────────────────────────────
  //
  // Pulls the authoritative server state for [userId] into the local Drift DB.
  // Called once after every sign-in so that returning users on a fresh device
  // (or after reinstall) see their real progress instead of being re-enrolled.
  //
  // Merge strategy: server wins, UNLESS the local record has needsSync=true
  // (meaning there are local writes not yet uploaded). Local-pending records
  // are skipped so we do not overwrite unsynced progress with stale server data.
  Future<void> rehydrate(String userId) async {
    // Signal rehydration-in-progress BEFORE the first await so the dashboard
    // guard sees isRehydrating=true even if GoRouter builds the screen before
    // the authStateProvider listener fires.  The broadcast stream controller
    // delivers this event synchronously to Riverpod's StreamProvider, making
    // rehydrationProvider = AsyncData(true) immediately.
    _setRehydrating(true);

    if (!await ConnectivityService.isConnected()) {
      // No network — emit completed immediately so UI doesn't wait forever
      _setRehydrating(false);
      return;
    }

    final client = Supabase.instance.client;
    if (client.auth.currentUser?.id != userId) {
      _setRehydrating(false);
      return;
    }

    appLogger.i('SyncService.rehydrate: pulling server data for user $userId');

    try {
      // 1. Pull enrollments
      final enrollmentRows = await client
          .from('enrollments')
          .select()
          .eq('user_id', userId) as List<dynamic>;

      for (final raw in enrollmentRows) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String;

        // Skip records with pending local changes — local wins until uploaded
        final local = await (_db.select(_db.enrollmentsTable)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (local?.needsSync == true) continue;

        await _db.into(_db.enrollmentsTable).insertOnConflictUpdate(
              EnrollmentsTableCompanion.insert(
                id: id,
                userId: row['user_id'] as String,
                subjectProfileId: Value(row['subject_profile_id'] as String?),
                packageId: row['package_id'] as String,
                status: Value(row['status'] as String? ?? 'active'),
                assignedDurationWeeks:
                    row['assigned_duration_weeks'] as int? ?? 8,
                startDate: _parseDate(row['start_date']),
                targetCompletionDate: _parseDate(row['target_completion_date']),
                completedAt: Value(
                  row['completed_at'] != null
                      ? DateTime.parse(row['completed_at'] as String)
                      : null,
                ),
                needsSync: const Value(false),
                updatedAt: Value(
                  row['updated_at'] != null
                      ? DateTime.parse(row['updated_at'] as String)
                      : DateTime.now(),
                ),
              ),
            );
      }

      // 2. Pull progress_entries for all user enrollments
      final enrollmentIds = enrollmentRows
          .map((r) => (r as Map<String, dynamic>)['id'] as String)
          .toList();

      if (enrollmentIds.isEmpty) {
        appLogger.i('SyncService.rehydrate: no enrollments on server');
        return;
      }

      final progressRows = await client
          .from('progress_entries')
          .select()
          .inFilter('enrollment_id', enrollmentIds) as List<dynamic>;

      for (final raw in progressRows) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String;

        final local = await (_db.select(_db.progressEntriesTable)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (local?.needsSync == true) continue;

        await _db.into(_db.progressEntriesTable).insertOnConflictUpdate(
              ProgressEntriesTableCompanion.insert(
                id: id,
                userId: row['user_id'] as String,
                subjectProfileId: Value(row['subject_profile_id'] as String?),
                enrollmentId: row['enrollment_id'] as String,
                currentDay: Value(row['current_day'] as int? ?? 1),
                lastActivityDate: Value(
                  row['last_activity_date'] != null
                      ? DateTime.parse(row['last_activity_date'] as String)
                      : null,
                ),
                consecutiveInactiveDays:
                    Value(row['consecutive_inactive_days'] as int? ?? 0),
                dailyStreak: Value(row['daily_streak'] as int? ?? 0),
                weeklyStreak: Value(row['weekly_streak'] as int? ?? 0),
                trainingsThisWeek:
                    Value(row['trainings_this_week'] as int? ?? 0),
                lastTrainingWeekStart: Value(
                  row['last_training_week_start'] != null
                      ? DateTime.parse(
                          row['last_training_week_start'] as String)
                      : null,
                ),
                weeklyGoal: Value(row['weekly_goal'] as int? ?? 5),
                totalSessionsSinceDisclaimer:
                    Value(row['total_sessions_since_disclaimer'] as int? ?? 0),
                needsSync: const Value(false),
                updatedAt: Value(
                  row['updated_at'] != null
                      ? DateTime.parse(row['updated_at'] as String)
                      : DateTime.now(),
                ),
              ),
            );
      }

      // 3. Pull training_sessions for all user enrollments
      final sessionRows = await client
          .from('training_sessions')
          .select()
          .inFilter('enrollment_id', enrollmentIds) as List<dynamic>;

      for (final raw in sessionRows) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String;

        // Skip records with pending local changes
        final local = await (_db.select(_db.trainingSessionsTable)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (local?.needsSync == true) continue;

        // Supabase returns text[] as List<dynamic>; locally stored as
        // jsonEncode(list) to match the format written by saveCompletedSession.
        final exerciseIds = row['completed_exercise_ids'];
        final exerciseIdsStr = exerciseIds is List
            ? jsonEncode(exerciseIds)
            : (exerciseIds as String? ?? '[]');

        await _db.into(_db.trainingSessionsTable).insertOnConflictUpdate(
              TrainingSessionsTableCompanion.insert(
                id: id,
                userId: row['user_id'] as String,
                subjectProfileId: Value(row['subject_profile_id'] as String?),
                enrollmentId: row['enrollment_id'] as String,
                sessionDate: _parseDate(row['session_date']),
                dayNumber: row['day_number'] as int,
                completedExerciseIds: exerciseIdsStr,
                isCompleted: Value(row['is_completed'] as bool? ?? false),
                completedAt: Value(
                  row['completed_at'] != null
                      ? DateTime.parse(row['completed_at'] as String)
                      : null,
                ),
                needsSync: const Value(false),
                createdAt: Value(
                  row['created_at'] != null
                      ? DateTime.parse(row['created_at'] as String)
                      : DateTime.now(),
                ),
              ),
            );
      }

      // 4. Pull journal_entries for all user enrollments
      final journalRows = await client
          .from('journal_entries')
          .select()
          .eq('user_id', userId) as List<dynamic>;

      for (final raw in journalRows) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String;

        final local = await (_db.select(_db.journalEntriesTable)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (local?.needsSync == true) continue;

        // checkin_id is not stored on Supabase (no FK there); preserve whatever
        // the local record has so the edit flow keeps working.
        final existingCheckinId = local?.checkinId;

        await _db.into(_db.journalEntriesTable).insertOnConflictUpdate(
              JournalEntriesTableCompanion.insert(
                id: id,
                userId: row['user_id'] as String,
                enrollmentId: Value(row['enrollment_id'] as String?),
                checkinId: Value(existingCheckinId),
                content: row['content'] as String,
                mood: Value(row['mood'] as int?),
                energy: Value(row['energy'] as int?),
                stress: Value(row['stress'] as int?),
                dayKey: row['day_key'] as int,
                createdAt: Value(
                  row['created_at'] != null
                      ? DateTime.parse(row['created_at'] as String)
                      : DateTime.now(),
                ),
                updatedAt: Value(
                  row['updated_at'] != null
                      ? DateTime.parse(row['updated_at'] as String)
                      : DateTime.now(),
                ),
                needsSync: const Value(false),
              ),
            );
      }

      // 5. Pull streak_credits — deliberately last. The whole rehydrate body
      // shares one try block, so a failure here must not skip the tables
      // above. Gated because the server table only exists after the migration
      // 2026082301_streak_credits.sql has been applied.
      var creditCount = 0;
      if (kStreakCreditsServerSyncEnabled) {
        final creditRows = await client
            .from('streak_credits')
            .select()
            .eq('user_id', userId) as List<dynamic>;
        creditCount = creditRows.length;

        for (final raw in creditRows) {
          final row = raw as Map<String, dynamic>;
          final id = row['id'] as String;

          // Skip records with pending local changes
          final local = await (_db.select(_db.streakCreditsTable)
                ..where((t) => t.id.equals(id)))
              .getSingleOrNull();
          if (local?.needsSync == true) continue;

          // Postgres date[] -> the JSON list StreakCreditsRepository reads
          final rescued = (row['rescued_days'] as List<dynamic>? ?? const [])
              .map((value) => value as String)
              .toList()
            ..sort();
          final lastCounted = row['last_counted_day'] as String?;

          await _db.into(_db.streakCreditsTable).insertOnConflictUpdate(
                StreakCreditsTableCompanion.insert(
                  id: id,
                  userId: row['user_id'] as String,
                  subjectProfileId: row['subject_profile_id'] as String,
                  available: Value(row['available'] as int? ?? 0),
                  progressToNext: Value(row['progress_to_next'] as int? ?? 0),
                  lastCountedDay: Value(
                    lastCounted == null ? null : DateTime.parse(lastCounted),
                  ),
                  rescuedDays: Value(jsonEncode(rescued)),
                  needsSync: const Value(false),
                  updatedAt: Value(
                    row['updated_at'] != null
                        ? DateTime.parse(row['updated_at'] as String)
                        : DateTime.now(),
                  ),
                ),
              );
        }
      }

      appLogger.i(
        'SyncService.rehydrate: pulled ${enrollmentRows.length} enrollments, '
        '${progressRows.length} progress entries, '
        '${sessionRows.length} training sessions, '
        '${journalRows.length} journal entries, '
        '$creditCount streak credits',
      );
    } on AuthException {
      appLogger.w('SyncService.rehydrate: auth error — skipping');
    } catch (e, st) {
      appLogger.e('SyncService.rehydrate failed', error: e, stackTrace: st);
    } finally {
      _setRehydrating(false);
    }
  }

  void _setRehydrating(bool value) {
    _isRehydrating = value;
    if (!_rehydrationController.isClosed) {
      _rehydrationController.add(value);
    }
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    final s = value as String;
    // Handles both 'YYYY-MM-DD' and full ISO-8601 timestamps
    return DateTime.parse(s.length == 10 ? '${s}T00:00:00.000Z' : s);
  }

  Future<void> enqueueUpsert({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    await _db.into(_db.syncJobsTable).insertOnConflictUpdate(
          SyncJobsTableCompanion.insert(
            id: _uuid.v4(),
            action: 'upsert',
            tableName_: tableName,
            recordId: recordId,
            payload: jsonEncode(payload),
          ),
        );
    _emitStatus();
    // Attempt immediate sync so data reaches Supabase without waiting for the
    // 5-minute periodic timer. Fire-and-forget — if it fails the job stays
    // in the queue and will be retried by the timer.
    unawaited(drain());
  }

  Future<void> enqueueDelete({
    required String tableName,
    required String recordId,
  }) async {
    await _db.into(_db.syncJobsTable).insertOnConflictUpdate(
          SyncJobsTableCompanion.insert(
            id: _uuid.v4(),
            action: 'delete',
            tableName_: tableName,
            recordId: recordId,
            payload: '{}',
          ),
        );
    _emitStatus();
    unawaited(drain());
  }

  Future<void> _emitStatus() async {
    if (_statusController.isClosed) return;
    try {
      final all = await (_db.select(_db.syncJobsTable)).get();
      final failed = all.where((j) => j.retryCount >= 5).length;
      final pending = all.length - failed;
      _statusController.add(SyncStatus(
        isSyncing: _isSyncing,
        pendingCount: pending,
        failedCount: failed,
        lastSyncAt: _lastSyncAt,
      ));
    } catch (_) {
      // DB may not be ready yet on startup
    }
  }
}
