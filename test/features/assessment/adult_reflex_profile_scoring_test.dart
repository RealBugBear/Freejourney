import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:corejourney/features/assessment/domain/adult_reflex_profile_scoring.dart';
import 'package:corejourney/features/assessment/domain/adult_reflex_questionnaire_definitions.dart';
import 'package:corejourney/features/assessment/domain/reflex_profile_scoring.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire_definitions.dart';

void main() {
  const engine = AdultReflexProfileScoringService();
  final definition = adultSelfQuestionnaireV3;
  final byId = {for (final q in definition.questions) q.id: q};

  AdultQuestionnaireScore score(
    Map<String, ReflexAnswerValue> answers, {
    bool movement = false,
  }) {
    return engine.score(
      definition: definition,
      answers: answers,
      movementChecksEnabled: movement,
    );
  }

  group('§14.1 Adult scoring', () {
    test('1. direct item yes → +1 / no → 0', () {
      final yes = score({'s035': const ReflexAnswerValue(yesNoUnknown: true)});
      expect(yes.reflexScores[PrimitiveReflex.moro]!.positiveCount, 1);
      expect(yes.reflexScores[PrimitiveReflex.moro]!.answeredCount, 1);

      final no = score({'s035': const ReflexAnswerValue(yesNoUnknown: false)});
      expect(no.reflexScores[PrimitiveReflex.moro]!.positiveCount, 0);
      expect(no.reflexScores[PrimitiveReflex.moro]!.answeredCount, 1);
    });

    test('2. inverse item no → +1 / yes → 0', () {
      final fixture = _inverseOnlyDefinition();
      final no = engine.score(
        definition: fixture,
        answers: {'inv1': const ReflexAnswerValue(yesNoUnknown: false)},
        movementChecksEnabled: true,
      );
      expect(no.reflexScores[PrimitiveReflex.moro]!.positiveCount, 1);

      final yes = engine.score(
        definition: fixture,
        answers: {'inv1': const ReflexAnswerValue(yesNoUnknown: true)},
        movementChecksEnabled: true,
      );
      expect(yes.reflexScores[PrimitiveReflex.moro]!.positiveCount, 0);
    });

    test('3. unknown excluded from numerator and denominator', () {
      final result = score({
        's035': const ReflexAnswerValue(yesNoUnknown: true),
        's036': const ReflexAnswerValue(isUnknown: true),
      });
      final moro = result.reflexScores[PrimitiveReflex.moro]!;
      expect(moro.answeredCount, 1);
      expect(moro.positiveCount, 1);
      expect(moro.unknownCount, greaterThanOrEqualTo(1));
      expect(moro.percent, 100);
      expect(result.meta.unknownItemIds, contains('s036'));
    });

    test('4. not_applicable excluded likewise', () {
      final result = score({
        's035': const ReflexAnswerValue(yesNoUnknown: true),
        's036': const ReflexAnswerValue(isNotApplicable: true),
      });
      final moro = result.reflexScores[PrimitiveReflex.moro]!;
      expect(moro.answeredCount, 1);
      expect(moro.notApplicableCount, greaterThanOrEqualTo(1));
      expect(moro.percent, 100);
      expect(result.meta.notApplicableItemIds, contains('s036'));
    });

    test('5. context never scores', () {
      final result = score({
        'f_swim': const ReflexAnswerValue(yesNoUnknown: true),
        's099': const ReflexAnswerValue(yesNoUnknown: true),
      });
      for (final reflexScore in result.reflexScores.values) {
        expect(reflexScore.positiveCount, 0);
        expect(reflexScore.answeredCount, 0);
      }
    });

    test('6. safety without reflexes never scores', () {
      expect(byId['a129']!.reflexes, isEmpty);
      expect(byId['a129']!.role, ReflexQuestionRole.safety);
      expect(
        adultQuestionScores(byId['a129']!, movementEnabled: false),
        isFalse,
      );

      final result = score({
        'a129': const ReflexAnswerValue(yesNoUnknown: true),
      });
      for (final reflexScore in result.reflexScores.values) {
        expect(reflexScore.answeredCount, 0);
        expect(reflexScore.positiveCount, 0);
      }
    });

    test('7. s046 scores only ATNR and STNR', () {
      expect(byId['s046']!.role, ReflexQuestionRole.safety);
      expect(byId['s046']!.contributesToScore, isFalse);
      expect(
        adultQuestionScores(byId['s046']!, movementEnabled: false),
        isTrue,
      );

      final result = score({
        's046': const ReflexAnswerValue(yesNoUnknown: true),
      });

      expect(result.reflexScores[PrimitiveReflex.atnr]!.positiveCount, 1);
      expect(result.reflexScores[PrimitiveReflex.stnr]!.positiveCount, 1);

      for (final entry in result.reflexScores.entries) {
        if (entry.key == PrimitiveReflex.atnr ||
            entry.key == PrimitiveReflex.stnr) {
          continue;
        }
        expect(entry.value.positiveCount, 0, reason: entry.key.name);
        expect(entry.value.answeredCount, 0, reason: entry.key.name);
      }
    });

    test('8. multi-map item increments multiple reflex buckets', () {
      final result = score({
        's017': const ReflexAnswerValue(yesNoUnknown: true),
      });
      expect(result.reflexScores[PrimitiveReflex.spinalGalant]!.positiveCount, 1);
      expect(result.reflexScores[PrimitiveReflex.stnr]!.positiveCount, 1);
      expect(result.amphibian.positiveCount, 1);
      expect(result.amphibian.answeredCount, 1);
    });

    test('9. filter hides item → not in possibleCount', () {
      final open = score(const {});
      final driveOpen = open.reflexScores[PrimitiveReflex.atnr]?.possibleCount ?? 0;

      final hidden = score({
        'f_drive': const ReflexAnswerValue(yesNoUnknown: false),
        'a040': const ReflexAnswerValue(yesNoUnknown: true),
      });
      expect(hidden.meta.hiddenItemIds, contains('a040'));
      expect(
        hidden.reflexScores[PrimitiveReflex.atnr]!.possibleCount,
        lessThan(driveOpen),
      );
      // Answer retained but must not score while hidden.
      expect(hidden.reflexScores[PrimitiveReflex.atnr]!.positiveCount, 0);
    });

    test('10. denominator 0 → insufficientData, no percent', () {
      final result = score({
        for (final q in definition.questions
            .where((q) => q.reflexes.contains(PrimitiveReflex.moro) &&
                adultQuestionScores(q, movementEnabled: false)))
          q.id: const ReflexAnswerValue(isUnknown: true),
      });
      final moro = result.reflexScores[PrimitiveReflex.moro]!;
      expect(moro.answeredCount, 0);
      expect(moro.percent, isNull);
      expect(moro.percentDisplay, isNull);
      expect(moro.band, AdultHintBand.insufficientData);
    });

    test('11. thresholds 29/30, 59/60, 79/80', () {
      expect(adultBandFor(29), AdultHintBand.fewMatching);
      expect(adultBandFor(30), AdultHintBand.someMatching);
      expect(adultBandFor(59), AdultHintBand.someMatching);
      expect(adultBandFor(60), AdultHintBand.clusteredPattern);
      expect(adultBandFor(79), AdultHintBand.clusteredPattern);
      expect(adultBandFor(80), AdultHintBand.stronglyClustered);
      expect(adultBandFor(null), AdultHintBand.insufficientData);

      // Stable display rounding: 1/3 → 33.
      final third = engine.score(
        definition: _nineMoroDefinition(),
        answers: {
          'm1': const ReflexAnswerValue(yesNoUnknown: true),
          'm2': const ReflexAnswerValue(yesNoUnknown: false),
          'm3': const ReflexAnswerValue(yesNoUnknown: false),
        },
      );
      final moro = third.reflexScores[PrimitiveReflex.moro]!;
      expect(moro.percentDisplay, 33);
    });

    test('12. amphibian 0/1/2 display + disclaimer flag', () {
      final none = score({
        's017': const ReflexAnswerValue(yesNoUnknown: false),
        's102': const ReflexAnswerValue(yesNoUnknown: false),
      });
      expect(none.amphibian.display, AmphibianDisplay.noneMatching);
      expect(none.amphibian.showDisclaimer, isTrue);

      final one = score({
        's017': const ReflexAnswerValue(yesNoUnknown: true),
        's102': const ReflexAnswerValue(yesNoUnknown: false),
      });
      expect(one.amphibian.display, AmphibianDisplay.singleHint);
      expect(one.amphibian.positiveCount, 1);

      final two = score({
        's017': const ReflexAnswerValue(yesNoUnknown: true),
        's102': const ReflexAnswerValue(yesNoUnknown: true),
      });
      expect(two.amphibian.display, AmphibianDisplay.clearSingleHint);
      expect(two.amphibian.positiveCount, 2);

      // s017 still scores Galant/STNR normally.
      expect(two.reflexScores[PrimitiveReflex.spinalGalant]!.positiveCount, 1);
      expect(two.reflexScores[PrimitiveReflex.stnr]!.positiveCount, 1);
    });

    test('13. passing child definition into adult engine throws', () {
      expect(
        () => engine.score(
          definition: childParentQuestionnaireV1,
          answers: const {},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('14. child engine golden still passes unchanged', () {
      const childEngine = ReflexProfileScoringService();
      final childScore = childEngine.score(
        definition: childParentQuestionnaireV1,
        answers: {
          'q013': const ReflexAnswerValue(yesNoUnknown: true),
        },
      );
      expect(childScore.reflexScores, isNotEmpty);
      final first = childScore.reflexScores.values.first;
      expect(first.toJson().containsKey('yes_count'), isTrue);
      expect(first.toJson().containsKey('positive_count'), isFalse);
    });

    test('14a. invariant answered+unknown+n.a.+missing == possible_count', () {
      final rng = Random(42);
      final choices = [
        null,
        const ReflexAnswerValue(yesNoUnknown: true),
        const ReflexAnswerValue(yesNoUnknown: false),
        const ReflexAnswerValue(isUnknown: true),
        const ReflexAnswerValue(isNotApplicable: true),
      ];

      for (var trial = 0; trial < 40; trial++) {
        final answers = <String, ReflexAnswerValue>{};
        for (final q in definition.questions) {
          final pick = choices[rng.nextInt(choices.length)];
          if (pick != null) answers[q.id] = pick;
        }
        final movement = trial.isEven;
        final result = score(answers, movement: movement);
        for (final reflexScore in result.reflexScores.values) {
          expect(
            reflexScore.satisfiesPartitionInvariant,
            isTrue,
            reason:
                'trial=$trial reflex=${reflexScore.reflex.name} '
                'a=${reflexScore.answeredCount} u=${reflexScore.unknownCount} '
                'n=${reflexScore.notApplicableCount} m=${reflexScore.missingCount} '
                'p=${reflexScore.possibleCount}',
          );
        }
        expect(result.meta.toJson().containsKey('movement_included'), isTrue);
      }
    });

    test('14b. possible_count is visible items, not unanswered leftovers', () {
      final result = engine.score(
        definition: _nineMoroDefinition(),
        answers: {
          'm1': const ReflexAnswerValue(yesNoUnknown: true),
          'm2': const ReflexAnswerValue(yesNoUnknown: true),
          'm3': const ReflexAnswerValue(yesNoUnknown: false),
          'm4': const ReflexAnswerValue(yesNoUnknown: false),
          'm5': const ReflexAnswerValue(yesNoUnknown: true),
          'm6': const ReflexAnswerValue(yesNoUnknown: false),
          'm7': const ReflexAnswerValue(yesNoUnknown: true),
          // m8, m9 missing
        },
      );
      final moro = result.reflexScores[PrimitiveReflex.moro]!;
      expect(moro.answeredCount, 7);
      expect(moro.possibleCount, 9);
      expect(moro.missingCount, 2);
      // The buggy first-draft semantics would have set possible_count to the
      // unanswered leftover (2). Visible-item semantics keep it at 9.
      expect(moro.possibleCount, isNot(moro.missingCount));
      expect(moro.satisfiesPartitionInvariant, isTrue);
    });

    test('14c. filter "?" does not hide; only "no" removes dependents', () {
      final handwritingIds = definition.questions
          .where(
            (q) => q.requiresFilters.contains(ApplicabilityFilter.handwriting),
          )
          .map((q) => q.id)
          .toSet();
      expect(handwritingIds.length, 9);

      final withUnknown = score({
        'f_handwriting': const ReflexAnswerValue(isUnknown: true),
      });
      expect(
        handwritingIds
            .where((id) => !withUnknown.meta.hiddenItemIds.contains(id))
            .length,
        9,
      );

      final withNo = score({
        'f_handwriting': const ReflexAnswerValue(yesNoUnknown: false),
      });
      expect(
        handwritingIds
            .where((id) => !withNo.meta.hiddenItemIds.contains(id))
            .length,
        0,
      );
      for (final id in handwritingIds) {
        expect(withNo.meta.hiddenItemIds, contains(id));
      }

      final palmarOpen =
          withUnknown.reflexScores[PrimitiveReflex.palmar]?.possibleCount ?? 0;
      final palmarHidden =
          withNo.reflexScores[PrimitiveReflex.palmar]?.possibleCount ?? 0;
      expect(palmarHidden, lessThan(palmarOpen));
    });

    test('14d. meta.movement_included always set; possible_count differs ON/OFF', () {
      final safetyAnswers = {
        for (final q in definition.questions
            .where((q) => q.role == ReflexQuestionRole.safety))
          q.id: const ReflexAnswerValue(yesNoUnknown: false),
      };

      final off = score(safetyAnswers);
      final on = score(safetyAnswers, movement: true);

      expect(off.meta.movementIncluded, isFalse);
      expect(on.meta.movementIncluded, isTrue);
      expect(off.toJson()['meta']['movement_included'], isFalse);
      expect(on.toJson()['meta']['movement_included'], isTrue);

      for (final reflex in [
        PrimitiveReflex.babinski,
        PrimitiveReflex.flr,
        PrimitiveReflex.moro,
        PrimitiveReflex.tlr,
        PrimitiveReflex.atnr,
        PrimitiveReflex.righting,
      ]) {
        final offCount = off.reflexScores[reflex]?.possibleCount ?? 0;
        final onCount = on.reflexScores[reflex]?.possibleCount ?? 0;
        expect(onCount, greaterThan(offCount), reason: reflex.name);
      }
    });
  });
}

ReflexQuestionnaireDefinition _inverseOnlyDefinition() {
  return const ReflexQuestionnaireDefinition(
    id: 'adult_inverse_fixture',
    version: 'adult_v3',
    type: ReflexQuestionnaireType.adultSelfReport,
    titleDe: 'Fixture',
    titleEn: 'Fixture',
    screenTitleDe: 'Fixture',
    screenTitleEn: 'Fixture',
    scoring: ReflexScoringDefinition(
      strongPercent: 100,
      elevatedPercent: 80,
      indicationPercent: 50,
    ),
    questions: [
      ReflexQuestion(
        id: 'inv1',
        number: 1,
        module: ReflexQuestionModule.other,
        adultModule: AdultQuestionModule.movementOptional,
        textDe: 'Inverse fixture',
        textEn: 'Inverse fixture',
        answerType: ReflexAnswerType.yesNoUnknownNotApplicable,
        role: ReflexQuestionRole.movement,
        reflexes: [PrimitiveReflex.moro],
        polarity: ReflexItemPolarity.inverse,
      ),
    ],
  );
}

ReflexQuestionnaireDefinition _nineMoroDefinition() {
  ReflexQuestion item(String id) {
    return ReflexQuestion(
      id: id,
      number: int.parse(id.substring(1)),
      module: ReflexQuestionModule.other,
      adultModule: AdultQuestionModule.sensory,
      textDe: id,
      textEn: id,
      answerType: ReflexAnswerType.yesNoUnknownNotApplicable,
      role: ReflexQuestionRole.score,
      reflexes: const [PrimitiveReflex.moro],
      polarity: ReflexItemPolarity.direct,
    );
  }

  return ReflexQuestionnaireDefinition(
    id: 'adult_nine_moro_fixture',
    version: 'adult_v3',
    type: ReflexQuestionnaireType.adultSelfReport,
    titleDe: 'Fixture',
    titleEn: 'Fixture',
    screenTitleDe: 'Fixture',
    screenTitleEn: 'Fixture',
    scoring: const ReflexScoringDefinition(
      strongPercent: 100,
      elevatedPercent: 80,
      indicationPercent: 50,
    ),
    questions: [
      for (var i = 1; i <= 9; i++) item('m$i'),
    ],
  );
}
