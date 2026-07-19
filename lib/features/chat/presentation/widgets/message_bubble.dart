import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isModerator,
    this.onDeleteRequested,
    this.onAcceptCall,
    this.onProposeAppointment,
    this.onOpenAppointmentProposals,
  });

  final ChatMessage message;
  final bool isModerator;
  final VoidCallback? onDeleteRequested;
  final VoidCallback? onAcceptCall;
  final VoidCallback? onProposeAppointment;
  final VoidCallback? onOpenAppointmentProposals;

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final isOwn = message.isOwnMessage(currentUserId);

    if (message.isDeleted) return _DeletedBubble(isOwn: isOwn);
    if (message.isBotResponse) return _BotBubble(message: message);
    if (message.isCallRequest) {
      return _CallRequestBubble(
        isOwn: isOwn,
        isModerator: isModerator,
        onAccept: isModerator ? onAcceptCall : null,
        onProposeAppointment: isModerator ? onProposeAppointment : null,
      );
    }
    if (message.isAppointmentProposalNotice) {
      return _AppointmentProposalBubble(
        message: message,
        isOwn: isOwn,
        onOpenAppointmentProposals: isOwn ? null : onOpenAppointmentProposals,
      );
    }

    final theme = Theme.of(context);
    final canDelete = isOwn || isModerator;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: canDelete ? onDeleteRequested : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.74),
          decoration: BoxDecoration(
            color: isOwn
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isOwn ? 16 : 4),
              bottomRight: Radius.circular(isOwn ? 4 : 16),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isOwn ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateFormat.Hm().format(message.createdAt.toLocal()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isOwn
                      ? Colors.white.withValues(alpha: 0.65)
                      : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension _ChatMessagePresentation on ChatMessage {
  bool get isAppointmentProposalNotice {
    final normalised = content.toLowerCase();
    return normalised.contains('terminvorschlag') ||
        normalised.contains('terminvorschläge');
  }
}

class _AppointmentProposalBubble extends StatelessWidget {
  const _AppointmentProposalBubble({
    required this.message,
    required this.isOwn,
    this.onOpenAppointmentProposals,
  });

  final ChatMessage message;
  final bool isOwn;
  final VoidCallback? onOpenAppointmentProposals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showAction = !isOwn && onOpenAppointmentProposals != null;

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isOwn ? 16 : 4),
            bottomRight: Radius.circular(isOwn ? 4 : 16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event_available_outlined,
                  size: 18,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).chatAppointmentProposal,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              message.content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            if (showAction) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: onOpenAppointmentProposals,
                icon: const Icon(Icons.arrow_forward_outlined, size: 18),
                label: Text(AppLocalizations.of(context).chatViewProposal),
              ),
            ],
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                DateFormat.Hm().format(message.createdAt.toLocal()),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onTertiaryContainer
                      .withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeletedBubble extends StatelessWidget {
  const _DeletedBubble({required this.isOwn});
  final bool isOwn;

  @override
  Widget build(BuildContext context) => Align(
        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            AppLocalizations.of(context).chatMessageRemoved,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey.shade500,
              fontSize: 13,
            ),
          ),
        ),
      );
}

class _BotBubble extends StatelessWidget {
  const _BotBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(Icons.smart_toy_outlined,
                  size: 13, color: theme.colorScheme.onSecondaryContainer),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context).chatAssistantName,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Text(message.content,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
          ],
        ),
      ),
    );
  }
}

class _CallRequestBubble extends StatelessWidget {
  const _CallRequestBubble({
    required this.isOwn,
    required this.isModerator,
    this.onAccept,
    this.onProposeAppointment,
  });
  final bool isOwn;
  final bool isModerator;
  final VoidCallback? onAccept;
  final VoidCallback? onProposeAppointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showActions =
        !isOwn && (onAccept != null || onProposeAppointment != null);

    return Align(
      alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.80,
        ),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam_outlined,
                    color: Colors.teal.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  _title(l10n),
                  style: TextStyle(
                    color: Colors.teal.shade800,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onAccept != null)
                    FilledButton.tonal(
                      onPressed: onAccept,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.teal.shade100,
                        foregroundColor: Colors.teal.shade900,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppLocalizations.of(context).trainerRequestAccept,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  if (onAccept != null && onProposeAppointment != null)
                    const SizedBox(width: 8),
                  if (onProposeAppointment != null)
                    OutlinedButton(
                      onPressed: onProposeAppointment,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal.shade900,
                        side: BorderSide(color: Colors.teal.shade300),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        AppLocalizations.of(context).trainerAppointmentAction,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _title(AppLocalizations l10n) {
    if (isOwn) {
      return isModerator
          ? l10n.chatCallRequestSentAsTrainer
          : l10n.chatCallRequestSentAsClient;
    }
    return isModerator
        ? l10n.chatCallRequestIncomingAsTrainer
        : l10n.chatCallRequestIncomingAsClient;
  }
}
