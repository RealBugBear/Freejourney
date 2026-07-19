import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../settings/settings_provider.dart';

enum AppOnboardingHint {
  dashboard,
  progress,
  accompaniment,
  profile,
}

class OnboardingHintContent {
  const OnboardingHintContent({
    required this.title,
    required this.body,
    required this.items,
  });

  final String title;
  final String body;
  final List<OnboardingHintItem> items;
}

class OnboardingHintItem {
  const OnboardingHintItem({
    required this.iconName,
    required this.text,
  });

  final String iconName;
  final String text;
}

extension AppOnboardingHintContent on AppOnboardingHint {
  String get storageKey => switch (this) {
        AppOnboardingHint.dashboard => 'dashboard',
        AppOnboardingHint.progress => 'progress',
        AppOnboardingHint.accompaniment => 'accompaniment',
        AppOnboardingHint.profile => 'profile',
      };

  OnboardingHintContent content(AppLocalizations l10n) => switch (this) {
        AppOnboardingHint.dashboard => OnboardingHintContent(
            title: l10n.today,
            body: l10n.hintDashboardBody,
            items: [
              OnboardingHintItem(
                iconName: 'play',
                text: l10n.hintDashboardItemStart,
              ),
              OnboardingHintItem(
                iconName: 'check',
                text: l10n.hintDashboardItemLog,
              ),
              OnboardingHintItem(
                iconName: 'note',
                text: l10n.hintDashboardItemNote,
              ),
            ],
          ),
        AppOnboardingHint.progress => OnboardingHintContent(
            title: l10n.progressTitle,
            body: l10n.hintProgressBody,
            items: [
              OnboardingHintItem(
                iconName: 'chart',
                text: l10n.hintProgressItemOverview,
              ),
              OnboardingHintItem(
                iconName: 'note',
                text: l10n.hintProgressItemObserve,
              ),
              OnboardingHintItem(
                iconName: 'book',
                text: l10n.hintProgressItemJournal,
              ),
            ],
          ),
        AppOnboardingHint.accompaniment => OnboardingHintContent(
            title: l10n.accompanimentTitle,
            body: l10n.hintAccompanimentBody,
            items: [
              OnboardingHintItem(
                iconName: 'trainer',
                text: l10n.hintAccompanimentItemTrainer,
              ),
              OnboardingHintItem(
                iconName: 'chat',
                text: l10n.hintAccompanimentItemChat,
              ),
              OnboardingHintItem(
                iconName: 'calendar',
                text: l10n.hintAccompanimentItemAppointments,
              ),
            ],
          ),
        AppOnboardingHint.profile => OnboardingHintContent(
            title: l10n.profile,
            body: l10n.hintProfileBody,
            items: [
              OnboardingHintItem(
                iconName: 'settings',
                text: l10n.hintProfileItemSettings,
              ),
              OnboardingHintItem(
                iconName: 'account',
                text: l10n.hintProfileItemAccount,
              ),
              OnboardingHintItem(
                iconName: 'work',
                text: l10n.hintProfileItemRoles,
              ),
            ],
          ),
      };
}

final onboardingHintControllerProvider =
    StateNotifierProvider<OnboardingHintController, int>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final userId = ref.watch(authStateProvider).valueOrNull?.session?.user.id ??
      Supabase.instance.client.auth.currentUser?.id;
  return OnboardingHintController(prefs, userId);
});

class OnboardingHintController extends StateNotifier<int> {
  OnboardingHintController(this._prefs, this._userId) : super(0);

  final SharedPreferences _prefs;
  final String? _userId;
  final Set<AppOnboardingHint> _dismissedThisSession = {};

  bool shouldShow(AppOnboardingHint hint) {
    if (_userId == null) return false;
    if (_dismissedThisSession.contains(hint)) return false;
    return _prefs.getBool(_prefKey(hint)) != true;
  }

  void dismissForSession(AppOnboardingHint hint) {
    _dismissedThisSession.add(hint);
    state++;
  }

  Future<void> hidePermanently(AppOnboardingHint hint) async {
    _dismissedThisSession.add(hint);
    await _prefs.setBool(_prefKey(hint), true);
    state++;
  }

  Future<void> resetAll() async {
    _dismissedThisSession.clear();
    for (final hint in AppOnboardingHint.values) {
      await _prefs.remove(_prefKey(hint));
    }
    state++;
  }

  String _prefKey(AppOnboardingHint hint) =>
      'onboarding_hint.v1.${_userId ?? 'anonymous'}.${hint.storageKey}.hidden';
}
