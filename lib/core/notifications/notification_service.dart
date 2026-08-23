import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/active_localizations.dart';
import '../logging/app_logger.dart';

// Stable notification ID for the daily training reminder.
const _kReminderId = 1;

const _kAndroidChannelId = 'training_reminders';

/// Notification ids reserved for the evening streak notice — one per planned
/// day. Ids 1 (daily reminder) and 500–899 (trainer alerts) are taken.
const int kStreakNoticeFirstId = 900;
const int kStreakNoticeDays = 7;

/// The fire times for the coming [kStreakNoticeDays] days.
///
/// A scheduled notification cannot check anything when it fires, so the slots
/// are planned ahead and cancelled again once the day is trained (spec §5).
List<DateTime> streakNoticeFireTimes({
  required DateTime from,
  required int endMinutes,
  required bool trainedToday,
}) {
  final hour = endMinutes ~/ 60;
  final minute = endMinutes % 60;
  final times = <DateTime>[];

  for (var offset = 0; offset < kStreakNoticeDays; offset++) {
    final day = DateTime(from.year, from.month, from.day + offset);
    final fireTime = DateTime(day.year, day.month, day.day, hour, minute);
    if (offset == 0 && (trainedToday || !fireTime.isAfter(from))) continue;
    times.add(fireTime);
  }
  return times;
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _tapController = StreamController<String>.broadcast();
  bool _enabled = true;
  bool _initialized = false;

  bool get isEnabled => _enabled;
  Stream<String> get notificationTaps => _tapController.stream;

  void disable(String reason) {
    if (!_enabled) return;
    _enabled = false;
    _initialized = false;
    appLogger.w('NotificationService disabled: $reason');
  }

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (!_enabled) return;
    if (_initialized) return;

    tz.initializeTimeZones();
    // Android build compatibility: avoid depending on flutter_timezone here.
    // Daily reminders still work, but are scheduled relative to UTC until a
    // newer timezone integration is added back.
    tz.setLocalLocation(tz.UTC);

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // we request explicitly on first enable
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _tapController.add(payload);
        }
      },
    );

    _initialized = true;
    appLogger.d('NotificationService initialized');
  }

  // ── Permission ──────────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    if (!_enabled) return false;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  // ── Schedule ────────────────────────────────────────────────────────────────

  /// Schedule (or reschedule) a daily training reminder at [startMinutes]
  /// (hour*60 + minute). Cancels any existing reminder first.
  ///
  /// Pass [fromTomorrow: true] when calling after a completed session so
  /// today's reminder is skipped.
  Future<void> scheduleReminder({
    required int startMinutes,
    required String title,
    required String body,
    bool fromTomorrow = false,
  }) async {
    if (!_enabled) return;
    await cancelReminder();

    final startHour = startMinutes ~/ 60;
    final startMin = startMinutes % 60;

    final now = tz.TZDateTime.now(tz.local);
    var fireTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      startHour,
      startMin,
    );

    // If the time has already passed today (or caller wants to skip today),
    // schedule for tomorrow.
    if (fromTomorrow || fireTime.isBefore(now)) {
      fireTime = fireTime.add(const Duration(days: 1));
    }

    final androidDetails = AndroidNotificationDetails(
      _kAndroidChannelId,
      await _channelName(),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      _kReminderId,
      title,
      body,
      fireTime,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    appLogger.d(
      'Reminder scheduled: ${fireTime.hour.toString().padLeft(2, '0')}:'
      '${fireTime.minute.toString().padLeft(2, '0')} daily',
    );
  }

  /// Cancel the daily training reminder (e.g. when user disables reminders or
  /// has already trained today).
  Future<void> cancelReminder() async {
    if (!_enabled) return;
    await _plugin.cancel(_kReminderId);
  }

  /// Show an immediate (non-scheduled) notification. Used for trainer alerts.
  /// IDs 500–899 are reserved for trainer notifications.
  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_enabled || !_initialized) return;
    final androidDetails = AndroidNotificationDetails(
      _kAndroidChannelId,
      await _channelName(),
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// The Android channel name is user-visible in system settings; resolve
  /// it from the active app language (channel names update on re-creation).
  Future<String> _channelName() async =>
      (await lookupActiveAppLocalizations()).notificationChannelTrainingReminders;

  /// Called after a successful training session. Cancels today's pending
  /// reminder and reschedules from tomorrow.
  Future<void> suppressTodayAndReschedule({
    required int startMinutes,
    required String title,
    required String body,
  }) async {
    if (!_enabled || !_initialized) return;
    await scheduleReminder(
      startMinutes: startMinutes,
      title: title,
      body: body,
      fromTomorrow: true,
    );
    appLogger.d('Reminder suppressed for today, rescheduled from tomorrow');
  }

  /// Cancels every planned streak notice.
  Future<void> cancelStreakNotices() async {
    if (!_enabled) return;
    for (var offset = 0; offset < kStreakNoticeDays; offset++) {
      await _plugin.cancel(kStreakNoticeFirstId + offset);
    }
  }

  /// Plans one-off evening notices for the coming week (spec §5).
  ///
  /// One-off on purpose: a repeating notification cannot be suppressed for a
  /// single day, and the notice must disappear the moment the day is trained.
  Future<void> scheduleStreakNotices({
    required int endMinutes,
    required String title,
    required String Function(int credits) bodyWithCredits,
    required String bodyWithoutCredits,
    required int credits,
    required bool trainedToday,
  }) async {
    if (!_enabled || !_initialized) return;
    await cancelStreakNotices();

    final body = credits > 0 ? bodyWithCredits(credits) : bodyWithoutCredits;
    final androidDetails = AndroidNotificationDetails(
      _kAndroidChannelId,
      await _channelName(),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = tz.TZDateTime.now(tz.local);
    final fireTimes = streakNoticeFireTimes(
      from: DateTime(now.year, now.month, now.day, now.hour, now.minute),
      endMinutes: endMinutes,
      trainedToday: trainedToday,
    );

    for (var i = 0; i < fireTimes.length; i++) {
      final fireTime = fireTimes[i];
      await _plugin.zonedSchedule(
        kStreakNoticeFirstId + i,
        title,
        body,
        tz.TZDateTime(tz.local, fireTime.year, fireTime.month, fireTime.day,
            fireTime.hour, fireTime.minute),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    appLogger.d('Streak notices scheduled: ${fireTimes.length}');
  }
}
