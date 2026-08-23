# Serie & Freischeine — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the daily streak visible and correct by deriving it from existing training-session rows, and add a two-credit "Freischein" safety net that rescues missed days automatically.

**Architecture:** The streak is **not stored**. A pure function derives it from the set of calendar days on which `training_sessions` rows exist for a subject profile. The only persisted state is the Freischein ledger (`streak_credits`), because "this gap was forgiven" cannot be derived from session rows. All three of today's streak computations are deleted rather than unified. `progress_entries.daily_streak` survives as a write-only mirror so the existing trainer RPC keeps working.

**Tech Stack:** Flutter 3.38, Riverpod, Drift (local SQLite), Supabase (Postgres + RLS), `flutter_local_notifications`.

**Spec:** `docs/superpowers/specs/2026-08-23-serie-und-freischeine-design.md`

## Global Constraints

- Work in `/Users/alexandermessinger/dev/claudvibes/reflexjourney`. Verify with `git rev-parse --show-toplevel` before every commit (CLAUDE.md §1, mistake #3).
- **Never `git push`** (CLAUDE.md §3). Local commits only.
- **Never apply SQL to the live database** without an explicit founder go, shown with exact SQL, blast radius and rollback first (CLAUDE.md §3). Task 9 stops at the migration file plus a local `supabase db reset --local`.
- Every user-facing string goes into **both** `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`, then `flutter gen-l10n`. No string literals in widgets (CLAUDE.md §6, mistake #12). German addresses the user as "du".
- Generated files (`app_localizations*.dart`, `*.g.dart`) are committed but **never hand-edited** (mistake #13).
- Done means: `flutter analyze --no-fatal-infos` → 0 errors, 0 warnings; `flutter test` → 100% pass. `make release-readiness-mobile` runs both plus the i18n gate.
- Never write user data (names, notes, message contents) into logs or chat (CLAUDE.md §5).
- Use `appLogger`, never `print`.
- All dates in streak logic are **local date-only** values built with `DateTime(y, m, d)`. Never use `Duration(days: 1)` arithmetic on them — it breaks across DST. Use the `nextDay` / `previousDay` helpers from Task 1.
- Commit messages reference the plan task, e.g. `feat(streak): derive credits from training days (Task 2)`.

---

## File Structure

**Create**

| File | Responsibility |
|---|---|
| `lib/features/progress/domain/streak/streak_credits.dart` | Value object for the ledger + date helpers + constants |
| `lib/features/progress/domain/streak/streak_math.dart` | Pure functions: `earnCredits`, `spendCredits`, `streakLength`, `evaluateStreak` |
| `lib/core/database/tables/streak_credits_table.dart` | Drift table |
| `lib/features/progress/data/repositories/streak_credits_repository.dart` | Load/save ledger, read training days, enqueue sync, mirror write |
| `lib/features/progress/presentation/providers/streak_provider.dart` | Riverpod wiring + `StreakService.evaluate()` |
| `lib/features/progress/presentation/widgets/streak_row.dart` | Dashboard row (length, credits, seven days) |
| `lib/features/training/presentation/widgets/joint_training_sheet.dart` | Shared "who is training?" picker |
| `supabase/migrations/YYYYMMDDNN_profile_streak_credits.sql` | Server table + RLS |

**Modify**

| File | Change |
|---|---|
| `lib/core/database/app_database.dart` | Register table, `schemaVersion` 8 → 9, migration `from < 9` |
| `lib/core/sync/sync_service.dart:306` (`rehydrate`) | Pull `streak_credits` |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | Replace `_WeeklyRegularityStrip`, use the shared picker on both paths |
| `lib/features/training/data/repositories/training_completion_repository.dart:470-503` | Delete streak math |
| `lib/features/progress/presentation/providers/progress_provider.dart:755-790, 860-885` | Delete streak math |
| `lib/core/notifications/notification_service.dart` | Streak notification scheduling |
| `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb` | New strings |

---

## Task 1: Ledger value object and date helpers

**Files:**
- Create: `lib/features/progress/domain/streak/streak_credits.dart`
- Test: `test/features/progress/domain/streak/streak_credits_test.dart`

**Interfaces:**
- Consumes: nothing
- Produces: `dateOnly(DateTime) -> DateTime`, `nextDay(DateTime) -> DateTime`, `previousDay(DateTime) -> DateTime`, `class StreakCredits` with fields `int available`, `int progressToNext`, `DateTime? lastCountedDay`, `Set<DateTime> rescuedDays`, `StreakCredits.empty`, `copyWith(...)`, and constants `StreakCredits.maxAvailable = 2`, `StreakCredits.trainingDaysPerCredit = 3`.

- [ ] **Step 1: Write the failing test**

```dart
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
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/features/progress/domain/streak/streak_credits_test.dart`
Expected: FAIL — `Target of URI doesn't exist` / undefined names.

- [ ] **Step 3: Write the implementation**

```dart
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
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `flutter test test/features/progress/domain/streak/streak_credits_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress/domain/streak/streak_credits.dart test/features/progress/domain/streak/streak_credits_test.dart
git commit -m "feat(streak): ledger value object and DST-safe day helpers (Task 1)"
```

---

## Task 2: Earning credits

**Files:**
- Create: `lib/features/progress/domain/streak/streak_math.dart`
- Test: `test/features/progress/domain/streak/streak_math_test.dart`

**Interfaces:**
- Consumes: `StreakCredits`, `dateOnly`, `nextDay`, `previousDay` from Task 1
- Produces: `StreakCredits earnCredits({required StreakCredits credits, required Set<DateTime> trainingDays, required DateTime today})`

Spec reference: §4.4.

- [ ] **Step 1: Write the failing test**

```dart
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
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/features/progress/domain/streak/streak_math_test.dart`
Expected: FAIL — `earnCredits` is undefined.

- [ ] **Step 3: Write the implementation**

```dart
// lib/features/progress/domain/streak/streak_math.dart
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
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `flutter test test/features/progress/domain/streak/streak_math_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress/domain/streak/streak_math.dart test/features/progress/domain/streak/streak_math_test.dart
git commit -m "feat(streak): earn one credit per three training days (Task 2)"
```

---

## Task 3: Spending credits

**Files:**
- Modify: `lib/features/progress/domain/streak/streak_math.dart`
- Test: `test/features/progress/domain/streak/streak_math_test.dart`

**Interfaces:**
- Consumes: `StreakCredits`, `nextDay`, `previousDay`, `earnCredits`
- Produces: `StreakCredits spendCredits({required StreakCredits credits, required Set<DateTime> trainingDays, required DateTime today, int lookbackDays = 400})`

Spec reference: §4.5, decisions D10 and D11.

- [ ] **Step 1: Write the failing test**

Append to `test/features/progress/domain/streak/streak_math_test.dart`, inside `main()`:

```dart
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
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/features/progress/domain/streak/streak_math_test.dart`
Expected: FAIL — `spendCredits` is undefined.

- [ ] **Step 3: Write the implementation**

Append to `lib/features/progress/domain/streak/streak_math.dart`:

```dart
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
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `flutter test test/features/progress/domain/streak/streak_math_test.dart`
Expected: PASS, 15 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress/domain/streak/streak_math.dart test/features/progress/domain/streak/streak_math_test.dart
git commit -m "feat(streak): spend credits only when they save the series (Task 3)"
```

---

## Task 4: Streak length and the composed evaluation

**Files:**
- Modify: `lib/features/progress/domain/streak/streak_math.dart`
- Test: `test/features/progress/domain/streak/streak_math_test.dart`

**Interfaces:**
- Consumes: `earnCredits`, `spendCredits`, `StreakCredits`
- Produces:
  - `int streakLength({required Set<DateTime> trainingDays, required Set<DateTime> rescuedDays, required DateTime today, int lookbackDays = 400})`
  - `class StreakEvaluation` with `final StreakCredits credits`, `final int length`, `final Set<DateTime> newlyRescued`
  - `StreakEvaluation evaluateStreak({required Set<DateTime> trainingDays, required StreakCredits credits, required DateTime today, int lookbackDays = 400})`

Spec reference: §4.1 and §4.3.

- [ ] **Step 1: Write the failing test**

Append to `test/features/progress/domain/streak/streak_math_test.dart`, inside `main()`:

```dart
  group('streakLength', () {
    test('counts consecutive training days ending today', () {
      expect(
        streakLength(
          trainingDays: _days([1, 2, 3]),
          rescuedDays: const <DateTime>{},
          today: DateTime(2026, 8, 3),
        ),
        3,
      );
    });

    test('an open today does not break the series', () {
      expect(
        streakLength(
          trainingDays: _days([1, 2, 3]),
          rescuedDays: const <DateTime>{},
          today: DateTime(2026, 8, 4),
        ),
        3,
      );
    });

    test('a rescued day keeps the series running', () {
      expect(
        streakLength(
          trainingDays: _days([1, 3]),
          rescuedDays: _days([2]),
          today: DateTime(2026, 8, 3),
        ),
        3,
      );
    });

    test('an unrescued gap ends the series', () {
      expect(
        streakLength(
          trainingDays: _days([1, 4]),
          rescuedDays: const <DateTime>{},
          today: DateTime(2026, 8, 4),
        ),
        1,
      );
    });

    test('no training at all is a length of zero', () {
      expect(
        streakLength(
          trainingDays: const <DateTime>{},
          rescuedDays: const <DateTime>{},
          today: DateTime(2026, 8, 4),
        ),
        0,
      );
    });
  });

  group('evaluateStreak', () {
    test('earns before spending, so a fresh credit can still rescue', () {
      // Trained on the 1st, 2nd and 3rd — the third day earns the first
      // credit, which then covers the missed 4th.
      final result = evaluateStreak(
        trainingDays: _days([1, 2, 3]),
        credits: StreakCredits.empty,
        today: DateTime(2026, 8, 5),
      );
      expect(result.credits.available, 0);
      expect(result.credits.rescuedDays, {DateTime(2026, 8, 4)});
      expect(result.newlyRescued, {DateTime(2026, 8, 4)});
      expect(result.length, 4);
    });

    test('reports nothing newly rescued when no gap exists', () {
      final result = evaluateStreak(
        trainingDays: _days([1, 2, 3]),
        credits: StreakCredits.empty,
        today: DateTime(2026, 8, 3),
      );
      expect(result.newlyRescued, isEmpty);
      expect(result.length, 3);
    });

    test('a second evaluation on the same day changes nothing', () {
      final first = evaluateStreak(
        trainingDays: _days([1, 2, 3]),
        credits: StreakCredits.empty,
        today: DateTime(2026, 8, 5),
      );
      final second = evaluateStreak(
        trainingDays: _days([1, 2, 3]),
        credits: first.credits,
        today: DateTime(2026, 8, 5),
      );
      expect(second.credits.available, first.credits.available);
      expect(second.credits.rescuedDays, first.credits.rescuedDays);
      expect(second.credits.progressToNext, first.credits.progressToNext);
      expect(second.length, first.length);
      expect(second.newlyRescued, isEmpty);
    });

    test('rescued days older than the horizon are pruned', () {
      final credits = StreakCredits.empty.copyWith(
        rescuedDays: {DateTime(2024, 1, 1), DateTime(2026, 8, 2)},
      );
      final result = evaluateStreak(
        trainingDays: _days([1, 3]),
        credits: credits,
        today: DateTime(2026, 8, 3),
        lookbackDays: 400,
      );
      expect(result.credits.rescuedDays, {DateTime(2026, 8, 2)});
    });
  });
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/features/progress/domain/streak/streak_math_test.dart`
Expected: FAIL — `streakLength` and `evaluateStreak` are undefined.

- [ ] **Step 3: Write the implementation**

Append to `lib/features/progress/domain/streak/streak_math.dart`:

```dart
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
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `flutter test test/features/progress/domain/streak/streak_math_test.dart`
Expected: PASS, 24 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress/domain/streak/streak_math.dart test/features/progress/domain/streak/streak_math_test.dart
git commit -m "feat(streak): derive series length and compose the evaluation (Task 4)"
```

---

## Task 5: Local ledger table and repository

**Files:**
- Create: `lib/core/database/tables/streak_credits_table.dart`
- Create: `lib/features/progress/data/repositories/streak_credits_repository.dart`
- Modify: `lib/core/database/app_database.dart:21-30` (table list), `:100` (`schemaVersion`), `:103-140` (migration)
- Test: `test/features/progress/data/streak_credits_repository_test.dart`

**Interfaces:**
- Consumes: `StreakCredits`, `dateOnly` (Task 1)
- Produces: `class StreakCreditsRepository` with
  - `StreakCreditsRepository(AppDatabase db, SyncService syncService)`
  - `Future<Set<DateTime>> trainingDaysFor({required String subjectProfileId, required DateTime since})`
  - `Future<StreakCredits> loadCredits({required String userId, required String subjectProfileId})`
  - `Future<void> saveCredits({required String userId, required String subjectProfileId, required StreakCredits credits})`
  - `Future<void> mirrorStreak({required String subjectProfileId, required int length})`

- [ ] **Step 1: Write the failing test**

```dart
// test/features/progress/data/streak_credits_repository_test.dart
import 'package:corejourney/core/database/app_database.dart';
import 'package:corejourney/features/progress/data/repositories/streak_credits_repository.dart';
import 'package:corejourney/features/progress/domain/streak/streak_credits.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StreakCreditsRepository repository;

  setUp(() {
    db = AppDatabase.inMemory();
    repository = StreakCreditsRepository(db, null);
  });

  tearDown(() => db.close());

  Future<void> insertSession({
    required String id,
    required String subjectProfileId,
    required DateTime date,
    bool completed = true,
  }) {
    return db.into(db.trainingSessionsTable).insert(
          TrainingSessionsTableCompanion.insert(
            id: id,
            userId: 'user-1',
            subjectProfileId: Value(subjectProfileId),
            enrollmentId: 'enrollment-1',
            sessionDate: date,
            dayNumber: 1,
            completedExerciseIds: '[]',
            isCompleted: Value(completed),
          ),
        );
  }

  test('collapses several sessions on one day into a single training day',
      () async {
    await insertSession(
      id: 's1',
      subjectProfileId: 'child-1',
      date: DateTime(2026, 8, 3, 9),
    );
    await insertSession(
      id: 's2',
      subjectProfileId: 'child-1',
      date: DateTime(2026, 8, 3, 18),
    );

    final days = await repository.trainingDaysFor(
      subjectProfileId: 'child-1',
      since: DateTime(2026, 1, 1),
    );
    expect(days, {DateTime(2026, 8, 3)});
  });

  test('keeps profiles apart', () async {
    await insertSession(
      id: 's1',
      subjectProfileId: 'child-1',
      date: DateTime(2026, 8, 3),
    );
    await insertSession(
      id: 's2',
      subjectProfileId: 'child-2',
      date: DateTime(2026, 8, 4),
    );

    expect(
      await repository.trainingDaysFor(
        subjectProfileId: 'child-1',
        since: DateTime(2026, 1, 1),
      ),
      {DateTime(2026, 8, 3)},
    );
  });

  test('ignores unfinished sessions', () async {
    await insertSession(
      id: 's1',
      subjectProfileId: 'child-1',
      date: DateTime(2026, 8, 3),
      completed: false,
    );
    expect(
      await repository.trainingDaysFor(
        subjectProfileId: 'child-1',
        since: DateTime(2026, 1, 1),
      ),
      isEmpty,
    );
  });

  test('an unknown profile loads an empty ledger', () async {
    final credits = await repository.loadCredits(
      userId: 'user-1',
      subjectProfileId: 'child-1',
    );
    expect(credits.available, 0);
    expect(credits.rescuedDays, isEmpty);
  });

  test('saved credits survive a reload', () async {
    await repository.saveCredits(
      userId: 'user-1',
      subjectProfileId: 'child-1',
      credits: StreakCredits.empty.copyWith(
        available: 2,
        progressToNext: 1,
        lastCountedDay: DateTime(2026, 8, 3),
        rescuedDays: {DateTime(2026, 8, 2)},
      ),
    );

    final loaded = await repository.loadCredits(
      userId: 'user-1',
      subjectProfileId: 'child-1',
    );
    expect(loaded.available, 2);
    expect(loaded.progressToNext, 1);
    expect(loaded.lastCountedDay, DateTime(2026, 8, 3));
    expect(loaded.rescuedDays, {DateTime(2026, 8, 2)});
  });

  test('saving twice updates instead of duplicating', () async {
    await repository.saveCredits(
      userId: 'user-1',
      subjectProfileId: 'child-1',
      credits: StreakCredits.empty.copyWith(available: 1),
    );
    await repository.saveCredits(
      userId: 'user-1',
      subjectProfileId: 'child-1',
      credits: StreakCredits.empty.copyWith(available: 2),
    );

    final rows = await db.select(db.streakCreditsTable).get();
    expect(rows, hasLength(1));
    expect(rows.single.available, 2);
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/features/progress/data/streak_credits_repository_test.dart`
Expected: FAIL — `StreakCreditsRepository` and `streakCreditsTable` are undefined.

- [ ] **Step 3: Add the Drift table**

```dart
// lib/core/database/tables/streak_credits_table.dart
import 'package:drift/drift.dart';

/// Freischein ledger, one row per subject profile.
///
/// The series itself is derived from `training_sessions` and is deliberately
/// not stored here (spec §4.1). Only [rescuedDays] cannot be derived — that a
/// missed day was forgiven leaves no other trace.
class StreakCreditsTable extends Table {
  @override
  String get tableName => 'streak_credits';

  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get subjectProfileId => text()();

  /// Credits ready to be spent, 0..2.
  IntColumn get available => integer().withDefault(const Constant(0))();

  /// Training days counted towards the next credit, 0..2.
  IntColumn get progressToNext => integer().withDefault(const Constant(0))();

  /// Latest training day already counted, date-only.
  DateTimeColumn get lastCountedDay => dateTime().nullable()();

  /// Rescued days as a JSON-encoded list of `yyyy-MM-dd` strings.
  TextColumn get rescuedDays => text().withDefault(const Constant('[]'))();

  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 4: Register the table and bump the schema**

In `lib/core/database/app_database.dart`, add the import next to the other table imports, add `StreakCreditsTable,` to the `@DriftDatabase(tables: [...])` list, change `int get schemaVersion => 8;` to `=> 9;`, and add the migration branch as the last `if` inside `onUpgrade`:

```dart
          if (from < 9) {
            await m.createTable(streakCreditsTable);
          }
```

Then regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Write the repository**

```dart
// lib/features/progress/data/repositories/streak_credits_repository.dart
import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_service.dart';
import '../../domain/streak/streak_credits.dart';

/// Reads training days, and loads/stores the Freischein ledger.
///
/// [syncService] may be null in tests that do not exercise the outbox.
class StreakCreditsRepository {
  StreakCreditsRepository(this._db, this._syncService);

  final AppDatabase _db;
  final SyncService? _syncService;

  static String _rowId(String userId, String subjectProfileId) =>
      '$userId::$subjectProfileId';

  static String _encodeDay(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  static DateTime _decodeDay(String value) {
    final parts = value.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Local calendar days with at least one finished session for this profile.
  Future<Set<DateTime>> trainingDaysFor({
    required String subjectProfileId,
    required DateTime since,
  }) async {
    final rows = await (_db.select(_db.trainingSessionsTable)
          ..where((t) => t.subjectProfileId.equals(subjectProfileId))
          ..where((t) => t.isCompleted.equals(true))
          ..where((t) => t.sessionDate.isBiggerOrEqualValue(since)))
        .get();
    return {for (final row in rows) dateOnly(row.sessionDate)};
  }

  Future<StreakCredits> loadCredits({
    required String userId,
    required String subjectProfileId,
  }) async {
    final row = await (_db.select(_db.streakCreditsTable)
          ..where((t) => t.id.equals(_rowId(userId, subjectProfileId)))
          ..limit(1))
        .getSingleOrNull();
    if (row == null) return StreakCredits.empty;

    final decoded = jsonDecode(row.rescuedDays);
    final rescued = decoded is List
        ? {for (final value in decoded) _decodeDay(value as String)}
        : <DateTime>{};

    return StreakCredits(
      available: row.available,
      progressToNext: row.progressToNext,
      lastCountedDay: row.lastCountedDay,
      rescuedDays: rescued,
    );
  }

  Future<void> saveCredits({
    required String userId,
    required String subjectProfileId,
    required StreakCredits credits,
  }) async {
    final id = _rowId(userId, subjectProfileId);
    final rescued = credits.rescuedDays.map(_encodeDay).toList()..sort();
    final now = DateTime.now();

    await _db.into(_db.streakCreditsTable).insertOnConflictUpdate(
          StreakCreditsTableCompanion.insert(
            id: id,
            userId: userId,
            subjectProfileId: subjectProfileId,
            available: Value(credits.available),
            progressToNext: Value(credits.progressToNext),
            lastCountedDay: Value(credits.lastCountedDay),
            rescuedDays: Value(jsonEncode(rescued)),
            needsSync: const Value(true),
            updatedAt: Value(now),
          ),
        );

    await _syncService?.enqueueUpsert(
      tableName: 'streak_credits',
      recordId: id,
      payload: {
        'id': id,
        'user_id': userId,
        'subject_profile_id': subjectProfileId,
        'available': credits.available,
        'progress_to_next': credits.progressToNext,
        'last_counted_day': credits.lastCountedDay == null
            ? null
            : _encodeDay(credits.lastCountedDay!),
        'rescued_days': rescued,
        'updated_at': now.toIso8601String(),
      },
    );
  }

  /// Writes the derived series into `progress_entries.daily_streak` so the
  /// existing trainer RPC keeps returning a number (spec §8). The column is a
  /// mirror from here on, never a source.
  Future<void> mirrorStreak({
    required String subjectProfileId,
    required int length,
  }) async {
    final progress = await (_db.select(_db.progressEntriesTable)
          ..where((t) => t.subjectProfileId.equals(subjectProfileId))
          ..limit(1))
        .getSingleOrNull();
    if (progress == null || progress.dailyStreak == length) return;

    await (_db.update(_db.progressEntriesTable)
          ..where((t) => t.id.equals(progress.id)))
        .write(
      ProgressEntriesTableCompanion(
        dailyStreak: Value(length),
        needsSync: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await _syncService?.enqueueUpsert(
      tableName: 'progress_entries',
      recordId: progress.id,
      payload: {
        'id': progress.id,
        'user_id': progress.userId,
        'enrollment_id': progress.enrollmentId,
        'daily_streak': length,
      },
    );
  }
}
```

- [ ] **Step 6: Run the tests and confirm they pass**

Run: `flutter test test/features/progress/data/streak_credits_repository_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 7: Run the full suite so the schema bump is proven safe**

Run: `flutter test`
Expected: PASS, no regressions.

- [ ] **Step 8: Commit**

```bash
git add lib/core/database/tables/streak_credits_table.dart lib/core/database/app_database.dart lib/core/database/app_database.g.dart lib/features/progress/data/repositories/streak_credits_repository.dart test/features/progress/data/streak_credits_repository_test.dart
git commit -m "feat(streak): local Freischein ledger and training-day source (Task 5)"
```

---

## Task 6: Evaluation service and providers

**Files:**
- Create: `lib/features/progress/presentation/providers/streak_provider.dart`
- Test: `test/features/progress/presentation/streak_provider_test.dart`

**Interfaces:**
- Consumes: `StreakCreditsRepository` (Task 5), `evaluateStreak`/`StreakEvaluation` (Task 4), `databaseProvider`, `syncServiceProvider`, `appClockProvider`, `selectedSubjectProfileProvider`
- Produces:
  - `class StreakService` with `StreakService({required StreakCreditsRepository repository, required DateTime Function() now})` and `Future<StreakEvaluation> evaluate({required String userId, required String subjectProfileId})`
  - `final streakServiceProvider = Provider<StreakService>(...)`
  - `class StreakView { final int length; final int credits; final Set<DateTime> trainingDays; final Set<DateTime> rescuedDays; final Set<DateTime> newlyRescued; }`
  - `final streakViewProvider = FutureProvider<StreakView?>(...)` — null when no profile is selected

- [ ] **Step 1: Write the failing test**

```dart
// test/features/progress/presentation/streak_provider_test.dart
import 'package:corejourney/core/database/app_database.dart';
import 'package:corejourney/features/progress/data/repositories/streak_credits_repository.dart';
import 'package:corejourney/features/progress/presentation/providers/streak_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StreakCreditsRepository repository;

  setUp(() {
    db = AppDatabase.inMemory();
    repository = StreakCreditsRepository(db, null);
  });

  tearDown(() => db.close());

  Future<void> trainOn(List<DateTime> dates) async {
    for (var i = 0; i < dates.length; i++) {
      await db.into(db.trainingSessionsTable).insert(
            TrainingSessionsTableCompanion.insert(
              id: 'session-$i',
              userId: 'user-1',
              subjectProfileId: const Value('child-1'),
              enrollmentId: 'enrollment-1',
              sessionDate: dates[i],
              dayNumber: i + 1,
              completedExerciseIds: '[]',
              isCompleted: const Value(true),
            ),
          );
    }
  }

  test('earns a credit, spends it on the gap and persists the result',
      () async {
    await trainOn([
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 2),
      DateTime(2026, 8, 3),
    ]);

    final service = StreakService(
      repository: repository,
      now: () => DateTime(2026, 8, 5, 10),
    );
    final result = await service.evaluate(
      userId: 'user-1',
      subjectProfileId: 'child-1',
    );

    expect(result.length, 4);
    expect(result.newlyRescued, {DateTime(2026, 8, 4)});

    final stored = await repository.loadCredits(
      userId: 'user-1',
      subjectProfileId: 'child-1',
    );
    expect(stored.available, 0);
    expect(stored.rescuedDays, {DateTime(2026, 8, 4)});
  });

  test('a second evaluation reports nothing newly rescued', () async {
    await trainOn([
      DateTime(2026, 8, 1),
      DateTime(2026, 8, 2),
      DateTime(2026, 8, 3),
    ]);

    final service = StreakService(
      repository: repository,
      now: () => DateTime(2026, 8, 5, 10),
    );
    await service.evaluate(userId: 'user-1', subjectProfileId: 'child-1');
    final second =
        await service.evaluate(userId: 'user-1', subjectProfileId: 'child-1');

    expect(second.newlyRescued, isEmpty);
    expect(second.length, 4);
  });

  test('mirrors the derived series into progress_entries', () async {
    await db.into(db.progressEntriesTable).insert(
          ProgressEntriesTableCompanion.insert(
            id: 'progress-1',
            userId: 'user-1',
            subjectProfileId: const Value('child-1'),
            enrollmentId: 'enrollment-1',
          ),
        );
    await trainOn([DateTime(2026, 8, 2), DateTime(2026, 8, 3)]);

    final service = StreakService(
      repository: repository,
      now: () => DateTime(2026, 8, 3, 10),
    );
    await service.evaluate(userId: 'user-1', subjectProfileId: 'child-1');

    final progress = await (db.select(db.progressEntriesTable)
          ..where((t) => t.id.equals('progress-1')))
        .getSingle();
    expect(progress.dailyStreak, 2);
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/features/progress/presentation/streak_provider_test.dart`
Expected: FAIL — `StreakService` is undefined.

- [ ] **Step 3: Write the implementation**

```dart
// lib/features/progress/presentation/providers/streak_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../bootstrap/providers.dart';
import '../../../../core/time/app_clock_provider.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';
import '../../data/repositories/streak_credits_repository.dart';
import '../../domain/streak/streak_credits.dart';
import '../../domain/streak/streak_math.dart';

/// How far back the series and the rescued-day list are considered.
const int kStreakLookbackDays = 400;

/// Runs one evaluation: earn, spend, mirror (spec §4.3).
class StreakService {
  StreakService({required this.repository, required this.now});

  final StreakCreditsRepository repository;
  final DateTime Function() now;

  Future<StreakEvaluation> evaluate({
    required String userId,
    required String subjectProfileId,
  }) async {
    final today = dateOnly(now());
    final since = DateTime(
      today.year,
      today.month,
      today.day - kStreakLookbackDays,
    );

    final trainingDays = await repository.trainingDaysFor(
      subjectProfileId: subjectProfileId,
      since: since,
    );
    final credits = await repository.loadCredits(
      userId: userId,
      subjectProfileId: subjectProfileId,
    );

    final evaluation = evaluateStreak(
      trainingDays: trainingDays,
      credits: credits,
      today: today,
      lookbackDays: kStreakLookbackDays,
    );

    await repository.saveCredits(
      userId: userId,
      subjectProfileId: subjectProfileId,
      credits: evaluation.credits,
    );
    await repository.mirrorStreak(
      subjectProfileId: subjectProfileId,
      length: evaluation.length,
    );

    return evaluation;
  }
}

final streakCreditsRepositoryProvider =
    Provider<StreakCreditsRepository>((ref) {
  return StreakCreditsRepository(
    ref.watch(databaseProvider),
    ref.watch(syncServiceProvider),
  );
});

final streakServiceProvider = Provider<StreakService>((ref) {
  final clock = ref.watch(appClockProvider);
  return StreakService(
    repository: ref.watch(streakCreditsRepositoryProvider),
    now: clock.now,
  );
});

/// Everything the dashboard row needs.
class StreakView {
  const StreakView({
    required this.length,
    required this.credits,
    required this.trainingDays,
    required this.rescuedDays,
    required this.newlyRescued,
  });

  final int length;
  final int credits;
  final Set<DateTime> trainingDays;
  final Set<DateTime> rescuedDays;
  final Set<DateTime> newlyRescued;
}

final streakViewProvider = FutureProvider<StreakView?>((ref) async {
  final profile = ref.watch(selectedSubjectProfileProvider);
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (profile == null || userId == null) return null;

  final service = ref.watch(streakServiceProvider);
  final evaluation = await service.evaluate(
    userId: userId,
    subjectProfileId: profile.id,
  );

  final today = dateOnly(ref.watch(appClockProvider).now());
  final since = DateTime(
    today.year,
    today.month,
    today.day - kStreakLookbackDays,
  );
  final trainingDays = await ref
      .watch(streakCreditsRepositoryProvider)
      .trainingDaysFor(subjectProfileId: profile.id, since: since);

  return StreakView(
    length: evaluation.length,
    credits: evaluation.credits.available,
    trainingDays: trainingDays,
    rescuedDays: evaluation.credits.rescuedDays,
    newlyRescued: evaluation.newlyRescued,
  );
});
```

- [ ] **Step 4: Run the tests and confirm they pass**

Run: `flutter test test/features/progress/presentation/streak_provider_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/features/progress/presentation/providers/streak_provider.dart test/features/progress/presentation/streak_provider_test.dart
git commit -m "feat(streak): evaluation service and dashboard providers (Task 6)"
```

---

## Task 7: Dashboard streak row

**Files:**
- Create: `lib/features/progress/presentation/widgets/streak_row.dart`
- Modify: `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb`
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — replace the `_WeeklyRegularityStrip(...)` call site (around line 693) and delete the `_WeeklyRegularityStrip` class
- Test: `test/features/progress/presentation/streak_row_test.dart`
- Evidence: `docs/evidence/serie-freischeine/`

**Interfaces:**
- Consumes: `StreakView` (Task 6)
- Produces: `class StreakRow extends StatelessWidget` with `const StreakRow({super.key, required this.view, required this.today, this.onDismissRescueNotice})`

Spec reference: §6.1 and §6.2. Variant A of the mockup: one row, series on the left, credits on the right, seven day marks underneath.

- [ ] **Step 1: Add the strings to both catalogs**

In `lib/l10n/app_de.arb`:

```json
  "streakTitle": "{days, plural, one{Serie · 1 Tag} other{Serie · {days} Tage}}",
  "@streakTitle": {
    "description": "Dashboard row: current streak length",
    "placeholders": { "days": { "type": "int" } }
  },
  "streakCreditsLabel": "{count, plural, =0{keine Freischeine} one{1 Freischein} other{{count} Freischeine}}",
  "@streakCreditsLabel": {
    "description": "Dashboard row: remaining Freischeine",
    "placeholders": { "count": { "type": "int" } }
  },
  "streakRescueNotice": "Ein Freischein hat deine Serie gerettet.",
  "@streakRescueNotice": {
    "description": "Shown once after a credit was spent"
  },
  "streakLegendTrained": "trainiert",
  "@streakLegendTrained": { "description": "Legend: day with a session" },
  "streakLegendRescued": "Freischein",
  "@streakLegendRescued": { "description": "Legend: day rescued by a credit" }
```

In `lib/l10n/app_en.arb`, the same keys with:

```json
  "streakTitle": "{days, plural, one{Streak · 1 day} other{Streak · {days} days}}",
  "streakCreditsLabel": "{count, plural, =0{no passes} one{1 pass} other{{count} passes}}",
  "streakRescueNotice": "A pass saved your streak.",
  "streakLegendTrained": "trained",
  "streakLegendRescued": "pass"
```

Then run:

```bash
flutter gen-l10n && make i18n-check
```

Expected: both scripts report "passed".

- [ ] **Step 2: Write the failing test**

```dart
// test/features/progress/presentation/streak_row_test.dart
import 'package:corejourney/features/progress/presentation/providers/streak_provider.dart';
import 'package:corejourney/features/progress/presentation/widgets/streak_row.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness(Widget child) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

StreakView _view({
  int length = 4,
  int credits = 1,
  Set<DateTime>? trainingDays,
  Set<DateTime>? rescuedDays,
  Set<DateTime>? newlyRescued,
}) {
  return StreakView(
    length: length,
    credits: credits,
    trainingDays: trainingDays ?? {DateTime(2026, 8, 17), DateTime(2026, 8, 18)},
    rescuedDays: rescuedDays ?? {DateTime(2026, 8, 19)},
    newlyRescued: newlyRescued ?? const <DateTime>{},
  );
}

void main() {
  testWidgets('shows the streak length and the remaining credits',
      (tester) async {
    await tester.pumpWidget(
      _harness(StreakRow(view: _view(), today: DateTime(2026, 8, 20))),
    );
    await tester.pump();

    expect(find.text('Serie · 4 Tage'), findsOneWidget);
    expect(find.text('1 Freischein'), findsOneWidget);
  });

  testWidgets('marks trained, rescued and open days differently',
      (tester) async {
    await tester.pumpWidget(
      _harness(StreakRow(view: _view(), today: DateTime(2026, 8, 20))),
    );
    await tester.pump();

    // 2026-08-17 is a Monday, so the week runs Mon..Sun at indices 0..6:
    // trained on the 17th and 18th, rescued on the 19th, today is the 20th.
    expect(find.byKey(const ValueKey('streak-day-trained-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('streak-day-trained-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('streak-day-rescued-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('streak-day-today-3')), findsOneWidget);
  });

  testWidgets('shows the rescue notice only when a day was just rescued',
      (tester) async {
    await tester.pumpWidget(
      _harness(StreakRow(view: _view(), today: DateTime(2026, 8, 20))),
    );
    await tester.pump();
    expect(find.text('Ein Freischein hat deine Serie gerettet.'), findsNothing);

    await tester.pumpWidget(
      _harness(
        StreakRow(
          view: _view(newlyRescued: {DateTime(2026, 8, 19)}),
          today: DateTime(2026, 8, 20),
        ),
      ),
    );
    await tester.pump();
    expect(
      find.text('Ein Freischein hat deine Serie gerettet.'),
      findsOneWidget,
    );
  });
}
```

- [ ] **Step 3: Run the test and confirm it fails**

Run: `flutter test test/features/progress/presentation/streak_row_test.dart`
Expected: FAIL — `StreakRow` is undefined.

- [ ] **Step 4: Write the widget**

```dart
// lib/features/progress/presentation/widgets/streak_row.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/streak/streak_credits.dart';
import '../providers/streak_provider.dart';

/// Dashboard row: series length, remaining credits and the current week.
///
/// A day rescued by a credit is drawn differently from a trained day — the
/// week must not claim training that did not happen (spec §6.1).
class StreakRow extends StatelessWidget {
  const StreakRow({
    super.key,
    required this.view,
    required this.today,
    this.onDismissRescueNotice,
  });

  final StreakView view;
  final DateTime today;
  final VoidCallback? onDismissRescueNotice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final weekStart = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - DateTime.monday),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.streakTitle(view.length),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Icon(Icons.confirmation_number_outlined,
                    size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  l10n.streakCreditsLabel(view.credits),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (var index = 0; index < 7; index++)
                  Expanded(
                    child: _DayMark(
                      day: DateTime(
                        weekStart.year,
                        weekStart.month,
                        weekStart.day + index,
                      ),
                      index: index,
                      today: today,
                      trainingDays: view.trainingDays,
                      rescuedDays: view.rescuedDays,
                    ),
                  ),
              ],
            ),
            if (view.newlyRescued.isNotEmpty) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: onDismissRescueNotice,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    l10n.streakRescueNotice,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DayMark extends StatelessWidget {
  const _DayMark({
    required this.day,
    required this.index,
    required this.today,
    required this.trainingDays,
    required this.rescuedDays,
  });

  final DateTime day;
  final int index;
  final DateTime today;
  final Set<DateTime> trainingDays;
  final Set<DateTime> rescuedDays;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isTrained = trainingDays.contains(day);
    final isRescued = !isTrained && rescuedDays.contains(day);
    final isToday = day == dateOnly(today);

    final String state;
    if (isTrained) {
      state = 'trained';
    } else if (isRescued) {
      state = 'rescued';
    } else if (isToday) {
      state = 'today';
    } else {
      state = 'empty';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        key: ValueKey('streak-day-$state-$index'),
        height: 20,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: isTrained
              ? AppColors.primary
              : isRescued
                  ? AppColors.warning.withValues(alpha: 0.25)
                  : cs.surfaceContainerHighest,
          border: isRescued
              ? Border.all(color: AppColors.warning)
              : isToday && !isTrained
                  ? Border.all(color: cs.outline)
                  : null,
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the test and confirm it passes**

Run: `flutter test test/features/progress/presentation/streak_row_test.dart`
Expected: PASS, 3 tests.

- [ ] **Step 6: Wire it into the dashboard**

In `lib/features/dashboard/presentation/screens/dashboard_screen.dart`, replace the
`_WeeklyRegularityStrip(now: now, sessions: sessionsThisWeek)` widget (around line 693) with:

```dart
              Consumer(
                builder: (context, ref, _) {
                  final view = ref.watch(streakViewProvider).valueOrNull;
                  if (view == null) return const SizedBox.shrink();
                  return StreakRow(
                    view: view,
                    today: now,
                    // Re-evaluating clears newlyRescued, because the credit is
                    // already persisted — that is the dismissal.
                    onDismissRescueNotice: () =>
                        ref.invalidate(streakViewProvider),
                  );
                },
              ),
```

Add the two imports:

```dart
import '../../../progress/presentation/providers/streak_provider.dart';
import '../../../progress/presentation/widgets/streak_row.dart';
```

Then delete the `_WeeklyRegularityStrip` class in full, and remove the
`sessionsThisWeek` plumbing (the field on the parent widget, the constructor
parameter and the `ref.watch(thisWeekSessionsProvider)` line) **only if**
`grep -n sessionsThisWeek lib/features/dashboard/presentation/screens/dashboard_screen.dart`
shows no other reader.

- [ ] **Step 7: Verify the whole app still builds and passes**

Run: `make release-readiness-mobile`
Expected: i18n passed, analyze 0 errors / 0 warnings, all tests pass.

- [ ] **Step 8: Capture evidence**

Create `test/evidence/streak_evidence_test.dart`, copying the `_frame`,
`_capture`, `_evidenceTheme`, `_replaceTestFontFallbacks` and
`_loadEvidenceFonts` helpers from `test/evidence/adult_reflexprofil_evidence_test.dart`
verbatim, with `_out = 'docs/evidence/serie-freischeine'`, plus:

```dart
  testWidgets('capture streak evidence screenshots', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 320));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final view = StreakView(
      length: 4,
      credits: 1,
      trainingDays: {DateTime(2026, 8, 17), DateTime(2026, 8, 18)},
      rescuedDays: {DateTime(2026, 8, 19)},
      newlyRescued: {DateTime(2026, 8, 19)},
    );

    final lightKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: lightKey,
        brightness: Brightness.light,
        child: StreakRow(view: view, today: DateTime(2026, 8, 20)),
      ),
    );
    await _capture(tester, lightKey, '01_streak_row_light.png');

    final darkKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: darkKey,
        brightness: Brightness.dark,
        child: StreakRow(view: view, today: DateTime(2026, 8, 20)),
      ),
    );
    await _capture(tester, darkKey, '02_streak_row_dark.png');
  });
