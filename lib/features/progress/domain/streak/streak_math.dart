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
