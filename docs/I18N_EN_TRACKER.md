# I18N-EN Tracker — Vollständige englische Lokalisierung

**Auftrag:** `docs/TRANSLATION_EN_PROMPT.md` (Quelle der Wahrheit für Regeln, Style Guide, Definition of Done).
**Endspurt + Mehrsprachen-Fundament:** `docs/I18N_STRUCTURE_PROMPT.md` (2026-07-19) — der
ausführungsfertige Prompt für alle Restarbeiten (W0–W8); Sessions steigen dort beim
„Nächsten Block“ ein. Künftige Sprachen: `docs/I18N_ADD_LANGUAGE.md` (entsteht in W7).
**Branch:** `i18n/english-localization` (abgezweigt von `main` @ `178d4bc`).
**Diese Datei ist das Gedächtnis über Session-Grenzen hinweg** — nach jedem Arbeitsblock aktualisieren.

**Nächster Block: W4/B6** (Launch-versteckte Features, siehe `docs/I18N_STRUCTURE_PROMPT.md`)

## Phasen-Checkliste

- [x] **Phase 0 — Einstieg:** Branch ✅, Tracker angelegt, Pflichtdokumente gelesen
- [x] **Phase 1 — Audit:** Audit-Skript, Kategorisierung, DB-/System-Analyse, EN-Review und 🔶-Checkpoint dokumentiert; keine Prod-Zugriffe
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

## Audit-Ergebnis Phase 1 (2026-07-15, `scripts/i18n_audit.py`)

**Mengengerüst** (Stand Commit-Basis `178d4bc`, 228 Dart-Dateien):

| Messwert | Anzahl |
|---|---|
| Nicht-technische String-Literale gesamt | 2653 |
| davon deutsch (Heuristik) | 1331 |
| **Nutzersichtbar hartcodiert (Gate-Scope a/b/c)** | **1684** (davon 1014 deutsch) |
| Log-/Sentry-/Debug-Texte (d) → auf Englisch vereinheitlichen, kein ARB | 164 |
| Rechts-/Consent-Texte (e) → NUR flaggen, Anwalt | 335 (consent_screen.dart) |
| Bilingual-by-design (De/En-Feldpaare, z. B. exercise.dart) | ~450 → kein Handlungsbedarf im Gate |
| Hartcodierte `de_DE`-Datumsformatierung (g) | 17 Stellen |

**Zentrale Architektur-Befunde:**

1. **Content-Ebene ist bereits zweisprachig gebaut:** `Exercise`-Modell (`titleDe/En`, `label(locale)`, …),
   DB-Tabellen `exercises` + `reflex_packages` mit `_de`/`_en`-Spalten, Seeds in
   `supabase/exercises_migration.sql`/`schema.sql` beidsprachig gefüllt (16 Übungen: moro 7,
   tlr 5, spinal_galant 4). → Keine neue Übersetzungsarchitektur nötig; offen ist nur die
   Live-DB-Verifikation (🔶, s. u.) und zwei Locale-Bugs im Rendering
   (`immersive_exercise_screen.dart:261` Fallback 'HALTEN', `training_session_screen.dart:147` inline isDE).
2. **Reflex-Fragebogen ist einsprachig deutsch:** `reflex_questionnaire_definitions.dart`
   (129 Fragen + Modul-/Titel-Texte). Lösung nach Codebasis-Muster: De/En-Feldpaare im
   Definitionsmodell (KEINE 129 nummerierten ARB-Keys). Größter Content-Block in Phase 2/3.
3. **`profiles.locale` existiert bereits in der DB** (default 'de', CHECK de/en) — aber die App
   schreibt die Sprachwahl nur in SharedPreferences. Für serverseitige Push-Lokalisierung
   (`_shared/reminder_copy.ts` + notify-*-Functions, alle deutsch-only) fehlt nur:
   App schreibt locale → profiles; Functions lesen sie. Kein Schema-Change nötig.
   Function-Deploy bleibt founder-gated.
4. **iOS:** 5 deutsche Usage-Descriptions in `Info.plist` (Camera, Mic, 2× Location, Calendars)
   → `InfoPlist.strings` de/en + `knownRegions` in Phase 4. **Android:** keine `strings.xml`
   (`@string/app_name`-Referenz im Manifest — Quelle in Phase 4 klären).
5. **Bestehende 316 ARB-Keys:** Parität perfekt (316/316, keine Leerwerte, Platzhalter identisch).
   EN-Qualität hoch/muttersprachlich. To-do Phase 3: en-US-Sweep („programme“→„program“,
   „cancelled“→„canceled“), 13 identische Keys als bewusst-identisch dokumentiert
   (Markennamen/Anglizismen: appTitle, goldenDay, dashboard, tutorialMode, …).
6. **DE-Quelltext-Typo (nur Notiz, DE bleibt unverändert):** `reflex_packages`-Seed
   „Tonischer Labirint Reflex“ → korrekt wäre „Labyrinth“; Founder entscheidet separat.

**Werkzeuge:** `scripts/i18n_audit.py` (Tokenizer-basiert, Kategorien a–g, `--gate` für Phase 5,
Allowlist `scripts/i18n_audit_allowlist.txt` für bewusste Ausnahmen wie „Reflex Journey“).

## 🔶 Founder-Checkpoint Phase 1

**Code darf ohne Rückfrage weiterlaufen; dieser Block verlangt keine sofortige Entscheidung.**

- **Mengengerüst am Handoff nach Onboarding + Dashboard:** 1.458 heuristische Gate-Kandidaten,
  davon 891 als deutsch erkannt, plus 17 feste `de`/`de_DE`-Formatierungen. Der Wert ist eine
  konservative Obergrenze und enthält noch technische Fehlklassifikationen; das End-Gate wird
  erst bei 0 realen nutzersichtbaren Hardcodes grün.
- **DB-Content-Empfehlung:** Keine neue Übersetzungstabelle und keine JSONB-Migration bauen.
  `exercises` und `reflex_packages` besitzen bereits `_de`/`_en`-Felder, die App-Modelle lesen
  sie locale-aware. Dieses bestehende Muster bleibt die Architektur. Eine Prüfung der Live-Daten
  wird in diesem Auftrag bewusst **nicht** ausgeführt, weil Prod-Zugriffe ausdrücklich verboten
  sind. Der einsprachige Fragebogen ist lokaler App-Content und wird analog als DE/EN-Feldpaar
  ergänzt.
- **Recht/Sicherheit:** `consent_screen.dart` (335 Literale) und der ungenutzte, aber
  rechtlich sensible `training_disclaimer_dialog.dart` (19 Literale) werden nicht frei
  übersetzt. Beide gehen mit Empfehlung an den Anwalt (`docs/legal/ANWALTS_BRIEFING.md`).
- **Systemrand:** iOS-Usage-Descriptions, Android-Ressourcen, client-/serverseitige Push-Copy
  und 17 feste deutsche Locale-Formate sind Phase 4. Ein Edge-Function-Deploy bleibt separat
  Founder-gated; im i18n-Auftrag wird nur lokaler Code vorbereitet und verifiziert.
