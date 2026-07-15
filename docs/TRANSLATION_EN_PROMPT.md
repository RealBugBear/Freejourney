# Prompt: Vollständige englische Lokalisierung der App (EN-i18n)

> **Anleitung für Alexander:** Diesen Prompt in einer frischen Claude-Code-Session im App-Repo
> (`~/dev/claudvibes/corejourney/app`) ausführen. Einstieg wie immer: Die Session liest zuerst
> `docs/LAUNCH_MASTER_PROMPT.md` und die Regeln in `docs/LAUNCH_TASK_PROMPTS.md`, dann diesen
> Prompt wörtlich abarbeiten. Der Task ist groß — er ist in Phasen mit Zwischen-Checkpoints
> geschnitten und kann über mehrere Sessions laufen (Fortschritt wird in einem Tracker-Dokument
> festgehalten, siehe Phase 0).

---

## Rolle

Du bist ein erfahrener Flutter-Entwickler **und** professioneller DE→EN-Fachübersetzer für
Gesundheits-Apps. Du arbeitest sorgfältig, in kleinen verifizierbaren Schritten, und du
übersetzt nie wörtlich-mechanisch, sondern idiomatisch und zielgruppengerecht.

## Auftrag

Mache die App **Reflex Journey** vollständig und professionell zweisprachig (Deutsch/Englisch).
Deutsch ist die Quellsprache und bleibt unverändert. Ziel: Ein englischsprachiger Nutzer, der
beim Erststart (Sprachwahl-Screen vor dem Login) oder später in den Einstellungen
(`lib/features/settings/presentation/screens/language_selection_screen.dart`) Englisch wählt,
sieht **nirgendwo in der App mehr deutschen Text** — auf keinem Screen, in keinem Dialog, in
keiner Fehlermeldung, in keiner Push-Nachricht, in keinem System-Permission-Dialog.

## Kontext: Warum Sorgfalt hier besonders zählt

- Reflex Journey ist eine gesundheitsnahe App (Reflexintegrations-Training), Zielgruppe sind
  Eltern, es geht auch um Kinderdaten. Die Texte müssen professionell, warm und präzise sein —
  eine holprige Übersetzung zerstört hier sofort Vertrauen.
- **Rechtliche Leitplanke (gilt für BEIDE Sprachen):** Keine Heilversprechen, keine
  Diagnose-/Therapie-Sprache, keine medizinischen Wirkversprechen. Englische Formulierungen wie
  "treats", "cures", "heals", "therapy for", "clinically proven" sind verboten. Erlaubt sind
  Formulierungen über Übung, Training, Begleitung und Beobachtung (siehe Style Guide unten).
- Rechtstexte (Datenschutzerklärung, AGB/Nutzungsbedingungen, Einwilligungen/Consent-Texte)
  sind ein **Anwalts-Thema** und dürfen **nicht frei übersetzt** werden → nur inventarisieren
  und im Abschlussreport flaggen (Phase 6).

## Ist-Zustand (Stichprobe vom 2026-07-15 — in Phase 1 selbst re-verifizieren)

- i18n-System: Flutter gen-l10n. `l10n.yaml` → Template `lib/l10n/app_de.arb`,
  Übersetzung `lib/l10n/app_en.arb`, generierte Klasse `AppLocalizations`.
- Die beiden ARB-Dateien sind synchron: je 316 Keys, keine fehlenden Keys. **Das eigentliche
  Problem liegt woanders:**
- **≥645 hartcodierte deutsche String-Vorkommen in ≥91 Dart-Dateien** unter `lib/` (gemessen
  nur über Umlaute/ß — deutsche Strings ohne Sonderzeichen wie „Weiter“, „Speichern“,
  „Training starten“ kommen noch obendrauf). Diese Texte laufen am l10n-System vorbei und
  bleiben deshalb in der englischen Version deutsch. Betroffen sind u. a. Journal, Progress,
  Golden Day, Chat, Settings/Theme, Onboarding-Hints, Router, Push-/Notification-Services,
  Sentry-/Logger-Meldungen.
- 12 Keys haben identische Werte in DE und EN (z. B. `stressLabel`, `silentMode`,
  `tutorialMode`) — einzeln prüfen: manche sind legitim gleich (`appTitle`), manche sind
  schlicht unübersetzt.
- **Trainings-/Übungsinhalte liegen (auch) in Supabase** — deutsche Texte u. a. in
  `supabase/exercises_migration.sql` und weiteren Migrations. Das ist der Kern-Content der App
  und braucht eine eigene Architektur-Entscheidung (Phase 1 → Founder-Vorlage).
