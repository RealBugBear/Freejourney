import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/chat_channel.dart';
import '../navigation/chat_navigation.dart';
import '../providers/chat_providers.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';

class DmScreen extends ConsumerWidget {
  const DmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelsAsync = ref.watch(chatChannelsProvider);
    final trainerIdAsync = ref.watch(clientTrainerIdProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(Routes.profile);
            }
          },
        ),
        title: Text(l10n.profileMessages),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(chatChannelsProvider),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      floatingActionButton: trainerIdAsync.valueOrNull != null
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text(l10n.dmChatWithTrainer),
              onPressed: () {
                final id = trainerIdAsync.valueOrNull;
                if (id != null) _openTrainerChat(context, ref, id);
              },
            )
          : null,
      body: channelsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(
          onRetry: () => ref.invalidate(chatChannelsProvider),
        ),
        data: (channels) {
          final visible = channels
              .where((c) =>
                  c.type == ChannelType.direct ||
                  c.type == ChannelType.applicationReview)
              .toList();
          if (visible.isEmpty) return const _EmptyState();
          return ListView.builder(
            itemCount: visible.length,
            itemBuilder: (ctx, i) => _DmListTile(
              channel: visible[i],
              onTap: () => openDirectChannel(context, visible[i]),
            ),
          );
        },
      ),
    );
  }
}

Future<void> _openTrainerChat(
  BuildContext context,
  WidgetRef ref,
  String trainerId,
) async {
  await openDirectChatWithUser(context, ref, trainerId);
}

class _DmListTile extends ConsumerWidget {
  const _DmListTile({required this.channel, required this.onTap});
  final ChatChannel channel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasUnread = channel.unreadCount > 0;
    final title = channel.type == ChannelType.applicationReview
        ? channel.channelDisplayName(l10n)
        : ref.watch(chatPartnerNameProvider(channel.id)).valueOrNull ??
            channel.channelDisplayName(l10n);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary,
        child: Icon(
          channel.type == ChannelType.applicationReview
              ? Icons.assignment_outlined
              : Icons.person_outline,
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        title,
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
                fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              ),
            )
          : null,
      trailing: channel.lastMessageAt != null
          ? Text(
              _formatTime(context, channel.lastMessageAt!),
              style: theme.textTheme.labelSmall?.copyWith(
                color: hasUnread
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
              ),
            )
          : null,
      onTap: onTap,
    );
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(dt.year, dt.month, dt.day);
    if (msgDay == today) return DateFormat.Hm(locale).format(dt);
    if (today.difference(msgDay).inDays == 1) return l10n.chatYesterday;
    return DateFormat.Md(locale).format(dt);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(l10n.chatNoMessagesYet,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.dmEmptyBody,
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
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 8),
          Text(l10n.errorLoadFailedInline,
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text(l10n.retry)),
        ],
      ),
    );
  }
}
