import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/appointment.dart';
import '../../domain/services/calendar_service.dart';
import '../providers/trainer_provider.dart';

class AppointmentProposalScreen extends ConsumerWidget {
  const AppointmentProposalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proposalsAsync = ref.watch(traineeProposalsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Terminvorschläge')),
      body: proposalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (proposals) {
          if (proposals.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 56, color: AppColors.textDisabled),
                  const SizedBox(height: 16),
                  Text(
                    'Keine offenen Terminvorschläge.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: proposals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, i) => _ProposalCard(
              proposal: proposals[i],
              onConfirmed: () => ref.invalidate(traineeProposalsProvider),
            ),
          );
        },
      ),
    );
  }
}

class _ProposalCard extends StatefulWidget {
  final Appointment proposal;
  final VoidCallback onConfirmed;

  const _ProposalCard({required this.proposal, required this.onConfirmed});

  @override
  State<_ProposalCard> createState() => _ProposalCardState();
}

class _ProposalCardState extends State<_ProposalCard> {
  DateTime? _chosen;
  bool _confirming = false;

  Future<void> _confirm(WidgetRef ref) async {
    if (_chosen == null) return;
    setState(() => _confirming = true);
    try {
      await confirmProposedSlot(widget.proposal.id, _chosen!);

      // Offer to add to calendar
      if (mounted) {
        final add = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Zum Kalender hinzufügen?'),
            content: Text(
              'Soll der Termin am ${DateFormat('E, d. MMM – HH:mm', 'de_DE').format(_chosen!)} in deinen Kalender eingetragen werden?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Nein'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Ja, hinzufügen'),
              ),
            ],
          ),
        );

        if (add == true && mounted) {
          await _addToCalendar();
        }
      }

      widget.onConfirmed();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Termin bestätigt!')),
        );
      }
      // Navigate away after confirming — pop if possible, else fall back to DMs
      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.dm);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _addToCalendar() async {
    if (_chosen == null) return;
    try {
      await CalendarService.instance.createCalendarEvent(
        title: '${widget.proposal.title} (mit ${widget.proposal.traineeName})',
        start: _chosen!,
        duration: Duration(minutes: widget.proposal.durationMinutes),
        location: widget.proposal.location,
        description: widget.proposal.notes,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kalender konnte nicht geöffnet werden: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final proposal = widget.proposal;

    return Consumer(
      builder: (context, ref, _) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  radius: 18,
                  child: const Icon(Icons.person_outline,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal
                          .traineeName, // trainer name here (fromJson sets it)
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    Text(
                      proposal.title,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),
            Text(
              'Wähle einen passenden Termin:',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 10),

            // Slot options
            ...proposal.proposedSlots.map((slot) {
              final isSelected = _chosen == slot;
              final label =
                  DateFormat('EEE, d. MMM · HH:mm', 'de_DE').format(slot);
              return GestureDetector(
                onTap: () => setState(() => _chosen = slot),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        size: 18,
                        color: isSelected
                            ? AppColors.textPrimary
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed:
                    _chosen == null || _confirming ? null : () => _confirm(ref),
                child: _confirming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Termin bestätigen',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