- **EN-Audio-Assets:** Das Repository und `pubspec.yaml` enthalten ausschließlich
  `assets/sounds/announcements/de/`; englische Announcement-MP3s fehlen. Die sichtbaren
  Trainings-Cues sind lokalisiert, die bestehenden Audio-Pfade bleiben zur Funktionserhaltung
  unverändert deutsch. Englische Aufnahmen sind ein separater Content-/Asset-Blocker.
- **🔶 Kalender-/Privacy-Entscheidung vor Release:** Die vorhandene native Integration ist
  plattformübergreifend inkonsistent: iOS ruft ab iOS 17 vollen Kalenderzugriff auf, besitzt
  aber nur `NSCalendarsUsageDescription`; Android fragt `READ_CALENDAR`/`WRITE_CALENDAR` im
  Kotlin-Code an, während das Quell-Manifest diese Rechte nicht deklariert. Zusätzlich existiert
  ein Always-Location-Usage-Key, obwohl die App nur When-in-use anfragt. Entweder direkten
  Kalenderzugriff samt korrekter Permissions/Datenschutzangaben bewusst behalten oder auf den
  bereits möglichen ICS-/Share-Weg begrenzen. Im i18n-Auftrag wurde keine dieser Semantiken
  verändert.

## Datei-Status (Audit 2026-07-15)

Status-Werte: `offen` → `externalisiert` → `übersetzt` → `verifiziert`
(a/b/c = nutzersichtbar; d-log = auf Englisch vereinheitlichen; „sonst“ = e-legal/bilingual-ok/g-format)

