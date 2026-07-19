import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire_definitions.dart';
import 'package:corejourney/features/assessment/presentation/screens/reflex_profile_result_helpers.dart';
import 'package:corejourney/features/assessment/presentation/widgets/reflex_radar_chart.dart';

void main() {
  group('reflex questionnaire bilingual content', () {
    test('preserves questionnaire, question, and module counts', () {
      expect(childParentQuestionnaireV1.questions, hasLength(109));
      expect(
        childParentQuestionnaireV1.questions.map((question) => question.id),
        [for (var number = 1; number <= 109; number++) _questionId(number)],
      );
      expect(
        childParentQuestionnaireV1.questions
            .map((question) => question.module)
            .toSet(),
        ReflexQuestionModule.values.toSet(),
      );

      expect(demoChildShortQuestionnaireV1.questions, hasLength(14));
      expect(
        demoChildShortQuestionnaireV1.questions.map((question) => question.id),
        const [
          'demo_delay',
          'demo_flr',
          'demo_moro',
          'demo_spinal_galant',
          'demo_tlr',
          'demo_atnr',
          'demo_stnr',
          'demo_landau',
          'demo_babinski',
          'demo_babkin',
          'demo_plantar',
          'demo_palmar',
          'demo_righting',
          'demo_rooting_sucking',
        ],
      );
    });

    test('provides nonempty paired copy for every definition and question', () {
      for (final definition in [
        childParentQuestionnaireV1,
        demoChildShortQuestionnaireV1,
      ]) {
        expect(definition.titleDe.trim(), isNotEmpty);
        expect(definition.titleEn.trim(), isNotEmpty);
        expect(definition.screenTitleDe.trim(), isNotEmpty);
        expect(definition.screenTitleEn.trim(), isNotEmpty);

        for (final question in definition.questions) {
          expect(question.textDe.trim(), isNotEmpty, reason: question.id);
          expect(question.textEn.trim(), isNotEmpty, reason: question.id);
          expect(question.helpTextDe == null, question.helpTextEn == null,
              reason: '${question.id} help text parity');
          expect(
            question.trainerFlagLabelDe == null,
            question.trainerFlagLabelEn == null,
            reason: '${question.id} trainer flag parity',
          );
        }
      }

      for (final module in ReflexQuestionModule.values) {
        expect(module.copy.titleDe.trim(), isNotEmpty);
        expect(module.copy.titleEn.trim(), isNotEmpty);
        expect(module.copy.resultLabelDe.trim(), isNotEmpty);
        expect(module.copy.resultLabelEn.trim(), isNotEmpty);
      }
    });

    test('preserves representative German source copy exactly', () {
      final questions = {
        for (final question in childParentQuestionnaireV1.questions)
          question.id: question,
      };

      expect(
        questions['q001']!.textDe,
        'Gab es während der Schwangerschaft gesundheitliche Probleme?',
      );
      expect(
        questions['q022']!.textDe,
        'Neigt dein Kind den Kopf oft nach unten, der Blick geht aber von unten nach oben? (Misstrauischer Blick)',
      );
      expect(
        questions['q022']!.helpTextDe,
        'Gemeint ist die beobachtbare Kopf- und Blickhaltung, nicht eine Bewertung des Verhaltens.',
      );
      expect(questions['q057']!.trainerFlagLabelDe, 'ADHS / ADS');
      expect(
        questions['q088']!.helpTextDe,
        'Dyskalkulie ist eine Rechenschwäche, bei der das Verstehen von Zahlen und mathematischen Zusammenhängen trotz normaler Intelligenz dauerhaft schwerfällt. Im Alltag zeigt sich das z. B. durch: Schwierigkeiten beim Wechselgeld zählen, Uhr lesen, Zahlen merken, Mengen schätzen oder bei einfachen Rechenaufgaben immer wieder neu anfangen müssen.',
      );
      expect(
        questions['q109']!.textDe,
        'Ist dein Kind in psychologischer oder psychiatrischer Behandlung?',
      );
      expect(
        demoChildShortQuestionnaireV1.questions
            .singleWhere((question) => question.id == 'demo_landau')
            .textDe,
        'Hat oder hatte dein Kind Probleme beim Schwimmenlernen, besonders beim Brustschwimmen?',
      );
    });

    test('English copy contains no German residue and uses FPR, not FLR', () {
      final englishCopy = <String>[
        childParentQuestionnaireV1.titleEn,
        childParentQuestionnaireV1.screenTitleEn,
        demoChildShortQuestionnaireV1.titleEn,
        demoChildShortQuestionnaireV1.screenTitleEn,
        for (final definition in [
          childParentQuestionnaireV1,
          demoChildShortQuestionnaireV1,
        ])
          for (final question in definition.questions) ...[
            question.textEn,
            if (question.helpTextEn case final helpText?) helpText,
            if (question.trainerFlagLabelEn case final flagLabel?) flagLabel,
          ],
        for (final module in ReflexQuestionModule.values) ...[
          module.copy.titleEn,
          module.copy.resultLabelEn,
        ],
        for (final reflex in PrimitiveReflex.values) reflex.label('en'),
      ].join('\n');

      expect(englishCopy, isNot(matches(RegExp(r'[äöüÄÖÜß]'))));
      expect(
        englishCopy,
        isNot(matches(RegExp(
          r'\b(?:dein|deine|Kind|Schwangerschaft|Geburt|Frage|Reflexprofil|Sonstiges)\b',
        ))),
      );
      expect(englishCopy, isNot(contains('FLR')));
      expect(PrimitiveReflex.flr.label('en'), contains('FPR'));
      expect(PrimitiveReflex.flr.shortLabel('en'), 'FPR');
      expect(PrimitiveReflex.flr.label('de'), 'FLR');
    });

    test('locale-aware consumers select English and preserve German', () {
      final question = childParentQuestionnaireV1.questions.first;

      expect(question.text('de'), question.textDe);
      expect(question.text('en'), question.textEn);
      expect(
        childParentQuestionnaireV1.title('de'),
        'Reflexprofil für Kinder',
      );
      expect(
        childParentQuestionnaireV1.title('en'),
        'Reflex Profile for Children',
      );
      expect(childParentQuestionnaireV1.screenTitle('de'), 'Reflexprofil');
      expect(childParentQuestionnaireV1.screenTitle('en'), 'Reflex Profile');
      expect(
        reflexModuleLabel(ReflexQuestionModule.pregnancyBirth, 'de'),
        'Schwangerschaft & Geburt',
      );
      expect(
        reflexModuleLabel(ReflexQuestionModule.pregnancyBirth, 'en'),
        'Pregnancy & Birth',
      );

      const scores = {
        'flr': {
          'percent': 75,
        },
      };
      expect(radarScoresFromAssessment(scores, 'de').single.label, 'FLR');
      expect(
        radarScoresFromAssessment(scores, 'en').single.label,
        contains('FPR'),
      );
      // The chart paints shortLabel, so it must stay compact in both languages.
      expect(radarScoresFromAssessment(scores, 'en').single.shortLabel, 'FPR');
    });
  });
}

String _questionId(int number) => 'q${number.toString().padLeft(3, '0')}';
