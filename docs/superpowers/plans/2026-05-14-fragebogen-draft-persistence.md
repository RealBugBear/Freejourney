# Fragebogen Draft-Persistenz Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fragebogen-Fortschritt bei App-Close, Hintergrund und Back-Button nie verlieren — per-Antwort lokal in SharedPreferences sichern, bei App-Pause zu Supabase syncen, beim Neustart neueren Stand laden.

**Architecture:** Neuer `DraftPersistenceService` (nur SharedPreferences, kein Riverpod) speichert den Draft nach jeder Antwort lokal. Der Screen erhält `WidgetsBindingObserver` für App-Pause → Supabase-Sync, Text-Debounce (300ms), `PopScope` mit Bestätigungsdialog, und eine erweiterte `_checkForDraft()` die lokal + Cloud vergleicht und den neueren Timestamp nimmt.

**Tech Stack:** Flutter, SharedPreferences (`^2.2.2`, bereits im Projekt), dart:async (Timer), bestehendes Supabase-Draft-System in `reflex_profile_provider.dart`.

---

## File Map

| Datei | Aktion | Verantwortlichkeit |
|---|---|---|
| `lib/features/assessment/domain/draft_persistence_service.dart` | **Neu** | SharedPreferences saveLocal / loadLocal / clearLocal |
| `test/features/assessment/domain/draft_persistence_service_test.dart` | **Neu** | Unit-Tests für den Service |
| `lib/features/assessment/presentation/screens/reflex_profile_screen.dart` | **Ändern** | WidgetsBindingObserver, _saveLocalDraft, Debounce, PopScope, _checkForDraft-Erweiterung |

---

## Task 1: DraftPersistenceService (TDD)

**Files:**
- Create: `lib/features/assessment/domain/draft_persistence_service.dart`
- Create: `test/features/assessment/domain/draft_persistence_service_test.dart`

- [ ] **Schritt 1: Test-Datei schreiben**

```dart
// test/features/assessment/domain/draft_persistence_service_test.dart
import 'package:corejourney/features/assessment/domain/draft_persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DraftPersistenceService service;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    service = DraftPersistenceService();
  });

  group('DraftPersistenceService', () {
    test('saveLocal + loadLocal round-trip preserves all fields', () async {
      final draft = {
        'saved_at': '2026-05-14T10:00:00.000Z',
        'answers': {
          '__meta': {'module_index': 2, 'questionnaire_for': 'child'},
          'q001': {'yesNoUnknown': true},
        },
        'warning_confirmations': <dynamic>[],
      };

      await service.saveLocal('profile-1', draft);
      final loaded = await service.loadLocal('profile-1');

      expect(loaded, equals(draft));
    });

    test('loadLocal returns null when nothing saved', () async {
      final result = await service.loadLocal('unknown-profile');
      expect(result, isNull);
    });

    test('clearLocal removes the draft', () async {
      await service.saveLocal('profile-1', {'saved_at': '2026-01-01T00:00:00Z'});
      await service.clearLocal('profile-1');
      final result = await service.loadLocal('profile-1');
      expect(result, isNull);
    });

    test('different profile IDs are stored independently', () async {
      await service.saveLocal('profile-a', {'saved_at': '2026-01-01T00:00:00Z', 'x': 1});
      await service.saveLocal('profile-b', {'saved_at': '2026-01-01T00:00:00Z', 'x': 2});

      final a = await service.loadLocal('profile-a');
      final b = await service.loadLocal('profile-b');

      expect(a!['x'], 1);
      expect(b!['x'], 2);
    });

    test('clearLocal only removes the targeted profile draft', () async {
      await service.saveLocal('profile-a', {'saved_at': '2026-01-01T00:00:00Z'});
      await service.saveLocal('profile-b', {'saved_at': '2026-01-01T00:00:00Z'});

      await service.clearLocal('profile-a');

      expect(await service.loadLocal('profile-a'), isNull);
      expect(await service.loadLocal('profile-b'), isNotNull);
    });

    test('loadLocal returns null and clears corrupt JSON', () async {
      SharedPreferences.setMockInitialValues({
        'reflex_draft_corrupt-profile': 'this is not valid json{{{',
      });
      final service2 = DraftPersistenceService();

      final result = await service2.loadLocal('corrupt-profile');
      expect(result, isNull);

      // Draft should be cleared after corrupt read
      final afterClear = await service2.loadLocal('corrupt-profile');
      expect(afterClear, isNull);
    });

    test('saveLocal is idempotent — overwrites previous draft', () async {
      await service.saveLocal('profile-1', {'saved_at': '2026-01-01T00:00:00Z', 'v': 1});
      await service.saveLocal('profile-1', {'saved_at': '2026-01-01T00:00:00Z', 'v': 2});

      final loaded = await service.loadLocal('profile-1');
      expect(loaded!['v'], 2);
    });
  });
}
```

