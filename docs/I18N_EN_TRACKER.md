# I18N-EN Tracker — Vollständige englische Lokalisierung

**Auftrag:** `docs/TRANSLATION_EN_PROMPT.md` (Quelle der Wahrheit für Regeln, Style Guide, Definition of Done).
**Endspurt + Mehrsprachen-Fundament:** `docs/I18N_STRUCTURE_PROMPT.md` (2026-07-19) — der
ausführungsfertige Prompt für alle Restarbeiten (W0–W8); Sessions steigen dort beim
„Nächsten Block“ ein. Künftige Sprachen: `docs/I18N_ADD_LANGUAGE.md` (entsteht in W7).
**Branch:** `i18n/english-localization` (abgezweigt von `main` @ `178d4bc`).
**Diese Datei ist das Gedächtnis über Session-Grenzen hinweg** — nach jedem Arbeitsblock aktualisieren.

**Nächster Block: W1** (Sprach-Registry `AppLanguages`, siehe `docs/I18N_STRUCTURE_PROMPT.md`)

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
| assessment | features/assessment/domain/draft_persistence_service.dart | 0 | 2 | 0  | offen |
| assessment | features/assessment/domain/reflex_questionnaire_definitions.dart | 134 | 0 | 0  | verifiziert (123 Fragen, 8 Module, 5 Hilfen, 5 Flags als DE/EN-Feldpaare; Audit 0 a/b/c) |
| assessment | features/assessment/domain/services/reflex_profile_pdf_service.dart | 36 | 0 | 1  | offen (B3; Entwurf liegt als `docs/i18n/wip/reflex_profile_pdf_localization.patch`) |
| assessment | features/assessment/presentation/providers/reflex_profile_provider.dart | 3 | 6 | 0  | offen |
| assessment | features/assessment/presentation/screens/analysis_placeholder_screen.dart | 16 | 0 | 0  | offen |
| assessment | features/assessment/presentation/screens/duration_recommendation_screen.dart | 20 | 0 | 0  | offen |
| assessment | features/assessment/presentation/screens/reflex_profile_demo_screen.dart | 66 | 0 | 0  | externalisiert (Fragen/Reflexnamen DE/EN; allgemeine UI noch offen) |
| assessment | features/assessment/presentation/screens/reflex_profile_result_helpers.dart | 8 | 0 | 0  | externalisiert (Modulnamen DE/EN; allgemeine UI noch offen) |
| assessment | features/assessment/presentation/screens/reflex_profile_result_screen.dart | 40 | 0 | 0  | externalisiert (Fragen/Reflexnamen DE/EN; allgemeine UI noch offen) |
| assessment | features/assessment/presentation/screens/reflex_profile_screen.dart | 77 | 0 | 0  | externalisiert (Fragen/Module DE/EN; Dialog-/Buttontexte noch offen) |
| assessment | features/assessment/presentation/widgets/reflex_radar_chart.dart | 15 | 0 | 0  | externalisiert (Reflexlabels DE/EN; Leerzustand noch offen) |
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
| trainer | features/trainer/data/repositories/supabase_trainer_application_repository.dart | 0 | 2 | 0  | offen |
| trainer | features/trainer/domain/models/appointment.dart | 2 | 0 | 0  | offen |
| trainer | features/trainer/domain/models/trainer_application.dart | 6 | 0 | 0  | offen |
| trainer | features/trainer/domain/models/trainer_client.dart | 1 | 0 | 0  | offen |
| trainer | features/trainer/domain/models/trainer_profile.dart | 1 | 0 | 0  | offen |
| trainer | features/trainer/domain/services/calendar_service.dart | 19 | 3 | 0  | offen |
| trainer | features/trainer/domain/services/trainer_notification_service.dart | 7 | 3 | 0  | offen |
| trainer | features/trainer/presentation/providers/trainer_provider.dart | 37 | 1 | 0  | offen |
| trainer | features/trainer/presentation/screens/appointment_proposal_screen.dart | 13 | 0 | 2  | offen |
| trainer | features/trainer/presentation/screens/appointment_scheduler_screen.dart | 13 | 3 | 1  | offen |
| trainer | features/trainer/presentation/screens/trainer_application_form_screen.dart | 15 | 0 | 0  | offen |
| trainer | features/trainer/presentation/screens/trainer_application_intro_screen.dart | 13 | 0 | 0  | offen |
| trainer | features/trainer/presentation/screens/trainer_application_status_screen.dart | 17 | 0 | 0  | offen |
| trainer | features/trainer/presentation/screens/trainer_client_detail_screen.dart | 38 | 0 | 4  | offen |
| trainer | features/trainer/presentation/screens/trainer_clients_screen.dart | 12 | 0 | 0  | offen |
| trainer | features/trainer/presentation/screens/trainer_dashboard_screen.dart | 44 | 0 | 3  | offen |
| trainer | features/trainer/presentation/screens/trainer_public_profile_screen.dart | 2 | 0 | 0  | offen |
| trainer | features/trainer/presentation/screens/trainer_requests_screen.dart | 2 | 0 | 0  | offen |
| trainer | features/trainer/presentation/widgets/osm_attribution.dart | 1 | 0 | 0  | offen |
| trainer | features/trainer/presentation/widgets/trainer_location_picker_widget.dart | 1 | 0 | 0  | offen |
| chat | features/chat/data/repositories/supabase_chat_repository.dart | 3 | 4 | 0  | offen |
| chat | features/chat/domain/models/chat_channel.dart | 3 | 0 | 0  | offen |
| chat | features/chat/presentation/navigation/chat_navigation.dart | 2 | 0 | 0  | offen |
| chat | features/chat/presentation/screens/chat_channel_screen.dart | 25 | 13 | 0  | offen |
| chat | features/chat/presentation/screens/chat_inbox_screen.dart | 8 | 0 | 0  | offen |
| chat | features/chat/presentation/screens/dm_screen.dart | 8 | 0 | 0  | offen |
| chat | features/chat/presentation/widgets/direct_messages_action.dart | 1 | 0 | 0  | offen |
| chat | features/chat/presentation/widgets/message_bubble.dart | 11 | 0 | 0  | offen |
| chat | features/chat/presentation/widgets/message_input_bar.dart | 2 | 0 | 0  | offen |
| chat | features/chat/presentation/widgets/typing_indicator.dart | 2 | 0 | 0  | offen |
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
| core/database | core/database/app_database.dart | 2 | 1 | 0  | offen |
| core/database | core/database/backup_exclusion.dart | 0 | 1 | 0  | offen |
| core/database | core/database/tables/exercises_table.dart | 0 | 0 | 2 bilingual-ok | offen |
| core/logging | core/logging/logger_service.dart | 2 | 2 | 0  | offen |
| core/monitoring | core/monitoring/sentry_service.dart | 1 | 2 | 0  | offen |
| core/navigation | core/navigation/app_router.dart | 3 | 0 | 0  | offen |
| core/navigation | core/navigation/app_shell.dart | 6 | 0 | 0  | offen |
| core/notifications | core/notifications/notification_service.dart | 2 | 4 | 1  | offen |
| core/onboarding | core/onboarding/onboarding_hint_gate.dart | 3 | 0 | 0  | offen |
| core/onboarding | core/onboarding/onboarding_hint_provider.dart | 20 | 0 | 0  | offen |
| core/push | core/push/push_notification_service.dart | 11 | 16 | 0  | offen |
| core/reminders | core/reminders/device_timezone_provider.dart | 2 | 0 | 0  | offen |
| core/reminders | core/reminders/reminder_preferences_repository.dart | 0 | 5 | 0  | offen |
| core/reminders | core/reminders/reminder_settings.dart | 1 | 0 | 0  | offen |
| core/services | core/services/notification_service.dart | 30 | 3 | 0  | offen |
| core/settings | core/settings/settings_provider.dart | 1 | 1 | 0  | offen |
| core/sync | core/sync/exercises_sync_service.dart | 0 | 5 | 2 bilingual-ok | offen |
| core/sync | core/sync/sync_service.dart | 1 | 14 | 0  | offen |
| core/widgets | core/widgets/error_retry_widget.dart | 1 | 0 | 0  | offen |
| lib/app.dart | app.dart | 6 | 2 | 4  | offen |
| lib/bootstrap | bootstrap/bootstrap.dart | 26 | 7 | 0  | offen |
| lib/bootstrap | bootstrap/providers.dart | 0 | 3 | 0  | offen |
| lib/main_development.dart | main_development.dart | 20 | 4 | 0  | offen |
| lib/main_production.dart | main_production.dart | 2 | 1 | 0  | offen |
| lib/main_smoke.dart | main_smoke.dart | 1 | 0 | 0  | offen |
| lib/main_staging.dart | main_staging.dart | 2 | 1 | 0  | offen |


## Arbeitslog

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
