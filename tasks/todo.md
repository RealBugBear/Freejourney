# T23 — Paywall-Grundstruktur, inaktiv hinter Flag (2026-07-07, D4)

Befunde aus der Lese-Phase:
- Trigger-Punkt existiert vorbereitet: `completion_questionnaire_screen.dart`
  `_continueAfterCelebration()` → Kommentar „Paid — go to packages screen
  (paywall coming later)“.
- Heutiges Verhalten: `freePackageIds = {moro, spinal_galant, tlr}` (3 frei);
  Pakete 4+ im UI gesperrt, Abschluss von Paket 3 endet heute auf dem
  Packages-Screen ohne Weiter-Weg (bekannte Sackgasse — Aktivierung der
  Paywall kommt lange bevor Launch-Nutzer dort ankommen: ≥ 12 Wochen).
- `packages_screen.dart` dupliziert Paketliste + Frei-Indizes → wird auf die
  zentrale Unlock-Logik umgestellt (Duplikat `_freePackageIndices` entfällt).
- ⚠️ Sicherheits-Erkenntnis: `profiles` ist durch Nutzer selbst updatebar —
  ohne DB-Schutz könnte sich ein Client `is_premium=true` setzen. Migration
  bekommt deshalb einen Trigger nach dem Muster von
  `prevent_direct_role_change` (2026041504).
- Semantik: Flag AUS → exakt heutiges Verhalten (3 frei, Rest gesperrt);
  Flag AN → nur `moro` frei (Design §3), Rest braucht Entitlement,
  Übergang/gesperrte Taps führen zur Paywall.

## Schritte

- [x] 1. Migration `2026070701_premium_entitlements.sql`: profiles-Felder
      (is_premium, premium_type inkl. 'code', premium_valid_until,
      stripe_customer_id) + `prevent_direct_premium_change`-Trigger;
      lokales Replay via `supabase db reset --local`; Live-Apply NICHT
      (gated, Founder-Go am Ende sammeln)
- [x] 2. `kPaywallEnabled = false` in launch_flags.dart
- [x] 3. Neues Feature `lib/features/premium/`: Entitlement-Modell +
      testbare `isPackageUnlocked(...)` (paywallEnabled als Parameter),
      PurchaseService (abstract + Stub), Produkt-Konstanten (eine Datei),
      PremiumRepository (profiles-Read + SharedPreferences-Cache),
      entitlementProvider
- [x] 4. l10n DE+EN (Paywall-Copy: ehrliche Dauer-Angabe, Jahr hervorgehoben,
      keine Druck-Mechaniken/Heilversprechen) + gen-l10n
- [x] 5. PaywallScreen (Trio B) + Route `/paywall` mit Gate-Redirect
      (Muster communityGateRedirect)
- [x] 6. Integration: completion-Übergang (pure Funktion
      `postCompletionRoute(...)` + Test), packages_screen auf zentrale
      Unlock-Logik (Flag aus = heutige 3 frei; Tap auf gesperrt → Paywall
      bei Flag an), defensiver Check im Trainingsstart
- [x] 7. Tests: Flag-false-Regression, Unlock-Matrix, Entitlement-Parsing,
      PaywallScreen-Widget-Test, postCompletionRoute
- [x] 8. Screenshots Paywall DE+EN (Harness) → docs/evidence/T23/
- [x] 9. `make release-readiness-mobile` + Prod-Build
- [x] 10. Tracker/Backlog/Commit; Founder-Go für Live-Migration sammeln

Nicht-Ziele: kein RevenueCat/IAP (T25), kein Live-DDL, kein Einzelpaket-Kauf,
keine Rechtstexte, Flag bleibt false.

---

# T26 — Anmeldung mit Apple & Google (2026-07-08)

## Schritte

- [ ] 1. Ist-Zustand lesen: Auth-Repository, Login-Screen, Auth-Provider,
      Consent/Onboarding-Weiterleitung, bestehende Entitlements/Build-Setup.
- [ ] 2. Dependencies/Platform vorbereiten: `sign_in_with_apple`,
      `google_sign_in`, iOS Entitlement + Android/Google Konfigurationspunkte
      (nur code-seitig, keine Secrets).
- [ ] 3. Auth-Schicht erweitern: neue Repository-Methoden
      `signInWithApple`/`signInWithGoogle`, Supabase-Integration, klare
      Fehlerpfade (Abbruch/Netz/Provider).
- [ ] 4. UI-Integration: Apple/Google-Buttons im Login (DE+EN), Layout ohne
      Lücken, E-Mail-Flow unverändert.
- [ ] 5. Consent/Onboarding-Pfad prüfen und anpassen, falls Social-Logins vom
      bestehenden Redirect-Pfad abweichen.
- [ ] 6. Tests ergänzen (Repository/Provider/UI) + vollständige Verifikation
      mit `make release-readiness-mobile` und relevantem Build-Check.
- [ ] 7. Tracker/Backlog evidenzbasiert updaten; founder-gated Klickschritte
      (Apple/Google/Supabase) als klare Liste im Abschluss.

---

# T24 — Freischalt-Codes für Gründungsnutzer (2026-07-08)

## Schritte

