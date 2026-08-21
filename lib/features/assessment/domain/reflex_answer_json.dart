import 'reflex_questionnaire.dart';

/// Shared answer JSON codec for reflex profile drafts and submissions.
///
/// Child answers continue to emit only `yes` / `no` / `unknown`.
/// `not_applicable` is emitted only when [ReflexAnswerValue.isNotApplicable]
/// is set (adult path).
Map<String, dynamic> reflexAnswerToJson(ReflexAnswerValue answer) {
  final map = <String, dynamic>{};

  if (answer.isNotApplicable) {
    map['answer'] = 'not_applicable';
  } else if (answer.isUnknown) {
    map['answer'] = 'unknown';
  } else if (answer.yesNoUnknown != null) {
    map['answer'] = answer.yesNoUnknown! ? 'yes' : 'no';
  }

  if (answer.selectedOptionIds.isNotEmpty) {
    map['selected_options'] = answer.selectedOptionIds;
  }
  if (answer.text != null && answer.text!.trim().isNotEmpty) {
    map['text'] = answer.text!.trim();
  }
  if (answer.months != null) {
    map['months'] = answer.months;
  }
  return map;
}

ReflexAnswerValue reflexAnswerFromJson(Map<String, dynamic> raw) {
  final answer = raw['answer'] as String?;
  return ReflexAnswerValue(
    yesNoUnknown: answer == 'yes'
        ? true
        : answer == 'no'
            ? false
            : null,
    isUnknown: answer == 'unknown',
    isNotApplicable: answer == 'not_applicable',
    selectedOptionIds: (raw['selected_options'] as List?)
            ?.map((e) => e as String)
            .toList() ??
        const [],
    text: raw['text'] as String?,
    months: (raw['months'] as num?)?.toInt(),
  );
}