```

Run: `flutter test test/evidence/streak_evidence_test.dart`, then open both PNGs
and confirm the rescued day is visibly different from the trained days.

- [ ] **Step 9: Commit**

```bash
git add lib/features/progress/presentation/widgets/streak_row.dart lib/features/dashboard/presentation/screens/dashboard_screen.dart lib/l10n/ test/features/progress/presentation/streak_row_test.dart test/evidence/ docs/evidence/serie-freischeine/
git commit -m "feat(streak): show the series and credits on the dashboard (Task 7)"
```

---

## Task 8: Delete the three old streak computations

**Files:**
- Modify: `lib/features/training/data/repositories/training_completion_repository.dart:470-503`
- Modify: `lib/features/progress/presentation/providers/progress_provider.dart:745-790` and `:855-885`
- Modify: `lib/features/dev_tools/presentation/screens/dev_tools_screen.dart:75-80, 330-360, 455-465`
- Test: `test/features/training/data/repositories/training_completion_repository_test.dart`

Spec reference: §6.3. The columns stay in the schema; only the writing stops.

- [ ] **Step 1: Write the failing test**

Add to `test/features/training/data/repositories/training_completion_repository_test.dart`:

```dart
  test('completing a session no longer computes a streak', () async {
    // The series is derived from training_sessions (spec §4.1); the completion
    // path must not touch the streak columns any more.
    final before = await (db.select(db.progressEntriesTable)
          ..where((t) => t.id.equals('progress-1')))
        .getSingle();

    await repository.saveCompletedSessionAtomically(
      sessionId: 'session-new',
      userId: 'user-1',
      enrollmentId: 'enrollment-1',
      completedExerciseIds: const [],
      completedAt: DateTime(2026, 8, 20, 9),
    );

    final after = await (db.select(db.progressEntriesTable)
          ..where((t) => t.id.equals('progress-1')))
        .getSingle();

    expect(after.dailyStreak, before.dailyStreak);
    expect(after.weeklyStreak, before.weeklyStreak);
    expect(after.currentDay, before.currentDay + 1);
  });
