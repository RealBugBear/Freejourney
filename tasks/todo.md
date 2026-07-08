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
