import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/launch_flags.dart';
import '../../../../core/l10n/app_languages.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/onboarding/onboarding_hint_gate.dart';
import '../../../../core/onboarding/onboarding_hint_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../../../chat/presentation/navigation/chat_navigation.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../chat/presentation/widgets/direct_messages_action.dart';
import '../../../trainer/domain/models/appointment.dart';
import '../../../trainer/presentation/providers/trainer_discovery_provider.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';
import '../widgets/end_accompaniment_dialog.dart';

class AccompanimentScreen extends ConsumerWidget {
  const AccompanimentScreen({super.key});

  Future<void> _showConnectTrainerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    String? errorText;
    var connecting = false;

    final connected = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.trainerOnboardingInviteTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.accompanimentConnectBody),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: l10n.accompanimentInviteLinkOrCodeLabel,
                  hintText: l10n.accompanimentInviteLinkOrCodeHint,
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
                onChanged: (_) => setDialogState(() => errorText = null),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: connecting ? null : () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: connecting
                  ? null
                  : () async {
                      final code = _extractTrainerInviteCode(controller.text);
                      if (code == null) {
                        setDialogState(() {
                          errorText = l10n.accompanimentConnectInvalidInvite;
                        });
                        return;
                      }

                      setDialogState(() => connecting = true);
                      try {
                        await acceptInvite(code);
                        if (ctx.mounted) Navigator.pop(ctx, true);
                      } catch (e) {
                        setDialogState(() {
                          connecting = false;
                          errorText = l10n.accompanimentConnectFailed('$e');
                        });
                      }
                    },
              child: connecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.accompanimentConnectAction),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (connected == true && context.mounted) {
      _invalidateTrainerConnectionState(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accompanimentConnectedSuccess)),
      );
    }
  }

  Future<void> _showSwitchTrainerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accompanimentSwitchTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.accompanimentSwitchBody),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: l10n.accompanimentInviteLinkOrCodeLabel,
                hintText: l10n.accompanimentInviteLinkOrCodeHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.accompanimentSwitchConfirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty || !context.mounted) return;

    try {
      final inviteCode = _extractTrainerInviteCode(code);
      if (inviteCode == null) {
        throw Exception(l10n.accompanimentSwitchInvalidInvite);
      }
      await switchTrainer(inviteCode);
      _invalidateTrainerConnectionState(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accompanimentSwitchUpdated)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accompanimentSwitchFailed('$e'))),
        );
      }
    }
  }

  Future<void> _endAccompaniment(
    BuildContext context,
    WidgetRef ref, {
    required String trainerId,
    required String relationshipId,
  }) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showEndAccompanimentDialog(context);
    if (confirmed != true) return;

    try {
      await endTrainerRelationship(
        ref,
        trainerId: trainerId,
        relationshipId: relationshipId,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.accompanimentEnded)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accompanimentEndFailed('$e'))),
        );
      }
    }
  }

  Future<void> _confirmWithdrawRequest(
    BuildContext context,
    WidgetRef ref,
    ClientTrainerConnection request,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accompanimentWithdrawTitle),
        content: Text(l10n.accompanimentWithdrawBody(request.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.accompanimentWithdrawAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await withdrawDiscoveryRequest(ref, request.relationshipId);
      ref.invalidate(clientTrainerConnectionsProvider);
      ref.invalidate(clientTrainerProvider);
      ref.invalidate(clientTrainerIdProvider);
      ref.invalidate(chatChannelsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.accompanimentWithdrawSuccess)),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accompanimentWithdrawFailed('$e')),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final connections =
        ref.watch(clientTrainerConnectionsProvider).valueOrNull ?? const [];
    final activeConnection =
        connections.where((connection) => connection.isActive).firstOrNull;
    final pendingConnections =
        connections.where((connection) => connection.isPending).toList();
    final unreadDm = ref.watch(unreadDmCountProvider);
    final hasTrainer = activeConnection != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accompanimentTitle),
        actions: [
          const DirectMessagesAction(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: OnboardingHintGate(
        hint: AppOnboardingHint.accompaniment,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _IsometricExplanationCard(),
            const SizedBox(height: 12),
            if (hasTrainer)
              _ConnectedTrainerCard(
                trainerName: activeConnection.displayName,
                unreadMessages: unreadDm,
                onMessage: () => openDirectChatWithUser(
                  context,
                  ref,
                  activeConnection.trainerId,
                ),
                onAppointments: () => context.push(Routes.appointmentProposals),
                onFindAnother: () => context.push(Routes.trainerDiscovery),
                onSwitchWithCode: () => _showSwitchTrainerDialog(context, ref),
                onEndAccompaniment: () => _endAccompaniment(
                  context,
                  ref,
                  trainerId: activeConnection.trainerId,
                  relationshipId: activeConnection.relationshipId,
                ),
              )
            else if (pendingConnections.isNotEmpty)
              _PendingRequestCard(
                request: pendingConnections.first,
                extraRequestCount: pendingConnections.length - 1,
                onFindMore: () => context.push(Routes.trainerDiscovery),
                onConnectWithLink: () =>
                    _showConnectTrainerDialog(context, ref),
                onWithdraw: () => _confirmWithdrawRequest(
                  context,
                  ref,
                  pendingConnections.first,
                ),
              )
            else
              _NoTrainerCard(
                onFindTrainer: () => context.push(Routes.trainerDiscovery),
                onConnectWithLink: () =>
                    _showConnectTrainerDialog(context, ref),
                onContinue: () => context.go(Routes.dashboard),
              ),
            if (activeConnection != null) const SizedBox(height: 12),
            if (activeConnection != null)
              _OpenAppointmentProposalsCard(
                onOpen: () {
                  ref.invalidate(traineeProposalsProvider);
                  context.push(Routes.appointmentProposals);
                },
              ),
            if (activeConnection != null) const SizedBox(height: 12),
            if (activeConnection != null)
              _ReflexProfileSharingCard(connection: activeConnection),
            if (kCommunityEnabled) ...[
              const SizedBox(height: 12),
              _ActionSection(
                icon: Icons.rate_review_outlined,
                title: l10n.accompanimentSharedExperiencesTitle,
                subtitle: l10n.accompanimentSharedExperiencesBody,
                actionLabel: l10n.accompanimentSharedExperiencesAction,
                onTap: () => context.push(Routes.community),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IsometricExplanationCard extends StatelessWidget {
  const _IsometricExplanationCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.accessibility_new_outlined,
                color: AppColors.primary),
            const SizedBox(height: 10),
            Text(
              l10n.accompanimentProfessionalTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.accompanimentProfessionalBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 10),
            _PlainInfoRow(
              icon: Icons.flag_outlined,
              text: l10n.accompanimentPackageStartNote,
            ),
            _PlainInfoRow(
              icon: Icons.self_improvement,
              text: l10n.accompanimentDailySessionsNote,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoTrainerCard extends StatelessWidget {
  const _NoTrainerCard({
    required this.onFindTrainer,
    required this.onConnectWithLink,
    required this.onContinue,
  });

  final VoidCallback onFindTrainer;
  final VoidCallback onConnectWithLink;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accompanimentNoTrainerTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.accompanimentNoTrainerBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onFindTrainer,
              icon: const Icon(Icons.person_search_outlined),
              label: Text(l10n.trainingFindTrainer),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onConnectWithLink,
              icon: const Icon(Icons.link_outlined),
              label: Text(l10n.accompanimentEnterInviteLink),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onContinue,
              child: Text(l10n.accompanimentContinueWithoutTrainer),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReflexProfileSharingCard extends ConsumerWidget {
  const _ReflexProfileSharingCard({required this.connection});

  final ClientTrainerConnection connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final summariesAsync = ref.watch(profilesWithAssessmentsProvider);

    return summariesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (summaries) {
        final completed = summaries
            .where((summary) => summary.latestAssessment?.isCompleted == true)
            .toList();
        if (completed.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.assignment_ind_outlined,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.accompanimentProfileSharingTitle,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.accompanimentProfileSharingBody,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...completed.map(
                  (summary) => _ReflexProfileShareTile(
                    profile: summary.profile,
                    trainerId: connection.trainerId,
                    relationshipId: connection.relationshipId,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReflexProfileShareTile extends ConsumerWidget {
  const _ReflexProfileShareTile({
    required this.profile,
    required this.trainerId,
    required this.relationshipId,
  });

  final ReflexSubjectProfile profile;
  final String trainerId;
  final String relationshipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lookup = ReflexTrainerShareLookup(
      subjectProfileId: profile.id,
      trainerId: trainerId,
    );
    final shareAsync = ref.watch(reflexProfileTrainerShareProvider(lookup));

    return shareAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.accompanimentProfileSharingLoadFailed('$error'),
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (isShared) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: isShared,
        title: Text(profile.displayName),
        subtitle: Text(
          isShared
              ? l10n.accompanimentProfileShared
              : l10n.accompanimentProfileNotShared,
        ),
        onChanged: (enabled) async {
          try {
            if (enabled) {
              await grantReflexProfileTrainerShare(
                ref,
                subjectProfileId: profile.id,
                trainerId: trainerId,
                relationshipId: relationshipId,
              );
            } else {
              await revokeReflexProfileTrainerShare(
                ref,
                subjectProfileId: profile.id,
                trainerId: trainerId,
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    l10n.accompanimentProfileSharingSaveFailed('$e'),
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }
}

class _OpenAppointmentProposalsCard extends ConsumerWidget {
  const _OpenAppointmentProposalsCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final proposalsAsync = ref.watch(traineeProposalsProvider);
    final proposals = proposalsAsync.valueOrNull ?? const <Appointment>[];
    if (proposals.isEmpty && !proposalsAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.event_available_outlined,
                color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.accompanimentProposalCount(proposals.length),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    proposalsAsync.isLoading
                        ? l10n.accompanimentProposalsLoading
                        : l10n.accompanimentProposalsBody,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: proposalsAsync.isLoading ? null : onOpen,
                    icon: const Icon(Icons.arrow_forward_outlined),
                    label: Text(l10n.accompanimentViewProposals),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({
    required this.request,
    required this.extraRequestCount,
    required this.onFindMore,
    required this.onConnectWithLink,
    required this.onWithdraw,
  });

  final ClientTrainerConnection request;
  final int extraRequestCount;
  final VoidCallback onFindMore;
  final VoidCallback onConnectWithLink;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.hourglass_top_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accompanimentPendingRequestTitle(
                          request.displayName,
                        ),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        extraRequestCount > 0
                            ? l10n.accompanimentExtraPendingRequests(
                                extraRequestCount,
                              )
                            : l10n.accompanimentPendingRequestAcceptedNotice,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onFindMore,
                  icon: const Icon(Icons.person_search_outlined),
                  label: Text(l10n.accompanimentMoreTrainers),
                ),
                OutlinedButton.icon(
                  onPressed: onConnectWithLink,
                  icon: const Icon(Icons.link_outlined),
                  label: Text(l10n.accompanimentInviteLinkShort),
                ),
                TextButton.icon(
                  onPressed: onWithdraw,
                  icon: const Icon(Icons.close_outlined),
                  label: Text(l10n.accompanimentWithdrawAction),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectedTrainerCard extends ConsumerWidget {
  const _ConnectedTrainerCard({
    required this.trainerName,
    required this.unreadMessages,
    required this.onMessage,
    required this.onAppointments,
    required this.onFindAnother,
    required this.onSwitchWithCode,
    required this.onEndAccompaniment,
  });

  final String trainerName;
  final int unreadMessages;
  final VoidCallback onMessage;
  final VoidCallback onAppointments;
  final VoidCallback onFindAnother;
  final VoidCallback onSwitchWithCode;
  final VoidCallback onEndAccompaniment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final proposalCount =
        ref.watch(traineeProposalsProvider).valueOrNull?.length ?? 0;
    final now = DateTime.now();
    final upcoming = (ref
                .watch(traineeConfirmedAppointmentsProvider)
                .valueOrNull ??
            [])
        .where((a) => a.scheduledFor != null && a.scheduledFor!.isAfter(now))
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person_outline)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trainerName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      Text(
                        l10n.accompanimentActiveGuidance,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (unreadMessages > 0)
                  Badge(
                      label: Text(
                          unreadMessages > 99 ? '99+' : '$unreadMessages')),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: onMessage,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(l10n.accompanimentMessage),
                ),
                Badge(
                  isLabelVisible: proposalCount > 0,
                  label: Text('$proposalCount'),
                  child: OutlinedButton.icon(
                    onPressed: onAppointments,
                    icon: const Icon(Icons.event_available_outlined),
                    label: Text(l10n.accompanimentAppointmentProposals),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Text(
              l10n.accompanimentNextAppointments,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              Text(
                l10n.accompanimentNoAppointments,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              )
            else
              ...upcoming.map((a) => _AppointmentRow(appointment: a)),
            const Divider(height: 28),
            Text(
              l10n.accompanimentSwitchTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.accompanimentSwitchAccessBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onFindAnother,
                  icon: const Icon(Icons.person_search_outlined),
                  label: Text(l10n.trainingFindTrainer),
                ),
                OutlinedButton.icon(
                  onPressed: onSwitchWithCode,
                  icon: const Icon(Icons.key_outlined),
                  label: Text(l10n.accompanimentEnterCode),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                key: const Key('accompaniment_end_action'),
                onPressed: onEndAccompaniment,
                style: TextButton.styleFrom(foregroundColor: cs.error),
                child: Text(l10n.accompanimentEndAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentRow extends StatelessWidget {
  const _AppointmentRow({required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final dt = appointment.scheduledFor!;
    final dateLabel = formatAccompanimentAppointmentDate(
      dt,
      Localizations.localeOf(context),
    );
    final isGespraech = appointment.title.toLowerCase().contains('gespräch') ||
        appointment.title.toLowerCase().contains('gespräch') ||
        appointment.title.toLowerCase().contains('gespraech');
    final profileLabel = appointment.profileLabel;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              isGespraech
                  ? Icons.forum_outlined
                  : Icons.accessibility_new_outlined,
              size: 15,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (profileLabel != null)
                  Text(
                    l10n.accompanimentAppointmentForProfile(profileLabel),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
              ],
            ),
          ),
          Text(
            appointment.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _PlainInfoRow extends StatelessWidget {
  const _PlainInfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  const _ActionSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(subtitle, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 12),
                    Text(
                      actionLabel,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

void _invalidateTrainerConnectionState(WidgetRef ref) {
  ref.invalidate(clientTrainerProvider);
  ref.invalidate(clientTrainerIdProvider);
  ref.invalidate(clientTrainerConnectionsProvider);
  ref.invalidate(chatChannelsProvider);
}

String? _extractTrainerInviteCode(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  final compact = trimmed.replaceAll(RegExp(r'\s'), '').toUpperCase();
  if (RegExp(r'^[A-Z0-9]{6}$').hasMatch(compact)) return compact;

  final uri = Uri.tryParse(trimmed);
  if (uri != null) {
    for (final key in const ['code', 'invite', 'invite_code', 'trainer_code']) {
      final value = uri.queryParameters[key];
      if (value == null) continue;
      final parsed = _extractTrainerInviteCode(value);
      if (parsed != null) return parsed;
    }

    for (final segment in uri.pathSegments.reversed) {
      final parsed = _extractTrainerInviteCode(segment);
      if (parsed != null) return parsed;
    }
  }

  final tokens = trimmed
      .split(RegExp(r'[^A-Za-z0-9]+'))
      .map((token) => token.trim().toUpperCase())
      .where((token) => RegExp(r'^[A-Z0-9]{6}$').hasMatch(token))
      .toList();
  if (tokens.length == 1) return tokens.single;
  return null;
}

String formatAccompanimentAppointmentDate(DateTime value, Locale locale) {
  final localeName = locale.toLanguageTag();
  // DE keeps its fixed 24h format; every other locale inherits the
  // locale-aware default (en-US: "Wed, Jul 15 · 3:30 PM").
  if (locale.languageCode == AppLanguages.sourceCode) {
    return DateFormat('EEE, d. MMM · HH:mm', localeName).format(value);
  }
  return '${DateFormat.MMMEd(localeName).format(value)} · '
      '${DateFormat.jm(localeName).format(value)}';
}