- [ ] **Schritt 2: Tests fehlschlagen lassen**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter test test/features/assessment/domain/draft_persistence_service_test.dart
```

Erwartet: FEHLER — `draft_persistence_service.dart` existiert noch nicht.

- [ ] **Schritt 3: Service implementieren**

```dart
// lib/features/assessment/domain/draft_persistence_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DraftPersistenceService {
  static String _key(String profileId) => 'reflex_draft_$profileId';

  Future<void> saveLocal(String profileId, Map<String, dynamic> draftJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(profileId), jsonEncode(draftJson));
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> loadLocal(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(profileId));
      if (raw == null) return null;
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      await clearLocal(profileId);
      return null;
    }
  }

  Future<void> clearLocal(String profileId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(profileId));
    } catch (_) {}
  }
}
```

- [ ] **Schritt 4: Tests grün laufen lassen**

```bash
flutter test test/features/assessment/domain/draft_persistence_service_test.dart
```

Erwartet: Alle 7 Tests PASS.

- [ ] **Schritt 5: Commit**

```bash
git add lib/features/assessment/domain/draft_persistence_service.dart \
        test/features/assessment/domain/draft_persistence_service_test.dart
git commit -m "feat: add DraftPersistenceService for local SharedPreferences draft storage"
```

---

## Task 2: Screen — WidgetsBindingObserver + _saveLocalDraft + per-Antwort Local Save

**Files:**
- Modify: `lib/features/assessment/presentation/screens/reflex_profile_screen.dart`

### Kontext: Was sich ändert

Die Klassen-Definition des Screens bekommt das `WidgetsBindingObserver` Mixin. Ein neues Feld `_draftService` wird hinzugefügt. Eine neue Methode `_saveLocalDraft()` serialisiert den aktuellen Stand ins lokale Format. `_setYesNoAnswer` und Multiselect-/Months-Handler rufen `_saveLocalDraft()` nach jeder `setState()`-Änderung auf.

- [ ] **Schritt 1: Import und Mixin hinzufügen**

In `lib/features/assessment/presentation/screens/reflex_profile_screen.dart`:

Zeile 1 — `dart:async` Import hinzufügen (wird für Task 3 gebraucht, hier schon rein):
```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/draft_persistence_service.dart';
import '../../domain/reflex_profile_scoring.dart';
import '../../domain/reflex_questionnaire.dart';
import '../../domain/reflex_questionnaire_definitions.dart';
import '../providers/reflex_profile_provider.dart';
import '../../../trainer/presentation/providers/trainer_provider.dart';
```

Class-Definition (Zeile 22) ändern — `with WidgetsBindingObserver` hinzufügen:
```dart
class _ReflexProfileScreenState extends ConsumerState<ReflexProfileScreen>
    with WidgetsBindingObserver {
```

- [ ] **Schritt 2: `_draftService` Feld hinzufügen**

Nach den bestehenden Feldern (nach Zeile 30, bei `_questionKeys`):
```dart
  final _draftService = DraftPersistenceService();
  final _debounceTimers = <String, Timer>{};
```

- [ ] **Schritt 3: `initState` und `dispose` aktualisieren**

`initState` fehlt aktuell — direkt vor `dispose()` (Zeile 51) einfügen:
```dart
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }
```

Existierendes `dispose()` (Zeile 52–59) ersetzen:
```dart
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    _nameController.dispose();
    _questionnaireScrollController.dispose();
    for (final controller in _textControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
```

- [ ] **Schritt 4: `didChangeAppLifecycleState` Handler hinzufügen**

Direkt nach `dispose()`:
```dart
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _questionnaireStarted) {
      _saveDraft(); // bestehende Supabase-Sync-Methode
    }
  }
