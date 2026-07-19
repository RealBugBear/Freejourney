// T06 — Video-Calls sind für den v1-Launch versteckt (Founder-Entscheidung
// D2=A, 2026-07-06). Sichert ab: Flag steht auf false, und der Chat-Screen
// rendert in beiden Rollen ohne videocam-Action — während die
// Termin-Funktion (event-Icon, Moderator) und das Nachrichtenfeld
// unverändert da sind (keine amputierte AppBar/Input-Bar).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/config/launch_flags.dart';
import 'package:corejourney/features/chat/domain/models/chat_channel.dart';
import 'package:corejourney/features/chat/domain/models/chat_message.dart';
import 'package:corejourney/features/chat/domain/repositories/chat_repository.dart';
import 'package:corejourney/features/chat/presentation/providers/chat_providers.dart';
import 'package:corejourney/features/chat/presentation/screens/chat_channel_screen.dart';
import 'package:corejourney/l10n/app_localizations.dart';

class _StubChatRepository implements ChatRepository {
  @override
  Future<List<ChatChannel>> getChannels() async => [];

  @override
  Future<ChatChannel> getOrCreateDirectChannel(String otherUserId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> markChannelRead(String channelId) async {}

  @override
  Stream<List<ChatMessage>> watchMessages(String channelId,
          {int pageSize = 30}) =>
      Stream.value(const []);

  @override
  Stream<List<ChatMessage>> watchCallRequests() => const Stream.empty();

  @override
  Future<List<ChatMessage>> fetchOlderMessages(
    String channelId, {
    required DateTime before,
    int limit = 30,
  }) async =>
      [];

  @override
  Future<void> sendMessage(String channelId, String content) async {}

  @override
  Future<void> sendCallRequest(String channelId) async {}

  @override
  Future<void> deleteMessage(String messageId) async {}

  @override
  Future<void> broadcastTyping(String channelId) async {}

  @override
  Stream<Set<String>> watchTypingUsers(String channelId) =>
      const Stream.empty();
}

ChatChannel _directChannel({required MemberRole role}) => ChatChannel(
      id: 'ch-1',
      type: ChannelType.direct,
      createdAt: DateTime(2026),
      currentUserRole: role,
      unreadCount: 0,
    );

Widget _app(ChatChannel channel) => ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(_StubChatRepository()),
      ],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChatChannelScreen(channelId: channel.id, channel: channel),
      ),
    );

void main() {
  test('kVideoCallsEnabled ist für den v1-Launch deaktiviert (D2=A)', () {
    expect(
      kVideoCallsEnabled,
      isFalse,
      reason: 'Video-Calls sind für v1 versteckt (AGORA_APP_ID fehlt in '
          '.env.prod; sichtbar kaputtes Feature wäre Apple-2.1-Risiko).',
    );
  });

  testWidgets('Practitioner-Chat rendert ohne Call-Button, Senden bleibt',
      (tester) async {
    await tester
        .pumpWidget(_app(_directChannel(role: MemberRole.member)));
    // Kein pumpAndSettle: der Screen enthält dauerhaft animierende Elemente.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.videocam_outlined), findsNothing);
    // Nachrichtenfeld unverändert vorhanden — Input-Bar nicht amputiert.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Moderator-Chat: kein Call-Button, Termin-Button bleibt',
      (tester) async {
    await tester
        .pumpWidget(_app(_directChannel(role: MemberRole.moderator)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.videocam_outlined), findsNothing);
    expect(find.byIcon(Icons.event_outlined), findsOneWidget);
  });
}
