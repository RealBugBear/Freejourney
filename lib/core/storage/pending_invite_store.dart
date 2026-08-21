import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../features/invite/domain/models/invite_overview.dart';
import '../../features/invite/domain/models/invite_impulse_store_state.dart';
import '../../features/invite/domain/invite_prompt_policy.dart';

/// File-based pending-invite + per-user tree UI state (not SharedPreferences).
///
/// Pending invite codes are device-global (pre-auth). Last-seen tree counts are
/// keyed by [userId] so a later account cannot inherit another user's stand.
///
/// Disk mutations are serialized through an internal Future queue so overlapping
/// unawaited calls cannot clobber each other via read–modify–write races.
///
/// Pass [memoryOnly]: true in widget tests to avoid dart:io and the async
/// queue under FakeAsync.
class PendingInviteStore {
  PendingInviteStore({
    Directory Function()? supportDirectoryOverride,
    DateTime Function()? clock,
    this.memoryOnly = false,
  })  : _supportDirectoryOverride = supportDirectoryOverride,
        _clock = clock ?? DateTime.now;

  static const codeFileName = 'pending_invite_code.json';
  static const treeFileName = 'invite_tree_counts.json';
  static const codeTtl = Duration(days: 30);

  final Directory Function()? _supportDirectoryOverride;
  final DateTime Function() _clock;

  /// When true, all state lives in memory (no disk I/O, no async queue).
  final bool memoryOnly;

  Map<String, dynamic> _memoryCode = {};
  Map<String, dynamic> _memoryTree = {};

  Future<void> _queue = Future<void>.value();

  Future<T> _enqueue<T>(Future<T> Function() action) {
    if (memoryOnly) {
      // No serialization queue under FakeAsync — memory ops are already
      // single-threaded and complete without dart:io.
      return action();
    }
    final done = _queue.then((_) => action());
    _queue = done.then<void>((_) {}, onError: (_) {});
    return done;
  }

  Future<Directory> _dir() async {
    if (_supportDirectoryOverride != null) {
      return _supportDirectoryOverride();
    }
    return getApplicationSupportDirectory();
  }

  Future<File> _codeFile() async =>
      File('${(await _dir()).path}/$codeFileName');

  Future<File> _treeFile() async =>
      File('${(await _dir()).path}/$treeFileName');

