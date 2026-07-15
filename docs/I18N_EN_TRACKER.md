# I18N-EN Tracker — Vollständige englische Lokalisierung

**Auftrag:** `docs/TRANSLATION_EN_PROMPT.md` (Quelle der Wahrheit für Regeln, Style Guide, Definition of Done).
**Branch:** `i18n/english-localization` (abgezweigt von `main` @ `178d4bc`).
**Diese Datei ist das Gedächtnis über Session-Grenzen hinweg** — nach jedem Arbeitsblock aktualisieren.

## Phasen-Checkliste

- [ ] **Phase 0 — Einstieg:** Branch ✅, Tracker angelegt, Pflichtdokumente gelesen
- [ ] **Phase 1 — Audit:** Audit-Skript, Kategorisierung aller Funde, DB-Content-Analyse, Systemebene, EN-Qualitätsreview, 🔶-Checkpoint
- [ ] **Phase 2 — Externalisierung:** alle nutzersichtbaren Strings über ARB-Keys
- [ ] **Phase 3 — Übersetzung:** Glossar, alle EN-Werte nach Style Guide, 12 DE==EN-Keys aufgelöst
- [ ] **Phase 4 — Systemebene:** InfoPlist.strings de/en, Android, Push (client+server), Locale-Formate
- [ ] **Phase 5 — Verifikation:** Parity-Gate (Make-Target), Audit=0, EN-Screenshots beide Umschaltwege, Layout-Check, analyze 0/0 + Suite grün
- [ ] **Phase 6 — Abschlussreport:** einfaches Deutsch, 🔶-Blöcke für Recht/DB/Bilder/Store

## Vorab-Befunde (Session-Start 2026-07-15)

- Working Tree enthielt unversionierte, verifizierte Arbeit aus Sessions 2026-07-08..14
  (T24, T26, T08, Sprachwahl-l10n-Anfang) → als Baseline-Commit `178d4bc` auf `main`
  gesichert, damit i18n-Commits sauber getrennt bleiben. Baseline: analyze sauber,
  **245/245 Tests grün**.
- `l10n.yaml`: Template ist `app_de.arb` (Hinweis: CLAUDE.md §4 nennt fälschlich
  `app_en.arb` als Template — im Abschlussreport korrigieren/flaggen).
- Untracked belassen (lokale Tool-Konfig, nicht App-Bestandteil): `.claude/`, `.cursor/`.

## Datei-Status (wird vom Audit in Phase 1 befüllt)

Status-Werte: `offen` → `externalisiert` → `übersetzt` → `verifiziert`

| Bereich | Datei | Funde | Status |
|---|---|---|---|
| _(Audit ausstehend)_ | | | |

## Arbeitslog

- **2026-07-15:** Session-Start. Baseline-Commit `178d4bc` (In-flight-Arbeit gesichert),
  Branch `i18n/english-localization` angelegt, Tracker erstellt. Phase 1 (Audit) begonnen.
