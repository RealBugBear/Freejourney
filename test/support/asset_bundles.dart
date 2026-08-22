import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Serves real bundled assets from disk.
///
/// Widget tests must not reach the platform asset channel: it answers for the
/// first test in a process and then stops, which leaves any screen that awaits
/// an asset stuck on its loading state for every test after the first.
class DiskAssetBundle extends AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final file = File(key);
    if (!file.existsSync()) throw FlutterError('missing asset $key');
    return ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync()));
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final file = File(key);
    if (!file.existsSync()) throw FlutterError('missing asset $key');
    return file.readAsString();
  }
}

/// Never answers — reproduces an unresponsive asset channel.
class StalledAssetBundle extends AssetBundle {
  final _never = Completer<Never>();

  @override
  Future<ByteData> load(String key) => _never.future;

  @override
  Future<String> loadString(String key, {bool cache = true}) => _never.future;
}
