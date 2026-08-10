# Einstiegsbereiche & Onboarding-Umstrukturierung — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Neuen Onboarding-Screen "Viele Wege führen hierher" mit 5 aufklappbaren Einstiegsbereichen einbauen, Onboarding-Flow bereinigen (Consent vorgezogen, `for_whom_screen` entfernt), und Chip-Auswahl in `intake_assessments.additionalAnswers` persistieren.

**Architecture:** Riverpod `StateNotifier` hält die Chip-Auswahl im lokalen State bis die Enrollment in `DurationRecommendationScreen._confirm()` erstellt wird — dort werden Enrollment und neuer `intake_assessments`-Eintrag gemeinsam geschrieben. Die `createEnrollment`-Funktion wird angepasst, um die generierte Enrollment-ID zurückzugeben. Eine neue `createIntakeAssessment`-Funktion übernimmt das Persistieren des Assessment-Eintrags inkl. `entry_points`.

**Tech Stack:** Flutter · Riverpod (StateNotifier) · Drift (SQLite) · go_router · Supabase sync

---

## File Map

| Aktion | Datei |
|---|---|
| NEU | `lib/features/onboarding/presentation/providers/entry_points_provider.dart` |
| NEU | `lib/features/onboarding/presentation/screens/entry_points_screen.dart` |
| NEU | `test/features/onboarding/presentation/providers/entry_points_provider_test.dart` |
| NEU | `test/features/onboarding/presentation/screens/entry_points_screen_test.dart` |
| ÄNDERN | `lib/core/navigation/app_router.dart` |
| ÄNDERN | `lib/features/profile/presentation/screens/username_setup_screen.dart` |
| ÄNDERN | `lib/features/progress/presentation/providers/progress_provider.dart` |
| ÄNDERN | `lib/features/assessment/presentation/screens/duration_recommendation_screen.dart` |
| ÄNDERN | `lib/features/consent/presentation/screens/consent_screen.dart` |

---

## Task 1: EntryPoints Provider

**Files:**
- Create: `lib/features/onboarding/presentation/providers/entry_points_provider.dart`
- Test: `test/features/onboarding/presentation/providers/entry_points_provider_test.dart`

- [ ] **Step 1.1: Failing Test schreiben**

```dart
// test/features/onboarding/presentation/providers/entry_points_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:corejourney/features/onboarding/presentation/providers/entry_points_provider.dart';

void main() {
  ProviderContainer makeContainer() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('starts empty', () {
    final c = makeContainer();
    expect(c.read(entryPointsProvider), isEmpty);
  });

  test('toggle adds key', () {
    final c = makeContainer();
    c.read(entryPointsProvider.notifier).toggle('mein_kind');
    expect(c.read(entryPointsProvider), contains('mein_kind'));
  });

  test('toggle removes already-selected key', () {
    final c = makeContainer();
    c.read(entryPointsProvider.notifier).toggle('mein_kind');
    c.read(entryPointsProvider.notifier).toggle('mein_kind');
    expect(c.read(entryPointsProvider), isEmpty);
  });

  test('multiple keys selectable simultaneously', () {
    final c = makeContainer();
    c.read(entryPointsProvider.notifier).toggle('koerper_therapie');
    c.read(entryPointsProvider.notifier).toggle('neugierde');
    expect(
      c.read(entryPointsProvider),
      containsAll(['koerper_therapie', 'neugierde']),
    );
  });
}
```

- [ ] **Step 1.2: Test ausführen — muss fehlschlagen**

```bash
cd /Users/alexandermessinger/dev/claudvibes/reflexjourney
flutter test test/features/onboarding/presentation/providers/entry_points_provider_test.dart
```

Erwartetes Ergebnis: Fehler `Target file not found` oder Import-Fehler.

- [ ] **Step 1.3: Provider implementieren**

```dart
// lib/features/onboarding/presentation/providers/entry_points_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EntryPointsNotifier extends StateNotifier<List<String>> {
  EntryPointsNotifier() : super(const []);

  void toggle(String key) {
    if (state.contains(key)) {
      state = state.where((k) => k != key).toList();
    } else {
      state = [...state, key];
    }
  }
}

final entryPointsProvider =
    StateNotifierProvider<EntryPointsNotifier, List<String>>(
  (ref) => EntryPointsNotifier(),
);
```

