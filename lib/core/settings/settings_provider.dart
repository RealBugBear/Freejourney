import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

export '../training/training_feedback_settings.dart' show TrainingFeedbackMode;

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/training/domain/models/training_session.dart';
import '../l10n/app_languages.dart';
import '../training/training_feedback_settings.dart';
import 'profile_locale_sync_service.dart';

// ── Keys ─────────────────────────────────────────────────────────────────────

const _kWeeklyGoal = 'settings.weeklyGoal';
const languagePreferenceKey = 'settings.languageCode';
// Theme is user-scoped: 'settings.themeMode_<userId>' so each account
// independently remembers its own theme preference.
// Falls back to 'settings.themeMode' for unauthenticated state.
const _kThemeModeGlobal = 'settings.themeMode';
const _kRemindersEnabled = 'settings.remindersEnabled';
const _kReminderStart = 'settings.reminderStartMinutes';
const _kReminderEnd = 'settings.reminderEndMinutes';
const _kChildAssist = 'settings.childAssistMode';
const _kTrainingMode = 'settings.trainingMode';

String _themeModeKey(String? userId) =>
    userId != null ? 'settings.themeMode_$userId' : _kThemeModeGlobal;

// ── Model ─────────────────────────────────────────────────────────────────────

class AppSettings {
  final TrainingFeedbackMode feedbackMode;
  final int weeklyGoal;
  final String languageCode;
  final bool hasSelectedLanguage;
  final ThemeMode themeMode;
  final bool remindersEnabled;
  final int reminderStartMinutes; // hour*60 + minute
  final int reminderEndMinutes;
  final bool childAssistMode;
  final TrainingSessionMode trainingMode;

  const AppSettings({
    this.feedbackMode = TrainingFeedbackMode.voiceAndCues,
    this.weeklyGoal = 5,
    this.languageCode = 'de',
    this.hasSelectedLanguage = false,
    this.themeMode = ThemeMode.system,
    this.remindersEnabled = false,
    this.reminderStartMinutes = 8 * 60, // 08:00
    this.reminderEndMinutes = 20 * 60, // 20:00
    this.childAssistMode = false,
    this.trainingMode = TrainingSessionMode.tutorial,
  });

  TimeOfDay get reminderStart => TimeOfDay(
      hour: reminderStartMinutes ~/ 60, minute: reminderStartMinutes % 60);
  TimeOfDay get reminderEnd => TimeOfDay(
      hour: reminderEndMinutes ~/ 60, minute: reminderEndMinutes % 60);

