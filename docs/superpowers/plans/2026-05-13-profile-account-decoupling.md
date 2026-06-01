# Profile-Account Decoupling Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Decouple reflex profile creation from mandatory onboarding so accounts are tied to the username and profiles are created deliberately on demand.

**Architecture:** Remove the `_maybeRedirectOnboarding` Step 3 gate that forces profile creation before reaching the dashboard. The Entry Points screen "Weiter" button routes directly to the dashboard. The dashboard `_DailyUnitCard` gains a `hasProfile` flag — when `false` it shows a "Create your first profile" CTA pointing to `for_whom_screen`; when `true` but no enrollment, it shows the existing "Start a package" CTA. `for_whom_screen` back navigation always returns to the dashboard (no longer to `usernameSetup`).

**Tech Stack:** Flutter, Riverpod (`allReflexSubjectProfilesProvider`, `StateNotifierProvider`), go_router (`Routes.dashboard`, `Routes.onboardingForWhom`), Material 3

---

## File Map

| File | Change |
|------|--------|
| `lib/features/onboarding/presentation/screens/entry_points_screen.dart` | `Weiter` navigates to `Routes.dashboard` instead of `Routes.intakeAssessment` |
| `lib/features/dashboard/presentation/screens/dashboard_screen.dart` | Remove `_subjectProfileCheckDone` field + Step 3 redirect block + profiles listener; watch profiles in build; add `hasProfile` + `onCreateProfile` to `_DailyUnitCard` |
| `lib/features/onboarding/presentation/screens/for_whom_screen.dart` | Back navigation always goes to `Routes.dashboard` |
| `test/features/onboarding/presentation/screens/entry_points_screen_test.dart` | Register `/dashboard` route instead of `/intake-assessment`; add navigation test |

---