- [ ] **Step 1.4: Test ausführen — muss grün sein**

```bash
flutter test test/features/onboarding/presentation/providers/entry_points_provider_test.dart
```

Erwartetes Ergebnis: 4 Tests PASS.

- [ ] **Step 1.5: Commit**

```bash
git add lib/features/onboarding/presentation/providers/entry_points_provider.dart \
        test/features/onboarding/presentation/providers/entry_points_provider_test.dart
git commit -m "feat: add EntryPointsNotifier provider for onboarding chip selection"
```

---

## Task 2: EntryPoints Screen

**Files:**
- Create: `lib/features/onboarding/presentation/screens/entry_points_screen.dart`
- Test: `test/features/onboarding/presentation/screens/entry_points_screen_test.dart`

- [ ] **Step 2.1: Failing Widget-Test schreiben**

```dart
// test/features/onboarding/presentation/screens/entry_points_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:corejourney/features/onboarding/presentation/screens/entry_points_screen.dart';
import 'package:corejourney/features/onboarding/presentation/providers/entry_points_provider.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp.router(
        routerConfig: GoRouter(
          routes: [
            GoRoute(path: '/', builder: (_, __) => child),
            GoRoute(path: '/intake-assessment', builder: (_, __) => const Scaffold()),
          ],
        ),
      ),
    );

void main() {
  testWidgets('renders all 5 area cards', (tester) async {
    await tester.pumpWidget(_wrap(const EntryPointsScreen()));
    expect(find.text('Körper & Therapie'), findsOneWidget);
    expect(find.text('Koordination & Leistung'), findsOneWidget);
    expect(find.text('Emotionale Regulation & Innenwelt'), findsOneWidget);
    expect(find.text('Mein Kind: Schule & Entwicklung'), findsOneWidget);
    expect(find.text('Neugierde & Entdeckung'), findsOneWidget);
  });

  testWidgets('card detail hidden by default, shown after tap', (tester) async {
    await tester.pumpWidget(_wrap(const EntryPointsScreen()));
    expect(find.text('Vgl. Goddard Blythe: (Über)leben mit Reflexen'),
        findsNothing);
    await tester.tap(find.text('Körper & Therapie'));
    await tester.pump();
    expect(find.text('Vgl. Goddard Blythe: (Über)leben mit Reflexen'),
        findsOneWidget);
  });

  testWidgets('chip tap updates provider selection', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(path: '/', builder: (_, __) => const EntryPointsScreen()),
              GoRoute(
                  path: '/intake-assessment',
                  builder: (_, __) => const Scaffold()),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Mein Kind').last);
    await tester.pump();
    expect(container.read(entryPointsProvider), contains('mein_kind'));
  });

  testWidgets('Weiter button is always active', (tester) async {
    await tester.pumpWidget(_wrap(const EntryPointsScreen()));
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNotNull);
  });
}
```

- [ ] **Step 2.2: Test ausführen — muss fehlschlagen**

```bash
flutter test test/features/onboarding/presentation/screens/entry_points_screen_test.dart
```

- [ ] **Step 2.3: EntryPointsScreen implementieren**

