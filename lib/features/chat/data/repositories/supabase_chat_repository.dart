import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/l10n/active_localizations.dart';
import '../../domain/models/chat_channel.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

class SupabaseChatRepository implements ChatRepository {
  SupabaseChatRepository();

  SupabaseClient get _client => Supabase.instance.client;
  String? get _userId => _client.auth.currentUser?.id;

  final _presenceChannels = <String, RealtimeChannel>{};

  // ── Channels ──────────────────────────────────────────────────────────────

  @override
  Future<List<ChatChannel>> getChannels() async {
    final userId = _userId;
    if (userId == null) return [];

    final rows = await _client.rpc(
      'get_channel_list',
      params: {'p_user_id': userId},
    ) as List;

    return rows.map((row) {
      final m = row as Map<String, dynamic>;
      final roleStr = m['member_role'] as String? ?? 'member';
      final role =
          roleStr == 'moderator' ? MemberRole.moderator : MemberRole.member;
      final lastMsgContent = m['last_message_content'] as String?;
      final lastMsgAtStr = m['last_message_at'] as String?;
      final lastMessageAt =
          lastMsgAtStr != null ? DateTime.parse(lastMsgAtStr) : null;
      final unreadCount = (m['unread_count'] as num?)?.toInt() ?? 0;

      return ChatChannel.fromJson(
        m,
        currentUserRole: role,
        lastMessageContent: lastMsgContent,
        lastMessageAt: lastMessageAt,
        unreadCount: unreadCount,
      );
    }).toList();
  }

  @override
  Future<ChatChannel> getOrCreateDirectChannel(String otherUserId) async {
    final userId = _userId;
    if (userId == null) throw StateError('User not authenticated');

    final channelId = await _client.rpc(
      'get_or_create_direct_channel',
      params: {'user_a': userId, 'user_b': otherUserId},
    ) as String;

    final channelJson = await _client
        .from('chat_channels')
        .select()
        .eq('id', channelId)
        .single();

    final memberJson = await _client
        .from('chat_channel_members')
        .select('role')
        .eq('channel_id', channelId)
        .eq('user_id', userId)
        .maybeSingle();
    final roleStr = memberJson?['role'] as String? ?? 'member';
    final role =
        roleStr == 'moderator' ? MemberRole.moderator : MemberRole.member;

    return ChatChannel.fromJson(
      channelJson,
      currentUserRole: role,
      unreadCount: 0,
    );
  }

  @override
  Future<void> markChannelRead(String channelId) async {
    final userId = _userId;
    if (userId == null) return;

    await _client
        .from('chat_channel_members')
        .update(
          {'last_read_at': DateTime.now().toIso8601String()},
        )
        .eq('channel_id', channelId)
        .eq('user_id', userId);
  }

  // ── Messages ──────────────────────────────────────────────────────────────

