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
- [ ] GATED (founder go, one batch): PATCH auth config —
  `site_url` → `https://reflexjourney.app`;
  `uri_allow_list` += `https://reflexjourney.app/auth/confirm`;
  confirmation template button/fallback link →
  `https://reflexjourney.app/auth/confirm?token_hash={{ .TokenHash }}&type=signup`.
  Payload: scratchpad `auth-config-patch-2026-07-03.json`; rollback snapshot:
  `auth-config-rollback-2026-07-03.json` (same directory).
- [x] Build release dev-flavor iOS app (`de.reflexjourney.app.dev`, release mode
  so it runs standalone from email taps). → built green 2026-07-03.
- [ ] Install on the iPhone. ⛔ device locked (`kAMDMobileImageMounterDeviceLocked`);
  retry once unlocked: `flutter install --release --flavor development -d 00008140-000671E10AEB001C`
- [ ] Founder runs the on-device QA script below.
- [x] Update backlog: corrected P1.4 note, evidence notes added, "Next up" refreshed.

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
