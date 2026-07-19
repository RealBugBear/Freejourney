import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/l10n/app_languages.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/error_retry_widget.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/models/mood_view_settings.dart';
import '../../../progress/presentation/providers/progress_provider.dart';
import '../providers/mood_provider.dart';
import 'mood_checkin_sheet.dart';
import 'mood_trend_chart.dart';
import 'note_entry_sheet.dart';

class MoodChartWidget extends ConsumerStatefulWidget {
  final bool showNotesList;
  final bool showLegend;
  final bool compactHeader;
  final double chartHeight;

  const MoodChartWidget({
    super.key,
    this.showNotesList = true,
    this.showLegend = true,
    this.compactHeader = false,
    this.chartHeight = 180,
  });

  @override
  ConsumerState<MoodChartWidget> createState() => _MoodChartWidgetState();
}

class _MoodChartWidgetState extends ConsumerState<MoodChartWidget> {
  // 0 = all time
  int _rangeDays = 30;

  void _invalidateMoodProviders() {
    ref.invalidate(moodDailyAggregatesProvider);
    ref.invalidate(moodNotesProvider);
  }

  void _showNotePopup(BuildContext context, MoodCheckinsTableData note) {
    final text = (note.note ?? '').trim();
    if (text.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_outlined, size: 18),
            const SizedBox(width: 8),
            Text(
              formatMoodNoteDate(
                note.recordedAt,
                Localizations.localeOf(context),
              ),
              style: Theme.of(ctx).textTheme.titleSmall,
            ),
          ],
        ),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              showMoodCheckinSheet(
                context,
                initialEntry: note,
                onSaved: _invalidateMoodProviders,
              );
            },
            child: Text(AppLocalizations.of(context).edit),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final aggregatesAsync = ref.watch(moodDailyAggregatesProvider(_rangeDays));
    final notesAsync = ref.watch(moodNotesProvider(_rangeDays));
    final enrollmentId = ref.watch(activeEnrollmentProvider).valueOrNull?.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                widget.compactHeader ? l10n.moodLabel : l10n.moodCheckIn,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _RangeChips(
              selected: _rangeDays,
              onSelect: (v) => setState(() => _rangeDays = v),
            ),
            if (enrollmentId != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_note_outlined, size: 18),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: l10n.moodWriteNote,
                onPressed: () => showNoteEntrySheet(
                  context,
                  enrollmentId: enrollmentId,
                  onSaved: _invalidateMoodProviders,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: widget.compactHeader ? 12 : 16),
        SizedBox(
          height: widget.chartHeight,
          child: aggregatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => InlineErrorWidget(
              onRetry: () =>
                  ref.invalidate(moodDailyAggregatesProvider(_rangeDays)),
            ),
            data: (aggregates) {
              if (aggregates.isEmpty) {
                return Center(
                  child: Text(
                    l10n.moodChartEmpty,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return notesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => InlineErrorWidget(
                  onRetry: () => ref.invalidate(moodNotesProvider(_rangeDays)),
                ),
                data: (notes) => MoodTrendChart(
                  aggregates: aggregates,
                  notes: notes,
                  settings: const MoodViewSettings(),
                  onNoteTap: (note) => _showNotePopup(context, note),
                ),
              );
            },
          ),
        ),
        if (widget.showNotesList)
          notesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (notes) {
              if (notes.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _NotesList(
                  entries: notes,
                  onEntryTap: (entry) => showMoodCheckinSheet(
                    context,
                    initialEntry: entry,
                    onSaved: () {
                      ref.invalidate(moodDailyAggregatesProvider(_rangeDays));
                      ref.invalidate(moodNotesProvider(_rangeDays));
                    },
                  ),
                ),
              );
            },
          ),
        if (widget.showLegend) ...[
          const SizedBox(height: 12),
          _Legend(),
        ],
      ],
    );
  }
}

class _RangeChips extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;

  const _RangeChips({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    const options = [30, 90, 365, 0];
    final l10n = AppLocalizations.of(context);
    final labels = [
      l10n.progressRange30Days,
      l10n.progressRange90Days,
      l10n.progressRangeOneYear,
      l10n.progressRangeAll,
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (i) {
        final isSelected = selected == options[i];
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: () => onSelect(options[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.textPrimary : AppColors.primary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: AppColors.moodRose, label: l10n.moodLabel),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.moodTeal, label: l10n.energyLabel),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.moodGold, label: l10n.stressLabel),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NotesList extends StatelessWidget {
  final List<MoodCheckinsTableData> entries;
  final ValueChanged<MoodCheckinsTableData> onEntryTap;

  const _NotesList({
    required this.entries,
    required this.onEntryTap,
  });

  @override
  Widget build(BuildContext context) {
    final visibleEntries = entries.take(3).toList();

    return Column(
      children: [
        for (final entry in visibleEntries)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => onEntryTap(entry),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatMoodNoteDate(
                          entry.recordedAt,
                          Localizations.localeOf(context),
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (entry.note ?? '').trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String formatMoodNoteDate(DateTime value, Locale locale) {
  final localeName = locale.toLanguageTag();
  // DE keeps its fixed dd.MM.yyyy format; other locales inherit yMd.
  if (locale.languageCode == AppLanguages.sourceCode) {
    return DateFormat('dd.MM.yyyy', localeName).format(value);
  }
  return DateFormat.yMd(localeName).format(value);
}
