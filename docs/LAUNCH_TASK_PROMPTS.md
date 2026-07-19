# Launch-Task-Prompts & Status-Tracker

Erstellt: 2026-07-06 (aus der Delta-Analyse vom 2026-07-05). Gehört zu `docs/LAUNCH_READINESS_BACKLOG.md` (Single Source of Truth für WAS offen ist) und `docs/LAUNCH_MASTER_PROMPT.md` (Regeln). **Diese Datei führt den Ausführungsstatus der Tasks T01–T22 und die fertigen Session-Prompts.**

## Wie diese Datei benutzt wird

1. **Jede Session** (gestartet über den Master-Prompt) liest zuerst den Status-Tracker unten und die „Offenen Founder-Entscheidungen“.
2. Sie wählt den **höchstprioren Task, der nicht blockiert ist** (Reihenfolge-Empfehlung beachten), kündigt ihn an und arbeitet ihn **exakt nach seinem Prompt** ab.
3. Nach Abschluss: Status im Tracker auf ✅ setzen **mit Evidenznotiz** (`✅ YYYY-MM-DD — was wurde ausgeführt/geprüft → beobachtetes Ergebnis`), den zugehörigen Backlog-Punkt in `LAUNCH_READINESS_BACKLOG.md` abhaken, „Next up“ im Backlog aktualisieren.
4. Am Session-Ende: **den Prompt des nächsten anstehenden Tasks wörtlich ausgeben**, damit der Founder ihn direkt in eine frische Session einfügen kann (oder die Session macht direkt weiter, wenn Kontext-Budget reicht).
5. Statuswerte: `☐ offen` · `🔄 in Arbeit` · `✅ erledigt` · `⛔ blockiert: <wer/was>`. Ein Task wird **nie** auf ✅ gesetzt ohne beobachtete Evidenz (Regel aus dem Master-Prompt).
6. Es gelten immer die Regeln aus `CLAUDE.md` und `docs/LAUNCH_MASTER_PROMPT.md`: keine PII/Secrets ausgeben, Live-SQL nur read-only + aggregiert, Deploys/mutierendes SQL/Secrets/`git push` nur mit explizitem Founder-Go, lokale Commits mit expliziten Dateilisten.
7. **🔶 Founder-Review-Vorlagen (R1–R12):** In den Plandokumenten liegen mit 🔶 markierte, vorbereitete Empfehlungsblöcke (Index: Tabelle unten). Regel: **Bevor** eine Session einen Punkt umsetzt, an dem ein offener 🔶-Block hängt, legt sie dem Founder den Block wörtlich zur Entscheidung vor (annehmen / ändern / ablehnen) und wartet auf die Antwort. Zusätzlich prüft jede Session zu Beginn die Index-Tabelle und legt alle Blöcke vor, deren „Vorlegen wann“-Bedingung jetzt erfüllt ist. Nach der Entscheidung: Status in der Index-Tabelle auf ✅ mit Datum + Kurzfassung der Entscheidung setzen und die Konsequenz am Zielort einarbeiten.

---

## Founder-Entscheidungen — ENTSCHIEDEN 2026-07-06

| # | Frage | Entscheidung | Konsequenz |
|---|-------|--------------|------------|
| **D1** | Community-Tab + Experience-Feed in v1? | **A — verstecken** ✅ 2026-07-06 | T04 aktiv; T02/T03 entfallen. Trainer-1:1-Chat bleibt; Review-Notiz erklärt Kontaktweg (T14) |
| **D2** | Video-Calls in v1? | **A — verstecken** ✅ 2026-07-06 | T06 aktiv. Agora bleibt aus Policy/DPA/Labels raus |
| **D3** | Trainer-Discovery (Karte + Standort) in v1? | **B — bleibt drin, „make it work“** ✅ 2026-07-06 | T13 ist jetzt ein vollwertiges Fertigbau-Paket (Empty-State, Permission-UX, OSM-Attribution, Offline-Verhalten). Folgen: **Standort** kommt fix in Nutrition Labels (T12), Consent-Entwurf (T05) und Anwalts-Policy (P0.6 — dem Anwalt melden: Geolocation + OSM-Tileserver als Empfänger); iOS/Android-Location-Permissions bleiben (T09/T10) |
| **D5** | Trainer-Session-Abrechnung über die Plattform? | **NEIN — direkte Abrechnung Trainer↔Klient, keine Provision** ✅ 2026-07-07 | Trainer-Payments-Teil des Monetization-Designs gestrichen (Stripe Connect, session_payments, 15 %, DAC7 — alles entfällt; nichts davon war gebaut). Künftiges Trainer-Modell: **Werkzeug-Abo** (post-launch, eigenes Design). Abgrenzungs-Formulierung („Plattform ist nicht Vertragspartei, verarbeitet keine Zahlungen“) ins Anwalts-Briefing (Abschnitt 1 + Leistung 7) eingearbeitet; Doku: `MONETARISIERUNG_EVALUATION.md` + Design-Spec-Banner |
| **D4** | Paywall-Struktur jetzt bauen? | **JA — Struktur sofort, Aktivierung später** ✅ 2026-07-07 | Founder bestätigt die Empfehlungen aus `docs/MONETARISIERUNG_EVALUATION.md`: Trio Monat 12,99 € / Jahr 89,99 € (hervorgehoben) / Lifetime 149 €; **kein Einzelpaket-Verkauf** zum Start. Neue Fakten: **alle Pakete launchen gleichzeitig**, Nutzer trainieren chronologisch (einzelne Frühnutzer werden manuell in spätere Pakete gesetzt — Admin-Fall, kein Paywall-Scope); reale **Programmdauer 10–12+ Monate** (Pausen/Neustarts möglich) → validiert Jahres-Abo als Sweet Spot. Konsequenz: neue Tasks **T23 (Struktur, inaktiv hinter Flag) → T24 (Freischalt-Codes) → T25 (IAP/RevenueCat, ⛔ extern)**. Launch bleibt kostenlos (8.4 unverändert); Aktivierung erst nach R8-Trigger + AGB (Anwalt) |

**Founder-Auflage zu allen dreien (2026-07-06):** Code UND UI müssen sauber angepasst werden — **keine hässlichen Lücken** (keine leeren Tabs/Sektionen, keine verwaisten Buttons/CTAs, Layouts fließen ohne Löcher nach). Das ist in T04/T06/T13 als hartes Akzeptanzkriterium verankert.

---

## 🔶 Founder-Review-Vorlagen — Index (angelegt 2026-07-06)

Für jeden offenen Founder-Punkt liegt eine vorbereitete Empfehlung als 🔶-Block **an der relevanten Stelle** im jeweiligen Dokument (Fundort unten). Vorlege-Regel: siehe „Wie diese Datei benutzt wird“, Punkt 7. Statuswerte wie im Status-Tracker.

| R# | Thema (Kurzfassung der Empfehlung) | Detail-Block liegt in | Vorlegen wann | Status |
|----|-------------------------------------|------------------------|----------------|--------|
| R1 | Anwaltsauftrag: erst versandfertiges Briefing erstellen, dann 2–3 Kanzleien mit Festpreis-Anfrage | Backlog P0.6 | **sofort** (nächste Session) | ✅ 2026-07-07 angenommen („go r1“) — Briefing liegt vor: `docs/legal/ANWALTS_BRIEFING.md` (inkl. E-Mail-Anschreiben; 3 Platzhalter für Founder: Rechtsform, Kontakt, Zeitrahmen). Nächster Schritt Founder: 15-Min-Review, Platzhalter füllen, an 2–3 IT-/Datenschutz-Kanzleien senden (Anlagen: Consent-Entwurf, `STANDORT_DATENFLUSS_T13.md`, `PRIVACY_LABELS_DRAFT.md`) |
| R2 | Confirm-Link-Test mit der Screenshot-Sitzung koppeln (eine Geräte-Sitzung für beides) | Tracker, T17-Prompt unten | nächste Geräte-Gelegenheit | ☐ offen |
| R3 | Untertitel „Dein Reflexintegrations-Weg“ + Copy-Freigabe als ein 15-Min-Durchgang | `STORE_LISTING_DRAFT.md`, „Offene Entscheidungen“ | **sofort** | ☐ offen |
| R4 | ASC-App-Record in gemeinsamer Claude-in-Chrome-Sitzung anlegen (~20 Min.) | Backlog P3 (ASC-Record) | **sofort** | ☐ offen |
| R5 | Support-Postfach: `support@reflexjourney.app` als echtes Postfach (mailbox.org) | Backlog P3 (Support-Postfach) | **sofort** | ☐ offen |
| R6 | Secrets-Löschung freigeben (Beleglage vollständig, ein „Go R6“ genügt) | Backlog „Next up“ Punkt 5 | **sofort** | ✅ 2026-07-18 angenommen („Go R6“) — `AGARO-APP-ID` + `BOT-USER-ID` per `supabase secrets unset` gelöscht, per `secrets list` verifiziert (beide weg, `AGORA_APP_ID` intakt); Evidenz im Backlog P0.2 |
| R7 | Telefonnummer: jetzt nichts kaufen; nach Anwalts-Antwort ggf. sipgate | Backlog P3 (EU-Trader-Status) | nach R1/Anwalts-Antwort | ☐ offen |
| R8 | Paywall: Trigger-basiert post-launch planen + Bestandsschutz-Formel-Vorschlag | Backlog „Open questions / parked“ (Monetarisierung) | Formel: vor der ersten Launch-Kommunikation · Rest: post-launch | 🔄 teilentschieden 2026-07-07 (D4): Struktur-Bau vorgezogen (T23–T25), Trio bestätigt, kein Einzelkauf; **offen bleibt:** Bestandsschutz-Formel-Freigabe + Aktivierungs-Trigger + AGB-Beauftragung |
| R9 | Reaktivierungs-Checkliste Community/Video statt eigenem Plan jetzt | Backlog „Open questions / parked“ (neuer Punkt) | erst bei Reaktivierungswunsch | ☐ offen |
| R10 | FAQ-Bereich als statische, gebündelte Inhalte (offline-fähig, kein Backend) | Backlog P2, Punkt C | wenn Sinas Content eintrifft | ☐ offen |
| R11 | `/trainer`-Formular: kleine Vercel-Function + Resend-Mail (kein neuer Dienstleister) | Backlog P3.W (W5-Zeile) | vor dem Bau von W5 | ☐ offen |
| R12 | P4-Reihenfolge post-launch (nur Kenntnisnahme, keine Entscheidung) | Backlog P4 (Einleitung) | erster Post-Launch-Planungstermin | ☐ offen |

---

## Status-Tracker

