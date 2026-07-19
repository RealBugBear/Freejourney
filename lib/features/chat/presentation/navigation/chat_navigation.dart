import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/repositories/supabase_chat_repository.dart';
import '../../domain/models/chat_channel.dart';
import '../providers/chat_providers.dart';

String directChannelRoute(String channelId) =>
    Routes.dmChannel.replaceFirst(':channelId', channelId);

void openDirectChannel(
  BuildContext context,
  ChatChannel channel,
) {
  context.push(directChannelRoute(channel.id), extra: channel);
}

Future<void> openDirectChatWithUser(
  BuildContext context,
  WidgetRef ref,
  String otherUserId,
) async {
  try {
    final channel = await SupabaseChatRepository().getOrCreateDirectChannel(
      otherUserId,
    );
    ref.invalidate(chatChannelsProvider);
    if (context.mounted) {
      openDirectChannel(context, channel);
    }
  } catch (e) {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.chatOpenFailed('$e'))),
    );
  }
}