```

Adjust the fixture names to the ones already used in that file.

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/features/training/data/repositories/training_completion_repository_test.dart`
Expected: FAIL — `dailyStreak` changed.

- [ ] **Step 3: Remove the streak math from the completion repository**

In `training_completion_repository.dart`, `_computeProgressUpdate` (around line
470) becomes:

```dart
    final lastActivityDate = progress.lastActivityDate == null
        ? null
        : _localDate(progress.lastActivityDate!);
    if (lastActivityDate != null &&
        _isSameDate(lastActivityDate, sessionDate)) {
      return null;
    }

    // The series is derived from training_sessions (spec §4.1) — this path
    // only advances the package day counter.
    return _ProgressUpdate(
      currentDay: progress.currentDay + 1,
      totalSessionsSinceDisclaimer: progress.totalSessionsSinceDisclaimer + 1,
    );
```

Reduce `_ProgressUpdate` to those two fields, and reduce the write at line ~303
to:

```dart
        ProgressEntriesTableCompanion(
          currentDay: Value(progressUpdate.currentDay),
          lastActivityDate: Value(sessionDate),
          totalSessionsSinceDisclaimer:
              Value(progressUpdate.totalSessionsSinceDisclaimer),
          needsSync: const Value(true),
          updatedAt: Value(completedAt),
        ),
```

