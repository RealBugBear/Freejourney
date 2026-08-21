import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/adult_reflex_profile_scoring.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/presentation/adult_top_pattern_lines.dart';

void main() {
  test('adultTopPatternLines ranks by percent and caps at three', () {
    final score = AdultQuestionnaireScore(
      scoringVersion: kAdultScoringVersion,
      questionnaireVersion: 'adult_v3',
      reflexScores: {
        PrimitiveReflex.moro: const AdultReflexScoreResult(
          reflex: PrimitiveReflex.moro,
          positiveCount: 3,
          answeredCount: 5,
          possibleCount: 6,
          unknownCount: 0,
          notApplicableCount: 0,
          missingCount: 1,
          percent: 60,
          percentDisplay: 60,
          band: AdultHintBand.clusteredPattern,
        ),
        PrimitiveReflex.flr: const AdultReflexScoreResult(
          reflex: PrimitiveReflex.flr,
          positiveCount: 1,
          answeredCount: 4,
          possibleCount: 5,
          unknownCount: 0,
          notApplicableCount: 0,
          missingCount: 1,
          percent: 25,
          percentDisplay: 25,
          band: AdultHintBand.fewMatching,
        ),
        PrimitiveReflex.atnr: const AdultReflexScoreResult(
          reflex: PrimitiveReflex.atnr,
          positiveCount: 4,
          answeredCount: 5,
          possibleCount: 5,
          unknownCount: 0,
          notApplicableCount: 0,
          missingCount: 0,
          percent: 80,
          percentDisplay: 80,
          band: AdultHintBand.stronglyClustered,
        ),
        PrimitiveReflex.stnr: const AdultReflexScoreResult(
          reflex: PrimitiveReflex.stnr,
          positiveCount: 2,
          answeredCount: 4,
          possibleCount: 4,
          unknownCount: 0,
          notApplicableCount: 0,
          missingCount: 0,
          percent: 50,
          percentDisplay: 50,
          band: AdultHintBand.someMatching,
        ),
        PrimitiveReflex.tlr: const AdultReflexScoreResult(
          reflex: PrimitiveReflex.tlr,
          positiveCount: 0,
          answeredCount: 0,
          possibleCount: 3,
          unknownCount: 0,
          notApplicableCount: 0,
          missingCount: 3,
          percent: null,
          percentDisplay: null,
          band: AdultHintBand.insufficientData,
        ),
      },
      amphibian: const AdultAmphibianScore(
        positiveCount: 0,
        answeredCount: 0,
        display: AmphibianDisplay.insufficientData,
        showDisclaimer: true,
      ),
      meta: const AdultScoreMeta(
        hiddenItemIds: [],
        notApplicableItemIds: [],
        unknownItemIds: [],
        noPublicTotalScore: true,
        movementIncluded: false,
        filterAnswers: {},
      ),
    );

    final lines = adultTopPatternLines(score);
    expect(lines.map((l) => l.reflex), [
      PrimitiveReflex.atnr,
      PrimitiveReflex.moro,
      PrimitiveReflex.stnr,
    ]);
    expect(lines.length, 3);
    expect(
      lines.any((l) => l.band == AdultHintBand.insufficientData),
      isFalse,
    );
  });
}
