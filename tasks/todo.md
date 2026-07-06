# T04 — Community-Tab + Experience-Feed für v1 verstecken (2026-07-06)

Befund-Update gegenüber dem Task-Prompt: Es gibt **zwei zusätzliche Einstiege**,
die der Prompt nicht listet — (a) die Checkbox „Als geteilte Erfahrung
einreichen" im Post-Training-Sheet (`training_experience_sheet.dart`, schreibt
direkt in `experience_shares`), (b) die Review-Karte im Trainer-Dashboard
(`trainer_dashboard_screen.dart:135`). Der DM-Screen filtert Community-Kanäle
bereits heraus (kein Handlungsbedarf). `profiles.display_name` wird auch im
Trainer-Chat als Anzeigename genutzt → Profil-Sektion „Anzeigename" bleibt,
nur ihr Community-Feed-Untertitel wird neutral gefasst. Admin-Panel-Tab
„Erfahrungen" bleibt bewusst (Admin-only = Founder, Moderation von
Altbeständen; kein Prod-Nutzerpfad).

## Schritte

- [x] 1. Vorher-Screenshots per Widget-Test-Harness (Begleitung-Tab ohne
      Trainer, Training-Experience-Sheet, Mood-Check-in-Sheet) →
      docs/evidence/T04/before/
- [x] 2. `lib/config/launch_flags.dart` mit `const bool kCommunityEnabled = false;`
- [x] 3. Router: `communityGateRedirect` (→ Dashboard) an Routen `community`
      und `experienceFeed`
- [x] 4. `mood_checkin_sheet.dart`: Share-Dialog-Aufruf gaten (Sheet-Layout
      unverändert)
- [x] 5. `training_experience_sheet.dart`: Share-Checkboxen + Save-Branch
      gaten, Abstände so umbauen, dass ohne Checkboxen kein Loch bleibt
- [x] 6. `accompaniment_screen.dart`: Karte „Geteilte Erfahrungen" +
      zugehörigen Spacer gaten (Listen-Ende bleibt sauber)
- [x] 7. `trainer_dashboard_screen.dart`: `_SharedExperienceReviewCard` gaten
- [x] 8. `profile_screen.dart`: Untertitel „Wird im Community-Feed angezeigt…"
      → neutrale Fassung bei deaktiviertem Flag; `username_setup_screen.dart`:
      Satz „…von deinem Community-Namen unterscheiden" gaten
- [x] 9. Neuer Test `test/core/navigation/launch_gate_test.dart`: Flag-Guard +
      Redirect /community und /experience/:id → Dashboard
- [x] 10. Nachher-Screenshots (gleiches Harness) → docs/evidence/T04/after/;
      Harness danach entfernen (temporäre Datei)
- [x] 11. `make release-readiness-mobile` grün
- [x] 12. `flutter build ios --flavor production -t lib/main_production.dart
      --release --no-codesign` grün
- [x] 13. Commit (explizite Dateiliste), Tracker + Backlog mit Evidenz,
      T06-Prompt ausgeben oder direkt anschließen

## Review (2026-07-06)

Alle 13 Schritte ausgeführt. Ergebnis: Mit `kCommunityEnabled=false` existiert
kein tappbarer oder tief verlinkter Weg zu Community/Feed; direkter Aufruf
beider Routen redirectet auf das Dashboard (produktiver `communityGateRedirect`,
per Widget-Test belegt). Kein Code gelöscht — Flag auf `true` stellt alles
identisch wieder her. Evidenz: `docs/evidence/T04/` (before/after-PNGs),
`make release-readiness-mobile` → 203 Tests grün / analyze 0 Fehler+Warnungen,
Prod-iOS-Build ✓ (101.4MB, --no-codesign). Bewusste Scope-Entscheidungen:
Admin-Moderations-Tab bleibt (nur Rolle admin); `app_shell.dart`-Tab-Mapping
für `/community` bleibt (harmlos, greift nie, minimiert Diff); DM-/Trainer-Chat
unangetastet. Icons in den Evidenz-PNGs erscheinen als Kästchen
(Widget-Test-Rendering ohne Icon-Font) — Layout/Text sind voll aussagekräftig.

---

# T06 — Video-Calls für v1 verstecken (2026-07-06, direkt nach T04)

