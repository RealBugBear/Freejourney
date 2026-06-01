import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../logging/app_logger.dart';
import '../settings/settings_provider.dart';
import 'device_timezone_provider.dart';

const weeklyGoalPreferenceKey = 'settings.weeklyGoal';

typedef ReminderPreferenceUpsert = Future<void> Function(
  Map<String, dynamic> values,
);

class ReminderPreferencesRepository {
  ReminderPreferencesRepository({
    required SupabaseClient supabase,
    required SharedPreferences prefs,
    required DeviceTimezoneProvider timezoneProvider,
    ReminderPreferenceUpsert? upsertOverride,
  })  : _supabase = supabase,
        _prefs = prefs,
        _timezoneProvider = timezoneProvider,
        _upsertOverride = upsertOverride;

  final SupabaseClient _supabase;
  final SharedPreferences _prefs;
  final DeviceTimezoneProvider _timezoneProvider;
  final ReminderPreferenceUpsert? _upsertOverride;

  Future<void> syncFromSettings(AppSettings settings) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final timezone = await _timezoneProvider.currentTimezone();
      await upsertPreference(
        userId: user.id,
        settings: settings,
        timezone: timezone,
      );
      await _timezoneProvider.markSyncedIfChanged(timezone);
      appLogger.i('Reminder preferences synced');
    } catch (error, stackTrace) {
      appLogger.w(
        'Reminder preference sync failed: $error',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> refreshTimezoneIfChanged(AppSettings settings) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final timezone = await _timezoneProvider.currentTimezone();
      if (_timezoneProvider.lastSyncedTimezone == timezone) return;
      await upsertPreference(
        userId: user.id,
        settings: settings,
        timezone: timezone,
      );
      await _timezoneProvider.markSyncedIfChanged(timezone);
      appLogger.i('Reminder timezone changed and synced: $timezone');
    } catch (error, stackTrace) {
      appLogger.w(
        'Reminder timezone refresh failed: $error',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> upsertPreference({
    required String userId,
    required AppSettings settings,
    required String timezone,
  }) async {
    final weeklyGoalWasExplicitlySet = _prefs.containsKey(
      weeklyGoalPreferenceKey,
    );
    final values = <String, dynamic>{
      'user_id': userId,
      'enabled': settings.remindersEnabled,
      'timezone': timezone,
      'quiet_start': _formatMinutes(settings.reminderEndMinutes),
      'quiet_end': _formatMinutes(settings.reminderStartMinutes),
      'weekly_goal': weeklyGoalWasExplicitlySet ? settings.weeklyGoal : null,
      'weekly_goal_source':
          weeklyGoalWasExplicitlySet ? 'user_setting' : 'default',
    };

    final override = _upsertOverride;
    if (override != null) {
      await override(values);
      return;
    }

    await _supabase.from('user_reminder_preferences').upsert(
          values,
          onConflict: 'user_id',
        );
  }

  Future<bool> serverRemindersEnabled() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final row = await _supabase
          .from('user_reminder_preferences')
          .select('server_reminders_enabled')
          .eq('user_id', user.id)
          .maybeSingle();
      return row?['server_reminders_enabled'] == true;
    } catch (error, stackTrace) {
      appLogger.w(
        'Server reminder cohort lookup failed: $error',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  String _formatMinutes(int minutes) {
    final normalized = ((minutes % (24 * 60)) + (24 * 60)) % (24 * 60);
    final hour = normalized ~/ 60;
    final minute = normalized % 60;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:00';
  }
}
