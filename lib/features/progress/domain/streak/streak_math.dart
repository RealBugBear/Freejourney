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