In derselben Session nach T04 ausgeführt (gleiche `launch_flags.dart`).
Befund-Update: Neben den im Prompt gelisteten Einstiegen (2× AppBar-videocam,
IncomingCallListener, openVideoCall) existieren weitere: videocam-Button in
der **Message-Input-Bar** (`message_input_bar.dart:69`), „Annehmen“-Action auf
Call-Request-Bubbles (`message_bubble.dart`, via `onAcceptCall`), Foreground-
Anzeige von Call-Pushes (`push_notification_service.dart`) und der
`video_call`-Push-Payload-Pfad (`app.dart`). `ChatInboxScreen` erwähnt
Video-Calls, ist aber nirgends geroutet (toter Screen — unangetastet).

## Ausgeführt

- [x] `kVideoCallsEnabled = false` in `lib/config/launch_flags.dart`
- [x] Chat-Screen: beide AppBar-videocam-Actions, `onAcceptCall`,
      `onCallRequest` (Input-Bar versteckt ihren Button selbst) gegated
- [x] `app.dart`: IncomingCallListener nur bei Flag=true; `video_call`-Payload
      → Log + Return (still ignoriert, kein Crash)
- [x] Push-Service: Foreground-Notifications für `video_call`/`call_request`
      unterdrückt (Log-Zeile)
- [x] Termin-Scheduler: Hinttext „Ort oder Video-Call“ → neutral bei Flag=false
- [x] Tests: Flag-Guard + Chat-Screen (Practitioner & Moderator) ohne
      videocam, Termin-Icon bleibt → Chat-Tests 22/22
- [x] Screenshots vorher/nachher `docs/evidence/T06/` (before via git stash)
- [x] `make release-readiness-mobile` grün; Prod-Build ✓ (101.2MB)

## Review

AppBar zeigt ohne Call-Button nur Titel (Practitioner) bzw. Termin-Icon
(Moderator) — Standard-Look, keine Lücke; Input-Bar beginnt sauber mit dem
Textfeld. Agora-Dependency, Edge Functions, Secrets unangetastet. Historische
Call-Request-Bubbles bleiben als Text lesbar, nur ohne „Annehmen“. Hinweis an
T09 (im Tracker vermerkt): Kamera-/Mikro-Strings in Info.plist bleiben, weil
der Agora-Code im Bundle bleibt.

---

# P3 — Store-Metadaten-Entwurf (2026-07-04)

Goal: a review-ready draft of all App Store / Play Store text fields under the
Reflex Journey brand, strictly free of therapy/medical-claim language, plus a
list of the decisions only the founder can make. Screenshots + age-rating
questionnaire stay with the founder (device + ASC access).

- [x] Collect product facts from l10n copy, docs, and app structure (done inline).
- [x] Write `docs/STORE_LISTING_DRAFT.md`: DE store fields within Apple/Google
  char limits (name, subtitle, description, keywords, promo text), Play Store
  variants, URLs, category/age-rating recommendation, founder-decision list.
- [x] Self-review every sentence against the no-therapy/medical-claims rule —
  activity descriptions only, explicit non-medical note, no diagnosis keywords.
- [x] Update backlog (split checkbox: draft done, review/screenshots remain),
  commit; hash recorded in the backlog evidence note.

---

# P1.2 final item — deep-link auth flows end-to-end + device QA (2026-07-03)

## Findings (live config + code, verified this session)

1. **Password reset breaks when the app is installed.** Recovery email links to
   `https://reflexjourney.app/auth/reset-password?token_hash={{ .TokenHash }}&type=recovery`.
   iOS (AASA `/auth/*`) and Android (`pathPrefix /auth/`) open the **app** for that
   link, but `_handleDeepLink` (lib/app.dart) only calls `getSessionFromUrl`, which
   cannot process `token_hash` links → silent failure, user stuck on login screen.
   The browser page only gets the link when the app is NOT installed.
2. **Confirm-signup lands on a dead URL.** Signup passes no `emailRedirectTo`; the
   confirmation template uses `{{ .ConfirmationURL }}` → Supabase verify endpoint →
   redirect to live `site_url`, which is `https:corejourney.care` — old brand AND
   malformed (missing `//`). Verification succeeds server-side, then the browser
   lands nowhere. The existing `/auth/confirm` page (expects `token_hash`) is never used.
