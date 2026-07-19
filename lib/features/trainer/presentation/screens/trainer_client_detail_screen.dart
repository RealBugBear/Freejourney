import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../assessment/domain/models/reflex_profile_assessment.dart';
import '../../../assessment/domain/reflex_questionnaire.dart';
import '../../domain/models/appointment.dart';
import '../../domain/models/trainer_client.dart';
import '../../../chat/presentation/navigation/chat_navigation.dart';
import '../providers/trainer_provider.dart';

class TrainerClientDetailScreen extends ConsumerStatefulWidget {
  final String clientId;
  const TrainerClientDetailScreen({super.key, required this.clientId});

  @override
  ConsumerState<TrainerClientDetailScreen> createState() =>
      _TrainerClientDetailScreenState();
}

class _TrainerClientDetailScreenState
    extends ConsumerState<TrainerClientDetailScreen> {
  late TextEditingController _notesController;
  TrainerClient? _client;
  bool _notesDirty = false;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _initClient(TrainerClient client) {
    if (_client?.clientId == client.clientId) return;
    _client = client;
    _notesController.text = client.trainerNotes ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // Find this client from the already-loaded list
    final clientsAsync = ref.watch(trainerClientsProvider);
    final client = clientsAsync.valueOrNull?.firstWhere(
      (c) => c.clientId == widget.clientId,
      orElse: () => TrainerClient(
        relationshipId: '',
        clientId: widget.clientId,
        displayName: l10n.trainerClientFallback,
        currentDay: 1,
        dailyStreak: 0,
      ),
    );

    if (client != null) _initClient(client);

    final sessionsAsync = ref.watch(clientSessionsProvider(widget.clientId));
    final appointments = (ref.watch(appointmentsProvider).valueOrNull ?? [])
        .where((appointment) => appointment.traineeId == widget.clientId)
        .toList();
    final observationsAsync =
        ref.watch(trainerClientObservationsProvider(widget.clientId));
    final sharedProfilesAsync =
        ref.watch(trainerClientSharedProfilesProvider(widget.clientId));

    return Scaffold(
      appBar: AppBar(
        title: Text(client?.displayName ?? l10n.trainerClientFallback),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(
                trainerClientSharedProfilesProvider(widget.clientId)),
          ),
        ],
      ),
      body: client == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── KPI strip ──────────────────────────────────────────────
                _KpiStrip(client: client, l10n: l10n),
                const SizedBox(height: 12),
                _ClientActionRow(client: client),
                const SizedBox(height: 24),

                Text(
                  l10n.trainerSharedReflexProfiles,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                sharedProfilesAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(
                    l10n.trainerProfilesLoadFailed('$e'),
                    style: const TextStyle(color: AppColors.error),
                  ),
                  data: (sharedProfiles) => sharedProfiles.isEmpty
                      ? Text(
                          l10n.trainerNoProfilesShared,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final profile in sharedProfiles) ...[
                              profile.latestAssessment == null
                                  ? Padding(
                                      padding: const EdgeInsets.only(
                                          left: 4, bottom: 16),
                                      child: Text(
                                        l10n.trainerNoCompletedReflexProfile(profile.displayName),
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant),
                                      ),
                                    )
                                  : Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _TappableProfileRow(
                                          profile: profile,
                                        ),
                                        const SizedBox(height: 12),
                                        _ReflexProfileNotesCard(
                                          assessment: profile.latestAssessment!,
                                          ownerUserId: client.clientId,
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 24),

                // ── Recent sessions ────────────────────────────────────────
                Text(
                  l10n.trainerRecentSessions,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                sessionsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(e.toString(),
                      style: const TextStyle(color: AppColors.error)),
                  data: (sessions) => sessions.isEmpty
                      ? Text(
                          l10n.trainerNoSessions,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        )
                      : _SessionList(sessions: sessions),
                ),
                const SizedBox(height: 24),

                _SectionTitle(
                  title: l10n.trainerAppointmentsMetric,
                  actionLabel: l10n.trainerProposeAppointment,
                  onAction: () => context.push(
                    Routes.appointmentScheduler
                        .replaceFirst(':clientId', client.clientId),
                    extra: client,
                  ),
                ),
                const SizedBox(height: 8),
                _ClientAppointmentsList(appointments: appointments),
                const SizedBox(height: 24),

                Text(
                  l10n.trainerObservations,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                observationsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text(
                    e.toString(),
                    style: const TextStyle(color: AppColors.error),
                  ),
                  data: (observations) => observations.isEmpty
                      ? Text(
                          l10n.trainerNoSharedObservations,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                        )
                      : _ObservationList(observations: observations),
                ),
                const SizedBox(height: 24),

                // ── Trainer notes ──────────────────────────────────────────
                Text(
                  l10n.trainerNotes,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _notesController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: l10n.trainerNotesHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (_) => setState(() => _notesDirty = true),
                ),
                const SizedBox(height: 12),
                if (_notesDirty)
                  ElevatedButton(
                    onPressed: () => _saveNotes(context, l10n, client),
                    child: Text(l10n.save),
                  ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }

  Future<void> _saveNotes(
    BuildContext context,
    AppLocalizations l10n,
    TrainerClient client,
  ) async {
    try {
      await ref
          .read(trainerClientsProvider.notifier)
          .saveNotes(client.relationshipId, _notesController.text);
      setState(() => _notesDirty = false);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.trainerNotesSaved)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorSaveFailed)),
        );
      }
    }
  }
}

