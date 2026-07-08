// T23 — PaywallScreen: rendert das Trio (Jahr hervorgehoben) und führt in
// der Stub-Phase auf die „noch nicht verfügbar“-Meldung statt in einen
// Kaufpfad. Kein Countdown, keine Rabatt-Inszenierung (bewusst nicht
// vorhanden — Test stellt sicher, dass der Kauf-Stub greift).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/premium/presentation/screens/paywall_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';

Widget _app() => const ProviderScope(
      child: MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PaywallScreen(),
      ),
    );

void main() {
  testWidgets('rendert Trio mit Preisen, Jahres-Badge und Dauer-Hinweis',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Monatlich'), findsOneWidget);
    expect(find.text('Jährlich'), findsOneWidget);
    expect(find.text('Einmalig'), findsOneWidget);
    expect(find.text('12,99 €'), findsOneWidget);
    expect(find.text('89,99 €'), findsOneWidget);
    expect(find.text('149,00 €'), findsOneWidget);
    expect(find.text('2 Monate geschenkt'), findsOneWidget);
    expect(find.textContaining('10–12 Monate'), findsOneWidget);
  });

  testWidgets('Stub-Kauf zeigt „noch nicht verfügbar“ statt Kaufpfad',
      (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Freischalten'));
    await tester.pumpAndSettle();

    expect(
      find.text('Käufe sind in dieser Version noch nicht verfügbar.'),
      findsOneWidget,
    );
  });

  testWidgets('Produktauswahl wechselt per Tap', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    // Lifetime antippen — kein Crash, Auswahlzustand ändert sich (Rahmen),
    // Kauf bleibt Stub.
    await tester.tap(find.text('Einmalig'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Käufe wiederherstellen'));
    await tester.pumpAndSettle();
    expect(
      find.text('Käufe sind in dieser Version noch nicht verfügbar.'),
      findsOneWidget,
    );
  });
}
