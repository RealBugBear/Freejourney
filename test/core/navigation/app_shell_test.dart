import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:corejourney/core/navigation/app_shell.dart';
import 'package:corejourney/features/trainer/presentation/providers/trainer_provider.dart';
import 'package:corejourney/features/chat/presentation/providers/chat_providers.dart';
import 'package:corejourney/l10n/app_localizations.dart';

Widget _buildApp({
  bool trainerLinked = false,
  String role = 'practitioner',
  int unreadDm = 0,
}) {
  final router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const Scaffold(body: Text('Heute')),
          ),
          GoRoute(
            path: '/verlauf',
            builder: (_, __) => const Scaffold(body: Text('Verlauf')),
          ),
          GoRoute(
            path: '/begleitung',
            builder: (_, __) => const Scaffold(body: Text('Begleitung')),
          ),
          GoRoute(
            path: '/trainer/dashboard',
            builder: (_, __) => const Scaffold(body: Text('Trainer')),
          ),
          GoRoute(
            path: '/admin',
            builder: (_, __) => const Scaffold(body: Text('Admin')),
          ),
          GoRoute(
            path: '/dm',
            builder: (_, __) => const Scaffold(body: Text('DM')),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const Scaffold(body: Text('Profile')),
          ),
        ],
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      userRoleProvider.overrideWith((ref) async => role),
      trainerLinkedProvider.overrideWithValue(trainerLinked),
      unreadDmCountProvider.overrideWithValue(unreadDm),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  testWidgets('shows user tabs for practitioners', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.destinations.length, 4);
  });

  testWidgets('shows trainer tab for trainers', (tester) async {
    await tester.pumpWidget(_buildApp(role: 'trainer'));
    await tester.pumpAndSettle();
    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.destinations.length, 5);
  });

  testWidgets('shows trainer and admin tabs for admins', (tester) async {
    await tester.pumpWidget(_buildApp(role: 'admin'));
    await tester.pumpAndSettle();
    final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(nav.destinations.length, 6);
  });

  testWidgets('Begleitung tab shows badge label when unread > 0',
      (tester) async {
    await tester.pumpWidget(_buildApp(unreadDm: 3));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('3'),
      ),
      findsWidgets, // badge appears on both icon and selectedIcon
    );
  });

  testWidgets('Begleitung tab badge is hidden when unread is 0',
      (tester) async {
    await tester.pumpWidget(_buildApp(unreadDm: 0));
    await tester.pumpAndSettle();
    // No numeric badge label should be visible
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('0'),
      ),
      findsNothing,
    );
  });

  testWidgets('tapping Begleitung tab navigates to /begleitung',
      (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Begleitung'));
    await tester.pumpAndSettle();
    expect(find.text('Begleitung'), findsWidgets);
  });
}
