import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

import '../../features/progress/domain/models/user_preferences.dart';

class ReminderSettings {
  static const String dailyRemindersEnabledKey = 'daily_reminders_enabled';
  static const String primaryWindowStartHourKey = 'primary_window_start_hour';
  static const String primaryWindowStartMinuteKey =
      'primary_window_start_minute';
  static const String primaryWindowEndHourKey = 'primary_window_end_hour';
  static const String primaryWindowEndMinuteKey = 'primary_window_end_minute';
  static const String quietHoursStartHourKey = 'quiet_hours_start_hour';
  static const String quietHoursStartMinuteKey = 'quiet_hours_start_minute';
  static const String quietHoursEndHourKey = 'quiet_hours_end_hour';
  static const String quietHoursEndMinuteKey = 'quiet_hours_end_minute';
  static const String timezoneKey = 'user_timezone';

  static bool dailyRemindersEnabled(SharedPreferences prefs) {
    return prefs.getBool(dailyRemindersEnabledKey) ?? true;
  }

  static Future<void> setDailyRemindersEnabled(
    SharedPreferences prefs,
    bool value,
  ) {
    return prefs.setBool(dailyRemindersEnabledKey, value);
  }

  static UserPreferences loadUserPreferences(SharedPreferences prefs) {
    final startHour = prefs.getInt(primaryWindowStartHourKey) ?? 7;
    final startMinute = prefs.getInt(primaryWindowStartMinuteKey) ?? 0;
    final endHour = prefs.getInt(primaryWindowEndHourKey) ?? 9;
    final endMinute = prefs.getInt(primaryWindowEndMinuteKey) ?? 0;

    final quietStartHour = prefs.getInt(quietHoursStartHourKey) ?? 22;
    final quietStartMinute = prefs.getInt(quietHoursStartMinuteKey) ?? 0;
    final quietEndHour = prefs.getInt(quietHoursEndHourKey) ?? 6;
    final quietEndMinute = prefs.getInt(quietHoursEndMinuteKey) ?? 0;

    final timezone = prefs.getString(timezoneKey) ?? 'local';

    return UserPreferences(
      preferredWindows: [
        HabitWindow(
          start: TimeOfDay(hour: startHour, minute: startMinute),
          end: TimeOfDay(hour: endHour, minute: endMinute),
        ),
      ],
      quietHours: QuietHours(
        start: TimeOfDay(hour: quietStartHour, minute: quietStartMinute),
        end: TimeOfDay(hour: quietEndHour, minute: quietEndMinute),
      ),
      timezone: timezone,
      locationConsent: false,
      dailyReminderEnabled: dailyRemindersEnabled(prefs),
      midweekCheckinEnabled: false,
      locationNudgesEnabled: false,
      silentMode: false,
    );
  }
}
