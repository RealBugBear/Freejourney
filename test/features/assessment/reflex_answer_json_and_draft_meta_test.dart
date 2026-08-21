import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/reflex_answer_json.dart';
import 'package:corejourney/features/assessment/domain/reflex_draft_meta.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';

void main() {
  group('reflexAnswerToJson / fromJson', () {
    test('child wire format stays yes/no/unknown only', () {
      expect(
        reflexAnswerToJson(const ReflexAnswerValue(yesNoUnknown: true)),
        {'answer': 'yes'},
      );
      expect(
        reflexAnswerToJson(const ReflexAnswerValue(yesNoUnknown: false)),
        {'answer': 'no'},
      );
      expect(
        reflexAnswerToJson(const ReflexAnswerValue(isUnknown: true)),
        {'answer': 'unknown'},
      );
    });

    test('adult not_applicable is a distinct fourth wire value', () {
      expect(
        reflexAnswerToJson(const ReflexAnswerValue(isNotApplicable: true)),
        {'answer': 'not_applicable'},
      );
    });

    test('round-trips all four adult answer choices', () {
      for (final choice in ReflexAnswerChoice.values) {
        final original = ReflexAnswerValue.fromChoice(choice);
        final restored = reflexAnswerFromJson(reflexAnswerToJson(original));
        expect(restored.choice, choice, reason: choice.name);
        expect(restored.isNotApplicable, choice == ReflexAnswerChoice.notApplicable);
        expect(restored.isUnknown, choice == ReflexAnswerChoice.unknown);
      }
    });

    test('preserves months and free text alongside unknown-free answers', () {
      const original = ReflexAnswerValue(
        text: ' note ',
        months: 14,
        selectedOptionIds: ['a', 'b'],
      );
      final json = reflexAnswerToJson(original);
      expect(json.containsKey('answer'), isFalse);
      expect(json['text'], 'note');
      expect(json['months'], 14);
      expect(json['selected_options'], ['a', 'b']);

      final restored = reflexAnswerFromJson(json);
      expect(restored.text, 'note');
      expect(restored.months, 14);
      expect(restored.selectedOptionIds, ['a', 'b']);
    });
  });

  group('ReflexDraftMeta', () {
    test('round-trips version, filter answers, timings and module index', () {
      final original = ReflexDraftMeta(
        moduleIndex: 3,
        questionnaireFor: 'adult',
        questionnaireVersion: 'adult_v3',
        filterAnswers: const {
          'f_swim': 'yes',
          'f_drive': 'no',
          'f_handwriting': 'unknown',
        },
        startedAt: DateTime.utc(2026, 8, 21, 6, 0),
        moduleTimings: const {'lifeContext': 12.5, 'sensory': 40},
        supersededItemIds: const ['a040'],
      );

      final restored = ReflexDraftMeta.fromJson(original.toJson());
      expect(restored.moduleIndex, 3);
      expect(restored.questionnaireFor, 'adult');
      expect(restored.questionnaireVersion, 'adult_v3');
      expect(restored.filterAnswers, original.filterAnswers);
      expect(restored.startedAt, original.startedAt);
      expect(restored.moduleTimings['lifeContext'], 12.5);
      expect(restored.supersededItemIds, ['a040']);
    });

    test('legacy child meta without new fields still restores module index', () {
      final restored = ReflexDraftMeta.fromJson(const {
        'module_index': 2,
        'questionnaire_for': 'child',
      });
      expect(restored.moduleIndex, 2);
      expect(restored.questionnaireFor, 'child');
      expect(restored.questionnaireVersion, isNull);
      expect(restored.filterAnswers, isEmpty);
      expect(restored.startedAt, isNull);
      expect(restored.moduleTimings, isEmpty);
      expect(restored.supersededItemIds, isEmpty);
    });
  });
}