| Task | Titel | Prio | Blockiert durch | Status |
|------|-------|------|-----------------|--------|
| T01 | Entscheidungsvorlage Sichtbarkeit (UGC/Video/Discovery) | P0 | — | ✅ 2026-07-06 — Delta-Analyse lieferte die Vorlage; Founder entschied: D1=A, D2=A, D3=B |
| T02 | Melde-Funktion Chat/Feed | — | — | ✖ entfällt (D1=A; Prompt-Fassung in git-Historie, Commit 7db274f) |
| T03 | Nutzer blockieren | — | — | ✖ entfällt (D1=A; Prompt-Fassung in git-Historie, Commit 7db274f) |
| T04 | Community/Feed für v1 verstecken — ohne UI-Lücken | P0 | — | ✅ 2026-07-06 — `launch_flags.dart` (kCommunityEnabled=false); Routen-Redirect + alle 4 UI-Einstiege gegated (inkl. Post-Training-Share-Checkbox, im Prompt ungelistet); Screenshots vorher/nachher in `docs/evidence/T04/`; 203 Tests grün (3 neue), Prod-Build ✓ |
| T05 | Consent-Screen Launch-Fassung (inkl. Standort/OSM-Passage) | P0 | Stufe 2 (Aktivierung): P0.6 (Anwalt) | ✅ Stufe 1 2026-07-07 — Launch-Entwurf DE+EN als toter Code hinter `kUsePrivacyLaunchDraft=false` in `consent_screen.dart` (`_buildLaunchDraftDE/EN`): ohne Testphasen-/6-Monats-Klauseln, AV-Liste komplett (Supabase EU, Google/FCM, Resend; OSMF als externer Empfänger), Standort-Passage wörtlich aus T13-Doku, Kinderprofil-Passage, ehrliche Push-Token-Passage, Speicherdauer neutral; Beleg-Liste für den Anwalt als Kommentarblock (jede Behauptung → Code-/Backlog-Beleg). Suite via `make release-readiness-mobile` grün. **Neu-Befund → P0.8:** aktiver Text behauptet fälschlich, Push-Daten verließen das Gerät nicht (FCM-Token existieren). Stufe 2 offen: Anwalts-Text einsetzen, Flag auf true, `kConsentVersion` bumpen |
| T06 | Video-Calls für v1 verstecken — ohne UI-Lücken | P0 | — | ✅ 2026-07-06 — `kVideoCallsEnabled=false`; AppBar-, Input-Bar- (ungelisteter Einstieg) und Bubble-Actions, IncomingCallListener + Call-Pushes gegated; Screenshots `docs/evidence/T06/`; Chat-Tests 22/22, Suite grün, Prod-Build ✓; Info.plist-Hinweis an T09 |
| T07 | Alt-Policies neutralisieren | P0 | — | ✅ 2026-07-06 — Repo-Teil: `public/privacy.html` gelöscht, `docs/privacy_policy.md` → Stub, keine aktiven Verweise. **Hosting-Abschaltung ✅ 2026-07-07** (Founder-Go, `firebase hosting:disable`, alle 4 Alt-URLs verifiziert 404) — P0.10 komplett |
| T08 | `experience_shares` Baseline-Migration | P1 | Live-Dump nötig (RPC-Definition existiert nur live) | ✅ 2026-07-08 — Live-Katalog read-only via Management API gedumpt (`docs/evidence/T08/live_columns.json`, `live_indexes.json`, `live_constraints.json`, `live_policies.json`, `live_function.json`); Migration `supabase/migrations/2026070801_experience_shares_baseline.sql` erstellt (Tabelle + Checks + RLS + 3 Policies + RPC, no-op on prod dokumentiert); `supabase db reset --local` grün inkl. neuer Migration; lokal↔live Vergleich erfolgreich (`columns_match=true`, `policies_match=true`, `function_match=true`). |
| T09 | iOS Info.plist bereinigen + Export-Compliance-Key | P1 | — | ✅ 2026-07-06 — `ITSAppUsesNonExemptEncryption=false` gesetzt (nur Standard-HTTPS/Plattform-Krypto); `NSLocationAlwaysAndWhenInUse` + beide `NSCalendars*`-Keys entfernt (Code nutzt nur When-In-Use; device_calendar deaktiviert); Kamera/Mikro + When-In-Use-Standort bleiben (D2=A/D3=B; Standort-Wortlaut passt zur T13-UX). Verifiziert: `plutil -lint` OK, Dev-Sim-Build ✓, Prod-Build ✓ 101.2MB, `plutil -p` des gebauten Prod-Bundles zeigt exakt die Ziel-Keys |
| T10 | Android-Manifest bereinigen | P1 | — | ✅ 2026-07-07 — `READ_CALENDAR`/`WRITE_CALENDAR` entfernt (device_calendar in pubspec deaktiviert); Location (D3=B) + CAMERA/RECORD_AUDIO (D2=A, Agora im Bundle) bewusst belassen. Verifiziert: Dev-APK-Build ✓, Merged Manifest `developmentDebug` → 0 CALENDAR-Treffer, Location/Kamera/Audio vorhanden |
| T11 | Env-/Bundle-Hygiene | P1 | — | ✅ 2026-07-07 — `TRAINER_CODE` aus `.env.prod` gelöscht (lokal, gitignored; verbleibende Keys: SUPABASE_URL/ANON_KEY, REVENUECAT_API_KEY, ENVIRONMENT); totes `adminEmail`-Feld aus AppConfig+bootstrap entfernt (kein Konsument, Tester-Gate prüft Domain seit `1077e02`); `.env.dev.example` bereinigt (beide Keys als obsolet dokumentiert). Flavor-Assets: nicht nativ trennbar → Empfehlung `--dart-define-from-file` post-launch im Backlog „parked“. Nebenbefund: `.env.staging` (alte FIREBASE_*-Keys) wird weder gebündelt noch gelesen. Verifiziert: analyze 0 Fehler/0 Warnungen, App-Start im Sim ✓ (VM Service + Exercise-Sync-Log) |
| T12 | Nutrition-Labels-Entwurf v2 (inkl. Standort) | P1 | Eintragen in ASC/Play: Founder, nach P0.6 | ✅ 2026-07-07 — `docs/PRIVACY_LABELS_DRAFT.md`: Apple- + Play-Tabellen, jede Zeile mit Beleg; neu ggü. Roadmap-Entwurf: Standort (ephemer, T13-Beleg), Device ID (FCM→device_tokens), Crash Data (Sentry T15), Name/Geburtsdatum Kinderprofil; „Nutzungsdaten“ gestrichen (kein Analytics-SDK — Roadmap-Entwurf war unbelegt); Kamera/Mikro/Fotos nicht deklariert (kein Datenfluss, D2=A, kein image_picker). Cross-Check SDKs↔Labels + Tabellen-Gegenprobe (25 `.from`-Tabellen) im Doc. Offene Anwalts-Frage markiert: Standort „linked vs. not linked“ |
| T13 | Trainer-Discovery fertig bauen („make it work“) | P1 | — | ✅ 2026-07-06 (Code) — Standort jetzt strikt nutzerinitiiert (CTA statt initState-Abruf); alle 4 Permission-Zweige gestaltet (Einstellungen-Buttons via neuer testbarer `LocationService`-Abstraktion); Empty-States global („noch keine Trainer freigeschaltet“ + CTA) vs. Umkreis getrennt; OSM-Attribution auf Discovery- UND Picker-Karte (tappbar); Offline-Banner + Error-State mit Retry; alles l10n DE+EN. 9 neue Widget-Tests, Suite 215 grün via `make release-readiness-mobile`, Prod-Build ✓ 101.2MB. Screenshots (13 Zustände): `docs/evidence/T13/`. Datenfluss-Doku: `docs/STANDORT_DATENFLUSS_T13.md` (Input für T12/T05/P0.6). **Offen: on-device-Durchlauf → reitet mit T17-Gerätesitzung (R2)** |
| T14 | Review-Paket: Demo-Account + Review-Notizen | P1 | ASC-Record (Founder legt an) | ⛔ blockiert: ASC-Record |
| T15 | Sentry einbauen (EU, DSGVO-schonend) | P1 | Dashboard-Verifikation: Founder (Projekt-Anlage) | ✅ Code 2026-07-07 — `sentry_flutter` 8.14; neuer `SentryService` (`lib/core/monitoring/`): aktiv nur bei gesetztem `SENTRY_DSN` (Dev default AUS), `sendDefaultPii=false`, Tracing 0, keine Screenshots/Replay, beforeSend verwirft Events mit Request + leert Extras, HTTP-/Navigations-Breadcrumbs verworfen; Init früh in bootstrap (no-op-sicher); Prod-Zone-Errors + `appLogger.error/fatal` melden nur Fehlerobjekt+Stacktrace (nie Message/Daten); Dev-Tools: „Test-Crash an Sentry senden“-Button (Tester-Gate); Consent-Entwurf um Sentry ergänzt (T05/T12-Notiz). Suite grün, Prod-Build ✓ 105.6MB. **Offen (Founder): Sentry-Projekt in EU-Region anlegen + DSN lokal in `.env.prod`, dann Test-Crash — Anleitung im Backlog P3** |
| T16 | Build-Nummern-Bump-Prozess | P1 | — | ✅ 2026-07-07 — `make bump-build` (heute+NN, idempotent steigend) + `make bump-patch` implementiert; **Fix nebenbei:** `make testflight`/`android-testers` überschrieben die Nummer bisher mit date-Werten (iOS 12-stellig — hätte Androids versionCode-Limit gesprengt) → beide lesen jetzt aus pubspec (Override via `BUILD_NUMBER=` bleibt). Limit-Check dokumentiert (YYYYMMDDNN < 2^31−1 bis Ende 2099). Verifiziert: 2×bump-build → 2026070701→2026070702 streng steigend, bump-patch → 1.0.6+…01, `make -n testflight` zeigt pubspec-Nummer; pubspec danach zurückgesetzt (kein eigenmächtiger Versions-Bump). Doku: RELEASE_READINESS_CHECKLIST.md §Build-Nummer |
| T17 | Confirm-Link auf iPhone antippen | P1 | Founder (Gerät, ~5 Min.) | ⛔ blockiert: Founder |
| T18 | Firebase-Admin-Key verschieben/rotieren | P2 | Founder (Keychain-Ablage + Löschung + Rotation) | ✅ Recherche 2026-07-07 — Key nachweislich ungenutzt (Grep beide Repos: 0 Nutzer; Client-Init läuft über firebase_options.dart; Edge Functions haben eigene Secrets; gitignored, nie committet). Founder-Anleitung (sichern → löschen → in Cloud Console rotieren) im Backlog P1.5 |
| T19 | In-App-Link zur Datenschutz-URL | P2 | P0.6 (URL live) | ⛔ blockiert: P0.6 |
| T20 | Doku-Korrekturen (FEATURE_FLAGS, TESTFLIGHT_QUICKSTART) | P3 | — | ✅ 2026-07-07 — `FEATURE_FLAGS.md`: 314 Zeilen Remote-Config-Fiktion → 28 Zeilen Realität (launch_flags.dart-Konstanten kCommunityEnabled/kVideoCallsEnabled/kUsePrivacyLaunchDraft, `feature_flags`-Tabelle als ungenutzt/parked markiert). `TESTFLIGHT_QUICKSTART.md`: neu auf heutigem Stand (Bundle-ID de.reflexjourney.app, `make bump-build` + `make testflight`, ASC-Record-Verweis auf R4, T22-Hinweis, Live-DB-Warnung); alte GitHub-Pages-/corejourney-Pfade raus |
| T21 | Trainer-Selbst-Freischaltung: DEV-Bypass verifizieren | P1 | — | ✅ 2026-07-07/08 — Client-Bypass existiert nicht mehr (Grep 0 Treffer; einziger Weg = Edge Function mit server-seitigem Code-Check; kDebugMode-Panels sind Anzeige-only; DB-Trigger `trg_prevent_direct_role_change` aus Migration 2026041504). Mini-Rest 2026-07-08 abgeschlossen: Live-Trigger-Existenz per read-only Query bestätigt (`select tgname from pg_trigger where tgname='trg_prevent_direct_role_change'` → Treffer), Evidenz: `docs/evidence/T21/live_trigger_check.json`. |
| T22 | aps-environment im ersten Store-Archiv prüfen | P1 | erster Archive-Build (nach T09/T16) | ⛔ blockiert: erster Archiv-Build |
| T23 | Paywall-Grundstruktur bauen (inaktiv hinter `kPaywallEnabled=false`) | P2 (post-launch-Aktivierung, Bau jetzt per D4) | — | ✅ 2026-07-07/08 — Migration `2026070701_premium_entitlements.sql` (profiles-Felder + **Schutz-Trigger** `trg_prevent_direct_premium_change` gegen Client-Selbstfreischaltung) lokal verifiziert und am 2026-07-08 auf Founder-Go live angewendet; Live-Evidenz: `docs/evidence/T23/live_apply_response.json` (`201`) + read-only Verifikation `docs/evidence/T23/live_verify_columns.json` (4 Spalten vorhanden) und `docs/evidence/T23/live_verify_trigger.json` (Trigger vorhanden). Neues Feature `lib/features/premium/` (Entitlement-Modell mit testbarer `isPackageUnlocked`/`postCompletionDestination`, PremiumRepository mit Offline-Cache, PurchaseService-Stub, Paywall-Screen Trio B mit Jahres-Badge + ehrlichem 10–12-Monate-Hinweis, DE+EN); Route `/paywall` mit Gate-Redirect; Integration: Paketabschluss-Übergang, Packages-Screen (zentrale Unlock-Logik statt Duplikat-Konstanten), defensiver Trainingsstart-Guard. Flag aus = exakt heutiges Verhalten (per Test belegt). 17 neue Tests, Suite grün via `make release-readiness-mobile`, Prod-Build ✓ 105.6MB, Screenshots `docs/evidence/T23/` |
| T24 | Freischalt-Codes für Gründungsnutzer (access_codes-Einlösung) | P2 | Live-Schema-Check + Function-Deploy: Standard-Freigaben/Founder-Go | ✅ 2026-07-08 — Live-Schema `access_codes` read-only geprüft (`docs/evidence/T24/live_columns.json`, `live_constraints.json`, `live_indexes.json`, `live_rls.json`): RLS an + 0 Policies bestätigt (deny-all). Migration `2026070802_access_codes_redeem.sql` ergänzt `redeemed_by`, `redeemed_at`, `grants` und atomare RPC `redeem_access_code(p_code,p_user_id)`; lokal per `supabase db reset --local` replayed. Live-Apply auf Founder-Go erfolgt (`docs/evidence/T24/live_apply_response.json` = `201`), read-only verifiziert: Spalten vorhanden (`live_verify_columns.json`), RPC vorhanden (`live_verify_function.json`), RLS unverändert (`live_verify_rls.json`). Edge Function `redeem-access-code` deployed (JWT-Pflicht, server-seitige Validierung, keine Code-Logs); unauth Smoke `401` (`live_function_smoke_unauth_status.txt`). App-UI ergänzt: Einlöse-Dialog im Account-Bereich (`profile_screen.dart`) + klare Fehlertexte DE/EN; Client liest/schreibt keine `access_codes` direkt. Tests grün: `flutter test test/features/premium/redeem_access_code_test.dart test/features/premium/premium_test.dart`, `flutter analyze` auf geänderten Dateien, `deno check supabase/functions/redeem-access-code/index.ts`. Founder-Runbook für sichere Code-Erzeugung: `docs/ACCESS_CODES_RUNBOOK.md`. |
| T25 | Multi-Grant/Benefit-Codes + RevenueCat + Apple/Google | P2 | PM-D1–PM-D12-Go; RevenueCat; ASC für T25.3; Play/D-U-N-S für T25.4; AGB vor Aktivierung | ✅ T25.0 lokal 2026-07-19 — Multi-Grant-/Benefit-Code-Fundament implementiert; Full Replay, 95 pgTAP-, 12 Edge-Function-, 43 fokussierte und 310 vollständige Flutter-Tests grün; Evidenz `docs/evidence/T25.0/README.md`. Kein Live-Apply/Deploy/Portal/Aktivierung. Preise/TS-8/finale Free-MVP-Daten bleiben Hypothesen. T25.1 ⛔ X3; T25.2–T25.5 gegated. |
| T26 | Anmeldung mit Apple & Google (Social Login) | P1 (vor Launch — Signup-Reibung) | Founder-Portal-Klicks (Apple Dev, Google Cloud, Supabase-Provider-Config) — Code ist vorher baubar | ✅ 2026-07-08 — Config-Wiring ergänzt (`GOOGLE_WEB_CLIENT_ID` über `AppConfig` → `SupabaseAuthRepository`/`GoogleSignIn.initialize(clientId)`), Login-Social-UI verifiziert (Widget-Tests für Sichtbarkeit im Sign-In und Ausblendung im Sign-Up), Doku-Nachträge für Privacy/Legal (`PRIVACY_LABELS_DRAFT.md`, `ANWALTS_BRIEFING.md`) + `.env.dev.example`-Hinweis; Verifikation: `flutter test test/config/app_config_test.dart test/features/auth/login_screen_social_test.dart` und `flutter analyze` auf allen geänderten T26-Dateien grün. |
| T27 | Trainer Studio: kostenloser MVP → bezahlter Founding-Pilot | Discovery jetzt möglich; Build/pilot gated | Free MVP: P4A + T25.0 + 3–5 Trainer; Paid: Free-MVP-Auswertung + P4B + T25.5 | ⏸ P0 offen; T25.0 lokal erfüllt. Erster MVP bewusst kostenlos, befristete `pilot`-Grants, keine Auto-Belastung. TS-8/finale Pilotdaten bleiben Hypothesen. T27.6A free; T27.6B später Store/paid. Spec/Gates/Prompts/Orchestrator wie T27-Abschnitt. |

