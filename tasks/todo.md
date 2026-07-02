# P1.2 Category-C identity work

Session 2026-07-02. Scope: finish the local parts of the `de.reflexjourney.app`
identity change, and separate anything that depends on external Firebase,
Vercel, App Store Connect, or device QA state.

## Context

- P0 remaining work is gated or blocked; P1.2 is the next actionable backlog
  item.
- Current mobile IDs are still `com.alexandermessinger.corejourney`; Android
  adds `.dev` / `.staging` suffixes.
- iOS flavor schemes exist but reference missing build configurations
  (`Debug-development`, `Release-staging`, `Release-production`, etc.).
- Firebase currently has no app records for `de.reflexjourney.app`,
  `de.reflexjourney.app.dev`, or `de.reflexjourney.app.staging`; those remote
  app records are required before the Firebase config files can be honestly
  regenerated.

## Steps

- [x] 1. Inventory current app IDs, Firebase app records, deep-link config, and
      the `reflexjourney-app-site/` static site.
- [x] 2. Update Android local identity: namespace/application ID to
      `de.reflexjourney.app`, preserve `.dev`/`.staging` suffixes, move the
      Kotlin package, and update package-name references/docs.
- [x] 3. Repair iOS flavor config and set bundle IDs to
      `de.reflexjourney.app.dev`, `de.reflexjourney.app.staging`, and
      `de.reflexjourney.app`.
- [x] 4. Add `.well-known/apple-app-site-association` and
      `.well-known/assetlinks.json` to the outer static site, using Team ID
      `5X6VFP7F58` and the release SHA-256 certificate fingerprint.
- [x] 5. Verify local builds/config: lint JSON/plists, run targeted greps,
      `flutter analyze`, Android dev build, and iOS simulator/prod build checks
      as far as signing/Firebase state permits.
- [x] 6. Update the backlog with observed evidence, splitting blocked Firebase
      and end-to-end device verification into their own unchecked follow-ups.

## Expected External Blockers

- Firebase: create/register the new Android and iOS app records, then regenerate
  `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`,
  and `lib/firebase_options.dart` with the real app IDs.
- Vercel: deploy the static-site `.well-known` files.
- App Store Connect / Apple Developer: ensure bundle IDs and associated domains
  exist for the final app IDs.
- Fresh-install deep-link verification must happen after the app IDs, site
  files, Firebase config, and deployed site are all in place.

## Review

- Android: base `applicationId`/namespace is now `de.reflexjourney.app`; dev
  and staging keep `.dev` / `.staging`. `flutter build apk --flavor
  development -t lib/main_development.dart --debug` passed, and the merged
  manifest reports package `de.reflexjourney.app.dev` with activity
  `de.reflexjourney.app.MainActivity`.
- iOS: added real Debug/Release/Profile build configurations for development,
  staging, and production; schemes now point at those configs; `pod install`
  runs without warnings. Verified dev simulator build bundle ID
  `de.reflexjourney.app.dev` and production no-codesign device build bundle ID
  `de.reflexjourney.app`.
- Static site: added local `.well-known/apple-app-site-association`,
  `.well-known/assetlinks.json`, and `vercel.json`; JSON validation passed.
- Not complete externally: Firebase apps/config are still old because Firebase
  has no `de.reflexjourney.app*` app records yet; Vercel still needs deployment;
  Apple Developer/App Store Connect records and fresh-install deep-link QA still
  need to happen after those external pieces.
- Verification caveat: `flutter analyze` still exits non-zero with 107
  pre-existing issues in assessment/training files; none are from the files
  changed for this item.

# P0.1 (3rd checkbox): Convert hand-run RLS scripts into versioned migrations

Session 2026-07-02. Rule applied: "the live DB is the fact; the repo gets
fixed to match reality." Completed — see review below.

## Steps

- [x] 1. Read-only dump of live policy state (pg_policies + rls flags) for the
      13 core tables via Management API — policy metadata only, no user rows.
- [x] 2. Diff live state vs. hand-run scripts (`rls_apply.sql`,
      `journal_entries_migration.sql`) and vs. the migrations pipeline.
- [x] 3. Check remote migration history → `supabase_migrations.schema_migrations`
      does not exist remotely; every past migration was SQL-Editor-applied.
- [x] 4. Write `supabase/migrations/20260702_rls_baseline_core_tables.sql`
      (idempotent; encodes live reality; drops policy names superseded by the
      "cj:" set; includes journal updated_at trigger).
- [x] 5. Handle untracked `20260513_enable_rls_postgis_spatial_ref_sys.sql` —
      it broke replay (not owner of extension table, SQLSTATE 42501, plus
      duplicate version 20260513). Made it permission-safe (EXCEPTION handler,
      NOTICE + skip) and renamed to `2026051301_…` for a unique version.
- [x] 6. Fix second pre-existing replay blocker: `20260601_admin_audit_events.sql`
      sorted after dependent `2026060102_admin_attribution_delete_behavior.sql`
      → `git mv` to `2026060100_admin_audit_events.sql`.
- [x] 7. Verify: `supabase db reset --local` replays all migrations green;
      identical dump query against replayed-local vs. live → only diff is the
      redundant legacy policy "Users manage own journal" (live-only), which
      the new migration intentionally drops.
- [x] 8. Tick backlog checkbox with evidence; add gated follow-up item
      (apply 20260702 on live via SQL Editor).

## Review

- New: `supabase/migrations/20260702_rls_baseline_core_tables.sql` — RLS
  baseline for profiles, enrollments, intake_assessments,
  completion_questionnaires, training_sessions, progress_entries,
  mood_checkins, journal_entries, trainer_client_relationships, access_codes
  (deny-all), device_tokens, user_consents, appointments (incl. the
  live-only "Trainees confirm own appointments" policy that existed in no
  script) + journal updated_at trigger.
- Fixed: `2026051301_enable_rls_postgis_spatial_ref_sys.sql` (was untracked
  in-flight work; permission-safe + unique version).
- Fixed: `2026060100_admin_audit_events.sql` (replay order).
- Verified: full local replay green; local-vs-live policy diff clean modulo
  the intended legacy-policy drop.
- NOT done (gated): applying 20260702 to the live DB. Remote has no migration
  history table; `db push` known to hang against the pooler → SQL Editor is
  the apply path.

# P0.3 + P0.5 (same session, 2026-07-02)

- [x] P0.3 fail-closed CRON_SECRET in both reminder functions (`9a0f565`);
      deno test 13/13, deno check error count unchanged (9 pre-existing).
      Deploy of both functions ⛔ gated — batch with P0.2 deploy.
- [x] P0.5 backup exclusion (`c654998`): iOS `local_store/` dir +
      `corejourney/backup_exclusion` channel + legacy file migration;
      Android `allowBackup="false"`. Verified: analyze clean, new tests 3/3,
      core suite 83/83, iOS sim + Android dev builds green, merged manifest
      carries `allowBackup="false"`.
- [x] P0.5 consent wording DE+EN corrected (`f68d476`) — no more encryption
      overclaim.
- [x] P0.5 account-deletion wipe: verified already implemented (delete_user
      RPC → signOut → clearUserData wipes all 8 user tables + session).
- Dirty-file discipline: AndroidManifest.xml and consent_screen.dart carry
  rebrand hunks — only my hunks were staged (git apply --cached with filtered
  patches); rebrand hunks remain uncommitted for P1.1.
