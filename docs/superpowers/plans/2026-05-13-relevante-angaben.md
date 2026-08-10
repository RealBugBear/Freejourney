# Relevante Angaben Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the raw "Antwortübersicht" expansion in the reflex profile result screen with a filtered, module-grouped "Relevante Angaben" section that shows only answers with chips, free text, or months — no more yes/no rows.

**Architecture:** Extract the pure data transformation logic (filter + group) into a testable helper file. The three new widgets (`_RelevanteAngaben`, `_ModuleGroup`, `_RelevantAnswerCard`) live in the existing screen file as private classes. The `ExpansionTile` is replaced with a plain always-visible section.

**Tech Stack:** Flutter/Dart 3, Material 3, `childParentQuestionnaireV1` from `reflex_questionnaire_definitions.dart`

---

## File Structure

| File | Action | Purpose |
|---|---|---|
| `lib/features/assessment/presentation/screens/reflex_profile_result_helpers.dart` | **Create** | Public `RelevantAnswerItem` data class + `buildRelevanteAngaben()` + `reflexModuleLabel()` |
| `lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart` | **Modify** | Add import, add 3 widgets, replace ExpansionTile, delete `_AnswerRow` + `_formatAnswer` |
| `test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart` | **Create** | Unit tests for the helper functions |

---

## Task 1: Helper file — data class, build function, module labels

**Spec:** Filter Rule, Grouping, Data classes, Helper function, `_moduleLabel` sections of the design spec.

**Files:**
- Create: `lib/features/assessment/presentation/screens/reflex_profile_result_helpers.dart`
- Create: `test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart`

---

- [ ] **Step 1: Write the failing tests**

