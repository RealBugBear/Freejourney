import 'streak_credits.dart';

/// Counts training days that have not been counted yet and turns them into
/// credits (spec §4.4).
///
/// While the ledger is full the progress counter rests: a day is consumed but
/// yields nothing. That is the founder's "no stockpiling" rule — neither
/// credits nor progress towards one can be banked.
StreakCredits earnCredits({
  required StreakCredits credits,
  required Set<DateTime> trainingDays,
  required DateTime today,
}) {
  final last = credits.lastCountedDay;
  final newDays = trainingDays
      .where((day) => !day.isAfter(today))
      .where((day) => last == null || day.isAfter(last))
      .toList()
    ..sort();
  if (newDays.isEmpty) return credits;

  var available = credits.available;
  var progress = credits.progressToNext;
  for (var i = 0; i < newDays.length; i++) {
    if (available >= StreakCredits.maxAvailable) continue;
    progress += 1;
    if (progress >= StreakCredits.trainingDaysPerCredit) {
      available += 1;
      progress = 0;
    }
  }

  return credits.copyWith(
    available: available,
    progressToNext: progress,
    lastCountedDay: newDays.last,
  );
}

/// Rescues the gap between the last counting day and today (spec §4.5).
///
/// Founder decision D11: credits are spent **only** when they cover the whole
/// gap. After a long absence the streak breaks and the credits are kept,
/// instead of being burned on a series that is lost anyway.
StreakCredits spendCredits({
  required StreakCredits credits,
  required Set<DateTime> trainingDays,
  required DateTime today,
  int lookbackDays = 400,
}) {
  bool counts(DateTime day) =>
      trainingDays.contains(day) || credits.rescuedDays.contains(day);

  DateTime? last;
  var cursor = today;
  for (var step = 0; step <= lookbackDays; step++) {
    if (counts(cursor)) {
      last = cursor;
      break;
    }
    cursor = previousDay(cursor);
  }
  if (last == null) return credits;

  final gap = <DateTime>{};
  for (var day = nextDay(last); day.isBefore(today); day = nextDay(day)) {
    gap.add(day);
  }
  if (gap.isEmpty) return credits;
  if (gap.length > credits.available) return credits;

  return credits.copyWith(
    available: credits.available - gap.length,
    rescuedDays: {...credits.rescuedDays, ...gap},
  );
}

/// Length of the series ending today (spec §4.1).
///
/// An untrained today does not end the series — it is still running.
int streakLength({
  required Set<DateTime> trainingDays,
  required Set<DateTime> rescuedDays,
  required DateTime today,
  int lookbackDays = 400,
}) {
  bool counts(DateTime day) =>
      trainingDays.contains(day) || rescuedDays.contains(day);

  var day = counts(today) ? today : previousDay(today);
  var length = 0;
  while (length < lookbackDays && counts(day)) {
    length += 1;
    day = previousDay(day);
  }
  return length;
}

/// Result of one evaluation (spec §4.3).
class StreakEvaluation {
  const StreakEvaluation({
    required this.credits,
    required this.length,
    required this.newlyRescued,
  });

  /// The ledger after earning, spending and pruning.
  final StreakCredits credits;

  /// Series length in days.
  final int length;

  /// Days rescued by *this* evaluation — what the UI reports to the user.
  final Set<DateTime> newlyRescued;
}

/// One evaluation: earn, then spend, then prune (spec §4.3).
///
/// Earning runs first on purpose so a training day that only just synced can
/// still contribute the credit that rescues the gap behind it.
StreakEvaluation evaluateStreak({
  required Set<DateTime> trainingDays,
  required StreakCredits credits,
  required DateTime today,
  int lookbackDays = 400,
}) {
  final earned = earnCredits(
    credits: credits,
    trainingDays: trainingDays,
    today: today,
  );
  final spent = spendCredits(
    credits: earned,
    trainingDays: trainingDays,
    today: today,
    lookbackDays: lookbackDays,
  );
  final newlyRescued = spent.rescuedDays.difference(credits.rescuedDays);

  final horizon =
      DateTime(today.year, today.month, today.day - lookbackDays);
  final pruned = spent.copyWith(
    rescuedDays:
        spent.rescuedDays.where((day) => !day.isBefore(horizon)).toSet(),
  );

  return StreakEvaluation(
    credits: pruned,
    length: streakLength(
      trainingDays: trainingDays,
      rescuedDays: pruned.rescuedDays,
      today: today,
      lookbackDays: lookbackDays,
    ),
    newlyRescued: newlyRescued,
  );
}