```

- [ ] **Schritt 5: `_saveLocalDraft()` Methode hinzufügen**

Direkt nach `_saveDraft()` (Zeile 332):
```dart
  void _saveLocalDraft() {
    final profile = _selectedProfile;
    if (profile == null || !_questionnaireStarted) return;
    _draftService.saveLocal(profile.id, {
      'saved_at': DateTime.now().toIso8601String(),
      'answers': {
        '__meta': {
          'module_index': _currentModuleIndex,
          'questionnaire_for': _questionnaireFor ?? 'child',
        },
        for (final e in _answers.entries) e.key: _answerToJson(e.value),
      },
      'warning_confirmations': _warningConfirmations.values
          .map((c) => {
                'question_id': c.questionId,
                'confirmed_at': c.confirmedAt.toIso8601String(),
                'message_version': c.messageVersion,
              })
          .toList(),
    });
  }
```

- [ ] **Schritt 6: `_setYesNoAnswer` — `_saveLocalDraft()` nach setState**

Existierendes `_setYesNoAnswer` (Zeile 110–117) — `_saveLocalDraft()` nach setState:
```dart
    setState(() {
      _highlightedQuestionIds.remove(question.id);
      _answers[question.id] = ReflexAnswerValue(
        yesNoUnknown: value,
        isUnknown: value == null,
      );
    });
    _saveLocalDraft();
```

- [ ] **Schritt 7: Multiselect Checkbox onChanged — `_saveLocalDraft()` nach setState**

In `_buildMultiSelectWithText` (Zeile 1062–1075), nach dem `setState`:
```dart
            onChanged: (checked) {
              final selected = [...answer.selectedOptionIds];
              if (checked == true && !selected.contains(option.id)) {
                selected.add(option.id);
              } else {
                selected.remove(option.id);
              }
              setState(() {
                _answers[question.id] = ReflexAnswerValue(
                  selectedOptionIds: selected,
                  text: controller.text,
                );
              });
              _saveLocalDraft();
            },
```

- [ ] **Schritt 8: Months „Weiß ich nicht" onTap — `_saveLocalDraft()` nach setState**

In `_buildMonths` (Zeile 1017–1028), beide setState-Blöcke im onTap:
```dart
          onTap: () {
            setState(() {
              if (isUnknown) {
                controller.clear();
                _answers[question.id] = const ReflexAnswerValue();
              } else {
                controller.clear();
                _answers[question.id] =
                    const ReflexAnswerValue(isUnknown: true);
              }
            });
            _saveLocalDraft();
          },
```

- [ ] **Schritt 9: App kompiliert fehlerfrei**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter analyze lib/features/assessment/presentation/screens/reflex_profile_screen.dart
```

Erwartet: keine Fehler.

- [ ] **Schritt 10: Commit**

```bash
git add lib/features/assessment/presentation/screens/reflex_profile_screen.dart
git commit -m "feat: add WidgetsBindingObserver + per-answer local draft save to ReflexProfileScreen"
```

---

## Task 3: Screen — Text-Debounce für Textfelder

**Files:**
- Modify: `lib/features/assessment/presentation/screens/reflex_profile_screen.dart`

### Kontext

Textfelder (FreeText, MultiSelectWithText-Text, MonthsNumber) sollen nach 300ms Schreibpause lokal speichern — nicht nach jedem Keystroke. Die `_scheduleDraftSave()`-Methode verwaltet einen Timer pro Question-ID.

- [ ] **Schritt 1: `_scheduleDraftSave` Methode hinzufügen**

Direkt nach `_saveLocalDraft()`:
```dart
  void _scheduleDraftSave(String questionId) {
    _debounceTimers[questionId]?.cancel();
    _debounceTimers[questionId] = Timer(
      const Duration(milliseconds: 300),
      _saveLocalDraft,
    );
  }
```

- [ ] **Schritt 2: FreeText `onChanged` — Debounce hinzufügen**

In `_buildFreeText` (Zeile 1044–1048):
```dart
      onChanged: (value) {
        setState(() {
          _answers[question.id] = ReflexAnswerValue(text: value);
        });
        _scheduleDraftSave(question.id);
      },
```

