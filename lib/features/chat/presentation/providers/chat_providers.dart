import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/repositories/supabase_chat_repository.dart';
import '../../domain/models/chat_channel.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

// ── Repository ────────────────────────────────────────────────────────────────

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return SupabaseChatRepository();
});

// ── Channels ──────────────────────────────────────────────────────────────────

final chatChannelsProvider =
    FutureProvider.autoDispose<List<ChatChannel>>((ref) {
  return ref.read(chatRepositoryProvider).getChannels();
});

// ── Unread badge count ────────────────────────────────────────────────────────

final totalUnreadCountProvider = Provider.autoDispose<int>((ref) {
  return ref.watch(chatChannelsProvider).maybeWhen(
        data: (channels) => channels.fold(0, (sum, c) => sum + c.unreadCount),
        orElse: () => 0,
      );
});

/// Ungelesene Nachrichten nur in Direct-Channels (für DM-Tab-Badge).
final unreadDmCountProvider = Provider<int>((ref) {
  return ref.watch(chatChannelsProvider).maybeWhen(
        data: (channels) => channels
            .where((c) => c.type == ChannelType.direct)
            .fold(0, (sum, c) => sum + c.unreadCount),
        orElse: () => 0,
      );
});

// ── Messages stream ───────────────────────────────────────────────────────────

final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, channelId) {
  return ref.read(chatRepositoryProvider).watchMessages(channelId);
});

final callRequestsProvider = StreamProvider.autoDispose<List<ChatMessage>>(
  (ref) => ref.read(chatRepositoryProvider).watchCallRequests(),
);

// ── Typing users stream ───────────────────────────────────────────────────────

final typingUsersProvider =
    StreamProvider.autoDispose.family<Set<String>, String>((ref, channelId) {
  return ref.read(chatRepositoryProvider).watchTypingUsers(channelId);
});

// ── Send message notifier ─────────────────────────────────────────────────────

class SendMessageNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> send(String channelId, String content) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).sendMessage(channelId, content),
    );
    ref.invalidate(chatChannelsProvider);
  }

  Future<void> sendCallRequest(String channelId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).sendCallRequest(channelId),
    );
    ref.invalidate(chatChannelsProvider);
  }
}

final sendMessageProvider =
    AsyncNotifierProvider.autoDispose<SendMessageNotifier, void>(
  SendMessageNotifier.new,
);

// ── Delete message notifier ───────────────────────────────────────────────────

class DeleteMessageNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> delete(String messageId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(chatRepositoryProvider).deleteMessage(messageId),
    );
  }
}

final deleteMessageProvider =
    AsyncNotifierProvider.autoDispose<DeleteMessageNotifier, void>(
  DeleteMessageNotifier.new,
);

// ── Mark read notifier ────────────────────────────────────────────────────────

class MarkReadNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> markRead(String channelId) async {
    await ref.read(chatRepositoryProvider).markChannelRead(channelId);
    ref.invalidate(chatChannelsProvider);
  }
}

final markReadProvider =
    AsyncNotifierProvider.autoDispose<MarkReadNotifier, void>(
  MarkReadNotifier.new,
);

/// Whether the signed-in user may currently send into [channelId].
///
/// Calls the very predicate `messages_insert_member` delegates to, so the
/// composer and the policy cannot drift apart. The client cannot evaluate it
/// locally: `members_select_own` exposes only the user's own membership row,
/// so the other members of a direct channel are not readable from the app.
final channelWritableProvider =
    FutureProvider.family<bool, String>((ref, channelId) async {
  ref.watch(authStateProvider);
  if (Supabase.instance.client.auth.currentUser == null) return false;

  final result = await Supabase.instance.client.rpc(
    'can_write_chat_channel',
    params: {'p_channel_id': channelId},
  );
  return result == true;
});
