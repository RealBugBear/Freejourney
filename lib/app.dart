import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'bootstrap/providers.dart';
import 'core/navigation/app_router.dart';
import 'core/logging/app_logger.dart';
import 'core/settings/settings_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/trainer/domain/services/calendar_service.dart';
import 'features/trainer/presentation/providers/trainer_provider.dart';
import 'features/video/presentation/providers/video_providers.dart';
import 'features/video/presentation/widgets/incoming_call_listener.dart';
import 'l10n/app_localizations.dart';

/// Root widget. Handles app lifecycle events (sync drain on background) and
/// delegates actual UI construction to [_CoreJourneyAppView].
class CoreJourneyApp extends ConsumerStatefulWidget {
  const CoreJourneyApp({super.key});

  @override
  ConsumerState<CoreJourneyApp> createState() => _CoreJourneyAppState();
}

class _CoreJourneyAppState extends ConsumerState<CoreJourneyApp>
    with WidgetsBindingObserver {
  StreamSubscription<Uri>? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks(); // NEU
    // Fire once per cold start. forceSync() is offline-safe (ConnectivityService
    // no-ops it when unreachable), so this is the correct one-shot location.
    unawaited(ref.read(exercisesSyncServiceProvider).forceSync());
  }

  @override
  void dispose() {
    _deepLinkSub?.cancel(); // NEU
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    // Cold start: App war geschlossen, Link öffnet sie neu
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleDeepLink(initialUri);
    }

    // Warm start: App läuft im Hintergrund
    _deepLinkSub = appLinks.uriLinkStream.listen(_handleDeepLink);
  }

  Future<void> _handleDeepLink(Uri uri) async {
    // Match both URL shapes:
    //   https://reflexjourney.app/auth/reset-password → path == '/auth/reset-password'
    //   reflexjourney://auth/reset-password           → host == 'auth', path == '/reset-password'
    final isResetPassword = uri.path == '/auth/reset-password' ||
        (uri.scheme == 'reflexjourney' &&
            uri.host == 'auth' &&
            uri.path == '/reset-password');

    if (isResetPassword) {
      try {
        ref.read(passwordRecoveryActiveProvider.notifier).state = true;
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (_) {
        // Reset flag if session retrieval fails (e.g. expired or malformed link)
        ref.read(passwordRecoveryActiveProvider.notifier).state = false;
      }
    }
  }

  /// Flush the sync queue whenever the app moves to background or is suspended.
  /// This ensures data written during the session reaches Supabase even if the
  /// user force-quits before the 5-minute periodic timer fires.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(ref.read(syncServiceProvider).drain());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_syncReminderState(ref));
    }
  }

  @override
  Widget build(BuildContext context) => const _CoreJourneyAppView();
}

// ── App view ──────────────────────────────────────────────────────────────────

class _CoreJourneyAppView extends ConsumerWidget {
  const _CoreJourneyAppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Existing sessions do not always emit a fresh signedIn event after the
    // first build. Register remote push once a persisted user is available.
    if (currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(
          ref.read(pushNotificationServiceProvider).registerDeviceToken(
                environment: ref.read(appConfigProvider).environment,
              ),
        );
        unawaited(_syncReminderState(ref));
      });
    }

    // Trigger server → local rehydration whenever the user signs in or the
    // token is refreshed. Ensures returning users on a fresh device or after
    // reinstall see their real Supabase data instead of being re-enrolled.
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (_, next) {
      final event = next.valueOrNull?.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        final userId = next.valueOrNull?.session?.user.id;
        if (userId != null) {
          ref.read(syncServiceProvider).rehydrate(userId);
          unawaited(
            ref.read(pushNotificationServiceProvider).registerDeviceToken(
                  environment: ref.read(appConfigProvider).environment,
                ),
          );
          unawaited(_syncReminderState(ref));
        }
      }
      // On sign-out: settingsProvider re-creates with userId=null,
      // reads the global theme key (no value saved → defaults to system).
      // On next sign-in: re-creates with the real userId, restoring
      // the user's previously saved theme from their scoped key.
    });

    // React to notification-relevant settings changes.
    ref.listen<AppSettings>(settingsProvider, (prev, next) {
      _syncNotifications(ref, prev, next);
    });

    ref.listen<AsyncValue<Map<String, String>>>(
      pushNotificationOpenProvider,
      (_, next) {
        final payload = next.valueOrNull;
        if (payload != null) {
          unawaited(_handleNotificationPayload(ref, payload));
        }
      },
    );

    ref.listen<AsyncValue<String>>(
      localNotificationTapProvider,
      (_, next) {
        final payload = next.valueOrNull;
        if (payload == null || payload.isEmpty) return;
        try {
          final decoded = jsonDecode(payload);
          if (decoded is Map<String, dynamic>) {
            unawaited(
              _handleNotificationPayload(
                ref,
                decoded.map(
                  (key, value) => MapEntry(key, value?.toString() ?? ''),
                ),
              ),
            );
          }
        } catch (_) {}
      },
    );

    return MaterialApp.router(
      title: 'Reflex Journey',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      routerConfig: router,
      builder: (context, child) => IncomingCallListener(
        child: child ?? const SizedBox.shrink(),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de'),
        Locale('en'),
      ],
    );
  }
}

