# Phase 1 — Unified Assessment View & Trainer Navigation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify the assessment result screen so trainer and user see the same view, rename "Relevante Angaben" → "Ergänzende Angaben", strip chips from the answers display, and replace the trainer's inline score card with a tappable profile row.

**Architecture:** Three files touched. Helper filter tightened (selectedIds removed). Result screen heading renamed and chip block deleted. Trainer client detail screen gets a new `_TappableProfileRow` widget in place of `_SharedReflexProfileCard` and `_SharedProfileHeader`; all duplicate trainer assessment code deleted.

**Tech Stack:** Flutter/Dart 3, Riverpod, go_router, intl

---

## File map

| File | Change |
|---|---|
| `lib/features/assessment/presentation/screens/reflex_profile_result_helpers.dart` | Remove selectedIds filter branch, always pass `selectedOptionLabels: const []` |
| `lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart` | Rename heading; remove chip rendering from `_RelevantAnswerCard` |
| `lib/features/trainer/presentation/screens/trainer_client_detail_screen.dart` | Add `_TappableProfileRow` + band helpers; replace build section; delete ~330 lines of dead code; remove one import |
| `test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart` | Update 5 tests that relied on selectedIds-only items being included |

---

## Task 1: Update helper filter (TDD)

**Files:**
- Modify: `test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart`
- Modify: `lib/features/assessment/presentation/screens/reflex_profile_result_helpers.dart`

### Background

`buildRelevanteAngaben` currently includes an item if any of `selectedIds`, `freeText`, or `months` is present. The new rule: only `freeText` or `months`. Items with only `selected_options` are excluded. The `selectedOptionLabels` field on `RelevantAnswerItem` stays (no callers need updating) but is always empty.

Five existing tests rely on the old behaviour and need updating before touching the implementation.

- [ ] **Step 1: Update the five affected tests**

Open `test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart` and make these five changes:

**Test at line 36 — rename and invert:**
```dart
test('selected_options only (no text/months) is excluded', () {
  final result = buildRelevanteAngaben(_assessment({
    'q006': {
      'answer': 'yes',
      'selected_options': ['vacuum', 'forceps'],
    },
  }));
  expect(result, isEmpty);
});
```

**Test at line 89 — rename and invert:**
```dart
test('selected_options only with unknown option ID is excluded', () {
  final result = buildRelevanteAngaben(_assessment({
    'q006': {'selected_options': ['unknown_option_xyz']},
  }));
  expect(result, isEmpty);
});
```

**Test at line 96 — change `q006 selected_options` to `q009 text`:**
```dart
test('groups are ordered by module enum order regardless of answer insertion order', () {
  // q037 = motorSkills (enum index 2), q009 = pregnancyBirth (enum index 0)
  // Insert in reverse order to verify enum-order output
  final result = buildRelevanteAngaben(_assessment({
    'q037': {'months': 18},        // motorSkills
    'q009': {'text': 'Sturzgeburt'},  // pregnancyBirth
  }));
  expect(result.length, 2);
  expect(result[0].$1, ReflexQuestionModule.pregnancyBirth);
  expect(result[1].$1, ReflexQuestionModule.motorSkills);
});
```

**Test at line 108 — change `q006 selected_options` to `q006 text`:**
```dart
test('multiple answers in same module appear in the same group', () {
  // q006 and q009 are both pregnancyBirth
  final result = buildRelevanteAngaben(_assessment({
    'q006': {'text': 'Zange verwendet'},
    'q009': {'text': 'Sturzgeburt'},
  }));
  expect(result.length, 1);
  expect(result.first.$2.length, 2);
});
```

**Test at line 118 — change `q006 selected_options` to `q006 text`:**
```dart
test('items within a module group are sorted by question number', () {
  // q009 (number 9) and q006 (number 6) are both pregnancyBirth
  // Insert q009 first — output should still be q006 first (lower number)
  final result = buildRelevanteAngaben(_assessment({
    'q009': {'text': 'Sturzgeburt'},      // question number 9
    'q006': {'text': 'Zange verwendet'},  // question number 6
  }));
  expect(result.length, 1);
  final items = result.first.$2;
  expect(items.length, 2);
  expect(items[0].question.number, 6);
  expect(items[1].question.number, 9);
});
```

