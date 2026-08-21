// lib/features/chat/presentation/screens/chat_channel_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permission_handler/permission_handler.dart';

import '../../domain/models/chat_channel.dart';
import '../../domain/models/chat_message.dart';
import '../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';
import '../widgets/message_input_bar.dart';
import '../widgets/typing_indicator.dart';
import '../../../video/domain/models/video_call.dart';
import '../../../video/presentation/providers/video_providers.dart';
import '../../../video/presentation/widgets/incoming_call_listener.dart';
import '../../../trainer/domain/models/trainer_client.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';
import '../../../../config/launch_flags.dart';
import '../../../../core/l10n/active_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/navigation/app_router.dart';
import 'package:go_router/go_router.dart';

class ChatChannelScreen extends ConsumerStatefulWidget {
  const ChatChannelScreen({
    super.key,
    required this.channelId,
    this.channel,
  });

  final String channelId;

  /// Passed from the inbox for instant title display — may be null on deep link.
  final ChatChannel? channel;

  @override
  ConsumerState<ChatChannelScreen> createState() => _ChatChannelScreenState();
}

class _ChatChannelScreenState extends ConsumerState<ChatChannelScreen> {
  final _scrollController = ScrollController();
  bool _loadingOlder = false;
  List<ChatMessage> _olderMessages = [];