// ── Notification sync helper ──────────────────────────────────────────────────

Future<void> _handleNotificationPayload(
  WidgetRef ref,
  Map<String, String> payload,
) async {
  final type = payload['type'];
  if (type == 'video_call') {
    await _openCallFromPayload(ref, payload);
    return;
  }

  if (type == 'call_request') {
    final channelId = payload['channel_id'];
    final context = rootNavigatorKey.currentContext;
    if (channelId != null && channelId.isNotEmpty && context != null) {
      context.push('/dm/$channelId');
    }
    return;
  }

  if (type == 'appointment_proposal') {
    ref.invalidate(traineeProposalsProvider);
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      context.push(Routes.accompaniment);
    }
    return;
  }

  if (type == 'appointment_confirmed') {
    await _addConfirmedAppointmentToCalendar(payload);
    return;
  }

  if (type == 'training_reminder') {
    final context = rootNavigatorKey.currentContext;
    if (context != null && context.mounted) {
      context.go(Routes.trainingStart);
    }
  }
}

Future<void> _openCallFromPayload(
  WidgetRef ref,
  Map<String, String> payload,
) async {
  final callId = payload['call_id'];
  if (callId == null || callId.isEmpty) return;

  final call = await ref.read(videoRepositoryProvider).getCallById(callId);
  if (call == null || call.endedAt != null) return;

  final context = rootNavigatorKey.currentContext;
  if (context == null || !context.mounted) return;
  await openVideoCall(context, ref, call);
}

Future<void> _addConfirmedAppointmentToCalendar(
  Map<String, String> payload,
) async {
  final scheduledRaw = payload['scheduled_for'];
  if (scheduledRaw == null || scheduledRaw.isEmpty) return;

  final start = DateTime.tryParse(scheduledRaw)?.toLocal();
  if (start == null) return;

  final durationMinutes =
      (int.tryParse(payload['duration_minutes'] ?? '') ?? 60).clamp(15, 240);
  final title = payload['title']?.isNotEmpty == true
      ? payload['title']!
      : 'Isometrische Partnerübung';
  final traineeName = payload['trainee_name']?.isNotEmpty == true
      ? payload['trainee_name']!
      : 'Klient';
  final messenger = rootNavigatorKey.currentContext != null
      ? ScaffoldMessenger.maybeOf(rootNavigatorKey.currentContext!)
      : null;

  try {
    await CalendarService.instance.createCalendarEvent(
      title: '$title (mit $traineeName)',
      start: start,
      duration: Duration(minutes: durationMinutes),
      location:
          payload['location']?.isNotEmpty == true ? payload['location'] : null,
      description:
          payload['notes']?.isNotEmpty == true ? payload['notes'] : null,
    );
    messenger?.showSnackBar(
      SnackBar(
        content:
            Text('Termin mit $traineeName wurde dem Kalender hinzugefügt.'),
      ),
    );
  } catch (e) {
    messenger?.showSnackBar(
      SnackBar(content: Text('Kalender konnte nicht geöffnet werden: $e')),
    );
  }
}

Future<void> _syncNotifications(
  WidgetRef ref,
  AppSettings? prev,
  AppSettings next,
) async {
  final prevEnabled = prev?.remindersEnabled ?? false;
  final prevStart = prev?.reminderStartMinutes;
  final prevEnd = prev?.reminderEndMinutes;
  final prevWeeklyGoal = prev?.weeklyGoal;

  final changed = prevEnabled != next.remindersEnabled ||
      prevStart != next.reminderStartMinutes ||
      prevEnd != next.reminderEndMinutes ||
      prevWeeklyGoal != next.weeklyGoal;

  if (!changed) return;

  await _syncReminderState(ref, settings: next, previous: prev);
}

Future<void> _syncReminderState(
  WidgetRef ref, {
  AppSettings? settings,
  AppSettings? previous,
}) async {
  final AppSettings next = settings ?? ref.read(settingsProvider);
  final ns = ref.read(notificationServiceProvider);
  final repository = ref.read(reminderPreferencesRepositoryProvider);

  await repository.syncFromSettings(next);
  await repository.refreshTimezoneIfChanged(next);

  if (!next.remindersEnabled) {
    await ns.cancelReminder();
    return;
  }

  final serverEnabled = await repository.serverRemindersEnabled();
  if (serverEnabled) {
    await ns.cancelReminder();
    appLogger.i('Local training reminder suppressed for server cohort');
    return;
  }

  final prevEnabled = previous?.remindersEnabled ?? false;
  if (!prevEnabled && next.remindersEnabled) {
    final granted = await ns.requestPermission();
    if (!granted) return;
  }

  final isDE = next.languageCode == 'de';
  await ns.scheduleReminder(
    startMinutes: next.reminderStartMinutes,
    titleDe: isDE ? 'Zeit für deine Einheit' : 'Time for your unit',
    bodyDe: isDE
        ? 'Nimm dir Zeit für deine heutige Reflexintegrations-Einheit.'
        : "Take time for today's reflex integration unit.",
  );
}
