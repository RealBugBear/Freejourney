import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/appointment.dart';
import '../../domain/models/trainer_client.dart';
import '../../domain/services/calendar_service.dart';
import '../providers/trainer_provider.dart';
import '../providers/trainer_discovery_provider.dart';
import '../widgets/trainer_location_picker_widget.dart';
import '../../../chat/presentation/navigation/chat_navigation.dart';
import '../../../chat/presentation/widgets/direct_messages_action.dart';

class TrainerDashboardScreen extends ConsumerStatefulWidget {
  const TrainerDashboardScreen({super.key});

  @override
  ConsumerState<TrainerDashboardScreen> createState() =>
      _TrainerDashboardScreenState();
}

class _TrainerDashboardScreenState extends ConsumerState<TrainerDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trainerDashboard),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.trainerTabTrainees),
            Tab(text: l10n.trainerTabCalendar),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inbox_outlined),
            tooltip: l10n.trainerRequestsTitle,
            onPressed: () => context.push(Routes.trainerRequests),
          ),
          const DirectMessagesAction(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(trainerClientsProvider);
              ref.invalidate(appointmentsProvider);
              ref.invalidate(trainerOpenInvitesProvider);
              ref.invalidate(incomingRequestsProvider);
              ref.invalidate(trainerRecentObservationsProvider);
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _TraineesTab(tabController: _tabController),
          const _AppointmentsTab(),
        ],
      ),
    );
  }
}

// ── Tab 1 — Trainees ─────────────────────────────────────────────────────────

