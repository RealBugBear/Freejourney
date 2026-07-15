import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../mood/presentation/widgets/mood_checkin_sheet.dart';
import '../providers/journal_provider.dart';

class JournalEntryTile extends ConsumerStatefulWidget {
  final JournalEntriesTableData entry;
  final VoidCallback onDeleted;
  final VoidCallback onChanged;

  const JournalEntryTile({
    super.key,
    required this.entry,
    required this.onDeleted,
    required this.onChanged,
  });

  @override
  ConsumerState<JournalEntryTile> createState() => _JournalEntryTileState();
}

class _JournalEntryTileState extends ConsumerState<JournalEntryTile> {
  bool _expanded = false;

  Future<bool> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.journalDeleteEntryTitle),
        content: Text(l10n.journalDeleteEntryBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Opens the mood checkin sheet for editing if a linked checkin exists,
  /// otherwise shows a read-only view (no editable checkin to attach to).
  Future<void> _openEdit() async {
    final checkinId = widget.entry.checkinId;
    if (checkinId == null) return; // standalone entry — no edit UI yet

    final linkedCheckin =
        await ref.read(journalRepositoryProvider).getLinkedCheckin(checkinId);

    if (linkedCheckin == null || !mounted) return;

    await showMoodCheckinSheet(
      context,
      initialEntry: linkedCheckin,
      onSaved: widget.onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final entry = widget.entry;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final dayText = DateFormat('dd', localeName).format(entry.createdAt);
    final monthText = DateFormat.MMM(localeName).format(entry.createdAt);
    final timeText = DateFormat.jm(localeName).format(entry.createdAt);
    final content = entry.content.trim();
    final hasLongText = content.length > 180;
    final shownText =
        hasLongText && !_expanded ? '${content.substring(0, 180)}…' : content;

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(),
      onDismissed: (_) => widget.onDeleted(),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: entry.checkinId != null ? _openEdit : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [
                      Text(
                        dayText,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        monthText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: content.isEmpty ? 82 : 108,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.divider,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 1, 0, 8),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              timeText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            if (entry.checkinId != null)
                              const Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            const Spacer(),
                            Text(
                              l10n.journalEntryTypeNote,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _metricChip('😊', entry.mood, AppColors.moodRose),
                            _metricChip('⚡', entry.energy, AppColors.moodTeal),
                            _metricChip('😤', entry.stress, AppColors.moodGold),
                          ].whereType<Widget>().toList(),
                        ),
                        if (content.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            shownText,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  height: 1.4,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                          if (hasLongText) ...[
                            const SizedBox(height: 4),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _expanded = !_expanded),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 28),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                _expanded
                                    ? l10n.journalShowLess
                                    : l10n.journalShowMore,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _metricChip(String emoji, int? value, Color color) {
    if (value == null) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$emoji $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
