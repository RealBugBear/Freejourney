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
import 'sync_backend.dart';

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

  final SyncBackend _backend;
  final Future<bool> Function() _isConnected;
  // Capture the application zone before any Drift transaction is entered.
  final Zone _syncZone = Zone.current;
  bool _paused = false;
  bool _stopped = false;
  int _sessionEpoch = 0;
  Future<void>? _drainFuture;
  Future<void>? _rehydrateFuture;
  Future<void>? _cleanupFuture;
  String? _rehydratingUserId;

  SyncService(this._db,
      {SyncBackend? backend, Future<bool> Function()? isConnected})
      : _backend = backend ?? SupabaseSyncBackend(),
        _isConnected = isConnected ?? ConnectivityService.isConnected;

  /// Invalidates in-flight responses before local account data is erased.
  void pauseForSignOut() {
    _paused = true;
    _sessionEpoch++;
    _setRehydrating(false);
  }

  Future<bool> clearUserDataForSignOut({bool discardPendingChanges = false}) {
    pauseForSignOut();
    final epoch = _sessionEpoch;
    final cleanup = _db.transaction(() async {
      final pending = await (_db.select(_db.syncJobsTable)..limit(1)).get();
      if (!discardPendingChanges && pending.isNotEmpty) {
        if (_sessionEpoch == epoch) _paused = false;
        return false;
      }
      await _db.clearUserData();
      return true;
    });
    _cleanupFuture =
        cleanup.then((_) {}, onError: (Object _, StackTrace __) {});
    return cleanup;
  }

  bool _isCurrent(String userId, int epoch) =>
      !_paused &&
      !_stopped &&
      _sessionEpoch == epoch &&
      _backend.userId == userId;

  void start() {
    if (_stopped || _periodicTimer != null) return;
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
    _stopped = true;
    pauseForSignOut();
    _periodicTimer?.cancel();
    _statusController.close();
    _rehydrationController.close();
  }

  Future<void> drain() {
    if (_stopped || _paused || _isRehydrating) return Future.value();
    if (_isSyncing) return _drainFuture ?? Future.value();
    // Reserve before the first await: connectivity checks can complete together.
    _isSyncing = true;
    return _drainFuture = _drain();
  }

  Future<void> _drain() async {
    try {
      final userId = _backend.userId;
      final epoch = _sessionEpoch;
      if (userId == null || !await _isConnected() || !_isCurrent(userId, epoch))
        return;
      await _emitStatus();
      await _processPendingJobs(userId, epoch);
      if (_isCurrent(userId, epoch)) _lastSyncAt = DateTime.now();
    } catch (error, stack) {
      appLogger.e('Sync drain failed',
          error: error.runtimeType, stackTrace: stack);
    } finally {
      _isSyncing = false;
      await _emitStatus();
    }
  }

  Future<void> _processPendingJobs(String userId, int epoch) async {
    // Insertion order is authoritative: created_at has second resolution and
    // business timestamps can be backdated. Keep partial updates intact instead
    // of throwing away fields by coalescing them to only the last payload.
    final jobs = await (_db.select(_db.syncJobsTable)
          ..orderBy(
              [(t) => OrderingTerm.asc(const CustomExpression<int>('rowid'))]))
        .get();
    final blockedRecords = <String>{};
    for (final job in jobs) {
      if (!_isCurrent(userId, epoch)) return;
      final key = '${job.tableName_}:${job.recordId}';
      if (blockedRecords.contains(key)) continue;
      if (job.retryCount > 0 && job.lastAttemptAt != null) {
        final backoffSeconds =
            min(30 * pow(2, min(job.retryCount - 1, 6)).toInt(), 1800);
        if (DateTime.now().isBefore(
            job.lastAttemptAt!.add(Duration(seconds: backoffSeconds)))) {
          blockedRecords.add(key);
          continue;
        }
      }
      try {
        if (job.action == 'upsert') {
          final payload = jsonDecode(job.payload) as Map<String, dynamic>;
          // Defense in depth for stale jobs after account switching. Server RLS
          // remains authoritative, including tables without user_id columns.
          if (payload['user_id'] != null && payload['user_id'] != userId) {
            blockedRecords.add(key);
            continue;
          }
          await _backend
              .upsert(job.tableName_, payload)
              .timeout(const Duration(seconds: 20));
        } else if (job.action == 'delete') {
          await _backend
              .delete(job.tableName_, job.recordId)
              .timeout(const Duration(seconds: 20));
        } else {
          throw const FormatException('Unsupported outbox action');
        }
        if (!_isCurrent(userId, epoch)) return;
        await _db.transaction(() async {
          if (!_isCurrent(userId, epoch)) return;
          // A stable-ID job may have been replaced while its request was in
          // flight. Acknowledge only the exact version that was transmitted.
          final removed = await (_db.delete(_db.syncJobsTable)
                ..where((t) =>
                    t.id.equals(job.id) &
                    t.payload.equals(job.payload) &
                    t.action.equals(job.action)))
              .go();
          final remaining = await (_db.select(_db.syncJobsTable)
                ..where((t) =>
                    t.tableName_.equals(job.tableName_) &
                    t.recordId.equals(job.recordId)))
              .get();
          if (removed == 1 && remaining.isEmpty && job.action == 'upsert') {
            final tables =
                _db.allTables.where((t) => t.actualTableName == job.tableName_);
            if (tables.isNotEmpty &&
                tables.single.columnsByName.containsKey('needs_sync')) {
              final table = tables.single;
              await _db.customUpdate(
                'UPDATE "${table.actualTableName}" SET needs_sync = 0 WHERE id = ?',
                variables: [Variable<String>(job.recordId)],
                updates: {table},
              );
            }
          }
        });
      } on AuthException {
        return;
      } catch (error, stack) {
        if (!_isCurrent(userId, epoch)) return;
        blockedRecords.add(key);
        // Never delete the local enrollment graph on FK/unique conflicts. It
        // may contain the only copy of offline training, mood and journal data.
        appLogger.e('Sync job retained for retry',
            error: error.runtimeType, stackTrace: stack);
        await (_db.update(_db.syncJobsTable)
              ..where((t) =>
                  t.id.equals(job.id) &
                  t.payload.equals(job.payload) &
                  t.action.equals(job.action)))
            .write(SyncJobsTableCompanion(
          retryCount: Value(min(job.retryCount + 1, 30)),
          lastAttemptAt: Value(DateTime.now()),
        ));
      }
    }
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
  Future<void> rehydrate(String userId) {
    if (_stopped || _backend.userId != userId) return Future.value();
    if (_isRehydrating && !_paused && _rehydratingUserId == userId) {
      return _rehydrateFuture ?? Future.value();
    }
    _paused = false;
    _rehydratingUserId = userId;
    final epoch = ++_sessionEpoch;
    _setRehydrating(true);
    return _rehydrateFuture = _rehydrate(userId, epoch);
  }

  Future<void> _rehydrate(String userId, int epoch) async {
    try {
      await _cleanupFuture;
      await _drainFuture;
      if (!await _isConnected() || !_isCurrent(userId, epoch)) return;
      final enrollmentRows = await _backend.fetch('enrollments', userId);
      final enrollmentIds =
          enrollmentRows.map((row) => row['id'] as String).toList();
      final progressRows = await _backend.fetch('progress_entries', userId);
      final sessionRows = await _backend.fetch('training_sessions', userId);
      final journalRows = await _backend.fetch('journal_entries', userId);
      final moodRows = await _backend.fetch('mood_checkins', userId);
      final intakeRows = await _backend.fetch('intake_assessments', userId,
          enrollmentIds: enrollmentIds);
      final questionnaireRows = await _backend.fetch(
          'completion_questionnaires', userId,
          enrollmentIds: enrollmentIds);
      final creditRows = kStreakCreditsServerSyncEnabled
          ? await _backend.fetch('streak_credits', userId)
          : <Map<String, dynamic>>[];
      if (!_isCurrent(userId, epoch)) return;
      // No network inside the transaction. Sign-out erasure is serialized after
      // this merge, and a stale response cannot repopulate another account's DB.
      await _db.transaction(() async {
        if (!_isCurrent(userId, epoch)) return;
        final pending = await _db.select(_db.syncJobsTable).get();
        final pendingKeys =
            pending.map((j) => '${j.tableName_}:${j.recordId}').toSet();
        bool pendingWrite(String table, String id) =>
            pendingKeys.contains('$table:$id');
        for (final raw in enrollmentRows) {
          final row = raw;
          final id = row['id'] as String;
          if (pendingWrite('enrollments', id)) continue;

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
                  pausedAt: Value(row['paused_at'] == null
                      ? null
                      : DateTime.parse(row['paused_at'] as String)),
                  precedingEnrollmentId:
                      Value(row['preceding_enrollment_id'] as String?),
                  createdAt: Value(_parseDate(row['created_at'])),
                  status: Value(row['status'] as String? ?? 'active'),
                  assignedDurationWeeks:
                      row['assigned_duration_weeks'] as int? ?? 8,
                  startDate: _parseDate(row['start_date']),
                  targetCompletionDate:
                      _parseDate(row['target_completion_date']),
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

        for (final raw in progressRows) {
          final row = raw;
          final id = row['id'] as String;
          if (pendingWrite('progress_entries', id)) continue;

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
                  lastDisclaimerAcceptedAt: Value(
                      row['last_disclaimer_accepted_at'] == null
                          ? null
                          : DateTime.parse(
                              row['last_disclaimer_accepted_at'] as String)),
                  totalSessionsSinceDisclaimer: Value(
                      row['total_sessions_since_disclaimer'] as int? ?? 0),
                  needsSync: const Value(false),
                  updatedAt: Value(
                    row['updated_at'] != null
                        ? DateTime.parse(row['updated_at'] as String)
                        : DateTime.now(),
                  ),
                ),
              );
        }

        for (final raw in sessionRows) {
          final row = raw;
          final id = row['id'] as String;
          if (pendingWrite('training_sessions', id)) continue;

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

        for (final raw in journalRows) {
          final row = raw;
          final id = row['id'] as String;
          if (pendingWrite('journal_entries', id)) continue;

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
                  subjectProfileId: Value(row['subject_profile_id'] as String?),
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
          creditCount = creditRows.length;

          for (final raw in creditRows) {
            final row = raw;
            final id = row['id'] as String;
            if (pendingWrite('streak_credits', id)) continue;

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

        for (final row in moodRows) {
          final id = row['id'] as String;
          if (pendingWrite('mood_checkins', id)) continue;
          final local = await (_db.select(_db.moodCheckinsTable)
                ..where((t) => t.id.equals(id)))
              .getSingleOrNull();
          if (local?.needsSync == true) continue;
          await _db
              .into(_db.moodCheckinsTable)
              .insertOnConflictUpdate(MoodCheckinsTableCompanion.insert(
                id: id,
                userId: row['user_id'] as String,
                enrollmentId: row['enrollment_id'] as String,
                sessionId: Value(row['session_id'] as String?),
                recordedAt: _parseDate(row['recorded_at']),
                dayKey: row['day_key'] as int,
                mood: Value(row['mood'] as int?),
                energy: Value(row['energy'] as int?),
                stress: Value(row['stress'] as int?),
                note: Value(row['note'] as String?),
                source: row['source'] as String,
                subjectProfileId: Value(row['subject_profile_id'] as String?),
                needsSync: const Value(false),
                createdAt: Value(_parseDate(row['created_at'])),
              ));
        }
        for (final row in intakeRows) {
          final id = row['id'] as String;
          if (pendingWrite('intake_assessments', id)) continue;
          final local = await (_db.select(_db.intakeAssessmentsTable)
                ..where((t) => t.id.equals(id)))
              .getSingleOrNull();
          if (local?.needsSync == true) continue;
          await _db
              .into(_db.intakeAssessmentsTable)
              .insertOnConflictUpdate(IntakeAssessmentsTableCompanion.insert(
                id: id,
                enrollmentId: row['enrollment_id'] as String,
                hadIsometricWithTrainer:
                    row['had_isometric_with_trainer'] as bool,
                additionalAnswers: Value(row['additional_answers'] == null
                    ? null
                    : row['additional_answers'] is String
                        ? row['additional_answers'] as String
                        : jsonEncode(row['additional_answers'])),
                recommendedDurationWeeks:
                    row['recommended_duration_weeks'] as int,
                userAcceptedRecommendation:
                    row['user_accepted_recommendation'] as bool,
                finalDurationWeeks: row['final_duration_weeks'] as int,
                completedAt: _parseDate(row['completed_at']),
                needsSync: const Value(false),
              ));
        }
        for (final row in questionnaireRows) {
          final id = row['id'] as String;
          if (pendingWrite('completion_questionnaires', id)) continue;
          final local = await (_db.select(_db.completionQuestionnairesTable)
                ..where((t) => t.id.equals(id)))
              .getSingleOrNull();
          if (local?.needsSync == true) continue;
          await _db
              .into(_db.completionQuestionnairesTable)
              .insertOnConflictUpdate(
                  CompletionQuestionnairesTableCompanion.insert(
                id: id,
                enrollmentId: row['enrollment_id'] as String,
                response: row['response'] as bool,
                result: row['result'] as String,
                attemptNumber: Value(row['attempt_number'] as int? ?? 1),
                nextEnrollmentCreated:
                    Value(row['next_enrollment_created'] as bool? ?? false),
                subjectProfileId: Value(row['subject_profile_id'] as String?),
                submittedAt: _parseDate(row['submitted_at']),
                needsSync: const Value(false),
              ));
        }
        appLogger.i(
          'SyncService.rehydrate: pulled ${enrollmentRows.length} enrollments, '
          '${progressRows.length} progress entries, '
          '${sessionRows.length} training sessions, '
          '${journalRows.length} journal entries, '
          '$creditCount streak credits',
        );
      });
    } on AuthException {
      appLogger.w('SyncService.rehydrate: auth error — skipping');
    } catch (e, st) {
      appLogger.e('SyncService.rehydrate failed',
          error: e.runtimeType, stackTrace: st);
    } finally {
      if (_sessionEpoch == epoch) {
        _setRehydrating(false);
        unawaited(drain());
      }
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
    return DateTime.parse(s);
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
    // Attempt immediate sync so data reaches Supabase without waiting for the
    // 5-minute periodic timer. Fire-and-forget — if it fails the job stays
    // in the queue and will be retried by the timer.
    _scheduleDrain();
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
    _scheduleDrain();
  }

  void _scheduleDrain() {
    // Outbox writes may participate in a caller's atomic transaction. Starting
    // network work in that transaction's zone can outlive/poison its executor.
    _syncZone.run(() {
      unawaited(_emitStatus());
      unawaited(drain());
    });
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