- [ ] **Step 2: Run tests to confirm they fail**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter test test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart --reporter=compact
```

Expected: 5 failures (the 5 tests we just changed now assert the opposite of what the current implementation does).

- [ ] **Step 3: Update the helper implementation**

Replace the entire body of `buildRelevanteAngaben` in `lib/features/assessment/presentation/screens/reflex_profile_result_helpers.dart`:

```dart
List<(ReflexQuestionModule, List<RelevantAnswerItem>)> buildRelevanteAngaben(
  ReflexProfileAssessment assessment,
) {
  final questionById = {
    for (final q in childParentQuestionnaireV1.questions) q.id: q,
  };

  final Map<ReflexQuestionModule, List<RelevantAnswerItem>> byModule = {};

  for (final entry in assessment.answers.entries) {
    final raw = entry.value;
    if (raw is! Map) continue;

    final question = questionById[entry.key];
    if (question == null) continue;

    final text = raw['text'] as String?;
    final months = (raw['months'] as num?)?.toInt();
    final trimmedText = text?.trim();
    final hasFreeText = trimmedText != null && trimmedText.isNotEmpty;

    if (!hasFreeText && months == null) continue;

    byModule.putIfAbsent(question.module, () => []).add(
          RelevantAnswerItem(
            question: question,
            selectedOptionLabels: const [],
            freeText: hasFreeText ? trimmedText : null,
            months: months,
          ),
        );
  }

  for (final list in byModule.values) {
    list.sort((a, b) => a.question.number.compareTo(b.question.number));
  }

  return [
    for (final module in ReflexQuestionModule.values)
      if (byModule.containsKey(module)) (module, byModule[module]!),
  ];
}
```

- [ ] **Step 4: Run tests to confirm they pass**

```bash
flutter test test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart --reporter=compact
```

Expected: all 12 tests pass.

- [ ] **Step 5: Analyzer check**

```bash
flutter analyze lib/features/assessment/presentation/screens/reflex_profile_result_helpers.dart
```

Expected: No issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/assessment/presentation/screens/reflex_profile_result_helpers.dart \
        test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart
git commit -m "refactor: strip selectedIds from Ergänzende Angaben filter"
```

---

## Task 2: Rename heading and remove chip rendering

**Files:**
- Modify: `lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart`

### Background

Two changes to this file:
1. The section heading on line 189 says `'Relevante Angaben'` — change to `'Ergänzende Angaben'`.
2. `_RelevantAnswerCard.build` (lines 517–598) renders chips when `hasChips` is true. Since the helper now always sets `selectedOptionLabels: const []`, `hasChips` is always false — delete the dead chip branch entirely and simplify the method.

- [ ] **Step 1: Rename the heading**

In `_ResultContent.build` at line 189, change:

```dart
'Relevante Angaben',
```

to:

```dart
'Ergänzende Angaben',
```

- [ ] **Step 2: Replace `_RelevantAnswerCard.build` with the simplified version**

Find `class _RelevantAnswerCard` (line 517) and replace its entire `build` method with:

```dart
@override
Widget build(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  final hasFreeText = item.freeText != null;
  final hasMonths = item.months != null;

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.question.text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          if (hasFreeText) ...[
            const SizedBox(height: 8),
            Text(
              '„${item.freeText}"',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: cs.onSurface.withValues(alpha: 0.70),
                    height: 1.45,
                  ),
            ),
          ],
          if (hasMonths) ...[
            SizedBox(height: hasFreeText ? 4 : 8),
            Text(
              '${item.months} Monate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
            ),
          ],
        ],
      ),
    ),
  );
}
```

The full `_RelevantAnswerCard` class after the change:

```dart
class _RelevantAnswerCard extends StatelessWidget {
  const _RelevantAnswerCard({required this.item});

  final RelevantAnswerItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasFreeText = item.freeText != null;
    final hasMonths = item.months != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.question.text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.4,
                  ),
            ),
            if (hasFreeText) ...[
              const SizedBox(height: 8),
              Text(
                '„${item.freeText}"',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: cs.onSurface.withValues(alpha: 0.70),
                      height: 1.45,
                    ),
              ),
            ],
            if (hasMonths) ...[
              SizedBox(height: hasFreeText ? 4 : 8),
              Text(
                '${item.months} Monate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Analyzer check**

```bash
flutter analyze lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart
```

Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart
git commit -m "feat: rename to Ergänzende Angaben, remove chip rendering"
```

---