**Empfohlene Reihenfolge (Stand 2026-07-06, D1–D3 entschieden):** T04 → T06 → T07 (P0-Block) → T13 → T09 → T10 → T11 → T21 → T05 (Vorbereitung) → T08 → T16 → T15 → T12 → T20 → T18. T04+T06 zuerst, weil sie dieselbe `launch_flags.dart` anlegen und die Chat-UI gemeinsam anfassen (eine Session kann beide nacheinander machen); T13 vor T12, damit die Labels den realen Standort-Datenfluss belegen können.

---

## Die Prompts

Jeder Prompt ist einzeln in eine frische Claude-Code-Session einfügbar. Gemeinsamer Kopf für alle (steht der Kürze halber nur hier): *Arbeitsverzeichnis `/Users/alexandermessinger/dev/claudvibes/corejourney/app`. Lies zuerst `CLAUDE.md`, `docs/LAUNCH_MASTER_PROMPT.md` (Regeln binden: Datenredaktion, gated actions, Evidenzpflicht) und den Status-Tracker in `docs/LAUNCH_TASK_PROMPTS.md`. Setze deinen Task im Tracker auf 🔄, arbeite ihn ab, und schließe mit Tracker-/Backlog-Update + Ausgabe des nächsten Task-Prompts.*

---

### T02 / T03 — ✖ ENTFALLEN (Founder-Entscheidung D1=A, 2026-07-06)

Melde-Funktion und Nutzer-Blocken werden für v1 nicht gebaut — Community/Feed werden versteckt (T04). Die vollständigen Prompt-Fassungen liegen in der git-Historie (Commit `7db274f`). **Falls die UGC-Flächen post-launch reaktiviert werden, MÜSSEN T02+T03 vorher umgesetzt sein (Apple 1.2)** — dieser Satz gehört dann in den Reaktivierungs-Plan.

---

### T04 — Community-Tab + Experience-Feed für v1 verstecken — ohne UI-Lücken *(D1=A, aktiv)*

**Rolle:** Du bist Senior Flutter Engineer mit Release-Management-Fokus — dein Markenzeichen sind minimal-invasive, per Konstante reversible Feature-Gates, die keinen toten Code hinterlassen, sondern lebenden Code schlafen legen.

**Ziel:** Kein UI-Pfad in Prod-Builds erreicht Community-Kanäle oder Experience-Feed. Trainer-1:1-Chat (DMs unter „Begleitung“) bleibt voll funktionsfähig.

**Kontext & Befund (2026-07-05):** Einstiegspunkte: Route `community` unter der Shell (`lib/core/navigation/app_router.dart:409-410`), `experienceFeed`-Route (`app_router.dart:102, 359`), CTA im Mood-Check-in (`lib/features/mood/presentation/widgets/mood_checkin_sheet.dart:184`), `community_screen.dart` listet Chat-Kanäle. Es gibt KEIN Feature-Flag-System (FEATURE_FLAGS.md beschreibt eines, das nicht existiert — nicht darauf bauen).

**Lies zuerst:** `lib/core/navigation/app_router.dart`, `lib/core/navigation/app_shell.dart`, `mood_checkin_sheet.dart`, `lib/features/community/`, Tests unter `test/` die diese Screens berühren.

**Aufgabe:**
1. Eine compile-time Konstante einführen (z. B. `const bool kCommunityEnabled = false;` in einer kleinen `lib/config/launch_flags.dart`) — bewusst simpel, kein Remote-Config.
2. Alle Einstiegspunkte dahinter gaten: Route-Registrierung, Shell-Ziel(e), Mood-Sheet-CTA. Direkter Route-Aufruf soll sauber auf Dashboard redirecten (kein Crash).
3. Grep-Sweep nach weiteren Einstiegen (`Routes.community`, `Routes.experienceFeed`, `communityChannel`) — insbesondere den „Begleitung“-Tab (`lib/features/accompaniment/`) prüfen: verweist er auf Community-Kanäle/„Erfahrungen“?
4. **UI-Lücken-Pass (Founder-Auflage 2026-07-06):** Jeden Screen, von dem ein Einstieg entfernt wurde, danach visuell prüfen und nacharbeiten — kein leerer Abschnitt, keine verwaiste Überschrift, kein einsamer Divider, kein Loch im Layout. Konkret erwartbar: (a) Mood-Check-in-Sheet: Abschluss-Flow muss ohne den Feed-CTA rund wirken (Button-Reihe/Abstände anpassen, ggf. Abschluss-Text der jetzt allein steht umformulieren lassen — l10n); (b) „Begleitung“-Tab: verbleibende Inhalte (Trainer-DMs, Termine) müssen den Platz sinnvoll füllen — notfalls Sektionen zusammenrücken; (c) Community-AppBar-Actions (DM-Icon), falls die DM-Funktion woanders schon erreichbar ist, nicht doppelt/verwaist stehen lassen.
5. Tests anpassen; ein Test ergänzen: „bei deaktiviertem Flag ist /community nicht erreichbar“.

**Akzeptanzkriterien:** Mit Flag=false existiert kein tappbarer Weg zu Feed/Community; **jeder angefasste Screen sieht absichtsvoll aus, nicht amputiert** (Screenshot-Vergleich vorher/nachher im Bericht); Mood-Check-in-Abschluss fühlt sich vollständig an; DM-/Trainer-Chat unverändert; Flag=true stellt alles wieder her.

**Verifikation:** `make release-readiness-mobile` grün; `flutter build ios --flavor production -t lib/main_production.dart --release --no-codesign` baut; Sim-Durchlauf mit Screenshots: Dashboard → Mood-Check-in → Abschluss, Begleitung-Tab, Einstellungen.

**Nicht-Ziele/Verboten:** Keine Dateien/Features löschen, keine DB-Änderungen, `chat_channels`-Backend unangetastet (Enrollment-Trigger dürfen weiterlaufen), keine l10n-Strings entfernen (neue dürfen dazukommen).

---

### T05 — Consent-Screen: Launch-Fassung

**Rolle:** Du bist Privacy Engineer an der Schnittstelle Recht/Produkt — du übersetzt Anwalts-Deutsch in ehrliche, DSGVO-konforme UI-Texte und weißt: Der Consent-Screen darf nur behaupten, was die App nachweislich tut.

**Ziel:** Der In-App-Consent verliert seinen Testphasen-Charakter und deckt die tatsächliche Verarbeitung ab. Zweistufig: **Stufe 1 (jetzt):** Struktur + faktisch korrekte Inhalte vorbereiten. **Stufe 2 (nach P0.6):** Anwalts-Formulierungen einsetzen, `kConsentVersion` bumpen.

**Kontext & Befund (2026-07-05):** `lib/features/consent/presentation/screens/consent_screen.dart` (~Z. 440 ff., DE + EN): Titel „Datenschutzerklärung (vorläufig)“, Zusage „Dauer der Testphase und bis zu 6 Monate danach“, AV-Liste nennt **nur Supabase**. Tatsächliche Verarbeiter: Supabase (EU), Google/FCM (Push), Resend (E-Mail-Versand), je nach D2/D3: Agora (Video), OSMF-Tileserver (Karte). Kinderprofile (`reflex_subject_profiles` mit Geburtsdatum) haben keine eigene Passage. Re-Consent-Mechanik über `kConsentVersion` + `user_consents`-Tabelle existiert und funktioniert.

**Lies zuerst:** den ganzen `consent_screen.dart`, die `kConsentVersion`-Definition und ihren Prüfpfad, `supabase/migrations/2026041601_user_consents.sql`, D1–D3-Entscheidungsstand im Tracker.

**Aufgabe (Stufe 1):**
1. Neue Textstruktur DE+EN als Entwurf im Code (hinter der bestehenden Struktur, klar als ENTWURF kommentiert, noch nicht aktiv): ohne „vorläufig“/Testphase/6-Monats-Klausel; AV-Liste vollständig — **Stand nach D-Entscheidungen 2026-07-06: Supabase (EU), Google/FCM (Push), Resend (E-Mail-Versand), OpenStreetMap Foundation (Karten-Tiles bei der Trainer-Suche); Standort-Passage gemäß T13-Datenfluss-Doku („Standort wird nur auf deine Anfrage zur Trainer-Suche verwendet, nicht gespeichert“ — nur behaupten, wenn T13 es belegt!); Agora NICHT aufnehmen (Video-Calls deaktiviert, D2=A)**; Passage „Profile für Kinder werden durch den erziehungsberechtigten Kontoinhaber angelegt und verwaltet“; Speicherdauer-Formulierung neutral („bis Konto-Löschung; Details in der Datenschutzerklärung“).
2. Liste aller Behauptungen mit Code-Beleg (z. B. „von Backups ausgeschlossen“ → P0.5-Commits) als Kommentarblock — der Anwalt bekommt diese Liste.
3. NICHT aktivieren, `kConsentVersion` NICHT bumpen — das ist Stufe 2.

