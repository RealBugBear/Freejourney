// T04 — Community/Feed sind für den v1-Launch versteckt (Founder-Entscheidung
// D1=A, 2026-07-06). Diese Tests sichern zwei Dinge ab:
//  1. Das Flag steht für den Launch tatsächlich auf false.
//  2. Der produktive Route-Gate-Redirect (communityGateRedirect, in
//     app_router.dart an /community und /experience/:channelId gehängt)
//     leitet direkte Aufrufe sauber aufs Dashboard um — kein Crash, kein 404.
// Beim bewussten Reaktivieren (Flag → true) schlagen Test 1 und die
// Redirect-Erwartungen fehl: vorher T02/T03 umsetzen (Apple 1.2), dann die
// Tests hier auf die neue Realität anpassen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:corejourney/config/launch_flags.dart';
import 'package:corejourney/core/navigation/app_router.dart';

GoRouter _gatedRouter(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: Routes.dashboard,
          builder: (_, __) => const Scaffold(body: Text('Dashboard')),
        ),
        // Stub-Builder statt echter Screens (die brauchen Provider/Supabase);
        // unter Test steht der produktive Redirect aus app_router.dart.
        GoRoute(
          path: Routes.community,
          redirect: communityGateRedirect,
          builder: (_, __) => const Scaffold(body: Text('Community')),
        ),
        GoRoute(
          path: Routes.experienceFeed,
          redirect: communityGateRedirect,
          builder: (_, __) => const Scaffold(body: Text('Feed')),
        ),
      ],
    );

void main() {
  test('kCommunityEnabled ist für den v1-Launch deaktiviert (D1=A)', () {
    expect(
      kCommunityEnabled,
      isFalse,
      reason: 'Community/Feed dürfen erst wieder aktiviert werden, wenn '
          'Melden + Blockieren (T02/T03) umgesetzt sind — Apple Guideline 1.2.',
    );
  });

  testWidgets('direkter Aufruf von /community landet auf dem Dashboard',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: _gatedRouter(Routes.community)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Community'), findsNothing);
  });

  testWidgets(
      'direkter Aufruf von /experience/:channelId landet auf dem Dashboard',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(routerConfig: _gatedRouter('/experience/abc-123')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Feed'), findsNothing);
  });
}
