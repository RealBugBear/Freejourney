import '../../domain/models/reflex_profile_assessment.dart';
import '../../domain/reflex_questionnaire.dart';
import '../../domain/reflex_questionnaire_definitions.dart';

class RelevantAnswerItem {
  const RelevantAnswerItem({
    required this.question,
    required this.selectedOptionLabels,
    this.freeText,
    this.months,
  });

  final ReflexQuestion question;
  final List<String> selectedOptionLabels;
  final String? freeText;
  final int? months;
}

List<(ReflexQuestionModule, List<RelevantAnswerItem>)> buildRelevanteAngaben(
  ReflexProfileAssessment assessment,
) {
  final questionById = {
    for (final q in childParentQuestionnaireV1.questions) q.id: q,
  };

  final Map<ReflexQuestionModule, List<RelevantAnswerItem>> byModule = {};

  for (final entry in assessment.answers.entries) {
    final raw = entry.value;
    if (raw is! Map) continue;

    final question = questionById[entry.key];
    if (question == null) continue;

    final text = raw['text'] as String?;
    final months = (raw['months'] as num?)?.toInt();
    final trimmedText = text?.trim();
    final hasFreeText = trimmedText != null && trimmedText.isNotEmpty;

    if (!hasFreeText && months == null) continue;

    byModule.putIfAbsent(question.module, () => []).add(
          RelevantAnswerItem(
            question: question,
            selectedOptionLabels: const [],
            freeText: hasFreeText ? trimmedText : null,
            months: months,
          ),
        );
  }

  for (final list in byModule.values) {
    list.sort((a, b) => a.question.number.compareTo(b.question.number));
  }

  return [
    for (final module in ReflexQuestionModule.values)
      if (byModule.containsKey(module)) (module, byModule[module]!),
  ];
}

String reflexModuleLabel(ReflexQuestionModule module, String locale) =>
    module.resultLabel(locale);