Drop the `daily_streak`, `weekly_streak`, `trainings_this_week`,
`last_training_week_start`, `weekly_goal` and `consecutive_inactive_days` keys
from both sync payloads (lines ~147 and ~366).

- [ ] **Step 4: Remove the streak math from both provider paths**

In `progress_provider.dart`, `saveCompletedSession` keeps its idempotency guard
and writes only:

```dart
      .write(ProgressEntriesTableCompanion(
    currentDay: drift.Value(progress.currentDay + 1),
    lastActivityDate: drift.Value(today),
    totalSessionsSinceDisclaimer:
        drift.Value(progress.totalSessionsSinceDisclaimer + 1),
    needsSync: const drift.Value(true),
    updatedAt: drift.Value(now),
  ));
```

Delete the `newDailyStreak` / `newWeeklyStreak` / `newTrainingsThisWeek` /
`thisWeekStart` block above it and the matching keys in the payload. Apply the
same reduction to `saveVorrundeRegulationSession` (around line 860).

While you are in this function, widen its signature so Task 12 can drive it
from a test — the body already computes `now` and `userId` internally:

```dart
Future<void> saveCompletedSession({
  required AppDatabase db,
  required SyncService? syncService,
  required EnrollmentsTableData enrollment,
  required ProgressEntriesTableData progress,
  required List<String> completedExerciseIds,
  String? userId,
  DateTime? now,
}) async {
  final resolvedUserId =
      userId ?? Supabase.instance.client.auth.currentUser?.id;
  if (resolvedUserId == null) return;
  final timestamp = now ?? DateTime.now();
  final today = DateTime(timestamp.year, timestamp.month, timestamp.day);
  // ...rest unchanged, using resolvedUserId / timestamp / today
```

