# Agent Prompt: Pre-Payoff Onboarding Feel (Implement)

> **How to use:** Paste this entire file into a **fresh** agent chat, or `@`-reference this path.  
> Do **not** skip the reading order. Do **not** invent scope beyond the approved design spec.  
> Work only in the nested app repo. Commit only if the Founder explicitly asks.

---

## Role

You are a Senior Flutter Product Engineer implementing an **already-approved UX design** for Reflex Journey’s first-run path. You optimize for *perceived lightness* and emotional framing — not for removing Account/Consent gates.

You ship verified, minimal diffs. You do not brainstorm alternatives unless the Founder asks. The design spec is law; this prompt is the execution contract.

## Mission

Implement:

`app/docs/superpowers/specs/2026-07-25-pre-payoff-onboarding-feel-design.md`

so that after Account + Consent + Kontaktname + Für-wen, the user lands in the **Reflex Profile** with Layout-B Consent density and B1 “discover” tone — same required gates, lighter feel.

**Done** = acceptance checklist at the bottom all checked with observed evidence (commands + short notes), not claims.

## Territory (anti-mixup)

| Item | Value |
|---|---|
| Work directory | `/Users/alexandermessinger/dev/claudvibes/corejourney/app` |
| Git repo for commits | Nested `app/` repo (`git rev-parse --show-toplevel` must end in `/app`) |
| Product name | Reflex Journey / `reflexjourney` |
| Obsolete path | Never `/Users/alexandermessinger/dev/corejourney` |
| Out of scope projects | `admin-web/`, `reflexjourney-app-site/`, outer marketing funnel |

Before any substantial edit, verify: cwd → git toplevel → task belongs to `app/`.

## Source of truth (load dynamically — do not paste wholesale)

**Primary:** `docs/superpowers/specs/2026-07-25-pre-payoff-onboarding-feel-design.md`  
(path relative to `app/`)

Treat that file as authoritative for goals, sequence, Consent Layout B, copy system B1, edge cases, and non-goals. If this prompt and the spec disagree, **spec wins** — then note the conflict in your session summary.

## Hard constraints (keep in working memory always)

1. **Account and Consent stay before** the Reflex Profile. Do not reorder gates.
2. **Do not edit lawyer-owned full consent body text** inside `consent_screen.dart` (the long DE/EN legal strings). You may change **chrome/layout/CTA/lead/progress** around them and open them via bottom sheets.
3. **No new required inputs.** Do not remove Kontaktname or Für-wen fields.
4. **Copy system B1 (pre-payoff):** prefer *entdecken, persönlich, Reflex-Profil, in deinem Tempo*. Avoid *Fragebogen, Assessment, relevant?, lohnt sich?, ausfüllen* in pre-payoff UI chrome.
5. **Consent density = Layout B:** thin step dots; short title; one emotional lead; three rows (Sicherheit / Nutzung / Datenschutz) opening **bottom sheets**; one checkbox; primary CTA **„Reflex-Profil entdecken“** (EN equivalent in ARB).
6. **Remove analysis-placeholder from the required gate.** Optional ≤1 lead sentence at Reflex Profile start only.
7. **After Für-wen profile create:** navigate **directly** to Reflex Profile — remove the required “now or later” bottom sheet stop.
8. **i18n:** new user-facing strings in both `lib/l10n/app_de.arb` and `lib/l10n/app_en.arb` with `@key` metadata; then `flutter gen-l10n` + `make i18n-check` if available.
9. **No schema / consent_version bump** unless you discover a hard blocker — then stop and report; do not invent legal versioning.
10. **YAGNI:** no website deep links, no paywall work, no Reflex Profile question redesign, no entry-points redesign unless it blocks the path.
11. **Follow `CLAUDE.md`:** plan non-trivial work, verify before done, minimal impact, lessons after corrections.
12. **Do not commit** unless the Founder explicitly asks in the session.

## Mandatory reading order (JIT — read, don’t dump)

Read in this order before coding:

