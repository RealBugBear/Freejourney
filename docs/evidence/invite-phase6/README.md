# Phase 6 — Impulse (MVP)

**Datum:** 2026-08-21  
**Flag:** `kInviteEnabled = false`, `kInviteImpulseI2Enabled = false`

## Scope (Freigabe)

- Nur I1 unter dem erstmaligen Reflexprofil-Ergebnis (`passedAssessment == null`)
- I2 nicht verdrahtet; Konstante aus
- Policy rein + Unit-Tests
- Kein Dialog / Push / Badge / Stufe 2

## Regeln in `invite_prompt_policy.dart`

- ≤ 1 Impuls / 30 Tage
- ≤ 3 im ersten Jahr
- nach 2× Anzeigen ohne Antippen → dauerhaft still
- Mood ≤ 2 in 24 h → unterdrücken
- laufende Trainingssitzung → unterdrücken

## Ignore-Semantik (Korrektur)

- Anzeigen setzt `last_show_unanswered`, **ohne** Ignore-Zähler.
- Erst beim **nächsten** Auswerten wird eine unbeantwortete Anzeige als
  ignoriert gezählt (`settleUnansweredImpulse`).
- Tap beantwortet die offene Anzeige und setzt die Ignore-Serie auf 0.
- Dauerhaft still erst nach **zwei settled** Ignorierungen.
- Mood-/Store-Fehler → fail-closed, kein Show-Eintrag.
- `kInviteEnabled == false` → keine Mood-/Store-Abfragen.

## Tests (beobachtet)

- Policy + Evaluator + Store + Karte → **25/25**
- Analyze → No issues found

Flag bleibt `false`; kein Commit. Phase 7 kann nach Freigabe starten.