| Bereich | Datei | a/b/c | d-log | sonst | Status |
|---|---|---|---|---|---|
| onboarding | features/onboarding/presentation/screens/entry_points_screen.dart | 50 | 0 | 0  | verifiziert (`0705c7c`, analyze + 245 Tests) |
| onboarding | features/onboarding/presentation/screens/for_whom_screen.dart | 21 | 0 | 0  | verifiziert (`0705c7c`, analyze + 245 Tests) |
| auth | features/auth/data/repositories/supabase_auth_repository.dart | 0 | 5 | 0  | verifiziert (technische Meldungen bereits EN) |
| auth | features/auth/presentation/screens/change_password_screen.dart | 1 | 0 | 0  | verifiziert (keine UI-Hardcodes) |
| auth | features/auth/presentation/screens/login_screen.dart | 14 | 0 | 0  | verifiziert (nur bewusste Sprach-Autonyme) |
| dashboard | features/dashboard/presentation/screens/dashboard_screen.dart | 76 | 0 | 4  | verifiziert (`2abf16a`, analyze + 245 Tests) |
| training | features/training/domain/models/exercise.dart | 0 | 0 | 445 bilingual-ok | verifiziert (DE/EN-Feldpaare) |
| training | features/training/domain/services/audio_announcement_service.dart | 0 | 1 | 0  | verifiziert (Log EN; fehlende EN-Audioassets separat geflaggt) |
| training | features/training/presentation/screens/immersive_exercise_screen.dart | 18 | 0 | 0  | verifiziert (sichtbare Cues DE/EN, Audit 0) |
| training | features/training/presentation/screens/immersive_session_screen.dart | 1 | 0 | 0  | verifiziert (nur technischer `_duo`-Assetsuffix) |
| training | features/training/presentation/screens/training_exercise_screen.dart | 32 | 0 | 0  | verifiziert (UI/Semantik DE/EN, Audit 0) |
| training | features/training/presentation/screens/training_intro_screen.dart | 8 | 0 | 0  | verifiziert (Audit 0, 5 DE/EN-Widget-Tests + 250 Tests) |
| training | features/training/presentation/screens/training_movement_screen.dart | 11 | 0 | 0  | verifiziert (Audit 0, ICU-Plural geprüft, 250 Tests) |
| training | features/training/presentation/screens/training_outro_screen.dart | 8 | 0 | 0  | verifiziert (DE/EN-Widgettest, Audit 0) |
| training | features/training/presentation/screens/training_position_screen.dart | 9 | 0 | 0  | verifiziert (Audit 0, Semantik/Dialog DE+EN, 250 Tests) |
| training | features/training/presentation/screens/training_preparation_screen.dart | 2 | 0 | 0  | verifiziert (Audit 0) |
| training | features/training/presentation/screens/training_session_screen.dart | 1 | 0 | 4  | verifiziert (sichtbare Copy DE/EN; Content-Felder bilingual) |
| training | features/training/presentation/screens/training_start_flow_screen.dart | 29 | 0 | 0  | verifiziert (Dialoge/Fehler DE/EN, Audit 0) |
| training | features/training/presentation/screens/vorrunde_interstitial_screen.dart | 9 | 0 | 0  | verifiziert (DE/EN-Widgettest, claim-safe EN) |
| training | features/training/presentation/services/in_app_music_service.dart | 3 | 2 | 0  | verifiziert (Anzeigenamen in ARB; technische Logs EN) |
| training | features/training/presentation/widgets/animated_progress_bar.dart | 7 | 0 | 0  | verifiziert (Semantik/Status DE/EN) |
| training | features/training/presentation/widgets/arc_swap_visualizer.dart | 2 | 0 | 0  | verifiziert (Steuerung DE/EN) |
| training | features/training/presentation/widgets/exercise_movement_widget.dart | 6 | 0 | 2  | verifiziert (Cues locale-aware; Content-Felder bilingual) |
| training | features/training/presentation/widgets/exercise_rest_widget.dart | 2 | 0 | 0  | verifiziert (Audit 0) |
| training | features/training/presentation/widgets/exercise_transition_widget.dart | 10 | 0 | 0  | verifiziert (DE/EN-Widgettest, Audit 0) |
| training | features/training/presentation/widgets/exercise_video_widget.dart | 2 | 0 | 0  | verifiziert (Audit 0) |
| training | features/training/presentation/widgets/music_picker_sheet.dart | 4 | 0 | 0  | verifiziert (DE/EN-Widgettest, Tracknamen lokalisiert) |
| training | features/training/presentation/widgets/parallel_lines_visualizer.dart | 2 | 0 | 0  | verifiziert (Steuerung DE/EN) |
| training | features/training/presentation/widgets/rhythm_visualizer.dart | 3 | 3 | 0  | verifiziert (Steuerung DE/EN; Logs technisch EN) |
| training | features/training/presentation/widgets/training_disclaimer_dialog.dart | 0 | 0 | 19 e-legal! | geflaggt – Anwalt, nicht frei übersetzen |
| training | features/training/presentation/widgets/training_intro_widget.dart | 2 | 0 | 0  | verifiziert (Modus/Statistik DE/EN) |
| training | features/training/presentation/widgets/training_outro_widget.dart | 1 | 0 | 0  | verifiziert (ICU-Anzahl DE/EN) |
| packages | features/packages/presentation/screens/packages_screen.dart | 0 | 0 | 0  | verifiziert (DE/EN-Paketnamen, Audit 0, 608-Key-Gate + Suite grün) |
| journal | features/journal/presentation/screens/journal_screen.dart | 0 | 0 | 0  | verifiziert (UI + aktives Monatsformat, Audit 0) |
| journal | features/journal/presentation/widgets/journal_entry_tile.dart | 0 | 0 | 0  | verifiziert (Dialoge/Timeline + locale-aware Datum/Uhrzeit, Audit 0) |
| progress | features/progress/presentation/screens/progress_overview_screen.dart | 0 | 0 | 0  | verifiziert (UI/ICU + DE `15.7`/EN `7/15`, Audit 0) |
| golden_day | features/golden_day/presentation/screens/golden_day_screen.dart | 0 | 0 | 0  | verifiziert (DE/EN-Widgettest, Audit 0) |
| assessment | features/assessment/domain/completion_questions.dart | 0 | 0 | 7 bilingual-ok | verifiziert (DE/EN-Feldpaare) |
| assessment | features/assessment/domain/draft_persistence_service.dart | 0 | 2 | 0  | verifiziert (B3; d-log bereits EN, keine UI) |
| assessment | features/assessment/domain/reflex_questionnaire_definitions.dart | 134 | 0 | 0  | verifiziert (123 Fragen, 8 Module, 5 Hilfen, 5 Flags als DE/EN-Feldpaare; Audit 0 a/b/c) |
| assessment | features/assessment/domain/services/reflex_profile_pdf_service.dart | 0 | 0 | 0  | verifiziert (B3; `ReflexProfilePdfCopy` + locale-aware Content, Audit 0) |
| assessment | features/assessment/presentation/providers/reflex_profile_provider.dart | 0 | 0 | 0  | verifiziert (B3; Fallbacks via ARB/`lookupActiveAppLocalizations`, Exceptions EN) |
| assessment | features/assessment/presentation/screens/analysis_placeholder_screen.dart | 0 | 0 | 0  | verifiziert (B3, Audit 0) |
| assessment | features/assessment/presentation/screens/duration_recommendation_screen.dart | 0 | 0 | 0  | verifiziert (B3; ICU-Bodies + `PrimitiveReflex.label`, Audit 0) |
| assessment | features/assessment/presentation/screens/reflex_profile_demo_screen.dart | 0 | 0 | 0  | verifiziert (B3, Audit 0) |
| assessment | features/assessment/presentation/screens/reflex_profile_result_helpers.dart | 0 | 0 | 0  | verifiziert (Modulnamen DE/EN; keine a/b/c-Hardcodes) |
| assessment | features/assessment/presentation/screens/reflex_profile_result_screen.dart | 0 | 0 | 0  | verifiziert (B3; PDF-Aufrufer verdrahtet, Audit 0) |
| assessment | features/assessment/presentation/screens/reflex_profile_screen.dart | 0 | 0 | 0  | verifiziert (B3, Audit 0) |
| assessment | features/assessment/presentation/widgets/reflex_radar_chart.dart | 0 | 0 | 0  | verifiziert (B3; Leerzustand ARB, Audit 0) |
| accompaniment | features/accompaniment/presentation/screens/accompaniment_screen.dart | 0 | 0 | 0  | verifiziert (UI/Fehler/Termine DE/EN, Audit 0) |
| mood | features/mood/presentation/widgets/mood_chart_widget.dart | 0 | 0 | 0  | verifiziert (locale-aware DE `15.7`/EN `7/15`, Audit 0) |
| mood | features/mood/presentation/widgets/mood_checkin_sheet.dart | 0 | 0 | 0  | verifiziert (DE/EN, Audit 0) |
| mood | features/mood/presentation/widgets/mood_trend_chart.dart | 0 | 0 | 0  | verifiziert (DE/EN, Audit 0) |
| mood | features/mood/presentation/widgets/note_entry_sheet.dart | 0 | 0 | 0  | verifiziert (locale-aware Datum, Audit 0) |
| mood | features/mood/presentation/widgets/training_experience_sheet.dart | 0 | 0 | 1 technischer Identifier | verifiziert (stabile Enums + exakte Audit-Ausnahme `training`) |
| settings | features/settings/presentation/screens/settings_screen.dart | 0 | 0 | 0  | verifiziert (Sprachnamen + locale-aware Uhrzeit, Audit 0) |
| settings | features/settings/presentation/widgets/theme_selector.dart | 0 | 0 | 0  | verifiziert (DE/EN, Audit 0) |
| profile | features/profile/data/repositories/profile_repository.dart | 0 | 3 | 0  | verifiziert (technische Logs bereits EN) |
| profile | features/profile/domain/models/profile.dart | 0 | 0 | 0  | verifiziert (lokalisierter Fallback durch Consumer) |
| profile | features/profile/presentation/screens/profile_screen.dart | 0 | 0 | 0  | verifiziert (UI/Fehler/Datum/ICU DE/EN, Audit 0) |
| profile | features/profile/presentation/screens/username_setup_screen.dart | 0 | 0 | 0  | verifiziert (UI/Validierung DE/EN, Audit 0) |
| trainer | features/trainer/data/repositories/supabase_trainer_application_repository.dart | 0 | 2 | 0  | verifiziert (B4; d-log EN, keine UI) |
| trainer | features/trainer/domain/models/appointment.dart | 0 | 0 | 0  | verifiziert (B4; leere Fallbacks, Labels im UI via ARB) |
| trainer | features/trainer/domain/models/trainer_application.dart | 0 | 0 | 0  | verifiziert (B4; `statusLabel(l10n)`, Audit 0) |
| trainer | features/trainer/domain/models/trainer_client.dart | 0 | 0 | 0  | verifiziert (B4; leerer Namens-Fallback) |
| trainer | features/trainer/domain/models/trainer_profile.dart | 0 | 0 | 0  | verifiziert (B4; leerer Namens-Fallback) |
| trainer | features/trainer/domain/services/calendar_service.dart | 0 | 3 | 0  | verifiziert (B4; ICS-Titel via `lookupActiveAppLocalizations`, d-log EN) |
| trainer | features/trainer/domain/services/trainer_notification_service.dart | 7 | 3 | 0  | verifiziert (B2 `f6e1012`, Alerts + Fallbackname ARB, Logs EN) |
| trainer | features/trainer/presentation/providers/trainer_provider.dart | 0 | 0 | 0  | verifiziert (B4; Debug/Fallbacks/Activate via ARB, Audit 0) |
| trainer | features/trainer/presentation/screens/appointment_proposal_screen.dart | 0 | 0 | 0  | verifiziert (B4, Audit 0) |
| trainer | features/trainer/presentation/screens/appointment_scheduler_screen.dart | 0 | 3 | 0  | verifiziert (B4; UI ARB, d-log EN, Audit 0 a/b/c) |
| trainer | features/trainer/presentation/screens/trainer_application_form_screen.dart | 0 | 0 | 0  | verifiziert (B4, Audit 0) |
| trainer | features/trainer/presentation/screens/trainer_application_intro_screen.dart | 0 | 0 | 0  | verifiziert (B4, Audit 0) |
| trainer | features/trainer/presentation/screens/trainer_application_status_screen.dart | 0 | 0 | 0  | verifiziert (B4, Audit 0) |
| trainer | features/trainer/presentation/screens/trainer_client_detail_screen.dart | 0 | 0 | 0  | verifiziert (B4; Bänder/Notizen/Datum locale-aware, Audit 0) |
| trainer | features/trainer/presentation/screens/trainer_clients_screen.dart | 0 | 0 | 0  | verifiziert (B4; Paketnamen + Debug-Panel ARB, Audit 0) |
| trainer | features/trainer/presentation/screens/trainer_dashboard_screen.dart | 0 | 0 | 0  | verifiziert (B4; Termine/Kalender/locale Dates, Audit 0) |
| trainer | features/trainer/presentation/screens/trainer_public_profile_screen.dart | 0 | 0 | 0  | verifiziert (bereits ARB; B4 Audit 0) |
| trainer | features/trainer/presentation/screens/trainer_requests_screen.dart | 0 | 0 | 0  | verifiziert (B4, Audit 0) |
| trainer | features/trainer/presentation/widgets/osm_attribution.dart | 0 | 0 | 0  | verifiziert (B4; Attribution ARB, Audit 0) |
| trainer | features/trainer/presentation/widgets/trainer_location_picker_widget.dart | 0 | 0 | 0  | verifiziert (B4; Tip ARB, Audit 0) |
| chat | features/chat/data/repositories/supabase_chat_repository.dart | 0 | 4 | 0  | verifiziert (B5; Call-Request-Content via ARB/`lookupActiveAppLocalizations`) |
| chat | features/chat/domain/models/chat_channel.dart | 0 | 0 | 0  | verifiziert (B5; `channelDisplayName(l10n)`, Audit 0) |
| chat | features/chat/presentation/navigation/chat_navigation.dart | 0 | 0 | 0  | verifiziert (B5, Audit 0) |
| chat | features/chat/presentation/screens/chat_channel_screen.dart | 0 | 0 | 0  | verifiziert (B5; UI/Dialoge/Fehler ARB, Audit 0) |
| chat | features/chat/presentation/screens/chat_inbox_screen.dart | 0 | 0 | 0  | verifiziert (B5; locale Dates, Audit 0) |
| chat | features/chat/presentation/screens/dm_screen.dart | 0 | 0 | 0  | verifiziert (B5; locale Dates, Audit 0) |
| chat | features/chat/presentation/widgets/direct_messages_action.dart | 0 | 0 | 0  | verifiziert (B5, Audit 0) |
| chat | features/chat/presentation/widgets/message_bubble.dart | 0 | 0 | 0  | verifiziert (B5; Bubbles/Call-Request ARB, Audit 0) |
| chat | features/chat/presentation/widgets/message_input_bar.dart | 0 | 0 | 0  | verifiziert (B5, Audit 0) |
| chat | features/chat/presentation/widgets/typing_indicator.dart | 0 | 0 | 0  | verifiziert (B5; ICU `chatTyping`, Audit 0) |
| experience | features/experience/data/repositories/experience_repository.dart | 0 | 7 | 0  | offen |
| experience | features/experience/domain/models/experience_share.dart | 1 | 0 | 0  | offen |
| experience | features/experience/presentation/screens/experience_feed_screen.dart | 12 | 0 | 0  | offen |
| experience | features/experience/presentation/widgets/experience_card.dart | 2 | 0 | 1  | offen |
| community | features/community/presentation/screens/community_screen.dart | 10 | 0 | 0  | offen |
| video | features/video/data/repositories/supabase_video_repository.dart | 1 | 5 | 0  | offen |
| video | features/video/presentation/screens/video_call_screen.dart | 28 | 20 | 0  | offen |
| video | features/video/presentation/widgets/incoming_call_listener.dart | 10 | 0 | 0  | offen |
| premium | features/premium/data/premium_repository.dart | 2 | 0 | 0  | offen |
| consent | features/consent/presentation/screens/consent_screen.dart | 0 | 0 | 335 e-legal! | geflaggt – Anwalt, nicht frei übersetzen |
| admin | features/admin/presentation/providers/admin_provider.dart | 9 | 0 | 0  | offen |
| admin | features/admin/presentation/screens/admin_panel_screen.dart | 99 | 0 | 0  | offen |
| dev_tools | features/dev_tools/presentation/screens/dev_tools_screen.dart | 36 | 7 | 0  | offen |
| core/database | core/database/app_database.dart | 2 | 1 | 0  | verifiziert (B1 `d955d11`, Logs/Assert bereits EN) |
| core/database | core/database/backup_exclusion.dart | 0 | 1 | 0  | verifiziert (Log bereits EN) |
| core/database | core/database/tables/exercises_table.dart | 0 | 0 | 2 bilingual-ok | offen |
| core/logging | core/logging/logger_service.dart | 2 | 2 | 0  | verifiziert (Logs bereits EN) |
| core/monitoring | core/monitoring/sentry_service.dart | 1 | 2 | 0  | verifiziert (Log bereits EN) |
| core/navigation | core/navigation/app_router.dart | 3 | 0 | 0  | verifiziert (B1 `d955d11`, Audit 0) |
| core/navigation | core/navigation/app_shell.dart | 6 | 0 | 0  | verifiziert (B1 `d955d11`, Tab-Labels DE/EN, Audit 0) |
| core/notifications | core/notifications/notification_service.dart | 2 | 4 | 1  | verifiziert (B2 `f6e1012`, title/body generisch, Channel-Name ARB) |
| core/onboarding | core/onboarding/onboarding_hint_gate.dart | 3 | 0 | 0  | verifiziert (B2 `f6e1012`, Sheet-Aktionen ARB) |
| core/onboarding | core/onboarding/onboarding_hint_provider.dart | 20 | 0 | 0  | verifiziert (B2 `f6e1012`, Content über AppLocalizations) |
| core/push | core/push/push_notification_service.dart | 11 | 16 | 0  | verifiziert (B2 `f6e1012`, Fallback-Copy ARB; Markenname allowlisted) |
| core/reminders | core/reminders/device_timezone_provider.dart | 2 | 0 | 0  | verifiziert (nur technische Werte/Logs, Audit 0 a/b/c) |
| core/reminders | core/reminders/reminder_preferences_repository.dart | 0 | 5 | 0  | verifiziert (Logs bereits EN) |
| core/reminders | core/reminders/reminder_settings.dart | 1 | 0 | 0  | verifiziert (B2 `f6e1012`, ungenutztes 'Home'-Label entfernt) |
| core/services | core/services/notification_service.dart | 30 | 3 | 0  | verifiziert (B2 `f6e1012`, legacy ohne Aufrufer; Copy jetzt Pflichtparameter) |
| core/settings | core/settings/settings_provider.dart | 1 | 1 | 0  | verifiziert (nur d-log/Assert, bereits EN) |
| core/sync | core/sync/exercises_sync_service.dart | 0 | 5 | 2 bilingual-ok | verifiziert (Logs EN, Halten/Hold bilingual-ok) |
| core/sync | core/sync/sync_service.dart | 1 | 14 | 0  | verifiziert (alle Funde d-log, bereits EN) |
| core/widgets | core/widgets/error_retry_widget.dart | 1 | 0 | 0  | verifiziert (B1 `d955d11`, lokalisierter Default, Audit 0) |
| lib/app.dart | app.dart | 6 | 2 | 4  | verifiziert (W2+B1 `d955d11`, Kalender-/Reminder-Copy DE/EN, Audit 0) |
| lib/bootstrap | bootstrap/bootstrap.dart | 26 | 7 | 0  | verifiziert (B1, alle Funde d-log, bereits EN) |
| lib/bootstrap | bootstrap/providers.dart | 0 | 3 | 0  | verifiziert (nur Provider-Asserts, bereits EN) |
| lib/main_development.dart | main_development.dart | 20 | 4 | 0  | verifiziert (B1 `d955d11`, Fehlertitel ARB; Boot-Status bewusst EN-technisch, Allowlist) |
| lib/main_production.dart | main_production.dart | 2 | 1 | 0  | verifiziert (B1 `d955d11`, Startfehler DE/EN via Geraetesprache) |
| lib/main_smoke.dart | main_smoke.dart | 1 | 0 | 0  | verifiziert (B1, technischer Smoke-Marker, Allowlist) |
| lib/main_staging.dart | main_staging.dart | 2 | 1 | 0  | verifiziert (B1 `d955d11`, Startfehler DE/EN via Geraetesprache) |