### Task 1: Entry Points Screen — Weiter routes to Dashboard

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/entry_points_screen.dart:89`
- Modify: `test/features/onboarding/presentation/screens/entry_points_screen_test.dart`

- [ ] **Step 1.1: Update test file**

Replace the full contents of `test/features/onboarding/presentation/screens/entry_points_screen_test.dart`:

```dart
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
            GoRoute(
              path: '/dashboard',
              builder: (_, __) => const Scaffold(body: Text('dashboard')),
            ),
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
              GoRoute(path: '/dashboard', builder: (_, __) => const Scaffold()),
            ],
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Mein Kind').last);
    await tester.tap(find.text('Mein Kind').last);
    await tester.pump();
    expect(container.read(entryPointsProvider), contains('mein_kind'));
  });

  testWidgets('Weiter button is always active', (tester) async {
    await tester.pumpWidget(_wrap(const EntryPointsScreen()));
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('Weiter button navigates to dashboard', (tester) async {
    await tester.pumpWidget(_wrap(const EntryPointsScreen()));
    await tester.tap(find.text('Weiter'));
    await tester.pumpAndSettle();
    expect(find.text('dashboard'), findsOneWidget);
  });
}
```

- [ ] **Step 1.2: Run tests — expect 1 failure**

```bash
flutter test test/features/onboarding/presentation/screens/entry_points_screen_test.dart -v
```

Expected: `Weiter button navigates to dashboard` fails — navigation attempts `/intake-assessment` which is not registered.

- [ ] **Step 1.3: Update entry_points_screen.dart line 89**

Change:
```dart
onPressed: () => context.go(Routes.intakeAssessment),
```
To:
```dart
onPressed: () => context.go(Routes.dashboard),
```

- [ ] **Step 1.4: Run tests — all pass**

```bash
flutter test test/features/onboarding/presentation/screens/entry_points_screen_test.dart -v
```

Expected: 5/5 pass.

- [ ] **Step 1.5: Commit**

```bash
git add lib/features/onboarding/presentation/screens/entry_points_screen.dart \
        test/features/onboarding/presentation/screens/entry_points_screen_test.dart
git commit -m "feat: entry points Weiter routes to dashboard, not intake assessment"
```

---

### Task 2: Dashboard — Remove profile gate and add profile-aware empty state

**Files:**
- Modify: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`

No automated test for this task — `DashboardScreen` requires ~20 provider dependencies. Covered by manual E2E testing in Task 4.

- [ ] **Step 2.1: Remove `_subjectProfileCheckDone` field**

In `_DashboardScreenState` (around line 42), remove:
```dart
bool _subjectProfileCheckDone = false;
```

- [ ] **Step 2.2: Remove Step 3 profile gate from `_maybeRedirectOnboarding`**

Remove lines 73–84 entirely (the Step 3 block including the comment):
```dart
    // Step 3: Subject profile check — every account needs at least one profile.
    if (!_subjectProfileCheckDone) {
      final profilesAsync = ref.read(allReflexSubjectProfilesProvider);
      if (profilesAsync.isLoading) return;
      _subjectProfileCheckDone = true;
      if (profilesAsync.valueOrNull?.isEmpty ?? true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(Routes.onboardingEntryPoints);
        });
        return;
      }
    }
```

After removal, `_maybeRedirectOnboarding` ends with `_onboardingCheckDone = true;`.

- [ ] **Step 2.3: Remove the `allReflexSubjectProfilesProvider` listener from build**

In the `build` method, remove (around line 327):
```dart
    ref.listen(allReflexSubjectProfilesProvider, (_, next) {
      if (!next.isLoading) _maybeRedirectOnboarding();
    });
```

- [ ] **Step 2.4: Watch profiles in build**

After the line `final enrollment = ref.watch(activeEnrollmentProvider).valueOrNull;` (around line 336), add:
```dart
    final profiles =
        ref.watch(allReflexSubjectProfilesProvider).valueOrNull ?? const [];
```

- [ ] **Step 2.5: Pass `hasProfile` and `onCreateProfile` to `_DailyUnitCard`**

The `_DailyUnitCard(...)` call (around lines 391–416) becomes:
```dart
_DailyUnitCard(
  packageName: _packageName(packageId),
  currentDay: progress?.currentDay ?? 1,
  totalDays: ((enrollment?.assignedDurationWeeks ?? 8) * 7).clamp(1, 3650),
  movementCount: flowState.totalExercises,
  estimatedMinutes: _estimatedMinutes(flowState.exercises),
  now: now,
  sessionsThisWeek: sessionsThisWeek,
  completedToday: completedToday,
  hasActivePackage: enrollment != null,
  hasProfile: profiles.isNotEmpty,
  onBeginGuided: () => _beginUnit(TrainingSessionMode.tutorial),
  onBeginRoutine: () => _beginUnit(TrainingSessionMode.routine),
  onObservation: () => _openObservation(enrollment?.id),
  onManualComplete: enrollment == null || progress == null || completedToday
      ? null
      : () => _markTodayComplete(enrollment: enrollment, progress: progress),
  onStartPackage: () => context.push(Routes.intakeAssessment),
  onCreateProfile: () => context.push(Routes.onboardingForWhom),
),
```

- [ ] **Step 2.6: Add `hasProfile` and `onCreateProfile` to `_DailyUnitCard` constructor**

In the `_DailyUnitCard` constructor (around line 474), add the two new required params after `hasActivePackage`:
```dart
const _DailyUnitCard({
  super.key,
  required this.packageName,
  required this.currentDay,
  required this.totalDays,
  required this.movementCount,
  required this.estimatedMinutes,
  required this.now,
  required this.sessionsThisWeek,
  required this.completedToday,
  required this.hasActivePackage,
  required this.hasProfile,
  required this.onBeginGuided,
  required this.onBeginRoutine,
  required this.onObservation,
  required this.onManualComplete,
  required this.onStartPackage,
  required this.onCreateProfile,
});
```

Add the two fields after `final bool hasActivePackage;` (around line 499):
```dart
final bool hasProfile;
final VoidCallback onCreateProfile;
```

- [ ] **Step 2.7: Replace empty state branch in `_DailyUnitCard.build`**

The current `else` block (around line 632) is:
```dart
            ] else ...[
              Text(
                'Erstelle dein Reflexprofil oder starte ein erstes Paket, um deinen Rhythmus aufzubauen.',
                ...
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onStartPackage,
                icon: const Icon(Icons.playlist_add_check_outlined),
                label: const Text('Paket starten'),
              ),
            ],
```

Replace with two cases:
```dart
            ] else if (!hasProfile) ...[
              Text(
                'Leg dein erstes Reflexprofil an, um loszulegen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onCreateProfile,
                icon: const Icon(Icons.person_add_outlined),
                label: const Text('Erstes Profil anlegen'),
              ),
            ] else ...[
              Text(
                'Erstelle dein Reflexprofil oder starte ein erstes Paket, um deinen Rhythmus aufzubauen.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onStartPackage,
                icon: const Icon(Icons.playlist_add_check_outlined),
                label: const Text('Paket starten'),
              ),
            ],
```

- [ ] **Step 2.8: Verify analyzer clean**

```bash
flutter analyze lib/features/dashboard/presentation/screens/dashboard_screen.dart
```

Expected: no new warnings or errors.

- [ ] **Step 2.9: Commit**

```bash
git add lib/features/dashboard/presentation/screens/dashboard_screen.dart
git commit -m "feat: remove profile gate from onboarding; add profile-aware empty state on dashboard"
```

---

### Task 3: For Whom Screen — Back navigation always to Dashboard

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/for_whom_screen.dart:136-144`

- [ ] **Step 3.1: Update back navigation**

Lines 136–144 currently read:
```dart
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          final profiles =
              ref.read(allReflexSubjectProfilesProvider).valueOrNull;
          context.go(
            profiles == null || profiles.isEmpty
                ? Routes.usernameSetup
                : Routes.dashboard,
          );
        },
      ),
```

Replace with:
```dart
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go(Routes.dashboard),
      ),
```

- [ ] **Step 3.2: Verify analyzer clean**

```bash
flutter analyze lib/features/onboarding/presentation/screens/for_whom_screen.dart
```

Expected: no warnings.

- [ ] **Step 3.3: Commit**

```bash
git add lib/features/onboarding/presentation/screens/for_whom_screen.dart
git commit -m "fix: for_whom back navigation always returns to dashboard"
```

---

### Task 4: Manual E2E Test

- [ ] **Step 4.1: Run on simulator**

```bash
make run-sim
```

- [ ] **Step 4.2: Test new user flow**

Register a fresh account and verify this exact sequence:

1. Login → Consent → Username → Einstiegsbereiche screen appears
2. Tap "Weiter" → lands on **Dashboard** (not intake assessment)
3. Dashboard shows **"Leg dein erstes Reflexprofil an, um loszulegen."** with "Erstes Profil anlegen" button
4. Tap "Erstes Profil anlegen" → opens `for_whom_screen`
5. Tap back arrow on `for_whom_screen` → returns to **Dashboard** (not username setup)
6. Tap "Erstes Profil anlegen" again → create a profile (self or child)
7. After profile creation modal: choose "Direkt zum Training" → back on dashboard
8. Dashboard now shows **"Paket starten"** CTA (profile exists, no enrollment yet)

- [ ] **Step 4.3: Test existing user flow**

Log in with an account that already has profiles:

1. Login → dashboard loads directly, no redirect to entry points
2. Dashboard shows active training state OR "Paket starten" (never "Erstes Profil anlegen")