- iOS-Permission-Texte (`ios/Runner/Info.plist`, z. B. Standort aus T13, Push) und ggf.
  Android-Ressourcen sind vermutlich nur deutsch → Systemebene in Phase 4.
- Trainings-Illustrationen unter `assets/images/trainings/` haben deutsche Dateinamen und
  enthalten evtl. eingebetteten deutschen Text → nur inventarisieren, nicht neu zeichnen.

## Harte Regeln (gelten in jeder Phase)

1. **Keine Logik-Änderungen.** Nur Strings externalisieren und übersetzen. Refactorings nur,
   wo sie für die Externalisierung zwingend nötig sind (z. B. `BuildContext`/`l10n` in ein
   Widget durchreichen).
2. **Kleine Commits pro Feature-Bereich** (z. B. „i18n: journal strings externalized“), nach
   jedem Commit: `flutter analyze` sauber und Testsuite grün (Stand zuletzt: 215 Tests).
3. **ARB-Disziplin:** DE bleibt Template und Quelle der Wahrheit. Jeder neue Key kommt
   gleichzeitig in `app_de.arb` und `app_en.arb`, mit `@key`-Metadaten (`description`, bei
   Platzhaltern `placeholders`). Semantische Key-Namen (`journalEmptyStateTitle`), keine
   Nummerierungen. Bestehende Key-Namen nicht umbenennen.
4. **ICU korrekt nutzen:** Plurals (`{count, plural, one{…} other{…}}`), Platzhalter statt
   String-Konkatenation, `select` für Genus-/Fallunterscheidungen. Niemals Sätze aus
   Fragmenten zusammensetzen — Englisch hat andere Satzstellung.
5. **Rechtstexte, Anwalts-Content, `docs/`-Dokumente, Store-Texte: nicht anfassen.**
   Store-Copy ist separat (R3). Nur flaggen.
6. **Keine Prod-Datenbank-Zugriffe, keine Live-Migrations.** DB-Änderungen werden nur als
   Migration + Vorschlag vorbereitet und dem Founder vorgelegt (Regel-7-Muster: 🔶-Block).
7. **Keine Heilversprechen** — in keiner der beiden Sprachen (siehe Style Guide).
8. **Evidenz-Pflicht:** Screenshot-Belege für die englische UI (Muster: Widget-Test-Harness
   mit FontLoader-Trick, wie in `docs/evidence/T04/` etabliert; Ablage in
   `docs/evidence/I18N-EN/`).

## Phasenplan

### Phase 0 — Einstieg & Arbeitsstand

1. `docs/LAUNCH_MASTER_PROMPT.md` und Regeln in `docs/LAUNCH_TASK_PROMPTS.md` lesen.
2. Feature-Branch anlegen (z. B. `i18n/english-localization`).
3. Fortschrittsdatei `docs/I18N_EN_TRACKER.md` anlegen: Phasen-Checkliste + Tabelle aller
   betroffenen Dateien mit Status (offen / externalisiert / übersetzt / verifiziert). Diese
   Datei ist das Gedächtnis über Session-Grenzen hinweg — nach jedem Arbeitsblock aktualisieren.

### Phase 1 — Vollständiges Audit (erst messen, dann anfassen)

1. Schreibe ein Audit-Skript (`scripts/i18n_audit.py` o. ä.), das **alle** String-Literale in
   `lib/**` (ohne `lib/l10n/`, ohne `*.g.dart`) extrahiert und heuristisch filtert
   (raus: Asset-Pfade, Routen, Keys, URLs, IDs, Log-Tags — die bleiben englisch/technisch und
   werden NICHT übersetzt). Der Umlaut-Grep
   `grep -rn --include="*.dart" -E "[äöüÄÖÜß]" lib --exclude-dir=l10n` ist nur die Untergrenze.
2. Kategorisiere jeden Fund: **(a)** UI-Text sichtbar für Nutzer, **(b)** Fehlermeldung/Snackbar,
   **(c)** Push-/Notification-Text (auch serverseitig: `supabase/functions/` prüfen!),
   **(d)** Log-/Sentry-/Debug-Text (→ auf Englisch vereinheitlichen, kein ARB-Key nötig),
   **(e)** Rechts-/Consent-Text (→ nur flaggen), **(f)** DB-Content aus Supabase.
3. DB-Content-Analyse: Welche Tabellen/Spalten enthalten nutzersichtbaren deutschen Text
   (Übungen, Trainingsanleitungen, Kategorien …)? Mengengerüst erstellen und **einen
   Lösungsvorschlag ausarbeiten** (z. B. Übersetzungstabelle `exercise_translations` mit
   `locale`-Spalte vs. JSONB-Spalten; Empfehlung mit Begründung, Migrations-Entwurf lokal).
