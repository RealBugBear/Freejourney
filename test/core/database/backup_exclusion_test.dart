import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/core/database/backup_exclusion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('corejourney/backup_exclusion');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('short-circuits true on non-iOS platforms without a channel call',
      () async {
    var channelCalled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      channelCalled = true;
      return true;
    });

    final exclusion = BackupExclusion(isIOS: false);
    expect(await exclusion.excludeFromBackup('/tmp/db'), isTrue);
    expect(channelCalled, isFalse);
  });

  test('passes the path over the channel on iOS and returns its result',
      () async {
    Object? receivedPath;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'excludeFromBackup');
      receivedPath = (call.arguments as Map)['path'];
      return true;
    });

    final exclusion = BackupExclusion(isIOS: true);
    expect(await exclusion.excludeFromBackup('/data/local_store'), isTrue);
    expect(receivedPath, '/data/local_store');
  });

  test('returns false instead of throwing when the channel fails', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'exclusion_failed');
    });

    final exclusion = BackupExclusion(isIOS: true);
    expect(await exclusion.excludeFromBackup('/data/local_store'), isFalse);
  });
}
