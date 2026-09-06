import 'dart:async';
import 'dart:io';
import 'package:corejourney/core/storage/file_local_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late FileLocalStorage storage;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('reflex-session-test-');
    storage = FileLocalStorage(
        supportDirectory: () async => directory,
        excludeFromBackup: (_) async => true);
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test('migrates legacy session without copying it into device backups',
      () async {
    final legacy = File('${directory.path}/supabase_session.bin');
    await legacy.writeAsString('synthetic-session');
    expect(await storage.accessToken(), 'synthetic-session');
    expect(await legacy.exists(), isFalse);
    expect(
        await File('${directory.path}/local_store/supabase_session.bin')
            .exists(),
        isTrue);
  });
  test('new session wins if legacy file also exists', () async {
    await storage.persistSession('new');
    await File('${directory.path}/supabase_session.bin').writeAsString('old');
    expect(await storage.accessToken(), 'new');
    expect(
        await File('${directory.path}/supabase_session.bin').exists(), isFalse);
  });
  test('logout waits for in-flight writes and cannot resurrect the session',
      () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    storage = FileLocalStorage(
        supportDirectory: () async => directory,
        excludeFromBackup: (_) async {
          if (!entered.isCompleted) entered.complete();
          await release.future;
          return true;
        });
    final writing = storage.persistSession('synthetic');
    await entered.future;
    final removing = storage.removePersistedSession();
    release.complete();
    await Future.wait([writing, removing]);
    expect(await storage.hasAccessToken(), isFalse);
  });
  test('atomic replacement and logout remove interrupted temporary files',
      () async {
    await storage.persistSession('first');
    await storage.persistSession('second');
    expect(await storage.accessToken(), 'second');
    await File('${directory.path}/local_store/supabase_session.bin.tmp')
        .writeAsString('partial');
    await storage.removePersistedSession();
    expect(
        await directory.list(recursive: true).where((e) => e is File).toList(),
        isEmpty);
  });
  test('failed backup exclusion rejects persistence but erasure remains usable',
      () async {
    await storage.persistSession('old');
    storage = FileLocalStorage(
        supportDirectory: () async => directory,
        excludeFromBackup: (_) async => false);
    await expectLater(
        storage.persistSession('new'), throwsA(isA<FileSystemException>()));
    await storage.removePersistedSession();
    expect(
        await File('${directory.path}/local_store/supabase_session.bin')
            .exists(),
        isFalse);
  });
}
