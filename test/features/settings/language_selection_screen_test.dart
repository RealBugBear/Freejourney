import 'package:corejourney/core/settings/settings_provider.dart';
import 'package:corejourney/features/settings/presentation/screens/language_selection_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
}