Create `test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/assessment/domain/models/reflex_profile_assessment.dart';
import 'package:corejourney/features/assessment/domain/reflex_questionnaire.dart';
import 'package:corejourney/features/assessment/presentation/screens/reflex_profile_result_helpers.dart';

ReflexProfileAssessment _assessment(Map<String, dynamic> answers) =>
    ReflexProfileAssessment(
      id: 'test',
      questionnaireType: 'child_parent_report',
      questionnaireVersion: 'child_parent_v1_2026_05',
      scoringVersion: 'score_equal_weight_v1',
      status: 'completed',
      answers: answers,
      scores: const {},
      warningConfirmations: const [],
      safetyStatus: 'clear',
      createdAt: DateTime(2026, 5, 13),
    );

void main() {
  group('buildRelevanteAngaben', () {
    test('pure yes/no answer is excluded', () {
      final result = buildRelevanteAngaben(_assessment({
        'q001': {'answer': 'yes'},
      }));
      expect(result, isEmpty);
    });

    test('pure no answer is excluded', () {
      final result = buildRelevanteAngaben(_assessment({
        'q001': {'answer': 'no'},
      }));
      expect(result, isEmpty);
    });

    test('selected_options resolves option labels and includes item', () {
      // q006 = "Wurden Geburtshilfe-Instrumente eingesetzt?", pregnancyBirth
      // option ids: 'forceps' -> 'Geburtszange', 'vacuum' -> 'Saugglocke'
      final result = buildRelevanteAngaben(_assessment({
        'q006': {
          'answer': 'yes',
          'selected_options': ['vacuum', 'forceps'],
        },
      }));
      expect(result.length, 1);
      final (module, items) = result.first;
      expect(module, ReflexQuestionModule.pregnancyBirth);
      expect(items.length, 1);
      expect(items.first.selectedOptionLabels, ['Saugglocke', 'Geburtszange']);
      expect(items.first.freeText, isNull);
      expect(items.first.months, isNull);
    });

    test('free text is included and trimmed', () {
      // q009 = "Sonstiges zur Geburt", freeText, pregnancyBirth
      final result = buildRelevanteAngaben(_assessment({
        'q009': {'text': '  Nabelschnur zweimal gewickelt  '},
      }));
      expect(result.length, 1);
      expect(result.first.$2.first.freeText, 'Nabelschnur zweimal gewickelt');
      expect(result.first.$2.first.selectedOptionLabels, isEmpty);
    });

    test('blank free text is excluded', () {
      final result = buildRelevanteAngaben(_assessment({
        'q009': {'text': '   '},
      }));
      expect(result, isEmpty);
    });

    test('months value is included', () {
      // q037 = "Wann ist dein Kind das erste Mal gelaufen?", monthsNumber, motorSkills
      final result = buildRelevanteAngaben(_assessment({
        'q037': {'months': 18},
      }));
      expect(result.length, 1);
      final (module, items) = result.first;
      expect(module, ReflexQuestionModule.motorSkills);
      expect(items.first.months, 18);
    });

    test('unknown question ID is silently skipped', () {
      final result = buildRelevanteAngaben(_assessment({
        'q_nonexistent': {'selected_options': ['foo']},
      }));
      expect(result, isEmpty);
    });

    test('unknown option ID falls back to raw id as label', () {
      final result = buildRelevanteAngaben(_assessment({
        'q006': {'selected_options': ['unknown_option_xyz']},
      }));
      expect(result.first.$2.first.selectedOptionLabels, ['unknown_option_xyz']);
    });

    test('groups are ordered by module enum order regardless of answer insertion order', () {
      // q037 = motorSkills (enum index 2), q006 = pregnancyBirth (enum index 0)
      // Insert in reverse order to verify enum-order output
      final result = buildRelevanteAngaben(_assessment({
        'q037': {'months': 18},        // motorSkills
        'q006': {'selected_options': ['vacuum']},  // pregnancyBirth
      }));
      expect(result.length, 2);
      expect(result[0].$1, ReflexQuestionModule.pregnancyBirth);
      expect(result[1].$1, ReflexQuestionModule.motorSkills);
    });

    test('multiple answers in same module appear in the same group', () {
      // q006 and q009 are both pregnancyBirth
      final result = buildRelevanteAngaben(_assessment({
        'q006': {'selected_options': ['vacuum']},
        'q009': {'text': 'Sturzgeburt'},
      }));
      expect(result.length, 1);
      expect(result.first.$2.length, 2);
    });
  });

  group('reflexModuleLabel', () {
    test('returns correct German label for every module', () {
      expect(reflexModuleLabel(ReflexQuestionModule.pregnancyBirth),
          'Schwangerschaft & Geburt');
      expect(reflexModuleLabel(ReflexQuestionModule.posturePerception),
          'Haltung & Wahrnehmung');
      expect(reflexModuleLabel(ReflexQuestionModule.motorSkills), 'Motorik');
      expect(reflexModuleLabel(ReflexQuestionModule.behaviorEmotion),
          'Verhalten & Emotionen');
      expect(reflexModuleLabel(ReflexQuestionModule.speech), 'Sprache');
      expect(reflexModuleLabel(ReflexQuestionModule.drawingWriting),
          'Zeichnen & Schreiben');
      expect(reflexModuleLabel(ReflexQuestionModule.school),
          'Schule & Konzentration');
      expect(reflexModuleLabel(ReflexQuestionModule.other),
          'Weitere Beobachtungen');
    });
  });
}
```

- [ ] **Step 2: Run tests — confirm they fail**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter test test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart
```

Expected: compilation error — `reflex_profile_result_helpers.dart` not found.

- [ ] **Step 3: Create the helpers file**

Create `lib/features/assessment/presentation/screens/reflex_profile_result_helpers.dart`:

```dart
import '../../domain/models/reflex_profile_assessment.dart';
import '../../domain/reflex_questionnaire.dart';
import '../../domain/reflex_questionnaire_definitions.dart';

class RelevantAnswerItem {
  const RelevantAnswerItem({
    required this.question,
    required this.selectedOptionLabels,
    this.freeText,
    this.months,
  });