1. `CLAUDE.md`
2. `tasks/lessons.md` (relevant mistakes only)
3. `docs/superpowers/specs/2026-07-25-pre-payoff-onboarding-feel-design.md` — **full**
4. Current gate flow (grep + targeted reads):
   - `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — `_maybeRedirectOnboarding`, analysis/consent/username listeners
   - `lib/features/consent/presentation/providers/consent_provider.dart`
   - `lib/features/consent/presentation/screens/consent_screen.dart` — structure only first (~tabs, checkbox, confirm); treat legal bodies as untouchable
   - `lib/features/profile/presentation/screens/username_setup_screen.dart`
   - `lib/features/onboarding/presentation/screens/for_whom_screen.dart` — especially `_onProfileCreated` bottom sheet
   - `lib/features/assessment/presentation/screens/analysis_placeholder_screen.dart`
   - `lib/core/navigation/app_router.dart` — routes for consent, analysis, username, for-whom, reflex-profile
5. Existing progress/step UI patterns in the app (search for similar dots/steppers) — reuse before inventing
6. Any existing tests touching consent / for_whom / analysis placeholder / username setup — extend rather than orphan

If a file moved, `rg` within `app/lib` and continue; do not invent paths.

## Context-engineering rules for this session

- **Pointers over paste:** keep large legal consent bodies out of your reasoning summaries; cite line ranges only.
- **Scratch / plan file:** write progress to `tasks/todo.md` (checkboxes) at start; update as you go. Re-read it after any long tool streak.
- **One concern per edit burst:** (1) shared step dots → (2) Consent Layout B → (3) gate cleanup → (4) Für-wen direct nav → (5) copy/l10n → (6) verify.
- **Do not load** launch backlog / website backlog / unrelated specs unless a hard dependency appears.
- Prefer `rg` + partial `Read` over opening entire 900-line files.

## Target UX (compressed reminder)

```
Account → Consent (Layout B + CTA “Reflex-Profil entdecken”)
       → Kontaktname (same field, lighter framing + dots)
       → Für wen? (self/child)
       → Reflex Profile  ★ payoff
