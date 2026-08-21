import 'adult_questionnaire_visibility.dart';
import 'reflex_draft_meta.dart';
import 'reflex_questionnaire.dart';

/// Builds draft `__meta`, wiring adult filter/superseded fields from
/// [AdultQuestionnaireVisibility] (not from `f_` key heuristics).
ReflexDraftMeta buildQuestionnaireDraftMeta({
  required ReflexQuestionnaireDefinition definition,
  required Map<String, ReflexAnswerValue> answers,
  required int moduleIndex,
  required String questionnaireFor,
  DateTime? startedAt,
  Map<String, dynamic> moduleTimings = const {},
  bool movementChecksEnabled = false,
}) {
  if (questionnaireFor == 'adult') {
    final visibility = AdultQuestionnaireVisibility(
      definition: definition,
      answers: answers,
      movementChecksEnabled: movementChecksEnabled,
    );
    final superseded = visibility.supersededAnswerIds.toList()..sort();
    return ReflexDraftMeta(
      moduleIndex: moduleIndex,
      questionnaireFor: questionnaireFor,
      questionnaireVersion: definition.version,
      filterAnswers: visibility.filterAnswersForMeta,
      startedAt: startedAt,
      moduleTimings: moduleTimings,
      supersededItemIds: superseded,
    );
  }

  return ReflexDraftMeta(
    moduleIndex: moduleIndex,
    questionnaireFor: questionnaireFor,
    questionnaireVersion: definition.version,
    startedAt: startedAt,
    moduleTimings: moduleTimings,
  );
}

/// Whole years completed at [asOf] (calendar age).
int adultAgeYears(DateTime birthDate, {DateTime? asOf}) {
  final now = asOf ?? DateTime.now();
  var years = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    years -= 1;
  }
  return years;
}

bool isAdultQuestionnaireAgeEligible(DateTime birthDate, {DateTime? asOf}) =>
    adultAgeYears(birthDate, asOf: asOf) >= 16;