**Akzeptanzkriterien:** Entwurfstexte vollständig, jede Tatsachenbehauptung mit Beleg; keine Heil-/Therapieversprechen; analyze + Tests grün (Entwurf darf toter String sein).

**Verifikation:** `flutter analyze`; Diff-Review der Texte gegen die Belegliste.

**Nicht-Ziele/Verboten:** Keine finalen Rechtstexte erfinden (Anwalt liefert); Re-Consent nicht auslösen; EN nicht maschinell-wörtlich, sondern äquivalent.

---

### T06 — Video-Calls für v1 verstecken — ohne UI-Lücken *(D2=A, aktiv)*

**Rolle:** Du bist Senior Flutter Engineer mit Release-Management-Fokus (wie T04) — gleiche Gate-Philosophie, anderes Feature.

**Ziel:** Kein erreichbares Video-Call-UI in Prod-Builds; Dev-Builds bleiben voll funktionsfähig (dort existiert `AGORA_APP_ID`).

**Kontext & Befund (2026-07-05):** `AGORA_APP_ID` fehlt in `.env.prod` → `video_call_screen.dart:52-68` zeigt „Konfigurationsfehler“. Einstiegspunkte: videocam-Buttons in `chat_channel_screen.dart:395,403`; `IncomingCallListener` global in `app.dart:233`; Aufruf-Logik `openVideoCall` ebd. Z. ~128-138; Edge Functions `agora-token`, `notify-video-call`, `notify-call-request` bleiben deployt (harmlos, JWT-gated).

**Lies zuerst:** `chat_channel_screen.dart`, `app.dart`, `lib/features/video/presentation/widgets/incoming_call_listener.dart`, T04-Flag-Datei (falls vorhanden — gleiche Konstanten-Datei nutzen: `kVideoCallsEnabled`).

**Aufgabe:**
1. Flag `kVideoCallsEnabled = false` in derselben `launch_flags.dart` (T04 legt sie an — Reihenfolge beachten oder gemeinsam in einer Session).
2. Videocam-Buttons und `IncomingCallListener` dahinter gaten; eingehende Call-Events werden bei deaktiviertem Flag still ignoriert (kein Crash, Log-Zeile reicht).
3. Grep-Sweep: `VideoCall`, `openVideoCall`, `video_calls`-Referenzen in UI — auch Termin-/Appointment-Screens prüfen (gibt es dort „Call starten“-Wege?).
4. **UI-Lücken-Pass (Founder-Auflage 2026-07-06):** Die Chat-AppBar hat zwei videocam-Actions (`chat_channel_screen.dart:395,403`) — nach deren Entfernung darf die AppBar nicht leer/unausgewogen wirken; verbleibende Actions (falls keine: Titel-Layout) prüfen und Abstände anpassen. Falls Appointment-Flows einen Video-Verweis in Texten haben („per Video-Call“ in l10n/Terminen), Kopie auf neutrale Formulierung prüfen und anpassen lassen.
5. Test: Chat-Screen rendert ohne Call-Button bei Flag=false; bestehende 19 Chat-Tests bleiben grün.

**Akzeptanzkriterien:** Prod-Build ohne sichtbares/erreichbares Call-UI; **Chat- und Termin-Screens sehen vollständig aus, keine verwaisten Icons/Texte** (Screenshots vorher/nachher); Dev-Verhalten mit Flag=true unverändert; `make release-readiness-mobile` grün.

**Verifikation:** Testlauf + Prod-Build (`--no-codesign`); Sim-Durchlauf Chat-Screen + Termin-Screen mit Screenshots.

**Nicht-Ziele/Verboten:** Agora-Dependency NICHT aus pubspec entfernen (großer Diff, unnötig); Edge Functions nicht anfassen; keine Secrets ändern. Hinweis in den Abschlussbericht: Kamera-/Mikrofon-Strings in Info.plist bleiben (Apple toleriert deklarierte, ungenutzte Beschreibungen; Entfernen wäre T09-Scope-Kollision — dort abstimmen).

---

### T07 — Veraltete Datenschutz-Artefakte neutralisieren

**Rolle:** Du bist Compliance-Auditor mit Web-Ops-Hintergrund — du verfolgst, wo ein Dokument überall lebt (Repo, Hosting, Links, Suchmaschinen-Cache), bevor du es für tot erklärst.

**Ziel:** Keine erreichbare oder im Repo verlinkte veraltete Datenschutzerklärung mehr.

**Kontext & Befund (2026-07-05):** `public/privacy.html` — „Reflex Journey“-Titel, aber Kontakt = private Gmail-Adresse, Stand Dez 2024, unvollständig (kein FCM/Agora/Standort/Kinderdaten). `docs/privacy_policy.md` — beschreibt Isar/Firestore/Firebase Analytics (falscher Stack), CoreJourney-Branding. Firebase-Hosting-Konfig wurde 2026-07-02 entfernt (P1.3, Commit `f0d88ef`) — ob `public/` je deployed war und ob die URL noch lebt, ist **ungeklärt**. `web/` ist Flutter-Web-Boilerplate.

**Lies zuerst:** `public/privacy.html`, `docs/privacy_policy.md`, `git log --follow --oneline -- public/privacy.html`, P1.3 im Backlog.

**Aufgabe:**
1. Hosting-Recherche: alte Firebase-Hosting-URLs testen (`corejourney-prod.web.app`, `corejourney-prod.firebaseapp.com`, analog dev; plus `firebase hosting:sites:list`, falls CLI-Zugriff da ist, sonst curl). Ergebnis dokumentieren (HTTP-Status reicht — Inhalte nicht nötig).
2. Repo-Grep nach Links auf beide Dateien (`privacy.html`, `privacy_policy`) in lib/, docs/, README, Store-Draft, äußerem Repo `reflexjourney-app-site/`.
3. Beide Dateien löschen ODER durch 5-Zeilen-Stub ersetzen („ersetzt durch finale Datenschutzerklärung, siehe reflexjourney.app/datenschutz — P0.6“). Empfehlung: Stub in docs/ (Historie), Löschung in public/.
4. Falls eine Live-URL noch antwortet: Abschalt-Schritte für den Founder als Klick-Anleitung notieren (Firebase Console → Hosting) — Abschalten selbst ist gated (Deploy-artig).

**Akzeptanzkriterien:** Grep über beide Repos findet keinen aktiven Verweis mehr; Hosting-Status dokumentiert (erreichbar ja/nein, wo); Backlog P0.10 abhakbar oder als „⛔ blocked: Founder (Hosting abschalten)“ präzisiert.

**Verifikation:** Grep-Ausgabe + curl-Statuscodes im Bericht; lokaler Commit mit expliziter Dateiliste.

**Nicht-Ziele/Verboten:** Keine neue Policy schreiben (P0.6); nichts an `reflexjourney-app-site/auth/*` ändern; kein Firebase-Deploy/-Abschalten ohne Founder-Go.

---

### T08 — `experience_shares` als Baseline-Migration einfrieren

**Rolle:** Du bist Database Reliability Engineer für Supabase/Postgres — Repo=DB-Parität ist dein Berufsethos; du hast die P0.1-Baseline gebaut und wendest exakt dasselbe Verfahren an.

**Ziel:** Tabelle, Policies und RPC von `experience_shares` existieren als versionierte Migration; lokales Replay == Live-Zustand.

**Kontext & Befund (2026-07-05):** Einzige Live-Tabelle ohne Repo-Spur. Live: RLS an, Policies `shares_read` (`auth.uid() IS NOT NULL`), `shares_insert` (`auth.uid() = user_id`), `shares_delete_own`; FKs: `user_id → auth.users ON DELETE CASCADE`, `mood_checkin_id → mood_checkins ON DELETE SET NULL`. RPC `moderator_delete_experience_share` existiert nur live (Definition unbekannt — dumpen). Muster: `supabase/migrations/20260702_rls_baseline_core_tables.sql`.

**Lies zuerst:** `20260702_rls_baseline_core_tables.sql` (Verfahren + Stil), `docs/LAUNCH_MASTER_PROMPT.md` (Management-API-Zugriff read-only).

**Aufgabe:**
1. Live-Definitionen read-only dumpen: `pg_get_tabledef`-Äquivalent via Katalog-Queries (Spalten, Defaults, Indizes, FKs), `pg_policies`, `pg_get_functiondef` für die RPC. Keine Zeileninhalte.
2. Migration `2026070X_experience_shares_baseline.sql` schreiben (idempotent, `IF NOT EXISTS`-Stil wie die P0.1-Baseline).
3. `supabase db reset --local` — Replay muss grün sein; danach lokalen Zustand gegen Live-Dump diffen (Policies + Spalten identisch).
4. Live-Apply NICHT nötig (Objekte existieren live bereits) — in der Migration als Kommentar vermerken: „encodes pre-existing live state, apply is a no-op on prod“.

**Akzeptanzkriterien:** Replay grün; Diff lokal↔live leer; Migration erklärt sich selbst (Kommentarkopf mit Herkunft + Datum).

**Verifikation:** Reset-Ausgabe + Diff-Ergebnis im Bericht; Commit referenziert T08/P0.1-Korrektur.

**Nicht-Ziele/Verboten:** Kein Live-DDL; Policies nicht „verbessern“ (nur einfrieren — Änderungen wären T02/T03-Scope); keine Daten dumpen.

---

### T09 — iOS Info.plist bereinigen + Export-Compliance-Key

**Rolle:** Du bist iOS Release Engineer — Plist-Einträge, Entitlements und App-Store-Formulare sind dein Tagesgeschäft; du weißt, welche Keys Apple-Reviewer stutzig machen und welche der Upload-Flow verlangt.

**Ziel:** `Info.plist` deklariert genau das, was die App nutzt, plus `ITSAppUsesNonExemptEncryption=false`.

**Kontext & Befund (2026-07-05, `ios/Runner/Info.plist`; D-Entscheidungen 2026-07-06 eingearbeitet):** (a) `ITSAppUsesNonExemptEncryption` fehlt — App nutzt nur Standard-HTTPS/Plattform-Krypto → `false` ist korrekt (Roadmap 3.5, Quelle dort). (b) `NSLocationAlwaysAndWhenInUseUsageDescription` deklariert, aber Code nutzt nur `Geolocator.getCurrentPosition` (When-In-Use) → Always-Key entfernen. (c) `NSCalendarsUsageDescription` + `NSCalendarsWriteOnlyAccessUsageDescription` deklariert, aber `device_calendar` ist in pubspec auskommentiert → entfernen. (d) Kamera/Mikro-Strings: **bleiben** — Agora-Code bleibt im Bundle, nur UI versteckt (D2=A); fehlende Beschreibungen würden bei versehentlichem Zugriff crashen. (e) `NSLocationWhenInUseUsageDescription`: **bleibt** — Trainer-Discovery ist Launch-Feature (D3=B); Wortlaut gegen die T13-Permission-UX gegenlesen (Text muss zur nutzerinitiierten Suche passen: „…um Trainer in deiner Nähe anzuzeigen“ passt).

**Lies zuerst:** `ios/Runner/Info.plist`, T13-Stand im Tracker, `grep -rn "Geolocator\." lib/`.

**Aufgabe:** Keys gemäß Befund ändern; jede Entscheidung im Commit-Text begründen; iOS-Build beider Flavors bauen.

**Akzeptanzkriterien:** `ITSAppUsesNonExemptEncryption=false` gesetzt; keine ungenutzten Permission-Strings mehr (Stand D2/D3); Builds grün.

**Verifikation:** `flutter build ios --flavor development -t lib/main_development.dart --debug --simulator` und `flutter build ios --flavor production -t lib/main_production.dart --release --no-codesign`; `plutil -lint ios/Runner/Info.plist`.

**Nicht-Ziele/Verboten:** Entitlements nicht anfassen (aps-environment ist T22); Bundle-IDs/Signing nicht ändern; keine neuen Permissions.

---

### T10 — Android-Manifest bereinigen

**Rolle:** Du bist Android Release Engineer — Merged-Manifest-Analyse und Play-Data-Safety-Formulare sind dein Spezialgebiet.

