import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/reflex_questionnaire.dart';
import '../screens/reflex_profile_result_helpers.dart';

/// Collapsed panel holding the parent's own free-text and month entries.
///
/// Founder decision 2026-08-23: the child result reads as radar plus bars, so
/// these notes start closed and stay one tap away.
class AdditionalAnswersPanel extends StatelessWidget {
  const AdditionalAnswersPanel({super.key, required this.groups});

  final List<(ReflexQuestionModule, List<RelevantAnswerItem>)> groups;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          AppLocalizations.of(context).reflexResultAdditionalInfo,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        children: [_RelevanteAngaben(groups: groups)],
      ),
    );
  }
}

class _RelevanteAngaben extends StatelessWidget {
  const _RelevanteAngaben({required this.groups});

  final List<(ReflexQuestionModule, List<RelevantAnswerItem>)> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          AppLocalizations.of(context).reflexResultNoAdditional,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups)
          _ModuleGroup(module: group.$1, items: group.$2),
      ],
    );
  }
}

class _ModuleGroup extends StatelessWidget {
  const _ModuleGroup({required this.module, required this.items});

  final ReflexQuestionModule module;
  final List<RelevantAnswerItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            reflexModuleLabel(module, locale).toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.84,
                ),
          ),
        ),
        for (int i = 0; i < items.length; i++) ...[
          _RelevantAnswerCard(item: items[i]),
          if (i < items.length - 1) const SizedBox(height: 6),
        ],
        const SizedBox(height: 14),
      ],
    );
  }
}

class _RelevantAnswerCard extends StatelessWidget {
  const _RelevantAnswerCard({required this.item});

  final RelevantAnswerItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final hasFreeText = item.freeText != null;
    final hasMonths = item.months != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.question.text(locale),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            if (hasFreeText) ...[
              const SizedBox(height: 8),
              Text(
                '„${item.freeText}"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: cs.onSurface.withValues(alpha: 0.70),
                      height: 1.45,
                    ),
              ),
            ],
            if (hasMonths) ...[
              SizedBox(height: hasFreeText ? 4 : 8),
              Text(
                AppLocalizations.of(context).monthsCount(item.months!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
