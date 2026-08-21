import 'adult_questionnaire_visibility.dart';
import 'reflex_questionnaire.dart';

const kAdultScoringVersion = 'adult_equal_weight_v1';

/// Adult equal-weight scoring (§7). Must not reuse [ReflexQuestion.contributesToScore]
/// — that getter excludes safety items with reflexes (s046).
class AdultReflexProfileScoringService {
  const AdultReflexProfileScoringService();

  AdultQuestionnaireScore score({
    required ReflexQuestionnaireDefinition definition,
    required Map<String, ReflexAnswerValue> answers,
    bool movementChecksEnabled = false,
  }) {
    if (definition.version != 'adult_v3' ||
        definition.type != ReflexQuestionnaireType.adultSelfReport) {
      throw ArgumentError(
        'AdultReflexProfileScoringService only accepts adult_v3 '
        '(adultSelfReport); got version=${definition.version} '
        'type=${definition.type.name}',
      );
    }

    final visibility = AdultQuestionnaireVisibility(
      definition: definition,
      answers: answers,
      movementChecksEnabled: movementChecksEnabled,
    );

    final buckets = <PrimitiveReflex, _AdultScoreBucket>{
      for (final reflex in PrimitiveReflex.values)
        if (reflex != PrimitiveReflex.amphibian) reflex: _AdultScoreBucket(),
    };

    var amphPositive = 0;
    var amphAnswered = 0;

    final unknownItemIds = <String>[];
    final notApplicableItemIds = <String>[];
    final hiddenItemIds = <String>[];

    for (final question in definition.questions) {
      final answer = answers[question.id];
      final visible = visibility.isVisible(question);

      if (!visible) {
        hiddenItemIds.add(question.id);
        continue;
      }

      if (answer?.isUnknown == true) {
        unknownItemIds.add(question.id);
      } else if (answer?.isNotApplicable == true) {
        notApplicableItemIds.add(question.id);
      }

      if (!_adultScores(question, movementEnabled: movementChecksEnabled)) {
        continue;
      }

      final classification = _classifyAnswer(answer);

      for (final reflex in question.reflexes) {
        if (reflex == PrimitiveReflex.amphibian) {
          if (classification == _AnswerClass.yesNo) {
            amphAnswered += 1;
            if (_isPositiveIndication(question, answer!)) {
              amphPositive += 1;
            }
          }
          continue;
        }

        final bucket = buckets[reflex]!;
        bucket.possibleCount += 1;
        switch (classification) {
          case _AnswerClass.missing:
            bucket.missingCount += 1;
          case _AnswerClass.unknown:
            bucket.unknownCount += 1;
          case _AnswerClass.notApplicable:
            bucket.notApplicableCount += 1;
          case _AnswerClass.yesNo:
            bucket.answeredCount += 1;
            if (_isPositiveIndication(question, answer!)) {
              bucket.positiveCount += 1;
            }
        }
      }
    }

    final reflexScores = <PrimitiveReflex, AdultReflexScoreResult>{
      for (final entry in buckets.entries)
        if (entry.value.possibleCount > 0)
          entry.key: entry.value.toResult(entry.key),
    };

    return AdultQuestionnaireScore(
      scoringVersion: kAdultScoringVersion,
      questionnaireVersion: definition.version,
      reflexScores: reflexScores,
      amphibian: AdultAmphibianScore(
        positiveCount: amphPositive,
        answeredCount: amphAnswered,
        display: _amphibianDisplay(amphPositive),
        showDisclaimer: true,
      ),
      meta: AdultScoreMeta(
        hiddenItemIds: List.unmodifiable(hiddenItemIds),
        notApplicableItemIds: List.unmodifiable(notApplicableItemIds),
        unknownItemIds: List.unmodifiable(unknownItemIds),
        noPublicTotalScore: true,
        movementIncluded: movementChecksEnabled,
        filterAnswers: visibility.filterAnswersForMeta,
      ),
    );
  }
}

/// Own adult scoring predicate (§7.2). Do not call [ReflexQuestion.contributesToScore].
bool adultQuestionScores(
  ReflexQuestion question, {
  required bool movementEnabled,
}) =>
    _adultScores(question, movementEnabled: movementEnabled);

bool _adultScores(
  ReflexQuestion question, {
  required bool movementEnabled,
}) {
  if (question.reflexes.isEmpty) return false;
  return switch (question.role) {
    ReflexQuestionRole.score => true,
    ReflexQuestionRole.safety => true,
    ReflexQuestionRole.movement => movementEnabled,
    ReflexQuestionRole.context => false,
  };
}

bool _isPositiveIndication(
  ReflexQuestion question,
  ReflexAnswerValue answer,
) {
  final yes = answer.yesNoUnknown == true;
  final no = answer.yesNoUnknown == false;
  return switch (question.polarity) {
    ReflexItemPolarity.direct => yes,
    ReflexItemPolarity.inverse => no,
  };
}

