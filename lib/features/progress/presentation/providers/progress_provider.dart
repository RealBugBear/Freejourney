import 'dart:convert';

import 'package:drift/drift.dart' as drift;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/settings/settings_provider.dart';
import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../../../core/time/app_clock_provider.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

const _uuid = Uuid();

const packageOrder = [
  'moro',
  'spinal_galant',
  'tlr',
  'babkin',
  'such_saug',
  'atnr',
  'stnr',
  'babinski',
  'landau',
];

const freePackageIds = {'moro', 'spinal_galant', 'tlr'};

String? nextPackageIdAfter(String packageId) {
  final currentIndex = packageOrder.indexOf(packageId);
  if (currentIndex < 0 || currentIndex >= packageOrder.length - 1) {
    return null;
  }
  return packageOrder[currentIndex + 1];
}

class PackageCompletionResult {
  const PackageCompletionResult({
    this.nextPackageId,
    this.resumedPackageId,
    this.wasMoroReactivation = false,
  });

  final String? nextPackageId;
  final String? resumedPackageId;
  final bool wasMoroReactivation;
}

DateTime _weekStart(DateTime date) {
  return DateTime(date.year, date.month, date.day - (date.weekday - 1));
}

// ── Selected package (persisted to SharedPreferences, scoped per profile) ─────
//
// Key format: 'selected_package_id_<userId>_<subjectProfileId>'
// Fallback reads the previous user-scoped key once so existing installs keep
// their current package selection until each profile gets its own value.

class _SelectedPackageNotifier extends StateNotifier<String> {
  static String _legacyPrefKey(String? userId) =>
      userId != null ? 'selected_package_id_$userId' : 'selected_package_id';

  static String _prefKey(String? userId, String? subjectProfileId) {
    if (userId == null || subjectProfileId == null) {
      return _legacyPrefKey(userId);
    }
    return 'selected_package_id_${userId}_$subjectProfileId';
  }

  final SharedPreferences _prefs;
  final String _storageKey;

  _SelectedPackageNotifier(
    this._prefs,
    String? userId,
    String? subjectProfileId,
  )   : _storageKey = _prefKey(userId, subjectProfileId),
        super(
          _prefs.getString(_prefKey(userId, subjectProfileId)) ??
              _prefs.getString(_legacyPrefKey(userId)) ??
              'moro',
        );

  void select(String packageId) {
    state = packageId;
    _prefs.setString(_storageKey, packageId);
  }
}

final selectedPackageIdProvider =
    StateNotifierProvider<_SelectedPackageNotifier, String>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  // Watch auth state so the notifier is re-created on sign-out/sign-in,
  // loading the correct user-scoped key from SharedPreferences.
  final userId = ref.watch(authStateProvider).valueOrNull?.session?.user.id ??
      Supabase.instance.client.auth.currentUser?.id;
  final subjectProfileId = ref.watch(selectedSubjectProfileProvider)?.id;
  return _SelectedPackageNotifier(prefs, userId, subjectProfileId);
});

// ── Active enrollment (for the currently selected package) ────────────────────

final activeEnrollmentProvider = StreamProvider<EnrollmentsTableData?>((ref) {
  final db = ref.watch(databaseProvider);
  // Watch auth state so this provider re-evaluates when the user changes.
  final userId = ref.watch(authStateProvider).valueOrNull?.session?.user.id ??
      Supabase.instance.client.auth.currentUser?.id;
  final packageId = ref.watch(selectedPackageIdProvider);
  final subjectProfileId = ref.watch(selectedSubjectProfileProvider)?.id;
  if (userId == null) return Stream.value(null);

  return (db.select(db.enrollmentsTable)
        ..where((t) =>
            t.userId.equals(userId) &
            t.packageId.equals(packageId) &
            t.status.equals('active') &
            (subjectProfileId == null
                ? t.subjectProfileId.isNull()
                : (t.subjectProfileId.equals(subjectProfileId) |
                    t.subjectProfileId.isNull())))
        ..orderBy([
          (t) => drift.OrderingTerm(
                expression: t.subjectProfileId.equals(subjectProfileId ?? ''),
                mode: drift.OrderingMode.desc,
              ),
        ])
        ..limit(1))
      .watchSingleOrNull();
});

