import 'package:corejourney/core/settings/settings_provider.dart';
import 'package:corejourney/features/consent/presentation/providers/consent_provider.dart';
import 'package:corejourney/features/consent/presentation/screens/consent_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _buildApp(SharedPreferences prefs, {String locale = 'de'}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      settingsProvider.overrideWith((ref) => SettingsNotifier(prefs, null)),
      hasConsentedProvider.overrideWith((ref) async => false),
    ],
    child: MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ConsentScreen(),
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'settings.languageCode': 'de'});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('discover CTA stays disabled until checkbox is checked',
      (tester) async {
    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();

    expect(find.text('Kurz zustimmen'), findsOneWidget);
    expect(find.text('Reflex-Profil entdecken'), findsOneWidget);
    expect(find.text('Sicherheit'), findsOneWidget);
    expect(find.text('Nutzung'), findsOneWidget);
    expect(find.text('Datenschutz'), findsOneWidget);

    final cta = tester.widget<ElevatedButton>(
      find.byKey(const Key('consent_discover_cta')),
    );
    expect(cta.onPressed, isNull);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();

    final enabledCta = tester.widget<ElevatedButton>(
      find.byKey(const Key('consent_discover_cta')),
    );
    expect(enabledCta.onPressed, isNotNull);
  });

  testWidgets('document rows open bottom sheets with lawyer content',
      (tester) async {
    await tester.pumpWidget(_buildApp(prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sicherheit'));
    await tester.pumpAndSettle();
    expect(find.text('Medizinische und psychologische Hinweise'), findsWidgets);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nutzung'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Nutzungsbedingungen'), findsWidgets);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Datenschutz'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Datenschutz'), findsWidgets);
  });
}
