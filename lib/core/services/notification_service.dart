import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../features/progress/domain/models/user_preferences.dart';

class ReminderDiagnostics {
  final int totalPending;
  final List<int> pendingIds;
  final bool hasDailyReminder;

  const ReminderDiagnostics({
    required this.totalPending,
    required this.pendingIds,
    required this.hasDailyReminder,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const int dailyReminderId = 1000;

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.UTC);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        // Handle notification tap
      },
    );
  }

  Future<bool> requestPermissions() async {
    final iosGranted = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
        true;

    final androidGranted = await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        true;

    return iosGranted && androidGranted;
  }

  Future<void> scheduleDailyReminder(DateTime lastTrainingTime) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduledLocal = computeNextDailyReminderDateForTesting(
      now: now,
      reminderTime: TimeOfDay(
        hour: lastTrainingTime.hour,
        minute: lastTrainingTime.minute,
      ),
    );
    final scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledLocal.year,
      scheduledLocal.month,
      scheduledLocal.day,
      scheduledLocal.hour,
      scheduledLocal.minute,
    );

    // Keep this legacy entrypoint single-shot and aligned with the current
    // one-reminder model.
    await flutterLocalNotificationsPlugin.cancel(dailyReminderId);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      dailyReminderId,
      'Zeit für deine Einheit',
      'Nimm dir Zeit für deine heutige Reflexintegrations-Einheit.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Tägliche Erinnerung',
          channelDescription: 'Erinnerung an die tägliche Einheit',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleReminderWindow({
    required DateTime date,
    required HabitWindow window,
    QuietHours? quietHours,
    int baseId = 100,
    String? message,
  }) async {
    final quiet = quietHours ??
        const QuietHours(
          start: TimeOfDay(hour: 22, minute: 0),
          end: TimeOfDay(hour: 6, minute: 0),
        );

    if (!_isWithinQuietHours(window, quiet)) {
      final scheduledDate = tz.TZDateTime(
        tz.local,
        date.year,
        date.month,
        date.day,
        window.start.hour,
        window.start.minute,
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        baseId,
        'Zeit für deine Einheit',
        message ?? 'Dein bevorzugtes Einheitsfenster hat begonnen.',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder_window',
            'Einheitsfenster',
            channelDescription: 'Erinnerungen innerhalb des Wunschzeitraums',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> scheduleDailyRepeatingWindow({
    required HabitWindow window,
    required QuietHours quietHours,
    required DateTime firstDate,
    String? message,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var start = tz.TZDateTime(
      tz.local,
      firstDate.year,
      firstDate.month,
      firstDate.day,
      window.start.hour,
      window.start.minute,
    );

    if (_isWithinQuietHours(window, quietHours)) {
      return;
    }

    // Session 9: schedule only the next reminder (not an endless daily repeat)
    // so reminders can be re-evaluated from current behavior and avoid spam.
    if (!start.isAfter(now)) {
      start = start.add(const Duration(days: 1));
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      dailyReminderId,
      'Zeit für deine Einheit',
      message ?? 'Dein bevorzugtes Einheitsfenster hat begonnen.',
      start,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder_window',
          'Einheitsfenster',
          channelDescription: 'Erinnerungen innerhalb des Wunschzeitraums',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint(
      '[NotificationService] Scheduled daily reminder '
      'id=$dailyReminderId at ${window.start.hour.toString().padLeft(2, '0')}:'
      '${window.start.minute.toString().padLeft(2, '0')} '
      'for=${start.toIso8601String()}',
    );
  }

  Future<void> scheduleWeeklyTouchpoints({
    required DateTime weekStart,
    required UserPreferences preferences,
  }) async {
    if (preferences.silentMode) return;

    final kickoff = tz.TZDateTime(
      tz.local,
      weekStart.year,
      weekStart.month,
      weekStart.day,
      7,
      30,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      200,
      'Starte deine Woche',
      'Plane deine Einheiten für diese Woche in einem ruhigen Rhythmus.',
      kickoff,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_kickoff',
          'Wöchentlicher Start',
          channelDescription: 'Montagmorgens die Woche planen',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    if (preferences.midweekCheckinEnabled) {
      final midweek = kickoff.add(const Duration(days: 2));
      await flutterLocalNotificationsPlugin.zonedSchedule(
        201,
        'Wo stehst du diese Woche?',
        'Mittwochs-Check-in: Was braucht es, um 5/7 zu schaffen?',
        midweek,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_midweek',
            'Wochenmitte',
            channelDescription: 'Motivations-Check-in am Mittwoch',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    final closeout = kickoff.add(const Duration(days: 6, hours: 11));
    await flutterLocalNotificationsPlugin.zonedSchedule(
      202,
      'Wochenausklang',
      'Schließe die Woche ab und bereite die nächste vor.',
      closeout,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_closeout',
          'Wochenausklang',
          channelDescription: 'Sonntags-Zusammenfassung und Ausblick',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> scheduleMakeUpPlan(DateTime date) async {
    final scheduledDate = tz.TZDateTime(
      tz.local,
      date.year,
      date.month,
      date.day,
      20,
      0,
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      300,
      'Noch ist Zeit für heute',
      'Eine kurze 15-Minuten-Einheit bewahrt deinen 5/7-Puffer.',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_makeup',
          'Aufhol-Erinnerung',
          channelDescription: 'Ermutigung für eine Recovery-Session',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminderWindow(int baseId) async {
    await flutterLocalNotificationsPlugin.cancel(baseId);
    await flutterLocalNotificationsPlugin.cancel(baseId + 1);
  }

  Future<void> cancelDailyRepeatingReminders() async {
    await flutterLocalNotificationsPlugin.cancel(dailyReminderId);
    debugPrint(
      '[NotificationService] Canceled daily reminder id $dailyReminderId',
    );
  }

  bool _isWithinQuietHours(HabitWindow window, QuietHours quietHours) {
    final windowRanges = _splitIntoDailyRanges(
      _toMinuteOfDay(window.start),
      _toMinuteOfDay(window.end),
    );
    final quietRanges = _splitIntoDailyRanges(
      _toMinuteOfDay(quietHours.start),
      _toMinuteOfDay(quietHours.end),
    );

    for (final w in windowRanges) {
      for (final q in quietRanges) {
        if (_rangesOverlap(w.$1, w.$2, q.$1, q.$2)) {
          return true;
        }
      }
    }
    return false;
  }

  int _toMinuteOfDay(TimeOfDay t) => t.hour * 60 + t.minute;

  List<(int, int)> _splitIntoDailyRanges(int startMinute, int endMinute) {
    if (startMinute == endMinute) {
      return const [(0, 24 * 60)];
    }
    if (startMinute < endMinute) {
      return [(startMinute, endMinute)];
    }
    return [
      (startMinute, 24 * 60),
      (0, endMinute),
    ];
  }

  bool _rangesOverlap(int aStart, int aEnd, int bStart, int bEnd) {
    return aStart < bEnd && bStart < aEnd;
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  @visibleForTesting
  bool isWithinQuietHoursForTesting(
    HabitWindow window,
    QuietHours quietHours,
  ) {
    return _isWithinQuietHours(window, quietHours);
  }

  Future<bool> hasScheduledDailyReminder() async {
    final pending =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    return pending.any((request) => request.id == dailyReminderId);
  }

  Future<ReminderDiagnostics> getReminderDiagnostics() async {
    final pending =
        await flutterLocalNotificationsPlugin.pendingNotificationRequests();
    final ids = pending.map((request) => request.id).toList()..sort();
    final hasDaily = ids.contains(dailyReminderId);
    return ReminderDiagnostics(
      totalPending: ids.length,
      pendingIds: ids,
      hasDailyReminder: hasDaily,
    );
  }

  @visibleForTesting
  DateTime computeNextDailyReminderDateForTesting({
    required DateTime now,
    required TimeOfDay reminderTime,
  }) {
    final localNow = now.toLocal();
    var scheduled = DateTime(
      localNow.year,
      localNow.month,
      localNow.day,
      reminderTime.hour,
      reminderTime.minute,
    ).add(const Duration(days: 1));

    if (!scheduled.isAfter(localNow)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