Replace every `syncService.enqueueUpsert(` in this function with
`await syncService?.enqueueUpsert(`.

- [ ] **Step 5: Point the debug panel at the derived value**

In `dev_tools_screen.dart`, replace the `progress?.dailyStreak` readout (line
~75) with `ref.watch(streakViewProvider).valueOrNull?.length ?? 0` and drop the
`trainingsThisWeek / weeklyGoal` readout (line ~79) — both numbers stopped being
written in the steps above and would show stale zeros.

- [ ] **Step 6: Run the tests and confirm they pass**

Run: `flutter test`
Expected: PASS. If a test asserted the old streak behaviour, delete that assertion — the behaviour is gone by design; note it in the commit body.

- [ ] **Step 7: Commit**

```bash
git add lib/features/training/data/repositories/training_completion_repository.dart lib/features/progress/presentation/providers/progress_provider.dart lib/features/dev_tools/presentation/screens/dev_tools_screen.dart test/
git commit -m "refactor(streak): delete the three old streak computations (Task 8)"
```

---

## Task 9: Evening notification

**Files:**
- Modify: `lib/core/notifications/notification_service.dart`
- Modify: `lib/app.dart:455-500` (`_syncReminderState`)
- Modify: `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb`
- Test: `test/core/notifications/streak_notification_test.dart`

**Interfaces:**
- Consumes: `StreakView` (Task 6)
- Produces: `Future<void> scheduleStreakNotices({required int endMinutes, required String Function(int credits) bodyWithCredits, required String bodyWithoutCredits, required String title, required int credits, required bool trainedToday})` and `Future<void> cancelStreakNotices()` on `NotificationService`

