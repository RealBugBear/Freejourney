/// Pure invite-impulse frequency rules (no Flutter).
///
/// An ignored show is counted only when a previous display was left unanswered
/// and the next evaluation runs — never at the moment the card appears.
class InvitePromptInput {
  const InvitePromptInput({
    required this.now,
    required this.sourceEnabled,
    required this.isEligibleContext,
    required this.isTrainingSessionActive,
    required this.hasLowMoodInLast24Hours,
    required this.permanentlySilent,
    required this.ignoredShowCount,
    required this.lastShownAt,
    required this.showsInFirstYear,
    required this.firstYearStartedAt,
  });

  final DateTime now;
  final bool sourceEnabled;
  final bool isEligibleContext;
  final bool isTrainingSessionActive;
  final bool hasLowMoodInLast24Hours;
  final bool permanentlySilent;

  /// Completed unanswered shows (settled at a later evaluation).
  final int ignoredShowCount;

  final DateTime? lastShownAt;
  final int showsInFirstYear;
  final DateTime? firstYearStartedAt;

  static const cooldown = Duration(days: 30);
  static const firstYear = Duration(days: 365);
  static const maxShowsInFirstYear = 3;
  static const maxIgnoredShows = 2;
  static const lowMoodThreshold = 2;
}

enum InvitePromptDecision {
  show,
  suppress,
}

InvitePromptDecision decideInvitePrompt(InvitePromptInput input) {
  if (!input.sourceEnabled) return InvitePromptDecision.suppress;
  if (!input.isEligibleContext) return InvitePromptDecision.suppress;
  if (input.isTrainingSessionActive) return InvitePromptDecision.suppress;
  if (input.hasLowMoodInLast24Hours) return InvitePromptDecision.suppress;
  if (input.permanentlySilent) return InvitePromptDecision.suppress;
  if (input.ignoredShowCount >= InvitePromptInput.maxIgnoredShows) {
    return InvitePromptDecision.suppress;
  }

  final last = input.lastShownAt;
  if (last != null) {
    final since = input.now.difference(last);
    if (since < InvitePromptInput.cooldown && !since.isNegative) {
      return InvitePromptDecision.suppress;
    }
  }

  final yearStart = input.firstYearStartedAt;
  if (yearStart != null) {
    final age = input.now.difference(yearStart);
    final inFirstYear = !age.isNegative && age < InvitePromptInput.firstYear;
    if (inFirstYear &&
        input.showsInFirstYear >= InvitePromptInput.maxShowsInFirstYear) {
      return InvitePromptDecision.suppress;
    }
  }

  return InvitePromptDecision.show;
}

/// Snapshot used by settle / show / tap transitions.
class InvitePromptPersistState {
  const InvitePromptPersistState({
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

  /// True after a show until the user taps or the next eval settles it.
  final bool lastShowUnanswered;
}

/// Counts a previous unanswered show into the ignore streak.
InvitePromptPersistState invitePromptStateAfterSettleUnanswered(
  InvitePromptPersistState previous,
) {
  if (!previous.lastShowUnanswered) return previous;
  final ignored = previous.ignoredShowCount + 1;
  return InvitePromptPersistState(
    ignoredShowCount: ignored,
    permanentlySilent: previous.permanentlySilent ||
        ignored >= InvitePromptInput.maxIgnoredShows,
    showsInFirstYear: previous.showsInFirstYear,
    firstYearStartedAt: previous.firstYearStartedAt,
    lastShownAt: previous.lastShownAt,
    lastShowUnanswered: false,
  );
}

/// Records that a card was shown; does not count it as ignored yet.
InvitePromptPersistState invitePromptStateAfterShow({
  required DateTime now,
  required InvitePromptPersistState previous,
}) {
  final yearStart = previous.firstYearStartedAt ?? now;
  final inFirstYear = now.difference(yearStart) < InvitePromptInput.firstYear;
  final showsInYear =
      inFirstYear ? previous.showsInFirstYear + 1 : previous.showsInFirstYear;
  return InvitePromptPersistState(
    ignoredShowCount: previous.ignoredShowCount,
    permanentlySilent: previous.permanentlySilent,
    showsInFirstYear: showsInYear,
    firstYearStartedAt: yearStart,
    lastShownAt: now,
    lastShowUnanswered: true,
  );
}

/// Tap answers the open show and clears the ignore streak.
InvitePromptPersistState invitePromptStateAfterTap(
  InvitePromptPersistState previous,
) {
  return InvitePromptPersistState(
    ignoredShowCount: 0,
    permanentlySilent: previous.permanentlySilent,
    showsInFirstYear: previous.showsInFirstYear,
    firstYearStartedAt: previous.firstYearStartedAt,
    lastShownAt: previous.lastShownAt,
    lastShowUnanswered: false,
  );
}
