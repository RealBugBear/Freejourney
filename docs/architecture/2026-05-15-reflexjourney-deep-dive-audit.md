# ReflexJourney Deep-Dive Audit

Status: Audit baseline  
Date: 2026-05-15  
Scope: Current CoreJourney Flutter app, Supabase backend, documentation, tests, and ReflexJourney rebrand readiness

## 1. Executive Summary

The current app should not be thrown away in a full Big Bang rebuild.

The codebase already contains a significant amount of valuable product and infrastructure work:

- Flutter app with feature-first structure
- Supabase Auth, database, RLS, Edge Functions, and RPC-heavy trainer flows
- local Drift database with offline-first sync jobs
- reflex profile questionnaire, scoring, PDF export, trainer sharing, and multi-subject support
- trainer/client relationship model, appointments, chat, video calls, push notifications
- iOS/Android build flavor setup
- meaningful domain documentation and partial test coverage

At the same time, the project is not yet enterprise-ready for handoff to a broader developer team. The main problems are not one catastrophic architectural flaw, but accumulated overhang:

- stale tests that reference deleted modules
- large presentation files with mixed UI and feature logic
- direct Supabase access spread across screens/providers
- older product concepts that conflict with the newer calm ReflexJourney positioning
- duplicated or transitional services
- brand strings and app identifiers deeply embedded as `CoreJourney` / `corejourney`
- legacy multi-subject fallbacks still present after the profile migration
- documentation volume is high, but not yet organized as a clean architecture handbook

Recommendation:

1. Stabilize the current app.
2. Create a clean architecture documentation layer.
3. Remove or quarantine obvious overhang.
4. Refactor high-risk modules feature by feature.
5. Perform the ReflexJourney rebrand in controlled phases.
6. Only rebuild individual modules where refactoring costs more than replacement.

## 2. Rebuild Decision

### Recommendation

Do a controlled consolidation and modular refactor, not a full rewrite.

### Why not full rewrite now

A rewrite would have to recreate several complex, already working systems:

- account auth and password recovery
- Supabase RLS and trainer/client visibility
- multi-subject profile migration
- local Drift persistence and sync
- training package flows
- questionnaire scoring and safety warnings
- trainer application/review flows
- appointments with subject profile links
- video/notification infrastructure
- iOS/Android build, deep link, and store setup

Rebuilding these systems would add risk without guaranteeing better architecture.

### Where partial rebuilds may make sense

Some areas are good candidates for module-level rewrites or heavy extraction:

- `dashboard_screen.dart`
- `progress_overview_screen.dart`
- `accompaniment_screen.dart`
- `trainer_dashboard_screen.dart`
- `admin_panel_screen.dart`
- `reflex_profile_screen.dart`
- `trainer_client_detail_screen.dart`
- router setup in `core/navigation/app_router.dart`
- tests around feature flags, old progress architecture, and training flow

These files are large enough that extracting widgets, coordinators, and feature services would make future development safer.

## 3. Current Product Shape

The current product is best described as:

ReflexJourney is a guided reflex integration platform for users, families, trainers, therapists, and admins.

Core flows:

- user onboarding
- language selection
- consent/test-phase terms
- subject profile creation and selection
- reflex profile questionnaire
- reflex profile result and PDF export
- trainer profile sharing
- daily training package flow
- progress, mood, journal, and completion questionnaire
- trainer discovery and trainer/client relationship
- trainer dashboard/client detail
- appointments and appointment proposals
- chat and video calls
- admin controls and trainer application review

The app is currently both:

- a user-facing reflex integration companion
- a trainer/therapist client-management tool

This dual nature is valid and should stay. It does mean role boundaries and feature ownership must be clearer than in a simpler consumer app.

## 4. Current Architecture Snapshot

### Flutter structure

The app is already broadly feature-first:

```text
lib/
  app.dart
  bootstrap/
  config/
  core/
  features/
  l10n/
  main_*.dart
```

Main feature directories:

- `assessment`
- `training`
- `trainer`
- `chat`
- `video`
- `mood`
- `journal`
- `progress`
- `dashboard`
- `accompaniment`
- `profile`
- `onboarding`
- `admin`
- `auth`
- `consent`
- `community`
- `experience`
- `packages`
- `settings`
- `dev_tools`
- `golden_day`

