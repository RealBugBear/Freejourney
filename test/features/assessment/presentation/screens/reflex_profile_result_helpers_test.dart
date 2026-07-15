import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/assessment/domain/models/reflex_profile_assessment.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/presentation/screens/reflex_profile_result_helpers.dart';

ReflexProfileAssessment _assessment(Map<String, dynamic> answers) =>
    ReflexProfileAssessment(
      id: 'test',
      questionnaireType: 'child_parent_report',
      questionnaireVersion: 'child_parent_v2_2026_05',
      scoringVersion: 'score_equal_weight_v1',
      status: 'completed',
      answers: answers,
      scores: const {},
      warningConfirmations: const [],
      safetyStatus: 'clear',
      createdAt: DateTime(2026, 5, 13),
    );

void main() {
  group('buildRelevanteAngaben', () {
    test('pure yes/no answer is excluded', () {
      final result = buildRelevanteAngaben(_assessment({
        'q001': {'answer': 'yes'},
      }));
      expect(result, isEmpty);
    });

    test('pure no answer is excluded', () {
      final result = buildRelevanteAngaben(_assessment({
        'q001': {'answer': 'no'},
      }));
      expect(result, isEmpty);
    });

    test('selected_options only (no text/months) is excluded', () {
      final result = buildRelevanteAngaben(_assessment({
        'q006': {
          'answer': 'yes',
          'selected_options': ['vacuum', 'forceps'],
        },
      }));
      expect(result, isEmpty);
    });

    test('free text is included and trimmed', () {
      // q009 = "Sonstiges zur Geburt", freeText, pregnancyBirth
      final result = buildRelevanteAngaben(_assessment({
        'q009': {'text': '  Nabelschnur zweimal gewickelt  '},
      }));
      expect(result.length, 1);
      expect(result.first.$2.first.freeText, 'Nabelschnur zweimal gewickelt');
      expect(result.first.$2.first.selectedOptionLabels, isEmpty);
    });

    test('blank free text is excluded', () {
      final result = buildRelevanteAngaben(_assessment({
        'q009': {'text': '   '},
      }));
      expect(result, isEmpty);
    });

    test('months value is included', () {
      // q033 = "Wann ist dein Kind das erste Mal gelaufen?", monthsNumber, motorSkills
      final result = buildRelevanteAngaben(_assessment({
        'q033': {'months': 18},
      }));
      expect(result.length, 1);
      final (module, items) = result.first;
      expect(module, ReflexQuestionModule.motorSkills);
      expect(items.first.months, 18);
    });

    test('unknown question ID is silently skipped', () {
      final result = buildRelevanteAngaben(_assessment({
        'q_nonexistent': {
          'selected_options': ['foo']
        },
      }));
      expect(result, isEmpty);
    });

    test('selected_options only with unknown option ID is excluded', () {
      final result = buildRelevanteAngaben(_assessment({
        'q006': {
          'selected_options': ['unknown_option_xyz']
        },
      }));
      expect(result, isEmpty);
    });

    test(
        'groups are ordered by module enum order regardless of answer insertion order',
        () {
      // q033 = motorSkills (enum index 2), q009 = pregnancyBirth (enum index 0)
      // Insert in reverse order to verify enum-order output
      final result = buildRelevanteAngaben(_assessment({
        'q033': {'months': 18}, // motorSkills
        'q009': {'text': 'Sturzgeburt'}, // pregnancyBirth
      }));
      expect(result.length, 2);
      expect(result[0].$1, ReflexQuestionModule.pregnancyBirth);
      expect(result[1].$1, ReflexQuestionModule.motorSkills);
    });

    test('multiple answers in same module appear in the same group', () {
      // q006 and q009 are both pregnancyBirth
      final result = buildRelevanteAngaben(_assessment({
        'q006': {'text': 'Zange verwendet'},
        'q009': {'text': 'Sturzgeburt'},
      }));
      expect(result.length, 1);
      expect(result.first.$2.length, 2);
    });

    test('items within a module group are sorted by question number', () {
      // q009 (number 9) and q006 (number 6) are both pregnancyBirth
      // Insert q009 first — output should still be q006 first (lower number)
      final result = buildRelevanteAngaben(_assessment({
        'q009': {'text': 'Sturzgeburt'}, // question number 9
        'q006': {'text': 'Zange verwendet'}, // question number 6
      }));
      expect(result.length, 1);
      final items = result.first.$2;
      expect(items.length, 2);
      expect(items[0].question.number, 6);
      expect(items[1].question.number, 9);
    });
  });

  group('reflexModuleLabel', () {
    test('returns correct German label for every module', () {
      expect(reflexModuleLabel(ReflexQuestionModule.pregnancyBirth, 'de'),
          'Schwangerschaft & Geburt');
      expect(reflexModuleLabel(ReflexQuestionModule.posturePerception, 'de'),
          'Haltung & Wahrnehmung');
      expect(
          reflexModuleLabel(ReflexQuestionModule.motorSkills, 'de'), 'Motorik');
      expect(reflexModuleLabel(ReflexQuestionModule.behaviorEmotion, 'de'),
          'Verhalten & Emotionen');
      expect(reflexModuleLabel(ReflexQuestionModule.speech, 'de'), 'Sprache');
      expect(reflexModuleLabel(ReflexQuestionModule.drawingWriting, 'de'),
          'Zeichnen & Schreiben');
      expect(reflexModuleLabel(ReflexQuestionModule.school, 'de'),
          'Schule & Konzentration');
      expect(reflexModuleLabel(ReflexQuestionModule.other, 'de'),
          'Weitere Beobachtungen');
    });
  });
}