class _ReflexProfileNotesCard extends ConsumerStatefulWidget {
  const _ReflexProfileNotesCard({
    required this.assessment,
    required this.ownerUserId,
  });

  final ReflexProfileAssessment assessment;
  final String ownerUserId;

  @override
  ConsumerState<_ReflexProfileNotesCard> createState() =>
      _ReflexProfileNotesCardState();
}

class _ReflexProfileNotesCardState
    extends ConsumerState<_ReflexProfileNotesCard> {
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    final body = _noteController.text.trim();
    final subjectProfileId = widget.assessment.subjectProfileId;
    if (body.isEmpty || subjectProfileId == null) return;

    setState(() => _saving = true);
    try {
      await addReflexSubjectProfileNote(
        ref: ref,
        subjectProfileId: subjectProfileId,
        ownerUserId: widget.ownerUserId,
        relatedAssessmentId: widget.assessment.id,
        body: body,
      );
      _noteController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).trainerReflexNoteSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).trainerNoteSaveFailed('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjectProfileId = widget.assessment.subjectProfileId;
    if (subjectProfileId == null) return const SizedBox.shrink();
    final notesAsync = ref.watch(
      reflexSubjectProfileNotesProvider(subjectProfileId),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note_alt_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).trainerReflexNotesTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              AppLocalizations.of(context).trainerReflexNotesBody,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).trainerReflexNoteHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _addNote,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_comment_outlined),
                label: Text(AppLocalizations.of(context).trainerSaveNote),
              ),
            ),
            const Divider(height: 28),
            notesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(
                AppLocalizations.of(context).trainerNotesLoadFailed('$e'),
                style: const TextStyle(color: AppColors.error),
              ),
              data: (notes) {
                if (notes.isEmpty) {
                  return Text(
                    AppLocalizations.of(context).trainerNoReflexNotes,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  );
                }
                return Column(
                  children: [
                    for (final note in notes.take(8))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.sticky_note_2_outlined),
                        title: Text(note.body),
                        subtitle: Text(
                          DateFormat('dd.MM.yyyy · HH:mm', Localizations.localeOf(context).toString())
                              .format(note.createdAt),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientActionRow extends ConsumerWidget {
  const _ClientActionRow({required this.client});

  final TrainerClient client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FilledButton.icon(
          onPressed: () =>
              openDirectChatWithUser(context, ref, client.clientId),
          icon: const Icon(Icons.chat_bubble_outline),
          label: Text(AppLocalizations.of(context).trainerMessageAction),
        ),
        OutlinedButton.icon(
          onPressed: () => context.push(
            Routes.appointmentScheduler.replaceFirst(
              ':clientId',
              client.clientId,
            ),
            extra: client,
          ),
          icon: const Icon(Icons.event_available_outlined),
          label: Text(AppLocalizations.of(context).trainerAppointmentAction),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}

class _KpiStrip extends StatelessWidget {
  final TrainerClient client;
  final AppLocalizations l10n;
  const _KpiStrip({required this.client, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiChip(
          icon: Icons.calendar_today_outlined,
          label: l10n.dayNumber(client.currentDay),
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        _KpiChip(
          icon: Icons.radio_button_checked,
          label: AppLocalizations.of(context).trainerDaysCount(client.dailyStreak),
          color: AppColors.warning,
        ),
        const SizedBox(width: 8),
        if (client.packageId != null)
          _KpiChip(
            icon: Icons.inventory_2_outlined,
            label: client.packageId!.toUpperCase(),
            color: AppColors.success,
          ),
      ],
    );
  }
}

class _KpiChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _KpiChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClientAppointmentsList extends StatelessWidget {
  const _ClientAppointmentsList({required this.appointments});

  final List<Appointment> appointments;

  @override
  Widget build(BuildContext context) {
    if (appointments.isEmpty) {
      return Text(
        AppLocalizations.of(context).trainerNoPlannedAppointments,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      children: appointments.take(5).map((appointment) {
        final scheduledFor = appointment.scheduledFor;
        final date = scheduledFor == null
            ? AppLocalizations.of(context).trainerAppointmentProposed
            : DateFormat('dd.MM.yyyy · HH:mm', Localizations.localeOf(context).toString()).format(scheduledFor);
        final profileLabel = appointment.profileLabel;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_available_outlined),
          title: Text(appointment.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(date),
              if (profileLabel != null)
                Text(
                  AppLocalizations.of(context).trainerAppointmentFor(profileLabel),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          trailing: _StatusChip(status: appointment.status),
        );
      }).toList(),
    );
  }
}

class _ObservationList extends StatelessWidget {
  const _ObservationList({required this.observations});

  final List<TrainerClientObservation> observations;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: observations.take(8).map((observation) {
        final date = DateFormat('dd.MM.yyyy · HH:mm', Localizations.localeOf(context).toString())
            .format(observation.recordedAt);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.edit_note_outlined),
          title: Text(
            observation.note,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(date),
        );
      }).toList(),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (status) {
      'confirmed' => l10n.appointmentStatusConfirmed,
      'proposed' => l10n.appointmentStatusProposal,
      'cancelled' => l10n.appointmentStatusCancelled,
      'done' => l10n.appointmentStatusCompletedShort,
      _ => l10n.appointmentStatusPlanned,
    };
    final color = switch (status) {
      'confirmed' => AppColors.success,
      'cancelled' => AppColors.error,
      'done' => AppColors.textDisabled,
      _ => AppColors.primary,
    };

    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.28)),
      backgroundColor: color.withValues(alpha: 0.10),
      labelStyle: TextStyle(color: color, fontSize: 12),
    );
  }
}