**Ziel:** Keine deklarierten Permissions ohne genutzte Funktion.

**Kontext & Befund (2026-07-05, `android/app/src/main/AndroidManifest.xml`; D-Entscheidungen 2026-07-06 eingearbeitet):** `READ_CALENDAR` + `WRITE_CALENDAR` deklariert, `device_calendar` ist deaktiviert (pubspec Z. 81) → entfernen. `ACCESS_FINE_LOCATION`/`ACCESS_COARSE_LOCATION`: **bleiben** — Trainer-Discovery ist Launch-Feature (D3=B); in Play-Data-Safety wird Standort entsprechend deklariert (T12). CAMERA/RECORD_AUDIO: **bleiben** (Agora-Code bleibt im Bundle, D2=A versteckt nur die UI).

**Aufgabe:** Calendar-Permissions entfernen; Location/Camera/Audio-Begründung im Commit-Text dokumentieren; Merged Manifest prüfen.

**Akzeptanzkriterien:** Merged Manifest ohne Calendar-Permissions; APK-Build grün.

**Verifikation:** `flutter build apk --flavor development -t lib/main_development.dart --debug`; Merged-Manifest-Check (build/…/merged_manifests) auf die entfernten Einträge.

**Nicht-Ziele/Verboten:** `allowBackup="false"` und Intent-Filter (App Links) unangetastet; keine Gradle-Änderungen.

---

### T11 — Env-/Bundle-Hygiene

**Rolle:** Du bist Application Security Engineer mit Mobile-Fokus — du behandelst jedes App-Bundle als öffentlich lesbar und minimierst, was hineinkommt.

**Ziel:** Keine toten oder unnötigen Einträge in den gebündelten `.env`-Dateien; idealerweise nur die jeweils passende Datei pro Build.

**Kontext & Befund (2026-07-05):** `pubspec.yaml` Z. 104–105 bündelt `.env.dev` UND `.env.prod` in **jeden** Build (aus IPA/APK trivial extrahierbar). `.env.prod` enthält `TRAINER_CODE` — wird nirgends gelesen (repo-weiter Grep; `bootstrap.dart` liest nur SUPABASE_URL/ANON_KEY, REVENUECAT_API_KEY, ADMIN_EMAIL, AGORA_APP_ID, ENABLE_IOS_PROFILE_NOTIFICATIONS) — totes Relikt. `.env.dev` enthält `ADMIN_EMAIL` (E-Mail-Adresse im Bundle). Werte sind sonst client-public (anon key).

**Lies zuerst:** `pubspec.yaml` (assets), `lib/bootstrap/bootstrap.dart` (Z. 60–140), `.env.dev.example`.

**Aufgabe:**
1. `TRAINER_CODE`-Zeile aus `.env.prod` entfernen (Datei ist gitignored — Änderung lokal, im Bericht nur Key-Name nennen). `.env.dev.example` entsprechend bereinigen (dort ist TRAINER_CODE dokumentiert, Funktion existiert nicht mehr — durch Kommentar „obsolet seit server-seitiger Aktivierung“ ersetzen).
2. Prüfen, ob Flutter flavor-spezifische Assets erlaubt (Spoiler: nicht nativ). Pragmatische Optionen bewerten: (a) beide Dateien bündeln, aber Inhalte minimieren (Status quo, dokumentieren), (b) Build-Skript/`--dart-define`-Migration (größer, post-launch). Empfehlung schreiben, NICHT umbauen.
3. `ADMIN_EMAIL` bewerten: wird für den internen Tester-Gate gebraucht (Commit `1077e02` nutzt `@reflexjourney.de`-Domain-Check) — prüfen, ob die Variable überhaupt noch gelesen wird; wenn tot: raus.

**Akzeptanzkriterien:** `.env.prod` ohne tote Keys; Beide Builds starten (Dev auf Sim reicht); Empfehlung für post-launch dokumentiert (Backlog „parked“).

**Verifikation:** Key-Namen-Diff (nie Werte); App-Start im Sim; Grep-Belege im Bericht.

**Nicht-Ziele/Verboten:** Keine Secrets/Werte ausgeben oder rotieren; kein Umbau auf --dart-define vor Launch; `.env`-Dateien bleiben gitignored und unkommittet.

---

### T12 — Privacy-Nutrition-Labels-Entwurf v2 *(sinnvoll nach T13 — braucht dessen Datenfluss-Beleg)*

**Rolle:** Du bist App-Privacy-Spezialist für Apple Nutrition Labels und Play Data Safety — du mappst tatsächliche Code-Pfade auf Apples Datentypen-Taxonomie und weißt, dass „Datenerhebung“ bei Apple schon der Transit zum Drittserver ist.

**Ziel:** Ein vollständiger, code-belegter Labels-Entwurf, den der Founder nur noch in ASC/Play einträgt.

**Kontext & Befund (2026-07-05; D-Entscheidungen 2026-07-06 eingearbeitet):** Roadmap-3.3-Entwurf (E-Mail, Health & Fitness, User Content, Nutzungsdaten, kein Tracking) ist unvollständig. **Fix dazu kommt: Standort** (D3=B — `Geolocator.getCurrentPosition` bei der Trainer-Suche + Kontakt zum OSM-Tileserver; ob „präziser Standort, erhoben“ oder nur transient, entscheidet der T13-Datenfluss-Abschnitt — deshalb T13 zuerst). **Nicht dazu kommt: Kamera/Mikrofon-Daten** (Video-Calls versteckt, D2=A — Permissions bleiben deklariert, aber es fließen keine Daten). Dazu: **Diagnostics** (sobald Sentry, T15, drin ist) und Device-Tokens (FCM → `device_tokens`-Tabelle, 4 Policies live).

**Lies zuerst:** T13-Datenfluss-Abschnitt (Pflicht-Input), T15-Stand, `docs/APPSTORE_LAUNCH_ROADMAP.md` §3, alle `.from('…')`-Tabellen (Grep), `lib/core/push/`.

**Aufgabe:** Je Apple-Datentyp: erhoben ja/nein, verknüpft mit Identität ja/nein, Tracking nein, Zweck — mit Code-/Tabellen-Beleg pro Zeile. Gleiches als Play-Data-Safety-Mapping. Als Markdown-Tabelle in `docs/STORE_LISTING_DRAFT.md` anhängen oder eigene Datei `docs/PRIVACY_LABELS_DRAFT.md`.

**Akzeptanzkriterien:** Jede Zeile hat einen Beleg; keine Kategorie der tatsächlichen Verarbeitung fehlt (Gegenprobe: Tabellenliste der App, Permissions, Dritt-SDKs firebase_messaging/agora/geolocator/audioplayers); konsistent mit Consent-Entwurf (T05).

**Verifikation:** Cross-Check-Tabelle SDKs↔Labels im Dokument.

**Nicht-Ziele/Verboten:** Nichts in ASC eintragen (Founder); keine Tracking-Deklaration erfinden (App hat keins — belegen statt behaupten).

---

### T13 — Trainer-Discovery fertig bauen: „make it work“ *(D3=B, Founder-Entscheidung 2026-07-06)*

**Rolle:** Du bist Senior Product Engineer mit Maps-/Geo-Spezialisierung und Privacy-Bewusstsein — du hast Karten-Features gebaut, die mit null Einträgen genauso überzeugend wirken wie mit tausend, du kennst die OSM-Tile-Usage-Policy auswendig, und du behandelst jeden Standort-Abruf als datenschutzrelevantes Ereignis, das begründet, minimal und nutzerinitiiert sein muss.

**Ziel:** Die Trainer-Suche ist launch-fertig: sie funktioniert einwandfrei mit 0 Trainern (Launch-Realität), mit wenigen und mit vielen; jede Permission-Verzweigung endet sinnvoll statt in einer Sackgasse; die Karte erfüllt die OSM-Auflagen; und der Standort-Datenfluss ist dokumentiert (Input für T12-Labels, T05-Consent und den Anwaltsauftrag P0.6).

**Kontext & Befund (2026-07-05):** Live 0 freigeschaltete Trainer, 1 pending (Aggregat — NICHT davon ausgehen, dass zum Launch welche da sind). `trainer_discovery_screen.dart`: Standort-Abfrage Z. 39–53 (`Geolocator.checkPermission/requestPermission/getCurrentPosition`), `TileLayer` mit `tile.openstreetmap.org` Z. 392–394, `userAgentPackageName` gesetzt, **keine Attribution** (OSM verlangt „© OpenStreetMap contributors“ mit Link auf openstreetmap.org/copyright). Zweite Karte: `trainer_location_picker_widget.dart` (Trainer-Onboarding) — ebenfalls OSM, ebenfalls ohne Attribution. Backend: RPCs `find_trainers_nearby` (Migration `2026042901`) und `list_public_trainers` (`2026050502`). **Achtung: eine einzige Supabase-Instanz für Dev+Prod mit echten Daten — keinerlei Test-Trainer live anlegen.**

**Lies zuerst:** `trainer_discovery_screen.dart` komplett, `trainer_location_picker_widget.dart`, beide RPC-Migrationen, `lib/features/trainer/presentation/providers/` (Discovery-Provider), Einstiegspunkte per Grep `Routes.trainerDiscovery`, `docs/LAUNCH_MASTER_PROMPT.md` (Live-DB-Regeln).

**Aufgabe:**
1. **Flow- und Datenfluss-Analyse (zuerst, dokumentieren):** Von welchen Screens ist die Suche erreichbar? Und kritisch: **verlassen die Gerätekoordinaten das Gerät** (z. B. als Parameter an `find_trainers_nearby`)? Werden sie gespeichert oder nur transient in der Query genutzt? Ergebnis als kurzer Abschnitt „Standort-Datenfluss“ in den Bericht — wörtlich verwendbar für T12/T05/P0.6.
2. **Permission-UX nutzerinitiiert machen:** Standort erst nach explizitem Tap („Trainer in meiner Nähe finden“), nie beim Screen-Öffnen. Alle Zweige bauen: (a) erlaubt → Suche läuft; (b) abgelehnt → freundliche Erklärung + Alternative (siehe 3.); (c) dauerhaft abgelehnt → Erklärung + „Einstellungen öffnen“-Button; (d) Ortungsdienste systemweit aus → eigener Hinweis. Kein Zweig endet in leerem Screen oder Roh-Exception.
3. **Alternative ohne Standort:** prüfen, was die RPCs hergeben — wenn `list_public_trainers` eine standortfreie Liste liefert, als Fallback „Alle Trainer anzeigen“ anbieten. Damit ist die Suche auch für Nutzer ohne Standort-Freigabe nutzbar (und der Reviewer ohne Location sieht trotzdem ein funktionierendes Feature).
4. **Empty-States ehrlich und absichtsvoll (Founder-Auflage: keine hässlichen Lücken):** zwei Fälle unterscheiden — „keine Trainer in deiner Nähe“ vs. „noch keine Trainer freigeschaltet“ (Launch-Realität). Copy DE+EN, heilversprechen-frei, einladend statt entschuldigend (z. B. „Wir prüfen und schalten gerade die ersten Trainer frei. Schau bald wieder vorbei — dein Training läuft auch ohne Trainer weiter.“). Gestaltung: Illustration/Icon + Text + sinnvoller CTA (zurück zum Training), keine leere Grau-Karte.
5. **OSM-Attribution auf BEIDEN Karten:** flutter_map `RichAttributionWidget` (oder `SimpleAttributionWidget`) mit „© OpenStreetMap contributors“, Tap öffnet openstreetmap.org/copyright via url_launcher.
6. **Netz-/Fehlerzustände:** Tiles brauchen Netz — bei Offline/Timeout klare Meldung statt grauer Kachelwüste (App ist sonst offline-first, Nutzer erwarten Funktion); Ladezustand mit Indikator; RPC-Fehler → Retry-Angebot.
7. **UI-Lücken-Pass:** kompletter Screen-Durchlauf aller Zustände mit Screenshots (Erst-Öffnen, Suchen, Ergebnis, jeder Permission-Zweig, offline, leer) — jeder Zustand muss gestaltet aussehen.
8. **Tests:** Provider-/Repository-Tests für die Zustandslogik (Permission-Zweige mocken, Empty-Ergebnis, RPC-Fehler); bestehende Trainer-Tests bleiben grün. Backend-Verhalten der RPCs read-only gegen die Live-DB belegen (Aggregat/EXPLAIN reicht) oder lokal via `supabase db reset --local` + lokalem Seed testen — **niemals Seeds in die Live-DB**.