3. `uri_allow_list` lacks `https://reflexjourney.app/auth/confirm`.
4. Backlog P1.4 claims "Site URL updated; old corejourney entries removed" — live
   config contradicts this; backlog note must be corrected.

## Plan

- [x] App fix (autonomous): `_handleDeepLink` handles `token_hash` links —
  recovery via `verifyOTP(OtpType.recovery, tokenHash)` (keep `getSessionFromUrl`
  as fallback for legacy link shape); add `/auth/confirm` handling via
  `verifyOTP(signup → email fallback)` guarded to no-existing-session.
  → commit `58827aa`.
- [x] Tests: extracted `classifyAuthDeepLink` (top-level, pure) + 6 unit tests;
  `flutter analyze` clean; full suite 200/200 green.
- [x] Commit app fix (own commit, P1.2 reference). → `58827aa`.
- [x] GATED (founder go, one batch): PATCH auth config —
  `site_url` → `https://reflexjourney.app`;
  `uri_allow_list` += `https://reflexjourney.app/auth/confirm`;
  confirmation template button/fallback link →
  `https://reflexjourney.app/auth/confirm?token_hash={{ .TokenHash }}&type=signup`.
  → applied + verified in the prior session; corroborated in field 2026-07-04.
- [x] Build release dev-flavor iOS app (`de.reflexjourney.app.dev`, release mode
  so it runs standalone from email taps). → built green 2026-07-03; rebuilt 2026-07-04.
- [x] Install on the iPhone. → installed 2026-07-04 to `00008140-000671E10AEB001C`.
- [x] Fix fresh-install crash (router redirect loop /login⇄/language). → `66958f0`.
- [x] Fix signup "something went wrong" once confirm-email enabled. → `264e2f0`.
- [~] Founder runs the on-device QA script below. → PARTIAL 2026-07-04 (see results).
- [x] Update backlog: ticked install + auth-config + both live fixes, QA results,
  "Next up" refreshed, P1.4 correction resolved.

## On-device QA results (2026-07-04)

- Step 0 (fresh-install crash): **PASS** — app opens to language/login, no crash;
  tester logged in. (Was the router-loop bug, fixed `66958f0`.)
- Step 1 (password reset, app installed): **PASS** — recovery link opened the app,
  in-app new-password screen, re-login worked.
- Step 2 (password reset, browser): **PASS** on the retest — a fresh link opened the
  reflexjourney.app page and reset worked. (First attempt "timed out"; the link had
  already been consumed — reset links are strictly one-time-use.)
- Step 3 (confirm signup): **PASS with a caveat.** Found the Supabase "Confirm email"
  toggle was OFF (accounts auto-confirmed, no email sent); founder turned it ON. That
  exposed a signup UX bug (generic error instead of "check your email") — fixed
  `264e2f0`. After the fix: friendly message shown, account created, email sent,
  confirmation + sign-in worked, no dead corejourney.care page. CAVEAT: the confirm
  link was opened via a **browser temp-email**, so "tapping the link opens the app on
  the iPhone" is still unverified for `/auth/confirm` (the reset link *did* open the
  app). One throwaway email + one tap on device closes P1.2.

## On-device QA script (founder, ~10 min, after config PATCH + install)

Preparation: use a test email address you can read on the iPhone. The dev build
talks to the live Supabase project, so use a throwaway/test account, not your
real one.

1. **Password reset (app installed):** open the app → login screen → "Passwort
   vergessen" with the test account's email → open the email on the iPhone →
   tap the green button. **Expected:** the app opens directly (no browser) and
   shows the in-app "new password" screen. Set a new password, log in with it.
2. **Password reset (no app / browser):** forward the same kind of email to a
   computer, or long-press the button link on the phone → "Open in Safari".
   **Expected:** the reflexjourney.app web page opens and lets you set a
   password (each link works once — request a fresh email for this step).
3. **Confirm signup:** in the app, register a brand-new test account → open the
   confirmation email on the iPhone → tap the button. **Expected (after the
   gated config change):** the app opens and you are signed in — no dead
   corejourney.care page anywhere.
4. **If a link opens the browser instead of the app:** iOS caches the
   universal-link file. Reinstalling the app or toggling
   Settings → Developer → "Associated Domains Development" refreshes it; then
   retry. Report what you saw either way.

Record pass/fail per step; the backlog item gets ticked only on observed passes.