  AppSettings copyWith({
    TrainingFeedbackMode? feedbackMode,
    int? weeklyGoal,
    String? languageCode,
    bool? hasSelectedLanguage,
    ThemeMode? themeMode,
    bool? remindersEnabled,
    int? reminderStartMinutes,
    int? reminderEndMinutes,
    bool? childAssistMode,
    TrainingSessionMode? trainingMode,
  }) {
    return AppSettings(
      feedbackMode: feedbackMode ?? this.feedbackMode,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      languageCode: languageCode ?? this.languageCode,
      hasSelectedLanguage: hasSelectedLanguage ?? this.hasSelectedLanguage,
      themeMode: themeMode ?? this.themeMode,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
      reminderStartMinutes: reminderStartMinutes ?? this.reminderStartMinutes,
      reminderEndMinutes: reminderEndMinutes ?? this.reminderEndMinutes,
      childAssistMode: childAssistMode ?? this.childAssistMode,
      trainingMode: trainingMode ?? this.trainingMode,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main');
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SharedPreferences _prefs;
  final String? _userId;
  final ProfileLocaleSyncService? _profileLocaleSyncService;
  Future<void> _feedbackPersistence = Future.value();

  SettingsNotifier(
    this._prefs,
    this._userId, {
    ProfileLocaleSyncService? profileLocaleSyncService,
  })  : _profileLocaleSyncService = profileLocaleSyncService,
        super(_load(_prefs, _userId)) {
    // SharedPreferences writes are local and best-effort. Reads remain
    // conservative until this migration completes, even if the app is killed.
    _feedbackPersistence = _migrateFeedbackMode();
    unawaited(_feedbackPersistence);
  }

  static AppSettings _load(SharedPreferences prefs, String? userId) {
    // Read theme from user-scoped key; fall back to global key for migration
    // (users who saved a theme before this change still get their preference).
    final themeModeIndex = prefs.getInt(_themeModeKey(userId)) ??
        prefs.getInt(_kThemeModeGlobal) ??
        0;

    // If no language has been saved yet (first launch), detect from device locale.
    // The registry decides which languages are supported and what an
    // unsupported device language falls back to.
    final savedLanguage = prefs.getString(languagePreferenceKey);
    final hasSelectedLanguage = prefs.containsKey(languagePreferenceKey);
    final languageCode = savedLanguage ??
        AppLanguages.resolveInitial(
          WidgetsBinding.instance.platformDispatcher.locale.languageCode,
        );

    return AppSettings(
      feedbackMode: TrainingFeedbackSettings.feedbackMode(prefs),
      weeklyGoal: prefs.getInt(_kWeeklyGoal) ?? 5,
      languageCode: languageCode,
      hasSelectedLanguage: hasSelectedLanguage,
      themeMode: ThemeMode.values[themeModeIndex.clamp(0, 2)],
      remindersEnabled: prefs.getBool(_kRemindersEnabled) ?? false,
      reminderStartMinutes: prefs.getInt(_kReminderStart) ?? 8 * 60,
      reminderEndMinutes: prefs.getInt(_kReminderEnd) ?? 20 * 60,
      childAssistMode: prefs.getBool(_kChildAssist) ?? false,
      trainingMode: TrainingSessionMode
          .values[(prefs.getInt(_kTrainingMode) ?? 0).clamp(0, 1)],
    );
  }

  void setFeedbackMode(TrainingFeedbackMode mode) {
    state = state.copyWith(feedbackMode: mode);
    _feedbackPersistence = _feedbackPersistence.then(
      (_) => _persistFeedbackMode(mode),
    );
    unawaited(_feedbackPersistence);
  }

  Future<void> _migrateFeedbackMode() async {
    try {
      await TrainingFeedbackSettings.migrateFeedbackMode(_prefs);
    } catch (error) {
      debugPrint('[SettingsNotifier] feedback migration failed: $error');
    }
  }

  Future<void> _persistFeedbackMode(TrainingFeedbackMode mode) async {
    try {
      await TrainingFeedbackSettings.setFeedbackMode(_prefs, mode);
    } catch (error) {
      debugPrint('[SettingsNotifier] feedback persistence failed: $error');
    }
  }

  void setWeeklyGoal(int goal) {
    state = state.copyWith(weeklyGoal: goal);
    _prefs.setInt(_kWeeklyGoal, goal);
  }

  Future<void> setLanguage(String code) async {
    assert(AppLanguages.isSupported(code), 'unsupported language code: $code');
    state = state.copyWith(languageCode: code, hasSelectedLanguage: true);
    await _prefs.setString(languagePreferenceKey, code);
    await syncCurrentLanguage();
  }

  Future<void> syncCurrentLanguage() async {
    final userId = _userId;
    final service = _profileLocaleSyncService;
    if (userId == null || service == null) return;

    await service.syncLocale(
      userId: userId,
      languageCode: state.languageCode,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    // Persist under user-scoped key so sign-out/sign-in restores correctly.
    _prefs.setInt(_themeModeKey(_userId), mode.index);
  }

  void setRemindersEnabled(bool enabled) {
    state = state.copyWith(remindersEnabled: enabled);
    _prefs.setBool(_kRemindersEnabled, enabled);
  }

  void setReminderStart(TimeOfDay time) {
    final minutes = time.hour * 60 + time.minute;
    state = state.copyWith(reminderStartMinutes: minutes);
    _prefs.setInt(_kReminderStart, minutes);
  }

  void setReminderEnd(TimeOfDay time) {
    final minutes = time.hour * 60 + time.minute;
    state = state.copyWith(reminderEndMinutes: minutes);
    _prefs.setInt(_kReminderEnd, minutes);
  }

  void setChildAssistMode(bool enabled) {
    state = state.copyWith(childAssistMode: enabled);
    _prefs.setBool(_kChildAssist, enabled);
  }

  void setTrainingMode(TrainingSessionMode mode) {
    state = state.copyWith(trainingMode: mode);
    _prefs.setInt(_kTrainingMode, mode.index);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  // Watch auth state so the notifier re-creates on sign-in/sign-out,
  // loading the correct user-scoped theme key each time.
  final userId = ref.watch(authStateProvider).valueOrNull?.session?.user.id ??
      Supabase.instance.client.auth.currentUser?.id;
  final notifier = SettingsNotifier(
    prefs,
    userId,
    profileLocaleSyncService: ref.watch(profileLocaleSyncServiceProvider),
  );
  if (userId != null) {
    // Covers persisted sessions, sign-in and token refresh. This is deliberately
    // best-effort and must not delay provider creation or app startup.
    unawaited(notifier.syncCurrentLanguage());
  }
  return notifier;
});

final hasSelectedLanguageProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).hasSelectedLanguage;
});

// ── Derived providers consumed by app.dart ────────────────────────────────────

final localeProvider = Provider<Locale>((ref) {
  final code = ref.watch(settingsProvider).languageCode;
  return Locale(code);
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).themeMode;
});