Spec reference: §5. IDs 900–906 are reserved for the seven scheduled days.

- [ ] **Step 1: Add the strings to both catalogs**

`lib/l10n/app_de.arb`:

```json
  "streakNoticeTitle": "Reflex Journey",
  "@streakNoticeTitle": { "description": "Title of the evening streak notice" },
  "streakNoticeWithCredits": "Heute noch nicht geübt. Wenn der Tag ohne Training endet, springt ein Freischein ein — du hast noch {count}.",
  "@streakNoticeWithCredits": {
    "description": "Evening notice while credits remain",
    "placeholders": { "count": { "type": "int" } }
  },
  "streakNoticeWithoutCredits": "Heute noch nicht geübt. Ohne Freischein endet deine Serie heute.",
  "@streakNoticeWithoutCredits": {
    "description": "Evening notice with an empty ledger"
  }
```

`lib/l10n/app_en.arb`, same keys:

```json
  "streakNoticeTitle": "Reflex Journey",
  "streakNoticeWithCredits": "No practice yet today. If the day ends without training, a pass steps in — you have {count} left.",
  "streakNoticeWithoutCredits": "No practice yet today. Without a pass, your streak ends today."
```

Run: `flutter gen-l10n && make i18n-check`

- [ ] **Step 2: Write the failing test**

```dart
// test/core/notifications/streak_notification_test.dart
import 'package:corejourney/core/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plans one notice per day for the coming week', () {
    final fireTimes = streakNoticeFireTimes(
      from: DateTime(2026, 8, 20, 9),
      endMinutes: 20 * 60,
      trainedToday: false,
    );
    expect(fireTimes, hasLength(7));
    expect(fireTimes.first, DateTime(2026, 8, 20, 20));
    expect(fireTimes.last, DateTime(2026, 8, 26, 20));
  });

  test('skips today once the day is done', () {
    final fireTimes = streakNoticeFireTimes(
      from: DateTime(2026, 8, 20, 9),
      endMinutes: 20 * 60,
      trainedToday: true,
    );
    expect(fireTimes, hasLength(6));
    expect(fireTimes.first, DateTime(2026, 8, 21, 20));
  });

  test('skips today when the slot has already passed', () {
    final fireTimes = streakNoticeFireTimes(
      from: DateTime(2026, 8, 20, 21),
      endMinutes: 20 * 60,
      trainedToday: false,
    );
    expect(fireTimes.first, DateTime(2026, 8, 21, 20));
  });
}
```

- [ ] **Step 3: Run the test and confirm it fails**

Run: `flutter test test/core/notifications/streak_notification_test.dart`
Expected: FAIL — `streakNoticeFireTimes` is undefined.

- [ ] **Step 4: Write the implementation**

Add to `lib/core/notifications/notification_service.dart` (top-level, so it is testable without the plugin):

```dart
/// Notification ids reserved for the evening streak notice — one per planned
/// day. Ids 1 (daily reminder) and 500–899 (trainer alerts) are taken.
const int kStreakNoticeFirstId = 900;
const int kStreakNoticeDays = 7;

/// The fire times for the coming [kStreakNoticeDays] days.
///
/// A scheduled notification cannot check anything when it fires, so the slots
/// are planned ahead and cancelled again once the day is trained (spec §5).
List<DateTime> streakNoticeFireTimes({
  required DateTime from,
  required int endMinutes,
  required bool trainedToday,
}) {
  final hour = endMinutes ~/ 60;
  final minute = endMinutes % 60;
  final times = <DateTime>[];

  for (var offset = 0; offset < kStreakNoticeDays; offset++) {
    final day = DateTime(from.year, from.month, from.day + offset);
    final fireTime = DateTime(day.year, day.month, day.day, hour, minute);
    if (offset == 0 && (trainedToday || !fireTime.isAfter(from))) continue;
    times.add(fireTime);
  }
  return times;
}
```

Then add these two methods to the `NotificationService` class:

```dart
  /// Cancels every planned streak notice.
  Future<void> cancelStreakNotices() async {
    if (!_enabled) return;
    for (var offset = 0; offset < kStreakNoticeDays; offset++) {
      await _plugin.cancel(kStreakNoticeFirstId + offset);
    }
  }

  /// Plans one-off evening notices for the coming week (spec §5).
  ///
  /// One-off on purpose: a repeating notification cannot be suppressed for a
  /// single day, and the notice must disappear the moment the day is trained.
  Future<void> scheduleStreakNotices({
    required int endMinutes,
    required String title,
    required String Function(int credits) bodyWithCredits,
    required String bodyWithoutCredits,
    required int credits,
    required bool trainedToday,
  }) async {
    if (!_enabled || !_initialized) return;
    await cancelStreakNotices();

    final body = credits > 0 ? bodyWithCredits(credits) : bodyWithoutCredits;
    final androidDetails = AndroidNotificationDetails(
      _kAndroidChannelId,
      await _channelName(),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);

    final now = tz.TZDateTime.now(tz.local);
    final fireTimes = streakNoticeFireTimes(
      from: DateTime(now.year, now.month, now.day, now.hour, now.minute),
      endMinutes: endMinutes,
      trainedToday: trainedToday,
    );

    for (var i = 0; i < fireTimes.length; i++) {
      final fireTime = fireTimes[i];
      await _plugin.zonedSchedule(
        kStreakNoticeFirstId + i,
        title,
        body,
        tz.TZDateTime(tz.local, fireTime.year, fireTime.month, fireTime.day,
            fireTime.hour, fireTime.minute),
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    appLogger.d('Streak notices scheduled: ${fireTimes.length}');
  }
```

- [ ] **Step 5: Call it from the reminder sync**

Add this helper to `lib/app.dart` and call it at the end of
`_syncReminderState`, and again next to the existing
`suppressTodayAndReschedule` calls in `training_session_screen.dart:393` and
`dashboard_screen.dart:195`:

```dart
Future<void> syncStreakNotices(WidgetRef ref) async {
  final settings = ref.read(settingsProvider);
  final ns = ref.read(notificationServiceProvider);

  if (!settings.remindersEnabled) {
    await ns.cancelStreakNotices();
    return;
  }

  final view = await ref.read(streakViewProvider.future);
  if (view == null) {
    await ns.cancelStreakNotices();
    return;
  }

  final l10n = await lookupActiveAppLocalizations();
  final today = dateOnly(ref.read(appClockProvider).now());
  await ns.scheduleStreakNotices(
    endMinutes: settings.reminderEndMinutes,
    title: l10n.streakNoticeTitle,
    bodyWithCredits: l10n.streakNoticeWithCredits,
    bodyWithoutCredits: l10n.streakNoticeWithoutCredits,
    credits: view.credits,
    trainedToday: view.trainingDays.contains(today),
  );
}
```

`l10n.streakNoticeWithCredits` is generated as `String Function(int)`, which
matches the `bodyWithCredits` parameter exactly — do not wrap it in a lambda.

- [ ] **Step 6: Run everything**

Run: `make release-readiness-mobile`
Expected: all green.

- [ ] **Step 7: Commit**

```bash
git add lib/core/notifications/notification_service.dart lib/app.dart lib/features/training/presentation/screens/training_session_screen.dart lib/features/dashboard/presentation/screens/dashboard_screen.dart lib/l10n/ test/core/notifications/streak_notification_test.dart
git commit -m "feat(streak): evening notice that warns before a pass is spent (Task 9)"
```

---

## Task 10: Server table and rehydration — GATED

