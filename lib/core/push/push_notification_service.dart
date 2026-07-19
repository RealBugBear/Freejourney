import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../config/launch_flags.dart';
import '../../firebase_options.dart';
import '../l10n/active_localizations.dart';
import '../logging/app_logger.dart';
import '../notifications/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Background delivery must never crash app startup.
  }
}

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();

  FirebaseMessaging? _messaging;
  final _openedPayloadController =
      StreamController<Map<String, String>>.broadcast();
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initialized = false;
  bool _registrationInFlight = false;
  String? _lastRegisteredUserId;
  String? _lastPermissionDeniedUserId;

  Stream<Map<String, String>> get openedPayloads =>
      _openedPayloadController.stream;

  Future<void> initialize({required AppEnvironment environment}) async {
    if (kIsWeb) return;
    if (_initialized) return;

    try {
      FirebaseMessaging.onBackgroundMessage(
        firebaseMessagingBackgroundHandler,
      );
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatformFor(environment),
      );
      _messaging = FirebaseMessaging.instance;

      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _messaging!.onTokenRefresh.listen((token) {
        unawaited(_upsertToken(token, environment: environment));
      });

      FirebaseMessaging.onMessage.listen((message) {
        appLogger.i(
          'Foreground push received: '
          '${message.notification?.title ?? message.data['type'] ?? 'unknown'}',
        );
        unawaited(_showForegroundNotification(message));
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        appLogger.i('Push opened app: ${message.data}');
        _openedPayloadController.add(_stringData(message.data));
      });

      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        appLogger.i('Push launched app: ${initialMessage.data}');
        _openedPayloadController.add(_stringData(initialMessage.data));
      }

      _initialized = true;
      appLogger.i('Push notification service initialized');
    } catch (e, st) {
      appLogger.w(
        'Push notification init skipped: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<void> registerDeviceToken({
    required AppEnvironment environment,
  }) async {
    if (kIsWeb) return;
    final messaging = _messaging;
    if (messaging == null) {
      appLogger.i('Push registration skipped: Firebase Messaging not ready');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (_registrationInFlight) return;
    if (user != null && _lastRegisteredUserId == user.id) return;
    if (user != null && _lastPermissionDeniedUserId == user.id) return;

    _registrationInFlight = true;

    try {
      if (Platform.isAndroid) {
        final androidStatus = await Permission.notification.request();
        appLogger.i('Android notification permission: $androidStatus');
      }

      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      appLogger.i(
        'Push permission status: ${settings.authorizationStatus.name}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _lastPermissionDeniedUserId = user?.id;
        appLogger.i('Push permission denied');
        return;
      }

      if (user == null) {
        appLogger
            .i('Push permission checked, token registration waits for login');
        return;
      }

      final token = await _getFcmToken(messaging);
      if (token == null || token.isEmpty) {
        appLogger.w('FCM token unavailable');
        return;
      }

      await _upsertToken(token, environment: environment);
      _lastRegisteredUserId = user.id;
      _lastPermissionDeniedUserId = null;
      appLogger.i('Push token registered for ${environment.name}');
    } catch (e, st) {
      appLogger.w(
        'Push token registration failed: $e',
        error: e,
        stackTrace: st,
      );
    } finally {
      _registrationInFlight = false;
    }
  }

  Future<String?> _getFcmToken(FirebaseMessaging messaging) async {
    if (Platform.isIOS || Platform.isMacOS) {
      final apnsToken = await _waitForApnsToken(messaging);
      if (apnsToken == null || apnsToken.isEmpty) {
        appLogger.w('APNs token unavailable; FCM token deferred');
        return null;
      }
    }
    return messaging.getToken();
  }

  Future<String?> _waitForApnsToken(FirebaseMessaging messaging) async {
    for (var attempt = 0; attempt < 5; attempt += 1) {
      final token = await messaging.getAPNSToken();
      if (token != null && token.isNotEmpty) return token;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  Future<void> _upsertToken(
    String token, {
    required AppEnvironment environment,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final packageInfo = await PackageInfo.fromPlatform();
    await Supabase.instance.client.rpc(
      'upsert_push_token',
      params: {
        'p_token': token,
        'p_platform': _platform,
        'p_environment': environment.name,
        'p_app_version': '${packageInfo.version}+${packageInfo.buildNumber}',
      },
    );
  }

  String get _platform {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    return 'unknown';
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final data = _stringData(message.data);
    final type = data['type'] ?? 'push';
    // T06 (D2=A): Call-Pushes still ignorieren, solange Video-Calls aus sind.
    if (!kVideoCallsEnabled &&
        (type == 'video_call' || type == 'call_request')) {
      appLogger.i('Call push suppressed: kVideoCallsEnabled is false');
      return;
    }
    // Data-only pushes carry no display copy; fall back to localized
    // defaults in the active app language (no BuildContext here).
    final l10n = await lookupActiveAppLocalizations();
    final title = message.notification?.title ??
        switch (type) {
          'video_call' => l10n.pushVideoCallTitle,
          'call_request' => l10n.pushCallRequestTitle,
          'appointment_proposal' => l10n.pushAppointmentProposalTitle,
          'appointment_confirmed' => l10n.pushAppointmentConfirmedTitle,
          'training_reminder' => l10n.pushTrainingReminderTitle,
          _ => 'Reflex Journey',
        };
    final body = message.notification?.body ??
        switch (type) {
          'video_call' => l10n.pushVideoCallBody,
          'call_request' => l10n.pushCallRequestBody,
          'appointment_proposal' => l10n.pushAppointmentProposalBody,
          'appointment_confirmed' => l10n.pushAppointmentConfirmedBody,
          'training_reminder' => l10n.pushTrainingReminderBody,
          _ => '',
        };

    await NotificationService.instance.showInstantNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      payload: jsonEncode(data),
    );
  }

  Map<String, String> _stringData(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }
}