- [x] 1. Live-Schema `access_codes` read-only prüfen (Spalten, Constraints,
      RLS/Policies) und Evidence unter `docs/evidence/T24/` sichern.
- [x] 2. Migration für fehlende Felder erstellen (mind. `redeemed_by`,
      `redeemed_at`, `grants`) — idempotent, ohne Öffnung der RLS.
- [x] 3. Edge Function `redeem-access-code` bauen: JWT-Pflicht,
      server-seitige Validierung, atomare Einlösung, Entitlement-Update in
      `profiles` (`is_premium=true`, `premium_type='code'`, kein Ablauf).
- [x] 4. App-UI im Account-Bereich ergänzen: Code-Eingabe + Einlösen-Action,
      klare Erfolgs-/Fehlermeldungen, keine lokale Code-Validierung als
      Sicherheitsersatz.
- [x] 5. Tests zuerst ergänzen (Entitlement-/Repository-/UI-Pfade), dann
      Implementierung grün ziehen; anschließend relevante Verifikation
      (`flutter test`, `flutter analyze`, ggf. `make release-readiness-mobile`).
- [x] 6. Edge Function deployen (Founder-Go liegt vor), read-only Smoke-Check
      dokumentieren, Tracker/Backlog evidenzbasiert auf ✅ setzen.

---

# App-weite englische Lokalisierung + TestFlight (2026-07-14)

## Schritte

- [x] 1. Phase 0/1: Ausgangsarbeit getrennt sichern, Feature-Branch anlegen,
      Audit-Skript + Tracker erstellen und Architektur-/System-/DB-Befunde
      dokumentieren (Commits `178d4bc`, `f853d1f`, `c996e06`).
- [x] 2. Onboarding/First-Launch-Sprachwahl externalisieren und natürliches
      DE/EN-Glossar anlegen; Widget-Test ergänzen (Commit `0705c7c`).
- [x] 3. Dashboard vollständig externalisieren, ICU-Plurale und locale-aware
      Wochentage einsetzen; Suite grün (Commit `2abf16a`).
- [x] 4. Handoff bereinigt: Audit-Gate/Allowlist präzisiert, Regressionstests
      ergänzt und Tracker auf den realen Stand gebracht (Commit `4f8a1d5`;
      `make release-readiness-mobile`, 245/245 Tests).
- [x] 5. Auth-Handoff geprüft: keine unallowlisteten UI-/Fehler-Hardcodes;
      technische Repository-Meldungen bereits Englisch. Kein Code-Commit nötig.
- [ ] 6. Trainingskern vollständig externalisiert/übersetzt (106 Keys, 5 neue
      DE/EN-Widgettests, Audit 0); Packages und verbleibende Locale-Fallbacks
      sind offen (Training-Commit `96db5e8`). EN-Announcement-MP3s fehlen und
      sind als Asset-Blocker erfasst.
- [ ] 7. Journal, Progress und Golden Day externalisieren/übersetzen; Tests
      und eigener Commit.
- [ ] 8. Reflexprofil/Assessment: tatsächliche 123 Fragen (109 + 14 Demo),
      Module/Hilfen/Trainer-Flags und Reflexlabels nach bilingualem Content-
      Muster umgesetzt und getestet; allgemeine UI sowie PDF-Ausgabe offen.
- [ ] 9. Begleitung, Mood, Settings, Profil und Trainer-Discovery vollständig
      externalisieren/übersetzen; Tests in kleinen Feature-Commits.
- [ ] 10. Chat, Trainer-Flows und launch-versteckte Community/Experience/Video-
      Flächen externalisieren; Logs Englisch; Tests in Feature-Commits.
- [ ] 11. Admin, Dev-Tools und Core-Ränder (Router, Onboarding-Hints, Bootstrap,
      DB-/Sync-/Fehlerpfade) externalisieren; technische Logs Englisch.
- [ ] 12. Systemebene: `profiles.locale`-Sync und iOS InfoPlist.strings de/en
      lokal umgesetzt; Android-Systemressourcen geprüft/invariant. Serverseitige
      Push-Copy ist locale-aware vorbereitet und getestet, aber nicht deployt.
      Client-Push sowie verbleibende Datum-/Zahlformate sind offen; Deploy/Live-
      Änderungen nur nach Founder-Go.
- [ ] 13. Dauerhafte Gates: ARB-Key-/Placeholder-Parität, Leerwerte und
      EN-Umlautprüfung sowie Glossar/en-US/Claim/DE==EN-Qualität sind als
      `make i18n-check` in Release-Readiness aktiv; Hardcode-Audit erst bei
      Endstand 0 aktivieren.
- [ ] 14. EN-Qualitätssweep (en-US, Glossar, DE==EN-Entscheidungen,
      Heilversprechen-Check) und offene Recht/DB/Bild/Store-Punkte flaggen.
- [ ] 15. Visuelle EN-Evidenz für beide Sprachwechsel-Wege und alle
      Haupt-Screens erzeugen; Layout/Overflow prüfen.
- [ ] 16. `make release-readiness-mobile`, Prod-Build ohne Codesign und
      Abschlussreport/Tracker finalisieren. Signierte IPA/Upload bleiben ein
      separater gated Release-Schritt und sind nicht Teil des i18n-Prompts.