**Akzeptanzkriterien:** Alle 7 UI-Zustände gestaltet (Screenshot-Serie im Bericht); Standort-Abruf nur nach Nutzer-Tap; Attribution auf beiden Karten sichtbar und tappbar; standortfreier Fallback funktioniert (falls RPC vorhanden — sonst begründet dokumentiert); „Standort-Datenfluss“-Abschnitt liegt vor; `make release-readiness-mobile` grün; on-device-Durchlauf (Dev-Build) bestanden.

**Verifikation:** Testlauf + Sim/Geräte-Durchlauf mit systematischem Durchspielen aller Permission-Zweige (iOS-Einstellungen → Standort wechseln); Screenshots; RPC-Belege.

**Nicht-Ziele/Verboten:** Kein Tile-Provider-Wechsel und kein eigener Tile-Proxy (post-launch, falls Volumen); **keine Trainer-/Testdaten in der Live-DB anlegen**; RLS/RPCs nicht umbauen (nur lesen/verstehen); kein Redesign der Trainer-Profilseiten; Trainer-Onboarding-Flow (Bewerbung) nicht anfassen — nur die Picker-Karte bekommt Attribution.

---

### T14 — Review-Paket: Demo-Account + Review-Notizen *(nach ASC-Record)*

**Rolle:** Du bist App-Review-Readiness-Manager — du hast dutzende Health-Apps durch Apple-Reviews begleitet und schreibst Reviewer-Notizen, die Rückfragen verhindern, bevor sie entstehen.

**Ziel:** Ein Reviewer kann die App ohne Rückfrage vollständig prüfen.

**Kontext & Befund:** `docs/demo_account_setup.md` ist veraltet (Firebase-Auth-Anleitung; App nutzt Supabase). Live: 0 Trainer, quasi leerer Feed → ohne Erklärung wirkt das unfertig. Zielgruppen-Konstellation (Erwachsene führen Kinderprofile) braucht proaktive Einordnung (Guideline 5.1.3/1.3-Abgrenzung, siehe Roadmap §2 Phase 5.1).

**Lies zuerst:** `docs/demo_account_setup.md` (als Negativ-Vorlage), `docs/STORE_LISTING_DRAFT.md`, D1/D2/D3-Umsetzungsstand, Roadmap §5.

**Aufgabe:**
1. `docs/demo_account_setup.md` neu schreiben: Supabase-basiert; Schritt-für-Schritt für den Founder (Konto anlegen via App-Signup mit Wegwerf-Adresse, Confirm-Link, sinnvoller Beispiel-Fortschritt: abgeschlossenes Intake, 3–5 Trainingstage, 2 Journal-Einträge, 1 Mood-Check-in — **fiktive Inhalte, keine echten Daten**); Hinweis fett: Zugangsdaten NUR in ASC, nie im Repo.
2. Review-Notizen-Entwurf (DE Arbeitsfassung + EN final, Apple liest EN): Zielgruppe Erwachsene; Kinderprofile nur unter Eltern-Account, bewusst NICHT Kids-Kategorie; kein Medizinprodukt/keine Diagnose (Zitat des Disclaimer-Absatzes aus dem Store-Text); Offline-Fähigkeit (Reviewer-Netzwerk); Status Trainer-Bereich („Trainer werden manuell geprüft und freigeschaltet; zum Review-Zeitpunkt ggf. leer — die App ist als Selbstanwender-Programm voll nutzbar“); UGC-/Moderations-Status gemäß D1; Demo-Account-Hinweise.
3. Beides dem Founder zur Freigabe vorlegen (Texte werden öffentlich-ähnlich — Copy-Regeln gelten).

**Akzeptanzkriterien:** Founder kann die Anleitung ohne Rückfragen ausführen; Notizen decken alle in der Roadmap §2/Phase-5-Tabelle gelisteten Ablehnungsrisiken ab; keine Zugangsdaten im Repo.

**Verifikation:** Selbst-Review gegen die Ablehnungsgründe-Tabelle; Grep, dass keine Credentials committet sind.

**Nicht-Ziele/Verboten:** Demo-Konto nicht selbst live anlegen (Founder macht das — E-Mail-Postfach nötig); keine echten Nutzer-/Kinderdaten als Beispiel.

---

### T15 — Sentry einbauen (EU, DSGVO-schonend)

**Rolle:** Du bist Observability Engineer mit Datenschutz-Fokus — du konfigurierst Crash-Reporting so, dass es beim Anwalt keine Zusatzseiten erzeugt: EU-Region, kein PII-Autocapture, minimale Datentiefe.

**Ziel:** Crashes und schwere Fehler aus TestFlight-/Prod-Builds erscheinen im Sentry-Dashboard (EU); Testphase belegt.

**Kontext:** Founder-Entscheidung 2026-07-05: Sentry, EU-Datenhaltung (Backlog P3, Entscheidung 8.6). Aktuell existiert kein Crash-Reporting (`firebase_crashlytics` auskommentiert). Bootstrap: `lib/bootstrap/bootstrap.dart` (Init-Reihenfolge beachten: dotenv → Firebase → Supabase). Logging: `lib/core/logging/logger_service.dart`.

**Lies zuerst:** `bootstrap.dart`, `logger_service.dart`, `pubspec.yaml`, Flavor-Setup (`main_development/production.dart`).

**Aufgabe:**
1. `sentry_flutter` einbinden; DSN via `.env` (neuer Key `SENTRY_DSN`, nur Name dokumentieren); Init in bootstrap mit: `sendDefaultPii=false`, EU-Region-DSN, `tracesSampleRate` 0 oder minimal, Environment = Flavor, Release = pubspec-Version, `beforeSend`-Hook der URLs/Extra-Daten strippt (keine Journal-/Chat-Inhalte in Breadcrumbs — Logger-Breadcrumb-Integration bewusst NICHT aktivieren oder filtern).
2. `appLogger.e`-Pfad optional an `Sentry.captureException` koppeln (nur Fehlerobjekt + Stacktrace, keine strukturierten Nutzdaten).
3. Dev-Flavor: Sentry standardmäßig AUS (kein Rauschen), aktivierbar per env.
4. Test-Crash-Mechanik: über die bestehenden Dev-Tools (`lib/features/dev_tools/`) einen „Test-Crash senden“-Knopf (nur Dev/interner Tester-Gate).
5. Doku-Notiz für T05/T12: Sentry als Verarbeiter (Diagnostics) ergänzen.

**Akzeptanzkriterien:** Test-Crash erscheint im EU-Dashboard (Founder bestätigt Sichtung oder Screenshot); Prod-Build baut; keine PII in Events (Event-JSON eines Testfehlers geprüft); Tests grün.

**Verifikation:** Test-Event ausgelöst + im Dashboard gesehen (Founder-Bestätigung einholen); `make release-readiness-mobile`.

**Nicht-Ziele/Verboten:** Kein Performance-Monitoring/Session-Replay; DSN-Wert nie in Chat/Repo; Sentry-Projekt-Anlage ist Founder-Klickarbeit (Anleitung liefern, EU-Region betonen).

---

### T16 — Build-Nummern-Bump-Prozess

**Rolle:** Du bist Release Engineer — Versionsschemata, die Uploads nie kollidieren lassen und trotzdem menschenlesbar bleiben, sind deine Handschrift.

**Ziel:** Ein dokumentierter, halbautomatischer Prozess, mit dem jeder ASC-/Play-Upload eine höhere Build-Nummer bekommt.

**Kontext & Befund:** `pubspec.yaml`: `version: 1.0.5+2026051001` — datumsbasiertes Schema (`YYYYMMDDNN`), letzter Bump Mai. iOS `CFBundleVersion` = `$(FLUTTER_BUILD_NUMBER)`, Android `versionCode = flutter.versionCode` — beide erben aus pubspec, gut.

**Aufgabe:**
1. Schema bestätigen/dokumentieren: `+YYYYMMDDNN` (NN = Laufnummer des Tages) — passt in Androids `versionCode`-Limit (2.1 Mrd) bis Jahr 2147+NN-Grenze prüfen: 2026051001 < 2147483647 ✓, aber 2026-Format sprengt das Limit ab `21474836xx` nie — kurz nachrechnen und im Doc festhalten.
2. Makefile-Target `make bump-build` (setzt Build-Nummer auf heute+NN, idempotent) + `make bump-patch` (1.0.5→1.0.6, Build-Reset NN=01).
3. `docs/RELEASE_READINESS_CHECKLIST.md` um den Bump-Schritt vor jedem Upload ergänzen.

**Akzeptanzkriterien:** Zwei aufeinanderfolgende `make bump-build`-Läufe erzeugen streng steigende Nummern; pubspec bleibt valide; Doku aktualisiert.

**Verifikation:** Target zweimal ausführen, `git diff pubspec.yaml` zeigen, danach zurücksetzen (oder ersten echten Bump stehen lassen — mit Founder-Hinweis).

**Nicht-Ziele/Verboten:** Keine CI-Automatisierung (post-launch); Marketing-Version (1.0.5) nicht eigenmächtig erhöhen.

---

### T17 — Confirm-Link auf dem iPhone antippen *(Founder-Task, Claude assistiert)*

**Rolle:** Du bist QA-Lead, der einen manuellen Gerätetest protokolliert — du führst den Founder in kleinsten Schritten und dokumentierst beweisfähig.

**Ziel:** Beweis, dass der `/auth/confirm`-Universal-Link die **App** öffnet (nicht Safari) und die Bestätigung in-app durchläuft. Letzter offener Punkt aus P1.2.

**Kontext:** Reset-Link (`/auth/reset-password`) öffnet die App nachweislich (QA 2026-07-04); der Confirm-Link wurde bisher nur im Browser einer Temp-Mail bestätigt. AASA liegt live, App verarbeitet `token_hash` seit Commit `58827aa`.

**Aufgabe (Anleitung für den Founder ausgeben):** 1. Wegwerf-Adresse erstellen (z. B. Temp-Mail-Dienst, der auf dem iPhone abrufbar ist). 2. In der App registrieren. 3. Mail **auf dem iPhone** öffnen, Link **antippen** (nicht kopieren). 4. Beobachten: öffnet sich die App mit Bestätigungs-/Login-Flow? 5. Ergebnis (App/Safari/Fehler) + iOS-Version notieren. Danach: Wegwerf-Konto in der App wieder löschen (Konto-Löschung ist implementiert — gleich mitgetestet).

**Akzeptanzkriterien:** App öffnet sich via Universal Link; Signup abschließbar; Wegwerf-Konto danach gelöscht.

**Verifikation:** Founder-Protokoll; Backlog-P1.2-Restpunkt abhaken mit Datum.

**Nicht-Ziele/Verboten:** Kein Test mit echter persönlicher E-Mail; keine Auth-Config-Änderungen; falls es fehlschlägt → als Bug protokollieren, `systematic-debugging`-Session starten, NICHT ad-hoc an Configs drehen.

> 🔶 **R2 — Empfehlung zur Entscheidung (2026-07-06):** Diesen 5-Minuten-Test mit der **Screenshot-Sitzung** (P3: Store-Screenshots, 6,9″) koppeln — beides braucht das iPhone in der Hand, eine Sitzung erledigt beides. Ablauf exakt nach dem Prompt oben: Temp-Mail-Dienst im iPhone-Safari (z. B. temp-mail.org), in der App registrieren, Link **antippen**; als Beleg reicht ein kurzes Bildschirmvideo oder zwei Screenshots. **Zu entscheiden:** nur der Termin — sag in einer Session „Geräte-Sitzung jetzt“, Claude führt dich durch. *(Nach Entscheidung: Index in diesem Dokument aktualisieren.)*

---

### T18 — Firebase-Admin-Key verschieben/rotieren

**Rolle:** Du bist Security Engineer für Secrets-Management — jeder Klartext-Key auf Platte ist für dich ein Incident in Wartestellung.

**Ziel:** Kein Service-Account-Key mehr im Projektbaum; Klarheit, ob er überhaupt gebraucht wird.

**Kontext & Befund (2026-07-05):** `corejourney-prod-firebase-adminsdk-fbsvc-39bd4a6ca5.json` liegt im App-Root (gitignored, nie committet — verifiziert; aber unverschlüsselt, volle FCM-/Projektrechte). Nutzung unklar — Edge Functions senden FCM über eigene Secrets, nicht über diese Datei.

