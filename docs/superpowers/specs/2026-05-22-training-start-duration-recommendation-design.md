# Training Start Flow + Duration Recommendation — Technical Spec

## Goal

Build a complete training start flow that:

- shows the Vorrunde recommendation only before Moro,
- keeps free Vorrunde available inside the current daily package card,
- calculates package duration from reflex profile scores and isometric partner training,
- reuses existing trainer discovery state,
- stores Vorrunde phase state in Supabase per subject profile,
- integrates dashboard, streak, history, journal/experience, and tests.
- follows enterprise delivery practices: additive migrations, isolated domain logic, provider boundaries, testable phases, explicit rollback path.

This spec implements the plan in:

`docs/superpowers/plans/2026-05-22-training-start-duration-recommendation.md`

## Core Decisions

- Vorrunde recommendation appears only before Moro.
- Free Vorrunde remains available after Moro and during later packages, but only when an active package exists.
- Free Vorrunde counts for `heute etwas gemacht` and the same Streak, but not for active package progress.
- If package training and Vorrunde happen on the same day, package training has visible priority in daily status/documentation.
- Vorrunde phase starts at first Vorrunde start, not first completion.
- Moro may start before 4 weeks with a small info text, no blocker.
- After 4 weeks, dashboard actively focuses `Jetzt Moro starten`.
- No CompletionQuestionnaire for Vorrunde.
- After free Vorrunde, offer the same experience/journal habit as package sessions.
- Trainer status uses existing `trainer_client_relationships` and `clientTrainerConnectionsProvider`.

## Supabase

### Migration

Add migration:

`supabase/migrations/20260522_create_vorrunde_phases.sql`

Table:

```sql
create table if not exists public.vorrunde_phases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  subject_profile_id uuid references public.reflex_subject_profiles(id) on delete cascade,
  status text not null default 'started'
    check (status in ('started', 'skipped', 'completed')),
  first_started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, subject_profile_id)
);
```

No `package_id`: Vorrunde is only a Moro preparation status per subject profile.

Add:

- index on `(user_id, subject_profile_id)`
- index on `(status)`
- `updated_at` trigger using the repo's existing timestamp pattern if available
- verification query in `supabase/rls_verify.sql`

### RLS

- Enable RLS.
- Users can select/insert/update/delete only rows where `auth.uid() = user_id`.
- Trainers get no access for now.
- RLS policy names should use the repo's hardened `cj:` naming style where appropriate.
- Add table to RLS verification checks.

### Sync Rules

- Local SharedPreferences/Drift is cache/fallback only.
- Supabase is source of truth for `status`, `first_started_at`, `completed_at`.
- On conflict, latest `updated_at` wins.
- Store `skipped` server-side so the Moro pre-start hint does not reappear on other devices.
- If a skipped user later does free Vorrunde, keep phase status `skipped`; log free Vorrunde separately.
- If user starts Moro before 4 weeks, keep phase status `started`.

## Domain Services

### Duration Recommendation

Create:

`lib/features/assessment/domain/services/training_duration_recommendation_service.dart`

Keep this file pure Dart/domain logic:

- no Flutter imports
- no Supabase imports
- no Riverpod imports
- deterministic inputs and outputs

API:

```dart
class TrainingDurationRecommendation {
  const TrainingDurationRecommendation({
    required this.weeks,
    required this.consideredPercents,
    required this.consideredReflexes,
    required this.usedAssessment,
    required this.hadIsometricWithTrainer,
  });

  final int weeks;
  final Map<PrimitiveReflex, double?> consideredPercents;
  final List<PrimitiveReflex> consideredReflexes;
  final bool usedAssessment;
  final bool hadIsometricWithTrainer;
}

TrainingDurationRecommendation recommendTrainingDuration({
  required String packageId,
  required bool hadIsometricWithTrainer,
  ReflexProfileAssessment? assessment,
});
```

Mapping:

- `moro` -> `moro`, `flr`
- `spinal_galant` -> `spinalGalant`
- `tlr` -> `tlr`
- later packages according to plan mapping

Rules:

- Use max percent across mapped reflexes.
- `< 75%`: low
- `>= 75% && <= 85%`: medium
- `> 85%`: high
- Isometric yes: 4 / 5 / 6 weeks
- Isometric no: 6 / 7 / 8 weeks
- Missing assessment fallback: yes -> 4 weeks, no -> 8 weeks
- Assessment never expires.

