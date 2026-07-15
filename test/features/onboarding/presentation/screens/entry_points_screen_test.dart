import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:corejourney/features/onboarding/presentation/screens/entry_points_screen.dart';
import 'package:corejourney/features/onboarding/presentation/providers/entry_points_provider.dart';
import 'package:corejourney/l10n/app_localizations.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => child),
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const Scaffold(body: Text('dashboard')),
            ),
          ],
        ),
      ),
    );

void main() {
  testWidgets('renders all 5 area cards', (tester) async {
    await tester.pumpWidget(_wrap(const EntryPointsScreen()));
    expect(find.text('Körper & Therapie'), findsOneWidget);
    expect(find.text('Koordination & Leistung'), findsOneWidget);
    expect(find.text('Emotionale Regulation & Innenwelt'), findsOneWidget);
    expect(find.text('Mein Kind: Schule & Entwicklung'), findsOneWidget);
    expect(find.text('Neugierde & Entdeckung'), findsOneWidget);
  });

  testWidgets('card detail hidden by default, shown after tap', (tester) async {
    await tester.pumpWidget(_wrap(const EntryPointsScreen()));
    expect(find.text('Vgl. Goddard Blythe: (Über)leben mit Reflexen'),
        findsNothing);
    await tester.tap(find.text('Körper & Therapie'));
    await tester.pump();
    expect(find.text('Vgl. Goddard Blythe: (Über)leben mit Reflexen'),
        findsOneWidget);
  });

  testWidgets('chip tap updates provider selection', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const EntryPointsScreen()),
              GoRoute(path: '/dashboard', builder: (_, __) => const Scaffold()),
            ],
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Mein Kind').last);
    await tester.tap(find.text('Mein Kind').last);
    await tester.pump();
    expect(container.read(entryPointsProvider), contains('mein_kind'));
  });

  testWidgets('Weiter button is always active', (tester) async {
    await tester.pumpWidget(_wrap(const EntryPointsScreen()));
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('Weiter button navigates to dashboard', (tester) async {
    await tester.pumpWidget(_wrap(const EntryPointsScreen()));
    await tester.ensureVisible(find.text('Weiter'));
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('dashboard'), findsOneWidget);
  });
}
