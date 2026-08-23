// lib/core/training/training_anchor_settings.dart
import 'package:shared_preferences/shared_preferences.dart';

import 'training_anchor.dart';

/// Stores the chosen training anchor and whether the question was already put.
///
/// Shaped after [RoutineTipSettings] and reading the same session counter, so
/// both one-time prompts key off one number.
class TrainingAnchorSettings {
  static const _keyAnchor = 'training_anchor';
  static const _keyAsked = 'training_anchor_asked';

  /// Written by RoutineTipSettings.incrementSessionCount after each completed
  /// session. Vorrunde units do not increment it, so they do not trigger the
  /// question either.
  static const _keySessionCount = 'completed_session_count';

  static TrainingAnchor? anchor(SharedPreferences prefs) =>
      anchorFromName(prefs.getString(_keyAnchor));

  static bool wasAsked(SharedPreferences prefs) =>
      prefs.getBool(_keyAsked) ?? false;

  static Future<void> setAnchor(
    SharedPreferences prefs,
    TrainingAnchor anchor,
  ) =>
      prefs.setString(_keyAnchor, anchor.name);

  static Future<void> markAsked(SharedPreferences prefs) =>
      prefs.setBool(_keyAsked, true);

  /// Exactly one session, not "at least one": the question belongs to the
  /// moment right after the first training. Someone who is already past that
  /// is not asked retroactively.
  static bool shouldAsk(SharedPreferences prefs) =>
      !wasAsked(prefs) && (prefs.getInt(_keySessionCount) ?? 0) == 1;
}
