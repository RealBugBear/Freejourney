// lib/features/training/presentation/apply_training_anchor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/settings_provider.dart';
import '../../../core/training/training_anchor_settings.dart';
import 'widgets/training_anchor_sheet.dart';

/// Stores the answer and switches reminders on (spec §4.6).
///
/// No notification code here: setting remindersEnabled and the window start
/// makes the existing reminder sync schedule both the training reminder and
/// the streak evening notice.
Future<void> applyTrainingAnchor(
  WidgetRef ref,
  TrainingAnchorResult result,
) async {
  final prefs = await SharedPreferences.getInstance();
  await TrainingAnchorSettings.setAnchor(prefs, result.anchor);
  await TrainingAnchorSettings.markAsked(prefs);

  final notifier = ref.read(settingsProvider.notifier);
  notifier.setReminderStart(
    TimeOfDay(hour: result.minutes ~/ 60, minute: result.minutes % 60),
  );
  notifier.setRemindersEnabled(true);
}
