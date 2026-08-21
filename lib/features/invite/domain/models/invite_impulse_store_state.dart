import '../invite_prompt_policy.dart';

/// Per-user persisted counters for invite impulse policy.
class InviteImpulseStoreState {
  const InviteImpulseStoreState({
    this.ignoredShowCount = 0,
    this.permanentlySilent = false,
    this.showsInFirstYear = 0,
    this.firstYearStartedAt,
    this.lastShownAt,
    this.lastShowUnanswered = false,
  });

  final int ignoredShowCount;
  final bool permanentlySilent;
  final int showsInFirstYear;
  final DateTime? firstYearStartedAt;
  final DateTime? lastShownAt;
  final bool lastShowUnanswered;

  factory InviteImpulseStoreState.fromJson(Map<String, dynamic>? raw) {
    if (raw == null) return const InviteImpulseStoreState();
    return InviteImpulseStoreState(
      ignoredShowCount: _nonNegInt(raw['ignored_show_count']) ?? 0,
      permanentlySilent: raw['permanently_silent'] == true,
      showsInFirstYear: _nonNegInt(raw['shows_in_first_year']) ?? 0,
      firstYearStartedAt: _parseTime(raw['first_year_started_at']),
      lastShownAt: _parseTime(raw['last_shown_at']),
      lastShowUnanswered: raw['last_show_unanswered'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'ignored_show_count': ignoredShowCount,
        'permanently_silent': permanentlySilent,
        'shows_in_first_year': showsInFirstYear,
        'last_show_unanswered': lastShowUnanswered,
        if (firstYearStartedAt != null)
          'first_year_started_at':
              firstYearStartedAt!.toUtc().toIso8601String(),
        if (lastShownAt != null)
          'last_shown_at': lastShownAt!.toUtc().toIso8601String(),
      };

  InvitePromptPersistState toPersist() => InvitePromptPersistState(
        ignoredShowCount: ignoredShowCount,
        permanentlySilent: permanentlySilent,
        showsInFirstYear: showsInFirstYear,
        firstYearStartedAt: firstYearStartedAt,
        lastShownAt: lastShownAt,
        lastShowUnanswered: lastShowUnanswered,
      );

  factory InviteImpulseStoreState.fromPersist(InvitePromptPersistState s) {
    return InviteImpulseStoreState(
      ignoredShowCount: s.ignoredShowCount,
      permanentlySilent: s.permanentlySilent,
      showsInFirstYear: s.showsInFirstYear,
      firstYearStartedAt: s.firstYearStartedAt,
      lastShownAt: s.lastShownAt,
      lastShowUnanswered: s.lastShowUnanswered,
    );
  }

  static int? _nonNegInt(Object? value) => switch (value) {
        final int n when n >= 0 => n,
        final num n when n >= 0 && n % 1 == 0 => n.toInt(),
        _ => null,
      };

  static DateTime? _parseTime(Object? value) {
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}
