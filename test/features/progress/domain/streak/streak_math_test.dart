// test/features/progress/domain/streak/streak_math_test.dart
import 'package:corejourney/features/progress/domain/streak/streak_credits.dart';
import 'package:corejourney/features/progress/domain/streak/streak_math.dart';
import 'package:flutter_test/flutter_test.dart';

Set<DateTime> _days(List<int> augustDays) =>
    {for (final day in augustDays) DateTime(2026, 8, day)};

void main() {
  group('earnCredits', () {
    test('three training days earn one credit', () {
      final result = earnCredits(
        credits: StreakCredits.empty,
        trainingDays: _days([1, 2, 3]),
        today: DateTime(2026, 8, 3),
      );
      expect(result.available, 1);
      expect(result.progressToNext, 0);
      expect(result.lastCountedDay, DateTime(2026, 8, 3));
    });

    test('two training days earn nothing but keep the progress', () {
      final result = earnCredits(
        credits: StreakCredits.empty,
        trainingDays: _days([1, 2]),
        today: DateTime(2026, 8, 2),
      );
      expect(result.available, 0);
      expect(result.progressToNext, 2);
    });

    test('days already counted are not counted again', () {
      final first = earnCredits(
        credits: StreakCredits.empty,
        trainingDays: _days([1, 2]),
        today: DateTime(2026, 8, 2),
      );
      final second = earnCredits(
        credits: first,
        trainingDays: _days([1, 2]),
        today: DateTime(2026, 8, 2),
      );
      expect(second.progressToNext, 2);
      expect(second.available, 0);
    });

    test('progress rests while the ledger is full', () {
      final full = StreakCredits.empty.copyWith(
        available: StreakCredits.maxAvailable,
        lastCountedDay: DateTime(2026, 8, 1),
      );
      final result = earnCredits(
        credits: full,
        trainingDays: _days([1, 2, 3, 4, 5, 6, 7]),
        today: DateTime(2026, 8, 7),
      );
      expect(result.available, StreakCredits.maxAvailable);
      expect(result.progressToNext, 0);
      expect(result.lastCountedDay, DateTime(2026, 8, 7));
    });

    test('six training days earn two credits and stop at the cap', () {
      final result = earnCredits(
        credits: StreakCredits.empty,
        trainingDays: _days([1, 2, 3, 4, 5, 6, 7, 8, 9]),
        today: DateTime(2026, 8, 9),
      );
      expect(result.available, StreakCredits.maxAvailable);
      expect(result.progressToNext, 0);
    });

    test('future training days are ignored', () {
      final result = earnCredits(
        credits: StreakCredits.empty,
        trainingDays: _days([1, 2, 3]),
        today: DateTime(2026, 8, 1),
      );
      expect(result.available, 0);
      expect(result.progressToNext, 1);
      expect(result.lastCountedDay, DateTime(2026, 8, 1));
    });

    test('rescued days do not earn progress', () {
      final credits = StreakCredits.empty.copyWith(
        rescuedDays: _days([2, 3]),
      );
      final result = earnCredits(
        credits: credits,
        trainingDays: _days([1]),
        today: DateTime(2026, 8, 3),
      );
      expect(result.progressToNext, 1);
    });
  });

  group('spendCredits', () {
    test('a one-day gap is rescued when a credit is available', () {
      final credits = StreakCredits.empty.copyWith(available: 1);
      final result = spendCredits(
        credits: credits,
        trainingDays: _days([1]),
        today: DateTime(2026, 8, 3),
      );
      expect(result.available, 0);
      expect(result.rescuedDays, {DateTime(2026, 8, 2)});
    });

    test('two consecutive missed days are rescued with two credits (D10)', () {
      final credits = StreakCredits.empty.copyWith(available: 2);
      final result = spendCredits(
        credits: credits,
        trainingDays: _days([1]),
        today: DateTime(2026, 8, 4),
      );
      expect(result.available, 0);
      expect(result.rescuedDays, {DateTime(2026, 8, 2), DateTime(2026, 8, 3)});
    });

    test('a three-day gap breaks the streak and keeps both credits (D11)', () {
      final credits = StreakCredits.empty.copyWith(available: 2);
      final result = spendCredits(
        credits: credits,
        trainingDays: _days([1]),
        today: DateTime(2026, 8, 5),
      );
      expect(result.available, 2);
      expect(result.rescuedDays, isEmpty);
    });

    test('today is never part of the gap', () {
      final credits = StreakCredits.empty.copyWith(available: 2);
      final result = spendCredits(
        credits: credits,
        trainingDays: _days([1]),
        today: DateTime(2026, 8, 2),
      );
      expect(result.available, 2);
      expect(result.rescuedDays, isEmpty);
    });

    test('an already rescued day counts as the last day', () {
      final credits = StreakCredits.empty.copyWith(
        available: 1,
        rescuedDays: _days([2]),
      );
      final result = spendCredits(
        credits: credits,
        trainingDays: _days([1]),
        today: DateTime(2026, 8, 4),
      );
      expect(result.available, 0);
      expect(result.rescuedDays, {DateTime(2026, 8, 2), DateTime(2026, 8, 3)});
    });

    test('nothing happens before the first training day', () {
      final result = spendCredits(
        credits: StreakCredits.empty.copyWith(available: 2),
        trainingDays: const <DateTime>{},
        today: DateTime(2026, 8, 5),
      );
      expect(result.available, 2);
      expect(result.rescuedDays, isEmpty);
    });

    test('the lookback stops at the configured horizon', () {
      final credits = StreakCredits.empty.copyWith(available: 2);
      final result = spendCredits(
        credits: credits,
        trainingDays: {DateTime(2024, 1, 1)},
        today: DateTime(2026, 8, 5),
        lookbackDays: 400,
      );
      expect(result.available, 2);
      expect(result.rescuedDays, isEmpty);
    });

    test('spending twice on the same gap changes nothing', () {
      final first = spendCredits(
        credits: StreakCredits.empty.copyWith(available: 2),
        trainingDays: _days([1]),
        today: DateTime(2026, 8, 3),
      );
      final second = spendCredits(
        credits: first,
        trainingDays: _days([1]),
        today: DateTime(2026, 8, 3),
      );
      expect(second.available, first.available);
      expect(second.rescuedDays, first.rescuedDays);
    });
  });
}