- [ ] **Schritt 3: MultiSelectWithText Text-Feld `onChanged` — Debounce hinzufügen**

In `_buildMultiSelectWithText` (Zeile 1085–1092):
```dart
          onChanged: (value) {
            setState(() {
              _answers[question.id] = ReflexAnswerValue(
                selectedOptionIds: answer.selectedOptionIds,
                text: value,
              );
            });
            _scheduleDraftSave(question.id);
          },
```

- [ ] **Schritt 4: MonthsNumber TextField `onChanged` — Debounce hinzufügen**

In `_buildMonths` (Zeile 1003–1009):
```dart
            onChanged: (value) {
              setState(() {
                _answers[question.id] = ReflexAnswerValue(
                  months: int.tryParse(value.trim()),
                );
              });
              _scheduleDraftSave(question.id);
            },
```

- [ ] **Schritt 5: Analyse**

```bash
flutter analyze lib/features/assessment/presentation/screens/reflex_profile_screen.dart
```

Erwartet: keine Fehler.

- [ ] **Schritt 6: Commit**

```bash
git add lib/features/assessment/presentation/screens/reflex_profile_screen.dart
git commit -m "feat: add 300ms debounced local draft save for text fields in ReflexProfileScreen"
```

---

## Task 4: Screen — PopScope mit Exit-Bestätigungsdialog

**Files:**
- Modify: `lib/features/assessment/presentation/screens/reflex_profile_screen.dart`

### Kontext

Der Back-Button soll während des Fragebogens einen Dialog zeigen: „Fragebogen verlassen?" — mit Abbrechen und Verlassen. Beim Verlassen wird sofort lokal gespeichert.

- [ ] **Schritt 1: `_showExitConfirmation()` Methode hinzufügen**

Direkt vor `_scheduleDraftSave()` einfügen:
```dart
  Future<void> _showExitConfirmation() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fragebogen verlassen?'),
        content: const Text(
          'Dein Fortschritt wird gespeichert. Du kannst jederzeit weitermachen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      _saveLocalDraft();
      context.pop();
    }
  }
```

- [ ] **Schritt 2: `build()` — Scaffold in PopScope einwickeln**

Aktuelles `build()` (Zeile 457–486) gibt direkt `Scaffold(...)` zurück. Das ersetzen durch:
```dart
  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(reflexSubjectProfilesProvider);

    return PopScope(
      canPop: !_questionnaireStarted,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _showExitConfirmation();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Reflexprofil')),
        body: SafeArea(
          child: profilesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Profile konnten nicht geladen werden: $error'),
              ),
            ),
            data: (profiles) {
              if (_questionnaireFor == null) {
                return _buildForWhom();
              }
              if (_questionnaireFor == 'adult') {
                return _buildAdultComingSoon();
              }
              if (!_questionnaireStarted) {
                return _buildStart(profiles);
              }
              return _buildQuestionnaire();
            },
          ),
        ),
      ),
    );
  }
```

- [ ] **Schritt 3: Analyse**

```bash
flutter analyze lib/features/assessment/presentation/screens/reflex_profile_screen.dart
```

Erwartet: keine Fehler.

- [ ] **Schritt 4: Commit**

```bash
git add lib/features/assessment/presentation/screens/reflex_profile_screen.dart
git commit -m "feat: add PopScope exit confirmation dialog with local draft save"
```

---

## Task 5: Screen — `_checkForDraft` lokal + Cloud

**Files:**
- Modify: `lib/features/assessment/presentation/screens/reflex_profile_screen.dart`

### Kontext

`_checkForDraft` liest aktuell nur Supabase. Es soll nun zuerst lokal laden, dann Cloud laden, Timestamps vergleichen, und den neueren Draft nehmen. Außerdem muss `_submit` den lokalen Draft beim Abschluss löschen.

Lokales Format (`saved_at` Top-Level): `{ 'saved_at': '...', 'answers': {...}, 'warning_confirmations': [...] }`  
Cloud Format (`updated_at` Top-Level, aus Supabase-Row): `{ 'updated_at': '...', 'answers': {...}, 'warning_confirmations': [...] }`

