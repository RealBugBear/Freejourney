# Beta Foundation — Closed Tester Rollout (P0)

Status: **Automated gate green** (2026-08-31) — `make release-readiness-mobile` passed (673 tests, analyze clean).

This runbook gets the first 2–5 real testers through signup → one Moro training → feedback, without waiting on videos, adult questionnaire, or App Store launch paperwork.

---

## 1. Pre-flight (founder, ~45 min)

### Automated (done)

```bash
make release-readiness-mobile
```

Expected: i18n checks pass, `flutter analyze` clean, full test suite green.

### Manual smoke (must-pass before inviting anyone)

Use a **throwaway email** on a **physical device** (not simulator). Production flavor talks to the live Supabase project.

| # | Step | Pass criteria |
|---|------|---------------|
| 1 | Install build (TestFlight or sideload) | App opens, language picker works |
| 2 | Sign up with new email | Snackbar: check inbox for confirmation |
| 3 | Tap confirmation link **on the phone** | App opens (universal link `/auth/confirm`) |
| 4 | Sign in | Lands on consent screen (not dashboard flash) |
| 5 | Accept consent | Username setup → optional onboarding cards → dashboard |
| 6 | Start Moro training | **Routine (hands-free)** mode, complete ≥1 exercise |
| 7 | Return to dashboard | Streak / “Heute” updates |
| 8 | Airplane mode: mark session or change setting | No crash |
| 9 | Back online | Sync queue drains (check Dev Tools if `@reflexjourney.de`) |

Notes for testers (tell them upfront):

- Consent screen says **“Testphase”** — that is intentional for this closed beta.
- **Email confirmation is required** — they must tap the link on the same device.
- **Adult self-report questionnaire** is enabled in this beta build (`kAdultReflexQuestionnaireEnabled = true`). Results and some copy are **preliminary** — not for medical decisions. Movement checks and safety hard-gates stay off.
- Exercise **videos are not wired yet** — training uses static images; “Video wird vorbereitet…” is expected.

### Sentry (~10 min) — see `docs/SENTRY_SETUP.md`

1. Create Sentry project (Flutter), **EU data region**.
2. Paste DSN into `.env.prod` as `SENTRY_DSN=…`
3. Rebuild → Dev Tools → “Test-Crash an Sentry senden” (or wait for a real crash in Issues).

---

## 2. Build & distribute

Current version after bump: see `pubspec.yaml` (`version: X.Y.Z+YYYYMMDDNN`).

### iOS — TestFlight

```bash
make bump-build          # before every upload
make testflight          # builds production IPA, opens Transporter
```

Upload in Transporter → App Store Connect → TestFlight.

- **Internal testers** (ASC team, up to 100): available immediately after processing (~10–30 min).
- **External testers**: need Apple beta review (skip for first cohort — use internal or ASC email invites).

First-time blockers (if not done yet): ASC app record for `de.reflexjourney.app` — see `docs/TESTFLIGHT_QUICKSTART.md`.

### Android — Firebase App Distribution

```bash
make bump-build
make android-testers ANDROID_DIST_GROUPS=testers
```

Requires Firebase CLI logged in and a `testers` group with emails added in Firebase console.

---

## 3. Tester cohort (start small)

**Wave 1 (2–3 people):** friendly, patient, will reply to messages.

Pick by scenario:

| Tester type | What you learn |
|-------------|----------------|
| Parent with child | Onboarding, child Reflex Profile, training for child |
| Adult training for self | Training flow, dashboard, reminders (no adult questionnaire yet) |
| Mixed household | Joint training / profile switching |

**Do not** invite more than 5 until Wave 1 feedback is processed and Sentry is clean.

---

## 4. Message to send testers

Copy from `docs/BETA_TESTER_BRIEF.md` (DE + EN). Attach:

- TestFlight invite link **or** Firebase install link
- Link to feedback form (create from `docs/BETA_FEEDBACK_FORM.md`)

---

## 5. What to fix before Wave 2

Prioritize by impact:

1. Anything that **blocks signup or training**
2. Crashes in Sentry
3. Confusing onboarding (where did they get stuck?)
4. Sync / data loss reports
5. Copy / translation issues

Defer until later: videos (P1), adult questionnaire, paywall, community, video calls.

---

## 6. Session log

| Date | Build | Testers invited | Blockers found | Next action |
|------|-------|-----------------|----------------|-------------|
| 2026-08-31 | **1.0.5+2026083102** — adult questionnaire enabled | 0 | — | Upload IPA, retest „Für mich selbst“ |

Update this table after each wave.
