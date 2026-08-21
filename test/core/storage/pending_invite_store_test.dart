import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/core/storage/pending_invite_store.dart';

void main() {
  late Directory tempDir;
  late PendingInviteStore store;
  late DateTime now;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('pending_invite_');
    now = DateTime.utc(2026, 8, 21, 12);
    store = PendingInviteStore(
      supportDirectoryOverride: () => tempDir,
      clock: () => now,
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('saveCode persists and readValidCode returns it', () async {
    await store.saveCode('ab-cd ef12'); // invalid after normalize
    expect(await store.readValidCode(), isNull);

    await store.saveCode('abcdefgh');
    expect(await store.readValidCode(), 'ABCDEFGH');
  });

  test('code survives a new store instance (restart)', () async {
    await store.saveCode('ABCDEFGH');
    final again = PendingInviteStore(
      supportDirectoryOverride: () => tempDir,
      clock: () => now,
    );
    expect(await again.readValidCode(), 'ABCDEFGH');
  });

  test('expired code is cleared after 30 days', () async {
    await store.saveCode('ABCDEFGH');
    now = now.add(const Duration(days: 31));
    expect(await store.readValidCode(), isNull);
    final restarted = PendingInviteStore(
      supportDirectoryOverride: () => tempDir,
      clock: () => now,
    );
    expect(await restarted.readValidCode(), isNull);
  });

  test('clearCode removes pending invite', () async {
    await store.saveCode('ABCDEFGH');
    await store.clearCode();
    expect(await store.readValidCode(), isNull);
  });

  test('last activated count is per userId', () async {
    await store.saveLastActivatedCount(userId: 'user-a', count: 5);
    await store.saveLastActivatedCount(userId: 'user-b', count: 12);

    expect(await store.readLastActivatedCount('user-a'), 5);
    expect(await store.readLastActivatedCount('user-b'), 12);
    expect(await store.readLastActivatedCount('user-c'), isNull);
  });

  test('overlapping mutations do not drop code or per-user counts', () async {
    final futures = <Future<void>>[
      store.saveCode('ABCDEFGH'),
      store.saveLastActivatedCount(userId: 'user-a', count: 3),
      store.saveCode('XYZ23456'),
      store.saveLastActivatedCount(userId: 'user-b', count: 7),
      store.saveLastActivatedCount(userId: 'user-a', count: 4),
    ];
    await Future.wait(futures);

    expect(await store.readValidCode(), 'XYZ23456');
    expect(await store.readLastActivatedCount('user-a'), 4);
    expect(await store.readLastActivatedCount('user-b'), 7);
  });

  test('impulse: ignored then tapped second show is not permanent', () async {
    final t0 = now;
    await store.recordImpulseShown(userId: 'user-a', now: t0);
    var a = await store.readImpulseState('user-a');
    expect(a.lastShowUnanswered, isTrue);
    expect(a.ignoredShowCount, 0);
    expect(a.permanentlySilent, isFalse);

    a = await store.settleUnansweredImpulse('user-a');
    expect(a.ignoredShowCount, 1);
    expect(a.lastShowUnanswered, isFalse);

    await store.recordImpulseShown(
      userId: 'user-a',
      now: t0.add(const Duration(days: 31)),
    );
    a = await store.readImpulseState('user-a');
    expect(a.lastShowUnanswered, isTrue);
    expect(a.permanentlySilent, isFalse);

    await store.recordImpulseTapped(userId: 'user-a');
    a = await store.readImpulseState('user-a');
    expect(a.ignoredShowCount, 0);
    expect(a.lastShowUnanswered, isFalse);
    expect(a.permanentlySilent, isFalse);
  });

  test('impulse: two unanswered shows become permanent on next settle',
      () async {
    final t0 = now;
    await store.recordImpulseShown(userId: 'user-a', now: t0);
    await store.settleUnansweredImpulse('user-a');
    await store.recordImpulseShown(
      userId: 'user-a',
      now: t0.add(const Duration(days: 31)),
    );
    final afterSecondSettle = await store.settleUnansweredImpulse('user-a');
    expect(afterSecondSettle.ignoredShowCount, 2);
    expect(afterSecondSettle.permanentlySilent, isTrue);
  });

  test('impulse state is isolated per user', () async {
    await store.recordImpulseShown(userId: 'user-a', now: now);
    await store.settleUnansweredImpulse('user-a');
    await store.recordImpulseShown(userId: 'user-b', now: now);
    final b = await store.readImpulseState('user-b');
    expect(b.ignoredShowCount, 0);
    expect(b.lastShowUnanswered, isTrue);
    final a = await store.readImpulseState('user-a');
    expect(a.ignoredShowCount, 1);
  });
}