## Arbeitslog

- **2026-07-19, B5 — Chat komplett (`927a344`):** 37 neue ARB-Keys (**1128 DE = 1128 EN**).
  Inbox, DM, Channel-Screen, Bubbles, Input-Bar, Typing-Indicator, Navigation und
  Call-Request-Persistenz über ARB. `ChatChannel.channelDisplayName(l10n)`;
  Community/Experience-Aufrufer mitgezogen (Compile). Reuse von
  `cancel`/`retry`/`settings`/`errorLoadFailedInline`/`profileMessages`/
  `trainerFallbackName`/`trainerProposeAppointment`/`trainerRequestAccept`/
  `trainerAppointmentAction`/`trainerChatFallback`. StateError-Texte EN;
  Snackbars immer über ARB. Belege: scoped Audit **0 a/b/c** unter
  `lib/features/chat/`, `make i18n-check` 1128/1128, analyze 0 Fehler/
  0 Warnungen, **283/283 Tests grün**.

- **2026-07-19, B4 — Trainer komplett (`49c86be`):** ~157 neue ARB-Keys (**1091 DE = 1091 EN**).
  Application-Intro/-Status/-Form, Dashboard, Clients-Liste + Debug-Panel,
  Client-Detail, Requests, Scheduler/Proposal, OSM-Attribution, Location-Picker-Tip,
  Kalender-ICS-Titel sowie `trainer_provider` (Connection-Check, Namens-Fallbacks,
  Activate-Fehler, Chat-Partner-Labels) über ARB. Paket-Kurzlabels `trainerPkg*`;
  Statuslabels via `statusLabel(AppLocalizations)` (Admin-Panel mitgezogen).
  Modelle liefern leere Strings statt harter DE-Fallbacks; UI nutzt
  `clientFallbackName`/`trainerFallbackName`/`appointmentSessionTitle`.
  Discovery/Public-Profile waren bereits ARB-verdrahtet. Quality-Allowlist für
  identische DE/EN-Strings (OSM, Diag-Zeilen, Paketkürzel). Belege: scoped Audit
  **0 a/b/c** unter `lib/features/trainer/` (nur d-log), `make i18n-check` 1091/1091,
  analyze 0 Fehler/0 Warnungen, **283/283 Tests grün**.

