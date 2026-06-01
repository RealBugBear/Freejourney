import 'package:flutter/material.dart';

class HabitWindow {
  final TimeOfDay start;
  final TimeOfDay end;
  final String? locationLabel;

  const HabitWindow({
    required this.start,
    required this.end,
    this.locationLabel,
  });
}

class QuietHours {
  final TimeOfDay start;
  final TimeOfDay end;

  const QuietHours({
    required this.start,
    required this.end,
  });
}

class UserPreferences {
  final List<HabitWindow> preferredWindows;
  final QuietHours quietHours;
  final String timezone;
  final bool locationConsent;
  final bool dailyReminderEnabled;
  final bool midweekCheckinEnabled;
  final bool locationNudgesEnabled;
  final bool silentMode;

  const UserPreferences({
    required this.preferredWindows,
    required this.quietHours,
    required this.timezone,
    required this.locationConsent,
    required this.dailyReminderEnabled,
    required this.midweekCheckinEnabled,
    required this.locationNudgesEnabled,
    required this.silentMode,
  });
}
