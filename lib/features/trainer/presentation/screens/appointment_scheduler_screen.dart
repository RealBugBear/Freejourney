import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/launch_flags.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../chat/presentation/providers/chat_providers.dart';
import '../../domain/models/trainer_client.dart';
import '../../domain/services/calendar_service.dart' show TimeSlot;
import '../providers/trainer_provider.dart';

class AppointmentSchedulerScreen extends ConsumerStatefulWidget {
  final TrainerClient client;
  final String? reviewChannelId;

  const AppointmentSchedulerScreen({
    super.key,
    required this.client,
    this.reviewChannelId,
  });

  @override
  ConsumerState<AppointmentSchedulerScreen> createState() =>
      _AppointmentSchedulerScreenState();
}

class _AppointmentSchedulerScreenState
    extends ConsumerState<AppointmentSchedulerScreen> {
  final _locationCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  List<TimeSlot>? _freeSlots;
  final Set<TimeSlot> _selectedSlots = {};
  final Set<String> _selectedProfileIds = {};
  bool _loadingSlots = true;
  bool _sending = false;
  bool _sent = false;

  bool get _isReviewFlow => widget.reviewChannelId != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _loadSlots();
  }

  Future<void> _loadSlots() async {
    setState(() => _loadingSlots = true);
    try {
      final slots = _buildSuggestedSlots(DateTime.now());
      if (mounted) setState(() => _freeSlots = slots);
    } catch (e) {
      appLogger.e('Failed to load available appointment slots', error: e);
    } finally {
      if (mounted) setState(() => _loadingSlots = false);
    }
  }

  List<TimeSlot> _buildSuggestedSlots(DateTime from) {
    final start = DateTime(from.year, from.month, from.day).add(
      const Duration(days: 1),
    );
    final suggestions = <TimeSlot>[];
    final slotHours = [9, 11, 14, 16];

    for (int dayOffset = 0; dayOffset < 10; dayOffset++) {
      final day = start.add(Duration(days: dayOffset));
      if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
        continue;
      }
      for (final hour in slotHours) {
        final slotStart = DateTime(day.year, day.month, day.day, hour);
        suggestions.add(
          TimeSlot(
            start: slotStart,
            end: slotStart.add(const Duration(hours: 1)),
          ),
        );
      }
    }

    return suggestions;
  }

  Future<void> _pickCustomTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null || !mounted) return;

    final custom =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      _selectedSlots.add(
          TimeSlot(start: custom, end: custom.add(const Duration(hours: 1))));
    });
  }

  List<DateTime> get _allSelectedDateTimes {
    final times = _selectedSlots.map((s) => s.start).toList();
    return times;
  }

  Future<void> _propose() async {
    final slots = _allSelectedDateTimes;
    if (slots.isEmpty) return;

    setState(() => _sending = true);
    try {
      final data = await Supabase.instance.client.rpc(
        _isReviewFlow
            ? 'propose_application_review_appointment'
            : 'propose_appointment',
        params: _isReviewFlow
            ? {
                'p_channel_id': widget.reviewChannelId,
                'p_applicant_id': widget.client.clientId,
                'p_proposed_slots':
                    slots.map((d) => d.toUtc().toIso8601String()).toList(),
                'p_location': _locationCtrl.text.trim().isEmpty
                    ? null
                    : _locationCtrl.text.trim(),
                'p_notes': _notesCtrl.text.trim().isEmpty
                    ? null
                    : _notesCtrl.text.trim(),
              }
            : {
                'p_client_id': widget.client.clientId,
                'p_proposed_slots':
                    slots.map((d) => d.toUtc().toIso8601String()).toList(),
                'p_location': _locationCtrl.text.trim().isEmpty
                    ? null
                    : _locationCtrl.text.trim(),
                'p_notes': _notesCtrl.text.trim().isEmpty
                    ? null
                    : _notesCtrl.text.trim(),
                'p_trainee_day_number': widget.client.currentDay,
              },
      );
      final appointmentId = (data as Map<String, dynamic>)['id'] as String?;
      if (appointmentId != null) {
        unawaited(_notifyAppointmentProposal(appointmentId));
        if (_selectedProfileIds.isNotEmpty) {
          await Supabase.instance.client
              .from('appointment_subject_profiles')
              .insert([
            for (final pid in _selectedProfileIds)
              {'appointment_id': appointmentId, 'subject_profile_id': pid},
          ]);
        }
      }

      ref.invalidate(appointmentsProvider);
      ref.invalidate(trainerClientsProvider);
      ref.invalidate(chatChannelsProvider);

      if (mounted) setState(() => _sent = true);
    } catch (e) {
      appLogger.e('Failed to propose appointment', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _notifyAppointmentProposal(String appointmentId) async {
    try {
      await Supabase.instance.client.functions.invoke(
        'notify-appointment-proposal',
        body: {'appointment_id': appointmentId},
      );
    } catch (e) {
      appLogger.w('Appointment proposal notification failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_sent) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.appointmentSchedulerTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.send_rounded,
                    size: 64, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  '${_selectedSlots.length} Terminvorschlag${_selectedSlots.length > 1 ? "schläge" : ""} an ${widget.client.displayName} gesendet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Die andere Person wählt einen passenden Slot aus.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.close),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.appointmentSchedulerTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Text(
            _isReviewFlow
                ? 'Video-Termin mit ${widget.client.displayName}'
                : l10n.appointmentWith(widget.client.displayName),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            _isReviewFlow
                ? 'Wähle 2–4 freie Slots für das Bewerbungsgespräch aus.'
                : 'Wähle 2–4 freie Slots aus — dein Klient sucht sich einen aus.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),

          // ── Selection summary ─────────────────────────────────────────────
          if (_selectedSlots.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedSlots.length} Slot${_selectedSlots.length > 1 ? "s" : ""} ausgewählt',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _selectedSlots.clear()),
                    child: Text(
                      'Zurücksetzen',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── Free slots ───────────────────────────────────────────────────
          Text(
            l10n.appointmentFreeSlotsTitle,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_loadingSlots)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 12),
                  Text(l10n.appointmentLoadingSlots,
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            )
          else if (_freeSlots == null || _freeSlots!.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.appointmentNoFreeSlots,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            )
          else
            _SlotGrid(
              slots: _freeSlots!.take(24).toList(),
              selectedSlots: _selectedSlots,
              onTap: (slot) => setState(() {
                if (_selectedSlots.contains(slot)) {
                  _selectedSlots.remove(slot);
                } else {
                  _selectedSlots.add(slot);
                }
              }),
            ),

          const SizedBox(height: 4),

          // ── Custom time ──────────────────────────────────────────────────
          TextButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: Text(l10n.appointmentOtherTime),
            onPressed: _pickCustomTime,
            style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(context).colorScheme.onSurfaceVariant),
          ),

          // ── Profile selection (regular appointments only) ─────────────────
          if (!_isReviewFlow) ...[
            const Divider(height: 28),
            _ProfileSelector(
              clientId: widget.client.clientId,
              selectedIds: _selectedProfileIds,
              onToggle: (id) => setState(() {
                if (_selectedProfileIds.contains(id)) {
                  _selectedProfileIds.remove(id);
                } else {
                  _selectedProfileIds.add(id);
                }
              }),
            ),
          ],

          const Divider(height: 28),

          // ── Location + notes ──────────────────────────────────────────────
          TextField(
            controller: _locationCtrl,
            decoration: InputDecoration(
              labelText: _isReviewFlow && kVideoCallsEnabled
                  ? 'Ort oder Video-Call'
                  : l10n.appointmentLocationLabel,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: l10n.appointmentNotesLabel,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 24),

          // ── Propose button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _selectedSlots.isEmpty || _sending ? null : _propose,
              icon: _sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded, size: 18),
              label: Text(
                _selectedSlots.isEmpty
                    ? 'Slots auswählen'
                    : 'Vorschlag senden (${_selectedSlots.length})',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Profile selector chips ────────────────────────────────────────────────────

class _ProfileSelector extends ConsumerWidget {
  const _ProfileSelector({
    required this.clientId,
    required this.selectedIds,
    required this.onToggle,
  });

  final String clientId;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync =
        ref.watch(trainerClientSharedProfilesProvider(clientId));

    return profilesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (profiles) {
        if (profiles.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Termin für (optional)',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'Wähle Profile aus, wenn dieser Termin für bestimmte Kinder ist.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profiles.map((p) {
                final selected = selectedIds.contains(p.subjectProfileId);
                return FilterChip(
                  label: Text(p.displayName),
                  selected: selected,
                  onSelected: (_) => onToggle(p.subjectProfileId),
                  showCheckmark: false,
                  avatar: selected
                      ? const Icon(Icons.person, size: 16)
                      : const Icon(Icons.person_outline, size: 16),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

// ── Multi-select slot grid ────────────────────────────────────────────────────

class _SlotGrid extends StatelessWidget {
  final List<TimeSlot> slots;
  final Set<TimeSlot> selectedSlots;
  final ValueChanged<TimeSlot> onTap;

  const _SlotGrid({
    required this.slots,
    required this.selectedSlots,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, List<TimeSlot>> byDay = {};
    for (final slot in slots) {
      final key = DateFormat('yyyy-MM-dd').format(slot.start);
      byDay.putIfAbsent(key, () => []).add(slot);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: byDay.entries.map((entry) {
        final daySlots = entry.value;
        final dayLabel =
            DateFormat('EEE, d. MMM', 'de_DE').format(daySlots.first.start);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: daySlots.map((slot) {
                  final selected = selectedSlots.contains(slot);
                  final timeStr = DateFormat('HH:mm').format(slot.start);
                  return GestureDetector(
                    onTap: () => onTap(slot),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
