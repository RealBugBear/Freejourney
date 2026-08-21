import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/adult_reflex_questionnaire_definitions.dart';
import 'package:corejourney/features/assessment/domain/questionnaire_draft_meta_builder.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire_definitions.dart';

void main() {
  group('buildQuestionnaireDraftMeta', () {
    test('adult draft fills superseded_item_ids from visibility', () {
      final definition = adultSelfQuestionnaireV3;
      final answers = <String, ReflexAnswerValue>{
        'f_drive': const ReflexAnswerValue(yesNoUnknown: false),
        'a040': const ReflexAnswerValue(yesNoUnknown: true),
        'a042': const ReflexAnswerValue(yesNoUnknown: false),
      };

      final meta = buildQuestionnaireDraftMeta(
        definition: definition,
        answers: answers,
        moduleIndex: 2,
        questionnaireFor: 'adult',
        startedAt: DateTime.utc(2026, 8, 21),
      );

      expect(meta.filterAnswers['f_drive'], 'no');
      expect(meta.supersededItemIds, containsAll(['a040', 'a042']));
      expect(meta.toJson()['superseded_item_ids'], contains('a040'));
      expect(meta.toJson()['filter_answers']['f_drive'], 'no');
    });

    test('child draft does not invent filter or superseded fields', () {
      final meta = buildQuestionnaireDraftMeta(
        definition: childParentQuestionnaireV1,
        answers: {
          'q013': const ReflexAnswerValue(yesNoUnknown: true),
        },
        moduleIndex: 1,
        questionnaireFor: 'child',
      );
      expect(meta.filterAnswers, isEmpty);
      expect(meta.supersededItemIds, isEmpty);
      expect(meta.toJson().containsKey('filter_answers'), isFalse);
      expect(meta.toJson().containsKey('superseded_item_ids'), isFalse);
    });
  });

  group('adult age gate', () {
    test('eligible at 16, not at 15', () {
      final asOf = DateTime(2026, 8, 21);
      expect(
        isAdultQuestionnaireAgeEligible(DateTime(2010, 8, 21), asOf: asOf),
        isTrue,
      );
      expect(
        isAdultQuestionnaireAgeEligible(DateTime(2010, 8, 22), asOf: asOf),
        isFalse,
      );
    });
  });

  group('definition selection contract', () {
    test('child path keeps childParentQuestionnaireV1', () {
      expect(childParentQuestionnaireV1.type,
          ReflexQuestionnaireType.childParentReport);
      expect(adultSelfQuestionnaireV3.version, 'adult_v3');
    });
  });
}