  @override
  Stream<List<ChatMessage>> watchMessages(String channelId,
      {int pageSize = 30}) async* {
    var lastSignature = '';
    var hasEmittedInitialValue = false;

    while (true) {
      try {
        final messages = await _fetchRecentMessages(channelId, pageSize);
        final signature =
            messages.map((m) => '${m.id}:${m.deletedAt}').join('|');
        if (signature != lastSignature || !hasEmittedInitialValue) {
          lastSignature = signature;
          hasEmittedInitialValue = true;
          yield messages;
        }
      } catch (e) {
        debugPrint('watchMessages polling failed: $e');
        if (!hasEmittedInitialValue) {
          hasEmittedInitialValue = true;
          yield const [];
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Stream<List<ChatMessage>> watchCallRequests() async* {
    var lastSignature = '';
    var hasEmittedInitialValue = false;

    while (true) {
      try {
        final messages = await _fetchRecentCallRequests();
        final signature =
            messages.map((m) => '${m.id}:${m.deletedAt}').join('|');
        if (signature != lastSignature || !hasEmittedInitialValue) {
          lastSignature = signature;
          hasEmittedInitialValue = true;
          yield messages;
        }
      } catch (e) {
        debugPrint('watchCallRequests polling failed: $e');
        if (!hasEmittedInitialValue) {
          hasEmittedInitialValue = true;
          yield const [];
        }
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Future<List<ChatMessage>> fetchOlderMessages(
    String channelId, {
    required DateTime before,
    int limit = 30,
  }) async {
    final rows = await _client
        .from('chat_messages')
        .select()
        .eq('channel_id', channelId)
        .lt('created_at', before.toIso8601String())
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List)
        .map((r) => ChatMessage.fromJson(r as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  Future<List<ChatMessage>> _fetchRecentMessages(
    String channelId,
    int pageSize,
  ) async {
    final rows = await _client
        .from('chat_messages')
        .select()
        .eq('channel_id', channelId)
        .order('created_at', ascending: false)
        .limit(pageSize);
    return (rows as List)
        .map((r) => ChatMessage.fromJson(r as Map<String, dynamic>))
        .toList()
        .reversed
        .toList();
  }

  Future<List<ChatMessage>> _fetchRecentCallRequests() async {
    final userId = _userId;
    if (userId == null) return const [];

    final directTrainerChannelIds = (await getChannels())
        .where(
          (channel) =>
              channel.type == ChannelType.direct && channel.isModerator,
        )
        .map((channel) => channel.id)
        .toList();

    if (directTrainerChannelIds.isEmpty) return const [];

    final rows = await _client
        .from('chat_messages')
        .select()
        .inFilter('channel_id', directTrainerChannelIds)
        .eq('is_call_request', true)
        .neq('sender_id', userId)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .limit(10);

    return (rows as List)
        .map((r) => ChatMessage.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> sendMessage(String channelId, String content) async {
    final userId = _userId;
    if (userId == null) return;

    await _client.from('chat_messages').insert({
      'channel_id': channelId,
      'sender_id': userId,
      'content': content,
      'is_bot_response': false,
      'is_call_request': false,
    });
  }

  @override
  Future<void> sendCallRequest(String channelId) async {
    final userId = _userId;
    if (userId == null) return;

    final l10n = await lookupActiveAppLocalizations();
    await _client.from('chat_messages').insert({
      'channel_id': channelId,
      'sender_id': userId,
      'content': l10n.chatCallRequestMessageContent,
      'is_bot_response': false,
      'is_call_request': true,
    });

    unawaited(_notifyCallRequest(channelId: channelId));
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await _client.from('chat_messages').update(
      {'deleted_at': DateTime.now().toIso8601String()},
    ).eq('id', messageId);
  }

  // ── Typing indicator ──────────────────────────────────────────────────────

  @override
  Future<void> broadcastTyping(String channelId) async {
    final userId = _userId;
    if (userId == null) return;

    final ch = _presenceChannels.putIfAbsent(
      channelId,
      () => _client.channel('typing:$channelId',
          opts: const RealtimeChannelConfig(ack: false))
        ..subscribe(),
    );
    await ch.track(
        {'user_id': userId, 'ts': DateTime.now().millisecondsSinceEpoch});
  }

  @override
  Stream<Set<String>> watchTypingUsers(String channelId) {
    final userId = _userId;
    final controller = StreamController<Set<String>>.broadcast();
    const cutoffMs = Duration(seconds: 10);

    late final RealtimeChannel ch;
    ch = _client
        .channel('presence:typing:$channelId',
            opts: const RealtimeChannelConfig(ack: false))
        .onPresenceSync((payload) {
      final state = ch.presenceState();
      final now = DateTime.now().millisecondsSinceEpoch;
      final active = state
          .expand((s) => s.presences)
          .where((p) {
            final ts = p.payload['ts'] as int?;
            return ts != null && (now - ts) < cutoffMs.inMilliseconds;
          })
          .map((p) => p.payload['user_id'] as String?)
          .whereType<String>()
          .where((id) => id != userId)
          .toSet();
      controller.add(active);
    })
      ..subscribe();

    controller.onCancel = () => ch.unsubscribe();
    return controller.stream;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _notifyCallRequest({required String channelId}) async {
    try {
      await _client.functions.invoke(
        'notify-call-request',
        body: {'channel_id': channelId},
      );
    } catch (e) {
      debugPrint('Call request notification failed: $e');
    }
  }
}