Moro UI must show:

```text
Moro-Tendenz: 68%
FLR-Tendenz: 82%
Für die Dauer zählt der stärkere Hinweis.
```

If a mapped value is unavailable:

```text
FLR-Tendenz: keine ausreichenden Daten
```

If assessment was skipped, do not show individual values. Show Standardlogik explanation.

### Vorrunde Phase Service

Create provider/service, suggested:

`lib/features/training/domain/services/vorrunde_phase_service.dart`

Recommended layering:

- domain model: `VorrundePhase`
- repository interface: fetch/start/skip/complete
- Supabase-backed implementation
- provider wrapper for UI
- local cache/fallback isolated from UI

Responsibilities:

- fetch phase for current `subject_profile_id`
- create/start phase with `first_started_at`
- mark `skipped`
- mark/derive `completed` after 4 calendar weeks from `first_started_at`
- cache locally

Expose a Riverpod provider for dashboard/startflow:

```dart
final vorrundePhaseProvider =
    FutureProvider.family<VorrundePhase?, String?>((ref, subjectProfileId) async {
  ...
});
```

## Routes And Screens

### New Route

Add route:

`Routes.trainingStart`

Routing migration:

- Replace dashboard `onStartPackage -> Routes.intakeAssessment` with `Routes.trainingStart`.
- Keep old screens available because the new flow still routes through intake/trainer/duration steps.
- No feature flag by default; use clean routing replacement after tests pass.

Screen:

`lib/features/training/presentation/screens/training_start_flow_screen.dart`

### TrainingStartFlowScreen

Responsibilities:

- show selected active profile clearly
- if package is Moro and no active/completed Moro enrollment:
  - if no Vorrunde phase or status unseen: show Vorrunde decision
  - if Vorrunde phase started and < 4 weeks: show small info if user continues to Moro
  - if Vorrunde phase >= 4 weeks: show `Jetzt Moro starten`
- strongly recommend Reflexprofil; allow skip with confirm:

```text
Ohne persönliches Reflexprofil zur Einschätzung deines Standes fortfahren?
```

- ask isometric partner training question
- if answer no: show trainer decision screen
- route to DurationRecommendationScreen

### Trainer Decision Screen

Use existing trainer flow.

Existing data:

- `clientTrainerConnectionsProvider`
- `ClientTrainerConnection.isPending`
- `ClientTrainerConnection.isActive`

Rules:

- no new trainer contact status
- `pending`: contact/request sent, waiting
- `active`: connected trainer
- if active but user has not done isometric partner training: still `hadIsometricWithTrainer == false`
- if user clicks `Trainer finden`, then returns without appointment/contact, go back to startflow
- only after clicking `Trainer finden`, offer Vorrunde as waiting option:

```text
Während du auf Rückmeldung oder einen Termin wartest, kannst du die Vorrunde nutzen.
Sie bereitet rhythmisch vor und ist unabhängig vom isometrischen Partnertraining.
```

Trainer reminder appears at each new package start if no trainer/isometric training, not before each daily session.

### Vorrunde Completion / Ready Screen

Create a small screen or sheet:

`VorrundeReadyForMoroScreen`

Primary:

```text
Jetzt Moro starten
```

It routes to `Routes.trainingStart`; if Reflexprofil and trainer decisions are already done, continue directly to duration recommendation.

## Dashboard

File:

`lib/features/dashboard/presentation/screens/dashboard_screen.dart`

### No Active Package

- Do not show free Vorrunde.
- Package start itself is the introduction.

### Active Vorrunde Phase

- Dashboard primarily shows Vorrunde.
- Main button:

```text
Vorrunde fortsetzen
```

- After 4 weeks, focus:

```text
Jetzt Moro starten
```

### Active Reflex Package

- Show current package as today card.
- Inside same card, add secondary Vorrunde option:

```text
Vorrunde zur Beruhigung
```

- No separate banner.
- If free Vorrunde done today, show small text:

```text
Heute Vorrunde gemacht
```

- Keep package button:

```text
Einheit beginnen
```

If package training and free Vorrunde both happened today:

- visible daily status shows package training
- Streak counts once
- both events may exist internally/history-side

