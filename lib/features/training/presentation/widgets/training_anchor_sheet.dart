// lib/features/training/presentation/widgets/training_anchor_sheet.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/training/training_anchor.dart';
import '../../../../l10n/app_localizations.dart';

/// Localised label for one anchor. The wake-up anchor reads differently for
/// families than for an adult training alone.
String trainingAnchorLabel(
  AppLocalizations l10n,
  TrainingAnchor anchor, {
  bool isAdultSelf = true,
}) {
  return switch (anchor) {
    TrainingAnchor.wakeUp =>
      isAdultSelf ? l10n.trainingAnchorWakeUpAdult : l10n.trainingAnchorWakeUpChild,
    TrainingAnchor.afterBreakfast => l10n.trainingAnchorAfterBreakfast,
    TrainingAnchor.midday => l10n.trainingAnchorMidday,
    TrainingAnchor.evening => l10n.trainingAnchorEvening,
    TrainingAnchor.afterSchool => l10n.trainingAnchorAfterSchool,
    TrainingAnchor.afterDinner => l10n.trainingAnchorAfterDinner,
    TrainingAnchor.fixedTime => l10n.trainingAnchorFixedTime,
  };
}

/// What the user chose: the anchor plus the reminder time for it.
class TrainingAnchorResult {
  const TrainingAnchorResult({required this.anchor, required this.minutes});

  final TrainingAnchor anchor;
  final int minutes;
}

/// Asks once when to remind. Returns null when the user taps "Später".
Future<TrainingAnchorResult?> showTrainingAnchorSheet(
  BuildContext context, {
  required bool isAdultSelf,
}) {
  return showModalBottomSheet<TrainingAnchorResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _TrainingAnchorSheet(isAdultSelf: isAdultSelf),
  );
}

class _TrainingAnchorSheet extends StatefulWidget {
  const _TrainingAnchorSheet({required this.isAdultSelf});

  final bool isAdultSelf;

  @override
  State<_TrainingAnchorSheet> createState() => _TrainingAnchorSheetState();
}

class _TrainingAnchorSheetState extends State<_TrainingAnchorSheet> {
  TrainingAnchor? _selected;
  int? _minutes;

  void _select(TrainingAnchor anchor) {
    setState(() {
      // Picking a different anchor proposes that anchor's time. Picking the
      // same one again leaves a time the user already adjusted alone.
      if (_selected != anchor) {
        _minutes = defaultMinutesFor(anchor);
      }
      _selected = anchor;
    });
  }

  Future<void> _pickTime() async {
    final current = _minutes ?? defaultMinutesFor(_selected!);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked != null) {
      setState(() => _minutes = picked.hour * 60 + picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final options = anchorOptionsFor(isAdultSelf: widget.isAdultSelf);
    final recommended = recommendedAnchorFor(isAdultSelf: widget.isAdultSelf);
    final selected = _selected;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.trainingAnchorTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.trainingAnchorBody,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 16),
            for (final anchor in options)
              RadioListTile<TrainingAnchor>(
                contentPadding: EdgeInsets.zero,
                value: anchor,
                groupValue: selected,
                onChanged: (value) => _select(value!),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        trainingAnchorLabel(
                          l10n,
                          anchor,
                          isAdultSelf: widget.isAdultSelf,
                        ),
                      ),
                    ),
                    if (anchor == recommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.trainingAnchorRecommended,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: anchor == TrainingAnchor.wakeUp && widget.isAdultSelf
                    ? Text(l10n.trainingAnchorWakeUpAdultDetail)
                    : null,
              ),
            if (selected != null && showsEveningHint(selected)) ...[
              const SizedBox(height: 4),
              Text(
                l10n.trainingAnchorEveningHint,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
              ),
            ],
            if (selected != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickTime,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(l10n.trainingAnchorTimeLabel),
                      const Spacer(),
                      Text(
                        TimeOfDay(
                          hour: (_minutes ?? defaultMinutesFor(selected)) ~/ 60,
                          minute:
                              (_minutes ?? defaultMinutesFor(selected)) % 60,
                        ).format(context),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Icon(Icons.edit_outlined, size: 18),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.trainingAnchorLater),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(
                            context,
                            TrainingAnchorResult(
                              anchor: selected,
                              minutes:
                                  _minutes ?? defaultMinutesFor(selected),
                            ),
                          ),
                  child: Text(l10n.trainingAnchorConfirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