4. Systemebene inventarisieren: `Info.plist`-Usage-Strings, Android `strings.xml`/Label,
   App-Name, Notification-Channels, Datums-/Zahlenformatierung (hartcodierte `DateFormat`
   mit deutschem Pattern oder fixem `'de_DE'`-Locale suchen).
5. Bestehende 316 EN-Werte einem Qualitäts-Review unterziehen (liest sich das wie von einem
   Muttersprachler? Konsistente Terminologie?) — Korrekturbedarf in den Tracker.
6. **Checkpoint an den Founder (🔶):** Mengengerüst gesamt, DB-Content-Vorschlag zur
   Entscheidung, Liste geflaggter Rechtstexte. Mit dem Code-Teil (Phase 2/3) darfst du ohne
   Rückfrage weitermachen — nur die DB-Entscheidung wartet auf ein Go.

### Phase 2 — Externalisierung (Feature für Feature)

Pro Feature-Bereich (Reihenfolge: nutzersichtbar zuerst — Onboarding/Sprachwahl → Auth →
Home/Training → Journal → Progress → Golden Day → Settings → Trainer-Discovery → Rest):

1. Hartcodierte Strings durch ARB-Keys ersetzen, DE-Wert = exakt der bisherige deutsche Text
   (keine stillen Umformulierungen).
2. `flutter gen-l10n`, `flutter analyze`, Tests. Commit.
3. Tracker-Datei aktualisieren.

Launch-versteckte Bereiche (Community/Feed, Video — `lib/config/launch_flags.dart`) haben
niedrigste Priorität, werden aber mit-externalisiert, damit nichts zurückbleibt.

### Phase 3 — Professionelle Übersetzung

1. Zuerst `docs/GLOSSARY_DE_EN.md` anlegen (Startbestand siehe unten) und **dann erst**
   übersetzen — Terminologie-Konsistenz ist wichtiger als Tempo.
2. Alle EN-Werte schreiben/überarbeiten nach dem Style Guide unten. In Batches pro Feature,
   nicht Key für Key ohne Kontext: Immer den Screen-Zusammenhang lesen (welches Widget zeigt
   den Text wo?), damit Ton und Länge passen.
3. Die 12 DE==EN-Keys auflösen (übersetzen oder als „bewusst identisch“ im Tracker markieren).

### Phase 4 — Systemebene & Ränder

1. iOS: `InfoPlist.strings` für de/en anlegen (alle `NS…UsageDescription`, `CFBundleDisplayName`
   falls sprachabhängig gewünscht — Empfehlung: App-Name bleibt „Reflex Journey“, ist bereits
   englisch). Xcode-Projekt: `en` als Lokalisierung registrieren (`knownRegions`).
2. Android: nutzersichtbare Ressourcen prüfen (`android/app/src/main/res/values*/`).
3. Push-Notifications: client- und serverseitige Texte (Supabase Edge Functions) lokalisieren —
   serverseitig braucht es die Nutzer-Locale; wenn die nirgends gespeichert ist, minimalen
   Vorschlag ausarbeiten und als 🔶 vorlegen statt eigenmächtig das Profil-Schema zu ändern.
4. Datums-, Zeit- und Zahlenformate überall über das aktive Locale formatieren
   (`MaterialApp.locale`/`Localizations.localeOf`), nie über fixes `'de_DE'`.
5. Fehlerpfade: Supabase-/Auth-Fehler, Offline-Meldungen, leere Zustände, Lade-Zustände,
   Bestätigungs-Dialoge, Snackbars — das sind die Stellen, die in Übersetzungsprojekten
   klassisch vergessen werden.

### Phase 5 — Verifikation (nichts gilt ohne Beleg)

1. **Parity-Gate als Skript** (`scripts/i18n_check.py`, in `make release-readiness-mobile`
   oder als eigenes Make-Target einhängen): DE- und EN-Keyset identisch, keine leeren Werte,
   Platzhalter-Mengen pro Key identisch, keine deutschen Umlaute in `app_en.arb`-Werten.
2. **Statisches Gate:** Audit-Skript aus Phase 1 erneut laufen lassen → 0 nutzersichtbare
   hartcodierte Strings in `lib/**`.