**Aufgabe:**
1. Nutzungs-Recherche: Grep über App-Repo + äußeres Repo + Skripte (`scripts/`, `package.json`) nach dem Dateinamen und nach `GOOGLE_APPLICATION_CREDENTIALS`/`admin.initializeApp`-Mustern. Shell-History NICHT durchsuchen (privat).
2. Falls ungenutzt: Founder-Anleitung — Datei in 1Password/Keychain sichern, vom Datenträger löschen; optional (empfohlen) in der Google-Cloud-Console den Key rotieren/widerrufen (Klick-Anleitung; das Widerrufen ist gated: Founder klickt selbst).
3. Falls genutzt: dokumentieren wofür, und den Pfad aus dem Projektbaum in einen Nicht-Repo-Ort verlegen.

**Akzeptanzkriterien:** Datei nicht mehr im Projektbaum ODER dokumentierter Nutzer + neuer Ablageort; Rotation-Empfehlung ausgesprochen.

**Verifikation:** `ls` + Grep-Belege; kein Funktionsverlust (FCM-Smoke: Edge-Function-Reminder-Lauf bleibt grün — read-only in `net._http_response` prüfbar).

**Nicht-Ziele/Verboten:** Key-Inhalt nie ausgeben; nicht selbst in der Cloud-Console widerrufen (Founder-Klick); keine neuen Keys erzeugen.

---

### T19 — In-App-Link zur finalen Datenschutz-URL *(nach P0.6)*

**Rolle:** Du bist Flutter Engineer mit UX-Gespür für Settings-Screens — kleiner Task, sauber ausgeführt.

**Ziel:** Nutzer erreichen die finale Datenschutzerklärung aus der App (Settings/Profil), Apple-üblich.

**Kontext:** Aktuell existiert keine Policy-URL in lib/ (Grep 2026-07-05). Ziel-URL: `https://reflexjourney.app/datenschutz` (Founder-Entscheidung 8.3), live erst nach P0.6/W4.

**Aufgabe:** ListTile „Datenschutzerklärung“ in den Einstellungen (`lib/features/settings/`), `url_launcher` (bereits dependency), DE+EN l10n; daneben prüfen, ob Impressum-Link (W1) gleich mit soll (Empfehlung: ja, ein Block „Rechtliches“).

**Akzeptanzkriterien:** Link öffnet die live URL im Browser; l10n vollständig; Tests grün.

**Verifikation:** Sim-Tap + `make release-readiness-mobile`.

**Nicht-Ziele/Verboten:** Kein WebView-Embedding; nicht vor Live-Gang der Seite mergen (sonst 404 im Review!).

---

### T20 — Doku-Korrekturen (FEATURE_FLAGS, TESTFLIGHT_QUICKSTART)

**Rolle:** Du bist Technical Writer mit Auditor-Blick — Doku, die Falsches behauptet, ist schlimmer als keine; du korrigierst gegen den Code, nicht gegen Erinnerungen.

**Ziel:** Beide Dokumente sagen die Wahrheit über das heutige System.

**Kontext & Befund (2026-07-05):** `docs/FEATURE_FLAGS.md` beschreibt Firebase-Remote-Config-Flags — im Code existiert nichts davon (0 Treffer `FeatureFlag` in lib/); live gibt es eine ungelesene `feature_flags`-Tabelle. Falls T04/T06/T13 die `launch_flags.dart`-Konstanten eingeführt haben: DAS ist das reale System. `docs/TESTFLIGHT_QUICKSTART.md` nennt `com.alexandermessinger.corejourney`, GitHub-Pages-Hosting, Pfade nach `/dev/corejourney` — Realität: Bundle-ID `de.reflexjourney.app` (registriert 2026-07-03), Schemes/Flavors existieren, ASC-Record fehlt noch.

**Aufgabe:** FEATURE_FLAGS.md: durch kurze, wahre Fassung ersetzen (compile-time Konstanten in `launch_flags.dart`; Remote-Config = nicht implementiert, `feature_flags`-Tabelle ungenutzt — als „Zukunft/parked“ markieren). TESTFLIGHT_QUICKSTART.md: neu schreiben auf heutigem Stand (richtige Bundle-ID, `flutter build ipa --flavor production -t lib/main_production.dart` bzw. Xcode-Archive-Weg, Verweis auf T16-Bump, Verweis auf Backlog-P3-ASC-Punkte), veraltete Links raus.

**Akzeptanzkriterien:** Kein Verweis mehr auf alte Bundle-ID/Pfade/GitHub-Pages (Grep); jede Anleitung gegen Code/Makefile geprüft.

**Verifikation:** Grep-Sweep `corejourney.dev|corejourney.care|com.alexandermessinger|/dev/corejourney` über docs/ → nur historische Backlog-/Lessons-Erwähnungen bleiben.

**Nicht-Ziele/Verboten:** Keine neuen Prozesse erfinden; Roadmap/Backlog nicht umschreiben (nur verlinken).

---

### T21 — Trainer-Selbst-Freischaltung: DEV-Bypass verifizieren

**Rolle:** Du bist Application-Security-Reviewer — du verfolgst einen Privilegien-Pfad vom Button bis zur DB-Zeile und glaubst nur dem Code.

**Ziel:** Nachweis, dass in **Prod-Builds** niemand ohne approval-gebundenen Code Trainer werden kann. (Deckt Roadmap Phase 3.8 / Marketing-Spec Blocker 2.)

**Kontext & Befund (2026-07-05):** Server-seitig sauber: `supabase/functions/activate-trainer/index.ts` verlangt JWT + `trainer_invite_codes`-Row mit `purpose='trainer_application_approval'` und verknüpfter Bewerbung. Offen: `.env.dev.example` dokumentierte einst „TRAINER_CODE leer lassen → in DEV-Builds direkt aktivierbar (kein Code nötig)“ — existiert dieser Client-Bypass noch, und ist er in Prod sicher tot?

**Lies zuerst:** `lib/features/trainer/presentation/providers/trainer_provider.dart` (ab Z. ~550), `trainer_application_status_screen.dart`, alle Aufrufer von `activateTrainerRole`, `lib/features/trainer/presentation/screens/trainer_profile_setup_screen.dart`, Grep `isDevelopment` in trainer-Feature, `2026041504_secure_role_activation.sql`.

**Aufgabe:** Pfad-Analyse dokumentieren: (1) Welche UI-Wege führen zur Trainer-Rolle? (2) Gibt es einen `isDevelopment`-Bypass und greift er in Prod-Flavor sicher nicht? (3) Kann die RLS/RPC-Seite (`set_user_role` Function? direkte `profiles.role`-Updates?) von Clients missbraucht werden — `profiles`-UPDATE-Policy live gegenprüfen (read-only Katalog-Query, Policy-Text vorhanden). Falls ein realer Bypass existiert: kleinste Absicherung umsetzen (z. B. Bypass an `kDebugMode`/Flavor koppeln), sonst nur Beleg-Bericht.

**Akzeptanzkriterien:** Schriftlicher Beleg-Bericht (Backlog-Notiz) „Selbst-Freischaltung in Prod nicht möglich, Belege: …“ ODER gefixter Bypass mit Test.

**Verifikation:** Code-Zitate + Policy-Dump (Namen/Bedingungen, keine Daten); Tests grün falls Codeänderung.

**Nicht-Ziele/Verboten:** Keine Live-Rollenspiele (keine Test-Aktivierung gegen Prod-DB); Edge Function nicht redeployen.

---

### T22 — aps-environment im ersten Store-Archiv prüfen *(beim ersten Archive)*

**Rolle:** Du bist iOS Release Engineer (wie T09) — Entitlement-Forensik am gebauten Artefakt statt Vertrauen in Xcode-Magie.

**Ziel:** Beweis, dass der signierte Store-Build `aps-environment=production` trägt (Datei im Repo sagt `development`; das Signing ersetzt das normalerweise — unverifiziert).

**Kontext:** `ios/Runner/Runner.entitlements`: `aps-environment=development`. Push ist launch-relevant (Reminder-System v2).

**Aufgabe (nach dem ersten Archive/IPA-Build, mit Founder):** Aus dem `.xcarchive`/`.ipa` die Entitlements extrahieren: `codesign -d --entitlements :- <App-Pfad>` bzw. `security cms -D -i embedded.mobileprovision` — `aps-environment` muss `production` sein. Falls nicht: Xcode-Signing-Konfiguration korrigieren (Release-Konfig → Distribution-Profil) und erneut archivieren.

**Akzeptanzkriterien:** Extrahierte Entitlements zeigen `production`; Push-Empfang auf TestFlight-Build einmal real beobachtet (Reminder oder Test-Push).

**Verifikation:** Kommando-Ausgabe (nur der aps-environment-Wert) im Protokoll.

**Nicht-Ziele/Verboten:** Entitlements-Datei nicht blind auf `production` hart editieren, ohne zu verstehen, dass Debug-Builds dann ggf. keine Sandbox-Pushes mehr bekommen — erst prüfen, dann gezielt ändern.

---

### T23 — Paywall-Grundstruktur bauen: inaktiv hinter Flag *(D4, Founder 2026-07-07)*

**Rolle:** Du bist Senior Flutter Engineer mit Monetarisierungs-Erfahrung (Entitlements, IAP-Architekturen) und Review-/Datenschutz-Bewusstsein — du baust Kaufstrukturen so, dass sie vor der Aktivierung unsichtbar und nach der Aktivierung auditierbar sind.

**Ziel:** Die komplette Paywall-Struktur existiert im Code und ist per Compile-Time-Flag deaktiviert: Entitlement-Modell, Paket-Gating ab Paket 2, Paywall-Screen (Trio) — Launch-Verhalten bleibt exakt „alles kostenlos“.

**Kontext (D4, 2026-07-07):** Alle Pakete launchen gleichzeitig, Nutzer trainieren chronologisch; Programmdauer real 10–12+ Monate. Bestätigtes Trio: Monat 12,99 € / **Jahr 89,99 € (hervorgehoben)** / Lifetime 149 €; KEIN Einzelpaket-Verkauf. Pflichtlektüre: `docs/MONETARISIERUNG_EVALUATION.md` (inkl. D4-Update) + `docs/superpowers/specs/2026-05-28-monetization-design.md` §3 (Datenmodell). Muster für Flags: `lib/config/launch_flags.dart` (T04/T06).

**Lies zuerst:** beide o. g. Docs; `launch_flags.dart`; den Paket-/Enrollment-Flow (Grep: `Routes.packages`, `enrollments`, wo Paketzugang entsteht und wo Paket 1 endet); `supabase/migrations/20260702_rls_baseline_core_tables.sql` (profiles-Stand); bestehende Paket-/Enrollment-Tests.

**Aufgabe:**
1. Migration `profiles`-Erweiterung nach Design §3: `is_premium`, `premium_type` (`monthly|yearly|lifetime|code` — `code` NEU für T24), `premium_valid_until`, `stripe_customer_id`; als Datei + `supabase db reset --local`-Replay. **Live-Apply NICHT ausführen** (gated — Founder-Go am Session-Ende sammeln).
2. `kPaywallEnabled = false` in `launch_flags.dart` (Kommentar: Aktivierung erst nach R8-Trigger + AGB).
3. `PremiumRepository` + `entitlementProvider`. Semantik glasklar: Flag aus → jeder Zugriff „frei“ (heutiges Verhalten); Flag an → Paket 1 frei, Paket 2+ nur mit Entitlement (`is_premium` bzw. lifetime/code ohne Ablauf).
4. Paywall-Screen: Trio B, Jahr visuell hervorgehoben („2 Monate geschenkt“), Lifetime als Anker; ehrliche Dauer-Angabe erlaubt („Das Programm dauert typischerweise 10–12 Monate“) — **keine Countdown-/Rabatt-/Angst-Mechaniken, keine Heil-/Wirkversprechen**; DE+EN l10n; Preise aus einer einzigen Konstanten-Datei. Kaufbuttons rufen eine abstrakte `PurchaseService`-Schnittstelle — Stub meldet „Kauf in dieser Version noch nicht verfügbar“ (RevenueCat = T25).
5. Gating-Einbau am Paketübergang (Trigger laut Design: Abschluss Paket 1 → Start Paket 2) + defensiver Route-Guard für Paket-Inhalte.
6. Tests: Flag-aus = alles frei (Regressionsschutz!); Flag-an-Matrix (kein Entitlement/monthly abgelaufen/yearly aktiv/lifetime/code); Paywall rendert Trio ohne aktiven Kaufpfad.
7. Screenshot-Evidenz Paywall (DE+EN, Harness-Muster T04/T13) → `docs/evidence/T23/`.

