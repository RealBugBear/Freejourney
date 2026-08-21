import 'reflex_questionnaire.dart';

/// Pure visibility rules for the adult_v3 questionnaire (§6.1).
///
/// No Flutter dependency. Movement gating is injected as a bool so Phase 3
/// does not depend on launch flags that land in Phase 6.
class AdultQuestionnaireVisibility {
  AdultQuestionnaireVisibility({
    required this.definition,
    required this.answers,
    this.movementChecksEnabled = false,
  });

  final ReflexQuestionnaireDefinition definition;
  final Map<String, ReflexAnswerValue> answers;

  /// When false, movement items are never visible (public default).
  final bool movementChecksEnabled;

  /// Filter questions keyed by the [ApplicabilityFilter] they provide.
  late final Map<ApplicabilityFilter, ReflexQuestion> _filterQuestions = {
    for (final question in definition.questions)
      if (question.providesFilter != null) question.providesFilter!: question,
  };

  /// Current choice per life-situation filter (`null` = unanswered).
  Map<ApplicabilityFilter, ReflexAnswerChoice?> get filterChoices {
    final result = <ApplicabilityFilter, ReflexAnswerChoice?>{};
    for (final entry in _filterQuestions.entries) {
      final filter = entry.key;
      if (filter == ApplicabilityFilter.afterSafetyCleared) continue;
      result[filter] = answers[entry.value.id]?.choice;
    }
    return result;
  }

  /// Compact meta map for drafts: `{ "f_swim": "yes", ... }`.
  Map<String, String> get filterAnswersForMeta {
    final result = <String, String>{};
    for (final entry in _filterQuestions.entries) {
      final choice = answers[entry.value.id]?.choice;
      if (choice == null) continue;
      result[entry.value.id] = _choiceToWire(choice);
    }
    return result;
  }

  /// True once every safety-role item has an answer (any of the four choices).
  bool get safetyModuleCompleted {
    final safetyItems = definition.questions
        .where((q) => q.role == ReflexQuestionRole.safety)
        .toList();
    if (safetyItems.isEmpty) return true;
    return safetyItems.every((q) => answers[q.id]?.isAnswered == true);
  }

  bool isVisible(ReflexQuestion question) {
    if (question.role == ReflexQuestionRole.movement &&
        !movementChecksEnabled) {
      return false;
    }

    for (final filter in question.requiresFilters) {
      if (!_filterAllows(filter)) return false;
    }
    return true;
  }

  List<ReflexQuestion> get visibleQuestions =>
      definition.questions.where(isVisible).toList(growable: false);

  /// Answered items that are currently hidden by filters / movement gate.
  /// Answers stay in the draft map; scoring must ignore these IDs.
  Set<String> get supersededAnswerIds {
    final hidden = <String>{};
    for (final question in definition.questions) {
      if (isVisible(question)) continue;
      final answer = answers[question.id];
      if (answer != null && answer.isAnswered) {
        hidden.add(question.id);
      }
    }
    return hidden;
  }

  bool _filterAllows(ApplicabilityFilter filter) {
    if (filter == ApplicabilityFilter.afterSafetyCleared) {
      return safetyModuleCompleted;
    }
    final choice = filterChoices[filter];
    // Only an explicit "no" hides dependents. "yes", "?", and unanswered keep
    // them visible (§6.1 / Gesamtkonzept §4).
    return choice != ReflexAnswerChoice.no;
  }

  static String _choiceToWire(ReflexAnswerChoice choice) => switch (choice) {
        ReflexAnswerChoice.yes => 'yes',
        ReflexAnswerChoice.no => 'no',
        ReflexAnswerChoice.unknown => 'unknown',
        ReflexAnswerChoice.notApplicable => 'not_applicable',
      };
}