class _SessionList extends StatelessWidget {
  final List<ClientSession> sessions;
  const _SessionList({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: sessions.take(14).map((s) {
        final dayStr =
            '${s.sessionDate.day}.${s.sessionDate.month}.${s.sessionDate.year}';
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            s.isCompleted
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            color: s.isCompleted ? AppColors.success : AppColors.textDisabled,
            size: 20,
          ),
          title:
              Text(AppLocalizations.of(context).trainerDayNumber(s.dayNumber), style: const TextStyle(fontSize: 14)),
          trailing: Text(
            dayStr,
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        );
      }).toList(),
    );
  }
}

class _TappableProfileRow extends StatelessWidget {
  const _TappableProfileRow({
    required this.profile,
  });

  final TrainerSharedProfile profile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final assessment = profile.latestAssessment!;

    final age = profile.ageYears != null
        ? AppLocalizations.of(context).trainerAgeYears(profile.ageYears!)
        : (profile.ageGroup ?? '');
    final dateStr = DateFormat('dd.MM.yyyy', Localizations.localeOf(context).toString())
        .format(assessment.completedAt ?? assessment.createdAt);
    final metaStr = [if (age.isNotEmpty) age, dateStr].join(' · ');

    final l10n = AppLocalizations.of(context);
    final topBand = _topScoredBand(assessment);
    final bandLabel =
        topBand != null ? _bandPillLabel(l10n, topBand) : null;
    final bandColor = topBand != null ? _bandPillColor(topBand, cs) : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          Routes.reflexProfileResult,
          extra: {'assessment': assessment},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            metaStr,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                        if (bandLabel != null &&
                            bandLabel.isNotEmpty &&
                            bandColor != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: bandColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              bandLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: bandColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

ReflexScoreBand? _topScoredBand(ReflexProfileAssessment assessment) {
  ReflexScoreBand? worst;
  for (final raw in assessment.scores.values) {
    if (raw is! Map) continue;
    final band = ReflexScoreBand.values.firstWhere(
      (b) => b.name == (raw['band'] as String? ?? ''),
      orElse: () => ReflexScoreBand.insufficientData,
    );
    if (band == ReflexScoreBand.strong) return band;
    if (band == ReflexScoreBand.elevated) worst = band;
  }
  return worst;
}

String _bandPillLabel(AppLocalizations l10n, ReflexScoreBand band) =>
    switch (band) {
      ReflexScoreBand.strong => l10n.trainerBandStrongNoticeable,
      ReflexScoreBand.elevated => l10n.scoreBandElevated,
      _ => '',
    };

Color _bandPillColor(ReflexScoreBand band, ColorScheme cs) => switch (band) {
      ReflexScoreBand.strong => AppColors.error,
      ReflexScoreBand.elevated => AppColors.warning,
      _ => cs.onSurface,
    };
