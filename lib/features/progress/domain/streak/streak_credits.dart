// lib/features/progress/domain/streak/streak_credits.dart

/// Strips the time component, keeping the local calendar day.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// The local calendar day after [day].
///
/// Built from the y/m/d constructor on purpose: `add(Duration(days: 1))`
/// shifts by exactly 24 hours and lands on the wrong day across a DST change.
DateTime nextDay(DateTime day) => DateTime(day.year, day.month, day.day + 1);

/// The local calendar day before [day]. See [nextDay] for why this is not
/// `subtract(Duration(days: 1))`.
DateTime previousDay(DateTime day) =>
    DateTime(day.year, day.month, day.day - 1);

/// The Freischein ledger for one subject profile.
///
/// This is the only part of the streak that is stored. The streak itself is
/// derived from `training_sessions` rows (see `streak_math.dart`); that a
/// missed day was forgiven cannot be derived from anything, so it lives here.
class StreakCredits {
  const StreakCredits({
    this.available = 0,
    this.progressToNext = 0,
    this.lastCountedDay,
    this.rescuedDays = const <DateTime>{},
  });

  static const StreakCredits empty = StreakCredits();

  /// Founder decision D8: never more than two credits at once.
  static const int maxAvailable = 2;

  /// Founder decision D8: three training days earn one credit.
  static const int trainingDaysPerCredit = 3;

  /// Credits ready to be spent, 0..[maxAvailable].
  final int available;

  /// Training days counted towards the next credit, 0..[trainingDaysPerCredit] - 1.
  final int progressToNext;

  /// Latest training day already counted towards [progressToNext].
  final DateTime? lastCountedDay;

  /// Days a credit has rescued. Date-only values.
  final Set<DateTime> rescuedDays;

  StreakCredits copyWith({
    int? available,
    int? progressToNext,
    DateTime? lastCountedDay,
    bool clearLastCountedDay = false,
    Set<DateTime>? rescuedDays,
  }) {
    return StreakCredits(
      available: available ?? this.available,
      progressToNext: progressToNext ?? this.progressToNext,
      lastCountedDay:
          clearLastCountedDay ? null : (lastCountedDay ?? this.lastCountedDay),
      rescuedDays: rescuedDays ?? this.rescuedDays,
    );
  }
}