- **2026-07-19, B3 — Assessment-UI & PDF (`cf5de93`):** 136 neue ARB-Keys (**934 DE = 934 EN**).
  Analysis-Placeholder, Dauerempfehlung, Reflexprofil-Fragebogen/-Ergebnis/-Demo,
  Radar-Leerzustand und PDF-Zusammenfassung vollständig über ARB. Gemeinsame
  Score-Band-Labels (`scoreBand*`) und `answerUnknown`; Reflexnamen weiter über
  `PrimitiveReflex.label`/`pickLocalized`. PDF: WIP-Patch
  (`docs/i18n/wip/reflex_profile_pdf_localization.patch`) angewendet —
  `ReflexProfilePdfCopy` + `buildSummaryContent`, Locale über
  `AppLanguages.normalize` (kein `== 'de'`), Aufrufer in
  `reflex_profile_result_screen` verdrahtet via `reflexProfilePdfCopyFromL10n`.
  Provider: sichtbare Fallbacks lokalisiert, Auth-Exceptions auf Englisch.
  EN-Disclaimer claim-safe umformuliert (Quality-Gate). Belege: scoped Audit 0
  a/b/c in allen B3-Dateien, `make i18n-check` 934/934, analyze 0 Fehler/
  0 Warnungen, **283/283 Tests grün**.

- **2026-07-19, B2 — Hinweise & Client-Push (`f6e1012`):** 38 neue ARB-Keys
  (**798 DE = 798 EN**): 19 Onboarding-Hints (4 Sheets als Titel+Body, 12 Bullet-Items,
  3 Sheet-Aktionen), Android-Channel-Name, 10 Push-Fallback-Texte, 4 Trainer-Alerts
  (Tag 25/28, mit `traineeName`-Platzhalter) plus `traineeFallbackName`. Neu
  `lib/core/l10n/active_localizations.dart` — `lookupActiveAppLocalizations()` löst
  in Headless-Kontexten (Push-Handler, Hintergrund-Services ohne lokalisierten Context)
  die persistierte App-Sprache auf; bei Erstinstallation Gerätesprache wie im
  `SettingsNotifier`. Live-`NotificationService`: `titleDe`/`bodyDe` → `title`/`body`
  (drei Aufrufer nachgezogen), Android-Channel-Name kommt aus dem ARB statt hart
  „Training Reminders“. `PushNotificationService`: die deutschen Inline-Ternaries für
  Foreground-Fallbacks sind ein lokalisierter `switch` über `pushXxxTitle/Body`-Keys;
  der Markenname „Reflex Journey“ als Default-Titel bleibt bewusst (Allowlist).
  `TrainerNotificationService` (live, feuert nach Sync): Tag-25/28-Alerts und
  Trainee-Fallbackname über ARB. Legacy `core/services/notification_service.dart`
  (keine Produktions-Aufrufer): sämtliche deutsche Rest-Copy entfernt — Aufrufer müssen
  `LocalNotificationCopy` übergeben; ungenutztes `'Home'`-Label in
  `reminder_settings.dart` gestrichen. Reminder-/Settings-/Sync-/Logger-/Sentry-Dateien
  brauchten keine Änderung (nur d-log, bereits EN). DE-Katalog byte-identisch bis auf
  angehängte Keys. Belege: Parity- und Quality-Gate 798/798 grün, analyze 0 Fehler/
  0 Warnungen (96 bekannte Infos), **283/283 Tests grün**; scoped Audit: keine
  nicht-erlaubten a/b/c-Funde mehr in allen B2-Dateien.

