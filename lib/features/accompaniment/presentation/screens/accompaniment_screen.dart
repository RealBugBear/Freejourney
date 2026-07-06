import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/launch_flags.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../../core/onboarding/onboarding_hint_gate.dart';
import '../../../../core/onboarding/onboarding_hint_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../../../chat/presentation/navigation/chat_navigation.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../../chat/presentation/widgets/direct_messages_action.dart';
import '../../../trainer/domain/models/appointment.dart';
import '../../../trainer/presentation/providers/trainer_discovery_provider.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';

class AccompanimentScreen extends ConsumerWidget {
  const AccompanimentScreen({super.key});

  Future<void> _showConnectTrainerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    String? errorText;
    var connecting = false;

    final connected = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Mit Trainer verbinden'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Füge den Einladungslink oder den 6-stelligen Code ein, den du von deinem Trainer erhalten hast.',
              ),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Einladungslink oder Code',
                  hintText: 'A1B2C3 oder https://...',
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
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: connecting
                  ? null
                  : () async {
                      final code = _extractTrainerInviteCode(controller.text);
                      if (code == null) {
                        setDialogState(() {
                          errorText =
                              'Bitte gib einen gültigen 6-stelligen Code oder Einladungslink ein.';
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
                          errorText =
                              'Verbindung konnte nicht hergestellt werden: $e';
                        });
                      }
                    },
              child: connecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verbinden'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
    if (connected == true && context.mounted) {
      _invalidateTrainerConnectionState(ref);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trainer wurde verbunden.')),
      );
    }
  }

  Future<void> _showSwitchTrainerDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Begleitung wechseln'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nach dem Wechsel erscheint dein Verlauf beim neuen Trainer. Dein bisheriger Trainer sieht dich danach nicht mehr in seiner Klientenübersicht.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Einladungslink oder Code',
                hintText: 'A1B2C3 oder https://...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Wechsel bestätigen'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.isEmpty || !context.mounted) return;

    try {
      final inviteCode = _extractTrainerInviteCode(code);
      if (inviteCode == null) {
        throw Exception(
            'Bitte gib einen gültigen Einladungslink oder Code ein.');
      }
      await switchTrainer(inviteCode);
      _invalidateTrainerConnectionState(ref);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Begleitung wurde aktualisiert.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Wechsel konnte nicht gespeichert werden: $e')),
        );
      }
    }
  }

  Future<void> _confirmWithdrawRequest(
    BuildContext context,
    WidgetRef ref,
    ClientTrainerConnection request,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anfrage zurückziehen?'),
        content: Text(
          'Die Anfrage an ${request.displayName} wird zurückgezogen. Du kannst später erneut eine passende Begleitung anfragen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Anfrage zurückziehen'),
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
          const SnackBar(content: Text('Anfrage wurde zurückgezogen.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Anfrage konnte nicht zurückgezogen werden: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: const Text('Begleitung'),
        actions: [
          const DirectMessagesAction(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
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
                title: 'Geteilte Erfahrungen',
                subtitle:
                    'Moderierte Beobachtungen aus laufenden Paketen ansehen.',
                actionLabel: 'Erfahrungen öffnen',
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
              'Professionelle Begleitung',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Manche Übungen werden mit einer zweiten Person durchgeführt. Dabei geht es nicht um Krafttraining, sondern um klares Spüren von Richtung, Bewegung und Widerstand. Ein geschulter Trainer kann dich dabei sicher anleiten.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 10),
            const _PlainInfoRow(
              icon: Icons.flag_outlined,
              text: 'Besonders relevant am Anfang eines Pakets.',
            ),
            const _PlainInfoRow(
              icon: Icons.self_improvement,
              text:
                  'Deine täglichen rhythmischen Einheiten bleiben selbstgeführt.',
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
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Noch keine Begleitung verbunden',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Du kannst dein Paket weiter selbstgeführt üben und bei Bedarf eine professionelle Begleitung für Partnerübungen oder Gespräche finden.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onFindTrainer,
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('Trainer finden'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onConnectWithLink,
              icon: const Icon(Icons.link_outlined),
              label: const Text('Einladungslink eingeben'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onContinue,
              child: const Text('Ohne Trainer fortfahren'),
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
                            'Reflexprofil-Freigabe',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Du kannst festlegen, ob der verbundene Trainer '
                            'die abgeschlossenen Reflexprofile sehen darf. '
                            'Das gilt nur, solange diese Begleitung aktiv ist.',
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
          'Freigabe konnte nicht geladen werden: $error',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
      data: (isShared) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: isShared,
        title: Text(profile.displayName),
        subtitle: Text(
          isShared
              ? 'Der verbundene Trainer darf dieses Reflexprofil sehen.'
              : 'Nicht für den verbundenen Trainer freigegeben.',
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
                    'Reflexprofil-Freigabe konnte nicht gespeichert werden: $e',
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
                    proposals.length == 1
                        ? '1 offener Terminvorschlag'
                        : '${proposals.length} offene Terminvorschläge',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    proposalsAsync.isLoading
                        ? 'Terminvorschläge werden geladen ...'
                        : 'Wähle einen passenden Termin direkt in deiner Begleitung aus.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: proposalsAsync.isLoading ? null : onOpen,
                    icon: const Icon(Icons.arrow_forward_outlined),
                    label: const Text('Vorschläge ansehen'),
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
                        'Anfrage offen bei ${request.displayName}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        extraRequestCount > 0
                            ? '$extraRequestCount weitere Anfrage${extraRequestCount == 1 ? '' : 'n'} offen'
                            : 'Du wirst informiert, sobald die Anfrage angenommen wurde.',
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
                  label: const Text('Mehr Trainer'),
                ),
                OutlinedButton.icon(
                  onPressed: onConnectWithLink,
                  icon: const Icon(Icons.link_outlined),
                  label: const Text('Einladungslink'),
                ),
                TextButton.icon(
                  onPressed: onWithdraw,
                  icon: const Icon(Icons.close_outlined),
                  label: const Text('Anfrage zurückziehen'),
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
  });

  final String trainerName;
  final int unreadMessages;
  final VoidCallback onMessage;
  final VoidCallback onAppointments;
  final VoidCallback onFindAnother;
  final VoidCallback onSwitchWithCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        'Aktive Begleitung',
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
                  label: const Text('Nachricht'),
                ),
                Badge(
                  isLabelVisible: proposalCount > 0,
                  label: Text('$proposalCount'),
                  child: OutlinedButton.icon(
                    onPressed: onAppointments,
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('Terminvorschläge'),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Text(
              'Nächste Termine',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              Text(
                'Noch keine geplanten Termine.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              )
            else
              ...upcoming.map((a) => _AppointmentRow(appointment: a)),
            const Divider(height: 28),
            Text(
              'Begleitung wechseln',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Beim Wechsel sieht dein neuer Trainer deinen Verlauf. Dein bisheriger Trainer verliert den Zugriff auf deine Klientenübersicht.',
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
                  label: const Text('Trainer finden'),
                ),
                OutlinedButton.icon(
                  onPressed: onSwitchWithCode,
                  icon: const Icon(Icons.key_outlined),
                  label: const Text('Code eingeben'),
                ),
              ],
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
    final cs = Theme.of(context).colorScheme;
    final dt = appointment.scheduledFor!;
    final dateLabel = DateFormat('EEE, d. MMM · HH:mm', 'de_DE').format(dt);
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
                    'für $profileLabel',
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
