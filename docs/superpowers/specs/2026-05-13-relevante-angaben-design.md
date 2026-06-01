# Relevante Angaben — Design Spec

## Goal

Replace the raw "Antwortübersicht" section in `ReflexProfileResultScreen` with a filtered, grouped, readable summary called "Relevante Angaben". Only answers with actual content (chips, free text, or numeric months) appear. Pure yes/no answers are hidden. Items are grouped by questionnaire module with German module labels.

---

## Scope

**Only changes:** the `ExpansionTile` block and the `_AnswerRow` widget inside `reflex_profile_result_screen.dart`.

**Unchanged:** radar, score tiles, warning card, trainer share card, PDF button, dashboard button — everything else stays exactly as is.

---

## Data Model

`ReflexProfileAssessment.answers` is `Map<String, dynamic>` keyed by question ID (e.g., `"q006"`). Each value is a Map with shape:

```dart
{
  'answer': 'yes' | 'no' | 'unknown',  // may be absent
  'selected_options': ['vacuum', 'forceps'],  // List<dynamic> or absent
  'text': 'Freitext...',  // String or absent
  'months': 18,  // int or absent
}
```

`childParentQuestionnaireV1.questions` (from `reflex_questionnaire_definitions.dart`) is the lookup source for:
- `ReflexQuestion.text` — human-readable question text
- `ReflexQuestion.module` — which `ReflexQuestionModule` it belongs to
- `ReflexQuestion.options` — `List<ReflexQuestionOption>` with `.id` and `.label`

---

## Filter Rule

An answer is **relevant** if at least one of:
- `selected_options` is a non-empty list
- `text` is a non-null, non-blank string
- `months` is a non-null integer

Pure yes/no/unknown answers (none of the above) are excluded.

---

## Grouping

Relevant items are grouped by `ReflexQuestion.module`. Groups are ordered by the natural `ReflexQuestionModule` enum order:

| Enum value | German display label |
|---|---|
| `pregnancyBirth` | Schwangerschaft & Geburt |
| `posturePerception` | Haltung & Wahrnehmung |
| `motorSkills` | Motorik |
| `behaviorEmotion` | Verhalten & Emotionen |
| `speech` | Sprache |
| `drawingWriting` | Zeichnen & Schreiben |
| `school` | Schule & Konzentration |
| `other` | Weitere Beobachtungen |

Modules with zero relevant answers are omitted entirely.

---

## Widget Structure

### Data classes (private to file)

```dart
class _RelevantItem {
  const _RelevantItem({
    required this.question,
    required this.selectedOptionLabels,
    this.freeText,
    this.months,
  });
  final ReflexQuestion question;
  final List<String> selectedOptionLabels;  // resolved labels, not IDs
  final String? freeText;
  final int? months;
}
```

### Helper function

```dart
List<(ReflexQuestionModule, List<_RelevantItem>)> _buildRelevanteAngaben(
  ReflexProfileAssessment assessment,
) {
  final questionById = {
    for (final q in childParentQuestionnaireV1.questions) q.id: q,
  };

  final Map<ReflexQuestionModule, List<_RelevantItem>> byModule = {};

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
          _RelevantItem(
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
```

### _RelevanteAngaben widget

Replaces the entire `ExpansionTile` in `_ResultContent.build`. Renders as a `Column` containing `_ModuleGroup` widgets, one per group.

If `groups` is empty (no relevant answers found), renders a centered muted text: _"Keine weiteren Angaben vorhanden."_

```dart
class _RelevanteAngaben extends StatelessWidget {
  const _RelevanteAngaben({required this.groups});
  final List<(ReflexQuestionModule, List<_RelevantItem>)> groups;
  // ...
}
```

### _ModuleGroup widget

```dart
class _ModuleGroup extends StatelessWidget {
  const _ModuleGroup({required this.module, required this.items});
  final ReflexQuestionModule module;
  final List<_RelevantItem> items;
}
```