## Task 3: Add `_TappableProfileRow` and update the trainer build section

**Files:**
- Modify: `lib/features/trainer/presentation/screens/trainer_client_detail_screen.dart`

### Background

Currently the `sharedProfiles` loop (lines 125–155) shows `_SharedProfileHeader` + `_SharedReflexProfileCard` inline. We replace that with `_TappableProfileRow` (a Card + InkWell that navigates to `Routes.reflexProfileResult` with `extra: {'assessment': assessment}`). `_ReflexProfileNotesCard` stays below each row.

Three things to do in this task: (a) add `_TappableProfileRow` widget class at the bottom of the file, (b) add three private band-helper functions, (c) update lines 125–155 in the build method.

- [ ] **Step 1: Add `_TappableProfileRow` and band helpers at the bottom of the file**

Append these classes and functions **before** the `_SharedProfileHeader` class (around line 773) — they will come right after the existing code and before `_SharedProfileHeader`. (In the next task, `_SharedProfileHeader` itself gets deleted.)

Actually, append them at the very bottom of the file, after `_SectionTitle`:

```dart
class _TappableProfileRow extends StatelessWidget {
  const _TappableProfileRow({
    required this.profile,
    required this.clientId,
  });

  final TrainerSharedProfile profile;
  final String clientId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final assessment = profile.latestAssessment!;

    final age = profile.ageYears != null
        ? '${profile.ageYears} Jahr${profile.ageYears == 1 ? '' : 'e'}'
        : (profile.ageGroup ?? '');
    final dateStr = DateFormat('dd.MM.yyyy', 'de_DE')
        .format(assessment.completedAt ?? assessment.createdAt);
    final metaStr = [if (age.isNotEmpty) age, dateStr].join(' · ');

    final topBand = _topScoredBand(assessment);
    final bandLabel = topBand != null ? _bandPillLabel(topBand) : null;
    final bandColor = topBand != null ? _bandPillColor(topBand, cs) : null;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          Routes.reflexProfileResult,
          extra: {'assessment': assessment},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: cs.primaryContainer,
                child: Text(
                  profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: cs.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.displayName,
                      style:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            metaStr,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                        if (bandLabel != null && bandColor != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: bandColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              bandLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: bandColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

ReflexScoreBand? _topScoredBand(ReflexProfileAssessment assessment) {
  ReflexScoreBand? worst;
  for (final raw in assessment.scores.values) {
    if (raw is! Map) continue;
    final band = ReflexScoreBand.values.firstWhere(
      (b) => b.name == (raw['band'] as String? ?? ''),
      orElse: () => ReflexScoreBand.insufficientData,
    );
    if (band == ReflexScoreBand.strong) return band;
    if (band == ReflexScoreBand.elevated) worst = band;
  }
  return worst;
}

String _bandPillLabel(ReflexScoreBand band) => switch (band) {
      ReflexScoreBand.strong => 'stark auffällig',
      ReflexScoreBand.elevated => 'auffällig',
      _ => '',
    };

Color _bandPillColor(ReflexScoreBand band, ColorScheme cs) => switch (band) {
      ReflexScoreBand.strong => AppColors.error,
      ReflexScoreBand.elevated => AppColors.warning,
      _ => cs.onSurface,
    };
```

- [ ] **Step 2: Update the `sharedProfiles` loop in the build method**

Find lines 125–155 (inside the `data: (sharedProfiles) =>` branch). Replace:

```dart
for (final profile in sharedProfiles) ...[
  _SharedProfileHeader(profile: profile),
  const SizedBox(height: 8),
  profile.latestAssessment == null
      ? Padding(
          padding: const EdgeInsets.only(
              left: 4, bottom: 16),
          child: Text(
            'Noch kein abgeschlossenes Reflexprofil.',
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant),
          ),
        )
      : Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _SharedReflexProfileCard(
                assessment:
                    profile.latestAssessment!),
            const SizedBox(height: 12),
            _ReflexProfileNotesCard(
              assessment: profile.latestAssessment!,
              ownerUserId: client.clientId,
            ),
            const SizedBox(height: 16),
          ],
        ),
],
```

with:

