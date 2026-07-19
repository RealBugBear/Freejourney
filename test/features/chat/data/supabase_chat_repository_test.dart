import 'package:corejourney/features/chat/domain/models/chat_channel.dart';
import 'package:corejourney/features/chat/domain/models/chat_message.dart';
import 'package:corejourney/features/chat/domain/repositories/chat_repository.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeChatRepository implements ChatRepository {
  @override
  Future<List<ChatChannel>> getChannels() async => [];
  @override
  Future<ChatChannel> getOrCreateDirectChannel(String o) async => ChatChannel(
      id: 'c',
      type: ChannelType.direct,
      createdAt: DateTime(2026),
      currentUserRole: MemberRole.member,
      unreadCount: 0);
  @override
  Future<void> markChannelRead(String c) async {}
  @override
  Stream<List<ChatMessage>> watchMessages(String c, {int pageSize = 30}) =>
      const Stream.empty();
  @override
  Stream<List<ChatMessage>> watchCallRequests() => const Stream.empty();
  @override
  Future<List<ChatMessage>> fetchOlderMessages(String c,
          {required DateTime before, int limit = 30}) async =>
      [];
  @override
  Future<void> sendMessage(String c, String m) async {}
  @override
  Future<void> sendCallRequest(String c) async {}
  @override
  Future<void> deleteMessage(String m) async {}
  @override
  Future<void> broadcastTyping(String c) async {}
  @override
  Stream<Set<String>> watchTypingUsers(String c) => const Stream.empty();
}

void main() {
  group('ChatChannel — domain logic', () {
    test('isModerator true for moderator role', () {
      final ch = ChatChannel(
          id: '1',
          type: ChannelType.direct,
          createdAt: DateTime(2026),
          currentUserRole: MemberRole.moderator,
          unreadCount: 0);
      expect(ch.isModerator, isTrue);
    });
    test('isModerator false for member role', () {
      final ch = ChatChannel(
          id: '1',
          type: ChannelType.direct,
          createdAt: DateTime(2026),
          currentUserRole: MemberRole.member,
          unreadCount: 0);
      expect(ch.isModerator, isFalse);
    });
    test('channelDisplayName returns Trainer for direct', () {
      final l10n = lookupAppLocalizations(const Locale('de'));
      final ch = ChatChannel(
          id: '1',
          type: ChannelType.direct,
          createdAt: DateTime(2026),
          currentUserRole: MemberRole.member,
          unreadCount: 0);
      expect(ch.channelDisplayName(l10n), l10n.trainerFallbackName);
    });
    test('channelDisplayName returns packageName for community', () {
      final l10n = lookupAppLocalizations(const Locale('de'));
      final ch = ChatChannel(
          id: '1',
          type: ChannelType.community,
          packageId: 'moro',
          createdAt: DateTime(2026),
          currentUserRole: MemberRole.member,
          unreadCount: 0);
      expect(ch.channelDisplayName(l10n, packageName: 'Moro'), 'Moro');
    });
    test('fromJson parses correctly', () {
      final json = {
        'id': 'abc',
        'type': 'community',
        'package_id': 'moro',
        'created_at': '2026-04-13T10:00:00.000Z'
      };
      final ch = ChatChannel.fromJson(json, currentUserRole: MemberRole.member);
      expect(ch.type, ChannelType.community);
      expect(ch.packageId, 'moro');
    });
  });

  group('ChatMessage — domain logic', () {
    test('isDeleted true when deletedAt set', () {
      final msg = ChatMessage(
          id: '1',
          channelId: 'c',
          senderId: 'u',
          content: 'hi',
          isBotResponse: false,
          isCallRequest: false,
          deletedAt: DateTime(2026),
          createdAt: DateTime(2026));
      expect(msg.isDeleted, isTrue);
    });
    test('isDeleted false when deletedAt null', () {
      final msg = ChatMessage(
          id: '1',
          channelId: 'c',
          senderId: 'u',
          content: 'hi',
          isBotResponse: false,
          isCallRequest: false,
          createdAt: DateTime(2026));
      expect(msg.isDeleted, isFalse);
    });
    test('isOwnMessage matches senderId', () {
      final msg = ChatMessage(
          id: '1',
          channelId: 'c',
          senderId: 'user-abc',
          content: 'hi',
          isBotResponse: false,
          isCallRequest: false,
          createdAt: DateTime(2026));
      expect(msg.isOwnMessage('user-abc'), isTrue);
      expect(msg.isOwnMessage('user-xyz'), isFalse);
    });
    test('fromJson parses all fields', () {
      final json = {
        'id': 'm1',
        'channel_id': 'c1',
        'sender_id': 'u1',
        'content': 'hello',
        'is_bot_response': true,
        'is_call_request': false,
        'deleted_at': null,
        'created_at': '2026-04-13T10:00:00.000Z',
      };
      final msg = ChatMessage.fromJson(json);
      expect(msg.isBotResponse, isTrue);
      expect(msg.isDeleted, isFalse);
    });
  });

  group('FakeChatRepository — interface compliance', () {
    test('getChannels returns empty list', () async {
      expect(await _FakeChatRepository().getChannels(), isEmpty);
    });
    test('sendMessage completes', () async {
      await expectLater(
          _FakeChatRepository().sendMessage('c', 'hi'), completes);
    });
  });
}