  @override
  void initState() {
    super.initState();
    // Mark channel as read when screen opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(markReadProvider.notifier).markRead(widget.channelId);
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 80 &&
        !_loadingOlder) {
      _loadMoreOlder();
    }
  }

  Future<void> _loadMoreOlder() async {
    final messages =
        ref.read(chatMessagesProvider(widget.channelId)).valueOrNull;
    final allMessages = [..._olderMessages, ...(messages ?? [])];
    if (allMessages.isEmpty) return;

    final oldest =
        allMessages.reduce((a, b) => a.createdAt.isBefore(b.createdAt) ? a : b);

    setState(() => _loadingOlder = true);
    try {
      final older = await ref
          .read(chatRepositoryProvider)
          .fetchOlderMessages(widget.channelId, before: oldest.createdAt);
      if (older.isNotEmpty) {
        setState(() => _olderMessages = [...older, ..._olderMessages]);
      }
    } finally {
      setState(() => _loadingOlder = false);
    }
  }

  void _sendMessage(String content) {
    ref.read(sendMessageProvider.notifier).send(widget.channelId, content);
    ref.invalidate(chatChannelsProvider);
    // Scroll to bottom after send.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startCall() async {
    appLogger.d('ChatChannelScreen: requesting permissions for trainer call');
    final statuses = await [Permission.camera, Permission.microphone].request();
    final cameraOk = statuses[Permission.camera]?.isGranted ?? false;
    final micOk = statuses[Permission.microphone]?.isGranted ?? false;

    if (!cameraOk || !micOk) {
      appLogger.e(
          'ChatChannelScreen: permissions denied camera=$cameraOk mic=$micOk');
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.chatCameraMicPermissionRequired),
        ),
      );
      return;
    }

    appLogger
        .d('ChatChannelScreen: starting call on channel ${widget.channelId}');
    VideoCall? call;
    try {
      call = await ref.read(startCallProvider.notifier).start(widget.channelId);
      if (call == null) {
        appLogger.e('ChatChannelScreen: startCall returned null');
        return;
      }
      appLogger
          .d('ChatChannelScreen: call created id=${call.id}, fetching token');
      if (!mounted) return;
      await openVideoCall(context, ref, call);
    } catch (e, st) {
      appLogger.e('ChatChannelScreen: _startCall failed',
          error: e, stackTrace: st);
      if (call != null) {
        await ref.read(endCallProvider.notifier).end(call.id);
      }
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.chatCallStartFailed('$e'))),
        );
      }
    }
  }

  Future<void> _proposeAppointment(
    WidgetRef ref, {
    String? clientId,
    bool reviewFlow = false,
  }) async {
    try {
      final client = await _appointmentClient(
        ref,
        clientId: clientId,
        reviewFlow: reviewFlow,
      );
      if (!mounted) return;
      context.push(
        Routes.appointmentScheduler.replaceFirst(':clientId', client.clientId),
        extra: reviewFlow
            ? {
                'client': client,
                'reviewChannelId': widget.channelId,
              }
            : client,
      );
    } catch (e, st) {
      appLogger.e('ChatChannelScreen: propose appointment failed',
          error: e, stackTrace: st);
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.chatAppointmentOpenFailed)),
      );
    }
  }

  Future<TrainerClient> _appointmentClient(
    WidgetRef ref, {
    String? clientId,
    bool reviewFlow = false,
  }) async {
    if (reviewFlow) {
      return _reviewApplicantClient();
    }

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final directClientId = clientId == currentUserId ? null : clientId;
    final resolvedClientId = directClientId ?? await _safePartnerId(ref);
    if (resolvedClientId == null) {
      throw StateError(
          'Client could not be found for appointment scheduling.');
    }

    final knownClients = ref.read(trainerClientsProvider).valueOrNull ?? [];
    for (final client in knownClients) {
      if (client.clientId == resolvedClientId) return client;
    }

    final profile = await Supabase.instance.client
        .from('profiles')
        .select('display_name')
        .eq('id', resolvedClientId)
        .maybeSingle();
    final l10n = await lookupActiveAppLocalizations();
    final displayName =
        (profile?['display_name'] as String?)?.trim() ?? l10n.chatUserFallback;

    return TrainerClient(
      relationshipId: '',
      clientId: resolvedClientId,
      displayName: displayName.isEmpty ? l10n.chatUserFallback : displayName,
      currentDay: 1,
      dailyStreak: 0,
    );
  }

  Future<TrainerClient> _reviewApplicantClient() async {
    final channel = await Supabase.instance.client
        .from('chat_channels')
        .select('application_id')
        .eq('id', widget.channelId)
        .maybeSingle();
    final applicationId = channel?['application_id'] as String?;
    if (applicationId == null) {
      throw StateError(
          'Application could not be found for the review channel.');
    }

    final application = await Supabase.instance.client
        .from('trainer_applications')
        .select('user_id, full_name, desired_display_name')
        .eq('id', applicationId)
        .maybeSingle();
    if (application == null) {
      throw StateError('Applicant could not be found.');
    }

    final applicantId = application['user_id'] as String?;
    if (applicantId == null) {
      throw StateError('Applicant could not be found.');
    }

    final l10n = await lookupActiveAppLocalizations();
    final desiredDisplayName =
        (application['desired_display_name'] as String?)?.trim();
    final fullName = (application['full_name'] as String?)?.trim();
    final displayName = desiredDisplayName?.isNotEmpty == true
        ? desiredDisplayName!
        : fullName?.isNotEmpty == true
            ? fullName!
            : l10n.chatApplicantFallback;

    return TrainerClient(
      relationshipId: '',
      clientId: applicantId,
      displayName: displayName,
      currentDay: 1,
      dailyStreak: 0,
    );
  }

  Future<String?> _safePartnerId(WidgetRef ref) async {
    final messagePartnerId = _messagePartnerId(ref);
    if (messagePartnerId != null) return messagePartnerId;

    try {
      final partnerId =
          await ref.read(chatPartnerIdProvider(widget.channelId).future);
      if (partnerId != null) return partnerId;
    } catch (e, st) {
      appLogger.e('ChatChannelScreen: chat partner provider failed',
          error: e, stackTrace: st);
    }

    try {
      return await _fetchPartnerId();
    } catch (e, st) {
      appLogger.e('ChatChannelScreen: chat partner fallback failed',
          error: e, stackTrace: st);
      return null;
    }
  }

  String? _messagePartnerId(WidgetRef ref) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return null;

    final messages = [
      ..._olderMessages,
      ...?ref.read(chatMessagesProvider(widget.channelId)).valueOrNull,
    ].reversed;

    for (final message in messages) {
      if (message.senderId != currentUserId) return message.senderId;
    }
    return null;
  }

  Future<String?> _fetchPartnerId() async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (currentUserId == null) return null;

    final rows = await Supabase.instance.client
        .from('chat_channel_members')
        .select('user_id')
        .eq('channel_id', widget.channelId)
        .neq('user_id', currentUserId)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    return list.first['user_id'] as String?;
  }

  void _sendCallRequest() {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatRequestVideoCallTitle),
        content: Text(l10n.chatRequestVideoCallBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(sendMessageProvider.notifier)
                  .sendCallRequest(widget.channelId);
            },
            child: Text(l10n.chatSendRequest),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(chatChannelsProvider).valueOrNull ?? const [];
    final channel = _findChannel(channels, widget.channelId) ?? widget.channel;
    final isDirect = channel?.type == ChannelType.direct;
    final isApplicationReview = channel?.type == ChannelType.applicationReview;
    final isModerator = channel?.isModerator ?? false;
    final isPractitioner = !isModerator && isDirect;
    final canModerateCall = isModerator && (isDirect || isApplicationReview);

    final messagesAsync = ref.watch(chatMessagesProvider(widget.channelId));
    ref.listen<AsyncValue<List<ChatMessage>>>(
      chatMessagesProvider(widget.channelId),
      (_, next) {
        if (next.hasValue) {
          ref.invalidate(chatChannelsProvider);
          ref.read(markReadProvider.notifier).markRead(widget.channelId);
        }
      },
    );

    final l10n = AppLocalizations.of(context);
    final partnerName = ref
            .watch(chatPartnerNameProvider(widget.channelId))
            .valueOrNull ??
        l10n.trainerFallbackName;

    return Scaffold(
      appBar: AppBar(
        title: isDirect
            ? Text(l10n.chatWithName(partnerName))
            : isApplicationReview
                ? Text(l10n.chatChannelTypeApplicationReview)
                : Text(
                    channel?.channelDisplayName(l10n) ??
                        l10n.trainerChatFallback,
                  ),
        actions: [
          // Trainer/Admin moderator: propose appointment (+ call, if enabled).
          if (canModerateCall) ...[
            IconButton(
              icon: const Icon(Icons.event_outlined),
              tooltip: l10n.trainerProposeAppointment,
              onPressed: () => _proposeAppointment(
                ref,
                reviewFlow: isApplicationReview,
              ),
            ),
            if (kVideoCallsEnabled)
              IconButton(
                icon: const Icon(Icons.videocam_outlined),
                tooltip: l10n.chatStartCall,
                onPressed: _startCall,
              ),
          ],
          // Practitioner: request video call.
          if (isPractitioner && kVideoCallsEnabled)
            IconButton(
              icon: const Icon(Icons.videocam_outlined),
              tooltip: l10n.chatRequestVideoCall,
              onPressed: _sendCallRequest,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.chatMessagesLoadFailed,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (realtimeMessages) {
                final allMessages = [
                  ..._olderMessages,
                  ...realtimeMessages,
                ];

                if (allMessages.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.chatEmptyThread,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: allMessages.length + (_loadingOlder ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (_loadingOlder && index == 0) {
                          return const Padding(
                            padding: EdgeInsets.all(8),
                            child: Center(
                                child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))),
                          );
                        }
                        final msgIndex = _loadingOlder ? index - 1 : index;
                        final msg = allMessages[msgIndex];
                        return MessageBubble(
                          message: msg,
                          isModerator: isModerator,
                          onDeleteRequested: (isModerator ||
                                  msg.isOwnMessage(_currentUserId()))
                              ? () => _confirmDelete(msg)
                              : null,
                          onAcceptCall: kVideoCallsEnabled && isModerator
                              ? _startCall
                              : null,
                          onProposeAppointment: canModerateCall
                              ? () => _proposeAppointment(
                                    ref,
                                    clientId: msg.senderId,
                                    reviewFlow: isApplicationReview,
                                  )
                              : null,
                          onOpenAppointmentProposals: () {
                            ref.invalidate(traineeProposalsProvider);
                            context.push(Routes.appointmentProposals);
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          TypingIndicator(channelId: widget.channelId),
          if (ref.watch(channelWritableProvider(widget.channelId)).valueOrNull ==
              false)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                AppLocalizations.of(context).chatWriteLockedNoRelationship,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            )
          else
            MessageInputBar(
              channel: channel ??
                  ChatChannel(
                    id: widget.channelId,
                    type: ChannelType.direct,
                    createdAt: DateTime.now(),
                    currentUserRole: MemberRole.member,
                    unreadCount: 0,
                  ),
              onSend: _sendMessage,
              onCallRequest:
                  kVideoCallsEnabled && isPractitioner ? _sendCallRequest : null,
              onTyping: () => ref
                  .read(chatRepositoryProvider)
                  .broadcastTyping(widget.channelId),
            ),
        ],
      ),
    );
  }

  ChatChannel? _findChannel(List<ChatChannel> channels, String channelId) {
    for (final channel in channels) {
      if (channel.id == channelId) return channel;
    }
    return null;
  }

  String _currentUserId() {
    return Supabase.instance.client.auth.currentUser?.id ?? '';
  }

  void _confirmDelete(ChatMessage message) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.chatDeleteMessageTitle),
        content: Text(l10n.chatDeleteMessageBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(deleteMessageProvider.notifier).delete(message.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.chatRemove),
          ),
        ],
      ),
    );
  }
}