3. **Visuelles Gate:** App-Durchlauf komplett auf Englisch — beide Umschaltwege testen:
   (a) Frischinstallation → Sprachwahl-Screen vor Login → Englisch, (b) laufende App →
   Einstellungen → Sprache wechseln (greift der Wechsel sofort, ohne Neustart?). Screenshots
   aller Haupt-Screens in EN nach `docs/evidence/I18N-EN/` (Widget-Test-Harness-Muster).
4. **Layout-Prüfung:** Englische Texte sind oft kürzer, manchmal länger — auf Overflows,
   abgeschnittene Buttons und unschöne Umbrüche prüfen (Founder-Auflage: keine hässlichen
   UI-Lücken).
5. `flutter analyze` 0/0, komplette Testsuite grün.

### Phase 6 — Abschlussreport (für einen Nicht-Techniker geschrieben)

In einfachem Deutsch, in `docs/I18N_EN_TRACKER.md` und als Chat-Zusammenfassung:

1. Was ist jetzt vollständig englisch (mit Screenshot-Verweisen)?
2. Offene Punkte, die NICHT automatisch erledigt wurden, je mit Empfehlung als 🔶-Block:
   - Rechtstexte/Consent → Anwalt (Verweis `docs/legal/ANWALTS_BRIEFING.md`)
   - DB-Content-Übersetzung → wartet ggf. auf Founder-Go + Migration in Standard-Session
   - Bilder mit eingebettetem deutschem Text (Liste)
   - Store-Texte EN (separater Task, R3-Umfeld)
3. Glossar-Verweis, damit künftige Texte konsistent bleiben.

---

## English Style Guide (für alle EN-Texte verbindlich)

*This section is intentionally in English — it defines the voice of the English app.*

- **Variant:** US English (en-US). Serial comma. Metric units stay metric.
- **Audience:** Parents (and movement trainers). Often reading on the go, sometimes worried.
  No medical background assumed.
- **Voice:** Warm, calm, encouraging, plain. Address the user as "you". Short sentences.
  Reading level ~grade 6–8. Never clinical-cold, never childish-cute.
- **Capitalization:** Title Case for buttons, tabs, and screen titles (Apple HIG);
  sentence case for body text, descriptions, and helper text.
- **Regulatory-safe wording:** The app supports *practicing exercises* and *tracking
  observations*. Allowed: "exercises", "training", "practice", "may support", "designed to
  accompany", "track your observations". Forbidden: "treat(ment)", "cure", "heal", "therapy",
  "diagnose", "clinically proven", "medical". When in doubt, describe what the user *does*,
  not what the app *achieves medically*.
- **Do not translate mechanically.** "Übung abgeschlossen! Weiter so!" →
  "Exercise complete — keep it up!", not "Exercise completed! Continue so!".
- **Beware false-friend abbreviations:** German reflex abbreviations differ in English —
  e.g. German *FLR (Furcht-Lähmungs-Reflex)* is English **FPR (fear paralysis reflex)**.
  Verify every reflex name against the glossary; never carry a German abbreviation over.

### Glossar-Startbestand (`docs/GLOSSARY_DE_EN.md` — in Phase 3 erweitern)

| Deutsch | Englisch | Hinweis |
|---|---|---|
| Reflexintegration(s-Training) | reflex integration (training) | nie „reflex therapy“ |
| frühkindliche Reflexe | primitive reflexes | fachüblich |
| Moro-Reflex | Moro reflex | Eigenname, groß |
| Spinaler Galant(-Reflex) | spinal Galant reflex | |
| Furcht-Lähmungs-Reflex (FLR) | fear paralysis reflex (FPR) | Abkürzung ändert sich! |
| Übung | exercise | |
| Training / Trainingseinheit | training / session | |
| Fortschritt | progress | |
| Tagebuch/Journal | journal | |
| Goldener Tag / Golden Day | Golden Day | Produktbegriff, bleibt |
| Trainer:in | trainer | |
| Einstellungen | Settings | |

---

## Was Erfolg bedeutet (Definition of Done)

- [ ] Audit-Skript findet 0 nutzersichtbare deutsche Strings außerhalb `app_de.arb`
- [ ] Parity-Skript grün und als Make-Target dauerhaft verankert
- [ ] Beide Sprachwechsel-Wege verifiziert (Erststart + Einstellungen), Screenshots in `docs/evidence/I18N-EN/`
- [ ] iOS-Permission-Dialoge englisch bei englischem Gerät/App-Locale
- [ ] Keine Layout-Brüche in EN, `flutter analyze` 0/0, Testsuite grün
- [ ] Glossar + Tracker + Abschlussreport liegen in `docs/`
- [ ] Alle bewusst offenen Punkte (Recht, DB-Content, Bilder, Store) als 🔶 mit Empfehlung vorgelegt
