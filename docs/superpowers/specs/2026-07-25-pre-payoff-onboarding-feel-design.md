# Pre-Payoff Onboarding Feel — Design

**Date:** 2026-07-25  
**Scope:** Flutter app (`app/`) — first-run path until the Reflex Profile  
**Status:** Draft for founder review  
**Out of scope:** Marketing website funnel, moving Account/Consent after the profile

## Problem

The path from first open to the Reflex Profile (the emotional “is this for me?” moment) feels long and effortful. Users face many screens and inputs before they get a personal payoff. The goal is not to remove Account or Consent, but to make the same required path **feel lighter**.

## Goals

1. Keep **Account** and **Consent** before the Reflex Profile (compliance + product constraint).
2. Reduce **perceived** effort: clearer progress, less wall-of-text, emotional framing.
3. Do **not** add new required inputs; do **not** remove required legal/account steps.
4. Frame the payoff as **discovering a personal Reflex Profile**, not as filling a questionnaire / relevance check.

## Non-goals

- Website ↔ app deep-link / marketing connection (explicitly deferred).
- Deferring signup or consent until after the Reflex Profile.
- Changing lawyer-owned consent full text.
- Cutting Kontaktname, profile-for-whom fields, or other required data.
- Redesigning the Reflex Profile questions themselves.

## Chosen approach

**Approach 1 — Progress + Consent lightness**, refined to:

| Decision | Choice |
|---|---|
| Density | **B — light** (thin step dots, short copy, three “Lesen” links, one checkbox) |
| Tone | **B1 — discover** (“persönliches Reflex-Profil entdecken”) |
| Heavy progress chrome | Rejected (felt overloaded) |
| Logical “Fragebogen / lohnt sich?” copy | Rejected in favor of emotional discover language |

Rejected alternatives: aggressive screen merging (Approach 2), framing-only without Consent UX change (Approach 3 alone).

## Target step sequence

1. **Account** — Login/Signup unchanged as a required gate. Light framing toward the payoff (“Gleich entdeckst du dein Reflex-Profil”).
2. **Consent — Layout B / Tone B1** — Thin step dots; short title; one emotional lead; three links (Sicherheit / Nutzung / Datenschutz) to full lawyer text; checkbox; CTA **„Reflex-Profil entdecken“**.
3. **Kontaktname** — Same required field; shorter benefit line; same step-dot pattern.
4. **Für wen? → subject profile** — Self vs child (existing fields). Then **go directly** into the Reflex Profile (no required “now or later” bottom sheet as a stop).
5. **Payoff: personal Reflex Profile** — Emotional discover moment. The analysis-placeholder gate is **removed** from the required path; at most one optional lead sentence may appear at Reflex Profile start.

Optional analytics surfaces (e.g. entry-points chips) stay **after** the payoff or remain non-blocking.

## Consent UX (Layout B)

- Progress: four thin dots; Account done ⇒ two filled when on Consent.
- Title: short (e.g. „Kurz zustimmen“).
- Lead: one B1 sentence — no “relevant / lohnt sich / Fragebogen”.
- Rows: Sicherheit · Nutzung · Datenschutz → open full text in a **bottom sheet** (one document per row). Full text unchanged.
- One checkbox + primary CTA **„Reflex-Profil entdecken“**.

## Copy system (pre-payoff)

**Prefer:** entdecken, persönlich, Reflex-Profil, in deinem Tempo.  
**Avoid before payoff:** Fragebogen, Assessment, relevant?, lohnt sich?, ausfüllen.

Child path uses the same tone (e.g. discovering this profile), fields unchanged.

## Small reliefs (no new obligations)

- Remove the analysis-placeholder screen from the onboarding gate (optional one-liner only at Reflex Profile start).
- Remove the required post–Für-wen bottom sheet; enter Reflex Profile directly. Soft exit to Dashboard if the user abandons mid-profile remains allowed.
- Keep Kontaktname; only shorten framing + share step dots.

## Edge cases

- Full consent texts must remain reachable before the checkbox; agreeing without reading remains possible, but links must not disappear.
- Back navigation keeps step state consistent; no re-prompting Consent if already granted.
- Consent save stays best-effort (local cache + remote upsert); no extra error screens that re-bloat the path.
- Soft abandon of Reflex Profile → Dashboard without re-inflating pre-payoff steps.

## Success criteria (qualitative — Goal D)

- Consent feels scannable; less chrome than today’s three tab text walls.
- CTA and framing sound like discovering a profile, not completing a form.
- Same required gates; noticeably less “why am I reading this / wall of text” feeling.

## Implementation notes (for later plan)

Likely touchpoints (indicative, not a plan):

- `consent_screen.dart` — Layout B shell around existing bilingual lawyer copy
- Onboarding gate / dashboard redirects — analysis placeholder, username, for-whom → reflex profile
- `for_whom_screen.dart` — remove or demote required bottom sheet
- `analysis_placeholder_screen.dart` — remove from gate or reduce to one line
- Shared step-dot / progress chrome for pre-payoff screens
- l10n ARB strings for B1 copy (DE/EN)

No schema/consent-version change expected unless product later revises legal text (out of scope here).

## Decisions log

| # | Decision | Outcome |
|---|---|---|
| 1 | Surface | App first-run only (not website) |
| 2 | Pain | Too many screens **and** too many inputs (feel) |
| 3 | Constraints | Account + Consent stay before payoff; compress feel |
| 4 | Success bar | Feel lighter (progress + less text), not hard screen-count cut |
| 5 | Approach | 1 (progress + Consent lightness) |
| 6 | Consent density | B light |
| 7 | Payoff tone | B1 discover / Reflex-Profil entdecken |
| 8 | Step sequence | Account → Consent B/B1 → Kontaktname → Für wen → Reflex Profile |
