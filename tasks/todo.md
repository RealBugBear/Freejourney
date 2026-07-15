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

- [ ] 1. Bestehende DE/EN-ARB-Dateien, First-Launch-Sprachauswahl und alle
      nutzerseitigen Hardcodes vollständig auditieren; bestehende Dirty-Diffs
      getrennt halten.
- [ ] 2. Sprachauswahl vor Login vollständig lokalisieren und den gespeicherten
      Wechsel zu Englisch per Widget-/Provider-Test absichern.
- [ ] 3. Alle launch-relevanten Nutzer-, Trainer- und gemeinsamen Flows auf
      `AppLocalizations` umstellen; natürliche DE/EN-Texte ergänzen und
      generierte Lokalisierungen neu erzeugen.
- [ ] 4. Statische Prüfungen für ARB-Key-Parität und verbleibende deutsche
      UI-Hardcodes ergänzen; gezielte UI-Tests und vollständige Mobile-Suite
      ausführen.
- [ ] 5. Produktions-Build ohne Codesign prüfen, Buildnummer verpflichtend
      erhöhen, signierte IPA erstellen und Inhalt/Signatur validieren.
- [ ] 6. Mit dem im Nutzerauftrag enthaltenen Store-Upload-Go die validierte
      IPA zu App Store Connect/TestFlight hochladen und Apples Ergebnis
      dokumentieren.