  Future<Map<String, dynamic>> _readJson({required bool code}) async {
    if (memoryOnly) {
      return Map<String, dynamic>.from(code ? _memoryCode : _memoryTree);
    }
    try {
      final file = code ? await _codeFile() : await _treeFile();
      if (!await file.exists()) return {};
      final raw = await file.readAsString();
      if (raw.isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      return {};
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeJson({
    required bool code,
    required Map<String, dynamic> map,
  }) async {
    if (memoryOnly) {
      if (code) {
        _memoryCode = Map<String, dynamic>.from(map);
      } else {
        _memoryTree = Map<String, dynamic>.from(map);
      }
      return;
    }
    try {
      final file = code ? await _codeFile() : await _treeFile();
      await file.writeAsString(jsonEncode(map), flush: true);
    } catch (_) {}
  }

  static String normalizeCode(String raw) =>
      raw.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

  /// Persists a normalized invite code with a 30-day TTL (device-global).
  Future<void> saveCode(String rawCode) => _enqueue(() async {
        final code = normalizeCode(rawCode);
        if (!InviteOverview.codePattern.hasMatch(code)) return;
        final map = await _readJson(code: true);
        map['code'] = code;
        map['saved_at'] = _clock().toUtc().toIso8601String();
        await _writeJson(code: true, map: map);
      });

  /// Returns a still-valid pending code, or `null` if missing/expired/invalid.
  Future<String?> readValidCode() => _enqueue(() async {
        final map = await _readJson(code: true);
        final code = map['code'];
        final savedAtRaw = map['saved_at'];
        if (code is! String || !InviteOverview.codePattern.hasMatch(code)) {
          return null;
        }
        if (savedAtRaw is! String) {
          await _clearCodeUnlocked();
          return null;
        }
        final savedAt = DateTime.tryParse(savedAtRaw);
        if (savedAt == null) {
          await _clearCodeUnlocked();
          return null;
        }
        final age = _clock().toUtc().difference(savedAt.toUtc());
        if (age > codeTtl || age.isNegative) {
          await _clearCodeUnlocked();
          return null;
        }
        return code;
      });

  Future<void> clearCode() => _enqueue(_clearCodeUnlocked);

  Future<void> _clearCodeUnlocked() async {
    final map = await _readJson(code: true);
    map.remove('code');
    map.remove('saved_at');
    await _writeJson(code: true, map: map);
  }

  /// Persists the last-seen activation count for [userId] only.
  Future<void> saveLastActivatedCount({
    required String userId,
    required int count,
  }) =>
      _enqueue(() async {
        if (userId.isEmpty || count < 0) return;
        final map = await _readJson(code: false);
        final byUser = _byUserMap(map);
        byUser[userId] = count;
        map['by_user'] = byUser;
        map.remove('last_activated_count');
        await _writeJson(code: false, map: map);
      });

  /// Last-seen count for [userId], or `null` if this account has none yet.
  Future<int?> readLastActivatedCount(String userId) => _enqueue(() async {
        if (userId.isEmpty) return null;
        final map = await _readJson(code: false);
        final byUser = _byUserMap(map);
        final value = byUser[userId];
        return switch (value) {
          final int n when n >= 0 => n,
          final num n when n >= 0 && n % 1 == 0 => n.toInt(),
          _ => null,
        };
      });

  Future<InviteImpulseStoreState> readImpulseState(String userId) =>
      _enqueue(() async {
        if (userId.isEmpty) return const InviteImpulseStoreState();
        return _readImpulseUnlocked(userId, await _readJson(code: false));
      });

  /// Settles a previous unanswered show into the ignore streak, then returns
  /// the state used for the current decision.
  Future<InviteImpulseStoreState> settleUnansweredImpulse(String userId) =>
      _enqueue(() async {
        if (userId.isEmpty) return const InviteImpulseStoreState();
        final map = await _readJson(code: false);
        final previous = _readImpulseUnlocked(userId, map);
        final settled = InviteImpulseStoreState.fromPersist(
          invitePromptStateAfterSettleUnanswered(previous.toPersist()),
        );
        if (settled.lastShowUnanswered != previous.lastShowUnanswered ||
            settled.ignoredShowCount != previous.ignoredShowCount ||
            settled.permanentlySilent != previous.permanentlySilent) {
          final impulses = _impulseByUserMap(map);
          impulses[userId] = settled.toJson();
          map['impulse_by_user'] = impulses;
          await _writeJson(code: false, map: map);
        }
        return settled;
      });

  Future<void> recordImpulseShown({
    required String userId,
    required DateTime now,
  }) =>
      _enqueue(() async {
        if (userId.isEmpty) return;
        final map = await _readJson(code: false);
        final previous = _readImpulseUnlocked(userId, map);
        final next = InviteImpulseStoreState.fromPersist(
          invitePromptStateAfterShow(now: now, previous: previous.toPersist()),
        );
        final impulses = _impulseByUserMap(map);
        impulses[userId] = next.toJson();
        map['impulse_by_user'] = impulses;
        await _writeJson(code: false, map: map);
      });

  Future<void> recordImpulseTapped({required String userId}) =>
      _enqueue(() async {
        if (userId.isEmpty) return;
        final map = await _readJson(code: false);
        final previous = _readImpulseUnlocked(userId, map);
        final next = InviteImpulseStoreState.fromPersist(
          invitePromptStateAfterTap(previous.toPersist()),
        );
        final impulses = _impulseByUserMap(map);
        impulses[userId] = next.toJson();
        map['impulse_by_user'] = impulses;
        await _writeJson(code: false, map: map);
      });

  InviteImpulseStoreState _readImpulseUnlocked(
    String userId,
    Map<String, dynamic> map,
  ) {
    final impulses = _impulseByUserMap(map);
    final raw = impulses[userId];
    if (raw is Map<String, dynamic>) {
      return InviteImpulseStoreState.fromJson(raw);
    }
    if (raw is Map) {
      return InviteImpulseStoreState.fromJson(Map<String, dynamic>.from(raw));
    }
    return const InviteImpulseStoreState();
  }

  Map<String, dynamic> _byUserMap(Map<String, dynamic> root) {
    final raw = root['by_user'];
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }

  Map<String, dynamic> _impulseByUserMap(Map<String, dynamic> root) {
    final raw = root['impulse_by_user'];
    if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return {};
  }
}

/// Process-wide store used by deep-link handling and invite UI.
/// Tests may replace this with a temp-directory or memory-only instance.
PendingInviteStore pendingInviteStore = PendingInviteStore();