// ── Active progress entry ─────────────────────────────────────────────────────

final activeProgressProvider = StreamProvider<ProgressEntriesTableData?>((ref) {
  final db = ref.watch(databaseProvider);
  final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
  if (enrollment == null) return Stream.value(null);

  return (db.select(db.progressEntriesTable)
        ..where((t) => t.enrollmentId.equals(enrollment.id))
        ..limit(1))
      .watchSingleOrNull();
});

// ── Sessions completed this week ──────────────────────────────────────────────

final thisWeekSessionsProvider =
    StreamProvider<List<TrainingSessionsTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
  if (enrollment == null) return Stream.value([]);

  final weekStart = _weekStart(DateTime.now());

  return (db.select(db.trainingSessionsTable)
        ..where((t) =>
            t.enrollmentId.equals(enrollment.id) &
            t.sessionDate.isBiggerOrEqualValue(weekStart) &
            t.dayNumber.isBiggerThanValue(0) &
            t.isCompleted.equals(true)))
      .watch();
});

final todayVorrundeSessionProvider = StreamProvider<bool>((ref) {
  final db = ref.watch(databaseProvider);
  final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
  if (enrollment == null) return Stream.value(false);
  final now = ref.watch(appClockProvider).now();
  final today = DateTime(now.year, now.month, now.day);

  return (db.select(db.trainingSessionsTable)
        ..where((t) =>
            t.enrollmentId.equals(enrollment.id) &
            t.sessionDate.equals(today) &
            t.dayNumber.equals(0) &
            t.isCompleted.equals(true))
        ..limit(1))
      .watch()
      .map((rows) => rows.isNotEmpty);
});

// ── Create enrollment after intake assessment ─────────────────────────────────

// ── Create enrollment — idempotent on both local DB and Supabase ──────────────
//
// Idempotenz-Strategie (zwei Ebenen):
//   1. Lokale DB: prüfe vor dem Insert, ob bereits ein aktives Enrollment
//      für (userId, packageId) existiert → return early.
//   2. Supabase: SyncService nutzt UPSERT. Supabase hat zusätzlich einen
//      UNIQUE-Partial-Index auf (user_id, package_id) WHERE status='active'
//      (siehe supabase/idempotency_constraints.sql). Ein doppelter UPSERT
//      mit identischer enrollmentId ist ein No-op; eine andere ID schlägt
//      mit UniqueViolation fehl → verhindert Datenverlust.
//
// Sonderfall fresh device: Wenn die lokale DB leer ist (nach Reinstall),
// schlägt der lokale Check fehl und ein neues Enrollment wird erstellt.
// Der nachfolgende Supabase-UPSERT ÜBERSCHREIBT das existierende Enrollment
// NICHT (dank UNIQUE Index). Stattdessen schlägt er mit einem Conflict-Fehler
// fehl, der im SyncService als retry-fähiger Fehler behandelt wird.
// rehydrate() wird bei sign-in aufgerufen und lädt das echte Enrollment vor
// dem Intake-Assessment in die lokale DB, sodass der lokale Check greift.
Future<String> createEnrollment({
  required AppDatabase db,
  required SyncService syncService,
  required String userId,
  required String? subjectProfileId,
  required String packageId,
  required int durationWeeks,
}) async {
  // Lokaler Idempotenz-Check — verhindert Duplicate in der Drift-DB.
  // Auf frischen Geräten ist die DB leer; rehydrate() lädt das Server-Enrollment
  // vor Ausführung dieser Funktion, sodass dieser Check auch dann greift.
  final existing = await (db.select(db.enrollmentsTable)
        ..where((t) =>
            t.userId.equals(userId) &
            (subjectProfileId == null
                ? t.subjectProfileId.isNull()
                : t.subjectProfileId.equals(subjectProfileId)) &
            t.packageId.equals(packageId) &
            t.status.equals('active'))
        ..limit(1))
      .getSingleOrNull();
  if (existing != null) return existing.id;

  final now = DateTime.now();
  final enrollmentId = _uuid.v4();
  final progressId = _uuid.v4();
  final target = now.add(Duration(days: durationWeeks * 7));

  await db.into(db.enrollmentsTable).insert(
        EnrollmentsTableCompanion.insert(
          id: enrollmentId,
          userId: userId,
          subjectProfileId: drift.Value(subjectProfileId),
          packageId: packageId,
          assignedDurationWeeks: durationWeeks,
          startDate: DateTime(now.year, now.month, now.day),
          targetCompletionDate: DateTime(target.year, target.month, target.day),
        ),
      );

  await db.into(db.progressEntriesTable).insert(
        ProgressEntriesTableCompanion.insert(
          id: progressId,
          userId: userId,
          subjectProfileId: drift.Value(subjectProfileId),
          enrollmentId: enrollmentId,
        ),
      );

  await syncService.enqueueUpsert(
    tableName: 'enrollments',
    recordId: enrollmentId,
    payload: {
      'id': enrollmentId,
      'user_id': userId,
      if (subjectProfileId != null) 'subject_profile_id': subjectProfileId,
      'package_id': packageId,
      'status': 'active',
      'assigned_duration_weeks': durationWeeks,
      'start_date': now.toIso8601String().substring(0, 10),
      'target_completion_date': target.toIso8601String().substring(0, 10),
    },
  );
  await syncService.enqueueUpsert(
    tableName: 'progress_entries',
    recordId: progressId,
    payload: {
      'id': progressId,
      'user_id': userId,
      if (subjectProfileId != null) 'subject_profile_id': subjectProfileId,
      'enrollment_id': enrollmentId,
      'current_day': 1,
    },
  );
  return enrollmentId;
}

