# Reflex Journey — Launch Readiness Backlog

Status: Active (created 2026-07-02)
Worked via `docs/LAUNCH_MASTER_PROMPT.md` — paste that prompt into a fresh Claude Code session; it reads this file as the single source of truth.
Decision: **Launch the existing app, rebranded to Reflex Journey.** The clean-rebuild planning package in `/Users/alexandermessinger/dev/ReflexJourney/docs/specs/reflex-journey-mvp/` is NOT the launch vehicle; it becomes the post-launch quality/handoff roadmap (see P4).

Sources consolidated here:
- Security/GDPR audit (Claude session 2026-06-18): Edge Function authorization sweep, RLS gap analysis, local-data findings
- Scalability/maintainability audit (Claude session 2026-06-18): staged scaling plan, do-now/do-later list
- Rebrand session (2026-06-19 → 06-22): infra done, app-level work uncommitted, "Category C" deferred
- `docs/RELEASE_READINESS_CHECKLIST.md`, `docs/HANDOFF_STATUS.md`
- Content status: `/Users/alexandermessinger/dev/ReflexJourney/docs/specs/reference/CONTENT-STATUS.md`

## Next up (update at the end of every session)

1. Founder-gated batch (everything actionable in P0 now waits on this): deploy `chat-triage-bot` (P0.2, incl. `BOT_USER_ID` secret check), deploy the two hardened reminder functions (P0.3), and run `supabase/migrations/20260702_rls_baseline_core_tables.sql` in the SQL Editor (P0.1 follow-up; only live effect is dropping the redundant legacy policy "Users manage own journal").
2. Meanwhile: P1.1 — review and commit the in-flight rebrand working tree (~36 files, now rebrand-only after this session's hunk-level commits).

---

## P0 — Security & compliance blockers (before ANY public launch)

### P0.1 Verify RLS is actually enabled on the live database ⚠️ HIGHEST RISK
The 10 oldest core tables (`profiles`, `enrollments`, `intake_assessments`, `completion_questionnaires`, `training_sessions`, `progress_entries`, `mood_checkins`, `journal_entries`, `trainer_client_relationships`, `access_codes`) get **no RLS from the migrations pipeline** — their protection lives only in hand-run scripts (`supabase/rls_apply.sql`, `supabase/schema.sql`, `supabase/journal_entries_migration.sql`). If those were never pasted into the SQL Editor, any logged-in user can read/write other users' health data.
- [x] Run the read-only RLS verification script from the 2026-06-18 security audit (project `sxvpiggednbftfqeokyd`). ✅ 2026-07-02 — ran `rls_verify.sql` queries via Management API → all 37 public tables `rls_enabled = true` except `spatial_ref_sys` (PostGIS extension table, no user data, expected). All 10 sensitive tables have the expected owner/trainer policies. `access_codes` has RLS on with zero policies = deny-all for clients (service-role-only access, locked down).
- [x] Fix any table showing `rls_enabled = false` immediately. ✅ 2026-07-02 — none found; nothing to fix.
- [x] Convert the hand-run RLS scripts into proper timestamped migrations so repo and DB can never silently diverge again. ✅ 2026-07-02 — added `supabase/migrations/20260702_rls_baseline_core_tables.sql` encoding the live pg_policies state (dumped via Management API) for all 13 core tables incl. journal trigger; `supabase db reset --local` replays green from the baseline; diff of replayed-local vs. live policy dump → identical except the redundant legacy policy "Users manage own journal", which the migration intentionally drops. Replay had two pre-existing blockers, both fixed: `20260513_enable_rls_postgis_spatial_ref_sys.sql` failed (not owner of extension table + duplicate version 20260513) → now permission-safe and renamed `2026051301_…`; `20260601_admin_audit_events.sql` sorted after its dependent `2026060102_…` → renamed `2026060100_…`.
- [ ] Apply `20260702_rls_baseline_core_tables.sql` to the live DB via SQL Editor (gated: mutating SQL — only effective change is dropping the redundant "Users manage own journal" policy; everything else verified already live). Note: the remote has **no** `supabase_migrations.schema_migrations` table at all — all past migrations were hand-applied; `db push` has never run (and is known to hang against the pooler). Seeding remote migration history is an optional later cleanup.

### P0.2 Deploy the chat-triage-bot authorization fix
Confirmed vulnerability: unauthenticated privileged write — anyone with the function URL can inject bot messages into any private chat. **The fix (JWT check + channel-membership check) is already written but uncommitted** in `supabase/functions/chat-triage-bot/index.ts`.
- [x] Review + commit the fixed function. ✅ 2026-07-02 — committed as `1d453ca` (401 without JWT, 403 without channel membership via `chat_channel_members`).
- [ ] Deploy the fixed function. ⛔ blocked: founder go (deploys are gated).
- [ ] Verify/set the correct secret names before or with the deploy (secret changes = gated): the function reads `BOT_USER_ID` (underscores) but `supabase secrets list` shows `BOT-USER-ID` (hyphens) — if the underscore variant is missing, bot inserts fail at runtime. Also `AGARO-APP-ID` looks like a typo'd duplicate of `AGORA_APP_ID`. (⚠️ Found 2026-07-02.)
- [ ] Smoke-test after deploy: request without auth → 401; non-member → 403; member → works.

### P0.3 Cron secret hardening
Both reminder functions read `Deno.env.get('CRON_SECRET') ?? ''` — if the secret is unset, an empty header passes.
- [x] Confirm `CRON_SECRET` is set: ✅ 2026-07-02 — `supabase secrets list` shows `CRON_SECRET` present (value/strength not printable; if in doubt, rotate to a fresh 32+ char random value — gated action).
- [x] Optional hardening: fail closed in code when the env var is missing. ✅ 2026-07-02 — committed `9a0f565`; both reminder functions now reject when `CRON_SECRET` is unset (deno test 13/13, deno check error count unchanged vs HEAD).
- [ ] Deploy the hardened reminder functions (`schedule-training-reminders`, `send-notification-jobs`). ⛔ blocked: founder go (deploys are gated) — batch with the P0.2 deploy.

### P0.4 Supabase region (one-way door)
- [x] Confirm the Supabase project region is in the EU. ✅ 2026-07-02 — `supabase projects list` → West EU (Ireland).

### P0.5 Local data protection on device
- [x] Exclude the Drift SQLite DB and auth-session file from device backups (iOS `NSURLIsExcludedFromBackupKey`, Android `allowBackup`/`fullBackupContent`). ✅ 2026-07-02 — committed `c654998`: iOS moves the DB into a backup-excluded `local_store/` dir via new platform channel (legacy files migrated on first launch); Android `allowBackup="false"` (covers DB + shared-prefs session). Verified: analyze clean, channel tests 3/3, core suite 83/83, iOS sim build OK, Android build OK with `allowBackup="false"` in the merged manifest. On-device spot-check of the flag rides with the P3 manual QA pass.
- [ ] iOS auth session: supabase session sits in NSUserDefaults, whose plist cannot be reliably backup-excluded (system rewrites it). Mitigation is the existing roadmap item below (move session to Keychain). Post-launch acceptable.
- [x] Fix the consent screen's false claim of an "encrypted SQLite database" (`consent_screen.dart` ~line 574) — either make the wording accurate or ship SQLCipher. ✅ 2026-07-02 — committed `f68d476`; DE+EN copy now claims only what is true (app-private DB, OS device encryption, excluded from backups). No therapy/medical language touched.
- [x] Account deletion must also wipe the local DB/session (reuse the sign-out wipe routine in `app_database.dart`). ✅ 2026-07-02 — verified already implemented, no code needed: `profile_screen.dart` `_confirmDeleteAccount` → `rpc('delete_user')` then `signOut()`; `AuthNotifier.signOut()` (auth_provider.dart:66) calls `clearUserData()` first, which deletes all 8 user tables (only shared `exercises` content kept), then Supabase sign-out clears the session.
- [ ] Roadmap (post-launch acceptable): SQLCipher at-rest encryption, key + auth session in Keychain/Keystore.

### P0.6 Legal/compliance paperwork (lawyer, not code) ⛔ blocked: lawyer
- [ ] Privacy policy finalized under the Reflex Journey brand; consent text matches actual processing (analytics/Crashlytics are currently disabled — don't claim them).
- [ ] DPAs with Supabase, Agora, Google (FCM); records of processing.

---

## P1 — Finish the rebrand

### P1.1 Commit the in-flight rebrand working tree
~38 modified files, uncommitted since ~2026-06-22: display name, `applinks:reflexjourney.app` entitlement, `reflexjourney` URL scheme, l10n strings, privacy.html, permission-usage strings, plus the chat-triage-bot fix (P0.2).
- [ ] Review the full diff, split into sensible commits (rebrand vs. security fix), commit.

### P1.2 "Category C" identity work (consciously deferred in June)
- [ ] Bundle/application ID → `de.reflexjourney.app` (iOS + Android, all flavors).
- [ ] Host `.well-known/apple-app-site-association` and `.well-known/assetlinks.json` on `reflexjourney.app` (the static site lives in the outer repo at `reflexjourney-app-site/`, deployed on Vercel).
- [ ] Align Firebase project IDs / FCM config with the new bundle IDs.
- [ ] Optional, low priority: Dart package rename `corejourney` → app-neutral name.
- [ ] Verify deep links + password reset + confirm-signup end-to-end on a fresh install after the ID change.

### P1.3 Repo hygiene (moved from P0 2026-07-02 — not a launch security blocker, just cheap cleanup)
- [ ] Remove `.env.staging` from git tracking (contains only client-public keys, but poor hygiene).
- [ ] Delete vestigial Firestore/Firebase Hosting config (`firebase.json` hosting parts, `firestore.rules`, `firestore.indexes.json`) — app uses FCM only.

### P1.4 Infra already DONE (do not redo)
- Resend sending domain `send.reflexjourney.de` verified; Supabase custom SMTP live.
- `reflexjourney.app` static auth site on Vercel; password-reset (`/auth/reset-password`) and confirm-signup (`/auth/confirm`) pages using token_hash, verified working 2026-06-22.
- Supabase Site URL + redirect allowlist updated; old corejourney entries removed.

---

## P2 — Content integration ⛔ blocked: Sina delivery

Expected deliverables (per CONTENT-STATUS and 2026-06-24 session):
**A) Adult questionnaire** — revised `erw` questions + question→reflex mapping (mapping currently missing entirely).
**B) Final training videos** — selected/cut from the filmed footage, plus final exercise pictures.