Measured size:

- 211 Dart files
- about 56k Dart lines
- about 38.6k lines under `features/`
- 32 test files
- Supabase Edge Functions total about 1.4k lines

Largest feature files observed:

- `trainer_dashboard_screen.dart` - about 1296 lines
- `reflex_profile_screen.dart` - about 1287 lines
- `admin_panel_screen.dart` - about 1231 lines
- `progress_overview_screen.dart` - about 1148 lines
- `dashboard_screen.dart` - about 1125 lines
- `accompaniment_screen.dart` - about 1036 lines
- `exercise.dart` - about 970 lines
- `trainer_client_detail_screen.dart` - about 840 lines
- `rhythm_visualizer.dart` - about 835 lines
- `progress_provider.dart` - about 809 lines
- `trainer_provider.dart` - about 782 lines

These are the main enterprise-readiness pressure points.

### Bootstrap and global services

`bootstrap/bootstrap.dart` initializes:

- environment via `.env.dev` / `.env.prod`
- Supabase with `FileLocalStorage`
- local Drift database
- sync service
- shared preferences with in-memory fallback
- local notifications
- remote push notifications

This is pragmatic and valuable. It also contains several platform workaround comments, which should eventually be moved into an operational runbook or architecture decision record.

### Navigation

`core/navigation/app_router.dart` is currently a central router importing many screens directly. It handles:

- language gate
- auth gate
- password recovery gate
- public routes
- shell routes
- trainer/admin routes
- appointment routes
- community/experience routes

The current routing works as a single control point, but it is becoming too broad. A future enterprise structure should split route definitions by feature and assemble them in the app router.

### Local database

Drift database tables:

- enrollments
- exercises
- training sessions
- progress entries
- mood checkins
- sync jobs
- intake assessments
- completion questionnaires
- journal entries

Current local schema version: 7.

Important observation: local DB file is still named `corejourney_db.sqlite`. During rebrand, do not blindly rename this without a migration strategy, or existing users may appear to lose local data.

### Backend

Supabase includes:

- base `schema.sql`
- many migrations from chat/video/trainer foundations through multi-subject reflex profile work
- RLS application and verification SQL
- Edge Functions for trainer activation, role changes, Agora tokens, notifications, and chat triage

Key remote entities include:

- `profiles`
- `reflex_packages`
- `exercises`
- `enrollments`
- `intake_assessments`
- `completion_questionnaires`
- `training_sessions`
- `progress_entries`
- `mood_checkins`
- `trainer_client_relationships`
- `access_codes`
- `device_tokens`
- `feature_flags`
- `appointments`
- `user_consents`
- newer multi-subject tables documented in `docs/product/multi-subject-implementation-status.md`

The multi-subject architecture is a major asset and should be preserved.

## 5. Feature Map

### Assessment / Reflex Profile

Strong product fit. This is one of the core ReflexJourney modules.

Current responsibilities:

- questionnaire definitions
- scoring
- warnings/safety flags
- draft persistence
- subject profiles
- latest assessment lookup
- trainer sharing
- result screen
- PDF export

Risks:

- provider directly calls Supabase in many functions
- result/PDF score row parsing is duplicated in places
- `score` terminology is technically accurate but product language should prefer `Hinweisstaerke`, `Profil`, or `Auswertung` in UI
- questionnaire definitions are large and business-critical, so they need explicit versioning docs and fixtures

Recommendation:

- keep this module
- extract data repository/application service from `presentation/providers`
- create fixture-based tests for questionnaire/scoring/PDF summary
- document scoring thresholds and clinical language constraints

### Training

Strong product fit. The training flow is core.

Current responsibilities:

- exercise model
- fallback hardcoded exercises
- metronome/rhythm services
- in-app music
- training flow provider
- immersive exercise screen
- training session recording

Risks:

- `exercise.dart` is very large and mixes domain model, parsing, fallback content, and rhythm configuration
- fallback exercise content is useful but should be explicitly marked as content seed/fallback, not hidden in the domain model
- some tests target an older training flow API

