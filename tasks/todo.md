# Pre-Payoff Onboarding Feel — Implement (2026-07-25)

**Branch:** `i18n/english-localization` (dirty with unrelated training/i18n work — do not sweep into this change set)
**Spec:** `docs/superpowers/specs/2026-07-25-pre-payoff-onboarding-feel-design.md`

## Redirect map (Phase 0 evidence)

- Dashboard `_maybeRedirectOnboarding`: Consent → Kontaktname only. Analysis placeholder was **not** forced in gate body; dead listener removed.
- Username (no subject profiles) now → Für-wen (was entry-points).
- Für-wen → Reflex Profile direct (now/later sheet removed).
- Analysis route `/onboarding/analysis` kept for deep links; not gated.

## Phases

- [x] 1. Shared 4 thin step-dot widget (`currentStep` 1-based: Account→Consent→Kontaktname→Für-wen)
- [x] 2. Consent Layout B (dots, short title, B1 lead, 3 sheet rows, checkbox, CTA „Reflex-Profil entdecken“); legal bodies untouched
- [x] 3. Analysis placeholder off required path (drop dead listener; keep route cheaply)
- [x] 4. Kontaktname: dots + shorter B1 body; username → Für-wen; Für-wen → Reflex Profile direct (no sheet)
- [x] 5. Account: single B1 framing line if natural slot
- [x] 6. Verify: analyze, tests, gen-l10n + i18n-check, acceptance table

## Review

### Verification evidence

- `dart analyze` on touched screens/widgets: **No issues found**
- `flutter test` consent Layout B + step dots: **All tests passed! (3)**
- `python3 scripts/i18n_check.py`: **parity passed** (1191 keys)
- `make i18n-check` overall: quality check failed on **pre-existing** allowlist keys (`routineMode`, `trainingRoutineSubtitle`, `tutorialMode`) already dirty on this branch — not introduced by this work
- Manual path: reasoned walkthrough (no simulator run this session)

### Acceptance

| # | Result | Evidence |
|---|---|---|
| A1 | ✅ | Consent Layout B + `consent_screen_layout_b_test.dart` |
| A2 | ✅ | Lawyer bodies retained in `_SafetyTab`/`_TermsTab`/`_PrivacyTab`; chrome-only rewrite |
| A3 | ✅ | No analysis redirect in `_maybeRedirectOnboarding`; listener removed |
| A4 | ✅ | `for_whom_screen.dart` → `context.go(Routes.reflexProfile)` direct |
| A5 | ✅ | New keys DE+EN; `i18n_check.py` parity passed |
| A6 | ✅ | Gate still Consent then Kontaktname before payoff |
| A7 | ✅ | Touched onboarding/consent/username/login/dashboard + ARB/tests only |

### Residual / follow-ups

- Entry-points screen remains reachable by route but is no longer on the required Kontaktname path (post-payoff / non-blocking per spec).
- Analysis placeholder route kept for deep links; provider/pref helpers left for that screen.
- Branch already dirty with training/i18n work — commit only the onboarding-feel files when Founder asks.
- No device/simulator smoke this session.
