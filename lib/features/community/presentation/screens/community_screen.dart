import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../chat/domain/models/chat_channel.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../chat/presentation/widgets/direct_messages_action.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(chatChannelsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Erfahrungen'),
        actions: [
          const DirectMessagesAction(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 8),
              Text('Fehler beim Laden',
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(chatChannelsProvider),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
        data: (channels) {
          final community =
              channels.where((c) => c.type == ChannelType.community).toList();

          if (community.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.push_pin_outlined,
                      size: 64,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Noch keine geteilten Erfahrungen',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Schließe dein erstes Training ab, um Erfahrungen auf der Pinnwand zu sehen.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.55),
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: community.length,
            itemBuilder: (ctx, i) {
              final channel = community[i];
              return _CommunityChannelTile(
                channel: channel,
                onTap: () => context.push(
                  Routes.experienceFeed.replaceFirst(':channelId', channel.id),
                  extra: channel,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CommunityChannelTile extends StatelessWidget {
  const _CommunityChannelTile({required this.channel, required this.onTap});
  final ChatChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasUnread = channel.unreadCount > 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.secondary,
        child:
            const Icon(Icons.push_pin_outlined, color: Colors.white, size: 20),
      ),
      title: Text(
        'Pinnwand ${channel.channelDisplayName(AppLocalizations.of(context))}',
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: channel.lastMessageContent != null
          ? Text(
              channel.lastMessageContent!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: hasUnread
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            )
          : null,
      trailing: _buildTrailing(context, theme, hasUnread, channel),
      onTap: onTap,
    );
  }

  Widget? _buildTrailing(
    BuildContext context,
    ThemeData theme,
    bool hasUnread,
    ChatChannel channel,
  ) {
    final items = <Widget>[];
    if (channel.lastMessageAt != null) {
      items.add(Text(
        _formatTime(channel.lastMessageAt!),
        style: theme.textTheme.labelSmall?.copyWith(
          color: hasUnread
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.45),
        ),
      ));
    }
    if (hasUnread) {
      items.add(const SizedBox(height: 4));
      items.add(Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          channel.unreadCount > 99 ? '99+' : 'Neu',
          style: theme.textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ));
    }
    if (items.isEmpty) return null;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: items,
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    if (msgDay == today) return DateFormat.Hm().format(dt);
    if (today.difference(msgDay).inDays == 1) return 'Gestern';
    return DateFormat('dd.MM').format(dt);
  }
}
