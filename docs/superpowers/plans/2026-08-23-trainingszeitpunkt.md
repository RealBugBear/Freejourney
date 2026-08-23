# Trainingszeitpunkt im Alltag — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ask once, after the first completed training, when the user wants to be reminded — and switch reminders on with the answer.

**Architecture:** A pure anchor model (which options exist per audience, which clock time each proposes) with no Flutter dependency, a `SharedPreferences` store following the existing `RoutineTipSettings` pattern, a bottom sheet in the style of the existing routine tip, and one trigger in the dashboard's existing `addPostFrameCallback`. Applying the answer reuses the settings notifier and the existing reminder sync — no new notification code.

**Tech Stack:** Flutter 3.38, Riverpod, SharedPreferences, `flutter_local_notifications` (indirectly, via the existing reminder sync).

**Spec:** `docs/superpowers/specs/2026-08-23-trainingszeitpunkt-design.md`

## Global Constraints

- Work in `/Users/alexandermessinger/dev/claudvibes/reflexjourney`. Verify with `git rev-parse --show-toplevel` before every commit (CLAUDE.md §1, mistake #3).
- **Never `git push`** (CLAUDE.md §3). Local commits only.
- **No database work in this plan at all.** Nothing touches `supabase/`, no migration, no SQL. If a task seems to need it, stop and ask.
- Every user-facing string goes into **both** `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`, then `flutter gen-l10n`. No string literals in widgets (mistake #12). German addresses the user as "du".
- Generated files (`app_localizations*.dart`, `*.g.dart`) are committed but **never hand-edited** (mistake #13).
- **No medical claims and no mention of medication, alcohol or drugs anywhere** in this feature (spec §6 and §7, founder decision A1, and the standing decision in `2026-08-21-adult-reflexprofil-questionnaire.md` §17). The evening hint is an observation about falling asleep, nothing more.
- Done means: `flutter analyze --no-fatal-infos` → 0 errors, 0 warnings; `flutter test` → 100% pass. `make release-readiness-mobile` runs both plus the i18n gate.
- Commit messages reference the plan task, e.g. `feat(reminders): anchor model and default times (Task 1)`.

---

## File Structure

**Create**

| File | Responsibility |
|---|---|
| `lib/core/training/training_anchor.dart` | Enum, per-audience option lists, default clock times, evening-hint predicate. No Flutter imports. |
| `lib/core/training/training_anchor_settings.dart` | SharedPreferences store: chosen anchor, whether the question was asked |
| `lib/features/training/presentation/widgets/training_anchor_sheet.dart` | The bottom sheet |

**Modify**

| File | Change |
|---|---|
| `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb` | New strings |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart:106-125` | Trigger, and one-sheet-per-return guard |
| `lib/features/settings/presentation/screens/settings_screen.dart:138-156` | Anchor row in the reminder block |

**Not touched:** `lib/core/notifications/`, `lib/app.dart`. Switching `remindersEnabled` on already makes the existing sync schedule both the training reminder and the streak evening notice.

---

## Task 1: Anchor model

**Files:**
- Create: `lib/core/training/training_anchor.dart`
- Test: `test/core/training/training_anchor_test.dart`

**Interfaces:**
- Consumes: nothing
- Produces:
  - `enum TrainingAnchor { wakeUp, afterBreakfast, midday, evening, afterSchool, afterDinner, fixedTime }`
  - `List<TrainingAnchor> anchorOptionsFor({required bool isAdultSelf})`
  - `TrainingAnchor? recommendedAnchorFor({required bool isAdultSelf})`
  - `int defaultMinutesFor(TrainingAnchor anchor)`
  - `bool showsEveningHint(TrainingAnchor anchor)`
  - `TrainingAnchor? anchorFromName(String? name)`

Spec reference: §4.3, §4.5, decision A2.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/training/training_anchor_test.dart
import 'package:corejourney/core/training/training_anchor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('adults are offered four anchors, waking up first', () {
    final options = anchorOptionsFor(isAdultSelf: true);
    expect(options, [
      TrainingAnchor.wakeUp,
      TrainingAnchor.afterBreakfast,
      TrainingAnchor.midday,
      TrainingAnchor.evening,
    ]);
  });

  test('families are offered their own four anchors', () {
    final options = anchorOptionsFor(isAdultSelf: false);
    expect(options, [
      TrainingAnchor.wakeUp,
      TrainingAnchor.afterSchool,
      TrainingAnchor.afterDinner,
      TrainingAnchor.fixedTime,
    ]);
  });

  test('only adults get a recommendation (A2)', () {
    expect(recommendedAnchorFor(isAdultSelf: true), TrainingAnchor.wakeUp);
    expect(recommendedAnchorFor(isAdultSelf: false), isNull);
  });

  test('every offered anchor proposes a time inside the day', () {
    for (final isAdult in [true, false]) {
      for (final anchor in anchorOptionsFor(isAdultSelf: isAdult)) {
        final minutes = defaultMinutesFor(anchor);
        expect(minutes, greaterThanOrEqualTo(0));
        expect(minutes, lessThan(24 * 60));
      }
    }
  });

  test('the proposed times follow the order of the day', () {
    expect(defaultMinutesFor(TrainingAnchor.wakeUp), 7 * 60);
    expect(defaultMinutesFor(TrainingAnchor.afterBreakfast), 8 * 60 + 30);
    expect(defaultMinutesFor(TrainingAnchor.midday), 12 * 60 + 30);
    expect(defaultMinutesFor(TrainingAnchor.afterSchool), 15 * 60 + 30);
    expect(defaultMinutesFor(TrainingAnchor.afterDinner), 18 * 60 + 30);
    expect(defaultMinutesFor(TrainingAnchor.evening), 19 * 60);
  });

  test('the sleep hint belongs to the late anchors only', () {
    expect(showsEveningHint(TrainingAnchor.evening), isTrue);
    expect(showsEveningHint(TrainingAnchor.afterDinner), isTrue);
    expect(showsEveningHint(TrainingAnchor.wakeUp), isFalse);
    expect(showsEveningHint(TrainingAnchor.afterSchool), isFalse);
    expect(showsEveningHint(TrainingAnchor.fixedTime), isFalse);
  });

  test('unknown or missing names decode to null', () {
    expect(anchorFromName('wakeUp'), TrainingAnchor.wakeUp);
    expect(anchorFromName('nonsense'), isNull);
    expect(anchorFromName(null), isNull);
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/core/training/training_anchor_test.dart`
Expected: FAIL — `Target of URI doesn't exist`.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/training/training_anchor.dart

/// A fixed daily event the training is hooked onto.
///
/// The point of the feature is the anchor, not the clock: waking up happens
/// every day without having to be remembered, which is why it carries a habit
/// better than a time does. The clock time only exists because a reminder
/// needs one (spec §4.4).
enum TrainingAnchor {
  wakeUp,
  afterBreakfast,
  midday,
  evening,
  afterSchool,
  afterDinner,
  fixedTime,
}

/// Which anchors are offered, in display order.
///
/// Families get a different list on purpose (founder decision A2): the school
/// morning is the one slot they cannot reliably deliver.
List<TrainingAnchor> anchorOptionsFor({required bool isAdultSelf}) {
  if (isAdultSelf) {
    return const [
      TrainingAnchor.wakeUp,
      TrainingAnchor.afterBreakfast,
      TrainingAnchor.midday,
      TrainingAnchor.evening,
    ];
  }
  return const [
    TrainingAnchor.wakeUp,
    TrainingAnchor.afterSchool,
    TrainingAnchor.afterDinner,
    TrainingAnchor.fixedTime,
  ];
}

/// The anchor marked as recommended, or null when none is.
///
/// Only adults training for themselves get one. For families the founder
/// deliberately chose to offer the choice without a suggestion — the app does
/// not know their day well enough to recommend one.
TrainingAnchor? recommendedAnchorFor({required bool isAdultSelf}) =>
    isAdultSelf ? TrainingAnchor.wakeUp : null;

/// Proposed reminder time as minutes since midnight. Adjustable by the user.
int defaultMinutesFor(TrainingAnchor anchor) {
  return switch (anchor) {
    TrainingAnchor.wakeUp => 7 * 60,
    TrainingAnchor.afterBreakfast => 8 * 60 + 30,
    TrainingAnchor.midday => 12 * 60 + 30,
    TrainingAnchor.afterSchool => 15 * 60 + 30,
    TrainingAnchor.afterDinner => 18 * 60 + 30,
    TrainingAnchor.evening => 19 * 60,
    TrainingAnchor.fixedTime => 17 * 60,
  };
}

/// Whether to show the falling-asleep hint (spec §4.5).
///
/// Only for anchors that sit close to bedtime. It is an observation, never a
/// claim about how the exercises work.
bool showsEveningHint(TrainingAnchor anchor) =>
    anchor == TrainingAnchor.evening || anchor == TrainingAnchor.afterDinner;

/// Decodes a stored name. Unknown values decode to null so a renamed or
/// removed anchor cannot crash the app.
TrainingAnchor? anchorFromName(String? name) {
  if (name == null) return null;
  for (final anchor in TrainingAnchor.values) {
    if (anchor.name == name) return anchor;
  }
  return null;
}
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `flutter test test/core/training/training_anchor_test.dart`
Expected: PASS, 7 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/core/training/training_anchor.dart test/core/training/training_anchor_test.dart
git commit -m "feat(reminders): anchor model, per-audience options and default times (Task 1)"
```

---

## Task 2: Persistence

**Files:**
- Create: `lib/core/training/training_anchor_settings.dart`
- Test: `test/core/training/training_anchor_settings_test.dart`

**Interfaces:**
- Consumes: `TrainingAnchor`, `anchorFromName` (Task 1)
- Produces: `class TrainingAnchorSettings` with statics
  - `TrainingAnchor? anchor(SharedPreferences prefs)`
  - `bool wasAsked(SharedPreferences prefs)`
  - `Future<void> setAnchor(SharedPreferences prefs, TrainingAnchor anchor)`
  - `Future<void> markAsked(SharedPreferences prefs)`
  - `bool shouldAsk(SharedPreferences prefs)` — true when not yet asked and exactly one completed session

Follows `lib/core/training/routine_tip_settings.dart` exactly — same file, same shape, same style.

- [ ] **Step 1: Write the failing test**

```dart
// test/core/training/training_anchor_settings_test.dart
import 'package:corejourney/core/training/training_anchor.dart';
import 'package:corejourney/core/training/training_anchor_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  test('nothing is stored before the question is answered', () {
    expect(TrainingAnchorSettings.anchor(prefs), isNull);
    expect(TrainingAnchorSettings.wasAsked(prefs), isFalse);
  });

  test('a stored anchor survives a reload', () async {
    await TrainingAnchorSettings.setAnchor(prefs, TrainingAnchor.afterSchool);
    expect(TrainingAnchorSettings.anchor(prefs), TrainingAnchor.afterSchool);
  });

  test('asks after exactly one completed session', () async {
    await prefs.setInt('completed_session_count', 1);
    expect(TrainingAnchorSettings.shouldAsk(prefs), isTrue);
  });

  test('does not ask before the first session', () async {
    await prefs.setInt('completed_session_count', 0);
    expect(TrainingAnchorSettings.shouldAsk(prefs), isFalse);
  });

  test('does not ask again once the question was put', () async {
    await prefs.setInt('completed_session_count', 1);
    await TrainingAnchorSettings.markAsked(prefs);
    expect(TrainingAnchorSettings.shouldAsk(prefs), isFalse);
  });

  test('a missed moment is not made up later', () async {
    // Someone who trained twice before this shipped is not asked at all —
    // the question belongs to the moment right after the first session.
    await prefs.setInt('completed_session_count', 5);
    expect(TrainingAnchorSettings.shouldAsk(prefs), isFalse);
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/core/training/training_anchor_settings_test.dart`
Expected: FAIL — `TrainingAnchorSettings` is undefined.

- [ ] **Step 3: Write the implementation**

```dart
// lib/core/training/training_anchor_settings.dart
import 'package:shared_preferences/shared_preferences.dart';

import 'training_anchor.dart';

/// Stores the chosen training anchor and whether the question was already put.
///
/// Shaped after [RoutineTipSettings] and reading the same session counter, so
/// both one-time prompts key off one number.
class TrainingAnchorSettings {
  static const _keyAnchor = 'training_anchor';
  static const _keyAsked = 'training_anchor_asked';

  /// Written by RoutineTipSettings.incrementSessionCount after each completed
  /// session. Vorrunde units do not increment it, so they do not trigger the
  /// question either.
  static const _keySessionCount = 'completed_session_count';

  static TrainingAnchor? anchor(SharedPreferences prefs) =>
      anchorFromName(prefs.getString(_keyAnchor));

  static bool wasAsked(SharedPreferences prefs) =>
      prefs.getBool(_keyAsked) ?? false;

  static Future<void> setAnchor(
    SharedPreferences prefs,
    TrainingAnchor anchor,
  ) =>
      prefs.setString(_keyAnchor, anchor.name);

  static Future<void> markAsked(SharedPreferences prefs) =>
      prefs.setBool(_keyAsked, true);

  /// Exactly one session, not "at least one": the question belongs to the
  /// moment right after the first training. Someone who is already past that
  /// is not asked retroactively.
  static bool shouldAsk(SharedPreferences prefs) =>
      !wasAsked(prefs) && (prefs.getInt(_keySessionCount) ?? 0) == 1;
}
```

- [ ] **Step 4: Run the test and confirm it passes**

Run: `flutter test test/core/training/training_anchor_settings_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/core/training/training_anchor_settings.dart test/core/training/training_anchor_settings_test.dart
git commit -m "feat(reminders): store the chosen anchor and the asked flag (Task 2)"
```

---

## Task 3: Strings and the sheet

**Files:**
- Modify: `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb`
- Create: `lib/features/training/presentation/widgets/training_anchor_sheet.dart`
- Test: `test/features/training/presentation/training_anchor_sheet_test.dart`

**Interfaces:**
- Consumes: Task 1 and Task 2
- Produces:
  - `String trainingAnchorLabel(AppLocalizations l10n, TrainingAnchor anchor)`
  - `class TrainingAnchorResult { final TrainingAnchor anchor; final int minutes; }`
  - `Future<TrainingAnchorResult?> showTrainingAnchorSheet(BuildContext context, {required bool isAdultSelf})` — null when the user taps "Später"

Spec reference: §4.2, §4.3, §4.5.

- [ ] **Step 1: Add the strings to both catalogs**

In `lib/l10n/app_de.arb`:

```json
  "trainingAnchorTitle": "Wann sollen wir dich erinnern?",
  "@trainingAnchorTitle": { "description": "Anchor sheet title" },
  "trainingAnchorBody": "Am verlässlichsten läuft es, wenn das Training einen festen Platz im Tag hat.",
  "@trainingAnchorBody": { "description": "Anchor sheet body" },
  "trainingAnchorRecommended": "Empfohlen",
  "@trainingAnchorRecommended": { "description": "Badge on the recommended anchor" },
  "trainingAnchorLater": "Später",
  "@trainingAnchorLater": { "description": "Dismiss the anchor sheet" },
  "trainingAnchorConfirm": "Erinnern",
  "@trainingAnchorConfirm": { "description": "Confirm the anchor sheet" },
  "trainingAnchorTimeLabel": "Erinnerung um",
  "@trainingAnchorTimeLabel": { "description": "Label above the adjustable time" },
  "trainingAnchorEveningHint": "Vielen fällt das Einschlafen nach den Übungen schwerer. Plane etwas Abstand zum Zubettgehen ein.",
  "@trainingAnchorEveningHint": { "description": "Shown for late anchors only" },
  "trainingAnchorSettingsLabel": "Trainingszeitpunkt",
  "@trainingAnchorSettingsLabel": { "description": "Settings row label" },
  "trainingAnchorWakeUpAdult": "Direkt nach dem Aufwachen",
  "@trainingAnchorWakeUpAdult": { "description": "Anchor: on waking, adult wording" },
  "trainingAnchorWakeUpAdultDetail": "geht im Liegen",
  "@trainingAnchorWakeUpAdultDetail": { "description": "Subline for the adult wake-up anchor" },
  "trainingAnchorWakeUpChild": "Morgens nach dem Aufwachen",
  "@trainingAnchorWakeUpChild": { "description": "Anchor: on waking, family wording" },
  "trainingAnchorAfterBreakfast": "Nach dem Frühstück",
  "@trainingAnchorAfterBreakfast": { "description": "Anchor: after breakfast" },
  "trainingAnchorMidday": "Mittags oder in einer Pause",
  "@trainingAnchorMidday": { "description": "Anchor: midday" },
  "trainingAnchorEvening": "Am Abend",
  "@trainingAnchorEvening": { "description": "Anchor: evening" },
  "trainingAnchorAfterSchool": "Nach Kita oder Schule",
  "@trainingAnchorAfterSchool": { "description": "Anchor: after nursery or school" },
  "trainingAnchorAfterDinner": "Nach dem Abendessen",
  "@trainingAnchorAfterDinner": { "description": "Anchor: after dinner" },
  "trainingAnchorFixedTime": "Zu einer festen Uhrzeit",
  "@trainingAnchorFixedTime": { "description": "Anchor: a fixed clock time" }
```

In `lib/l10n/app_en.arb`, the same keys with:

```json
  "trainingAnchorTitle": "When should we remind you?",
  "trainingAnchorBody": "It works most reliably when the training has a fixed place in the day.",
  "trainingAnchorRecommended": "Recommended",
  "trainingAnchorLater": "Later",
  "trainingAnchorConfirm": "Remind me",
  "trainingAnchorTimeLabel": "Remind me at",
  "trainingAnchorEveningHint": "Many find it harder to fall asleep after the exercises. Leave some room before bedtime.",
  "trainingAnchorSettingsLabel": "Training time",
  "trainingAnchorWakeUpAdult": "Right after waking",
  "trainingAnchorWakeUpAdultDetail": "works lying down",
  "trainingAnchorWakeUpChild": "In the morning after waking",
  "trainingAnchorAfterBreakfast": "After breakfast",
  "trainingAnchorMidday": "Midday or during a break",
  "trainingAnchorEvening": "In the evening",
  "trainingAnchorAfterSchool": "After nursery or school",
  "trainingAnchorAfterDinner": "After dinner",
  "trainingAnchorFixedTime": "At a fixed time"
```

Then run: `flutter gen-l10n && make i18n-check`
Expected: both scripts report "passed".

- [ ] **Step 2: Write the failing test**

```dart
// test/features/training/presentation/training_anchor_sheet_test.dart
import 'package:corejourney/core/training/training_anchor.dart';
import 'package:corejourney/features/training/presentation/widgets/training_anchor_sheet.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:corejourney/l10n/app_localizations_de.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({required bool isAdultSelf, required void Function(TrainingAnchorResult?) onDone}) {
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            onDone(await showTrainingAnchorSheet(context, isAdultSelf: isAdultSelf));
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  final de = AppLocalizationsDe();

  testWidgets('adults see the recommendation badge', (tester) async {
    await tester.pumpWidget(_harness(isAdultSelf: true, onDone: (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(de.trainingAnchorWakeUpAdult), findsOneWidget);
    expect(find.text(de.trainingAnchorRecommended), findsOneWidget);
    expect(find.text(de.trainingAnchorAfterSchool), findsNothing);
  });

  testWidgets('families see their own options and no recommendation',
      (tester) async {
    await tester.pumpWidget(_harness(isAdultSelf: false, onDone: (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(de.trainingAnchorWakeUpChild), findsOneWidget);
    expect(find.text(de.trainingAnchorAfterSchool), findsOneWidget);
    expect(find.text(de.trainingAnchorRecommended), findsNothing);
  });

  testWidgets('the sleep hint appears only for a late anchor', (tester) async {
    await tester.pumpWidget(_harness(isAdultSelf: false, onDone: (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text(de.trainingAnchorEveningHint), findsNothing);

    await tester.tap(find.text(de.trainingAnchorAfterDinner));
    await tester.pumpAndSettle();
    expect(find.text(de.trainingAnchorEveningHint), findsOneWidget);

    await tester.tap(find.text(de.trainingAnchorWakeUpChild));
    await tester.pumpAndSettle();
    expect(find.text(de.trainingAnchorEveningHint), findsNothing);
  });

  testWidgets('later returns nothing', (tester) async {
    TrainingAnchorResult? result;
    var called = false;
    await tester.pumpWidget(_harness(
      isAdultSelf: true,
      onDone: (value) {
        result = value;
        called = true;
      },
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(de.trainingAnchorLater));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(result, isNull);
  });

  testWidgets('confirming returns the anchor and its proposed time',
      (tester) async {
    TrainingAnchorResult? result;
    await tester.pumpWidget(
      _harness(isAdultSelf: true, onDone: (value) => result = value),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(de.trainingAnchorMidday));
    await tester.pumpAndSettle();
    await tester.tap(find.text(de.trainingAnchorConfirm));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.anchor, TrainingAnchor.midday);
    expect(result!.minutes, defaultMinutesFor(TrainingAnchor.midday));
  });
}
```

- [ ] **Step 3: Run the test and confirm it fails**

Run: `flutter test test/features/training/presentation/training_anchor_sheet_test.dart`
Expected: FAIL — `showTrainingAnchorSheet` is undefined.

- [ ] **Step 4: Write the sheet**

```dart
// lib/features/training/presentation/widgets/training_anchor_sheet.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/training/training_anchor.dart';
import '../../../../l10n/app_localizations.dart';

/// Localised label for one anchor. The wake-up anchor reads differently for
/// families than for an adult training alone.
String trainingAnchorLabel(
  AppLocalizations l10n,
  TrainingAnchor anchor, {
  bool isAdultSelf = true,
}) {
  return switch (anchor) {
    TrainingAnchor.wakeUp =>
      isAdultSelf ? l10n.trainingAnchorWakeUpAdult : l10n.trainingAnchorWakeUpChild,
    TrainingAnchor.afterBreakfast => l10n.trainingAnchorAfterBreakfast,
    TrainingAnchor.midday => l10n.trainingAnchorMidday,
    TrainingAnchor.evening => l10n.trainingAnchorEvening,
    TrainingAnchor.afterSchool => l10n.trainingAnchorAfterSchool,
    TrainingAnchor.afterDinner => l10n.trainingAnchorAfterDinner,
    TrainingAnchor.fixedTime => l10n.trainingAnchorFixedTime,
  };
}

/// What the user chose: the anchor plus the reminder time for it.
class TrainingAnchorResult {
  const TrainingAnchorResult({required this.anchor, required this.minutes});

  final TrainingAnchor anchor;
  final int minutes;
}

/// Asks once when to remind. Returns null when the user taps "Später".
Future<TrainingAnchorResult?> showTrainingAnchorSheet(
  BuildContext context, {
  required bool isAdultSelf,
}) {
  return showModalBottomSheet<TrainingAnchorResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceDark,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _TrainingAnchorSheet(isAdultSelf: isAdultSelf),
  );
}

class _TrainingAnchorSheet extends StatefulWidget {
  const _TrainingAnchorSheet({required this.isAdultSelf});

  final bool isAdultSelf;

  @override
  State<_TrainingAnchorSheet> createState() => _TrainingAnchorSheetState();
}

class _TrainingAnchorSheetState extends State<_TrainingAnchorSheet> {
  TrainingAnchor? _selected;
  int? _minutes;

  void _select(TrainingAnchor anchor) {
    setState(() {
      // Picking a different anchor proposes that anchor's time. Picking the
      // same one again leaves a time the user already adjusted alone.
      if (_selected != anchor) {
        _minutes = defaultMinutesFor(anchor);
      }
      _selected = anchor;
    });
  }

  Future<void> _pickTime() async {
    final current = _minutes ?? defaultMinutesFor(_selected!);
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
    );
    if (picked != null) {
      setState(() => _minutes = picked.hour * 60 + picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final options = anchorOptionsFor(isAdultSelf: widget.isAdultSelf);
    final recommended = recommendedAnchorFor(isAdultSelf: widget.isAdultSelf);
    final selected = _selected;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.trainingAnchorTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.trainingAnchorBody,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
            ),
            const SizedBox(height: 16),
            for (final anchor in options)
              RadioListTile<TrainingAnchor>(
                contentPadding: EdgeInsets.zero,
                value: anchor,
                groupValue: selected,
                onChanged: (value) => _select(value!),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        trainingAnchorLabel(
                          l10n,
                          anchor,
                          isAdultSelf: widget.isAdultSelf,
                        ),
                      ),
                    ),
                    if (anchor == recommended) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.trainingAnchorRecommended,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: anchor == TrainingAnchor.wakeUp && widget.isAdultSelf
                    ? Text(l10n.trainingAnchorWakeUpAdultDetail)
                    : null,
              ),
            if (selected != null && showsEveningHint(selected)) ...[
              const SizedBox(height: 4),
              Text(
                l10n.trainingAnchorEveningHint,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant, height: 1.4),
              ),
            ],
            if (selected != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickTime,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Text(l10n.trainingAnchorTimeLabel),
                      const Spacer(),
                      Text(
                        TimeOfDay(
                          hour: (_minutes ?? defaultMinutesFor(selected)) ~/ 60,
                          minute:
                              (_minutes ?? defaultMinutesFor(selected)) % 60,
                        ).format(context),
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Icon(Icons.edit_outlined, size: 18),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.trainingAnchorLater),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: selected == null
                      ? null
                      : () => Navigator.pop(
                            context,
                            TrainingAnchorResult(
                              anchor: selected,
                              minutes:
                                  _minutes ?? defaultMinutesFor(selected),
                            ),
                          ),
                  child: Text(l10n.trainingAnchorConfirm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Run the tests and confirm they pass**

Run: `flutter test test/features/training/presentation/training_anchor_sheet_test.dart`
Expected: PASS, 5 tests.

- [ ] **Step 6: Commit**

```bash
git add lib/features/training/presentation/widgets/training_anchor_sheet.dart lib/l10n/ test/features/training/presentation/training_anchor_sheet_test.dart
git commit -m "feat(reminders): the anchor sheet and its copy (Task 3)"
```

---

## Task 4: Apply the answer

**Files:**
- Create: `lib/features/training/presentation/apply_training_anchor.dart`
- Test: `test/features/training/presentation/apply_training_anchor_test.dart`

**Interfaces:**
- Consumes: `TrainingAnchorResult` (Task 3), `TrainingAnchorSettings` (Task 2), `settingsProvider`
- Produces: `Future<void> applyTrainingAnchor(WidgetRef ref, TrainingAnchorResult result)`

Spec reference: §4.6.

- [ ] **Step 1: Write the failing test**

```dart
// test/features/training/presentation/apply_training_anchor_test.dart
import 'package:corejourney/core/settings/settings_provider.dart';
import 'package:corejourney/core/training/training_anchor.dart';
import 'package:corejourney/core/training/training_anchor_settings.dart';
import 'package:corejourney/features/training/presentation/apply_training_anchor.dart';
import 'package:corejourney/features/training/presentation/widgets/training_anchor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('applying an answer switches reminders on and sets the time',
      (tester) async {
    late WidgetRef captured;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) {
              captured = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await applyTrainingAnchor(
      captured,
      const TrainingAnchorResult(
        anchor: TrainingAnchor.afterSchool,
        minutes: 15 * 60 + 30,
      ),
    );

    final settings = captured.read(settingsProvider);
    expect(settings.remindersEnabled, isTrue);
    expect(settings.reminderStartMinutes, 15 * 60 + 30);

    final prefs = await SharedPreferences.getInstance();
    expect(TrainingAnchorSettings.anchor(prefs), TrainingAnchor.afterSchool);
    expect(TrainingAnchorSettings.wasAsked(prefs), isTrue);
  });
}
```

- [ ] **Step 2: Run the test and confirm it fails**

Run: `flutter test test/features/training/presentation/apply_training_anchor_test.dart`
Expected: FAIL — `applyTrainingAnchor` is undefined.

- [ ] **Step 3: Write the implementation**

```dart
// lib/features/training/presentation/apply_training_anchor.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/settings_provider.dart';
import '../../../core/training/training_anchor_settings.dart';
import 'widgets/training_anchor_sheet.dart';

/// Stores the answer and switches reminders on (spec §4.6).
///
/// No notification code here: setting remindersEnabled and the window start
/// makes the existing reminder sync schedule both the training reminder and
/// the streak evening notice.
Future<void> applyTrainingAnchor(
  WidgetRef ref,
  TrainingAnchorResult result,
) async {
  final prefs = await SharedPreferences.getInstance();
  await TrainingAnchorSettings.setAnchor(prefs, result.anchor);
  await TrainingAnchorSettings.markAsked(prefs);

  final notifier = ref.read(settingsProvider.notifier);
  notifier.setReminderStart(
    TimeOfDay(hour: result.minutes ~/ 60, minute: result.minutes % 60),
  );
  notifier.setRemindersEnabled(true);
}
```

Both setters are verified against `lib/core/settings/settings_provider.dart`:
`void setRemindersEnabled(bool)` at line 202 and `void setReminderStart(TimeOfDay)`
at line 207. Neither returns a Future, so neither is awaited.

- [ ] **Step 4: Run the test and confirm it passes**

Run: `flutter test test/features/training/presentation/apply_training_anchor_test.dart`
Expected: PASS, 1 test.

- [ ] **Step 5: Commit**

```bash
git add lib/features/training/presentation/apply_training_anchor.dart test/features/training/presentation/apply_training_anchor_test.dart
git commit -m "feat(reminders): apply the chosen anchor to the reminder settings (Task 4)"
```

---

## Task 5: Ask after the first training

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart:106-125`

Spec reference: §4.1.

- [ ] **Step 1: Extend the existing post-frame check**

`_checkRoutineTip` becomes `_checkOneTimePrompts`, keeping the existing
`addPostFrameCallback` registration:

```dart
  Future<void> _checkOneTimePrompts() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    // At most one sheet per return. The anchor question comes first because it
    // belongs to the moment right after the first session; the routine tip
    // only becomes due from the second session on, so in practice they never
    // compete — the guard is here so a future change cannot stack them.
    if (TrainingAnchorSettings.shouldAsk(prefs)) {
      await TrainingAnchorSettings.markAsked(prefs);
      if (!mounted) return;
      await _askTrainingAnchor();
      return;
    }

    if (RoutineTipSettings.shouldShowTip(prefs)) {
      await RoutineTipSettings.markTipShown(prefs);
      if (!mounted) return;
      _showRoutineTip();
    }
  }

  Future<void> _askTrainingAnchor() async {
    final profile = ref.read(selectedSubjectProfileProvider);
    final result = await showTrainingAnchorSheet(
      context,
      isAdultSelf: profile?.profileType == 'adult_self',
    );
    if (result == null || !mounted) return;
    await applyTrainingAnchor(ref, result);
  }
```

Note that `markAsked` runs **before** the sheet opens, matching how
`markTipShown` works: a one-time prompt that crashes or is dismissed by a back
gesture must not come back.

Add the imports for `TrainingAnchorSettings`, `showTrainingAnchorSheet` and
`applyTrainingAnchor`, and rename the call in `initState`.

- [ ] **Step 2: Verify by hand on the simulator**

Run: `make run-sim`

Fresh install, complete one training, return to the dashboard: the sheet
appears. Tap "Später": it does not come back on the next return. Reinstall,
complete one training, choose an anchor: the reminder settings show the chosen
time and the switch is on.

- [ ] **Step 3: Run the gate**

Run: `make release-readiness-mobile`
Expected: all green.

- [ ] **Step 4: Capture evidence**

Screenshots of the sheet in both variants (adult with the badge, family
without) under `docs/evidence/trainingszeitpunkt/`, following the pattern in
`test/evidence/adult_reflexprofil_evidence_test.dart`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/screens/dashboard_screen.dart docs/evidence/trainingszeitpunkt/ test/evidence/
git commit -m "feat(reminders): ask for the anchor after the first training (Task 5)"
```

---

## Task 6: Change it later in the settings

**Files:**
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart:138-156`

Spec reference: §5.

- [ ] **Step 1: Add the anchor row**

Inside the existing `if (settings.remindersEnabled) ...[` block, above the two
`_TimePickerTile`s:

```dart
            Consumer(
              builder: (context, ref, _) {
                final prefs = ref.watch(sharedPreferencesProvider);
                final anchor = TrainingAnchorSettings.anchor(prefs);
                final profile = ref.watch(selectedSubjectProfileProvider);
                final isAdultSelf = profile?.profileType == 'adult_self';
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  title: Text(l10n.trainingAnchorSettingsLabel),
                  subtitle: anchor == null
                      ? null
                      : Text(trainingAnchorLabel(l10n, anchor,
                          isAdultSelf: isAdultSelf)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final result = await showTrainingAnchorSheet(
                      context,
                      isAdultSelf: isAdultSelf,
                    );
                    if (result == null) return;
                    // Spec §5: changing the anchor keeps a time the user has
                    // already adjusted — only the anchor is rewritten.
                    final prefs = await SharedPreferences.getInstance();
                    await TrainingAnchorSettings.setAnchor(
                        prefs, result.anchor);
                  },
                );
              },
            ),
```

`sharedPreferencesProvider` exists in `lib/core/settings/settings_provider.dart`
(line 94) — import it from there, not from `lib/bootstrap/providers.dart`.

- [ ] **Step 2: Run the gate**

Run: `make release-readiness-mobile`
Expected: all green.

- [ ] **Step 3: Commit**

```bash
git add lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat(reminders): change the training anchor from the settings (Task 6)"
```

---

## Spec coverage

| Spec section | Task |
|---|---|
| §4.1 trigger, one sheet per return | 5 |
| §4.2 the sheet | 3 |
| §4.3 options per audience, A2 | 1, 3 |
| §4.4 anchor vs clock time | 1, 3 |
| §4.5 sleep hint | 1, 3 |
| §4.6 what the answer does, A4 | 4 |
| §5 change it later | 6 |
| §6 medication stays out, A1 | nothing to build — enforced by the global constraints |
| §7 non-goals | nothing to build |