**Akzeptanzkriterien:** `make release-readiness-mobile` grün; Prod-Build baut; Verhalten mit Flag=false nachweislich unverändert; Migration replayt lokal sauber; Screenshots liegen vor.

**Nicht-Ziele/Verboten:** kein RevenueCat/IAP-SDK (T25); kein Live-DDL; kein Stripe; keine AGB-/Rechtstexte erfinden; Einzelpaket-Kauf NICHT bauen (bewusst, D4).

---

### T24 — Freischalt-Codes für Gründungsnutzer *(nach T23)*

**Rolle:** Du bist Backend-Engineer mit Security-Fokus — Codes sind Zahlungsäquivalente, Einlösung passiert ausschließlich server-seitig.

**Ziel:** Ein Gründungsnutzer-Code lässt sich in der App einlösen und setzt ein dauerhaftes Entitlement (`premium_type='code'`); Erzeugung/Verwaltung bleibt service-role-only.

**Kontext:** Live-Tabelle `access_codes` existiert (RLS an, 0 Policies = deny-all für Clients — so lassen!). Founder-Anforderung 2026-07-05: Codes geben allen Content dauerhaft oder teilweise kostenlos.

**Aufgabe:** (1) Live-Schema von `access_codes` prüfen (read-only Katalog-Query — braucht Session mit Standard-Freigaben) und fehlende Spalten (z. B. `redeemed_by`, `redeemed_at`, `grants`) als Migration ergänzen; (2) Edge Function `redeem-access-code`: JWT-Pflicht, validiert Code, markiert einmalige Einlösung atomar, setzt Entitlement in `profiles`; deno-Tests; **Deploy gated (Founder-Go)**; (3) Einlöse-UI in den Einstellungen (sichtbar auch bei aktiver Paywall sinnvoll positioniert); (4) Doku: wie der Founder Codes erzeugt (service-role, nie im Chat/Repo).

**Akzeptanzkriterien:** Doppel-Einlösung unmöglich (Test); Client kann Codes weder lesen noch erzeugen; Suite grün.

**Nicht-Ziele/Verboten:** keine Codes im Klartext in Logs/Chat; keine Client-seitige Validierung; RLS von `access_codes` nicht öffnen.

---

### T25 — Cross-Platform-Payments *(Plan fertig; Founder-/Account-Gates offen)*

**Verbindlich:** `docs/PAYMENTS_MASTER_PLAN.md` (Produkte, Multi-Grant-Ledger,
RevenueCat-Identität, Apple/Google, Lifecycle/Testmatrix),
`docs/PAYMENTS_BUILD_PROMPTS.md` (T25.0–T25.5 kopierfertig) und
`docs/MONETIZATION_STUDIO_MASTER_PROMPT.md` (Status + nächster Task).

**Reihenfolge:** T25.0 Multi-Grant-/Benefit-Code-Fundament → T25.1 RevenueCat Core/Test Store
→ T25.2 Webhook/Reconciliation → T25.3 Apple IAP + T25.4 Google Play Billing
→ T25.5 Operations/Activation Readiness. Ein einzelnes `premium_type` ist nur
Legacy-Projektion und darf Code/Lifetime/Store-Grants nicht gegenseitig
überschreiben. Kauf nur nach Login; RevenueCat nie beim App-Logout in eine
anonyme ID schicken. Aktivierung bleibt eigener Founder-Go nach R8/Legal/E2E.

---

### T26 — Anmeldung mit Apple & Google *(geplant 2026-07-07, Founder-Wunsch)*

**Rolle:** Du bist Senior Flutter Engineer mit Auth-Schwerpunkt — du kennst Supabase-Social-Login, Apples HIG-Button-Regeln und die Review-Fallstricke (4.8, Token-Revocation) auswendig.

**Ziel:** Login-/Signup-Screen bietet zusätzlich „Mit Apple anmelden“ und „Mit Google anmelden“; der bestehende E-Mail/Passwort-Flow bleibt unverändert. Social-Nutzer durchlaufen dieselbe Consent-/Onboarding-Mechanik.

**Kontext & Regeln:** Apple Guideline 4.8: Wer Google-Login anbietet, MUSS Sign in with Apple (o. ä.) anbieten — wir bauen beide gleichzeitig. Supabase unterstützt beide nativ (`signInWithIdToken` mit Apple-/Google-ID-Token). Die App hat eine saubere Abstraktion: `lib/features/auth/domain/repositories/auth_repository.dart` + `supabase_auth_repository.dart` — Social Login wird dort ergänzt, Screens sprechen nur das Repository. Packages: `sign_in_with_apple`, `google_sign_in` (neu in pubspec).

**Lies zuerst:** `auth_repository.dart` + `supabase_auth_repository.dart`, `login_screen.dart`, `auth_provider.dart`, den Consent-Prüfpfad (`consent_provider.dart` — wann wird der Consent-Screen erzwungen?), Signup-Flow-Verhalten seit Commit `264e2f0` (E-Mail-Bestätigung), `ios/Runner/Runner.entitlements` (bewusst: T22 betrifft nur aps-environment; die neue `com.apple.developer.applesignin`-Entitlement-Ergänzung ist erlaubt und im Bericht zu dokumentieren).

**Founder-Vorarbeit (gated — Klick-Anleitungen im Abschlussbericht mitliefern, Reihenfolge egal zur Code-Arbeit):**
1. Apple Developer: App-ID `de.reflexjourney.app` (+ .dev/.staging) um Capability „Sign in with Apple“ ergänzen; Service-ID + Sign-in-Key (.p8) für Supabase erzeugen (Key-Datei NIE ins Repo/Chat).
2. Google Cloud Console: OAuth-Consent-Screen + iOS-Client-ID + Web-Client-ID (für Supabase).
3. Supabase Dashboard: Provider Apple + Google aktivieren, Secrets eintragen (Auth-Config-Änderung = gated, Founder-Go).

**Code-Aufgaben:**
1. Packages einbinden; iOS: Entitlement `com.apple.developer.applesignin` + Xcode-Capability (alle 3 Flavors); Android: google_sign_in-Konfiguration (Web-Client-ID via Konstante/env — Name dokumentieren, kein Secret).
2. `AuthRepository` um `signInWithApple()` / `signInWithGoogle()` erweitern (Supabase `signInWithIdToken`); Fehlerzweige: Nutzer-Abbruch (still), kein Netz (freundliche Meldung), Provider-Fehler.
3. Login-Screen: Apple-Button nach Apple-HIG (Paket-Widget `SignInWithAppleButton` oder HIG-konform), Google-Button nach Google-Branding; Reihenfolge Apple zuerst (iOS-Konvention); l10n DE+EN; Layout-Pass (kein gequetschter Screen — Founder-Auflage „keine hässlichen Lücken“ gilt).
4. Nach-Login-Pfad verifizieren: neue Social-Nutzer bekommen `profiles`-Zeile (Trigger/Upsert prüfen!), landen im Consent-Screen und Onboarding wie E-Mail-Nutzer; bestehende Router-Redirects funktionieren.
5. Edge Cases dokumentieren + testen soweit möglich: (a) gleiche E-Mail wie bestehender Passwort-Account → Supabase-Identity-Linking-Verhalten prüfen und im Bericht festhalten; (b) Apple „Hide My Email“-Relay-Adressen (Systememails via Resend funktionieren dorthin; interner Tester-Gate @reflexjourney.de unberührt); (c) **Konto-Löschung:** Apple verlangt bei SIWA-Apps mit Account-Löschung die Token-Revocation — prüfen, was Supabase beim `delete_user` macht, sonst Revocation ergänzen/als Folge-Task dokumentieren (Review-relevant!).
6. Tests: Repository-Abstraktion mockbar; Widget-Test Login-Screen (beide Buttons sichtbar, E-Mail-Flow unverändert); Suite grün via `make release-readiness-mobile`.
7. Doku-Nachträge: T05-Consent-Entwurf + `PRIVACY_LABELS_DRAFT.md` um den Hinweis „Anmeldung wahlweise über Apple/Google — dabei erhält der gewählte Anbieter die Anmeldedaten“ ergänzen; kurzer Nachtrag ins Anwalts-Briefing (Abschnitt 3, eine Zeile), falls noch nicht versendet.

**Akzeptanzkriterien:** Beide Buttons auf dem Login-Screen (Screenshot-Evidenz `docs/evidence/T26/`); E-Mail-Flow regressionfrei (Tests); Google-Login e2e im Dev-Build mit Wegwerf-Google-Konto verifiziert; Apple-Login e2e braucht echtes Gerät → als Founder-Checkpunkt in die nächste Gerätesitzung; Suite + Prod-Build grün.

**Nicht-Ziele/Verboten:** Keine Secrets/Client-IDs mit Secret-Charakter im Repo/Chat; E-Mail-Flow nicht umbauen; kein Facebook/sonstige Provider; Supabase-Config nur mit Founder-Go.

---

### T27 — Trainer-Werkzeug-Abo „Trainer Studio” *(Planning/Discovery; Build-Prompts vorbereitet)*

**Status:** ⏸ P0 Founder-Review offen. Verbindliche Artefakte:

- **Product-/UX-/Delivery-Spec:** `docs/superpowers/specs/2026-07-08-trainer-studio-design.md` — North Star, mobile UX-Blueprint, Freemium-Grenze, Daten-/Legal-/Store-Risiken, Research, Gates und Pilotmessung.
- **Planning-Prompt:** `docs/TRAINER_STUDIO_PROMPT.md` — P0 Founder-Review → P1 Problem-Interviews → P2 Low-Fi-Test → P3A Daten/Recht → P4A Free-MVP-Readiness; parallel P3B Store/Pricing → später P4B Paid-Readiness.
- **Vorbereitete Build-Prompts:** `docs/TRAINER_STUDIO_BUILD_PROMPTS.md` — T27.1–T27.6B vollständig formuliert; Existenz hebt P4A/P4B-/Legal-/Store-Gates nicht auf.
- **Gesamt-Orchestrator:** `docs/MONETIZATION_STUDIO_MASTER_PROMPT.md` — wählt nach Status genau den nächsten Payment-/Discovery-/Studio-Task.
- **Archivierte Vorarbeit:** `docs/TRAINER_TOOL_PLAN.md` — historische Stripe-/IAP-Überlegungen, nicht ausführen.

**Zweistufig:** Discovery → P4A → T27.1–T27.4 → T27.6A kostenloser, geschlossener MVP (3–5 Trainer, 6–8 Wochen, befristete interne Grants, keine Zahlungsdaten/Auto-Umwandlung). Parallel T25.1–T25.5. Erst nach Free-MVP-Auswertung + P4B folgt T27.6B mit Paywall und bezahltem Founding-Pilot. Gründerpreis bleibt bis Research/P3B/Storeprüfung Hypothese. `trainer_notes`/`mood_checkins` bereits vor Launch anwaltlich klären.

**Start:** Founder nutzt den „Startanweisung”-Block aus `docs/TRAINER_STUDIO_PROMPT.md`; bis P4A-GO gilt ausdrücklich „Planung, kein Studio-Code“.

---

## Änderungshistorie dieser Datei

- 2026-07-06: Erstanlage aus der Delta-Analyse 2026-07-05 (T01 dort bereits erledigt). T-Nummern entsprechen der Analyse; T01 ist als D1–D3-Entscheidungsblock aufgegangen.
- 2026-07-06 (später): Founder-Entscheidungen eingearbeitet — D1=A (Community/Feed verstecken), D2=A (Video verstecken), D3=B (Trainer-Discovery fertig bauen). T02/T03 entfallen; T04/T06 um verbindlichen UI-Lücken-Pass erweitert (Founder-Auflage: keine hässlichen Lücken); T13 zum vollwertigen „make it work“-Paket ausgebaut (Permission-UX, Empty-States, OSM-Attribution, Offline-Verhalten, Standort-Datenfluss-Doku); T05/T09/T10/T12 auf den Entscheidungsstand konkretisiert.
