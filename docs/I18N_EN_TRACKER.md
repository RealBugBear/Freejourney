# I18N-EN Tracker — Vollständige englische Lokalisierung

**Auftrag:** `docs/TRANSLATION_EN_PROMPT.md` (Quelle der Wahrheit für Regeln, Style Guide, Definition of Done).
**Branch:** `i18n/english-localization` (abgezweigt von `main` @ `178d4bc`).
**Diese Datei ist das Gedächtnis über Session-Grenzen hinweg** — nach jedem Arbeitsblock aktualisieren.

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
| training | features/training/domain/services/audio_announcement_service.dart | 0 | 1 | 0  | offen |
| training | features/training/presentation/screens/immersive_exercise_screen.dart | 18 | 0 | 0  | offen |
| training | features/training/presentation/screens/immersive_session_screen.dart | 1 | 0 | 0  | offen |
| training | features/training/presentation/screens/training_exercise_screen.dart | 32 | 0 | 0  | offen |
| training | features/training/presentation/screens/training_intro_screen.dart | 8 | 0 | 0  | verifiziert (Audit 0, 5 DE/EN-Widget-Tests + 250 Tests) |
| training | features/training/presentation/screens/training_movement_screen.dart | 11 | 0 | 0  | verifiziert (Audit 0, ICU-Plural geprüft, 250 Tests) |
| training | features/training/presentation/screens/training_outro_screen.dart | 8 | 0 | 0  | offen |
| training | features/training/presentation/screens/training_position_screen.dart | 9 | 0 | 0  | verifiziert (Audit 0, Semantik/Dialog DE+EN, 250 Tests) |
| training | features/training/presentation/screens/training_preparation_screen.dart | 2 | 0 | 0  | offen |
| training | features/training/presentation/screens/training_session_screen.dart | 1 | 0 | 4  | offen |
| training | features/training/presentation/screens/training_start_flow_screen.dart | 29 | 0 | 0  | offen |
| training | features/training/presentation/screens/vorrunde_interstitial_screen.dart | 9 | 0 | 0  | offen |
| training | features/training/presentation/services/in_app_music_service.dart | 3 | 2 | 0  | offen |
| training | features/training/presentation/widgets/animated_progress_bar.dart | 7 | 0 | 0  | offen |
| training | features/training/presentation/widgets/arc_swap_visualizer.dart | 2 | 0 | 0  | offen |
| training | features/training/presentation/widgets/exercise_movement_widget.dart | 6 | 0 | 2  | offen |
| training | features/training/presentation/widgets/exercise_rest_widget.dart | 2 | 0 | 0  | offen |
| training | features/training/presentation/widgets/exercise_transition_widget.dart | 10 | 0 | 0  | offen |
| training | features/training/presentation/widgets/exercise_video_widget.dart | 2 | 0 | 0  | offen |
| training | features/training/presentation/widgets/music_picker_sheet.dart | 4 | 0 | 0  | offen |
| training | features/training/presentation/widgets/parallel_lines_visualizer.dart | 2 | 0 | 0  | offen |
| training | features/training/presentation/widgets/rhythm_visualizer.dart | 3 | 3 | 0  | offen |
| training | features/training/presentation/widgets/training_disclaimer_dialog.dart | 0 | 0 | 19 e-legal! | geflaggt – Anwalt, nicht frei übersetzen |
| training | features/training/presentation/widgets/training_intro_widget.dart | 2 | 0 | 0  | offen |
| training | features/training/presentation/widgets/training_outro_widget.dart | 1 | 0 | 0  | offen |
| packages | features/packages/presentation/screens/packages_screen.dart | 10 | 0 | 0  | offen |
| journal | features/journal/presentation/screens/journal_screen.dart | 8 | 0 | 1  | offen |
| journal | features/journal/presentation/widgets/journal_entry_tile.dart | 10 | 0 | 3  | offen |
| progress | features/progress/presentation/screens/progress_overview_screen.dart | 36 | 0 | 0  | offen |
| golden_day | features/golden_day/presentation/screens/golden_day_screen.dart | 6 | 0 | 0  | offen |
| assessment | features/assessment/domain/completion_questions.dart | 0 | 0 | 7 bilingual-ok | verifiziert (DE/EN-Feldpaare) |
| assessment | features/assessment/domain/draft_persistence_service.dart | 0 | 2 | 0  | offen |
| assessment | features/assessment/domain/reflex_questionnaire_definitions.dart | 134 | 0 | 0  | offen |
| assessment | features/assessment/domain/services/reflex_profile_pdf_service.dart | 36 | 0 | 1  | offen |
| assessment | features/assessment/presentation/providers/reflex_profile_provider.dart | 3 | 6 | 0  | offen |
| assessment | features/assessment/presentation/screens/analysis_placeholder_screen.dart | 16 | 0 | 0  | offen |
| assessment | features/assessment/presentation/screens/duration_recommendation_screen.dart | 20 | 0 | 0  | offen |
| assessment | features/assessment/presentation/screens/reflex_profile_demo_screen.dart | 66 | 0 | 0  | offen |
| assessment | features/assessment/presentation/screens/reflex_profile_result_helpers.dart | 8 | 0 | 0  | offen |
| assessment | features/assessment/presentation/screens/reflex_profile_result_screen.dart | 40 | 0 | 0  | offen |
| assessment | features/assessment/presentation/screens/reflex_profile_screen.dart | 77 | 0 | 0  | offen |
| assessment | features/assessment/presentation/widgets/reflex_radar_chart.dart | 15 | 0 | 0  | offen |
| accompaniment | features/accompaniment/presentation/screens/accompaniment_screen.dart | 70 | 1 | 1  | offen |
| mood | features/mood/presentation/widgets/mood_chart_widget.dart | 4 | 0 | 0  | offen |
| mood | features/mood/presentation/widgets/mood_checkin_sheet.dart | 11 | 0 | 0  | offen |
| mood | features/mood/presentation/widgets/mood_trend_chart.dart | 1 | 0 | 0  | offen |
| mood | features/mood/presentation/widgets/note_entry_sheet.dart | 3 | 0 | 0  | offen |
| mood | features/mood/presentation/widgets/training_experience_sheet.dart | 28 | 0 | 0  | offen |
| settings | features/settings/presentation/screens/settings_screen.dart | 2 | 0 | 0  | offen |
| settings | features/settings/presentation/widgets/theme_selector.dart | 7 | 0 | 0  | offen |
| profile | features/profile/data/repositories/profile_repository.dart | 0 | 3 | 0  | offen |
| profile | features/profile/domain/models/profile.dart | 1 | 0 | 0  | offen |
| profile | features/profile/presentation/screens/profile_screen.dart | 47 | 0 | 0  | offen |
| profile | features/profile/presentation/screens/username_setup_screen.dart | 10 | 0 | 0  | offen |
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