- **2026-07-19, B1 — Start & Gerüst (`d955d11`):** 10 neue ARB-Keys (**763 DE = 763 EN**).
  Bottom-Navigation nutzt bestehende Keys (`today`, `progressTitle`, `accompanimentTitle`,
  `profile`) plus neu `tabTrainer`/`tabAdmin` (DE=EN, mit Einzelbegründung in der
  Quality-Allowlist). Router-Fehlerseite (`routeNotFound`), Startfehler-Screens in
  production/staging (`startupCouldNotStart` — über `lookupAppLocalizations` aus der
  Gerätesprache aufgelöst, weil beim Bootstrap-Fehler kein lokalisierter Context
  existiert; DE-Nutzer sahen hier bisher Englisch), Dev-Fehlertitel
  (`startupBootstrapFailedTitle`), Kalender-Event-Copy für bestätigte Termine
  (Titel/Fallbacks/Snackbars, aus der aktiven App-Sprache aufgelöst) sowie gemeinsamer
  `clientFallbackName` (ersetzt hartes `'Trainee'` im Router und `'Klient'` in `app.dart`).
  `ErrorRetryWidget`: deutscher Default-Parameter ist jetzt nullable und fällt zur Laufzeit
  auf `errorLoadFailed` zurück. Bewusst EN-technisch per exakter Audit-Allowlist:
  Dev-Boot-Status (5 Einträge) und Smoke-Marker — Abweichung von „alle sichtbaren Texte in
  ARB“ ist dev-/smoke-flavor-only und im Prompt (B1) vorgesehen. `bootstrap.dart` und
  `app_database.dart` brauchten keine Änderung (nur d-log, bereits EN). Belege: scoped
  Audit 0 nicht-erlaubte a/b/c-Funde in allen 10 B1-Dateien, `make i18n-check` 763/763,
  analyze 0 Fehler/0 Warnungen, **283/283 Tests grün** (Shell-Testharness bekam
  l10n-Delegates).

- **2026-07-19, W3 — Gates auf N Sprachen (`75efb1f`):** `scripts/i18n_check.py`
  entdeckt jetzt alle `lib/l10n/app_*.arb` neben dem DE-Template und führt sämtliche
  Prüfungen (Key-/Metadaten-Parität, Leerwerte, ICU-Platzhalter, Umlaut-Check nur für
  Nicht-DE) pro Zielsprache in einer Schleife aus; Fehlermeldungen nennen die Datei,
  jede scheiternde Sprache setzt Exit ≠ 0. Fixture-Tests belegen: ein unvollständiges
  `app_fr.arb` lässt das Gate scheitern, ein vollständiges besteht.
  `scripts/i18n_quality_check.py` deklariert `RULES_BY_LOCALE` (derzeit nur EN);
  Kataloge ohne Regelwerk werden mit explizitem Hinweis übersprungen („app_fr.arb: no
  quality rules defined yet — add them when the language ships“), EN-Verhalten
  byte-identisch. **Umgebungs-Befund:** das System-`python3` ist 3.9 (das frühere 3.14
  aus den `__pycache__`-Artefakten existiert nicht mehr); ein
  `from __future__ import annotations` im Quality-Testmodul stellt die Lauffähigkeit
  her, die Skripte selbst hatten den Import bereits. `make i18n-check` unverändert
  (nur Kommentar). Belege: 27 Python-Tests grün, `make i18n-check` 753/753,
  **283/283 Flutter-Tests grün**.

- **2026-07-19, W2 — Content-Resolver `pickLocalized` (`af9360b`):** Neu
  `lib/core/l10n/localized_content.dart` — die eine Stelle, die die Content-Fallback-
  Policy kennt (DE wenn angefragt, sonst EN als internationaler Fallback). Alle
  `*De`/`*En`-Accessor-Methoden (`exercise.dart`, `reflex_questionnaire.dart`,
  `completion_questions.dart`) und direkten Feldzugriffe
  (`immersive_exercise_screen.dart`, `exercise_movement_widget.dart`) laufen darüber.
  Formatierungs-Weichen (Datum kompakt/`dd.MM.yyyy`, 24h-Uhr in Settings) behalten ihre
  DE-Sonderformate, vergleichen aber gegen `AppLanguages.sourceCode` statt `'de'`-Literal
  — ein drittes Locale erbt automatisch das EN-Format. `consent_screen.dart` und
  `analysis_placeholder_screen.dart`: **nur die `isDE`-Bedingung** registry-getrieben,
  die (anwaltsgebundene) Copy blieb byte-identisch. **Bug-Fix `app.dart:407`:** der
  Inline-Reminder-Text („Zeit für deine Einheit" / „Time for your unit") lief am ARB
  vorbei; jetzt `reminderSessionTitle`/`reminderSessionBody` via
  `lookupAppLocalizations(Locale(next.languageCode))` — dieselben Keys wie im Dashboard.
  Sichtbare Folge (beabsichtigt): der Reminder-Body lautet nun einheitlich „Nimm dir
  Zeit für deine heutige Einheit." statt des alten Inline-Wortlauts mit
  „Reflexintegrations-Einheit". Hartes Grep-Gate erfüllt: `== 'de'` außerhalb
  `core/l10n/`/generierter Dateien → **0 Treffer**. Belege: analyze 0 Fehler/0 Warnungen
  (96 bekannte Infos), `make i18n-check` 753/753, **283/283 Tests grün** (4 neue
  Resolver-Tests).

