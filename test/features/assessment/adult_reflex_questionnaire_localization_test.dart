import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/adult_reflex_questionnaire_definitions.dart';
import 'package:corejourney/features/assessment/domain/adult_reflex_result_copy.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';

void main() {
  group('adultSelfQuestionnaireV3 catalog', () {
    final questions = adultSelfQuestionnaireV3.questions;
    final byId = {for (final q in questions) q.id: q};

    test('stamps questionnaire identity and adult type', () {
      expect(adultSelfQuestionnaireV3.id, 'adult_self_reflex_profile');
      expect(adultSelfQuestionnaireV3.version, 'adult_v3');
      expect(
        adultSelfQuestionnaireV3.type,
        ReflexQuestionnaireType.adultSelfReport,
      );
    });

    test('contains 110 items with expected role counts', () {
      expect(questions, hasLength(110));

      final filters = questions
          .where((q) => q.providesFilter != null)
          .map((q) => q.id)
          .toList();
      expect(
        filters,
        [
          'f_swim',
          'f_screen',
          'f_desk',
          'f_drive',
          'f_passenger',
          'f_handwriting',
          'f_tools',
        ],
      );
      expect(
        questions.where((q) => q.role == ReflexQuestionRole.score),
        hasLength(87),
      );
      expect(
        questions.where((q) => q.role == ReflexQuestionRole.context),
        hasLength(11), // 7 filters + 4 document context items
      );
      expect(
        questions.where((q) => q.role == ReflexQuestionRole.safety),
        hasLength(10),
      );
      expect(
        questions.where((q) => q.role == ReflexQuestionRole.movement),
        hasLength(2),
      );
    });

    test('covers all 14 adult modules including lifeContext', () {
      expect(
        questions.map((q) => q.adultModule).toSet(),
        AdultQuestionModule.values.toSet(),
      );
    });

    test('does not invent deleted handwriting IDs s067 or s071', () {
      expect(byId.containsKey('s067'), isFalse);
      expect(byId.containsKey('s071'), isFalse);
      expect(
        byId['f_handwriting']!.providesFilter,
        ApplicabilityFilter.handwriting,
      );
      expect(
        questions
            .where(
              (q) => q.requiresFilters.contains(ApplicabilityFilter.handwriting),
            )
            .map((q) => q.id)
            .toSet(),
        {
          's061',
          's066',
          's068',
          's069',
          's070',
          's072',
          's073',
          's074',
          'a074',
        },
      );
    });

    test('maps representative items to document reflexes and polarity', () {
      expect(
        byId['s013']!.reflexes,
        [PrimitiveReflex.babinski, PrimitiveReflex.plantar],
      );
      expect(byId['s013']!.polarity, ReflexItemPolarity.direct);
      expect(byId['s013']!.role, ReflexQuestionRole.score);

      expect(byId['s046']!.role, ReflexQuestionRole.safety);
      expect(
        byId['s046']!.reflexes,
        [PrimitiveReflex.atnr, PrimitiveReflex.stnr],
      );

      expect(byId['s078']!.role, ReflexQuestionRole.context);
      expect(byId['s078']!.reflexes, isEmpty);

      expect(byId['s005']!.role, ReflexQuestionRole.movement);
      expect(byId['s005']!.polarity, ReflexItemPolarity.inverse);
      expect(
        byId['s005']!.requiresFilters,
        {ApplicabilityFilter.afterSafetyCleared},
      );

      expect(
        byId['s017']!.reflexes,
        [
          PrimitiveReflex.spinalGalant,
          PrimitiveReflex.stnr,
          PrimitiveReflex.amphibian,
        ],
      );
      expect(byId['s102']!.reflexes, [PrimitiveReflex.amphibian]);
    });

    test('marks multi-reflex expert-pending items from the plan', () {
      for (final id in ['s029', 's063', 's023', 's072', 's005', 's006', 's017', 's102']) {
        expect(
          byId[id]!.approvalStatus,
          ReflexContentApprovalStatus.expertPending,
          reason: id,
        );
      }
    });

    test('preserves representative German source wording exactly', () {
      expect(
        byId['s013']!.textDe,
        'Sind deine Fußsohlen so empfindlich oder kitzelig, dass du '
        'Berührungen dort ungern zulässt – etwa bei Fußpflege, Massage oder '
        'beim Schuhkauf?',
      );
      expect(
        byId['s063']!.textDe,
        'Wird dir häufiger zurückgemeldet, dass du undeutlich sprichst oder '
        'bestimmte Laute schwer verständlich aussprichst?',
      );
      expect(
        byId['s102']!.textDe,
        'Hast du deine Pubertät rückblickend als ungewöhnlich schwierig oder '
        'körperlich stark belastend erlebt?',
      );
    });

    test('provides nonempty paired DE/EN copy for every adult item', () {
      expect(adultSelfQuestionnaireV3.titleDe.trim(), isNotEmpty);
      expect(adultSelfQuestionnaireV3.titleEn.trim(), isNotEmpty);

      for (final question in questions) {
        expect(question.textDe.trim(), isNotEmpty, reason: question.id);
        expect(question.textEn.trim(), isNotEmpty, reason: question.id);
        expect(question.adultModule, isNotNull, reason: question.id);
      }

      for (final module in AdultQuestionModule.values) {
        expect(module.copy.titleDe.trim(), isNotEmpty);
        expect(module.copy.titleEn.trim(), isNotEmpty);
      }
    });

    test('adult English item copy avoids German orthography', () {
      final englishCopy = [
        for (final question in questions) question.textEn,
        for (final module in AdultQuestionModule.values) module.copy.titleEn,
      ].join('\n');

      expect(englishCopy, isNot(matches(RegExp(r'[äöüÄÖÜß]'))));
    });
  });

  group('adultReflexResultCopy', () {
    test('covers adult-relevant reflexes with expertPending placeholders', () {
      expect(adultReflexResultCopyByReflex.containsKey(PrimitiveReflex.delay),
          isFalse);
      expect(
        adultReflexResultCopyByReflex.keys,
        containsAll([
          PrimitiveReflex.flr,
          PrimitiveReflex.amphibian,
          PrimitiveReflex.rootingSucking,
        ]),
      );

      for (final entry in adultReflexResultCopyByReflex.entries) {
        expect(
          entry.value.approvalStatus,
          ReflexContentApprovalStatus.expertPending,
          reason: entry.key.name,
        );
        expect(entry.value.shortDescriptionDe.trim(), isNotEmpty);
        expect(entry.value.shortDescriptionEn.trim(), isNotEmpty);
        expect(entry.value.limitsDe, isNot(contains('Diagnose')));
        expect(entry.value.limitsEn.toLowerCase(), isNot(contains('diagnos')));
        expect(entry.value.shortDescriptionDe, isNot(contains('Reflex aktiv')));
      }
    });
  });

  group('domain extensions stay child-compatible', () {
    test('ReflexAnswerValue choice helpers round-trip four adult answers', () {
      expect(
        ReflexAnswerValue.fromChoice(ReflexAnswerChoice.yes).choice,
        ReflexAnswerChoice.yes,
      );
      expect(
        ReflexAnswerValue.fromChoice(ReflexAnswerChoice.no).choice,
        ReflexAnswerChoice.no,
      );
      expect(
        ReflexAnswerValue.fromChoice(ReflexAnswerChoice.unknown).choice,
        ReflexAnswerChoice.unknown,
      );
      expect(
        ReflexAnswerValue.fromChoice(ReflexAnswerChoice.notApplicable).choice,
        ReflexAnswerChoice.notApplicable,
      );
    });

    test('amphibian label is available without German chars in English', () {
      expect(PrimitiveReflex.amphibian.label('de'), 'Amphibienreflex');
      expect(PrimitiveReflex.amphibian.label('en'), 'Amphibian Reflex');
      expect(PrimitiveReflex.amphibian.label('en'), isNot(contains('ä')));
    });
  });
}