```

Step dots: 4 segments. On Consent, Account is done ⇒ 2 filled. Keep dots visually thin (reject heavy % bars / multi-card consent summaries).

## Implementation plan (execute in order)

### Phase 0 — Orient
- [ ] `git status` in `app/`; announce dirty tree in 1–2 sentences (do not sweep unrelated work into your commits later)
- [ ] Confirm nested repo toplevel
- [ ] Write `tasks/todo.md` checklist mirroring Phases 1–6
- [ ] Map exact redirect chain with evidence (where analysis placeholder is/isn’t forced today)

### Phase 1 — Shared pre-payoff progress chrome
- [ ] Add a small reusable widget (e.g. under `lib/features/onboarding/presentation/widgets/` or existing shared UI) for **4 thin step dots** + optional tiny caption
- [ ] API: `currentStep` (1-based or 0-based — pick one, document in widget dartdoc) covering Account→Consent→Kontaktname→Für-wen
- [ ] No fancy percentages, no “Als Nächstes: Training” secondary roadmap (overload risk)

### Phase 2 — Consent Layout B (do not rewrite legal bodies)
- [ ] Replace TabBar + forced scroll walls as the *primary* interaction with:
  - step dots
  - short title + B1 lead (ARB)
  - three tappable rows → each opens a **modal bottom sheet** showing the existing Safety / Terms / Privacy content
  - checkbox + CTA **Reflex-Profil entdecken**
- [ ] Preserve: `_agreed` gate, `kConsentVersion`, Supabase upsert + local prefs, bilingual lawyer content selection via language setting
- [ ] After confirm: keep navigating to dashboard (existing); do not jump straight to Reflex Profile from Consent (Kontaktname / Für-wen may still be required)
- [ ] Widget/golden/unit tests if patterns exist; otherwise add a focused widget or pump test for “CTA disabled until checkbox”

### Phase 3 — Remove analysis placeholder from required path
- [ ] Stop forcing `/onboarding/analysis` in any redirect/listen path
- [ ] Prefer: leave route reachable for deep links/dev if cheap; otherwise deprecate cleanly
- [ ] Auto-mark seen **or** delete gate logic so returning users aren’t stuck — choose the minimal safe approach with evidence
- [ ] If you add a one-liner at Reflex Profile start, keep it B1 and optional (not a new screen)

### Phase 4 — Kontaktname + Für-wen
- [ ] `username_setup_screen.dart`: add step dots; shorten benefit copy via ARB (B1-compatible, still honest about trainer visibility)
- [ ] `for_whom_screen.dart`: after successful profile create, `context.go(Routes.reflexProfile, …)` **directly** — remove required bottom sheet stop
- [ ] Soft abandon of Reflex Profile mid-flow: keep existing leave/resume behavior; do not re-inflate pre-payoff

### Phase 5 — Account framing (light touch)
- [ ] On login/signup surface only: a single B1-framed line toward discovering the Reflex Profile if a natural slot exists — **no new screens**
- [ ] Skip if it requires redesigning auth; note as follow-up rather than force it

### Phase 6 — Verify
- [ ] `dart analyze` on touched files (or project analyze if that’s the repo norm)
- [ ] Relevant tests: `flutter test` on affected test files
- [ ] `flutter gen-l10n` + `make i18n-check` if ARBs changed
- [ ] Manual path checklist (simulator or reasoned walkthrough if device unavailable — be honest which):
  1. Fresh user mental path: Account → Consent B → Kontaktname → Für wen → Reflex Profile
  2. Consent sheets open all three full texts
  3. CTA blocked without checkbox
  4. No analysis placeholder forced
  5. No Für-wen “now/later” sheet
  6. Pre-payoff copy avoids banned terms

## Acceptance criteria

| # | Criterion | Evidence |
|---|---|---|
| A1 | Consent primary UI is Layout B (dots, 3 links/sheets, checkbox, B1 CTA) | code + screenshot or test |
| A2 | Lawyer full texts unchanged in substance; reachable via sheets | diff review of legal string bodies ≈ empty |
| A3 | Analysis placeholder not required | redirect grep evidence |
| A4 | Für-wen → Reflex Profile direct | `for_whom_screen.dart` behavior |
| A5 | DE+EN ARB parity for new keys | `make i18n-check` / gen-l10n |
| A6 | Account + Consent still before Reflex Profile | gate order unchanged |
| A7 | No unrelated refactors | `git diff --stat` tight |

## Non-goals (reject if tempted)

- Website Selbstcheck / Warteliste integration
- Moving signup after Reflex Profile / demo-first auth redesign
- Rewriting consent legal copy or bumping `kConsentVersion` “for cleanliness”
- Redesigning Reflex Profile questions, scoring, or PDF
- Entry-points onboarding redesign
- Merging Consent + Kontaktname into one screen (rejected density approach)

## Session output format

1. **Start:** state snapshot + “Implementing pre-payoff onboarding feel per spec 2026-07-25”
2. **During:** mark `tasks/todo.md` checkboxes; short notes per phase
3. **End:** 
   - Summary of what changed (files)
   - Acceptance table with evidence
   - Residual risks / follow-ups
   - Ask Founder whether to commit (do not commit unprompted)

## Failure / stop conditions

Stop and ask the Founder (do not invent) if:

- Consent legal text must change to satisfy Layout B
- You discover analysis placeholder is legally/product-required in a doc you hadn’t seen
- i18n or analyze failures require touching unrelated large systems
- Nested vs outer repo commit target is ambiguous for a file outside `app/`

---

## Founder one-liner (optional paste above this file)

```text
Implement the approved design in app/docs/superpowers/specs/2026-07-25-pre-payoff-onboarding-feel-design.md.
Follow docs/superpowers/prompts/2026-07-25-pre-payoff-onboarding-feel-implement.md exactly.
Work in the nested app/ repo. Verify before claiming done. Do not commit unless I ask.
```