```dart
for (final profile in sharedProfiles) ...[
  profile.latestAssessment == null
      ? Padding(
          padding: const EdgeInsets.only(
              left: 4, bottom: 16),
          child: Text(
            '${profile.displayName}: Noch kein abgeschlossenes Reflexprofil.',
            style: TextStyle(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant),
          ),
        )
      : Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _TappableProfileRow(
              profile: profile,
              clientId: client.clientId,
            ),
            const SizedBox(height: 12),
            _ReflexProfileNotesCard(
              assessment: profile.latestAssessment!,
              ownerUserId: client.clientId,
            ),
            const SizedBox(height: 16),
          ],
        ),
],
```

- [ ] **Step 3: Analyzer check**

```bash
flutter analyze lib/features/trainer/presentation/screens/trainer_client_detail_screen.dart
```

Expected: No errors. There will be warnings about unused symbols (`_SharedReflexProfileCard`, `_SharedProfileHeader`, etc.) — those are expected and get cleaned up in Task 4.

- [ ] **Step 4: Commit**

```bash
git add lib/features/trainer/presentation/screens/trainer_client_detail_screen.dart
git commit -m "feat: replace inline assessment card with tappable profile row"
```

---

## Task 4: Delete dead trainer assessment code and clean up imports

**Files:**
- Modify: `lib/features/trainer/presentation/screens/trainer_client_detail_screen.dart`

### Background

After Task 3 removed all references to the old inline card, the following are now dead code. Delete them in one edit pass from bottom to top (so line numbers above don't shift):

Delete these symbols (find them by name — exact line numbers may shift slightly from the Task 3 edit):
- `_SharedProfileHeader` class (~line 773)
- `_trainerReflexLabel()` function (~line 755)
- `_trainerFormatAnswer()` function (~line 738)
- `_trainerBandColor()` function (~line 728)
- `_trainerScoreBandFromName()` function (~line 721)
- `_trainerSafetyRows()` function (~line 693)
- `_trainerScoreRows()` function (~line 676)
- `_TrainerScoreRow` class (~line 664)
- `_TrainerAnswerRow` class (~line 627)
- `_TrainerScoreBar` class (~line 588)
- `_SharedReflexProfileCard` class (~line 472)

Also remove the now-unused import on line 11:

```dart
import '../../../assessment/domain/reflex_questionnaire_definitions.dart';
```

This import was only needed for `childParentQuestionnaireV1` inside `_trainerSafetyRows`. After deleting that function, the import is unused. (The `reflex_questionnaire.dart` import on line 10 stays — it provides `ReflexScoreBand` and `ReflexProfileAssessment` used by `_TappableProfileRow`.)

- [ ] **Step 1: Delete `_SharedReflexProfileCard` class (lines ~472–587)**

The class starts with `class _SharedReflexProfileCard extends StatelessWidget {` and ends just before `class _TrainerScoreBar`. Delete the entire class body.

- [ ] **Step 2: Delete `_TrainerScoreBar`, `_TrainerAnswerRow`, `_TrainerScoreRow` classes (lines ~588–675)**

Three classes back to back. Delete all three.

- [ ] **Step 3: Delete `_trainerScoreRows`, `_trainerSafetyRows`, `_trainerScoreBandFromName`, `_trainerBandColor`, `_trainerFormatAnswer`, `_trainerReflexLabel` functions (lines ~676–772)**

Six top-level functions. Delete all six.

- [ ] **Step 4: Delete `_SharedProfileHeader` class (lines ~773–803)**

The class starts with `class _SharedProfileHeader extends StatelessWidget {` and ends just before `class _SectionTitle`. Delete it. `_SectionTitle` stays.

- [ ] **Step 5: Remove unused import**

Delete line 11:
```dart
import '../../../assessment/domain/reflex_questionnaire_definitions.dart';
```

- [ ] **Step 6: Analyzer check — must be clean**

```bash
flutter analyze lib/features/trainer/presentation/screens/trainer_client_detail_screen.dart
```

Expected: No issues at all (no warnings, no errors).

- [ ] **Step 7: Run all tests**

```bash
flutter test test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart --reporter=compact
```

Expected: 12 tests, all pass.

- [ ] **Step 8: Commit**

```bash
git add lib/features/trainer/presentation/screens/trainer_client_detail_screen.dart
git commit -m "refactor: delete duplicate trainer assessment widgets and unused import"
```

---

## Done

After Task 4, run a final analyzer sweep:

```bash
flutter analyze lib/features/assessment/presentation/screens/ lib/features/trainer/presentation/screens/trainer_client_detail_screen.dart
```

Expected: No issues.