`_restoreDraft(row)` erwartet `row['answers']` und `row['warning_confirmations']` — beide Formate sind kompatibel.

- [ ] **Schritt 1: `_checkForDraft` ersetzen**

Existierende Methode (Zeile 334–377) komplett ersetzen:
```dart
  Future<void> _checkForDraft(String profileId) async {
    final localRaw = await _draftService.loadLocal(profileId);
    final cloudRaw = await loadReflexProfileDraft(profileId);
    if (!mounted) return;

    Map<String, dynamic>? best;
    if (localRaw != null && cloudRaw != null) {
      final localSavedAt =
          DateTime.tryParse(localRaw['saved_at'] as String? ?? '');
      final cloudUpdatedAt =
          DateTime.tryParse(cloudRaw['updated_at'] as String? ?? '');
      if (localSavedAt != null &&
          cloudUpdatedAt != null &&
          localSavedAt.isAfter(cloudUpdatedAt)) {
        best = localRaw;
      } else {
        best = cloudRaw;
      }
    } else {
      best = cloudRaw ?? localRaw;
    }

    if (best == null) {
      setState(() {
        _questionnaireStarted = true;
        _currentModuleIndex = 0;
      });
      return;
    }

    final resume = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fragebogen fortsetzen?'),
        content: const Text(
          'Du hast diesen Fragebogen bereits begonnen. '
          'Möchtest du dort weitermachen, wo du aufgehört hast?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Von vorne'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Fortsetzen'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (resume == true) {
      _restoreDraft(best);
    } else {
      deleteReflexProfileDraft(profileId).ignore();
      _draftService.clearLocal(profileId);
      setState(() {
        _questionnaireStarted = true;
        _currentModuleIndex = 0;
      });
    }
  }
```

- [ ] **Schritt 2: `_submit` — lokalen Draft beim Abschluss löschen**

In `_submit()` (Zeile 214), direkt nach `deleteReflexProfileDraft(profile.id).ignore();` einfügen:
```dart
      deleteReflexProfileDraft(profile.id).ignore();
      _draftService.clearLocal(profile.id);
```

- [ ] **Schritt 3: Analyse**

```bash
flutter analyze lib/features/assessment/presentation/screens/reflex_profile_screen.dart
```

Erwartet: keine Fehler.

- [ ] **Schritt 4: Bestehende Tests noch grün**

```bash
flutter test test/features/assessment/
```

Erwartet: alle Tests PASS.

- [ ] **Schritt 5: Commit**

```bash
git add lib/features/assessment/presentation/screens/reflex_profile_screen.dart
git commit -m "feat: extend _checkForDraft to merge local and cloud drafts by timestamp"
```

---

## Task 6: Manuelle Verifikation

- [ ] **Schritt 1: App starten**

```bash
make run
```

- [ ] **Szenario 1 — App-Close mid-module**
  1. Navigiere zum Reflexprofil → Kinderprofil auswählen → Fragebogen starten
  2. Beantworte 5-10 Fragen in Modul 1 (ohne „Weiter" zu drücken)
  3. App schließen (vom App-Switcher wegwischen)
  4. App neu starten → Reflexprofil → dasselbe Profil antippen
  5. Erwartet: Dialog „Fragebogen fortsetzen?" erscheint → „Fortsetzen" → Antworten wiederhergestellt

- [ ] **Szenario 2 — Back-Button**
  1. Fragebogen starten → einige Antworten geben
  2. Back-Button drücken
  3. Erwartet: Dialog „Fragebogen verlassen?" erscheint
  4. „Abbrechen" → zurück im Fragebogen ✓
  5. Nochmal Back → „Verlassen" → App-Screen verlassen → Profil antippen → Resume-Dialog ✓

- [ ] **Szenario 3 — Vollständiger Abschluss**
  1. Fragebogen vollständig ausfüllen und absenden
  2. Zum Reflexprofil zurück → dasselbe Profil antippen
  3. Erwartet: Kein Resume-Dialog, frischer Start ✓

- [ ] **Schritt 2: Abschließender Commit falls nötig**

Falls im manuellen Test kleinere Fixes nötig waren:
```bash
git add lib/features/assessment/presentation/screens/reflex_profile_screen.dart
git commit -m "fix: manual verification fixes for draft persistence"
```
