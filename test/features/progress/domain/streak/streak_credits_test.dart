// test/features/progress/domain/streak/streak_credits_test.dart
import 'package:corejourney/features/progress/domain/streak/streak_credits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dateOnly drops the time component', () {
    expect(dateOnly(DateTime(2026, 3, 29, 13, 45)), DateTime(2026, 3, 29));
  });

  test('day arithmetic crosses a DST boundary without drifting', () {
    // Europe/Berlin springs forward on 2026-03-29; Duration(days: 1) would
    // land on 23:00 of the wrong day.
    expect(nextDay(DateTime(2026, 3, 28)), DateTime(2026, 3, 29));
    expect(previousDay(DateTime(2026, 3, 29)), DateTime(2026, 3, 28));
    expect(nextDay(DateTime(2026, 12, 31)), DateTime(2027, 1, 1));
    expect(previousDay(DateTime(2026, 1, 1)), DateTime(2025, 12, 31));
  });

  test('empty ledger starts with no credits and no progress', () {
    expect(StreakCredits.empty.available, 0);
    expect(StreakCredits.empty.progressToNext, 0);
    expect(StreakCredits.empty.lastCountedDay, isNull);
    expect(StreakCredits.empty.rescuedDays, isEmpty);
  });

  test('copyWith replaces only what is given', () {
    final credits = StreakCredits.empty.copyWith(
      available: 2,
      rescuedDays: {DateTime(2026, 8, 20)},
    );
    expect(credits.available, 2);
    expect(credits.progressToNext, 0);
    expect(credits.rescuedDays, {DateTime(2026, 8, 20)});

    final later = credits.copyWith(progressToNext: 1);
    expect(later.available, 2);
    expect(later.progressToNext, 1);
    expect(later.rescuedDays, {DateTime(2026, 8, 20)});
  });

  test('copyWith can clear lastCountedDay explicitly', () {
    final credits = StreakCredits.empty.copyWith(
      lastCountedDay: DateTime(2026, 8, 20),
    );
    expect(credits.copyWith(clearLastCountedDay: true).lastCountedDay, isNull);
  });
}
