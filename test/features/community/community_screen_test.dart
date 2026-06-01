import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:corejourney/features/community/presentation/screens/community_screen.dart';
import 'package:corejourney/features/chat/presentation/providers/chat_providers.dart';

void main() {
  testWidgets('CommunityScreen renders Erfahrungen title and empty state',
      (tester) async {
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, __) => const CommunityScreen())],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatChannelsProvider.overrideWith((_) => Future.value([])),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Erfahrungen'), findsWidgets);
    expect(find.text('Noch keine geteilten Erfahrungen'), findsOneWidget);
  });
}
