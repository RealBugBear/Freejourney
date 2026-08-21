import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/adult_reflex_profile_scoring.dart';
import '../../domain/models/reflex_profile_assessment.dart';
import '../../domain/reflex_questionnaire.dart';
import '../adult_score_band_l10n.dart';
import '../adult_top_pattern_lines.dart';
import '../providers/reflex_profile_provider.dart';

/// Progress-strip card for adult_v3 / legacy adult assessments (§10.3a).
///
/// Same outer size and chrome as the child mini-radar cards — no radar, no
/// overall score.
class AdultProgressProfileCard extends StatelessWidget {
  const AdultProgressProfileCard({
    super.key,
    required this.summary,
    required this.onTap,
    this.isSelected = false,
  });

  final ReflexProfileSummary summary;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final assessment = summary.latestAssessment!;
    final isV3 = assessment.questionnaireVersion == 'adult_v3';
    final locale = Localizations.localeOf(context).languageCode;
    final parsed =
        isV3 ? AdultQuestionnaireScore.tryParse(assessment.scores) : null;
    final lines = parsed == null
        ? const <AdultTopPatternLine>[]
        : adultTopPatternLines(parsed);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.07)
              : Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.profile.displayName,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                l10n.profileAdult,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: isV3
                    ? _TopPatternList(lines: lines, locale: locale)
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.progressAdultLegacyCardBody,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    height: 1.35,
                                  ),
                        ),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                _dateLabel(context, assessment.completedAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.bar_chart_outlined, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    l10n.progressProfileDetails,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(BuildContext context, DateTime? dt) {
    if (dt == null) return '';
    return DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(dt);
  }
}

class _TopPatternList extends StatelessWidget {
  const _TopPatternList({required this.lines, required this.locale});

  final List<AdultTopPatternLine> lines;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (lines.isEmpty) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.progressAdultNoPatternsYet,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    // Vertically centred (§10.3a review): the adult card carries less content
    // than the child mini-radar it sits next to, so top alignment left an
    // empty third above the date and read as a missing section.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final (index, line) in lines.indexed) ...[
          if (index > 0) const SizedBox(height: 6),
          Text(
            line.reflex.copy.label(locale),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            adultHintBandLabel(l10n, line.band),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Whether [assessment] should use the adult progress strip card (not radar).
bool isAdultProgressAssessment(ReflexProfileAssessment assessment) =>
    assessment.questionnaireType == 'adult_self_report';