  final ReflexQuestion question;
  final List<String> selectedOptionLabels;
  final String? freeText;
  final int? months;
}

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

    final selectedIds =
        (raw['selected_options'] as List?)?.cast<String>() ?? const <String>[];
    final text = raw['text'] as String?;
    final months = raw['months'] as int?;
    final trimmedText = text?.trim();
    final hasFreeText = trimmedText != null && trimmedText.isNotEmpty;

    if (selectedIds.isEmpty && !hasFreeText && months == null) continue;

    final optionLabels = selectedIds.map((id) {
      return question.options
          .firstWhere(
            (o) => o.id == id,
            orElse: () => ReflexQuestionOption(id: id, label: id),
          )
          .label;
    }).toList();

    byModule.putIfAbsent(question.module, () => []).add(
          RelevantAnswerItem(
            question: question,
            selectedOptionLabels: optionLabels,
            freeText: hasFreeText ? trimmedText : null,
            months: months,
          ),
        );
  }

  return [
    for (final module in ReflexQuestionModule.values)
      if (byModule.containsKey(module)) (module, byModule[module]!),
  ];
}

String reflexModuleLabel(ReflexQuestionModule module) => switch (module) {
      ReflexQuestionModule.pregnancyBirth => 'Schwangerschaft & Geburt',
      ReflexQuestionModule.posturePerception => 'Haltung & Wahrnehmung',
      ReflexQuestionModule.motorSkills => 'Motorik',
      ReflexQuestionModule.behaviorEmotion => 'Verhalten & Emotionen',
      ReflexQuestionModule.speech => 'Sprache',
      ReflexQuestionModule.drawingWriting => 'Zeichnen & Schreiben',
      ReflexQuestionModule.school => 'Schule & Konzentration',
      ReflexQuestionModule.other => 'Weitere Beobachtungen',
    };
```

- [ ] **Step 4: Run tests — confirm they pass**

```bash
flutter test test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart
```

Expected output:
```
All tests passed!
```

All 10 tests should be green. If any fail, fix the helpers file before continuing.

- [ ] **Step 5: Run existing scoring test to confirm no regressions**

```bash
flutter test test/features/assessment/reflex_profile_scoring_test.dart
```

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
git add lib/features/assessment/presentation/screens/reflex_profile_result_helpers.dart \
        test/features/assessment/presentation/screens/reflex_profile_result_helpers_test.dart
git commit -m "feat: add buildRelevanteAngaben helper with unit tests"
```

---

## Task 2: Widgets + wire-up + delete old code

**Spec:** Widget Structure, Import Addition, Changes to `_ResultContent.build`, Removed sections of the design spec.

**Files:**
- Modify: `lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart`

---

- [ ] **Step 1: Add the import for helpers and questionnaire definitions**

In `lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart`, the current import block ends at line 13. Add two lines after the existing imports:

```dart
import '../../domain/reflex_questionnaire_definitions.dart';
import 'reflex_profile_result_helpers.dart';
```

The full import block should now be:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/reflex_profile_assessment.dart';
import '../../domain/reflex_questionnaire_definitions.dart';
import '../../domain/services/reflex_profile_pdf_service.dart';
import '../../domain/reflex_questionnaire.dart';
import '../providers/reflex_profile_provider.dart';
import '../widgets/reflex_radar_chart.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';
import 'reflex_profile_result_helpers.dart';
```

- [ ] **Step 2: Replace the ExpansionTile with the new section in `_ResultContent.build`**

Find this block (around line 187–199):

```dart
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(
            'Antwortübersicht',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          children: [
            for (final entry in assessment.answers.entries)
              _AnswerRow(questionId: entry.key, value: entry.value),
          ],
        ),