Recommendation:

- split exercise content/fallbacks from the model
- make training flow state machine explicit and tested
- remove outdated tests or update them to the current state model

### Progress / Mood / Journal

Valid supporting modules.

Current responsibilities:

- active enrollment selection
- local progress entries
- regularity/streak fields
- mood check-ins
- journal entries
- aggregates for progress screens

Risks:

- `progress_provider.dart` is too large and has legacy preference key handling
- DB fields still include `daily_streak` and `weekly_streak`, while product direction says avoid streak/fire pressure
- UI language and analytics should distinguish technical regularity fields from user-facing pressure language

Recommendation:

- keep data fields if needed for backward compatibility
- rename UI concepts to regularity/rhythm, not streak
- extract progress domain services and query helpers

### Trainer / Client System

Core platform differentiator.

Current responsibilities:

- role lookup
- trainer clients
- invites
- trainer discovery
- applications and admin review
- shared reflex profiles
- client observations
- appointments and proposals
- profile notes

Risks:

- `trainer_provider.dart` directly accesses many Supabase tables/RPCs
- data access, debugging, relationship management, appointment actions, and shared profile logic are in one file
- several large trainer screens combine UI with orchestration

Recommendation:

- keep the module
- split into subdomains: `clients`, `applications`, `discovery`, `appointments`, `shared_profiles`
- move direct Supabase access into repositories
- keep providers thin

### Chat / Video

Useful for trainer/client support, but needs product boundary discipline.

Current responsibilities:

- direct channels
- community/application-review channel types
- realtime/polling fallbacks
- video call lifecycle
- Agora token edge function
- push notification edge functions

Risks:

- Community and experience concepts may pull the app toward social-platform energy
- `chat-triage-bot` uses Firebase legacy HTTP API while other notification functions use FCM v1
- video and chat are enterprise-sensitive and need stronger integration tests/RLS checks

Recommendation:

- keep 1:1 communication and application-review support
- decide whether community/experience is V1, hidden, or removed
- standardize notification implementation

### Community / Experience / Golden Day

These are the clearest product-overhang candidates.

Current product direction says:

- calm
- safe
- professional
- not social-feed energy
- no trophy/streak pressure
- shared experiences only as moderated voluntary content, not open community

Observed code still contains:

- `features/community`
- `features/experience`
- `features/golden_day`
- `Golden Day` localization
- community channel types and tests
- experience share prompts from mood/training sheets

Recommendation:

- decide explicitly:
  - remove for ReflexJourney V1
  - or quarantine behind admin/feature flag
  - or redesign as moderated `Erfahrungen`, not `Community`
- remove `Golden Day` from user-facing V1 unless there is a clear therapeutic rationale

## 6. Test And QA Findings

`flutter test` was run.

Observed result:

- many tests pass
- final run showed 104 passing tests before failure reporting
- test suite fails overall

Main failure categories:

1. Stale feature flag tests:
   - `test/core/feature_flags/feature_flag_service_test.dart`
   - imports `firebase_remote_config`, which is not in `pubspec.yaml`
   - imports missing files:
     - `lib/core/feature_flags/feature_flag_service.dart`
     - `lib/core/feature_flags/feature_flags.dart`
   - expects old `AppConfig.development` / `AppConfig.production` factory/static members

2. Stale old architecture tests:
   - tests reference missing old modules such as:
     - `core/database/database_service.dart`
     - `features/progress/domain/services/progress_service.dart`
     - old progress models
   - these need to be deleted, restored, or rewritten against Drift/current providers

3. Stale training flow tests:
   - `training_flow_provider_test.dart` expects methods/properties no longer present:
     - `startTraining`
     - `previousScreen`
     - `screenType`
   - indicates test suite is not synchronized with current training flow API

4. Widget test missing infrastructure:
   - `community_screen_test.dart` fails because `DirectMessagesAction` calls `Supabase.instance` without test initialization
   - also produced a large AppBar overflow due to exception/render fallout

Enterprise readiness requires that `flutter test` and `flutter analyze` become trusted gates again. The current tests are partially valuable but cannot be used as a release gate until stale tests are cleaned up.