- **2026-07-19, W1 — Sprach-Registry `AppLanguages` (`f72cdc8`):** Neu
  `lib/core/l10n/app_languages.dart` als einziges Verzeichnis der unterstützten Sprachen
  (Code, Autonym, Flagge) plus `locales`, `isSupported`, `resolveInitial`, `normalize`,
  `byCode`. Verdrahtet: `app.dart` (`supportedLocales`), `settings_provider.dart`
  (Erstsprach-Erkennung + `assert` in `setLanguage`), `language_selection_screen.dart`
  (Schleife statt zwei fester Buttons), `settings_screen.dart` (Optionsliste + Label über
  `byCode`), `login_screen.dart` (Chips aus Registry), `profile_locale_sync_service.dart`
  (`normalize` statt eigener de/en-Prüfung). **Sichtbare Copy unverändert:** die ARB-Werte
  `languageGerman`/`languageEnglish` waren bereits exakt die Autonyme („Deutsch“/„English“,
  in beiden Katalogen identisch) — die Allowlist-Einträge für die Login-Chips bleiben gültig.
  Eine Verhaltensnuance bewusst erhalten: der Sync akzeptierte vorher via `startsWith('en')`
  auch `en-US`; jetzt wird der Region-Subtag vor `normalize` abgeschnitten, damit `en-US`
  nicht auf `de` zurückfällt. 6 Registry-Tests plus ein Sprachwahl-Widgettest, der über
  `AppLanguages.all` iteriert statt hart 2 Buttons zu erwarten. Belege: analyze 0 Fehler/
  0 Warnungen, `make i18n-check` 753/753, **279/279 Tests grün**.

- **2026-07-19, W0 — In-flight-Batch teilweise gelandet (`dca9563`, `f6b3250`):**
  Der Tree entsprach exakt der erwarteten Dateiliste. Der Content-Teil (Übungs-Copy,
  Reflexlabels, Fragebogen, Completion-Frage) ist verifiziert und committet: DE-Werte sind
  byte-identisch geblieben, geändert wurden ausschließlich EN-Felder; die neue EN-Copy nennt
  Abbruchkriterien explizit („stop the exercise“, „ask a qualified professional“) und
  vermeidet Diagnose-Sprache („identified as being on the autism spectrum“ statt „diagnosed
  with“). Zwei Tests in `reflex_questionnaire_localization_test.dart` pinnten den alten Wert
  `'FPR'`; sie prüfen jetzt `contains('FPR')` plus zusätzlich, dass `shortLabel('en')` kompakt
  `'FPR'` bleibt — relevant, weil `reflex_radar_chart.dart:172` `shortLabel` zeichnet und die
  langen Labels sonst das Radar sprengen würden. Belege: analyze 0 Fehler/0 Warnungen
  (97 bekannte Infos), `make i18n-check` 753/753 DE=EN, **272/272 Tests grün**.

  **Abweichung — W0-Commit 2 (PDF) verworfen:** `reflex_profile_pdf_service.dart` enthielt
  einen unvollständigen Refactor. `createSummaryPdf` bekam die Pflicht-Parameter `locale` und
  `copy` (24-Feld-Struktur `ReflexProfilePdfCopy`), aber der einzige Aufrufer
  `reflex_profile_result_screen.dart:223` wurde nie angepasst → 2 `missing_required_argument`
  -Fehler, der Tree kompilierte nicht. Heilen hätte ~24 ARB-Key-Paare plus Aufrufer-Verdrahtung
  gebraucht — das ist B3-Umfang, nicht „≤3 kleine Fixes“. Datei daher per `git restore`
  zurückgesetzt. Der Entwurf ist **nicht verloren**: er liegt als
  `docs/i18n/wip/reflex_profile_pdf_localization.patch` und ist in B3 mit
  `git apply` wiederverwendbar — die Trennung von Copy-Struktur und Layout dort ist gut und
  sollte übernommen werden. Achtung beim Wiederaufsetzen: der Patch enthält ein eigenes
  `_supportedLanguageCode` mit `== 'de'`, das nach W2 durch `pickLocalized`/`AppLanguages`
  ersetzt gehört.

- **2026-07-19, Struktur-Prompt:** Vollständige Standortbestimmung (749 sichtbare Hardcodes
  offen, davon 479 deutsch, 11 Formatstellen; 36 `== 'de'`-Ternaries; W0-Batch uncommitted;
  `app.dart:409` trägt noch alte Inline-Reminder-Texte). Daraus den ausführungsfertigen
  Prompt `docs/I18N_STRUCTURE_PROMPT.md` geschrieben: zentrale `AppLanguages`-Registry +
  `pickLocalized`-Resolver (Code fertig vorgegeben), N-Sprachen-Gates, Batch-Plan B1–B7 für
  die Rest-Externalisierung, Gate-Scharfschaltung, Runbook `I18N_ADD_LANGUAGE.md`,
  Abschlussreport — inkl. Anti-Stall-Protokoll (Commit-oder-Revert, Tracker-Pflicht,
  mechanische Reihenfolge), damit Folgesessions nicht mehr liegen bleiben. Ausführung ist
  für günstigere Modell-Sessions (Opus 4.8) ausgelegt.

- **2026-07-15, Begleitung/Mood/Settings/Profil:** 145 semantische Keys ergänzt
  (**753 DE = 753 EN**, jeweils mit Metadaten). Der scoped Audit meldet in allen
  zwölf Produktdateien keine nicht erlaubten UI-/Fehler-/Push-Hardcodes und keine
  festen deutschen Locale-Formate. Der persistierte DB-Identifier `training` ist
  als eine exakte Pfad+Literal-Ausnahme dokumentiert. Datums-/Zeit-Regressionen
  sichern DE (`15.07.2026`, `15.7`, `Mi., 15. Juli · 15:30`) und en-US
  (`7/15/2026`, `7/15`, `Wed, Jul 15 · 3:30 PM`); die Auswahlwerte der
  Trainingserfahrung verwenden stabile Enums statt übersetzter Zustands-IDs.

- **2026-07-15, EN-Evidenz und Asset-Inventar (`0cfec14`):** Sechs reproduzierbare
  PNGs belegen First-Launch-Sprachwahl, Login, unmittelbaren Wechsel in Settings,
  Onboarding, Dashboard und Training in Englisch; der isolierte Harness nutzt
  lokale Stubs und weder Netzwerk noch Produktionsdaten. Alle 29 Trainingsbilder
  wurden visuell auf eingebetteten Text geprüft. Separat geflaggt bleiben fehlende
  EN-Announcement-Audios, elf referenzierte aber nicht vorhandene Übungsbilder,
  fünf leere Bildfamilien, GPS-Metadaten in sechs JPEGs, Standard-Flutter-Branding
  auf Desktop/Web sowie nicht geprüfte Remote-Medien.

- **2026-07-15, Audit-Härtung (`c6ce9c4`):** Statement-gebundene Log-/Exception-
  Klassifizierung und exakte technische Muster reduzieren 44 False Positives,
  ohne neun echte UI-Funde zu verschlucken. Positive und negative Regressionstests
  sichern die konservative Klassifizierung; absichtlich sichtbare Wörter wie
  `Today` und `May` bleiben Audit-Funde.

- **2026-07-15, Packages/Journal/Progress/Golden Day:** 57 semantische Keys ergänzt
  (608 DE = 608 EN, alle mit Metadaten). Die fünf zugehörigen Dateien haben im
  scoped Audit keine Hardcodes oder festen deutschen Locale-Formate mehr. Datum
  und Uhrzeit folgen der aktiven Sprache; Tests sichern die unveränderte deutsche
  Ausgabe (`09:05`, `15.7`) und en-US (`9:05 AM`, `7/15`). Drei fokussierte
  Lokalisierungstests, Analyse ohne Fehler/Warnungen und die reguläre Gesamtsuite
  sind grün.