```

Replace it with:

```dart
        Text(
          'Relevante Angaben',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        _RelevanteAngaben(
          groups: buildRelevanteAngaben(assessment),
        ),
```

- [ ] **Step 3: Add the three new widget classes**

After the closing `}` of `_ScoreTile` (around line 455) and before the existing `_AnswerRow` class, insert the following three classes:

```dart
class _RelevanteAngaben extends StatelessWidget {
  const _RelevanteAngaben({required this.groups});

  final List<(ReflexQuestionModule, List<RelevantAnswerItem>)> groups;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Keine weiteren Angaben vorhanden.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups)
          _ModuleGroup(module: group.$1, items: group.$2),
      ],
    );
  }
}

class _ModuleGroup extends StatelessWidget {
  const _ModuleGroup({required this.module, required this.items});

  final ReflexQuestionModule module;
  final List<RelevantAnswerItem> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            reflexModuleLabel(module).toUpperCase(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.07 * 12,
                ),
          ),
        ),
        for (int i = 0; i < items.length; i++) ...[
          _RelevantAnswerCard(item: items[i]),
          if (i < items.length - 1) const SizedBox(height: 6),
        ],
        const SizedBox(height: 14),
      ],
    );
  }
}

class _RelevantAnswerCard extends StatelessWidget {
  const _RelevantAnswerCard({required this.item});

  final RelevantAnswerItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasChips = item.selectedOptionLabels.isNotEmpty;
    final hasFreeText = item.freeText != null;
    final hasMonths = item.months != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        children: [
          // Question text
          Text(
            item.question.text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.4,
                ),
          ),
          // Chips
          if (hasChips) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final label in item.selectedOptionLabels)
                  Chip(
                    label: Text(label),
                    backgroundColor: cs.primaryContainer,
                    labelStyle: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                  ),
              ],
            ),
          ],
          // Free text
          if (hasFreeText) ...[
            if (hasChips) ...[
              const SizedBox(height: 6),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 6),
            ] else
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
          // Months
          if (hasMonths) ...[
            if (hasChips) const SizedBox(height: 4) else const SizedBox(height: 8),
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
    );
  }
}
```

Note: `Card` uses `children` via a `Column` wrapping. The `Padding` widget wraps a `Column`:

```dart
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... all children as listed above
          ],
        ),
      ),
    );
```

(The `children:` property shorthand above is pseudo-code for clarity — make sure to use the proper `Column` wrapping in the actual code.)

- [ ] **Step 4: Delete `_AnswerRow` and `_formatAnswer`**

Remove the entire `_AnswerRow` class (lines ~457–493 in the original file):

```dart
class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.questionId,
    required this.value,
  });

  final String questionId;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

Remove the entire `_formatAnswer` function (lines ~591–606 in the original file):

```dart
String _formatAnswer(dynamic value) {
  // ...
}
```

- [ ] **Step 5: Run `flutter analyze` — confirm no errors**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart
```

Expected: `No issues found!`

If there are unused import warnings, remove the offending import. If there are type errors in the new widgets, fix them before continuing.

- [ ] **Step 6: Run all tests**

```bash
flutter test test/features/assessment/
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
git add lib/features/assessment/presentation/screens/reflex_profile_result_screen.dart
git commit -m "feat: replace Antwortübersicht with filtered Relevante Angaben section"
```

---

## Verification Checklist (manual, after both tasks)

Run `make run` or `make run-sim` and navigate to a completed reflex profile result screen.

- [ ] Title "Relevante Angaben" appears below the score tiles
- [ ] No yes/no-only rows are visible
- [ ] Module labels appear in green uppercase (e.g., "SCHWANGERSCHAFT & GEBURT")
- [ ] Selected options render as chips in `primaryContainer` color
- [ ] Free text renders in italic with quotation marks `„..."`
- [ ] Months render as bold text (e.g., "18 Monate")
- [ ] If an assessment has no rich answers: "Keine weiteren Angaben vorhanden." appears
- [ ] All other screen sections unchanged: radar, score tiles, warning card, trainer share card, PDF button, dashboard button