- [ ] A: Validate content (scoring rules per `specs/reflexprofil_planung.md`), seed into the questionnaire system following the child-questionnaire pattern (`reflex_profile_questionnaire_v1` migration as reference).
- [ ] B: Upload media to Supabase Storage, populate the remote media URL columns (pipeline built 2026-05-30: `ExerciseImageWidget`/`ExerciseVideoWidget` URL-or-asset resolution, Drift cache sync).
- [ ] Verify on-device: media loads remotely, falls back to assets offline.
- [ ] Note for scale (from architecture audit): video egress is the first real cost line; CDN in front of Storage is the planned move at ~1k users — not now.

---

## P3 — Launch operations

- [ ] Supabase Free → Pro before real users (removes 7-day-pause risk + egress headroom). Trigger per audit: at latest with first real/paying user.
- [ ] Run `make release-readiness-mobile` + fix everything.
- [ ] Full manual device QA per `docs/RELEASE_READINESS_CHECKLIST.md` (hands-free, reminders v2, offline sync, dashboard) on iOS + Android.
- [ ] Ensure `APP_ENVIRONMENT` Edge Function secret is set to the intended production value (was flipped during reminder testing).
- [ ] Store metadata under Reflex Journey brand: name, screenshots, age rating, description — **no therapy/medical-claim language**.
- [ ] TestFlight (see `docs/TESTFLIGHT_QUICKSTART.md`) → staged rollout.
- [ ] Crash reporting decision: Sentry (or re-enable Crashlytics) so bugs surface before users report them.
- [ ] Payments: RevenueCat is coded but disabled. Decide model before enabling paid tiers (in-app purchase is mandatory for digital subscriptions; Stripe not allowed for in-app digital goods). Not a launch blocker if launch is free.