```dart
// lib/features/onboarding/presentation/screens/entry_points_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../providers/entry_points_provider.dart';

class EntryPointsScreen extends ConsumerStatefulWidget {
  const EntryPointsScreen({super.key});

  @override
  ConsumerState<EntryPointsScreen> createState() => _EntryPointsScreenState();
}

class _EntryPointsScreenState extends ConsumerState<EntryPointsScreen> {
  final Set<String> _expanded = {};

  void _toggleCard(String key) => setState(() {
        _expanded.contains(key) ? _expanded.remove(key) : _expanded.add(key);
      });

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(entryPointsProvider);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Viele Wege führen hierher',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Reflexintegration ist für sehr unterschiedliche Menschen relevant. '
                'Schau, was für dich klingt.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),
              ..._kAreas.map(
                (a) => _AreaCard(
                  area: a,
                  expanded: _expanded.contains(a.key),
                  onToggle: () => _toggleCard(a.key),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Was klingt für dich vertraut? (optional, Mehrfachauswahl)',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kAreas.map((a) {
                  return FilterChip(
                    label: Text(a.chipLabel),
                    selected: selected.contains(a.key),
                    onSelected: (_) =>
                        ref.read(entryPointsProvider.notifier).toggle(a.key),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                'Deine Auswahl ändert nichts am Training — sie hilft uns zu verstehen, wer die App nutzt.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.go(Routes.intakeAssessment),
                  child: const Text('Weiter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AreaData {
  const _AreaData({
    required this.key,
    required this.title,
    required this.teaser,
    required this.detail,
    required this.chipLabel,
    this.source,
  });
  final String key;
  final String title;
  final String teaser;
  final String detail;
  final String chipLabel;
  final String? source;
}

const _kAreas = [
  _AreaData(
    key: 'koerper_therapie',
    title: 'Körper & Therapie',
    teaser: 'Verspannungen, Fehlhaltungen, Empfehlung vom Therapeuten',
    detail:
        'Aktive Reflexmuster können zu dauerhafter Muskelanspannung führen — '
        'unabhängig von äußeren Auslösern. Physiotherapeut·innen und Ergotherapeut·innen '
        'empfehlen Reflexintegration häufig ergänzend, wenn klassische Behandlung nicht '
        'vollständig greift.\n\nTypische Hinweise: chronische Rücken- oder Nackenverspannungen, '
        'Kieferspannung, Fehlhaltungen die immer wiederkehren.',
    chipLabel: 'Körper & Therapie',
    source: 'Vgl. Goddard Blythe: (Über)leben mit Reflexen',
  ),
  _AreaData(
    key: 'koordination_leistung',
    title: 'Koordination & Leistung',
    teaser: 'Bewegungsqualität, Gleichgewicht, sportliche Koordination',
    detail:
        'Unintegrierte Reflexe binden motorische Ressourcen — was sich in eingeschränkter '
        'Koordination, verlangsamten Reaktionen oder Gleichgewichtsproblemen zeigen kann. '
        'Sportler·innen nutzen Reflexintegration um koordinative Grenzen zu erweitern, '
        'die durch klassisches Training nicht erreichbar sind.\n\nTypische Hinweise: '
        'Bewegungsabläufe fühlen sich schwerer an als nötig, Asymmetrien, Gleichgewicht unter Druck.',
    chipLabel: 'Koordination & Leistung',
    source: 'Vgl. Blomberg: Bewegungen die heilen',
  ),
  _AreaData(
    key: 'emotionale_regulation',
    title: 'Emotionale Regulation & Innenwelt',
    teaser: 'Stressreaktionen, Reizempfindlichkeit, Selbstwahrnehmung',
    detail:
        'Manche Reflexmuster beeinflussen direkt wie das Nervensystem auf Reize reagiert — '
        'Stressempfindlichkeit, emotionale Reaktivität, Reizüberflutung. Rhythmische Bewegung '
        'kann helfen, das Nervensystem zu regulieren und Zugang zu inneren Zuständen zu finden.\n\n'
        'Typische Hinweise: schnelle emotionale Überflutung, Schwierigkeit zur Ruhe zu kommen, '
        'Körperspannung in Stress. Verläuft sehr individuell.',
    chipLabel: 'Emotionale Regulation',
    source: 'Vgl. Blomberg: Bewegungen die heilen',
  ),
  _AreaData(
    key: 'mein_kind',
    title: 'Mein Kind: Schule & Entwicklung',
    teaser: 'Konzentration, Lernen, Schule — als Elternteil',
    detail:
        'Frühkindliche Reflexmuster die nicht vollständig integriert wurden, können sich später '
        'in Schwierigkeiten beim Lesen, Schreiben oder Konzentrieren zeigen — oft ohne klare '
        'organische Ursache.\n\nTypische Hinweise: Kind kommt in der Schule nicht mit, kann sich '
        'schwer fokussieren, ist unruhig im Unterricht, Feinmotorik oder Lesen bereitet Mühe.',
    chipLabel: 'Mein Kind',
    source: 'Vgl. Goddard Blythe: (Über)leben mit Reflexen',
  ),
  _AreaData(
    key: 'neugierde',
    title: 'Neugierde & Entdeckung',
    teaser: 'Kein konkretes Problem — einfach erkunden',
    detail:
        'Manche Menschen kommen ohne konkretes Symptom — sie haben von Reflexintegration gehört '
        'und sind neugierig was rhythmische Bewegung über mehrere Wochen verändert. '
        'Das ist ein vollständig gültiger Einstieg.\n\nDas Training wirkt unabhängig davon ob '
        'man ein "Problem" benennen kann oder nicht.',
    chipLabel: 'Einfach neugierig',
  ),
];

class _AreaCard extends StatelessWidget {
  const _AreaCard({
    required this.area,
    required this.expanded,
    required this.onToggle,
  });
  final _AreaData area;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(area.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(area.teaser,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    expanded ? 'Weniger ↑' : 'Mehr ↓',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: cs.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    area.detail,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.55,
                        ),
                  ),
                  if (area.source != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      area.source!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: cs.primary,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

- [ ] **Step 2.4: Tests ausführen — müssen grün sein**

```bash
flutter test test/features/onboarding/presentation/screens/entry_points_screen_test.dart
```

Erwartetes Ergebnis: 4 Tests PASS.

- [ ] **Step 2.5: Commit**

```bash
git add lib/features/onboarding/presentation/screens/entry_points_screen.dart \
        test/features/onboarding/presentation/screens/entry_points_screen_test.dart
