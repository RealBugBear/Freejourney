import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/adult_reflex_profile_scoring.dart';
import '../../domain/adult_reflex_result_copy.dart';
import '../../domain/reflex_questionnaire.dart';
import '../adult_score_band_l10n.dart';
import 'adult_reflex_hint_bar.dart';

/// Expandable adult reflex detail (§10.2).
class AdultReflexDetailTile extends StatelessWidget {
  const AdultReflexDetailTile({
    super.key,
    required this.score,
    required this.matchingAnswers,
  });

  final AdultReflexScoreResult score;
  final List<String> matchingAnswers;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final cs = Theme.of(context).colorScheme;
    final copy = adultReflexResultCopyFor(score.reflex);
    final bandText = adultHintBandLabel(l10n, score.band);
    final name = score.reflex.copy.label(locale);
    final percentText = score.percentDisplay == null
        ? '—'
        : '${score.percentDisplay} %';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        title: Text(
          name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AdultReflexHintBar(percent: score.percent),
              const SizedBox(height: 8),
              Text(
                '$percentText · $bandText',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.adultResultFeaturesAnswered(
                  score.answeredCount,
                  score.possibleCount,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        children: [
          if (copy != null) ...[
            Text(
              copy.shortDescription(locale),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.adultResultDetailHintStrength,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text('$bandText · $percentText'),
            const SizedBox(height: 10),
            Text(
              l10n.adultResultDetailDataBasis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(
              l10n.adultResultFeaturesAnswered(
                score.answeredCount,
                score.possibleCount,
              ),
            ),
            if (matchingAnswers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                l10n.adultResultDetailMatchingAnswers,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              for (final text in matchingAnswers)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('• $text'),
                ),
            ],
            const SizedBox(height: 10),
            Text(
              l10n.adultResultDetailAlternatives,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(copy.alternativeExplanations(locale)),
            const SizedBox(height: 10),
            Text(
              l10n.adultResultDetailLimits,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            Text(copy.limits(locale)),
            const SizedBox(height: 10),
            Text(
              copy.optionalPhysicalCheckHint(locale),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