## Session / Progress / Streak

### Vorrunde Session

- Save as event/session with `packageId: 'vorrunde'`.
- Counts for `heute etwas gemacht`.
- Counts for same Streak as package training.
- Does not update active package `progress_entries.current_day`.
- Does not help complete Moro or later packages faster.

### Completion

- No CompletionQuestionnaire for Vorrunde.
- CompletionQuestionnaire remains package-only.

### Journal / Experience

- After free Vorrunde, offer same experience/journal habit as package training.
- Do not let Vorrunde override visible package daily status if package training also happened that day.

## DurationRecommendationScreen

File:

`lib/features/assessment/presentation/screens/duration_recommendation_screen.dart`

Changes:

- use new recommendation service
- load selected subject latest assessment
- show source:

```text
Diese Empfehlung basiert auf deiner persönlichen Reflexprofil-Auswertung.
```

or:

```text
Diese Empfehlung basiert auf der Standardlogik, weil kein persönliches Reflexprofil vorliegt.
```

- default view has primary action:

```text
Empfehlung übernehmen
```

- secondary:

```text
Dauer anpassen
```

- only after secondary action show slider/week picker
- manual adjustment allows free choice 4-8 weeks

## Tests

### Unit Tests

Duration service:

- isometric yes, Moro max 65 -> 4
- isometric yes, Moro max 75 -> 5
- isometric yes, Moro max 85 -> 5
- isometric yes, Moro max 86 -> 6
- isometric no, Moro max 65 -> 6
- isometric no, Moro max 75 -> 7
- isometric no, Moro max 86 -> 8
- Moro uses max of Moro/FLR
- Moro returns both individual values
- missing value returns null/`keine ausreichenden Daten`
- missing assessment uses fallback

Vorrunde phase:

- start creates first_started_at
- skipped persists
- skipped plus free Vorrunde remains skipped
- 4 calendar weeks derives/completes phase
- Moro start before 4 weeks keeps status started

### Widget / Flow Tests

- Dashboard package start routes to training start flow.
- Vorrunde shown only before Moro.
- Vorrunde not shown before later packages.
- Free Vorrunde hidden without active package.
- Free Vorrunde visible inside active package card.
- Free Vorrunde done today shows small text, package button remains.
- Active Vorrunde phase shows `Vorrunde fortsetzen`.
- After 4 weeks dashboard shows `Jetzt Moro starten`.
- Reflexprofile skip confirm appears.
- Trainer decision appears when isometric no.
- Trainer pending state offers Vorrunde waiting option.
- Duration screen shows source and individual Moro/FLR values.

### Integration / Analyze

- Run `flutter analyze`.
- Run focused tests for new services/screens.
- Verify Supabase migration and RLS with read/write smoke queries.

## Delivery Phases

### Phase 1 — Data + Domain

Files:

- `supabase/migrations/20260522_create_vorrunde_phases.sql`
- `supabase/rls_verify.sql`
- `lib/features/assessment/domain/services/training_duration_recommendation_service.dart`
- tests for duration recommendation
- `lib/features/training/domain/services/vorrunde_phase_service.dart`

Exit:

- migration additive and RLS verified
- domain tests passing
- no UI routing changed

### Phase 2 — Startflow + Duration UI

Files:

- `lib/core/navigation/app_router.dart`
- route constants
- `lib/features/training/presentation/screens/training_start_flow_screen.dart`
- `lib/features/assessment/presentation/screens/duration_recommendation_screen.dart`

Exit:

- package start routes through new flow
- skip/reflex/trainer/duration paths tested

### Phase 3 — Dashboard + Vorrunde Integration

Files:

- `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- training session completion/save path
- experience/journal sheet integration
- progress/streak providers if needed

Exit:

- Vorrunde cannot mutate active package progress
- daily status priority verified
- journal prompt works for Vorrunde

### Phase 4 — Hardening

- `flutter analyze`
- focused test suite
- manual QA matrix from plan
- migration/RLS smoke checks

## Rollback

- Migration is additive; do not roll it back for app rollback.
- If UI regression occurs, route dashboard package start back to `Routes.intakeAssessment`.
- Keep new domain services unused until routing is restored.
- Existing enrollments/progress tables are not destructively changed.