Future<void> createIntakeAssessment({
  required AppDatabase db,
  required SyncService syncService,
  required String enrollmentId,
  required bool hadIsometricWithTrainer,
  required int recommendedDurationWeeks,
  required bool userAcceptedRecommendation,
  required int finalDurationWeeks,
  required List<String> entryPoints,
}) async {
  final id = _uuid.v4();
  final now = DateTime.now();
  final additionalAnswers =
      entryPoints.isEmpty ? null : jsonEncode({'entry_points': entryPoints});

  await db.into(db.intakeAssessmentsTable).insert(
        IntakeAssessmentsTableCompanion.insert(
          id: id,
          enrollmentId: enrollmentId,
          hadIsometricWithTrainer: hadIsometricWithTrainer,
          additionalAnswers: drift.Value(additionalAnswers),
          recommendedDurationWeeks: recommendedDurationWeeks,
          userAcceptedRecommendation: userAcceptedRecommendation,
          finalDurationWeeks: finalDurationWeeks,
          completedAt: now,
        ),
      );

  await syncService.enqueueUpsert(
    tableName: 'intake_assessments',
    recordId: id,
    payload: {
      'id': id,
      'enrollment_id': enrollmentId,
      'had_isometric_with_trainer': hadIsometricWithTrainer,
      if (additionalAnswers != null) 'additional_answers': additionalAnswers,
      'recommended_duration_weeks': recommendedDurationWeeks,
      'user_accepted_recommendation': userAcceptedRecommendation,
      'final_duration_weeks': finalDurationWeeks,
      'completed_at': now.toIso8601String(),
    },
  );
}

// ── All enrollments for the current user (all packages) ──────────────────────

