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

1. **Anwalt beauftragen (P0.6 — kritischer Pfad, blockiert Store-Einreichung UND Marketing-Pilot):** ein gebündelter Auftrag — Datenschutzerklärung (App + Website + Trainer-Akquise, ggf. Waitlist), Impressumspflichten, DPAs, plus die Frage, welche Adresse/Telefonnummer öffentlich in Impressum + App-Store-Trader-Status (DSA) stehen darf. Founder 2026-07-05: besorgt dafür voraussichtlich eine eigene Telefonnummer. Siehe `docs/APPSTORE_LAUNCH_ROADMAP.md` Phase 1.1.
2. **Drei Sichtbarkeits-Entscheidungen D1–D3 (Delta-Analyse 2026-07-05):** D1 Community/Experience-Feed (P0.7), D2 Video-Calls (P0.9), D3 Trainer-Discovery (P1.5). Empfehlung: alle drei für v1 verstecken → kleinere Review-Fläche, keine Moderations-Pflichten, schlankere Privacy Labels. Details + Entscheidungsvorlage: `docs/LAUNCH_TASK_PROMPTS.md` (Block „Offene Founder-Entscheidungen“). Entsperrt T02–T06, T12, T13.
3. P1.2 is ~done. ONE small on-device check remains: register a throwaway account and **tap the confirmation link on the iPhone** to prove the `/auth/confirm` universal link opens the app (everything else in the QA script passed 2026-07-04; the confirm link was only exercised via a browser temp-email so far). Note: Supabase "Confirm email" is now ON (founder enabled it 2026-07-04) — every new signup now requires a real email click, so this path matters at launch.
4. Founder: store-listing draft (`docs/STORE_LISTING_DRAFT.md`) — Restfragen: Untertitel-Wahl + Satz-für-Satz-Copy-Freigabe. Bereits entschieden 2026-07-05 (Roadmap-Session): EN-Listing zum Launch, eigene Support-Adresse, Datenschutz-URL `/datenschutz`, Launch kostenlos, Launch mit aktuellem Content.
5. Founder go pending (asked 2026-07-04): delete the two orphaned secrets `AGARO-APP-ID` (typo'd duplicate of `AGORA_APP_ID`, identical digest) and `BOT-USER-ID` (bot neutralized) — repo-wide grep confirms nothing reads either name (P0.2 optional cleanup).
6. Content requests to Sina are in flight (founder, 2026-07-03): adult questionnaire + videos (P2.A/B) and the top-20–30 forum Q&As for the new FAQ area (P2.C). When any of it lands, P2 jumps the queue.
7. **Arbeitssystem seit 2026-07-06:** Die Launch-Tasks T01–T22 werden in `docs/LAUNCH_TASK_PROMPTS.md` getrackt (Status-Tracker + fertige Session-Prompts mit Rollen). Jede Session: Tracker lesen → nächsten nicht-blockierten Task per Prompt ausführen → Tracker UND Backlog fortschreiben. Der Backlog bleibt Single Source of Truth für WAS offen ist; der Tracker führt Ausführungsstatus + Arbeitsanweisungen.

*(2026-07-04: on-device QA on the fresh release dev build. Fixed two launch blockers found live: a fresh-install startup crash from a router redirect loop (`66958f0`) and a signup "something went wrong" error that appeared once email confirmation was enabled (`264e2f0`). Auth-config PATCH from the prior session corroborated in the field (emails link to reflexjourney.app, no dead corejourney.care page). Password reset — in-app and browser — both verified working on device.)*

---

## P0 — Security & compliance blockers (before ANY public launch)

### P0.1 Verify RLS is actually enabled on the live database ⚠️ HIGHEST RISK
The 10 oldest core tables (`profiles`, `enrollments`, `intake_assessments`, `completion_questionnaires`, `training_sessions`, `progress_entries`, `mood_checkins`, `journal_entries`, `trainer_client_relationships`, `access_codes`) get **no RLS from the migrations pipeline** — their protection lives only in hand-run scripts (`supabase/rls_apply.sql`, `supabase/schema.sql`, `supabase/journal_entries_migration.sql`). If those were never pasted into the SQL Editor, any logged-in user can read/write other users' health data.
- [x] Run the read-only RLS verification script from the 2026-06-18 security audit (project `sxvpiggednbftfqeokyd`). ✅ 2026-07-02 — ran `rls_verify.sql` queries via Management API → all 37 public tables `rls_enabled = true` except `spatial_ref_sys` (PostGIS extension table, no user data, expected). All 10 sensitive tables have the expected owner/trainer policies. `access_codes` has RLS on with zero policies = deny-all for clients (service-role-only access, locked down).
- [x] Fix any table showing `rls_enabled = false` immediately. ✅ 2026-07-02 — none found; nothing to fix.
- [x] Convert the hand-run RLS scripts into proper timestamped migrations so repo and DB can never silently diverge again. ✅ 2026-07-02 — added `supabase/migrations/20260702_rls_baseline_core_tables.sql` encoding the live pg_policies state (dumped via Management API) for all 13 core tables incl. journal trigger; `supabase db reset --local` replays green from the baseline; diff of replayed-local vs. live policy dump → identical except the redundant legacy policy "Users manage own journal", which the migration intentionally drops. Replay had two pre-existing blockers, both fixed: `20260513_enable_rls_postgis_spatial_ref_sys.sql` failed (not owner of extension table + duplicate version 20260513) → now permission-safe and renamed `2026051301_…`; `20260601_admin_audit_events.sql` sorted after its dependent `2026060102_…` → renamed `2026060100_…`.
- [x] Apply `20260702_rls_baseline_core_tables.sql` to the live DB. ✅ 2026-07-03 — applied via Management API on founder go; post-apply policy dump diffed against the migration-replayed local state → **identical** (only change: redundant "Users manage own journal" policy dropped). Note: the remote has **no** `supabase_migrations.schema_migrations` table at all — all past migrations were hand-applied; `db push` has never run (and is known to hang against the pooler). Seeding remote migration history is an optional later cleanup.
- ⚠️ Korrektur 2026-07-05 (Delta-Analyse): **`experience_shares` ist die einzige Live-Tabelle ohne jede Repo-Spur** (Tabelle + 3 Policies + RPC `moderator_delete_experience_share` existieren nur live; repo-weiter Grep über `supabase/` → 0 Treffer). Live verifiziert: `rls_enabled=true`, Policies `shares_read` (`auth.uid() IS NOT NULL`), `shares_insert`, `shares_delete_own`; FK auf `auth.users` mit ON DELETE CASCADE. Nachziehen als Baseline-Migration = Task **T08** in `docs/LAUNCH_TASK_PROMPTS.md` (P1.5, nicht launch-blocking).

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
- [ ] Privacy policy finalized under the Reflex Journey brand; consent text matches actual processing (analytics/Crashlytics are currently disabled — don't claim them; Sentry kommt dazu, siehe P3 crash-reporting decision 2026-07-05).
- [ ] DPAs with Supabase, Agora, Google (FCM); records of processing.
- [ ] Auftrags-Bündelung: der Anwaltsauftrag deckt AUCH ab — Website (Impressum, Datenschutzseite), Trainer-Akquise (UWG § 7 / DSGVO Art. 14) und, falls gebaut, die Waitlist; dazu die öffentliche Adress-/Telefonnummer-Frage (Impressum + DSA-Trader-Status). Ein Auftrag statt drei. (Roadmap 2026-07-05, Phase 1.1)

### P0.7 UGC ohne Melde-/Block-Funktion — Apple Guideline 1.2 ⚠️ NEU (Delta-Analyse 2026-07-05)
Befund: Community-Chat, DMs und Experience-Feed sind nutzergenerierte Inhalte (Freitext, für **alle** eingeloggten Nutzer lesbar — Live-Policy `shares_read: auth.uid() IS NOT NULL`; anonym möglich). Apple 1.2 verlangt vier Dinge: Inhaltsfilter, Melde-Mechanismus, Nutzer-Blocken, publizierte Kontaktinfo (developer.apple.com/app-store/review/guidelines, abgerufen 2026-07-05). Vorhanden ist nur eine Moderator-Lösch-RPC — **keins der vier nutzerseitig**. Roadmap §2/§5 kannte 1.2 nicht.
- [ ] Founder-Entscheidung **D1**: Community-Tab + Experience-Feed für v1 verstecken (Empfehlung) ODER Minimal-Moderation bauen. Details: `docs/LAUNCH_TASK_PROMPTS.md`.
- [ ] Umsetzung je nach D1: **T04** (verstecken) oder **T02+T03** (Melden + Blocken). Der Trainer-1:1-Chat braucht in beiden Fällen mindestens eine Melde-Option oder eine dokumentierte Kontakt-Alternative (Review-Notiz).

### P0.8 Consent-Screen ist die Testphasen-Fassung ⚠️ NEU (Delta-Analyse 2026-07-05)
Befund (`lib/features/consent/presentation/screens/consent_screen.dart`, ~Z. 440 ff.): Titel „Datenschutzerklärung (vorläufig)“, Zusage „für die Dauer der Testphase und bis zu 6 Monate danach“, Auftragsverarbeiter-Liste nennt **nur Supabase** (FCM/Google, Resend, ggf. Agora fehlen), keine Kinderprofil-Passage trotz `reflex_subject_profiles` mit Geburtsdatum. Das ist **App-Code-Arbeit**, kein Anwalts-Deliverable — P0.6 liefert nur den Text-Input.
- [ ] **T05**: Launch-Fassung des Consent-Screens (Struktur jetzt vorbereitbar, Finaltext nach P0.6); `kConsentVersion` bumpen → Re-Consent-Mechanik existiert bereits.

### P0.9 Video-Calls in Production funktionsunfähig ⚠️ NEU (Delta-Analyse 2026-07-05)
Befund: `AGORA_APP_ID` fehlt in `.env.prod` (Key-Namen-Check) → `video_call_screen.dart:52-68` zeigt „Konfigurationsfehler: Agora App-ID fehlt.“; der Call-Button sitzt sichtbar in der Chat-AppBar (`chat_channel_screen.dart:395`), der `IncomingCallListener` global in `app.dart:233`. Sichtbar kaputtes Feature = Guideline-2.1-Risiko.
- [ ] Founder-Entscheidung **D2**: Video-Calls für v1 verstecken (Empfehlung) ODER `AGORA_APP_ID` in Prod aufnehmen — dann muss Agora auch in Datenschutzerklärung, DPA-Liste (P0.6) und Nutrition Labels.
- [ ] Umsetzung: **T06** (verstecken, kleinster reversibler Eingriff) bzw. Konfig + Policy-Erweiterung.

### P0.10 Veraltete Datenschutz-Artefakte neutralisieren ⚠️ NEU (Delta-Analyse 2026-07-05)
Befund: `public/privacy.html` (Kontakt = private Gmail-Adresse, Stand Dez 2024, nennt weder FCM/Agora/Standort noch Kinderdaten) und `docs/privacy_policy.md` (beschreibt Isar + Firestore + Firebase Analytics — Stack existiert nicht). Hosting-Status von `public/` ungeklärt (Firebase-Hosting-Config wurde in P1.3 entfernt).
- [ ] **T07**: klären, ob eine der Alt-Policies noch irgendwo erreichbar/verlinkt ist; beide Dateien löschen oder durch Verweis auf die finale Policy ersetzen. Launch-blocking **falls** live erreichbar.

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

### P1.5 Plattform-/Store-Hygiene vor TestFlight (Delta-Analyse 2026-07-05; Prompts in `docs/LAUNCH_TASK_PROMPTS.md`)
- [ ] **T09** iOS `Info.plist`: `ITSAppUsesNonExemptEncryption=false` setzen (fehlt — verifiziert 2026-07-05); `NSLocationAlwaysAndWhenInUseUsageDescription` entfernen (nur When-In-Use wird genutzt); `NSCalendars*`-Keys entfernen (`device_calendar` ist in pubspec deaktiviert). Launch-blocking vor Build-Upload.
- [ ] **T10** AndroidManifest: `READ_CALENDAR`/`WRITE_CALENDAR` entfernen (Plugin deaktiviert; Play-Data-Safety-Reibung).
- [ ] **T11** Env-/Bundle-Hygiene: totes `TRAINER_CODE`-Relikt aus `.env.prod` löschen (wird nirgends gelesen — repo-weiter Grep 2026-07-05 — liegt aber extrahierbar in jedem Build); prüfen, ob `.env.dev` aus dem Prod-Asset-Bundle raus kann (`pubspec.yaml` Z. 104–105 bündelt beide).
- [ ] **T13** Trainer-Discovery-Entscheidung **D3**: bei aktuell 0 freigeschalteten Trainern (live, Aggregat 2026-07-05) für v1 verstecken (Empfehlung) oder bewussten Empty-State + OSM-Attribution bauen (`trainer_discovery_screen.dart:392` hat kein Attribution-Widget; OSM-Policy verlangt es).
- [ ] **T16** Build-Nummern-Bump-Prozess definieren (aktuell `1.0.5+2026051001` vom Mai; jeder ASC-Upload braucht höhere Build-Nummer).
- [ ] **T21** Trainer-Selbst-Freischaltung verifizieren: server-seitig ist die Aktivierung bereits approval-gebunden (`activate-trainer` prüft `trainer_invite_codes` mit `purpose='trainer_application_approval'` — Code-Review 2026-07-05); offen ist nur der Nachweis, dass der DEV-Bypass in Prod-Builds tot ist. (Deckt Roadmap Phase 3.8 ab.)
- [ ] **T22** Beim ersten Store-Archiv prüfen, dass `aps-environment` im signierten Build `production` ist (Datei sagt `development`; Signing ersetzt das normalerweise — unverifiziert).
- [ ] **T08** `experience_shares` als Baseline-Migration einfrieren (siehe Korrektur unter P0.1; nicht blocking).
- [ ] **T18** Firebase-Admin-Service-Account-Key (`corejourney-prod`, volle FCM-/Projektrechte) aus dem App-Root in Keychain/Passwortmanager verschieben; Rotation erwägen (gitignored, aber unverschlüsselt auf Platte; nicht blocking).

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
- [x] Store metadata — draft all text fields under the Reflex Journey brand. ✅ 2026-07-04 — wrote `docs/STORE_LISTING_DRAFT.md`: DE name/subtitle/promo/description/keywords within Apple char limits, Play short+full description, category + age-rating recommendation (Gesundheit & Fitness, 4+, NOT Kids category), URLs, and a 6-point founder-decision list; every sentence self-reviewed against the no-therapy/medical-claims rule (activity descriptions only, explicit "kein Medizinprodukt" note, no diagnosis terms in keywords).
- [ ] Store metadata — founder approves the DE copy sentence-by-sentence + picks the subtitle (`docs/STORE_LISTING_DRAFT.md`). ⛔ blocked: founder review. Privacy URL additionally blocked on P0.6 (lawyer). *(Entschieden 2026-07-05: EN-Listing zum Launch; eigene Support-Adresse; Datenschutz-URL `reflexjourney.app/datenschutz`; Launch kostenlos; Launch mit aktuellem Content.)*
- [ ] Store metadata — EN listing erstellen (Übersetzung der freigegebenen DE-Texte; App selbst ist bereits zweisprachig). Founder-Entscheidung 2026-07-05: EN zum Launch fertig. Abhängig von der DE-Copy-Freigabe.
- [ ] Support-Postfach einrichten (z. B. `support@reflexjourney.de` — **Empfang**, nicht nur Versand; die Resend-Domain sendet bisher nur) und als offizielle Support-Adresse in ASC + Website verwenden. Founder-Entscheidung 2026-07-05.
- [ ] Store metadata — screenshots (aktuelle Pflichtgröße 6,9" / 1320×2868 als Master; Apple skaliert kleinere Größen daraus) + fill the ASC/IARC age-rating questionnaires (needs device + store console access).
- [ ] `docs/screenshot_guide.md` auf aktuelle Pflichtgrößen aktualisieren (6,9" als Master; alte 6,7"/5,5"-Angaben streichen). (Lückenanalyse 2026-07-05; Quellen in `docs/APPSTORE_LAUNCH_ROADMAP.md` §3.)
- [ ] ASC: App-Record unter `de.reflexjourney.app` anlegen (Bundle-ID registriert 2026-07-03; Record fehlt noch).
- [ ] ASC: NEUES Altersfreigabe-Fragenset beantworten (4+/9+/13+/16+/18+, inkl. Medizin/Wellness-Fragen; Pflicht seit 31.01.2026 — Ergebnis kann über dem alten 4+-Entwurf liegen; ehrlich beantworten und akzeptieren).
- [ ] ASC: Privacy Nutrition Labels ausfüllen (E-Mail, Health & Fitness, User Content/Journal, Nutzungsdaten; kein Tracking; Sentry-Diagnostics ergänzen sobald eingebaut) — konsistent mit finaler Datenschutzerklärung (P0.6). **Update 2026-07-05 (T12):** der bisherige Entwurf ist unvollständig — **präziser Standort** kommt dazu, falls Trainer-Discovery sichtbar bleibt (Geolocator + OSM-Tileserver, `trainer_discovery_screen.dart:39-53`), **Kamera/Mikrofon** falls Video-Calls aktiv bleiben. Hängt an D2/D3.
- [ ] ASC: EU-Trader-Status (DSA) verifizieren — verifizierte Adresse + Telefonnummer + E-Mail werden öffentlich auf der Produktseite angezeigt. ⛔ blocked: founder/Anwalt (Adress-/Nummern-Frage; founder besorgt ggf. eigene Nummer, 2026-07-05).
- [ ] ASC: Export-Compliance klären; `ITSAppUsesNonExemptEncryption` in Info.plist prüfen/setzen (Standard-HTTPS ist ausgenommen).
- [ ] Review-Demo-Account NEU aufsetzen — `docs/demo_account_setup.md` ist veraltet (Firebase-Anleitung; App nutzt Supabase-Auth). Frisches Konto mit Beispiel-Fortschritt; Zugangsdaten nur in ASC eintragen, nie im Repo. **Update 2026-07-05 (T14):** Beispiel-Daten so wählen, dass keine leere Fläche wie ein Bug wirkt (live: 0 freigeschaltete Trainer, 1 Experience-Share — Aggregat-Check).
- [ ] Review-Notizen für den Gesundheits-/Kinder-Kontext schreiben (Zielgruppe Erwachsene, kein Medizinprodukt, Kinderprofile nur unter Eltern-Account, Demo-Hinweise, Offline-Hinweis). **Update 2026-07-05 (T14):** zusätzlich den UGC-/Moderations-Status erklären (je nach D1) und die leere Trainer-Liste einordnen.
- [ ] **T19** In-App-Link zur finalen Datenschutz-URL (Settings/Profil) — aktuell existiert keine Policy-URL in der App (Grep über lib/ 2026-07-05). Nach P0.6.
- [ ] Trainer-Selbst-Freischaltung in der App für die Pilotphase sperren (Marketing-Spec Blocker 2) — kleine App-Änderung, vor dem ersten Trainer-Onboarding.
- [ ] TestFlight (see `docs/TESTFLIGHT_QUICKSTART.md`) → staged rollout.
- [x] Crash reporting decision. ✅ 2026-07-05 — founder decision (Roadmap-Session): Sentry, DSGVO-konform mit EU-Datenhaltung; in Anwalts-Policy + Nutrition Labels aufnehmen.
- [ ] Sentry einbauen + verifizieren (Test-Crash kommt im Dashboard an), idealerweise vor dem ersten TestFlight-Build.
- [x] Payments decision. ✅ 2026-07-05 — founder decision: Launch ist kostenlos, Paket 1 bleibt kostenlos; keine Paywall im Launch-Build. (Korrektur der alten Zeile „RevenueCat is coded but disabled": im Code existiert nur ein leeres Config-Feld, `purchases_flutter` ist in pubspec auskommentiert — Code-Prüfung 2026-07-05.) Post-Launch-Plan siehe „Open questions / parked".

### P3.W — Website Launch-Pflichtseiten (äußeres Repo `reflexjourney-app-site/`, Vercel)

Quellen/Begründung: `docs/APPSTORE_LAUNCH_ROADMAP.md` §6. Support- und Datenschutz-URL sind ASC-Pflichtfelder.

- [ ] Website: `/impressum` mit Pflichtangaben (Anwalt bestätigt) — Launch-Blocker.
- [ ] Website: `/support` + offizielle Support-Mail (ASC-Pflichtfeld Support-URL) — Launch-Blocker.
- [ ] Website: schlanke Landingpage ersetzt Platzhalter (heilversprechen-freie Copy; aktueller Platzhalter-Claim „Nervensystem-Training für den Alltag" wird ersetzt) — Launch-Blocker in Minimalform.
- [ ] Website: `/datenschutz` mit Anwalts-Text (ASC-Pflichtfeld Datenschutz-URL) — Launch-Blocker, hängt an P0.6.
- [ ] Website: `/trainer` + Bewerbungsformular (Marketing-Spec Teil C; einfaches Formular, kein Datei-Upload; Sichtprüfungs-Ablauf siehe Roadmap §7) — kein Launch-Blocker; Blocker für den Akquise-Piloten. Founder 2026-07-05: Angebot freigegeben, einfaches Formular + Einzelprüfung mit Führungszeugnis.

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
- [ ] **T20** Doku-Korrekturen (Delta-Analyse 2026-07-05): `docs/FEATURE_FLAGS.md` beschreibt ein Firebase-Remote-Config-System, das im Code nicht existiert (0 Flag-Nutzungen in lib/; `feature_flags`-Tabelle live, aber ungelesen) — korrigieren oder als „nicht implementiert“ markieren. `docs/TESTFLIGHT_QUICKSTART.md` komplett neu schreiben (nennt altes Bundle-ID `com.alexandermessinger.corejourney`, GitHub-Pages-Hosting, obsolete Pfade — Roadmap-Einschätzung „Inhalt sonst brauchbar“ war zu freundlich).

---

## Open questions / parked

- Chatbot feature: neutralized for launch 2026-07-03 (see P0.2) — app no longer calls it, endpoint stubbed. The user-facing need it hinted at is now properly scoped: **Stufe 1** = curated FAQ section (P2.C, content from Sina's forum). Post-launch roadmap: **Stufe 2** = guided question flow (free-text input matched against reviewed FAQs only, with real trainer forwarding rebuilt on FCM HTTP v1); **Stufe 3** = content-gated chatbot (own project, product + legal review). The 4 seeded `bot_faqs` rows sit unused in the DB; reuse or delete when P2.C is built.
- Post-Launch-Monetarisierung: RevenueCat + Apple IAP nach `docs/superpowers/specs/2026-05-28-monetization-design.md` Phase 2; vorher AGB/Widerruf (Anwalt) + IAP-Produkte in ASC. Stripe-Checkout fürs Abo ist im App Store nicht zulässig (Guideline 3.1.1). **Founder-Anforderung 2026-07-05:** Freischalt-Codes für bestimmte Nutzer („Gründungsnutzer" o. ä.), die allen Content dauerhaft oder teilweise kostenlos geben — beim Paywall-Design von Anfang an einplanen (die vorhandene `access_codes`-Tabelle ist ein möglicher Anknüpfungspunkt, aktuell service-role-only/deny-all). Bestandsschutz-Kommunikation für Gratis-Phase-Nutzer festlegen, bevor die Paywall live geht.
- Old repos: `/Users/alexandermessinger/dev/corejourney` (obsolete) and `_ARCHIVED_corejourney_old` — consider archiving/removing to reduce confusion.
- App-Root-Streuner (Delta-Analyse 2026-07-05, kein Risiko, nur Hygiene): `example.mjs` (OpenAI-Beispielskript), `node_modules/` + `package.json` im Flutter-Root, alter Worktree `.worktrees/android-firebase-distribution`, `flutter_0*.log` — bei Gelegenheit aufräumen.
- Kein In-App-Datenexport vorhanden (Grep 2026-07-05); die alte Policy versprach „Export your data“. Anwalts-Policy soll Export als Support-Prozess formulieren (Art. 20 DSGVO), nicht als App-Funktion — oder Export wird post-launch gebaut.
- Outer repo (`claudvibes/corejourney`) has its own uncommitted admin-web changes + untracked specs — needs a housekeeping commit.
