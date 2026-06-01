import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/chat/domain/models/chat_channel.dart';
import 'package:corejourney/features/chat/domain/models/chat_message.dart';
import 'package:corejourney/features/chat/domain/repositories/chat_repository.dart';
import 'package:corejourney/features/chat/presentation/providers/chat_providers.dart';

// ── Stub ──────────────────────────────────────────────────────────────────────

class _StubChatRepository implements ChatRepository {
  final List<ChatChannel> channels;

  _StubChatRepository({required this.channels});

  @override
  Future<List<ChatChannel>> getChannels() async => channels;

  @override
  Future<ChatChannel> getOrCreateDirectChannel(String otherUserId) async {
    throw UnimplementedError();
  }

  @override
  Future<void> markChannelRead(String channelId) async {}

  @override
  Stream<List<ChatMessage>> watchMessages(String channelId,
      {int pageSize = 30}) {
    return const Stream.empty();
  }

  @override
  Stream<List<ChatMessage>> watchCallRequests() {
    return const Stream.empty();
  }

  @override
  Future<List<ChatMessage>> fetchOlderMessages(
    String channelId, {
    required DateTime before,
    int limit = 30,
  }) async {
    return [];
  }

  @override
  Future<void> sendMessage(String channelId, String content) async {}

  @override
  Future<void> sendCallRequest(String channelId) async {}

  @override
  Future<void> deleteMessage(String messageId) async {}

  @override
  Future<void> broadcastTyping(String channelId) async {}

  @override
  Stream<Set<String>> watchTypingUsers(String channelId) {
    return const Stream.empty();
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

ChatChannel _makeChannel(String id, int unreadCount) {
  return ChatChannel(
    id: id,
    type: ChannelType.direct,
    createdAt: DateTime(2024),
    currentUserRole: MemberRole.member,
    unreadCount: unreadCount,
  );
}

ProviderContainer _makeContainer(_StubChatRepository stub) {
  return ProviderContainer(
    overrides: [
      chatRepositoryProvider.overrideWithValue(stub),
    ],
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('chatChannelsProvider', () {
    test('returns channels from stub repository', () async {
      final channels = [
        _makeChannel('ch-1', 2),
        _makeChannel('ch-2', 0),
      ];
      final stub = _StubChatRepository(channels: channels);
      final container = _makeContainer(stub);
      addTearDown(container.dispose);

      final result = await container.read(chatChannelsProvider.future);

      expect(result, equals(channels));
      expect(result.length, 2);
    });

    test('returns empty list when stub has no channels', () async {
      final stub = _StubChatRepository(channels: []);
      final container = _makeContainer(stub);
      addTearDown(container.dispose);

      final result = await container.read(chatChannelsProvider.future);

      expect(result, isEmpty);
    });
  });

  group('totalUnreadCountProvider', () {
    test('sums unread counts across all channels', () async {
      final channels = [
        _makeChannel('ch-1', 3),
        _makeChannel('ch-2', 7),
        _makeChannel('ch-3', 0),
      ];
      final stub = _StubChatRepository(channels: channels);
      final container = _makeContainer(stub);
      addTearDown(container.dispose);

      // Wait for channels to load first
      await container.read(chatChannelsProvider.future);

      final total = container.read(totalUnreadCountProvider);
      expect(total, equals(10));
    });

    test('returns 0 when no channels have unread messages', () async {
      final channels = [
        _makeChannel('ch-1', 0),
        _makeChannel('ch-2', 0),
      ];
      final stub = _StubChatRepository(channels: channels);
      final container = _makeContainer(stub);
      addTearDown(container.dispose);

      await container.read(chatChannelsProvider.future);

      final total = container.read(totalUnreadCountProvider);
      expect(total, equals(0));
    });

    test('returns 0 before channels are loaded', () {
      final stub = _StubChatRepository(channels: [_makeChannel('ch-1', 5)]);
      final container = _makeContainer(stub);
      addTearDown(container.dispose);

      // Do NOT await — totalUnreadCountProvider should be 0 while loading
      final total = container.read(totalUnreadCountProvider);
      expect(total, equals(0));
    });
  });
}