final allUserEnrollmentsProvider =
    StreamProvider<List<EnrollmentsTableData>>((ref) {
  final db = ref.watch(databaseProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.session?.user.id ??
      Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return Stream.value([]);

  return (db.select(db.enrollmentsTable)..where((t) => t.userId.equals(userId)))
      .watch();
});

// ── Completion questionnaire ready? ──────────────────────────────────────────

final completionReadyProvider = Provider<bool>((ref) {
  final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;
  if (enrollment == null || enrollment.status != 'active') return false;
  final now = ref.watch(appClockProvider).now();
  final today = DateTime(now.year, now.month, now.day);
  final target = enrollment.targetCompletionDate;
  final targetDay = DateTime(target.year, target.month, target.day);
  return !today.isBefore(targetDay);
});

final moroCompletedProvider = Provider<bool>((ref) {
  final enrollments = ref.watch(allUserEnrollmentsProvider).valueOrNull ?? [];
  return enrollments.any(
    (e) => e.packageId == 'moro' && e.status == 'completed',
  );
});

// ── Complete enrollment (questionnaire passed) ────────────────────────────────

Future<PackageCompletionResult> completeEnrollment({
  required AppDatabase db,
  required SyncService syncService,
  required EnrollmentsTableData enrollment,
}) async {
  final now = DateTime.now();
  await (db.update(db.enrollmentsTable)
        ..where((t) => t.id.equals(enrollment.id)))
      .write(EnrollmentsTableCompanion(
    status: const drift.Value('completed'),
    completedAt: drift.Value(now),
    needsSync: const drift.Value(true),
    updatedAt: drift.Value(now),
  ));

  final qId = _uuid.v4();
  final subjectProfileId = enrollment.subjectProfileId;
  await db.into(db.completionQuestionnairesTable).insert(
        CompletionQuestionnairesTableCompanion.insert(
          id: qId,
          enrollmentId: enrollment.id,
          response: true,
          result: 'passed',
          subjectProfileId: drift.Value(subjectProfileId),
          submittedAt: now,
        ),
      );

  await syncService.enqueueUpsert(
    tableName: 'enrollments',
    recordId: enrollment.id,
    payload: {
      'id': enrollment.id,
      'status': 'completed',
      'completed_at': now.toIso8601String(),
    },
  );
  await syncService.enqueueUpsert(
    tableName: 'completion_questionnaires',
    recordId: qId,
    payload: {
      'id': qId,
      'enrollment_id': enrollment.id,
      'attempt_number': 1,
      'response': true,
      'result': 'passed',
      'submitted_at': now.toIso8601String(),
      if (subjectProfileId != null) 'subject_profile_id': subjectProfileId,
    },
  );

  if (enrollment.packageId == 'moro' &&
      enrollment.precedingEnrollmentId != null) {
    final resumed = await _resumeInterruptedEnrollmentAfterMoro(
      db: db,
      syncService: syncService,
      enrollmentId: enrollment.precedingEnrollmentId!,
      now: now,
    );
    return PackageCompletionResult(
      resumedPackageId: resumed?.packageId,
      wasMoroReactivation: resumed != null,
    );
  }

  return PackageCompletionResult(
    nextPackageId: nextPackageIdAfter(enrollment.packageId),
  );
}

// ── Extend enrollment by N days (questionnaire not yet passed) ────────────────

Future<void> extendEnrollment({
  required AppDatabase db,
  required SyncService syncService,
  required EnrollmentsTableData enrollment,
  int days = 7,
}) async {
  final now = DateTime.now();
  final newTarget = enrollment.targetCompletionDate.add(Duration(days: days));

  await (db.update(db.enrollmentsTable)
        ..where((t) => t.id.equals(enrollment.id)))
      .write(EnrollmentsTableCompanion(
    targetCompletionDate: drift.Value(newTarget),
    needsSync: const drift.Value(true),
    updatedAt: drift.Value(now),
  ));

  final qId = _uuid.v4();
  // Record the "not yet" attempt
  final existing = await (db.select(db.completionQuestionnairesTable)
        ..where((t) => t.enrollmentId.equals(enrollment.id))
        ..orderBy([(t) => drift.OrderingTerm.desc(t.submittedAt)])
        ..limit(1))
      .getSingleOrNull();
  final attempt = (existing?.attemptNumber ?? 0) + 1;

  final extendSubjectProfileId = enrollment.subjectProfileId;
  await db.into(db.completionQuestionnairesTable).insert(
        CompletionQuestionnairesTableCompanion.insert(
          id: qId,
          enrollmentId: enrollment.id,
          attemptNumber: drift.Value(attempt),
          response: false,
          result: 'extend',
          subjectProfileId: drift.Value(extendSubjectProfileId),
          submittedAt: now,
        ),
      );

  await syncService.enqueueUpsert(
    tableName: 'enrollments',
    recordId: enrollment.id,
    payload: {
      'id': enrollment.id,
      'target_completion_date': newTarget.toIso8601String().substring(0, 10),
    },
  );
  await syncService.enqueueUpsert(
    tableName: 'completion_questionnaires',
    recordId: qId,
    payload: {
      'id': qId,
      'enrollment_id': enrollment.id,
      'attempt_number': attempt,
      'response': false,
      'result': 'extend',
      'submitted_at': now.toIso8601String(),
      if (extendSubjectProfileId != null)
        'subject_profile_id': extendSubjectProfileId,
    },
  );
}

Future<EnrollmentsTableData?> _resumeInterruptedEnrollmentAfterMoro({
  required AppDatabase db,
  required SyncService syncService,
  required String enrollmentId,
  required DateTime now,
}) async {
  final interrupted = await (db.select(db.enrollmentsTable)
        ..where((t) => t.id.equals(enrollmentId))
        ..limit(1))
      .getSingleOrNull();
  if (interrupted == null) return null;

  final start = DateTime(now.year, now.month, now.day);
  final target = start.add(
    Duration(days: interrupted.assignedDurationWeeks * 7),
  );

  await (db.update(db.enrollmentsTable)
        ..where((t) => t.id.equals(interrupted.id)))
      .write(EnrollmentsTableCompanion(
    status: const drift.Value('active'),
    startDate: drift.Value(start),
    targetCompletionDate: drift.Value(target),
    pausedAt: const drift.Value(null),
    completedAt: const drift.Value(null),
    needsSync: const drift.Value(true),
    updatedAt: drift.Value(now),
  ));

  final progress = await (db.select(db.progressEntriesTable)
        ..where((t) => t.enrollmentId.equals(interrupted.id))
        ..limit(1))
      .getSingleOrNull();
  if (progress != null) {
    await _resetProgressToDay1(
      db: db,
      syncService: syncService,
      progress: progress,
      now: now,
    );
  }

  await syncService.enqueueUpsert(
    tableName: 'enrollments',
    recordId: interrupted.id,
    payload: {
      'id': interrupted.id,
      'status': 'active',
      'start_date': start.toIso8601String().substring(0, 10),
      'target_completion_date': target.toIso8601String().substring(0, 10),
      'paused_at': null,
      'completed_at': null,
    },
  );

  return interrupted;
}

Future<void> _resetProgressToDay1({
  required AppDatabase db,
  required SyncService syncService,
  required ProgressEntriesTableData progress,
  required DateTime now,
}) async {
  await (db.update(db.progressEntriesTable)
        ..where((t) => t.id.equals(progress.id)))
      .write(ProgressEntriesTableCompanion(
    currentDay: const drift.Value(1),
    lastActivityDate: const drift.Value(null),
    consecutiveInactiveDays: const drift.Value(0),
    dailyStreak: const drift.Value(0),
    weeklyStreak: const drift.Value(0),
    trainingsThisWeek: const drift.Value(0),
    lastTrainingWeekStart: const drift.Value(null),
    totalSessionsSinceDisclaimer: const drift.Value(0),
    needsSync: const drift.Value(true),
    updatedAt: drift.Value(now),
  ));

  await syncService.enqueueUpsert(
    tableName: 'progress_entries',
    recordId: progress.id,
    payload: {
      'id': progress.id,
      'user_id': progress.userId,
      'enrollment_id': progress.enrollmentId,
      'current_day': 1,
      'last_activity_date': null,
      'daily_streak': 0,
      'weekly_streak': 0,
      'trainings_this_week': 0,
      'total_sessions_since_disclaimer': 0,
    },
  );
}

Future<String> restartMoroFromCurrentPackage({
  required AppDatabase db,
  required SyncService syncService,
  required EnrollmentsTableData currentEnrollment,
}) async {
  if (currentEnrollment.packageId == 'moro') return currentEnrollment.id;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = today.add(const Duration(days: 28));
  final moroEnrollmentId = _uuid.v4();
  final progressId = _uuid.v4();
  final existingActiveMoro = await (db.select(db.enrollmentsTable)
        ..where((t) =>
            t.userId.equals(currentEnrollment.userId) &
            (currentEnrollment.subjectProfileId == null
                ? t.subjectProfileId.isNull()
                : t.subjectProfileId
                    .equals(currentEnrollment.subjectProfileId!)) &
            t.packageId.equals('moro') &
            t.status.equals('active')))
      .get();

  await db.transaction(() async {
    await (db.update(db.enrollmentsTable)
          ..where((t) =>
              t.userId.equals(currentEnrollment.userId) &
              (currentEnrollment.subjectProfileId == null
                  ? t.subjectProfileId.isNull()
                  : t.subjectProfileId
                      .equals(currentEnrollment.subjectProfileId!)) &
              t.packageId.equals('moro') &
              t.status.equals('active')))
        .write(EnrollmentsTableCompanion(
      status: const drift.Value('abandoned'),
      needsSync: const drift.Value(true),
      updatedAt: drift.Value(now),
    ));

    await (db.update(db.enrollmentsTable)
          ..where((t) => t.id.equals(currentEnrollment.id)))
        .write(EnrollmentsTableCompanion(
      status: const drift.Value('paused'),
      pausedAt: drift.Value(now),
      needsSync: const drift.Value(true),
      updatedAt: drift.Value(now),
    ));

    await db.into(db.enrollmentsTable).insert(
          EnrollmentsTableCompanion.insert(
            id: moroEnrollmentId,
            userId: currentEnrollment.userId,
            subjectProfileId: drift.Value(currentEnrollment.subjectProfileId),
            packageId: 'moro',
            assignedDurationWeeks: 4,
            startDate: today,
            targetCompletionDate: target,
            precedingEnrollmentId: drift.Value(currentEnrollment.id),
          ),
        );

    await db.into(db.progressEntriesTable).insert(
          ProgressEntriesTableCompanion.insert(
            id: progressId,
            userId: currentEnrollment.userId,
            subjectProfileId: drift.Value(currentEnrollment.subjectProfileId),
            enrollmentId: moroEnrollmentId,
          ),
        );
  });

  await syncService.enqueueUpsert(
    tableName: 'enrollments',
    recordId: currentEnrollment.id,
    payload: {
      'id': currentEnrollment.id,
      'status': 'paused',
      'paused_at': now.toIso8601String(),
    },
  );
  for (final oldMoro in existingActiveMoro) {
    await syncService.enqueueUpsert(
      tableName: 'enrollments',
      recordId: oldMoro.id,
      payload: {
        'id': oldMoro.id,
        'status': 'abandoned',
      },
    );
  }
  await syncService.enqueueUpsert(
    tableName: 'enrollments',
    recordId: moroEnrollmentId,
    payload: {
      'id': moroEnrollmentId,
      'user_id': currentEnrollment.userId,
      if (currentEnrollment.subjectProfileId != null)
        'subject_profile_id': currentEnrollment.subjectProfileId,
      'package_id': 'moro',
      'status': 'active',
      'assigned_duration_weeks': 4,
      'start_date': today.toIso8601String().substring(0, 10),
      'target_completion_date': target.toIso8601String().substring(0, 10),
      'preceding_enrollment_id': currentEnrollment.id,
    },
  );
  await syncService.enqueueUpsert(
    tableName: 'progress_entries',
    recordId: progressId,
    payload: {
      'id': progressId,
      'user_id': currentEnrollment.userId,
      if (currentEnrollment.subjectProfileId != null)
        'subject_profile_id': currentEnrollment.subjectProfileId,
      'enrollment_id': moroEnrollmentId,
      'current_day': 1,
    },
  );

  return moroEnrollmentId;
}

// ── Save a completed session and update progress ──────────────────────────────

Future<void> saveCompletedSession({
  required AppDatabase db,
  required SyncService? syncService,
  required EnrollmentsTableData enrollment,
  required ProgressEntriesTableData progress,
  required List<String> completedExerciseIds,
  String? userId,
  DateTime? now,
}) async {
  final resolvedUserId =
      userId ?? Supabase.instance.client.auth.currentUser?.id;
  if (resolvedUserId == null) return;

  final timestamp = now ?? DateTime.now();
  final today = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final sessionId = _uuid.v4();

  // Save session
  await db.into(db.trainingSessionsTable).insert(
        TrainingSessionsTableCompanion.insert(
          id: sessionId,
          userId: resolvedUserId,
          subjectProfileId: drift.Value(enrollment.subjectProfileId),
          enrollmentId: enrollment.id,
          sessionDate: today,
          dayNumber: progress.currentDay,
          completedExerciseIds: jsonEncode(completedExerciseIds),
          isCompleted: const drift.Value(true),
          completedAt: drift.Value(timestamp),
        ),
      );

  // Idempotency: skip if already recorded today
  final lastActivity = progress.lastActivityDate;
  final isToday = lastActivity != null &&
      lastActivity.year == today.year &&
      lastActivity.month == today.month &&
      lastActivity.day == today.day;
  if (isToday) return;

  await (db.update(db.progressEntriesTable)
        ..where((t) => t.id.equals(progress.id)))
      .write(ProgressEntriesTableCompanion(
    currentDay: drift.Value(progress.currentDay + 1),
    lastActivityDate: drift.Value(today),
    totalSessionsSinceDisclaimer:
        drift.Value(progress.totalSessionsSinceDisclaimer + 1),
    needsSync: const drift.Value(true),
    updatedAt: drift.Value(timestamp),
  ));

  await syncService?.enqueueUpsert(
    tableName: 'training_sessions',
    recordId: sessionId,
    payload: {
      'id': sessionId,
      'user_id': resolvedUserId,
      if (enrollment.subjectProfileId != null)
        'subject_profile_id': enrollment.subjectProfileId,
      'enrollment_id': enrollment.id,
      'session_date': today.toIso8601String().substring(0, 10),
      'day_number': progress.currentDay,
      'completed_exercise_ids': completedExerciseIds,
      'is_completed': true,
      'completed_at': timestamp.toIso8601String(),
    },
  );
  await syncService?.enqueueUpsert(
    tableName: 'progress_entries',
    recordId: progress.id,
    payload: {
      'id': progress.id,
      'user_id': resolvedUserId,
      if (progress.subjectProfileId != null)
        'subject_profile_id': progress.subjectProfileId,
      'enrollment_id': enrollment.id,
      'current_day': progress.currentDay + 1,
      'last_activity_date': today.toIso8601String().substring(0, 10),
    },
  );
}

Future<void> saveVorrundeRegulationSession({
  required AppDatabase db,
  required SyncService syncService,
  required EnrollmentsTableData enrollment,
  required ProgressEntriesTableData progress,
  required List<String> completedExerciseIds,
}) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sessionId = _uuid.v4();

  await db.into(db.trainingSessionsTable).insert(
        TrainingSessionsTableCompanion.insert(
          id: sessionId,
          userId: userId,
          subjectProfileId: drift.Value(enrollment.subjectProfileId),
          enrollmentId: enrollment.id,
          sessionDate: today,
          dayNumber: 0,
          completedExerciseIds: jsonEncode(completedExerciseIds),
          isCompleted: const drift.Value(true),
          completedAt: drift.Value(now),
        ),
      );

  final lastActivity = progress.lastActivityDate;
  final isToday = lastActivity != null &&
      lastActivity.year == today.year &&
      lastActivity.month == today.month &&
      lastActivity.day == today.day;
  if (!isToday) {
    await (db.update(db.progressEntriesTable)
          ..where((t) => t.id.equals(progress.id)))
        .write(ProgressEntriesTableCompanion(
      lastActivityDate: drift.Value(today),
      totalSessionsSinceDisclaimer:
          drift.Value(progress.totalSessionsSinceDisclaimer + 1),
      needsSync: const drift.Value(true),
      updatedAt: drift.Value(now),
    ));

    await syncService.enqueueUpsert(
      tableName: 'progress_entries',
      recordId: progress.id,
      payload: {
        'id': progress.id,
        'user_id': userId,
        if (progress.subjectProfileId != null)
          'subject_profile_id': progress.subjectProfileId,
        'enrollment_id': enrollment.id,
        'last_activity_date': today.toIso8601String().substring(0, 10),
      },
    );
  }

  await syncService.enqueueUpsert(
    tableName: 'training_sessions',
    recordId: sessionId,
    payload: {
      'id': sessionId,
      'user_id': userId,
      if (enrollment.subjectProfileId != null)
        'subject_profile_id': enrollment.subjectProfileId,
      'enrollment_id': enrollment.id,
      'session_date': today.toIso8601String().substring(0, 10),
      'day_number': 0,
      'completed_exercise_ids': completedExerciseIds,
      'is_completed': true,
      'completed_at': now.toIso8601String(),
    },
  );
}