## 7. Rebrand Touchpoint Audit

The rebrand from CoreJourney to ReflexJourney touches more than UI text.

### User-facing strings

Current `CoreJourney` strings appear in:

- `lib/app.dart`
- `main_development.dart`
- `main_staging.dart`
- `main_production.dart`
- l10n ARB/generated localization files
- consent/legal text
- trainer application copy
- PDF export metadata
- share text
- notification fallback text
- calendar ICS metadata

### Package and import identity

Current Dart package name:

```yaml
name: corejourney
```

All `package:corejourney/...` imports rely on this. Renaming the Dart package is possible but should be separated from the first user-facing rebrand if speed and safety matter.

### iOS

Current iOS values include:

- `CFBundleDisplayName`: `CoreJourney`
- `CFBundleName`: `CoreJourney`
- bundle ID: `com.alexandermessinger.corejourney`
- associated domain: `applinks:corejourney.care`
- permission prompts mentioning `CoreJourney`

### Android

Current Android values include:

- namespace: `com.alexandermessinger.corejourney`
- applicationId: `com.alexandermessinger.corejourney`
- flavor app names:
  - `CoreJourney DEV`
  - `CoreJourney STAGING`
  - `CoreJourney`
- HTTPS deep link host: `corejourney.care`
- custom scheme: `corejourney`

### Auth and deep links

Current password reset flow references:

- `https://corejourney.care/auth/reset-password`
- `corejourney://auth/reset-password`

Rebrand must update:

- Supabase Auth redirect URLs
- iOS associated domains
- Android app links
- website `apple-app-site-association`
- website `assetlinks.json`
- email templates
- login screen reset redirect
- app link parsing in `app.dart`

Do not remove old links immediately. Keep compatibility redirect handling for at least one release cycle.

### Firebase and push

Current Firebase references include:

- `corejourney-prod`
- `corejourney-prod.firebasestorage.app`
- default FCM project IDs in Supabase functions
- generated `firebase_options.dart`

Decision needed:

- keep existing Firebase project internally and rebrand only display names
- or create new `reflexjourney` Firebase project/apps and migrate push setup

For fastest stable rebrand, keep the project initially and rename user-facing app names.

### Supabase

Supabase table names do not need brand renaming. Avoid renaming tables/RPCs just for branding.

Potentially rename only:

- Edge Function notification titles
- secrets/default project IDs if Firebase project changes
- email/domain/auth redirect config

### Local data

Do not rename `corejourney_db.sqlite` without a migration path.

Recommended:

- keep file name in first rebrand release
- optionally introduce a later migration that copies/renames the DB file

## 8. Enterprise Readiness Risks

### High priority

1. Test suite is not a reliable gate.
2. Direct Supabase calls are spread across providers and screens.
3. Large screens/providers are hard to review and hand off.
4. Product-overhang modules conflict with ReflexJourney positioning.
5. Rebrand touches auth/deep-link infrastructure and can break password reset/login.
6. Multi-subject migration still intentionally contains nullable legacy paths.

### Medium priority

1. Generated files and docs are mixed with planning history.
2. There are duplicate notification service names:
   - `core/notifications/notification_service.dart`
   - `core/services/notification_service.dart`
3. Some folders exist without visible active implementation or are currently placeholders:
   - `core/access`
   - `core/payments`
   - parts of `community`
   - `golden_day`
4. Edge Functions have inconsistent Firebase push implementation styles.
5. App language sometimes still uses old terms (`Community`, `Golden Day`, `streak`, `score`) that should be reviewed against product language rules.

### Lower priority

1. `CoreJourneyApp` class name can remain internally at first, but should be renamed later for developer clarity.
2. `corejourney` Dart package name can remain temporarily, but should be renamed after a stable rebrand if the team wants full codebase consistency.
3. Historical docs are useful but need archival structure.

## 9. Recommended Target Architecture

Keep feature-first, but enforce layering.

Target shape:

