import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../core/database/app_database.dart';
import '../core/notifications/notification_service.dart';
import '../core/push/push_notification_service.dart';
import '../core/reminders/device_timezone_provider.dart';
import '../core/reminders/reminder_preferences_repository.dart';
import '../core/settings/settings_provider.dart';
import '../core/sync/exercises_sync_service.dart';
import '../core/sync/sync_service.dart';
import '../core/sync/sync_status.dart';
import 'bootstrap.dart';

// These are overridden in main with real values from Bootstrap
final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('appConfigProvider must be overridden');
});

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider must be overridden');
});

final syncServiceProvider = Provider<SyncService>((ref) {
  throw UnimplementedError('syncServiceProvider must be overridden');
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncServiceProvider).statusStream;
});

/// Emits true while rehydrate() is running, false when it is done.
/// DashboardScreen listens to this to gate the onboarding redirect:
/// a returning user must not be sent to intake assessment before
/// their Supabase data has loaded into the local DB.
final rehydrationProvider = StreamProvider<bool>((ref) {
  return ref.watch(syncServiceProvider).rehydrationStream;
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService.instance;
});

final pushNotificationServiceProvider =
    Provider<PushNotificationService>((ref) {
  return PushNotificationService.instance;
});

final pushNotificationOpenProvider = StreamProvider<Map<String, String>>((ref) {
  return ref.watch(pushNotificationServiceProvider).openedPayloads;
});

final deviceTimezoneProvider = Provider<DeviceTimezoneProvider>((ref) {
  return DeviceTimezoneProvider(prefs: ref.watch(sharedPreferencesProvider));
});

final reminderPreferencesRepositoryProvider =
    Provider<ReminderPreferencesRepository>((ref) {
  return ReminderPreferencesRepository(
    supabase: Supabase.instance.client,
    prefs: ref.watch(sharedPreferencesProvider),
    timezoneProvider: ref.watch(deviceTimezoneProvider),
  );
});

final localNotificationTapProvider = StreamProvider<String>((ref) {
  return ref.watch(notificationServiceProvider).notificationTaps;
});

/// Lazily-constructed exercises sync service.
/// Automatically syncs exercises from Supabase when first accessed.
final exercisesSyncServiceProvider = Provider<ExercisesSyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return ExercisesSyncService(db);
});

List<Override> bootstrapOverrides(Bootstrap bootstrap) => [
      appConfigProvider.overrideWithValue(bootstrap.config),
      databaseProvider.overrideWithValue(bootstrap.database),
      syncServiceProvider.overrideWithValue(bootstrap.syncService),
      sharedPreferencesProvider.overrideWithValue(bootstrap.prefs),
    ];