Renders:
1. Module label row — `Text(_moduleLabel(module))` styled as:
   - `bodySmall`, `fontWeight: FontWeight.w700`, `color: cs.primary`, `letterSpacing: 0.07 * 14`, `textTransform` via `.toUpperCase()`, `margin-bottom: 6`
2. For each item: `_RelevantAnswerCard(item: item)` with `SizedBox(height: 6)` between cards
3. `SizedBox(height: 14)` after the last card in the group

### _RelevantAnswerCard widget

```dart
class _RelevantAnswerCard extends StatelessWidget {
  const _RelevantAnswerCard({required this.item});
  final _RelevantItem item;
}
```

Renders as a `Card` (uses app's default Card styling) with inner `Padding(padding: EdgeInsets.all(12))`:

1. **Question text**: `Text(item.question.text)` — `bodySmall`, color `cs.onSurfaceVariant`, `height: 1.4`, `margin-bottom: 8`
2. **Chips** (if `item.selectedOptionLabels.isNotEmpty`): `Wrap(spacing: 4, runSpacing: 4)` of `Chip` widgets:
   - Each `Chip` with `label: Text(label)`, `backgroundColor: cs.primaryContainer`, `labelStyle: TextStyle(color: cs.onPrimaryContainer, fontSize: 11, fontWeight: FontWeight.w600)`, `visualDensity: VisualDensity.compact`, `materialTapTargetSize: MaterialTapTargetSize.shrinkWrap`, `padding: EdgeInsets.symmetric(horizontal: 2)`
   - `margin-bottom: 6` after wrap if anything follows
3. **Free text** (if `item.freeText != null`):
   - Preceded by a `Divider(height: 1, thickness: 1)` and `SizedBox(height: 6)` only if chips were rendered above
   - `Text('„${item.freeText}"')` — `bodySmall`, `fontStyle: FontStyle.italic`, color `cs.onSurface.withValues(alpha: 0.70)`, `height: 1.45`
4. **Months** (if `item.months != null`):
   - `Text('${item.months} Monate')` — `bodySmall`, `fontWeight: FontWeight.w700`, color `cs.onSurface`

Months and free text may coexist on the same card (different questions). If both chips and freeText are present: chips → divider → freeText. If chips and months: chips → `SizedBox(height: 4)` → months. If only freeText (no chips): freeText directly. If only months: months directly.

### _moduleLabel helper

```dart
String _moduleLabel(ReflexQuestionModule module) => switch (module) {
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

---

## Import Addition

`reflex_profile_result_screen.dart` currently imports `reflex_questionnaire.dart` but not `reflex_questionnaire_definitions.dart`. Add:

```dart
import '../../domain/reflex_questionnaire_definitions.dart';
```

---

## Changes to _ResultContent.build

Replace lines ~187–199 (the ExpansionTile block):

**Before:**
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

**After:**
```dart
Text(
  'Relevante Angaben',
  style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
      ),
),
const SizedBox(height: 10),
_RelevanteAngaben(
  groups: _buildRelevanteAngaben(assessment),
),
```

Note: The ExpansionTile is removed entirely — "Relevante Angaben" is always visible, not collapsible. This matches the approved design (the expand/collapse interaction was part of the mockup framing, not a requested feature).

---

## Removed

- `_AnswerRow` class — deleted entirely
- `_formatAnswer` function — deleted entirely (no longer used)

---

## Testing Notes

- Questionnaire with no relevant answers → only the "Keine weiteren Angaben vorhanden." fallback text appears
- Question with only yes/no answer → not shown
- Question with `selected_options` only → chips, no divider or freeText row
- Question with `selected_options` + `text` → chips, then divider, then italic text
- Question with only `text` → no chips, italic text directly
- Question with `months` → bold months text (e.g., "18 Monate")
- Unknown question ID (not in `childParentQuestionnaireV1`) → silently skipped
- Unknown option ID → falls back to raw ID as label
- Module order follows `ReflexQuestionModule` enum order regardless of insertion order