git commit -m "feat: add EntryPointsScreen with 5 expandable area cards"
```

---

## Task 3: Router — neuen Route hinzufügen

**Files:**
- Modify: `lib/core/navigation/app_router.dart`

- [ ] **Step 3.1: Import und Route-Konstante hinzufügen**

In `lib/core/navigation/app_router.dart`:

Nach Zeile 51 (`import '../../features/onboarding/presentation/screens/for_whom_screen.dart';`) einfügen:

```dart
import '../../features/onboarding/presentation/screens/entry_points_screen.dart';
```

In der `Routes`-Klasse (nach `static const onboardingForWhom = '/onboarding/for-whom';`) einfügen:

```dart
static const onboardingEntryPoints = '/onboarding/entry-points';
```

- [ ] **Step 3.2: GoRoute registrieren**

Im Routenblock (nach dem GoRoute-Block für `path: Routes.onboardingForWhom`) einfügen:

```dart
GoRoute(
  path: Routes.onboardingEntryPoints,
  name: 'onboarding-entry-points',
  builder: (context, state) => const EntryPointsScreen(),
),
```

- [ ] **Step 3.3: App starten und prüfen dass sie kompiliert**

```bash
make run-sim
```

Erwartetes Ergebnis: App startet ohne Compilerfehler.

- [ ] **Step 3.4: Commit**

```bash
git add lib/core/navigation/app_router.dart
git commit -m "feat: register onboardingEntryPoints route in router"
```

---

## Task 4: Username-Setup Navigation anpassen

**Files:**
- Modify: `lib/features/profile/presentation/screens/username_setup_screen.dart`

- [ ] **Step 4.1: Navigations-Target ändern**

In `username_setup_screen.dart`, die Zeile:

```dart
context.go(Routes.onboardingForWhom);
```

ersetzen durch:

```dart
context.go(Routes.onboardingEntryPoints);
```

- [ ] **Step 4.2: Manuell testen**

```bash
make run-sim
```

Neuen Account anlegen → nach Username-Setup muss der neue EntryPoints-Screen erscheinen (nicht mehr der for_whom_screen). "Weiter" navigiert zum Intake Assessment.

- [ ] **Step 4.3: Commit**

```bash
git add lib/features/profile/presentation/screens/username_setup_screen.dart
git commit -m "feat: route username setup to entry points screen instead of for-whom"
```

---

## Task 5: createEnrollment gibt ID zurück + createIntakeAssessment

**Files:**
- Modify: `lib/features/progress/presentation/providers/progress_provider.dart`

- [ ] **Step 5.1: createEnrollment Rückgabetyp auf `Future<String>` ändern**

In `progress_provider.dart`, Funktionssignatur ändern von:

```dart
Future<void> createEnrollment({
```

zu:

```dart
Future<String> createEnrollment({
```

Die frühe Rückkehr wenn Enrollment schon existiert ändern von `return;` zu:

```dart
if (existing != null) return existing.id;
```

Am Ende der Funktion (nach dem letzten `syncService.enqueueUpsert`-Aufruf) hinzufügen:

```dart
return enrollmentId;
```

- [ ] **Step 5.2: createIntakeAssessment Funktion hinzufügen**

Am Ende von `progress_provider.dart`, nach `createEnrollment`, einfügen:

```dart
Future<void> createIntakeAssessment({
  required AppDatabase db,
  required SyncService syncService,
  required String enrollmentId,
  required bool hadIsometricWithTrainer,
  required int recommendedDurationWeeks,
  required bool userAcceptedRecommendation,
  required int finalDurationWeeks,
  required List<String> entryPoints,
}) async {
  final id = _uuid.v4();
  final now = DateTime.now();
  final additionalAnswers = entryPoints.isEmpty
      ? null
      : jsonEncode({'entry_points': entryPoints});

  await db.into(db.intakeAssessmentsTable).insert(
        IntakeAssessmentsTableCompanion.insert(
          id: id,
          enrollmentId: enrollmentId,
          hadIsometricWithTrainer: hadIsometricWithTrainer,
          additionalAnswers: drift.Value(additionalAnswers),
          recommendedDurationWeeks: recommendedDurationWeeks,
          userAcceptedRecommendation: userAcceptedRecommendation,
          finalDurationWeeks: finalDurationWeeks,
          completedAt: now,
        ),
      );

  await syncService.enqueueUpsert(
    tableName: 'intake_assessments',
    recordId: id,
    payload: {
      'id': id,
      'enrollment_id': enrollmentId,
      'had_isometric_with_trainer': hadIsometricWithTrainer,
      if (additionalAnswers != null) 'additional_answers': additionalAnswers,
      'recommended_duration_weeks': recommendedDurationWeeks,
      'user_accepted_recommendation': userAcceptedRecommendation,
      'final_duration_weeks': finalDurationWeeks,
      'completed_at': now.toIso8601String(),
    },
  );
}
```

- [ ] **Step 5.3: Import für jsonEncode hinzufügen**

Am Anfang von `progress_provider.dart` prüfen ob `dart:convert` importiert ist. Falls nicht:

```dart
import 'dart:convert';
```

Außerdem sicherstellen dass der Drift-Generated Companion importiert ist. Die Datei importiert bereits `app_database.dart`, daher ist `IntakeAssessmentsTableCompanion` über `.g.dart` verfügbar.

- [ ] **Step 5.4: App kompilieren**

```bash
flutter analyze lib/features/progress/presentation/providers/progress_provider.dart
```

Erwartetes Ergebnis: keine Fehler.

- [ ] **Step 5.5: Commit**

```bash
git add lib/features/progress/presentation/providers/progress_provider.dart
git commit -m "feat: createEnrollment returns ID, add createIntakeAssessment with entry_points"
```

---

## Task 6: DurationRecommendationScreen ruft createIntakeAssessment auf

**Files:**
- Modify: `lib/features/assessment/presentation/screens/duration_recommendation_screen.dart`

- [ ] **Step 6.1: Import für entryPointsProvider hinzufügen**

Am Anfang von `duration_recommendation_screen.dart` einfügen:

```dart
import '../../../onboarding/presentation/providers/entry_points_provider.dart';
```

- [ ] **Step 6.2: `_confirm()` erweitern**

Die bestehende `_confirm()`-Methode enthält:

```dart
await createEnrollment(
  db: ref.read(databaseProvider),
  syncService: ref.read(syncServiceProvider),
  userId: userId,
  subjectProfileId: ref.read(selectedSubjectProfileProvider)?.id,
  packageId: _packageId,
  durationWeeks: _selectedWeeks,
);
```

Ersetzen durch:

```dart
final enrollmentId = await createEnrollment(
  db: ref.read(databaseProvider),
  syncService: ref.read(syncServiceProvider),
  userId: userId,
  subjectProfileId: ref.read(selectedSubjectProfileProvider)?.id,
  packageId: _packageId,
  durationWeeks: _selectedWeeks,
);

await createIntakeAssessment(
  db: ref.read(databaseProvider),
  syncService: ref.read(syncServiceProvider),
  enrollmentId: enrollmentId,
  hadIsometricWithTrainer: _hadTrainer,
  recommendedDurationWeeks:
      _computeRecommendedWeeks(hadIsometricWithTrainer: _hadTrainer),
  userAcceptedRecommendation: _selectedWeeks ==
      _computeRecommendedWeeks(hadIsometricWithTrainer: _hadTrainer),
  finalDurationWeeks: _selectedWeeks,
  entryPoints: ref.read(entryPointsProvider),
);
```

- [ ] **Step 6.3: App kompilieren und manuell testen**

```bash
flutter analyze lib/features/assessment/presentation/screens/duration_recommendation_screen.dart
make run-sim
```

Kompletten Onboarding-Flow durchführen, Einstiegsbereiche-Chips auswählen, bis Dashboard. Danach in Supabase Studio prüfen (oder lokale Drift DB): `intake_assessments` enthält einen neuen Eintrag mit `additional_answers` → `{"entry_points": ["..."]}`.

- [ ] **Step 6.4: Commit**

```bash
git add lib/features/assessment/presentation/screens/duration_recommendation_screen.dart
git commit -m "feat: create intake_assessment with entry_points on enrollment confirmation"
```

---

## Task 7: Consent Screen — Datenpunkt ergänzen

**Files:**
- Modify: `lib/features/consent/presentation/screens/consent_screen.dart`

- [ ] **Step 7.1: Deutschen Consent-Text ergänzen**

In `consent_screen.dart`, Zeile 474–477 (Deutsch — "Erhobene Daten"):

Bestehend:
```dart
'Wir erheben folgende Daten: E-Mail-Adresse und Passwort (für die Registrierung), '
'Fortschrittsdaten (Trainingseinheiten, Intake-Assessment), '
'Stimmungsdaten (Mood-Checkins, Journal-Einträge) sowie '
'Geräteinformationen (Betriebssystem, App-Version).',
```

Ersetzen durch:
```dart
'Wir erheben folgende Daten: E-Mail-Adresse und Passwort (für die Registrierung), '
'Fortschrittsdaten (Trainingseinheiten, Intake-Assessment), '
'Stimmungsdaten (Mood-Checkins, Journal-Einträge), '
'deine optionale Angabe dazu, was dich hierher geführt hat (Einstiegsbereich), sowie '
'Geräteinformationen (Betriebssystem, App-Version).',
```

- [ ] **Step 7.2: Englischen Consent-Text ergänzen**

In `consent_screen.dart`, Zeile 554–555 (Englisch — "progress data"):

Bestehend:
```dart
'progress data (training sessions, intake assessment), '
'mood data (mood check-ins, journal entries), and '
```

Ersetzen durch:
```dart
'progress data (training sessions, intake assessment), '
'mood data (mood check-ins, journal entries), '
'your optional entry point selection (what brought you here), and '
```

- [ ] **Step 7.3: Visuell prüfen**

```bash
make run-sim
```

Consent-Screen öffnen — neuer Datenpunkt muss im "Erhobene Daten"-Block sichtbar sein.

- [ ] **Step 7.4: Commit**

```bash
git add lib/features/consent/presentation/screens/consent_screen.dart
git commit -m "feat: add entry_points data point to consent screen text"
```

---

## Task 8: Gesamttest

- [ ] **Step 8.1: Alle Unit-Tests ausführen**

```bash
flutter test test/features/onboarding/
```

Erwartetes Ergebnis: alle 8 Tests PASS.

- [ ] **Step 8.2: Manuellen End-to-End Flow durchführen**

Neuen Account mit frischer E-Mail anlegen. Prüfen:
- ✓ Nach Login: Consent erscheint (nicht username setup)
- ✓ Nach Consent: Username Setup
- ✓ Nach Username: EntryPoints Screen "Viele Wege führen hierher"
- ✓ Karten klappen auf/zu
- ✓ Chips lassen sich auswählen/abwählen (Mehrfachauswahl)
- ✓ "Weiter" ohne Chip-Auswahl funktioniert
- ✓ Nach Weiter: Intake Assessment (isometrische Frage)
- ✓ `for_whom_screen` erscheint nicht mehr als separater Schritt
- ✓ Nach vollem Flow: Dashboard
- ✓ `intake_assessments`-Eintrag in Supabase enthält `additional_answers` mit `entry_points`

- [ ] **Step 8.3: flutter analyze**

```bash
flutter analyze lib/
```

Keine neuen Fehler oder Warnings.