- **2026-07-15:** Session-Start. Baseline-Commit `178d4bc` (In-flight-Arbeit gesichert),
  Branch `i18n/english-localization` angelegt, Tracker erstellt. Phase 1 (Audit) durchgeführt:
  Skript gebaut + kalibriert (Import-Direktiven, Bilingual-Felder, SQL/Locale-Filter),
  Mengengerüst + Architektur-Befunde oben. Live-DB-Check der EN-Spalten in dieser Session
  nicht möglich (Prod-Zugriffe für diese Session verboten) → als vorbereitetes SQL im
  🔶-Block an den Founder.
- **2026-07-15, Handoff:** Vier i18n-Commits gegen den Tree geprüft. Onboarding fügte real
  49 Keys hinzu, Dashboard 64 (gesamt 429 DE = 429 EN; alle neuen Keys mit Metadaten).
  Auth ist bereits sauber und braucht keinen eigenen Umbau. Das angefangene Audit-Gate wurde
  gegen False Negatives gehärtet: Vergleichsliterale werden präzise statt zeilenweise
  gefiltert; Regressionstests decken `.contains`, Ternary und `case` ab. Nächster Code-Batch:
  Training-Intro, Position und Bewegung; rechtlicher Trainingshinweis bleibt ausgespart.
- **2026-07-15, Training-Instruktionen:** Intro, Positions- und Bewegungsanweisung vollständig
  externalisiert; 16 semantische Keys ergänzt (445 DE = 445 EN, jeweils mit Metadaten).
  Deutsche UI-Ausgaben bleiben unverändert. Englische Copy folgt Glossar (`session`,
  `exercise`, `movement`) und ICU behandelt Singular/Plural. Audit für alle drei Dateien: 0.
  Fünf Widget-Tests prüfen natürliche EN-Copy, Tooltips, Fortschritts-Semantik, Dialoge,
  Singular/Plural und DE-Parität. Vollcheck: Analyze 0 Fehler/0 Warnungen (bekannte Infos),
  **250/250 Tests grün**.
- **2026-07-15, dauerhaftes Paritäts-Gate:** `scripts/i18n_check.py` prüft DE/EN-Message-
  und Metadaten-Key-Parität, Leer-/Nicht-String-Werte, ICU-Platzhalter gegen `@`-Metadaten,
  identische Placeholder-Definitionen sowie deutsche Umlaute/`ß` in EN-Werten. Das schnelle
  Gate ist als `make i18n-check` in `release-readiness-mobile` eingebunden; 14 Python-Tests
  und der reale Katalog mit **445/445 Keys** sind grün. Das Hardcode-Gate wird bewusst erst
  bei Audit 0 aktiviert und bleibt Teil der offenen Phase 5.
- **2026-07-15, Profil-Locale-Sync:** Die authentifizierte Sprachwahl wird best-effort in
  `profiles.locale` geschrieben. `SettingsNotifier` synchronisiert nach einem expliziten
  Sprachwechsel und beim Neuaufbau nach bestehender Session, Sign-in oder Token-Refresh;
  lokale Auswahl/App-Start werden bei einem Netzwerkfehler nie blockiert. Kein Schema-Change
  und kein Prod-Zugriff. Zwei neue Unit-Tests decken Wechsel und Session-Restore ab.
- **2026-07-15, System-Permission-Texte:** Alle fünf bestehenden iOS-Usage-Descriptions als
  `de.lproj/en.lproj/InfoPlist.strings` lokalisiert und als Xcode-Variant-Group paketiert;
  DE ist wortgleich zum bisherigen `Info.plist`, EN ist natürliche en-US-Copy. Marken-/Flavor-
  Namen bleiben invariant. Android benötigt für die bestehenden Systemdialoge keine zusätzliche
  App-Copy. 5 Plattformtests, `plutil` und Xcode-Projektparser sind grün. Einschränkung: Die
  Flutter-In-App-Sprache steuert iOS-Systemdialoge nicht; iOS nutzt seine App-/Gerätesprache.
- **2026-07-15, Trainingskern (`96db5e8`):** 20 geänderte Training-Screens/-Widgets/-Services mit 106
  semantischen Keys lokalisiert; **551/551** DE/EN-Keys, fünf neue bilinguale Widgettests und
  scoped Audit 0. Das Glossarwort `session` ersetzt alte EN-`unit`-Copy. Sichtbare Cues und
  Exercise-Feldpaare sind locale-aware. Echte EN-Sprachausgaben bleiben offen, weil nur deutsche
  Announcement-MP3s vorhanden und gebündelt sind; keine nicht existierenden Assets verdrahtet.
- **2026-07-15, Fragebogen-Content:** Der reale Bestand ist **109 Vollfragen + 14 Demo = 123**
  (nicht 129). Alle Fragen, acht Module, fünf Hilfetexte, fünf Trainer-Flags sowie Reflexnamen
  sind als DE/EN-Feldpaare umgesetzt; DE-Runtime-Copy ist vollständig identisch zum Ausgangsstand,
  EN nutzt `FPR` statt `FLR`. 32 Assessment-Tests, Claim-/Residue-Prüfung und scoped Analyze sind
  grün. Allgemeine Assessment-UI und PDF-Rahmentexte bleiben ein eigener ARB-/Formatierungs-Batch.
- **2026-07-15, serverseitige Push-Copy:** Reminder-, Termin-, Call-Request- und eingehende
  Video-Call-Notifications lesen die Empfängersprache aus `profiles.locale`, normalisieren auf
  `de`/`en` und fallen bei fehlendem/ungültigem Wert auf Deutsch zurück. Mehrere Empfänger werden
  pro Device-Token in ihrer eigenen Sprache bedient. Bestehende DE-Copy ist regressionsgetestet,
  en-US-Copy nutzt `session`; 15/15 Deno-Tests und `deno check` für alle fünf Entry-Points sind
  grün. Kein Schema, kein Prod-Zugriff und kein Function-Deploy; Deploy bleibt Founder-gated.
- **2026-07-15, EN-Qualitätsgate:** Ein zweites ARB-Gate prüft Glossar (`session`, nie `unit`),
  en-US-Schreibweisen, verbotene Claim-Begriffe und unbegründete identische DE/EN-Werte.
  27 bewusst identische Produktnamen/Akronyme besitzen exakte Einzelbegründungen; Legal- und
  Quellentitel-Ausnahmen sind typisiert und ohne Wildcards. Sechs alte, nicht rechtliche EN-Werte
  wurden auf en-US/Glossar korrigiert. Der lawyer-owned Disclaimer bleibt unverändert und exakt
  ausgenommen. 11 fokussierte Quality-Tests und der reale 551-Key-Katalog sind grün.