```text
lib/
  app/
    bootstrap/
    router/
    theme/
    localization/
  core/
    auth/
    database/
    errors/
    logging/
    network/
    security/
    storage/
    sync/
    time/
    widgets/
  features/
    assessment/
      domain/
      application/
      data/
      presentation/
    training/
      domain/
      application/
      data/
      presentation/
    trainer/
      clients/
      appointments/
      applications/
      discovery/
      shared_profiles/
    communication/
      chat/
      video/
    progress/
    mood/
    journal/
    profile/
    onboarding/
    admin/
```

Rules:

- Screens should not directly call Supabase except in explicitly accepted small migrations.
- Providers should orchestrate use cases, not contain all data access.
- Repositories own Supabase/Drift queries.
- Domain models should not contain large content datasets.
- Feature route definitions should live near features and be assembled centrally.
- Legal/consent copy should be separated from UI layout.
- Product wording should be l10n-driven, not hardcoded in screens.

## 10. Suggested Work Plan

### Phase A: Audit documentation and safety gates

1. Keep this audit as the baseline.
2. Create:
   - `docs/architecture/product-map.md`
   - `docs/architecture/data-map.md`
   - `docs/architecture/feature-ownership.md`
   - `docs/architecture/rebrand-runbook.md`
3. Fix or remove stale tests until `flutter test` can pass.
4. Run and fix `flutter analyze`.
5. Add a release-readiness command that combines analyze + tests + generated-code check.

### Phase B: Product scope cleanup

1. Decide V1 status for:
   - Community
   - Experience shares
   - Golden Day
   - streak wording
2. Hide/remove/quarantine anything that does not match ReflexJourney V1.
3. Update language rules to ReflexJourney terminology:
   - Reflexprofil
   - Hinweisstaerke
   - Rhythmus
   - Begleitung
   - Verlauf
   - Einheit
   - Beobachtung

### Phase C: Rebrand Phase 1 - user-facing

1. Change app display names to ReflexJourney.
2. Update l10n strings and permission prompts.
3. Update PDF/share/calendar display text.
4. Update App Store/TestFlight metadata docs.
5. Keep internal package name and DB filename for now.

### Phase D: Rebrand Phase 2 - infrastructure

1. Pick canonical domain:
   - `reflexjourney.app`
   - `reflexjourney.care`
   - or another final domain
2. Configure new website deep link files.
3. Add Supabase redirect URLs.
4. Add `reflexjourney://` scheme.
5. Keep old `corejourney://` and `corejourney.care` compatibility.
6. Decide final Bundle ID/applicationId:
   - likely `com.freeplace.reflexjourney`
   - or `care.freeplace.reflexjourney`
7. Decide whether this is a new app listing or a renamed existing listing.

### Phase E: Architecture cleanup

1. Split large screens into sections/widgets.
2. Split `trainer_provider.dart`.
3. Split `progress_provider.dart`.
4. Extract Assessment repository/application service.
5. Extract Training content/fallback data.
6. Modularize routes.
7. Archive old planning docs.

### Phase F: Hardening

1. Add RLS verification scripts to CI/manual release checklist.
2. Add smoke tests for:
   - password reset deep link
   - onboarding
   - subject profile creation/switching
   - reflex profile completion
   - trainer share/revoke
   - appointment proposal
   - training session completion and sync
3. Add seeded test accounts and documented QA matrix for user/trainer/admin.

## 11. Immediate Next Steps

Recommended next implementation task:

Fix the test suite until `flutter test` is green or intentionally scoped.

Minimum cleanup list:

1. Remove or rewrite stale feature flag tests.
2. Remove or rewrite stale old progress/database tests.
3. Update training flow tests to current API.
4. Fix widget tests that require Supabase initialization by overriding providers or using test wrappers.
5. Then run `flutter analyze` and address real warnings/errors.

After that, the ReflexJourney rebrand can happen on a much safer baseline.

## 12. Final Recommendation

The current app is salvageable and worth consolidating.

Do not restart from zero. Treat the rebrand as the forcing function to professionalize the codebase:

- keep proven product logic
- document current behavior
- remove stale product/code overhang
- restore test gates
- refactor the worst hotspots
- rebrand in phases

This path is more likely to produce an enterprise-level ReflexJourney app than a rewrite, because it protects the complex work already done while still creating a clean developer handoff path.
