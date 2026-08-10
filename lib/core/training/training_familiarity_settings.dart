import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Profile-, package- and content-version-scoped learning progression.
class TrainingFamiliaritySettings {
  const TrainingFamiliaritySettings._();

  static const String _prefix = 'training.familiarity';

  static String _key({
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

  static int completedSessions(
    SharedPreferences prefs, {
    required String profileId,
    required String packageId,
    required String contentVersion,
  }) {
    final key = _key(
      profileId: profileId,
      packageId: packageId,
      contentVersion: contentVersion,
    );
    final ledger = _readLedger(prefs, key);
    return ledger?.count ?? prefs.getInt(key) ?? 0;
  }

  static Future<int> recordCompletion(
    SharedPreferences prefs, {
    required String profileId,
    required String packageId,
    required String contentVersion,
    String? sessionId,
  }) async {
    final key = _key(
      profileId: profileId,
      packageId: packageId,
      contentVersion: contentVersion,
    );
    final existing = _readLedger(prefs, key);
    final previousCount = existing?.count ?? prefs.getInt(key) ?? 0;
    final sessionIds = [...?existing?.sessionIds];
    if (sessionId != null && sessionIds.contains(sessionId)) {
      return previousCount;
    }
    if (sessionId != null) {
      sessionIds.add(sessionId);
      if (sessionIds.length > 64) {
        sessionIds.removeRange(0, sessionIds.length - 64);
      }
    }
    final next = previousCount + 1;
    final saved = await prefs.setString(
      '$key.ledger',
      jsonEncode({
        'count': next,
        'sessionIds': sessionIds,
      }),
    );
    if (!saved) {
      try {
        await prefs.reload();
      } on Object {
        // Preserve the explicit write failure below.
      }
      throw StateError('The training familiarity ledger could not be stored.');
    }
    return next;
  }

  static bool shouldRecommendRoutine(int completedSessions) =>
      completedSessions >= 2;

  static bool shouldShowFullLearningGuidance(int completedSessions) =>
      completedSessions == 0;

  static bool shouldShowCompactLearningGuidance(int completedSessions) =>
      completedSessions == 1;

  static _FamiliarityLedger? _readLedger(
    SharedPreferences prefs,
    String key,
  ) {
    final raw = prefs.getString('$key.ledger');
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return _FamiliarityLedger(
        count: decoded['count'] as int,
        sessionIds: (decoded['sessionIds'] as List<dynamic>).cast<String>(),
      );
    } on Object {
      return null;
    }
  }
}

class _FamiliarityLedger {
  const _FamiliarityLedger({
    required this.count,
    required this.sessionIds,
  });

  final int count;
  final List<String> sessionIds;
}
