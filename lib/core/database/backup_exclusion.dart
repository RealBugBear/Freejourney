import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Flags a file or directory as excluded from device backups.
///
/// The local Drift database holds health-adjacent data (including children's
/// data) and must never leave the device inside an iCloud/Finder backup.
///
/// iOS: sets `NSURLIsExcludedFromBackupKey` via a platform channel
/// (see `registerBackupExclusionChannel` in `ios/Runner/AppDelegate.swift`).
/// Android: backups are disabled app-wide via `android:allowBackup="false"`
/// in the manifest, so no per-file flag is needed there.
class BackupExclusion {
  BackupExclusion({
    MethodChannel channel =
        const MethodChannel('corejourney/backup_exclusion'),
    bool? isIOS,
  })  : _channel = channel,
        _isIOS = isIOS ?? Platform.isIOS;

  final MethodChannel _channel;
  final bool _isIOS;

  /// Best-effort: returns true when the platform needs no flag or the flag
  /// was set. Never throws — a failure to set the exclusion flag must not
  /// prevent the database from opening.
  Future<bool> excludeFromBackup(String path) async {
    if (!_isIOS) return true;
    try {
      final ok = await _channel
          .invokeMethod<bool>('excludeFromBackup', {'path': path});
      return ok ?? false;
    } catch (e) {
      debugPrint('BackupExclusion: could not set exclusion flag: $e');
      return false;
    }
  }
}
