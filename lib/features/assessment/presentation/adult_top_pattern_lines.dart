import '../domain/adult_reflex_profile_scoring.dart';
import '../domain/reflex_questionnaire.dart';

/// One short line for the adult progress strip card (§10.3a).
class AdultTopPatternLine {
  const AdultTopPatternLine({
    required this.reflex,
    required this.band,
    required this.percent,
  });

  final PrimitiveReflex reflex;
  final AdultHintBand band;
  final double percent;
}

/// Strongest answer patterns by percent, excluding insufficient-data rows.
///
/// Amphibian is not a percent bar and is omitted here — the result screen
/// remains the place for the full list.
List<AdultTopPatternLine> adultTopPatternLines(
  AdultQuestionnaireScore score, {
  int limit = 3,
}) {
  final ranked = score.reflexScores.values
      .where(
        (s) =>
            s.percent != null && s.band != AdultHintBand.insufficientData,
      )
      .toList()
    ..sort((a, b) => (b.percent ?? -1).compareTo(a.percent ?? -1));

  return [
    for (final s in ranked.take(limit))
      AdultTopPatternLine(
        reflex: s.reflex,
        band: s.band,
        percent: s.percent!,
      ),
  ];
}
