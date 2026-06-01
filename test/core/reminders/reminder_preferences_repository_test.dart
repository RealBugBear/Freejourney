import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:corejourney/core/reminders/device_timezone_provider.dart';
import 'package:corejourney/core/reminders/reminder_preferences_repository.dart';
import 'package:corejourney/core/settings/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps local reminder window to server quiet hours', () async {
    SharedPreferences.setMockInitialValues({
      weeklyGoalPreferenceKey: 4,
    });
    final prefs = await SharedPreferences.getInstance();
    late Map<String, dynamic> payload;
    final repository = ReminderPreferencesRepository(
      supabase: SupabaseClient('https://example.supabase.co', 'anon-key'),
      prefs: prefs,
      timezoneProvider: DeviceTimezoneProvider(
        prefs: prefs,
        resolver: () async => 'Europe/Berlin',
      ),
      upsertOverride: (values) async {
        payload = values;
      },
    );

    await repository.upsertPreference(
      userId: 'user-1',
      timezone: 'Europe/Berlin',
      settings: const AppSettings(
        remindersEnabled: true,
        reminderStartMinutes: 8 * 60,
        reminderEndMinutes: 20 * 60,
        weeklyGoal: 4,
      ),
    );

    expect(payload['quiet_start'], '20:00:00');
    expect(payload['quiet_end'], '08:00:00');
    expect(payload['enabled'], true);
  });

  test('does not write server_reminders_enabled', () async {
    SharedPreferences.setMockInitialValues({
      weeklyGoalPreferenceKey: 5,
    });
    final prefs = await SharedPreferences.getInstance();
    late Map<String, dynamic> payload;
    final repository = ReminderPreferencesRepository(
      supabase: SupabaseClient('https://example.supabase.co', 'anon-key'),
      prefs: prefs,
      timezoneProvider: DeviceTimezoneProvider(
        prefs: prefs,
        resolver: () async => 'Europe/Berlin',
      ),
      upsertOverride: (values) async {
        payload = values;
      },
    );

    await repository.upsertPreference(
      userId: 'user-1',
      timezone: 'Europe/Berlin',
      settings: const AppSettings(remindersEnabled: true),
    );

    expect(payload.containsKey('server_reminders_enabled'), false);
  });

  test('weekly goal source is default when user has not saved weekly goal',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    late Map<String, dynamic> payload;
    final repository = ReminderPreferencesRepository(
      supabase: SupabaseClient('https://example.supabase.co', 'anon-key'),
      prefs: prefs,
      timezoneProvider: DeviceTimezoneProvider(
        prefs: prefs,
        resolver: () async => 'Europe/Berlin',
      ),
      upsertOverride: (values) async {
        payload = values;
      },
    );

    await repository.upsertPreference(
      userId: 'user-1',
      timezone: 'Europe/Berlin',
      settings: const AppSettings(weeklyGoal: 5),
    );

    expect(payload['weekly_goal'], isNull);
    expect(payload['weekly_goal_source'], 'default');
  });
}
