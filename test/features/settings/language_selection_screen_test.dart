import 'package:corejourney/core/l10n/app_languages.dart';
import 'package:corejourney/core/settings/profile_locale_sync_service.dart';
import 'package:corejourney/core/settings/settings_provider.dart';
import 'package:corejourney/features/settings/presentation/screens/language_selection_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingLocaleSyncService implements ProfileLocaleSyncService {
  final calls = <({String userId, String languageCode})>[];

  @override
  Future<void> syncLocale({
    required String userId,
    required String languageCode,
  }) async {
    calls.add((userId: userId, languageCode: languageCode));
  }
}

void main() {
  test('settings language change updates state and persists', () async {
    SharedPreferences.setMockInitialValues({languagePreferenceKey: 'de'});
    final prefs = await SharedPreferences.getInstance();
    final notifier = SettingsNotifier(prefs, null);

    await notifier.setLanguage('en');

    expect(notifier.state.languageCode, 'en');
    expect(notifier.state.hasSelectedLanguage, isTrue);
    expect(prefs.getString(languagePreferenceKey), 'en');
    expect(SettingsNotifier(prefs, null).state.languageCode, 'en');
  });

  test('authenticated language change syncs profiles.locale', () async {
    SharedPreferences.setMockInitialValues({languagePreferenceKey: 'de'});
    final prefs = await SharedPreferences.getInstance();
    final syncService = _RecordingLocaleSyncService();
    final notifier = SettingsNotifier(
      prefs,
      'user-123',
      profileLocaleSyncService: syncService,
    );

    await notifier.setLanguage('en');

    expect(
      syncService.calls,
      [(userId: 'user-123', languageCode: 'en')],
    );
  });

  test('authenticated restore syncs the persisted language', () async {
    SharedPreferences.setMockInitialValues({languagePreferenceKey: 'en'});
    final prefs = await SharedPreferences.getInstance();
    final syncService = _RecordingLocaleSyncService();
    final notifier = SettingsNotifier(
      prefs,
      'user-123',
      profileLocaleSyncService: syncService,
    );

    await notifier.syncCurrentLanguage();

    expect(
      syncService.calls,
      [(userId: 'user-123', languageCode: 'en')],
    );
  });

  testWidgets('previews English before login without saving prematurely',
      (tester) async {
    SharedPreferences.setMockInitialValues({languagePreferenceKey: 'de'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => SettingsNotifier(prefs, null)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LanguageSelectionScreen(),
        ),
      ),
    );

    expect(find.text('Sprache wählen'), findsOneWidget);
    expect(find.text('Weiter'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pump();

    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(prefs.getString(languagePreferenceKey), 'de');
  });

  testWidgets('renders one button per registry entry', (tester) async {
    SharedPreferences.setMockInitialValues({languagePreferenceKey: 'de'});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => SettingsNotifier(prefs, null)),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LanguageSelectionScreen(),
        ),
      ),
    );

    // Iterates the registry rather than asserting a hardcoded count, so a
    // newly registered language is covered without touching this test.
    for (final language in AppLanguages.all) {
      expect(
        find.text(language.autonym),
        findsOneWidget,
        reason: 'missing picker button for ${language.code}',
      );
    }
  });
}
