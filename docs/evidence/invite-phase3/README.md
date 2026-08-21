# Phase 3 — Invite screen + impact tree

**Datum:** 2026-08-21 (Visual-Iteration 2)  
**Flag:** `kInviteEnabled = false` (Oberfläche gegated)

## Geliefert (nach Review-Korrektur)

- Route `/einladen` + `inviteGateRedirect`
- `ImpactTreeCard` / `ImpactTreePainter`
  - Leerzustand: kurzer gebogener Sprössling mit zwei Blattansätzen
  - Wachstum: linke/rechte Spitzen nur von gleichen Seiten; Cubic-Bögen; Krone
  - **Crown-Tiers:** ≤12 → Tier 0 · 13–24 → Tier 1 · ≥25 → Tier 2
  - Semantics: aggregiertes Label mit `excludeSemantics: true`; bei 0 =
    Überschrift + Empty-Hinweis
- Gate-Test auf Flag reduziert (`kInviteEnabled == false`)
- Goldens: `tree_{0,1,5,12,13,25}_{light,dark}.png`

## Noch offen (bewusst, nicht Phase-3-Fehler)

1. **600-ms-Einwachs-Animation:** `previousActivatedCount` wird vom Screen
   noch nicht übergeben. Anschluss in **Phase 5**.
2. **Offline mit zuletzt geholtem Code:** Cache in **Phase 5**.
3. **Router-Widgettest für `inviteGateRedirect`:** wartet auf unrelated
   Compile-Fix in `reflex_profile_screen.dart`.

## Tests (beobachtet)

`flutter test test/features/invite/` → **41/41 passed** (inkl. Phase-4-Redeem-Tests)  
Phase-3-Anteil: Crown-Tiers, Goldens 13/25, Semantics bei 0 — grün.
