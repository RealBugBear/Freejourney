import 'dart:convert';

import 'package:corejourney/core/database/app_database.dart';
import 'package:corejourney/core/sync/sync_backend.dart';
import 'package:corejourney/core/sync/sync_service.dart';
import 'package:corejourney/core/time/app_clock.dart';
import 'package:corejourney/features/journal/data/repositories/journal_repository.dart';
import 'package:corejourney/features/mood/data/repositories/mood_repository.dart';
import 'package:corejourney/features/progress/presentation/providers/progress_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _OfflineBackend implements SyncBackend {
  @override
  String? get userId => 'synthetic-owner';
  @override
  Future<void> upsert(String table, Map<String, dynamic> payload) =>
      throw StateError('This test must never reach the network');
  @override
  Future<void> delete(String table, String id) =>
      throw StateError('This test must never reach the network');
  @override
  Future<List<Map<String, dynamic>>> fetch(String table, String userId,
          {List<String>? enrollmentIds}) =>
      throw StateError('This test must never reach the network');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late SyncService sync;
  late AppClock clock;
  late MoodRepository mood;

  setUpAll(() async {
    // Supabase also initializes PKCE storage even with EmptyLocalStorage.
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://offline-writer-test.invalid',
      anonKey: 'synthetic-test-key',
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: false,
        detectSessionInUri: false,
        localStorage: EmptyLocalStorage(),
      ),
    );
    // In-memory synthetic session only; no auth HTTP request or actual user data.
    await Supabase.instance.client.auth.setInitialSession(jsonEncode({
      'access_token': 'synthetic-local-token',
      'token_type': 'bearer',
      'user': {
        'id': 'synthetic-owner',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': '2026-09-06T00:00:00Z',
      },
    }));
  });
  tearDownAll(() => Supabase.instance.dispose());

  setUp(() {
    db = AppDatabase.inMemory();
    sync = SyncService(db,
        backend: _OfflineBackend(), isConnected: () async => false);
    clock = AppClock();
    mood = MoodRepository(db, sync, clock);
  });
  tearDown(() async {
    await sync.drain();
    sync.stop();
    clock.dispose();
    await db.close();
  });

  Future<void> failOutbox(String table) => db.customStatement('''
    CREATE TRIGGER fail_selected_outbox BEFORE INSERT ON sync_jobs
    WHEN NEW.table_name = '$table'
    BEGIN SELECT RAISE(ABORT, 'synthetic outbox disk failure'); END
  ''');

  Future<String> enroll({String? subject}) => createEnrollment(
        db: db,
        syncService: sync,
        userId: 'synthetic-owner',
        subjectProfileId: subject,
        packageId: 'moro',
        durationWeeks: 8,
      );

  Future<void> clearJobs() => db.delete(db.syncJobsTable).go();

  test('second enrollment outbox failure leaves no enrollment, progress or job',
      () async {
    await failOutbox('progress_entries');
    await expectLater(enroll(), throwsA(isA<Exception>()));
    expect(await db.select(db.enrollmentsTable).get(), isEmpty);
    expect(await db.select(db.progressEntriesTable).get(), isEmpty);
    expect(await db.select(db.syncJobsTable).get(), isEmpty);
  });

  test('concurrent enrollment creates one record and one pair of sync intents',
      () async {
    final ids = await Future.wait(List.generate(12, (_) => enroll()));
    expect(ids.toSet(), hasLength(1));
    expect(await db.select(db.enrollmentsTable).get(), hasLength(1));
    expect(await db.select(db.progressEntriesTable).get(), hasLength(1));
    expect(await db.select(db.syncJobsTable).get(), hasLength(2));
  });

  test('enrollment idempotency preserves distinct child subjects', () async {
    final ids = await Future.wait([enroll(), enroll(subject: 'synthetic-child')]);
    expect(ids.toSet(), hasLength(2));
    expect(await db.select(db.progressEntriesTable).get(), hasLength(2));
  });

  test('completion queue failure restores active enrollment and questionnaire',
      () async {
    await enroll();
    final entry = await db.select(db.enrollmentsTable).getSingle();
    await clearJobs();
    await failOutbox('completion_questionnaires');
    await expectLater(
        completeEnrollment(db: db, syncService: sync, enrollment: entry),
        throwsA(isA<Exception>()));
    expect((await db.select(db.enrollmentsTable).getSingle()).status, 'active');
    expect(await db.select(db.completionQuestionnairesTable).get(), isEmpty);
    expect(await db.select(db.syncJobsTable).get(), isEmpty);
  });

  test('extension queue failure preserves target date and attempt history',
      () async {
    await enroll();
    final entry = await db.select(db.enrollmentsTable).getSingle();
    await clearJobs();
    await failOutbox('completion_questionnaires');
    await expectLater(
        extendEnrollment(db: db, syncService: sync, enrollment: entry),
        throwsA(isA<Exception>()));
    expect((await db.select(db.enrollmentsTable).getSingle()).targetCompletionDate,
        entry.targetCompletionDate);
    expect(await db.select(db.completionQuestionnairesTable).get(), isEmpty);
    expect(await db.select(db.syncJobsTable).get(), isEmpty);
  });

  test('session queue failure rolls back activity advance and session', () async {
    await enroll();
    final entry = await db.select(db.enrollmentsTable).getSingle();
    final progress = await db.select(db.progressEntriesTable).getSingle();
    await clearJobs();
    await failOutbox('progress_entries');
    await expectLater(
      saveCompletedSession(
        db: db, syncService: sync, enrollment: entry, progress: progress,
        completedExerciseIds: ['moro_ex1'], userId: 'synthetic-owner',
      ),
      throwsA(isA<Exception>()),
    );
    expect(await db.select(db.trainingSessionsTable).get(), isEmpty);
    expect((await db.select(db.progressEntriesTable).getSingle()).currentDay, 1);
    expect(await db.select(db.syncJobsTable).get(), isEmpty);
  });

  test('same-day retry cannot leave an extra local session without sync intent',
      () async {
    await enroll();
    final entry = await db.select(db.enrollmentsTable).getSingle();
    await clearJobs();
    final today = DateTime(2026, 9, 6, 10);
    for (var i = 0; i < 2; i++) {
      await saveCompletedSession(
        db: db, syncService: sync, enrollment: entry,
        progress: await db.select(db.progressEntriesTable).getSingle(),
        completedExerciseIds: ['moro_ex1'], userId: 'synthetic-owner', now: today,
      );
    }
    expect(await db.select(db.trainingSessionsTable).get(), hasLength(1));
    final jobs = await db.select(db.syncJobsTable).get();
    expect(jobs.where((j) => j.tableName_ == 'training_sessions'), hasLength(1));
    expect((await db.select(db.progressEntriesTable).getSingle()).currentDay, 2);
  });

  test('concurrent session submission ignores stale caller progress', () async {
    await enroll();
    final entry = await db.select(db.enrollmentsTable).getSingle();
    final progress = await db.select(db.progressEntriesTable).getSingle();
    await clearJobs();
    await Future.wait(List.generate(6, (_) => saveCompletedSession(
      db: db, syncService: sync, enrollment: entry, progress: progress,
      completedExerciseIds: ['moro_ex1'], userId: 'synthetic-owner',
      now: DateTime(2026, 9, 6, 10),
    )));
    expect(await db.select(db.trainingSessionsTable).get(), hasLength(1));
    expect(await db.select(db.syncJobsTable).get(), hasLength(2));
  });

  test('mood creation second queue failure rolls back note and checkin', () async {
    await failOutbox('journal_entries');
    await expectLater(mood.createCheckin(enrollmentId: 'synthetic-enrollment',
        source: 'manual', note: 'synthetic note', mood: 3),
        throwsA(isA<Exception>()));
    expect(await db.select(db.moodCheckinsTable).get(), isEmpty);
    expect(await db.select(db.journalEntriesTable).get(), isEmpty);
    expect(await db.select(db.syncJobsTable).get(), isEmpty);
  });

  test('mood update failure restores both original note copies', () async {
    final id = await mood.createCheckin(enrollmentId: 'synthetic-enrollment',
        source: 'manual', note: 'original synthetic note', mood: 3);
    await clearJobs();
    await failOutbox('journal_entries');
    await expectLater(mood.updateCheckin(id: id, note: 'changed synthetic note', mood: 5),
        throwsA(isA<Exception>()));
    expect((await db.select(db.moodCheckinsTable).getSingle()).note, 'original synthetic note');
    expect((await db.select(db.journalEntriesTable).getSingle()).content, 'original synthetic note');
    expect(await db.select(db.syncJobsTable).get(), isEmpty);
  });

  test('mood deletion failure restores note, checkin and earlier queued deletion',
      () async {
    final id = await mood.createCheckin(enrollmentId: 'synthetic-enrollment',
        source: 'manual', note: 'synthetic note', mood: 3);
    await clearJobs();
    await failOutbox('mood_checkins');
    await expectLater(mood.deleteCheckin(id: id), throwsA(isA<Exception>()));
    expect(await db.select(db.moodCheckinsTable).get(), hasLength(1));
    expect(await db.select(db.journalEntriesTable).get(), hasLength(1));
    expect(await db.select(db.syncJobsTable).get(), isEmpty);
  });

  test('journal deletion failure restores cleared linked note and journal',
      () async {
    await mood.createCheckin(enrollmentId: 'synthetic-enrollment',
        source: 'manual', note: 'synthetic note', mood: 3);
    final entry = await db.select(db.journalEntriesTable).getSingle();
    await clearJobs();
    await failOutbox('journal_entries');
    await expectLater(JournalRepository(db, sync).deleteEntry(entry.id),
        throwsA(isA<Exception>()));
    expect((await db.select(db.moodCheckinsTable).getSingle()).note, 'synthetic note');
    expect(await db.select(db.journalEntriesTable).get(), hasLength(1));
    expect(await db.select(db.syncJobsTable).get(), isEmpty);
  });
}
