import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/reflex_profile_scoring.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire_definitions.dart';

void main() {
  const scoring = ReflexProfileScoringService();

  test('scores only answered yes/no values for each reflex', () {
    final result = scoring.score(
      definition: childParentQuestionnaireV1,
      answers: const {
        'q044': ReflexAnswerValue(yesNoUnknown: true),
        'q045': ReflexAnswerValue(yesNoUnknown: false),
        'q046': ReflexAnswerValue(),
      },
    );

    final flr = result.reflexScores[PrimitiveReflex.flr]!;
    final moro = result.reflexScores[PrimitiveReflex.moro]!;

    expect(flr.yesCount, 1);
    expect(flr.answeredCount, 2);
    expect(flr.percent, 50);
    expect(flr.band, ReflexScoreBand.indication);
    expect(moro.yesCount, 1);
    expect(moro.answeredCount, 2);
  });

  test('does not score context month or free-text answers', () {
    final result = scoring.score(
      definition: childParentQuestionnaireV1,
      answers: const {
        'q032': ReflexAnswerValue(months: 9),
        'q033': ReflexAnswerValue(months: 14),
      },
    );

    expect(
      result.reflexScores.values.every((score) => score.answeredCount == 0),
      isTrue,
    );
    expect(result.warningQuestionIds, isEmpty);
  });

  test('collects professional-clearance warning questions', () {
    final result = scoring.score(
      definition: childParentQuestionnaireV1,
      answers: const {
        'q106': ReflexAnswerValue(yesNoUnknown: true),
        'q107': ReflexAnswerValue(yesNoUnknown: true),
        'q108': ReflexAnswerValue(yesNoUnknown: false),
        'q109': ReflexAnswerValue(),
      },
    );

    expect(result.warningQuestionIds, ['q106', 'q107']);
  });
}
