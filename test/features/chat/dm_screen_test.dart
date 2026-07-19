import 'package:corejourney/features/chat/domain/models/chat_channel.dart';
import 'package:corejourney/features/chat/presentation/providers/chat_providers.dart';
import 'package:corejourney/features/chat/presentation/screens/dm_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

ChatChannel _directChannel(String id) => ChatChannel(
      id: id,
      type: ChannelType.direct,
      createdAt: DateTime(2026),
      currentUserRole: MemberRole.member,
      unreadCount: 0,
    );

ChatChannel _communityChannel(String id) => ChatChannel(
      id: id,
      type: ChannelType.community,
      packageId: 'moro',
      createdAt: DateTime(2026),
      currentUserRole: MemberRole.member,
      unreadCount: 0,
    );

Widget _wrap(List<ChatChannel> channels) {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, __) => const DmScreen())],
  );
  return ProviderScope(
    overrides: [
      chatChannelsProvider.overrideWith((_) => Future.value(channels)),
    ],
    child: MaterialApp.router(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  );
}

void main() {
  testWidgets('shows only direct channels, filters community out',
      (tester) async {
    await tester.pumpWidget(_wrap([
      _directChannel('dm-1'),
      _communityChannel('comm-1'),
    ]));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsOneWidget);
  });

  testWidgets('shows empty state when no direct channels', (tester) async {
    await tester.pumpWidget(_wrap([_communityChannel('comm-1')]));
    await tester.pumpAndSettle();
    expect(
      find.text(lookupAppLocalizations(const Locale('de')).chatNoMessagesYet),
      findsOneWidget,
    );
  });

  testWidgets('shows empty state when channel list is empty', (tester) async {
    await tester.pumpWidget(_wrap([]));
    await tester.pumpAndSettle();
    expect(
      find.text(lookupAppLocalizations(const Locale('de')).chatNoMessagesYet),
      findsOneWidget,
    );
  });
}