class _TraineesTab extends ConsumerWidget {
  final TabController tabController;
  const _TraineesTab({required this.tabController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final clientsAsync = ref.watch(trainerClientsProvider);
    final appointmentsAsync = ref.watch(appointmentsProvider);
    final openInvitesAsync = ref.watch(trainerOpenInvitesProvider);
    final incomingRequestsAsync = ref.watch(incomingRequestsProvider);
    final observationsAsync = ref.watch(trainerRecentObservationsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(trainerClientsProvider.notifier).refresh();
        ref.invalidate(appointmentsProvider);
        ref.invalidate(trainerOpenInvitesProvider);
        ref.invalidate(incomingRequestsProvider);
        ref.invalidate(trainerRecentObservationsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          // ── Invite link section ─────────────────────────────────────────
          _InviteBanner(l10n: l10n, ref: ref),
          const _DiscoveryVisibilityCard(),
          _TrainerPriorityOverview(
            clients: clientsAsync.valueOrNull ?? const [],
            appointments: appointmentsAsync.valueOrNull ?? const [],
            openInviteCount: openInvitesAsync.valueOrNull?.length ?? 0,
            incomingRequestCount:
                incomingRequestsAsync.valueOrNull?.length ?? 0,
            observationCount: observationsAsync.valueOrNull?.length ?? 0,
            onOpenRequests: () => context.push(Routes.trainerRequests),
            onOpenCalendar: () => tabController.animateTo(1),
          ),
          _OpenInvitesCard(
              openInvites: openInvitesAsync.valueOrNull ?? const []),
          _RecentObservationsCard(
            observations: observationsAsync.valueOrNull ?? const [],
          ),
          const _SharedExperienceReviewCard(),
          if (kDebugMode) const _TrainerClientsDebugPanel(),

          // ── Clients ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'KLIENTEN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          clientsAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Center(
                child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(e.toString()),
            )),
            data: (clients) {
              if (clients.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.trainerNoClients,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                );
              }
              final appointments = appointmentsAsync.valueOrNull ?? [];
              return Column(
                children: clients
                    .map((c) => _ClientCard(
                          client: c,
                          appointments: appointments,
                          l10n: l10n,
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TrainerPriorityOverview extends StatelessWidget {
  const _TrainerPriorityOverview({
    required this.clients,
    required this.appointments,
    required this.openInviteCount,
    required this.incomingRequestCount,
    required this.observationCount,
    required this.onOpenRequests,
    required this.onOpenCalendar,
  });

  final List<TrainerClient> clients;
  final List<Appointment> appointments;
  final int openInviteCount;
  final int incomingRequestCount;
  final int observationCount;
  final VoidCallback onOpenRequests;
  final VoidCallback onOpenCalendar;

  int get _transitionCount => clients.where(_needsTransitionPlanning).length;

  int get _upcomingAppointmentCount => appointments
      .where((appointment) =>
          appointment.status != 'cancelled' &&
          appointment.status != 'done' &&
          (appointment.scheduledFor?.isAfter(DateTime.now()) ?? false))
      .length;

  bool _needsTransitionPlanning(TrainerClient client) {
    final hasOpenAppointment = appointments.any((appointment) =>
        appointment.traineeId == client.clientId &&
        appointment.status != 'cancelled' &&
        appointment.status != 'done' &&
        (appointment.isProposed ||
            (appointment.scheduledFor?.isAfter(DateTime.now()) ?? false)));
    return client.needsNextPackageAppointment && !hasOpenAppointment;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arbeitsübersicht',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Priorisiert nach Paketübergängen, Anfragen, Terminen und Beobachtungen.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _PriorityTile(
                  icon: Icons.flag_outlined,
                  label: 'Paketübergänge',
                  value: _transitionCount,
                  highlighted: _transitionCount > 0,
                ),
                _PriorityTile(
                  icon: Icons.link_outlined,
                  label: 'Offene Einladungen',
                  value: openInviteCount,
                ),
                _PriorityTile(
                  icon: Icons.inbox_outlined,
                  label: 'Neue Anfragen',
                  value: incomingRequestCount,
                  highlighted: incomingRequestCount > 0,
                  onTap: onOpenRequests,
                ),
                _PriorityTile(
                  icon: Icons.event_available_outlined,
                  label: 'Termine',
                  value: _upcomingAppointmentCount,
                  onTap: onOpenCalendar,
                ),
                _PriorityTile(
                  icon: Icons.edit_note_outlined,
                  label: 'Neue Beobachtungen',
                  value: observationCount,
                  highlighted: observationCount > 0,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriorityTile extends StatelessWidget {
  const _PriorityTile({
    required this.icon,
    required this.label,
    required this.value,
    this.highlighted = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = highlighted ? AppColors.primary : cs.onSurfaceVariant;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlighted
                ? AppColors.primary.withValues(alpha: 0.28)
                : AppColors.divider,
          ),
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.06)
              : Theme.of(context).colorScheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 10),
            Text(
              '$value',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenInvitesCard extends StatelessWidget {
  const _OpenInvitesCard({required this.openInvites});

  final List<TrainerOpenInvite> openInvites;

  @override
  Widget build(BuildContext context) {
    if (openInvites.isEmpty) return const SizedBox.shrink();
    final visible = openInvites.take(3).toList();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offene Einladungen',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            ...visible.map((invite) => _InviteCodeRow(invite: invite)),
            if (openInvites.length > visible.length)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${openInvites.length - visible.length} weitere Einladung${openInvites.length - visible.length == 1 ? '' : 'en'} offen',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InviteCodeRow extends StatelessWidget {
  const _InviteCodeRow({required this.invite});

  final TrainerOpenInvite invite;

  @override
  Widget build(BuildContext context) {
    final created = DateFormat('dd.MM.yyyy', 'de_DE').format(invite.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.link_outlined, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              invite.code,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Text(
            created,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _RecentObservationsCard extends StatelessWidget {
  const _RecentObservationsCard({required this.observations});

  final List<TrainerClientObservation> observations;

  @override
  Widget build(BuildContext context) {
    if (observations.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Neue Beobachtungen',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            ...observations.take(3).map(
                  (observation) => _ObservationPreview(
                    observation: observation,
                    onTap: () => context.push(
                      Routes.trainerClientDetail.replaceFirst(
                        ':clientId',
                        observation.clientId,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ObservationPreview extends StatelessWidget {
  const _ObservationPreview({
    required this.observation,
    this.onTap,
  });

  final TrainerClientObservation observation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final date =
        DateFormat('dd.MM. HH:mm', 'de_DE').format(observation.recordedAt);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.edit_note_outlined),
      title: Text(observation.clientName),
      subtitle: Text(
        '${observation.note}\n$date',
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}

class _SharedExperienceReviewCard extends StatelessWidget {
  const _SharedExperienceReviewCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: ListTile(
        leading: const Icon(Icons.rate_review_outlined),
        title: const Text('Geteilte Erfahrungen prüfen'),
        subtitle: const Text(
          'Moderierte Erfahrungsbeiträge aus laufenden Paketen im Blick behalten.',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(Routes.community),
      ),
    );
  }
}

class _TrainerClientsDebugPanel extends ConsumerWidget {
  const _TrainerClientsDebugPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final debugAsync = ref.watch(trainerClientsDebugProvider);
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          height: 1.35,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 12),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            leading: const Icon(Icons.bug_report_outlined, size: 18),
            title: Text(
              'Diagnose Trainer-Verknüpfung',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            subtitle: debugAsync.when(
              loading: () => const Text('Prüfe Datenbank...'),
              error: (e, _) => const Text('Fehler in der Diagnose'),
              data: (debug) {
                String? rowsLine;
                for (final line in debug.split('\n')) {
                  if (line.startsWith('get_trainer_clients rows:')) {
                    rowsLine = line;
                    break;
                  }
                }
                return Text(rowsLine ?? 'Zum Öffnen antippen');
              },
            ),
            trailing: IconButton(
              tooltip: 'Diagnose aktualisieren',
              icon: const Icon(Icons.refresh, size: 18),
              onPressed: () {
                ref.invalidate(trainerClientsDebugProvider);
                ref.invalidate(trainerClientsProvider);
              },
            ),
            children: [
              debugAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Diagnose Fehler: $e', style: textStyle),
                data: (debug) => Text(debug, style: textStyle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InviteBanner extends StatefulWidget {
  final AppLocalizations l10n;
  final WidgetRef ref;
  const _InviteBanner({required this.l10n, required this.ref});

  @override
  State<_InviteBanner> createState() => _InviteBannerState();
}

class _InviteBannerState extends State<_InviteBanner> {
  String? _code;
  bool _loading = false;

  String get _formattedCode {
    if (_code == null) return '';
    // Format 6-digit code as "XXX · XXX"
    final c = _code!.padLeft(6, '0');
    return '${c.substring(0, 3)} · ${c.substring(3)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.l10n.trainerMyLink,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (_code != null) ...[
            // Big readable code display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formattedCode,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4,
                    color: AppColors.primary,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Einmaliger Code — teile ihn mit deinem Klienten',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Code kopieren'),
                    onPressed: () => _copyCode(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: _loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 16),
                  label: const Text('Neu'),
                  onPressed: _loading ? null : () => _generate(context),
                  style: OutlinedButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ] else ...[
            // No code yet
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_link, size: 18),
                label: Text(_loading
                    ? 'Wird erstellt…'
                    : widget.l10n.trainerGenerateCode),
                onPressed: _loading ? null : () => _generate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _generate(BuildContext context) async {
    setState(() => _loading = true);
    try {
      final code = await widget.ref
          .read(trainerClientsProvider.notifier)
          .generateInviteCode();
      setState(() {
        _code = code;
        _loading = false;
      });
      if (context.mounted) _copyCode(context);
    } catch (e) {
      setState(() => _loading = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              duration: const Duration(seconds: 8)),
        );
      }
    }
  }

  void _copyCode(BuildContext context) {
    if (_code == null) return;
    Clipboard.setData(ClipboardData(text: _code!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code $_formattedCode kopiert!')),
    );
  }
}

class _DiscoveryVisibilityCard extends ConsumerStatefulWidget {
  const _DiscoveryVisibilityCard();

  @override
  ConsumerState<_DiscoveryVisibilityCard> createState() =>
      _DiscoveryVisibilityCardState();
}

class _DiscoveryVisibilityCardState
    extends ConsumerState<_DiscoveryVisibilityCard> {
  bool _expanded = false;
  bool _saving = false;
  LatLng? _pickedLocation;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(ownTrainerProfileProvider);

    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (profile) {
        if (profile == null || profile.hasLocation) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.warning.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_off_outlined,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Standort fehlt',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dein Trainerprofil ist aktiv, erscheint aber erst in der Trainersuche, wenn ein Standort gesetzt ist. Öffentlich wird nur ein ungefährer Pin angezeigt.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: TrainerLocationPickerWidget(
                      onLocationPicked: (latLng) =>
                          setState(() => _pickedLocation = latLng),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving
                        ? null
                        : () => setState(() => _expanded = !_expanded),
                    icon: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.location_on_outlined,
                    ),
                    label: Text(_expanded ? 'Schließen' : 'Standort setzen'),
                  ),
                  if (_expanded) ...[
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saving || _pickedLocation == null
                          ? null
                          : _saveLocation,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Speichern'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveLocation() async {
    final location = _pickedLocation;
    if (location == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(trainerProfileRepositoryProvider).updateLocation(
            location.latitude,
            location.longitude,
          );
      ref.invalidate(ownTrainerProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Standort gespeichert')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Standort konnte nicht gespeichert werden: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ClientCard extends ConsumerWidget {
  final TrainerClient client;
  final List<Appointment> appointments;
  final AppLocalizations l10n;

  const _ClientCard({
    required this.client,
    required this.appointments,
    required this.l10n,
  });

  bool get _needsAppointment {
    final hasOpenAppointment = appointments.any((a) =>
        a.traineeId == client.clientId &&
        a.status != 'cancelled' &&
        a.status != 'done' &&
        (a.isProposed || (a.scheduledFor?.isAfter(DateTime.now()) ?? false)));
    return !hasOpenAppointment && client.needsNextPackageAppointment;
  }

  bool get _isNearCompletion =>
      client.needsNextPackageAppointment && !_isComplete;
  bool get _isComplete => client.currentDay >= 28;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = client.currentDay / 28.0;

    Color badgeColor;
    String? badgeLabel;
    String buttonLabel;

    if (_isComplete) {
      badgeColor = AppColors.success;
      badgeLabel = 'Tag 28 ✓';
      buttonLabel = _needsAppointment
          ? l10n.trainerAppointmentMissing
          : l10n.trainerScheduleAppointment;
    } else if (_isNearCompletion) {
      badgeColor = AppColors.warning;
      badgeLabel = '${client.remainingTrainingDays} Tage übrig';
      buttonLabel = _needsAppointment
          ? 'Termin vorschlagen'
          : l10n.trainerScheduleAppointment;
    } else {
      badgeColor = AppColors.primary;
      badgeLabel = null;
      buttonLabel = l10n.trainerScheduleAppointment;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: badgeColor.withValues(alpha: 0.15),
                  child: Text(
                    client.displayName[0].toUpperCase(),
                    style: TextStyle(
                        color: badgeColor, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            client.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (badgeLabel != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                badgeLabel,
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: badgeColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        l10n.currentDay(client.currentDay, 28),
                        style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation(badgeColor),
              ),
            ),
            if (_needsAppointment) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(
                  'Noch ${client.remainingTrainingDays} Tage: Termin für das isometrische Training des nächsten Pakets vorschlagen.',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.insights_outlined, size: 20),
                  tooltip: 'Detail öffnen',
                  onPressed: () => context.push(
                    Routes.trainerClientDetail.replaceFirst(
                      ':clientId',
                      client.clientId,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  tooltip: 'Chat öffnen',
                  onPressed: () =>
                      _openClientChat(context, ref, client.clientId),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _needsAppointment
                          ? badgeColor
                          : AppColors.backgroundLight,
                      foregroundColor: _needsAppointment
                          ? AppColors.white
                          : AppColors.textPrimary,
                      elevation: 0,
                      minimumSize: const Size(0, 40),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    onPressed: () => context.push(
                      Routes.appointmentScheduler
                          .replaceFirst(':clientId', client.clientId),
                      extra: client,
                    ),
                    child: Text(
                      buttonLabel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openClientChat(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    await openDirectChatWithUser(context, ref, clientId);
  }
}

// ── Tab 2 — Appointments (Calendar) ─────────────────────────────────────────

class _AppointmentsTab extends ConsumerWidget {
  const _AppointmentsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(appointmentsProvider);

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (appointments) {
        if (appointments.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 56, color: AppColors.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    l10n.trainerNoAppointments,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(appointmentsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: appointments.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, i) =>
                _AppointmentTile(appointment: appointments[i], l10n: l10n),
          ),
        );
      },
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final AppLocalizations l10n;

  const _AppointmentTile({required this.appointment, required this.l10n});

  Color get _statusColor {
    switch (appointment.status) {
      case 'confirmed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      case 'done':
        return AppColors.textDisabled;
      default:
        return AppColors.primary;
    }
  }

  String _statusLabel(AppLocalizations l10n) {
    switch (appointment.status) {
      case 'confirmed':
        return l10n.appointmentStatusConfirmed;
      case 'cancelled':
        return l10n.appointmentStatusCancelled;
      case 'done':
        return l10n.appointmentStatusDone;
      default:
        return l10n.appointmentStatusPlanned;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = appointment.scheduledFor != null
        ? DateFormat('E, d. MMM · HH:mm', 'de_DE')
            .format(appointment.scheduledFor!)
        : '–';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: _statusColor.withValues(alpha: 0.12),
        child:
            Icon(Icons.calendar_today_outlined, size: 20, color: _statusColor),
      ),
      title: Text(
        appointment.traineeName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(date,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 13)),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statusLabel(l10n),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _statusColor),
            ),
          ),
        ],
      ),
      trailing: appointment.scheduledFor != null
          ? IconButton(
              icon: const Icon(Icons.event_available_outlined, size: 20),
              tooltip: l10n.appointmentOpenInCalendar,
              onPressed: () => _openInCalendar(context, appointment),
            )
          : null,
    );
  }

  Future<void> _openInCalendar(BuildContext context, Appointment appt) async {
    final shareOrigin = _shareOriginFor(context);
    final messenger = ScaffoldMessenger.of(context);

    // iOS deep link directly to the event in Calendar.app
    if (appt.calendarEventId != null) {
      final ts = appt.scheduledFor!.millisecondsSinceEpoch / 1000;
      final uri = Uri.parse('calshow:$ts');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }

    try {
      await CalendarService.instance.createCalendarEvent(
        title: '${appt.title} (mit ${appt.traineeName})',
        start: appt.scheduledFor!,
        duration: Duration(minutes: appt.durationMinutes),
        location: appt.location,
        description: appt.notes,
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Kalender konnte nicht geöffnet werden: $e')),
      );
    }
  }

  Rect _shareOriginFor(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      final size = MediaQuery.sizeOf(context);
      return Rect.fromLTWH(size.width / 2, size.height / 2, 1, 1);
    }
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }
}