---

## P4 — Maintainability & handoff (the actual long-term goal)

Owner goal: stable, scalable, secure, easy to maintain, documented well enough that another person can take over.

The 2026-06-18 architecture audit's verdict: the codebase is substantially better than "vibecoded" fear suggests (220 Dart files, RLS model, offline-first done correctly, edge functions properly gated except the one fixed in P0.2). The path to handoff quality is **incremental hardening of this repo**, not a rewrite. The ReflexJourney MVP package becomes the refactor/standards roadmap.

- [ ] ARCHITECTURE.md: system map (Flutter offline-first + Drift/sync outbox + Supabase + edge functions + admin-web + FCM + Agora), request flows, data/privacy map. Much of this text already exists in the 2026-06-18 audit output — harvest it.
- [ ] Document the sync engine (identified as the single biggest maintenance liability): job types, coalescing, retry/drop rules, how to debug via the Local Sync Diagnostics dev tools.
- [ ] RLS regression test suite runnable in CI. (The migrations conversion itself is tracked as P0.1's third checkbox — not duplicated here.)
- [ ] CI pipeline: analyze + tests on every push (GitHub Actions workflow exists — verify it covers the current suite).
- [ ] Adopt the adapter-boundary standard from the MVP package incrementally (repositories isolate Supabase access) — opportunistic, per feature touched, not big-bang.
- [ ] Admin-web: close the client-side audit gap (move destructive mutations into RPCs/Edge Functions) — carried from the MVP package Phase 10.
- [ ] HANDOFF_STATUS.md refresh: it currently points at the obsolete `/dev/corejourney` paths.

---

## Open questions / parked

- Chatbot feature (planned in the 2026-06-18 session as safe, content-gated triage bot): current bot is keyword/FAQ-based; the uncommitted auth fix touches it. Any further chatbot expansion is post-launch.
- Old repos: `/Users/alexandermessinger/dev/corejourney` (obsolete) and `_ARCHIVED_corejourney_old` — consider archiving/removing to reduce confusion.
- Outer repo (`claudvibes/corejourney`) has its own uncommitted admin-web changes + untracked specs — needs a housekeeping commit.
