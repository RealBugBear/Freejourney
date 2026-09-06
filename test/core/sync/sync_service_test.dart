import 'dart:async';
import 'dart:convert';

import 'package:corejourney/core/database/app_database.dart';
import 'package:corejourney/core/sync/sync_backend.dart';
import 'package:corejourney/core/sync/sync_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Backend implements SyncBackend {
  @override
  String? userId = 'owner';
  final rows = <String, List<Map<String, dynamic>>>{};
  final writes = <Map<String, dynamic>>[];
  final deletes = <String>[];
  Future<void> Function()? onWrite;
  Future<void> Function()? onFetch;
  Object? failure;

  @override
  Future<void> upsert(String table, Map<String, dynamic> payload) async {
    writes.add(Map.of(payload));
    await onWrite?.call();
    if (failure != null) throw failure!;
  }

  @override
  Future<void> delete(String table, String id) async {
    deletes.add(id);
  }

  @override
  Future<List<Map<String, dynamic>>> fetch(String table, String userId,
      {List<String>? enrollmentIds}) async {
    await onFetch?.call();
    return rows[table] ?? [];
  }
}

Map<String, dynamic> _journal(String id) => {
      'id': id,
      'user_id': 'owner',
      'enrollment_id': null,
      'subject_profile_id': 'child',
      'content': 'synthetic note',
      'day_key': 20000,
      'created_at': '2026-09-05T10:00:00Z',
      'updated_at': '2026-09-05T10:00:00Z',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late _Backend backend;
  late SyncService service;

  setUp(() {
    db = AppDatabase.inMemory();
    backend = _Backend();
    service = SyncService(db, backend: backend, isConnected: () async => true);
  });
  tearDown(() async {
    service.stop();
    await db.close();
  });

  Future<void> job(String id, Map<String, dynamic> payload,
      {String table = 'journal_entries', String action = 'upsert'}) async {
    await db
        .into(db.syncJobsTable)
        .insertOnConflictUpdate(SyncJobsTableCompanion.insert(
          id: id,
          action: action,
          tableName_: table,
          recordId: payload['id'] as String,
          payload: jsonEncode(payload),
        ));
  }

  test('simultaneous drains reserve one worker before connectivity returns',
      () async {
    service.stop();
    final online = Completer<bool>();
    service =
        SyncService(db, backend: backend, isConnected: () => online.future);
    await job('one', {'id': 'row', 'user_id': 'owner'});
    final drains = List.generate(20, (_) => service.drain());
    online.complete(true);
    await Future.wait(drains);
    expect(backend.writes, hasLength(1));
    expect(await db.select(db.syncJobsTable).get(), isEmpty);
  });

  test('ordered partial writes do not lose fields by last-job coalescing',
      () async {
    await job('one', {'id': 'row', 'user_id': 'owner', 'content': 'first'});
    await job('two', {'id': 'row', 'user_id': 'owner', 'mood': 4});
    await service.drain();
    expect(backend.writes.map((p) => p.keys), [
      ['id', 'user_id', 'content'],
      ['id', 'user_id', 'mood'],
    ]);
  });

  test('a changed stable-ID job is not acknowledged by an older response',
      () async {
    await job('stable', {'id': 'row', 'user_id': 'owner', 'content': 'old'});
    backend.onWrite = () async {
      await job('stable', {'id': 'row', 'user_id': 'owner', 'content': 'new'});
    };
    await service.drain();
    final pending = await db.select(db.syncJobsTable).get();
    expect(pending, hasLength(1));
    expect(jsonDecode(pending.single.payload)['content'], 'new');
  });

  test(
      'FK conflict retains offline record and intent, later writes cannot overtake',
      () async {
    await db
        .into(db.journalEntriesTable)
        .insert(JournalEntriesTableCompanion.insert(
          id: 'row',
          userId: 'owner',
          content: 'only offline copy',
          dayKey: 20000,
        ));
    await job('one',
        {'id': 'row', 'user_id': 'owner', 'content': 'only offline copy'});
    await job('two', {'id': 'row', 'user_id': 'owner', 'mood': 4});
    backend.failure = const PostgrestException(
        message: 'progress_entries_enrollment_id_fkey', code: '23503');
    await service.drain();
    expect(backend.writes, hasLength(1));
    expect(await db.select(db.journalEntriesTable).get(), hasLength(1));
    expect(await db.select(db.syncJobsTable).get(), hasLength(2));
  });

  test('acknowledgement clears needsSync only after all record writes succeed',
      () async {
    await db
        .into(db.journalEntriesTable)
        .insert(JournalEntriesTableCompanion.insert(
          id: 'row',
          userId: 'owner',
          content: 'note',
          dayKey: 20000,
        ));
    await job('one', {'id': 'row', 'user_id': 'owner', 'content': 'note'});
    await service.drain();
    expect((await db.select(db.journalEntriesTable).getSingle()).needsSync,
        isFalse);
  });

  test(
      'restore includes standalone journal without an enrollment and retains child scope',
      () async {
    backend.rows['journal_entries'] = [_journal('row')];
    await service.rehydrate('owner');
    await service.drain();
    final row = await db.select(db.journalEntriesTable).getSingle();
    expect(row.subjectProfileId, 'child');
    expect(row.needsSync, isFalse);
  });

  test('pending delete prevents stale remote journal resurrection', () async {
    backend.rows['journal_entries'] = [_journal('row')];
    await job('delete', {'id': 'row'}, action: 'delete');
    await service.rehydrate('owner');
    await service.drain();
    expect(await db.select(db.journalEntriesTable).get(), isEmpty);
  });

  test('late restore response cannot repopulate account data after logout',
      () async {
    final started = Completer<void>();
    final release = Completer<void>();
    backend.rows['journal_entries'] = [_journal('row')];
    backend.onFetch = () async {
      if (!started.isCompleted) started.complete();
      await release.future;
    };
    final restoring = service.rehydrate('owner');
    await started.future;
    await service.clearUserDataForSignOut(discardPendingChanges: true);
    backend.userId = null;
    release.complete();
    await restoring;
    expect(await db.select(db.journalEntriesTable).get(), isEmpty);
    expect(service.isRehydrating, isFalse);
  });

  test(
      'logout removes all user tables including streak credits but preserves content',
      () async {
    await db
        .into(db.streakCreditsTable)
        .insert(StreakCreditsTableCompanion.insert(
          id: 'ledger',
          userId: 'owner',
          subjectProfileId: 'child',
          available: const Value(2),
        ));
    await job('one', {'id': 'row', 'user_id': 'owner'});
    await service.clearUserDataForSignOut(discardPendingChanges: true);
    for (final table
        in db.allTables.where((t) => t.actualTableName != 'exercises')) {
      final count = await db
          .customSelect(
              'SELECT COUNT(*) AS count FROM "${table.actualTableName}"')
          .getSingle();
      expect(count.read<int>('count'), 0, reason: table.actualTableName);
    }
  });

  test('stale account jobs never transmit under another account', () async {
    await job('one', {'id': 'row', 'user_id': 'other'});
    await service.drain();
    expect(backend.writes, isEmpty);
    expect(await db.select(db.syncJobsTable).get(), hasLength(1));
  });
}
