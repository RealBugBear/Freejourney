import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/training/domain/session/session_orchestrator.dart';

/// Compact local crash-recovery checkpoint for one profile/package/version.
///
/// The checkpoint stores remaining monotonic timeline state, never a wall-clock
/// deadline. A restored session therefore cannot skip time spent while the app
/// was suspended.
class TrainingSessionCheckpointStore {
  const TrainingSessionCheckpointStore(this._prefs);

  static const int schemaVersion = 1;
  static const String _prefix = 'training.sessionCheckpoint';

  final SharedPreferences _prefs;

  String _key({
    required String profileId,
    required String packageId,
    required String contentVersion,
  }) {
    return [
      _prefix,
      Uri.encodeComponent(profileId),
      Uri.encodeComponent(packageId),
      Uri.encodeComponent(contentVersion),
    ].join('.');
  }

  Future<void> save({
    required String profileId,
    required TrainingSessionState state,
  }) async {
    if (state.stage == TrainingSessionStage.cancelled ||
        state.stage == TrainingSessionStage.failure) {
      await clear(
        profileId: profileId,
        packageId: state.packageId,
        contentVersion: state.contentVersion,
      );
      return;
    }
    final payload = <String, Object?>{
      'schemaVersion': schemaVersion,
      'state': state.toJson(),
    };
    final saved = await _prefs.setString(
      _key(
        profileId: profileId,
        packageId: state.packageId,
        contentVersion: state.contentVersion,
      ),
      jsonEncode(payload),
    );
    if (!saved) {
      try {
        await _prefs.reload();
      } on Object {
        // Preserve the explicit write failure below.
      }
      throw StateError('The training checkpoint could not be stored.');
    }
  }

  TrainingSessionState? load({
    required String profileId,
    required String packageId,
    required String contentVersion,
  }) {
    final raw = _prefs.getString(
      _key(
        profileId: profileId,
        packageId: packageId,
        contentVersion: contentVersion,
      ),
    );
    if (raw == null) return null;
    try {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      if (payload['schemaVersion'] != schemaVersion) return null;
      final state = TrainingSessionState.fromJson(
        payload['state'] as Map<String, dynamic>,
      );
      if (state.packageId != packageId ||
          state.contentVersion != contentVersion ||
          state.stage == TrainingSessionStage.cancelled ||
          state.stage == TrainingSessionStage.failure) {
        return null;
      }
      return state;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on StateError {
      return null;
    }
  }

  Future<void> clear({
    required String profileId,
    required String packageId,
    required String contentVersion,
  }) async {
    final removed = await _prefs.remove(
      _key(
        profileId: profileId,
        packageId: packageId,
        contentVersion: contentVersion,
      ),
    );
    if (!removed) {
      try {
        await _prefs.reload();
      } on Object {
        // Preserve the explicit removal failure below.
      }
      throw StateError('The training checkpoint could not be cleared.');
    }
  }
}

/// Serializes best-effort checkpoint writes without poisoning later writes.
///
/// Periodic snapshots may fail transiently (for example during a platform
/// preference write). The next snapshot must still run. The final completed
/// snapshot uses [saveRequired], which surfaces the current error and can be
/// retried independently.
class TrainingSessionCheckpointWriteQueue {
  TrainingSessionCheckpointWriteQueue({
    required Future<void> Function(TrainingSessionState state) save,
  }) : _save = save;

  final Future<void> Function(TrainingSessionState state) _save;
  Future<void> _tail = Future<void>.value();

  Object? lastBestEffortError;

  void enqueue(TrainingSessionState state) {
    final previous = _tail;
    _tail = _saveAfter(previous, state);
  }

  Future<void> flush() => _tail;

  Future<void> saveRequired(TrainingSessionState state) async {
    await _tail;
    await _save(state);
    lastBestEffortError = null;
  }

  Future<void> _saveAfter(
    Future<void> previous,
    TrainingSessionState state,
  ) async {
    await previous;
    try {
      await _save(state);
      lastBestEffortError = null;
    } on Object catch (error) {
      lastBestEffortError = error;
    }
  }
}
