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

1. P1.2 is ~done. ONE small on-device check remains: register a throwaway account and **tap the confirmation link on the iPhone** to prove the `/auth/confirm` universal link opens the app (everything else in the QA script passed 2026-07-04; the confirm link was only exercised via a browser temp-email so far). Note: Supabase "Confirm email" is now ON (founder enabled it 2026-07-04) — every new signup now requires a real email click, so this path matters at launch.
2. Founder go pending (asked 2026-07-04): delete the two orphaned secrets `AGARO-APP-ID` (typo'd duplicate of `AGORA_APP_ID`, identical digest) and `BOT-USER-ID` (bot neutralized) — repo-wide grep confirms nothing reads either name (P0.2 optional cleanup).
3. Content requests to Sina are in flight (founder, 2026-07-03): adult questionnaire + videos (P2.A/B) and the top-20–30 forum Q&As for the new FAQ area (P2.C). When any of it lands, P2 jumps the queue.

*(2026-07-04: on-device QA on the fresh release dev build. Fixed two launch blockers found live: a fresh-install startup crash from a router redirect loop (`66958f0`) and a signup "something went wrong" error that appeared once email confirmation was enabled (`264e2f0`). Auth-config PATCH from the prior session corroborated in the field (emails link to reflexjourney.app, no dead corejourney.care page). Password reset — in-app and browser — both verified working on device.)*

---

## P0 — Security & compliance blockers (before ANY public launch)

### P0.1 Verify RLS is actually enabled on the live database ⚠️ HIGHEST RISK
The 10 oldest core tables (`profiles`, `enrollments`, `intake_assessments`, `completion_questionnaires`, `training_sessions`, `progress_entries`, `mood_checkins`, `journal_entries`, `trainer_client_relationships`, `access_codes`) get **no RLS from the migrations pipeline** — their protection lives only in hand-run scripts (`supabase/rls_apply.sql`, `supabase/schema.sql`, `supabase/journal_entries_migration.sql`). If those were never pasted into the SQL Editor, any logged-in user can read/write other users' health data.
- [x] Run the read-only RLS verification script from the 2026-06-18 security audit (project `sxvpiggednbftfqeokyd`). ✅ 2026-07-02 — ran `rls_verify.sql` queries via Management API → all 37 public tables `rls_enabled = true` except `spatial_ref_sys` (PostGIS extension table, no user data, expected). All 10 sensitive tables have the expected owner/trainer policies. `access_codes` has RLS on with zero policies = deny-all for clients (service-role-only access, locked down).
- [x] Fix any table showing `rls_enabled = false` immediately. ✅ 2026-07-02 — none found; nothing to fix.
- [x] Convert the hand-run RLS scripts into proper timestamped migrations so repo and DB can never silently diverge again. ✅ 2026-07-02 — added `supabase/migrations/20260702_rls_baseline_core_tables.sql` encoding the live pg_policies state (dumped via Management API) for all 13 core tables incl. journal trigger; `supabase db reset --local` replays green from the baseline; diff of replayed-local vs. live policy dump → identical except the redundant legacy policy "Users manage own journal", which the migration intentionally drops. Replay had two pre-existing blockers, both fixed: `20260513_enable_rls_postgis_spatial_ref_sys.sql` failed (not owner of extension table + duplicate version 20260513) → now permission-safe and renamed `2026051301_…`; `20260601_admin_audit_events.sql` sorted after its dependent `2026060102_…` → renamed `2026060100_…`.
- [x] Apply `20260702_rls_baseline_core_tables.sql` to the live DB. ✅ 2026-07-03 — applied via Management API on founder go; post-apply policy dump diffed against the migration-replayed local state → **identical** (only change: redundant "Users manage own journal" policy dropped). Note: the remote has **no** `supabase_migrations.schema_migrations` table at all — all past migrations were hand-applied; `db push` has never run (and is known to hang against the pooler). Seeding remote migration history is an optional later cleanup.

### P0.2 Neutralize the exposed chat-triage-bot endpoint (scope changed 2026-07-03)
Confirmed vulnerability: unauthenticated privileged write — anyone with the function URL can inject bot messages into any private chat (live function predates the auth fix).
**Decision 2026-07-03 (founder + analysis):** the bot is not launched. It was never a reviewed product feature — live DB shows 0 bot messages ever; its no-match path auto-replies "Ich habe deine Frage an deinen Trainer weitergeleitet" backed by the FCM *legacy* HTTP API, which Google shut down in 2024, so the promise would be false; seeded FAQ copy needs product/legal review. P0.2 therefore means: remove the privileged endpoint, don't fix-and-ship the bot.
- [x] Review + commit the fixed function. ✅ 2026-07-02 — committed as `1d453ca` (401 without JWT, 403 without channel membership via `chat_channel_members`). Superseded by the neutralization below but kept in history.
- [x] Verify the chat bot secret names. ✅ 2026-07-02 — `supabase secrets list`: `BOT_USER_ID` absent, `BOT-USER-ID` present; `AGARO-APP-ID` has the same digest as `AGORA_APP_ID` (typo'd duplicate).
- [x] Neutralize in code. ✅ 2026-07-03 — committed `2849cc7`: app no longer invokes `chat-triage-bot` on sendMessage (direct trainer chat unchanged); function replaced by a stub with no service-role client, no DB access, no secrets, answering 410 to fire-and-forget calls from app builds ≤ v1.0.5. flutter analyze clean on touched file, deno check passes, chat tests 19/19. `BOT_USER_ID` no longer needs to be created.
- [x] Deploy the stubbed function. ✅ 2026-07-03 — deployed on founder go with default JWT verification (stricter than the old `--no-verify-jwt` deployment).
- [x] Smoke-test after deploy. ✅ 2026-07-03 — unauth POST → 401 (gateway); POST with valid anon JWT → 410 `{"error":"chat-triage-bot is disabled"}`; `chat_messages` count with `is_bot_response = true` → 0. The vulnerable privileged endpoint no longer exists.
- [ ] Optional gated cleanup (batch with any secret change): remove the typo'd duplicate `AGARO-APP-ID` after confirming nothing reads it; `BOT-USER-ID` can also be removed once the stub is deployed (nothing reads it anymore).
- [ ] Post-launch (parked): if a chatbot becomes a product goal, plan it properly — reviewed copy, working notification path (FCM HTTP v1), and content gating. The 4 seeded `bot_faqs` rows are unused once the stub is live; deleting them is optional gated SQL.

### P0.3 Cron secret hardening
Both reminder functions read `Deno.env.get('CRON_SECRET') ?? ''` — if the secret is unset, an empty header passes.
- [x] Confirm `CRON_SECRET` is set: ✅ 2026-07-02 — `supabase secrets list` shows `CRON_SECRET` present (value/strength not printable; if in doubt, rotate to a fresh 32+ char random value — gated action).
- [x] Optional hardening: fail closed in code when the env var is missing. ✅ 2026-07-02 — committed `9a0f565`; both reminder functions now reject when `CRON_SECRET` is unset (deno test 13/13, deno check error count unchanged vs HEAD).
- [x] Deploy the hardened reminder functions (`schedule-training-reminders`, `send-notification-jobs`). ✅ 2026-07-03 — deployed on founder go with `--no-verify-jwt` (cron calls authenticate via `x-cron-secret`). Smoke: POST without secret → 401 `{"error":"unauthorized"}` on both; first post-deploy cron tick (15:30 UTC) ran `succeeded` with HTTP 200 responses recorded in `net._http_response`.

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
- [x] Review the full diff, split into sensible commits (rebrand vs. security fix), commit. ✅ 2026-07-02 — reviewed all 82 changed lines; committed as `88186dd` (identity + deep links), `cfa96ff` (copy/l10n/export artifacts; generated l10n verified identical to fresh `flutter gen-l10n`), `1077e02` (behavioral: internal tester gate now requires `@reflexjourney.de` emails — old `@corejourney.dev` accounts lose dev-tools access), `d54056c` (web/scripts/CI), `9f02462` (CLI version marker, tracked by convention). Stale-domain grep for `corejourney.care`/`corejourney.dev` over lib/ios/android/web/public/scripts/CI → zero hits. Working tree is clean. Build evidence: iOS sim + Android dev builds and 83/83 core tests ran green with these changes in tree earlier the same session.

### P1.2 "Category C" identity work (consciously deferred in June)
- [x] Bundle/application ID → `de.reflexjourney.app` (iOS + Android, all flavors). ✅ 2026-07-02 — Android base `applicationId`/namespace is `de.reflexjourney.app` with `.dev`/`.staging` suffixes; `flutter build apk --flavor development -t lib/main_development.dart --debug` built `app-development-debug.apk`, and the merged manifest reports package `de.reflexjourney.app.dev` + activity `de.reflexjourney.app.MainActivity`. iOS now has real dev/staging/prod build configs; `pod install` runs warning-free; `flutter build ios --flavor development -t lib/main_development.dart --debug --simulator` built with `CFBundleIdentifier = de.reflexjourney.app.dev`; `flutter build ios --flavor production -t lib/main_production.dart --release --no-codesign` built with `CFBundleIdentifier = de.reflexjourney.app`.
- [x] Add local `.well-known/apple-app-site-association` and `.well-known/assetlinks.json` to `reflexjourney-app-site/`. ✅ 2026-07-02 — added AASA entries for Team ID `5X6VFP7F58` + `de.reflexjourney.app`/`.staging`/`.dev`, Android asset links for all three package IDs using the release signing SHA-256 fingerprint, and `vercel.json` JSON content-type headers; `jq empty` validates all three files.
- [x] Deploy `reflexjourney-app-site/` to Vercel and verify the `.well-known` URLs. ✅ 2026-07-03 — deployed via Vercel CLI (founder go, "lets go" session); live checks: AASA and `assetlinks.json` both return 200 with JSON content type and the expected app/package IDs (`5X6VFP7F58.de.reflexjourney.app[.dev/.staging]` / `de.reflexjourney.app[.dev/.staging]`); auth pages `/auth/reset-password` and `/auth/confirm` still return 200.
- [x] Align Firebase project IDs / FCM config with the new bundle IDs. ✅ 2026-07-03 — created 6 app records in `corejourney-prod` via Firebase CLI (Android + iOS for base/.dev/.staging); committed `eeeb8ed`: `firebase_options.dart` is now environment-aware (dev builds → DEV records, staging/prod → production records; staging boots as production env, own records exist for later); deleted dead `google-services.json` + `GoogleService-Info.plist` (no gradle plugin, no Xcode reference — Firebase initializes from Dart options only). Android dev APK + iOS dev simulator builds green after deletion.
- [x] Upload the APNs auth key to the three new iOS app records in the Firebase console (Project settings → Cloud Messaging → each iOS app). ✅ 2026-07-03 — founder located the existing `AuthKey_3UF24376W3.p8` (Key ID `3UF24376W3`, Team ID `5X6VFP7F58`, confirmed still enabled for APNs, team-scoped/all-topics, Sandbox & Production) and uploaded it to all three iOS app records (prod/dev/staging) in `corejourney-prod`.
- [x] Apple Developer / App Store Connect: register bundle ID `de.reflexjourney.app` (+ `.dev`/`.staging` App IDs with Associated Domains capability) and create the ASC app record under the new ID. ✅ 2026-07-03 — registered all three App IDs (`de.reflexjourney.app`, `.dev`, `.staging`) in Apple Developer, each with Associated Domains + Push Notifications capabilities enabled. ASC app record (TestFlight) intentionally deferred — not requested yet.
- [ ] Optional, low priority: Dart package rename `corejourney` → app-neutral name.
- [x] Pre-QA audit of the auth link flows (found + fixed the app-side blocker). ✅ 2026-07-03 — read live auth config via Management API + traced app deep-link code: (a) recovery emails link to `reflexjourney.app/auth/reset-password?token_hash=…`, which the new app intercepts via universal links (AASA + Android intent filter both claim `/auth/*`) but could not process — `getSessionFromUrl` doesn't understand `token_hash` → silent failure. Fixed in commit `58827aa`: `verifyOTP` for recovery and `/auth/confirm` links, legacy `getSessionFromUrl` kept as fallback; 6 new unit tests, full suite 200/200, analyze clean. (b) live `site_url` is still `https:corejourney.care` — old brand AND malformed — so signup-confirmation emails verify server-side but strand the user on a dead URL. (c) redirect allowlist lacks `/auth/confirm`.
- [x] Apply the auth-config fix: `site_url` → `https://reflexjourney.app`, allowlist += `https://reflexjourney.app/auth/confirm`, confirmation email template → `https://reflexjourney.app/auth/confirm?token_hash={{ .TokenHash }}&type=signup`. ✅ 2026-07-04 — applied + verified via the live Management API PATCH in the prior session (payload/rollback: `auth-config-patch-2026-07-03.json` / `auth-config-rollback-2026-07-03.json`). Behaviourally corroborated in this session's on-device QA: confirmation + reset emails now link to `reflexjourney.app` and no dead `corejourney.care` page appeared anywhere.
- [x] Install the fresh release dev build on the iPhone. ✅ 2026-07-04 — `flutter install --release --flavor development` to device `00008140-000671E10AEB001C`; old version uninstalled, new build deployed. Reinstalled again after the signup-UX fix below.
- [x] Fresh-install startup crash fixed (router deadlock). ✅ 2026-07-04 — on-device QA of a fresh logged-out install crashed with `GoException: redirect loop detected /login => /language => /language => /login`. Root cause: `app_router.dart` built `isPublicRoute` without the language-selection route, so a logged-out user with no saved language got bounced `/language → /login → /language` forever (hit every genuinely new user; a logged-in tester never triggered it). Fixed by adding `Routes.languageSelection` to `isPublicRoute` (commit `66958f0`). Verified on device: app now opens to the language/login screen with no crash and the tester logged in.
- [x] Signup showed a generic error instead of "check your email" once confirmation was enabled — fixed. ✅ 2026-07-04 — the on-device confirm-email toggle was found OFF (new accounts were auto-confirmed, no email ever sent); founder turned it ON. Registering then showed `errorGeneric` because the signup screen assumed sign-up returns an active session (built for the old auto-confirm world) and tried to enter the dashboard. Fixed so `signUp` reports confirmation-pending up through the notifier and the screen switches to sign-in + shows `signUpConfirmEmailSent` (commit `264e2f0`; `flutter analyze` clean, 200/200 tests green). On-device retest: friendly "check your email" message shown, account created, email sent, confirmation + sign-in worked.
- [~] Verify deep links + password reset + confirm-signup end-to-end on the fresh install (QA script in `tasks/todo.md`). PARTIAL 2026-07-04. Passed on device: fresh-install no longer crashes → language/login screen; in-app password reset (recovery link opened the **app**, in-app new-password screen, re-login worked); browser password reset (fresh link opened the reflexjourney.app page, reset worked); signup end-to-end (account created, confirmation email sent, confirmation + sign-in worked, **no dead corejourney.care page**). NOT YET VERIFIED ON DEVICE: tapping the **confirmation link opens the app** — founder confirmed the signup link via a browser temp-email, not by tapping it on the iPhone, so the universal-link app-open for `/auth/confirm` is unproven (the `/auth/reset-password` universal link *did* open the app, which is good corroboration). One throwaway email + one tap on the iPhone would close this.

### P1.3 Repo hygiene (moved from P0 2026-07-02 — not a launch security blocker, just cheap cleanup)
- [x] Remove `.env.staging` from git tracking (contains only client-public keys, but poor hygiene). ✅ 2026-07-02 — `a4036c9`: `git rm --cached` + `.gitignore` entry; file stays on disk. (Old values remain in git history — acceptable for client-public keys per the audit.)
- [x] Delete vestigial Firestore/Firebase Hosting config (`firebase.json` hosting parts, `firestore.rules`, `firestore.indexes.json`) — app uses FCM only. ✅ 2026-07-02 — `f0d88ef`: verified no `cloud_firestore` dependency and zero Firestore usage in lib/; removed both firestore files and the `firestore`/`hosting` sections; FlutterFire config kept; JSON validity checked.

### P1.4 Infra already DONE (do not redo)
- Resend sending domain `send.reflexjourney.de` verified; Supabase custom SMTP live.
- `reflexjourney.app` static auth site on Vercel; password-reset (`/auth/reset-password`) and confirm-signup (`/auth/confirm`) pages using token_hash, verified working 2026-06-22.
- Supabase Site URL + redirect allowlist updated; old corejourney entries removed. *(Correction 2026-07-03: live config still had `site_url = https:corejourney.care` — malformed, old brand — and no `/auth/confirm` allowlist entry, so this line was wrong at the time. Resolved: the gated PATCH was applied in the prior session and corroborated in on-device QA 2026-07-04 — see the ticked P1.2 auth-config item above.)*

---

## P2 — Content integration ⛔ blocked: Sina delivery

Expected deliverables (per CONTENT-STATUS and 2026-06-24 session):
**A) Adult questionnaire** — revised `erw` questions + question→reflex mapping (mapping currently missing entirely).
**B) Final training videos** — selected/cut from the filmed footage, plus final exercise pictures.
**C) FAQ/orientation content** (added 2026-07-03, founder decision) — the 20–30 most common questions + answers from Sina's forum, as the content base for an in-app help area.