_AnswerClass _classifyAnswer(ReflexAnswerValue? answer) {
  if (answer == null) return _AnswerClass.missing;
  if (answer.isNotApplicable) return _AnswerClass.notApplicable;
  if (answer.isUnknown) return _AnswerClass.unknown;
  if (answer.yesNoUnknown != null) return _AnswerClass.yesNo;
  return _AnswerClass.missing;
}

AmphibianDisplay _amphibianDisplay(int positiveCount) {
  return switch (positiveCount) {
    0 => AmphibianDisplay.noneMatching,
    1 => AmphibianDisplay.singleHint,
    _ => AmphibianDisplay.clearSingleHint,
  };
}

AdultHintBand adultBandFor(double? percent) {
  if (percent == null) return AdultHintBand.insufficientData;
  if (percent < 30) return AdultHintBand.fewMatching;
  if (percent < 60) return AdultHintBand.someMatching;
  if (percent < 80) return AdultHintBand.clusteredPattern;
  return AdultHintBand.stronglyClustered;
}

enum _AnswerClass { missing, unknown, notApplicable, yesNo }

class _AdultScoreBucket {
  int positiveCount = 0;
  int answeredCount = 0;
  int possibleCount = 0;
  int unknownCount = 0;
  int notApplicableCount = 0;
  int missingCount = 0;

  AdultReflexScoreResult toResult(PrimitiveReflex reflex) {
    final percent =
        answeredCount == 0 ? null : (positiveCount / answeredCount) * 100.0;
    return AdultReflexScoreResult(
      reflex: reflex,
      positiveCount: positiveCount,
      answeredCount: answeredCount,
      possibleCount: possibleCount,
      unknownCount: unknownCount,
      notApplicableCount: notApplicableCount,
      missingCount: missingCount,
      percent: percent,
      percentDisplay: percent?.round(),
      band: adultBandFor(percent),
    );
  }
}

class AdultReflexScoreResult {
  const AdultReflexScoreResult({
    required this.reflex,
    required this.positiveCount,
    required this.answeredCount,
    required this.possibleCount,
    required this.unknownCount,
    required this.notApplicableCount,
    required this.missingCount,
    required this.percent,
    required this.percentDisplay,
    required this.band,
  });

  final PrimitiveReflex reflex;
  final int positiveCount;
  final int answeredCount;
  final int possibleCount;
  final int unknownCount;
  final int notApplicableCount;
  final int missingCount;
  final double? percent;
  final int? percentDisplay;
  final AdultHintBand band;

  /// §7.1 invariant: partitions of possible_count.
  bool get satisfiesPartitionInvariant =>
      answeredCount +
          unknownCount +
          notApplicableCount +
          missingCount ==
      possibleCount;

  Map<String, dynamic> toJson() => {
        'positive_count': positiveCount,
        'answered_count': answeredCount,
        'possible_count': possibleCount,
        'percent': percent,
        'percent_display': percentDisplay,
        'band': band.name,
      };
}

class AdultAmphibianScore {
  const AdultAmphibianScore({
    required this.positiveCount,
    required this.answeredCount,
    required this.display,
    required this.showDisclaimer,
  });

  final int positiveCount;
  final int answeredCount;
  final AmphibianDisplay display;
  final bool showDisclaimer;

  Map<String, dynamic> toJson() => {
        'positive_count': positiveCount,
        'answered_count': answeredCount,
        'display': display.name,
        'show_disclaimer': showDisclaimer,
      };
}

class AdultScoreMeta {
  const AdultScoreMeta({
    required this.hiddenItemIds,
    required this.notApplicableItemIds,
    required this.unknownItemIds,
    required this.noPublicTotalScore,
    required this.movementIncluded,
    required this.filterAnswers,
  });

  final List<String> hiddenItemIds;
  final List<String> notApplicableItemIds;
  final List<String> unknownItemIds;
  final bool noPublicTotalScore;

  /// Always present (§7.5) — even when false.
  final bool movementIncluded;
  final Map<String, String> filterAnswers;

  Map<String, dynamic> toJson() => {
        'hidden_item_ids': hiddenItemIds,
        'not_applicable_item_ids': notApplicableItemIds,
        'unknown_item_ids': unknownItemIds,
        'no_public_total_score': noPublicTotalScore,
        'movement_included': movementIncluded,
        'filter_answers': filterAnswers,
      };
}

class AdultQuestionnaireScore {
  const AdultQuestionnaireScore({
    required this.scoringVersion,
    required this.questionnaireVersion,
    required this.reflexScores,
    required this.amphibian,
    required this.meta,
  });

  final String scoringVersion;
  final String questionnaireVersion;
  final Map<PrimitiveReflex, AdultReflexScoreResult> reflexScores;
  final AdultAmphibianScore amphibian;
  final AdultScoreMeta meta;

  Map<String, dynamic> toJson() => {
        'scoring_version': scoringVersion,
        'questionnaire_version': questionnaireVersion,
        'reflexes': {
          for (final entry in reflexScores.entries)
            entry.key.name: entry.value.toJson(),
        },
        'amphibian': amphibian.toJson(),
        'meta': meta.toJson(),
      };
}