**Files:**
- Create: `supabase/migrations/YYYYMMDDNN_profile_streak_credits.sql` (use today's date plus a two-digit run number, e.g. `2026082301_profile_streak_credits.sql`)
- Modify: `lib/core/sync/sync_service.dart:306` (`rehydrate`)

> **STOP — founder gate.** This task writes the migration file and proves it
> locally. It does **not** apply anything to the live database. Present the
> exact SQL, the blast radius and the rollback to the founder and wait for an
> explicit go before any live apply (CLAUDE.md §3).

- [ ] **Step 1: Write the migration**

```sql
-- Freischein ledger, one row per subject profile.
-- The streak itself is derived from training_sessions (see
-- docs/superpowers/specs/2026-08-23-serie-und-freischeine-design.md §4.1).

CREATE TABLE IF NOT EXISTS public.streak_credits (
  id text PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subject_profile_id uuid NOT NULL
    REFERENCES public.reflex_subject_profiles(id) ON DELETE CASCADE,
  available int NOT NULL DEFAULT 0 CHECK (available BETWEEN 0 AND 2),
  progress_to_next int NOT NULL DEFAULT 0 CHECK (progress_to_next BETWEEN 0 AND 2),
  last_counted_day date,
  rescued_days date[] NOT NULL DEFAULT '{}',
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, subject_profile_id)
);

CREATE INDEX IF NOT EXISTS idx_streak_credits_user
  ON public.streak_credits(user_id);

ALTER TABLE public.streak_credits ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cj: streak_credits all own" ON public.streak_credits;
CREATE POLICY "cj: streak_credits all own"
  ON public.streak_credits FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "cj: streak_credits trainer read" ON public.streak_credits;
CREATE POLICY "cj: streak_credits trainer read"
  ON public.streak_credits FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.trainer_client_relationships tcr
      WHERE tcr.trainer_id = auth.uid()
        AND tcr.client_id = streak_credits.user_id
        AND tcr.status = 'active'
    )
  );
```

Mirror the exact `USING` clause of the existing `"cj: progress_entries trainer read"` policy in `supabase/migrations/20260702_rls_baseline_core_tables.sql:165-172` — copy it rather than re-deriving it.

- [ ] **Step 2: Prove it replays locally**

Run: `supabase db reset --local`
Expected: every migration replays green, including the new file.

- [ ] **Step 3: Add rehydration**

In `SyncService.rehydrate`, after the `training_sessions` block (around line
478), insert:

```dart
      // 5. Pull streak_credits for this user
      final creditRows = await client
          .from('streak_credits')
          .select()
          .eq('user_id', userId) as List<dynamic>;

      for (final raw in creditRows) {
        final row = raw as Map<String, dynamic>;
        final id = row['id'] as String;

        // Skip records with pending local changes
        final local = await (_db.select(_db.streakCreditsTable)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (local?.needsSync == true) continue;

        // Postgres date[] -> the JSON list format StreakCreditsRepository reads
        final rescued = (row['rescued_days'] as List<dynamic>? ?? const [])
            .map((value) => value as String)
            .toList()
          ..sort();
        final lastCounted = row['last_counted_day'] as String?;

        await _db.into(_db.streakCreditsTable).insertOnConflictUpdate(
              StreakCreditsTableCompanion.insert(
                id: id,
                userId: row['user_id'] as String,
                subjectProfileId: row['subject_profile_id'] as String,
                available: Value(row['available'] as int? ?? 0),
                progressToNext: Value(row['progress_to_next'] as int? ?? 0),
                lastCountedDay: Value(
                  lastCounted == null ? null : DateTime.parse(lastCounted),
                ),
                rescuedDays: Value(jsonEncode(rescued)),
                needsSync: const Value(false),
                updatedAt: Value(
                  row['updated_at'] != null
                      ? DateTime.parse(row['updated_at'] as String)
                      : DateTime.now(),
                ),
              ),
            );
      }
```

- [ ] **Step 4: Run everything**

Run: `make release-readiness-mobile`
Expected: all green.

- [ ] **Step 5: Commit — no live apply**

```bash
git add supabase/migrations/ lib/core/sync/sync_service.dart
git commit -m "feat(streak): server table and rehydration for the credit ledger (Task 10)"
```

- [ ] **Step 6: Present the live-apply request to the founder**

Show the exact SQL, which tables it touches, that no existing row is modified, and the rollback (`DROP TABLE public.streak_credits;`). Wait for an explicit go. Do not apply.

---

## Task 11: Shared "who is training?" picker

**Files:**
- Create: `lib/features/training/presentation/widgets/joint_training_sheet.dart`
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — `_askForJointTrainingProfiles`, `_showJointTrainingDialog`, `_beginUnit`
- Test: `test/features/training/presentation/joint_training_sheet_test.dart`

**Interfaces:**
- Consumes: `ReflexSubjectProfile`, `AppDatabase`
- Produces:
  - `class JointTrainingCandidate { final ReflexSubjectProfile profile; }`
  - `List<String> defaultJointSelection({required List<JointTrainingCandidate> candidates, required List<String> remembered})`
  - `Future<List<String>?> showJointTrainingSheet(BuildContext context, {required List<JointTrainingCandidate> candidates, required Set<String> preselected, required String confirmLabel})`

Spec reference: §7, decisions D13 and D14.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/training/presentation/joint_training_sheet_test.dart
import 'package:corejourney/features/assessment/presentation/providers/reflex_profile_provider.dart';
import 'package:corejourney/features/training/presentation/widgets/joint_training_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

ReflexSubjectProfile _profile(String id, String name) => ReflexSubjectProfile(
      id: id,
      displayName: name,
      profileType: 'child',
    );

void main() {
  test('without a remembered selection every candidate is preselected', () {
    final candidates = [
      JointTrainingCandidate(profile: _profile('a', 'Lena')),
      JointTrainingCandidate(profile: _profile('b', 'Noah')),
    ];
    expect(
      defaultJointSelection(candidates: candidates, remembered: const []),
      ['a', 'b'],
    );
  });

  test('the remembered selection wins when it still applies', () {
    final candidates = [
      JointTrainingCandidate(profile: _profile('a', 'Lena')),
      JointTrainingCandidate(profile: _profile('b', 'Noah')),
    ];
    expect(
      defaultJointSelection(candidates: candidates, remembered: const ['b']),
      ['b'],
    );
  });

  test('remembered profiles that are gone drop out', () {
    final candidates = [JointTrainingCandidate(profile: _profile('a', 'Lena'))];
    expect(
      defaultJointSelection(
        candidates: candidates,
        remembered: const ['b', 'a'],
      ),
      ['a'],
    );
  });

  test('an empty remembered result falls back to everyone', () {
    final candidates = [JointTrainingCandidate(profile: _profile('a', 'Lena'))];
    expect(
      defaultJointSelection(candidates: candidates, remembered: const ['gone']),
      ['a'],
    );
  });
}
```

Adjust the `ReflexSubjectProfile` constructor call to the real required parameters in `reflex_profile_provider.dart:10-35`.

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/features/training/presentation/joint_training_sheet_test.dart`
Expected: FAIL — `JointTrainingCandidate` is undefined.

- [ ] **Step 3: Write the implementation**

```dart
// lib/features/training/presentation/widgets/joint_training_sheet.dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../assessment/presentation/providers/reflex_profile_provider.dart';

/// One profile that could join today's session.
class JointTrainingCandidate {
  const JointTrainingCandidate({required this.profile});

  final ReflexSubjectProfile profile;
}

/// Which candidates start ticked (spec §7.2, D14).
///
/// The remembered selection wins, minus anyone who is no longer a candidate.
/// If nothing survives, everyone is ticked — the same behaviour as a first run.
List<String> defaultJointSelection({
  required List<JointTrainingCandidate> candidates,
  required List<String> remembered,
}) {
  final ids = candidates.map((candidate) => candidate.profile.id).toList();
  if (remembered.isEmpty) return ids;

  final survivors = ids.where(remembered.contains).toList();
  return survivors.isEmpty ? ids : survivors;
}

/// Asks who is training. Returns null when the user backs out.
Future<List<String>?> showJointTrainingSheet(
  BuildContext context, {
  required List<JointTrainingCandidate> candidates,
  required Set<String> preselected,
  required String confirmLabel,
}) {
  final selected = {...preselected};
  final l10n = AppLocalizations.of(context);

  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(l10n.dashboardJointTrainingTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.dashboardJointTrainingBody),
            const SizedBox(height: 12),
            for (final candidate in candidates)
              CheckboxListTile(
                key: ValueKey('joint-${candidate.profile.id}'),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: selected.contains(candidate.profile.id),
                title: Text(candidate.profile.displayName),
                onChanged: (value) => setDialogState(() {
                  if (value == true) {
                    selected.add(candidate.profile.id);
                  } else {
                    selected.remove(candidate.profile.id);
                  }
                }),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, selected.toList()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 4: Widen the candidate query and remember the selection**

In `dashboard_screen.dart`, replace `_askForJointTrainingProfiles` with:

```dart
  /// Returns the chosen companion ids, `const []` when nobody could join, and
  /// `null` when the user backed out of the sheet. Task 12 needs those two
  /// cases kept apart.
  Future<List<String>?> _askForJointTrainingProfiles({
    required String packageId,
    required String confirmLabel,
  }) async {
    final activeProfile = ref.read(selectedSubjectProfileProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (activeProfile == null || userId == null) return const [];

    // D13: every profile with a running enrollment, the adult one included —
    // the old version bailed out unless the active profile was a child.
    final profiles =
        ref.read(allReflexSubjectProfilesProvider).valueOrNull ?? const [];
    final others =
        profiles.where((profile) => profile.id != activeProfile.id).toList();
    if (others.isEmpty) return const [];

    final db = ref.read(databaseProvider);
    final today = dateOnly(ref.read(appClockProvider).now());
    final candidates = <JointTrainingCandidate>[];

    for (final profile in others) {
      final enrollment = await (db.select(db.enrollmentsTable)
            ..where((t) => t.subjectProfileId.equals(profile.id))
            ..where((t) => t.packageId.equals(packageId))
            ..where((t) => t.status.equals('active'))
            ..limit(1))
          .getSingleOrNull();
      if (enrollment == null) continue;

      final trainedToday = await (db.select(db.trainingSessionsTable)
            ..where((t) => t.subjectProfileId.equals(profile.id))
            ..where((t) => t.isCompleted.equals(true))
            ..where((t) => t.sessionDate.isBiggerOrEqualValue(today))
            ..where((t) => t.sessionDate.isSmallerThanValue(nextDay(today)))
            ..limit(1))
          .getSingleOrNull();
      if (trainedToday != null) continue;

      candidates.add(JointTrainingCandidate(profile: profile));
    }
    if (candidates.isEmpty || !mounted) return const [];

    // D14: start from whoever took part last time.
    final prefs = await SharedPreferences.getInstance();
    final key = 'joint_training_selection_${userId}_$packageId';
    final remembered = prefs.getStringList(key) ?? const <String>[];
    final preselected =
        defaultJointSelection(candidates: candidates, remembered: remembered);

    if (!mounted) return const [];
    final selected = await showJointTrainingSheet(
      context,
      candidates: candidates,
      preselected: preselected.toSet(),
      confirmLabel: confirmLabel,
    );
    if (selected == null) return null;

    await prefs.setStringList(key, selected);
    return selected;
  }
```

Add the imports this needs to `dashboard_screen.dart` if they are not already
there: `package:shared_preferences/shared_preferences.dart`,
`../../../progress/domain/streak/streak_credits.dart` (for `dateOnly` and
`nextDay`) and `../../../training/presentation/widgets/joint_training_sheet.dart`.

Update the one existing caller in `_beginUnit` to pass
`confirmLabel: AppLocalizations.of(context).dashboardJointTrainingTogether`
and to treat a cancelled sheet as "do not start":

```dart
    final companions = await _askForJointTrainingProfiles(
      packageId: packageId,
      confirmLabel: AppLocalizations.of(context).dashboardJointTrainingTogether,
    );
    if (companions == null || !mounted) return;
```
Delete `_showJointTrainingDialog` and the private `_JointTrainingCandidate`
class — both are replaced by the shared widget.

- [ ] **Step 5: Run the tests and confirm they pass**

Run: `flutter test test/features/training/presentation/joint_training_sheet_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/training/presentation/widgets/joint_training_sheet.dart lib/features/dashboard/presentation/screens/dashboard_screen.dart test/features/training/presentation/joint_training_sheet_test.dart
git commit -m "feat(training): shared joint-training picker with remembered selection (Task 11)"
```

---

## Task 12: Ask on the manual logging path too

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart:150-200` (`_markTodayComplete`)
- Test: `test/features/dashboard/mark_today_complete_test.dart`

Spec reference: §7.2, decision D12. The picker **replaces** the current confirmation dialog — one question instead of two — and keeps the `dashboardLogUnitConfirm` wording on the confirming button.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/dashboard/mark_today_complete_test.dart
import 'package:corejourney/core/database/app_database.dart';
import 'package:corejourney/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.inMemory());
  tearDown(() => db.close());

  test('logging a day writes one session row per selected profile', () async {
    for (final id in ['child-1', 'child-2']) {
      await db.into(db.enrollmentsTable).insert(
            EnrollmentsTableCompanion.insert(
              id: 'enrollment-$id',
              userId: 'user-1',
              subjectProfileId: Value(id),
              packageId: 'moro',
              assignedDurationWeeks: 4,
              startDate: DateTime(2026, 8, 1),
              targetCompletionDate: DateTime(2026, 8, 29),
            ),
          );
      await db.into(db.progressEntriesTable).insert(
            ProgressEntriesTableCompanion.insert(
              id: 'progress-$id',
              userId: 'user-1',
              subjectProfileId: Value(id),
              enrollmentId: 'enrollment-$id',
            ),
          );
    }

    await logTrainingDayForProfiles(
      db: db,
      syncService: null,
      userId: 'user-1',
      packageId: 'moro',
      subjectProfileIds: const ['child-1', 'child-2'],
      now: DateTime(2026, 8, 20, 19),
    );

    final rows = await db.select(db.trainingSessionsTable).get();
    expect(rows, hasLength(2));
    expect(
      rows.map((row) => row.subjectProfileId).toSet(),
      {'child-1', 'child-2'},
    );
  });

  test('a profile that already trained today is skipped', () async {
    await db.into(db.enrollmentsTable).insert(
          EnrollmentsTableCompanion.insert(
            id: 'enrollment-1',
            userId: 'user-1',
            subjectProfileId: const Value('child-1'),
            packageId: 'moro',
            assignedDurationWeeks: 4,
            startDate: DateTime(2026, 8, 1),
            targetCompletionDate: DateTime(2026, 8, 29),
          ),
        );
    await db.into(db.progressEntriesTable).insert(
          ProgressEntriesTableCompanion.insert(
            id: 'progress-1',
            userId: 'user-1',
            subjectProfileId: const Value('child-1'),
            enrollmentId: 'enrollment-1',
          ),
        );
    await db.into(db.trainingSessionsTable).insert(
          TrainingSessionsTableCompanion.insert(
            id: 'existing',
            userId: 'user-1',
            subjectProfileId: const Value('child-1'),
            enrollmentId: 'enrollment-1',
            sessionDate: DateTime(2026, 8, 20),
            dayNumber: 1,
            completedExerciseIds: '[]',
            isCompleted: const Value(true),
          ),
        );

    await logTrainingDayForProfiles(
      db: db,
      syncService: null,
      userId: 'user-1',
      packageId: 'moro',
      subjectProfileIds: const ['child-1'],
      now: DateTime(2026, 8, 20, 19),
    );

    expect(await db.select(db.trainingSessionsTable).get(), hasLength(1));
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/features/dashboard/mark_today_complete_test.dart`
Expected: FAIL — `logTrainingDayForProfiles` is undefined.

- [ ] **Step 3: Write the logging helper**

Add this top-level function to `dashboard_screen.dart`, above the state class.
It relies on the widened `saveCompletedSession` signature from Task 8 Step 4:

```dart
/// Records a training day for each of [subjectProfileIds] (spec §7.2, D12).
///
/// A profile that already has a finished session today is skipped, so a second
/// tap cannot inflate anybody's series.
Future<void> logTrainingDayForProfiles({
  required AppDatabase db,
  required SyncService? syncService,
  required String userId,
  required String packageId,
  required List<String> subjectProfileIds,
  required DateTime now,
}) async {
  final today = dateOnly(now);

  for (final subjectProfileId in subjectProfileIds) {
    final enrollment = await (db.select(db.enrollmentsTable)
          ..where((t) => t.subjectProfileId.equals(subjectProfileId))
          ..where((t) => t.packageId.equals(packageId))
          ..where((t) => t.status.equals('active'))
          ..limit(1))
        .getSingleOrNull();
    if (enrollment == null) continue;

    final progress = await (db.select(db.progressEntriesTable)
          ..where((t) => t.enrollmentId.equals(enrollment.id))
          ..limit(1))
        .getSingleOrNull();
    if (progress == null) continue;

    final already = await (db.select(db.trainingSessionsTable)
          ..where((t) => t.subjectProfileId.equals(subjectProfileId))
          ..where((t) => t.isCompleted.equals(true))
          ..where((t) => t.sessionDate.isBiggerOrEqualValue(today))
          ..where((t) => t.sessionDate.isSmallerThanValue(nextDay(today)))
          ..limit(1))
        .getSingleOrNull();
    if (already != null) continue;

    await saveCompletedSession(
      db: db,
      syncService: syncService,
      enrollment: enrollment,
      progress: progress,
      completedExerciseIds: const [],
      userId: userId,
      now: now,
    );
  }
}
```

- [ ] **Step 4: Ask before logging**

In `_markTodayComplete`, replace the current `showDialog<bool>(...)`
confirmation with:

```dart
    final activeProfile = ref.read(selectedSubjectProfileProvider);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (activeProfile == null || userId == null) return;

    final l10n = AppLocalizations.of(context);
    final packageId = ref.read(selectedPackageIdProvider);

    // D12: the picker replaces the old confirmation — one question, not two.
    final companions = await _askForJointTrainingProfiles(
      packageId: packageId,
      confirmLabel: l10n.dashboardLogUnitConfirm,
    );
    if (companions == null || !mounted) return;

    if (companions.isEmpty) {
      // Nobody else could join: keep the plain confirmation.
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.dashboardLogUnitTitle),
          content: Text(l10n.dashboardLogUnitBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.dashboardLogUnitConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    await logTrainingDayForProfiles(
      db: ref.read(databaseProvider),
      syncService: ref.read(syncServiceProvider),
      userId: userId,
      packageId: packageId,
      subjectProfileIds: [activeProfile.id, ...companions],
      now: ref.read(appClockProvider).now(),
    );
    ref.invalidate(streakViewProvider);
```

Keep the existing experience-prompt and snackbar code that follows.

The nullable return from Task 11 is what makes this safe: `null` means the user
backed out and nothing is logged, while `const []` means nobody else could join
and the plain confirmation takes over.

- [ ] **Step 5: Run the tests and confirm they pass**

Run: `flutter test test/features/dashboard/mark_today_complete_test.dart`
Expected: PASS, 2 tests.

- [ ] **Step 6: Capture evidence**

Extend `test/evidence/streak_evidence_test.dart` (Task 7 Step 8) with a capture
of the picker, using the same `_frame` / `_capture` helpers:

```dart
    final pickerKey = GlobalKey();
    await tester.pumpWidget(
      _frame(
        key: pickerKey,
        brightness: Brightness.light,
        child: Builder(
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final name in ['Lena', 'Noah'])
                CheckboxListTile(
                  value: true,
                  onChanged: (_) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(name),
                ),
            ],
          ),
        ),
      ),
    );
    await _capture(tester, pickerKey, '03_joint_training_picker.png');
```

- [ ] **Step 7: Run the full gate**

Run: `make release-readiness-mobile`
Expected: i18n passed, analyze 0 errors / 0 warnings, all tests pass.

- [ ] **Step 8: Commit**

```bash
git add lib/features/dashboard/presentation/screens/dashboard_screen.dart lib/features/progress/presentation/providers/progress_provider.dart test/ docs/evidence/serie-freischeine/
git commit -m "feat(training): ask who trained when logging a day manually (Task 12)"
```

---

## Spec coverage

| Spec section | Task |
|---|---|
| §4.1 derived series | 4 |
| §4.2 stored ledger | 5 |
| §4.3 evaluation order | 6 |
| §4.4 earning | 2 |
| §4.5 spending, D10, D11 | 3 |
| §5 notification | 9 |
| §6.1 dashboard row, §6.2 feedback | 7 |
| §6.3 removals | 8 |
| §7 who is training, D12–D14 | 11, 12 |
| §8 trainer mirror | 5 (`mirrorStreak`), 6 (called from `evaluate`) |
| §9 migration, RLS, sync | 10 |
| §10 tests | every task |
