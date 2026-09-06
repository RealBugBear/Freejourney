import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/backup_exclusion.dart';
import '../logging/app_logger.dart';

/// Serialized, atomic session persistence in the backup-excluded local store.
/// The file relies on OS app isolation/device encryption; it is not a keychain.
class FileLocalStorage extends LocalStorage {
  FileLocalStorage({
    Future<Directory> Function()? supportDirectory,
    Future<bool> Function(String)? excludeFromBackup,
  })  : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
        _excludeFromBackup =
            excludeFromBackup ?? BackupExclusion().excludeFromBackup;

  static const _fileName = 'supabase_session.bin';
  final Future<Directory> Function() _supportDirectory;
  final Future<bool> Function(String) _excludeFromBackup;
  Future<void> _pending = Future.value();

  Future<T> _serialize<T>(Future<T> Function() action) {
    final next = _pending.then((_) => action());
    // Keep subsequent operations usable even if a previous disk operation failed.
    _pending = next.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return next;
  }

  Future<File> _file() async {
    final support = await _supportDirectory();
    final store = Directory('${support.path}/local_store');
    await store.create(recursive: true);
    if (!await _excludeFromBackup(store.path)) {
      throw const FileSystemException('Session backup exclusion unavailable');
    }
    final current = File('${store.path}/$_fileName');
    final legacy = File('${support.path}/$_fileName');
    if (await legacy.exists()) {
      if (!await current.exists()) {
        await legacy.rename(current.path);
      } else {
        // A completed newer write wins over a leftover pre-migration file.
        await legacy.delete();
      }
    }
    return current;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => (await accessToken()) != null;

  @override
  Future<String?> accessToken() => _serialize(() async {
        try {
          final file = await _file();
          if (!await file.exists()) return null;
          final value = await file.readAsString();
          return value.isEmpty ? null : value;
        } on FileSystemException {
          appLogger.w('Session cache unavailable');
          return null;
        }
      });

  @override
  Future<void> persistSession(String persistSessionString) =>
      _serialize(() async {
        final file = await _file();
        final temporary = File('${file.path}.tmp');
        // Never truncate the last good session before the replacement is durable.
        await temporary.writeAsString(persistSessionString, flush: true);
        await temporary.rename(file.path);
      });

  @override
  Future<void> removePersistedSession() => _serialize(() async {
        // Erasure must remain possible even when the backup-exclusion channel fails.
        final support = await _supportDirectory();
        for (final path in [
          '${support.path}/$_fileName',
          '${support.path}/local_store/$_fileName',
          '${support.path}/local_store/$_fileName.tmp',
        ]) {
          final file = File(path);
          if (await file.exists()) await file.delete();
        }
      });
}
