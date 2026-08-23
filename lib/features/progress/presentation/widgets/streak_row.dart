import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/streak/streak_credits.dart';
import '../providers/streak_provider.dart';

/// Dashboard row: series length, remaining credits and the current week.
///
/// A day rescued by a credit is drawn differently from a trained day — the
/// week must not claim training that did not happen (spec §6.1).
class StreakRow extends StatelessWidget {
  const StreakRow({
    super.key,
    required this.view,
    required this.today,
    this.onDismissRescueNotice,
  });

  final StreakView view;
  final DateTime today;
  final VoidCallback? onDismissRescueNotice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - DateTime.monday),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.streakTitle(view.length),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Icon(Icons.confirmation_number_outlined,
                    size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  l10n.streakCreditsLabel(view.credits),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var index = 0; index < 7; index++)
                  Expanded(
                    child: _DayMark(
                      day: DateTime(
                        weekStart.year,
                        weekStart.month,
                        weekStart.day + index,
                      ),
                      index: index,
                      today: today,
                      trainingDays: view.trainingDays,
                      rescuedDays: view.rescuedDays,
                    ),
                  ),
              ],
            ),
            if (view.newlyRescued.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: onDismissRescueNotice,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.streakRescueNotice,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayMark extends StatelessWidget {
  const _DayMark({
    required this.day,
    required this.index,
    required this.today,
    required this.trainingDays,
    required this.rescuedDays,
  });

  final DateTime day;
  final int index;
  final DateTime today;
  final Set<DateTime> trainingDays;
  final Set<DateTime> rescuedDays;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isTrained = trainingDays.contains(day);
    final isRescued = !isTrained && rescuedDays.contains(day);
    final isToday = day == dateOnly(today);

    final String state;
    if (isTrained) {
      state = 'trained';
    } else if (isRescued) {
      state = 'rescued';
    } else if (isToday) {
      state = 'today';
    } else {
      state = 'empty';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        key: ValueKey('streak-day-$state-$index'),
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isTrained
              ? AppColors.primary
              : isRescued
                  ? AppColors.warning.withValues(alpha: 0.25)
                  : cs.surfaceContainerHighest,
          border: isRescued
              ? Border.all(color: AppColors.warning)
              : isToday && !isTrained
                  ? Border.all(color: cs.outline)
                  : null,
        ),
      ),
    );
  }
}