- [ ] A: Validate content (scoring rules per `specs/reflexprofil_planung.md`), seed into the questionnaire system following the child-questionnaire pattern (`reflex_profile_questionnaire_v1` migration as reference).
- [ ] B: Upload media to Supabase Storage, populate the remote media URL columns (pipeline built 2026-05-30: `ExerciseImageWidget`/`ExerciseVideoWidget` URL-or-asset resolution, Drift cache sync).
- [ ] Verify on-device: media loads remotely, falls back to assets offline.
- [ ] C (Stufe 1): Build a curated, searchable FAQ/orientation section in the app from Sina's reviewed forum Q&As. **Not launch-blocking** — ships with or shortly after launch once content arrives. Every answer gets a copy review for therapy/medical-claim language before seeding. No bot, no free-text generation — static reviewed content only. ⛔ blocked: content (founder requested forum access / top-20–30 Q&As from Sina, 2026-07-03).
- [ ] Note for scale (from architecture audit): video egress is the first real cost line; CDN in front of Storage is the planned move at ~1k users — not now.

---

## P3 — Launch operations

- [ ] Supabase Free → Pro before real users (removes 7-day-pause risk + egress headroom). Trigger per audit: at latest with first real/paying user.
- [x] Run `make release-readiness-mobile` + fix everything. ✅ 2026-07-04 — target existed only in docs, never in the Makefile (git log -S over full history); implemented it (`6991e44`: flutter analyze --no-fatal-infos + full test suite). Run found 0 errors / 4 warnings / 103 deprecation infos; the 4 warnings were dead code, removed in `b4b2be7` (incl. a never-called trainer-share prompt superseded by the result screen). Re-run → exit 0, analyze error/warning-free, 200/200 tests passed. The 103 infos are non-blocking deprecation cleanups (mostly `withOpacity`→`withValues`), left for post-launch.
- [ ] Full manual device QA per `docs/RELEASE_READINESS_CHECKLIST.md` (hands-free, reminders v2, offline sync, dashboard) on iOS + Android.
- [x] Ensure `APP_ENVIRONMENT` Edge Function secret is set to the intended production value (was flipped during reminder testing). ✅ 2026-07-04 — `supabase secrets list` digest for `APP_ENVIRONMENT` equals sha256("production") (verified by hashing candidate values locally; secret value itself never printed). Code expects exactly `production` (both reminder functions).
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

- Chatbot feature: neutralized for launch 2026-07-03 (see P0.2) — app no longer calls it, endpoint stubbed. The user-facing need it hinted at is now properly scoped: **Stufe 1** = curated FAQ section (P2.C, content from Sina's forum). Post-launch roadmap: **Stufe 2** = guided question flow (free-text input matched against reviewed FAQs only, with real trainer forwarding rebuilt on FCM HTTP v1); **Stufe 3** = content-gated chatbot (own project, product + legal review). The 4 seeded `bot_faqs` rows sit unused in the DB; reuse or delete when P2.C is built.
- Old repos: `/Users/alexandermessinger/dev/corejourney` (obsolete) and `_ARCHIVED_corejourney_old` — consider archiving/removing to reduce confusion.
- Outer repo (`claudvibes/corejourney`) has its own uncommitted admin-web changes + untracked specs — needs a housekeeping commit.
