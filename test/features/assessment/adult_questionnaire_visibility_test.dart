import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/adult_questionnaire_visibility.dart';
import 'package:corejourney/features/assessment/domain/adult_reflex_questionnaire_definitions.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';

void main() {
  group('AdultQuestionnaireVisibility', () {
    final definition = adultSelfQuestionnaireV3;

    AdultQuestionnaireVisibility visibility(
      Map<String, ReflexAnswerValue> answers, {
      bool movementEnabled = false,
    }) {
      return AdultQuestionnaireVisibility(
        definition: definition,
        answers: answers,
        movementChecksEnabled: movementEnabled,
      );
    }

    test('filter "no" hides dependents; "yes" and "?" keep them visible', () {
      final byId = {for (final q in definition.questions) q.id: q};
      expect(byId['s030']!.requiresFilters, {ApplicabilityFilter.swims});

      final hidden = visibility({
        'f_swim': const ReflexAnswerValue(yesNoUnknown: false),
      });
      expect(hidden.isVisible(byId['s030']!), isFalse);

      final shownYes = visibility({
        'f_swim': const ReflexAnswerValue(yesNoUnknown: true),
      });
      expect(shownYes.isVisible(byId['s030']!), isTrue);

      final shownUnknown = visibility({
        'f_swim': const ReflexAnswerValue(isUnknown: true),
      });
      expect(shownUnknown.isVisible(byId['s030']!), isTrue);

      final shownUnanswered = visibility(const {});
      expect(shownUnanswered.isVisible(byId['s030']!), isTrue);
    });

    test('f_handwriting no hides exactly the nine handwriting items', () {
      final hidden = visibility({
        'f_handwriting': const ReflexAnswerValue(yesNoUnknown: false),
      });
      final hiddenIds = hidden.visibleQuestions.map((q) => q.id).toSet();
      for (final id in [
        's061',
        's066',
        's068',
        's069',
        's070',
        's072',
        's073',
        's074',
        'a074',
      ]) {
        expect(hiddenIds.contains(id), isFalse, reason: id);
      }
      expect(hiddenIds.contains('s067'), isFalse);
      expect(hiddenIds.contains('s071'), isFalse);
      // Unrelated score item stays visible.
      expect(hiddenIds.contains('s013'), isTrue);
    });

    test('answered hidden items are listed as superseded and kept in answers', () {
      final answers = <String, ReflexAnswerValue>{
        'f_drive': const ReflexAnswerValue(yesNoUnknown: false),
        'a040': const ReflexAnswerValue(yesNoUnknown: true),
        'a042': const ReflexAnswerValue(yesNoUnknown: false),
      };
      final state = visibility(answers);
      expect(state.isVisible(definition.questions.firstWhere((q) => q.id == 'a040')),
          isFalse);
      expect(state.supersededAnswerIds, containsAll(['a040', 'a042']));
      // Draft map is untouched — answers remain for later resume.
      expect(answers['a040']!.choice, ReflexAnswerChoice.yes);
      expect(answers['a042']!.choice, ReflexAnswerChoice.no);

      // Flipping filter back to yes resurfaces the prior answers.
      answers['f_drive'] = const ReflexAnswerValue(yesNoUnknown: true);
      final resumed = visibility(answers);
      expect(resumed.isVisible(definition.questions.firstWhere((q) => q.id == 'a040')),
          isTrue);
      expect(resumed.supersededAnswerIds, isEmpty);
      expect(answers['a040']!.choice, ReflexAnswerChoice.yes);
    });

    test('movement items stay hidden while movementChecksEnabled is false', () {
      final state = visibility({
        // Even with safety answered, movement stays gated off.
        for (final q in definition.questions
            .where((q) => q.role == ReflexQuestionRole.safety))
          q.id: const ReflexAnswerValue(yesNoUnknown: false),
      });
      expect(
        state.visibleQuestions.any((q) => q.role == ReflexQuestionRole.movement),
        isFalse,
      );

      final enabled = visibility(
        {
          for (final q in definition.questions
              .where((q) => q.role == ReflexQuestionRole.safety))
            q.id: const ReflexAnswerValue(yesNoUnknown: false),
        },
        movementEnabled: true,
      );
      expect(
        enabled.visibleQuestions
            .where((q) => q.role == ReflexQuestionRole.movement)
            .map((q) => q.id)
            .toSet(),
        {'s005', 's006'},
      );
    });

    test('filterAnswersForMeta stores yes/no/unknown without answer bodies', () {
      final state = visibility({
        'f_swim': const ReflexAnswerValue(yesNoUnknown: true),
        'f_drive': const ReflexAnswerValue(yesNoUnknown: false),
        'f_handwriting': const ReflexAnswerValue(isUnknown: true),
        's013': const ReflexAnswerValue(yesNoUnknown: true),
      });
      expect(state.filterAnswersForMeta, {
        'f_swim': 'yes',
        'f_drive': 'no',
        'f_handwriting': 'unknown',
      });
    });
  });
}
