/// Draft `__meta` payload for reflex questionnaires (§6.2 / §11.4).
///
/// Duration fields are product data for the user's own draft — not analytics.
class ReflexDraftMeta {
  const ReflexDraftMeta({
    required this.moduleIndex,
    required this.questionnaireFor,
    this.questionnaireVersion,
    this.filterAnswers = const {},
    this.startedAt,
    this.moduleTimings = const {},
    this.supersededItemIds = const [],
  });

  final int moduleIndex;
  final String questionnaireFor;
  final String? questionnaireVersion;

  /// Filter item id → wire value (`yes` / `no` / `unknown`).
  final Map<String, String> filterAnswers;

  final DateTime? startedAt;

  /// Module name → elapsed seconds (or nested timing maps). No answer bodies.
  final Map<String, dynamic> moduleTimings;

  final List<String> supersededItemIds;

  Map<String, dynamic> toJson() => {
        'module_index': moduleIndex,
        'questionnaire_for': questionnaireFor,
        if (questionnaireVersion != null)
          'questionnaire_version': questionnaireVersion,
        if (filterAnswers.isNotEmpty) 'filter_answers': filterAnswers,
        if (startedAt != null) 'started_at': startedAt!.toIso8601String(),
        if (moduleTimings.isNotEmpty) 'module_timings': moduleTimings,
        if (supersededItemIds.isNotEmpty)
          'superseded_item_ids': supersededItemIds,
      };

  factory ReflexDraftMeta.fromJson(Map<String, dynamic> json) {
    final filterRaw = json['filter_answers'];
    final timingsRaw = json['module_timings'];
    final supersededRaw = json['superseded_item_ids'];
    return ReflexDraftMeta(
      moduleIndex: (json['module_index'] as num?)?.toInt() ?? 0,
      questionnaireFor: json['questionnaire_for'] as String? ?? 'child',
      questionnaireVersion: json['questionnaire_version'] as String?,
      filterAnswers: filterRaw is Map
          ? filterRaw.map((key, value) => MapEntry('$key', '$value'))
          : const {},
      startedAt: json['started_at'] == null
          ? null
          : DateTime.tryParse(json['started_at'] as String),
      moduleTimings: timingsRaw is Map
          ? timingsRaw.map((key, value) => MapEntry('$key', value))
          : const {},
      supersededItemIds: supersededRaw is List
          ? supersededRaw.map((e) => '$e').toList()
          : const [],
    );
  }
}
