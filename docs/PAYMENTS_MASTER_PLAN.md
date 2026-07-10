# Payments Master Plan — alle Strukturen, Apple + Android

**Stand:** 2026-07-10 · **Anlass:** Founder-Anfrage 2026-07-10 („fully flesh out
payment on all my structures as well as all devices apple and android")
**Verwandt:** `docs/MONETARISIERUNG_EVALUATION.md` (Entscheidungen D4/D5) ·
`docs/superpowers/specs/2026-05-28-monetization-design.md` (Datenmodell, teilverworfen) ·
`docs/superpowers/specs/2026-07-08-trainer-studio-design.md` (Studio) ·
`docs/TRAINER_STUDIO_BUILD_PROMPTS.md` (Studio-Build-Prompts)

Dieses Dokument bündelt ALLE Zahlungsstrukturen der App auf BEIDEN Plattformen
in einen ausführbaren Plan. Es erfindet keine neuen Geschäftsentscheidungen:
D4 (Trio, Struktur vor Aktivierung), D5 (keine Session-Provision) und
„ein Bezahlsystem: Store-IAP via RevenueCat" (2026-07-08) gelten unverändert.
Store-/Preis-/Rechtsaussagen sind Hypothesen und werden bei Ausführung gegen
aktuelle Primärquellen geprüft (Standing Rule).

---

## 1. Zahlungs-Inventar — was es gibt, was fehlt

| Struktur | Zweck | iOS | Android | Server |
|---|---|---|---|---|
| **Nutzer-Premium** (Trio B: Monat 12,99 € / Jahr 89,99 € ★ / Lifetime 149 €) | Zugang Paket 2+ | T23 ✅ UI+Modell, T25 ⛔ IAP fehlt | ❌ komplett offen | ✅ `profiles`-Entitlement + Schutz-Trigger live |
| **Freischalt-Codes** (Gründungsnutzer) | Premium per Code, ohne Kauf | ✅ T24 live | ✅ T24 live (plattformneutral) | ✅ `access_codes` + RPC + Edge Function |
| **Trainer Studio** (Abo 14,99 €/Monat / 119,99 €/Jahr, Hypothese) | Trainer-Werkzeuge | ⏸ T27 Planung | ⏸ T27 Planung | ❌ Entitlement fehlt (T27.1) |
| ~~Session-Provision~~ | — | — | — | **gestrichen (D5)** — Trainer↔Klient rechnen direkt ab |

Erkenntnis aus der Bestandsaufnahme: **Android ist in allen bisherigen
Payment-Dokumenten ein blinder Fleck.** Die App baut und läuft auf Android
(Flavors, Bundle-IDs, Asset Links ✅), aber es existiert kein Play-Console-Konto,
kein Play-Billing-Plan und keine Android-Zeile in der Monetarisierungs-Evaluation.
Dieser Plan schließt die Lücke.

## 2. Ziel-Architektur — ein Muster für alles

**RevenueCat ist die einzige Kauf-Schicht, für beide Plattformen und beide
Abo-Strukturen (Premium + Studio).** Begründung:

- Ein SDK (`purchases_flutter`), ein Entitlement-Modell, eine Webhook-Quelle —
  statt StoreKit- und Play-Billing-Sonderwege.
- Cross-Plattform von Haus aus: Kauf auf dem iPhone, Nutzung auf dem
  Android-Gerät desselben Kontos funktioniert, weil RevenueCat Entitlements am
  App-User-ID (= Supabase-UID) führt, nicht am Gerät.
- Der T23-`PurchaseService` wurde genau dafür als abstrakte Schnittstelle
  gebaut — die Paywall-UI und ihre Tests bleiben unverändert.

```text
                 ┌────────────── App Store (IAP) ─────────────┐
Nutzer/Trainer → │                                            │
                 └────────────── Play Store (Billing) ────────┘
                                   │ Käufe
                                   ▼
                             RevenueCat
                    Entitlements: `premium` · `studio`
                    appUserID = Supabase auth.uid
                       │                        │
         CustomerInfo (SDK, sofort)     Webhook (signiert)
                       ▼                        ▼
                 Flutter-App          Edge Function `revenuecat-webhook`
                 (optimistisches            (service_role)
                  Freischalten)               │
                                              ▼
                                   profiles.is_premium/… (Nutzer)
                                   trainer_profiles.studio_… (Trainer, T27.1)
```

**Verbindliche Regeln (aus dem Bestand abgeleitet):**

1. **Server bleibt Quelle der Wahrheit.** `profiles.is_premium` &
   `trainer_profiles.studio_*` werden ausschließlich per service_role gesetzt
   (Schutz-Trigger existieren bzw. werden gespiegelt). Das SDK-CustomerInfo
   dient nur dem sofortigen Freischalten nach Kauf, bis der Webhook greift.
2. **Der Webhook darf Code-Entitlements nie zerstören.** `premium_type='code'`
   (T24) und `'lifetime'` werden von EXPIRATION/CANCELLATION-Events nicht
   angefasst. Sonderfall: Code-Nutzer kauft zusätzlich ein Abo und lässt es
   auslaufen → beim Ablauf wird gegen `access_codes.redeemed_by` re-derived
   und ggf. `premium_type='code'` wiederhergestellt statt `is_premium=false`.
3. **Preise kommen zur Laufzeit aus dem Store** (lokalisiert, inkl.
   Trial-Berechtigung). `paywall_products.dart` liefert nach T25 nur noch
   Identität + Reihenfolge — steht dort schon so im Doc-Kommentar.
4. **Ein Abo deckt alle Profile des Kontos** (Kinderprofile) — kein
   Pro-Profil-Kauf, keine Änderung nötig.
5. **Idempotenz:** verarbeitete RevenueCat-Event-IDs werden in einer kleinen
   Tabelle protokolliert; doppelte Zustellung ist ein No-op.
6. `profiles.stripe_customer_id` ist toter Bestand (Stripe komplett
   gestrichen). Bleibt stehen (harmlos, Migration live), wird nirgends gelesen.

## 3. Produkte & Preise (beide Stores)

| Produkt | Typ | iOS (Vorschlag) | Android (Vorschlag) | Entitlement |
|---|---|---|---|---|
| Premium Monat 12,99 € | Auto-renewable, Gruppe „premium" | `rj_premium_monthly` | `rj-premium-monthly` | `premium` |
| Premium Jahr 89,99 € ★ | Auto-renewable, Gruppe „premium" | `rj_premium_yearly` | `rj-premium-yearly` | `premium` |
| Premium Lifetime 149 € | Non-consumable / einmalig | `rj_premium_lifetime` | `rj-premium-lifetime` | `premium` |
| Studio Monat 14,99 € (Hypothese TS-10) | Auto-renewable, **eigene Gruppe „studio"** | `rj_studio_monthly` | `rj-studio-monthly` | `studio` |
| Studio Jahr 119,99 € (Hypothese TS-10) | Auto-renewable, Gruppe „studio" | `rj_studio_yearly` | `rj-studio-yearly` | `studio` |

- **Getrennte Subscription-Gruppen** für Premium und Studio sind Pflicht:
  sonst behandelt Apple einen Wechsel Nutzer-Abo↔Studio-Abo als Up-/Downgrade
  innerhalb einer Gruppe.
- Produktnamen können in Store-/Abo-Oberflächen sichtbar werden — neutral
  benennen („Reflex Journey Premium — Jahr"), keine internen Codenamen.
- Kein Einzelpaket-Produkt (D4). Wochenabo bleibt unverbaut.

## 4. Founder-Setup — der externe kritische Pfad

Alles Code-seitige ist von genau diesen Konten/Records blockiert. Reihenfolge
und realistische Dauer:

### 4.1 Apple (entsperrt T25.1) — ~30–45 Min. Founder-Zeit

1. **ASC-App-Record anlegen (= offene Empfehlung R4)** — Bundle-ID
   `de.reflexjourney.app` ist seit 2026-07-03 registriert, nur der Record fehlt.
   Gemeinsame Browser-Sitzung wie in R4 beschrieben.
2. **Small Business Program beantragen** (15 % statt 30 %) — direkt nach
   Record-Anlage, Wirkung ab Folgemonat der Genehmigung.
3. IAP-Produkte (3× Premium) in ASC anlegen — kann Claude in gemeinsamer
   Sitzung vorbereiten; Freigabe je Produkt durch Apple-Review beim ersten
   App-Review mit IAP.
4. **Banking/Tax/Verträge in ASC ausfüllen** („Agreements, Tax, Banking") —
   ohne unterschriebenen Paid-Apps-Vertrag keine IAP-Tests.

### 4.2 RevenueCat (entsperrt T25.1–T25.2) — ~20 Min. Founder-Zeit

1. Konto anlegen (Founder-E-Mail), Projekt „Reflex Journey".
2. iOS-App mit ASC-App-Specific-Shared-Secret bzw. In-App-Purchase-Key
   verbinden; später Android-App mit Play-Service-Credentials.
3. Entitlement `premium` + Offering `default` mit den 3 Produkten anlegen.
4. Webhook-URL + Authorization-Secret konfigurieren (Wert kommt aus T25.2;
   Secret landet in Supabase Secrets, nie im Repo).
5. Kostenmodell notieren: RevenueCat ist bis zu einer Umsatzschwelle
   kostenlos (Schwelle bei Ausführung auf revenuecat.com/pricing verifizieren
   — ändert sich; für die Startgrößenordnung hier ist „kostenlos" die
   realistische Annahme).

### 4.3 Google (entsperrt T25.3) — ~1–2 h Founder-Zeit + Wartezeit

1. **Play-Console-Entwicklerkonto anlegen** (25 $ einmalig).
   **Empfehlung: als Organisation (Kleingewerbe) registrieren, nicht als
   Privatperson** — für private Neukonten verlangt Google vor dem
   Produktions-Release einen geschlossenen Test mit ~12 Testern über 14 Tage;
   Organisationskonten sind davon ausgenommen (Regel bei Anmeldung
   verifizieren). Identitäts-/Gewerbe-Verifikation kann mehrere Tage dauern
   → **früh starten, auch wenn Android nach iOS launcht.**
2. App-Record `de.reflexjourney.app` anlegen; Data-Safety-Formular aus
   `docs/PRIVACY_LABELS_DRAFT.md` befüllen (+ RevenueCat als Verarbeiter —
   Nachtrag ist im T25-Prompt verankert).
3. **15-%-Gebührenstufe aktivieren** (Play Media Experience/Service-Fee-
   Programm für Umsatz bis 1 Mio $ — Anmeldung in der Console nötig, nicht
   automatisch).
4. Abo-Produkte + Lifetime anlegen; Lizenz-Tester für Testkäufe eintragen;
   Internal-Testing-Track als Sandbox.
5. Google-Cloud-Service-Account für RevenueCat erzeugen und in RevenueCat
   hinterlegen (RevenueCat-Doku-Schritte, bei Ausführung prüfen).

## 5. Build-Prompts T25.1–T25.4

Hausregeln gelten für jeden Prompt: CLAUDE.md lesen; Arbeit hinter
`kPaywallEnabled=false` (Flag-aus = heutiges Verhalten, per Test belegt);
keine Live-DDL/Deploys ohne Founder-Go; `make release-readiness-mobile` grün;
DE+EN l10n; Evidenz nach `docs/evidence/T25/`.

### T25.1 — RevenueCat-SDK + iOS-Kaufweg *(Gate: ASC-Record + Produkte + RC-Konto)*

**Rolle:** Flutter-Entwickler:in mit IAP-Erfahrung.
**Lies zuerst:** `lib/features/premium/` komplett, `docs/MONETARISIERUNG_EVALUATION.md` §4, diesen Plan §2–3.
**Scope:**
1. `purchases_flutter` einbinden (iOS-Mindestversionen prüfen; Podfile).
2. `RevenueCatPurchaseService implements PurchaseService` — Kauf, Restore,
   Fehler-Mapping auf `PurchaseOutcome`; Stub bleibt für Tests/Dev-Flavor
   ohne RC-Keys.
3. Identität: `Purchases.logIn(supabaseUid)` nach Sign-in,
   `Purchases.logOut()` bei Sign-out (Bootstrap-/Auth-Provider-Anbindung).
4. Paywall zeigt lokalisierten Store-Preis + Intro-/Trial-Status aus dem
   Offering; `paywall_products.dart` nur noch Identität/Reihenfolge/Fallback.
5. Optimistisches Freischalten: nach `success` CustomerInfo-Entitlement
   lokal respektieren, bis Server-Profil nachzieht (fail-closed bleibt).
**Akzeptanz:** Sandbox-Kauf aller 3 Produkte + Restore auf physischem Gerät
belegt (redigierte Screenshots); Flag-aus-Regression; API-Keys via
`--dart-define`/Env, nie im Repo; Suite grün.
**Nicht-Ziele:** kein Webhook (T25.2), kein Android (T25.3), keine Aktivierung.

### T25.2 — Server-Entitlement-Sync (Webhook) *(Gate: RC-Konto; Deploy = Founder-Go)*

**Rolle:** Supabase-/Deno-Entwickler:in.
**Lies zuerst:** `supabase/migrations/2026070701_premium_entitlements.sql`,
`2026070802_access_codes_redeem.sql`, Cron-Secret-Muster bestehender Functions.
**Scope:**
1. Migration: Tabelle `revenuecat_events` (event_id PK, processed_at) für
   Idempotenz; lokal replay-grün.
2. Edge Function `revenuecat-webhook`: Authorization-Header gegen Secret
   (fail-closed wenn unkonfiguriert); Events mindestens
   INITIAL_PURCHASE/RENEWAL/UNCANCELLATION/PRODUCT_CHANGE (→ setzen),
   CANCELLATION (No-op bis Ablauf), BILLING_ISSUE (No-op + Log; Grace
   respektieren), EXPIRATION (→ löschen, mit Code-/Lifetime-Schutz und
   `access_codes`-Re-Derivation nach §2 Regel 2), TRANSFER; unbekannte
   Events: loggen + 200.
3. Entitlement-Mapping tabellengetrieben: `premium` → `profiles`,
   `studio` → `trainer_profiles` (Spalten kommen mit T27.1; bis dahin
   sauber ignorieren + loggen).
4. Kein PII-Logging (Event-Typ + gekürzte IDs, nie E-Mail/Empfänger).
**Akzeptanz:** Unit-/Integrationstests der Event-Verarbeitung inkl.
Code-Schutz-Fällen; `deno check`; unauth Smoke → 401/403; Live-Deploy nur
per Founder-Go mit Evidenz wie T24.
**Nicht-Ziele:** keine Client-Änderungen; kein Studio-Schema.

### T25.3 — Android: Play Billing über dieselbe Schicht *(Gate: Play-Konto + Produkte + RC-Play-App)*

**Rolle:** Flutter-/Android-Entwickler:in.
**Lies zuerst:** T25.1-Ergebnis, `android/app/build.gradle*` (Flavors!),
Mistake #1 (Stale-APK — nur `make run-android`).
**Scope:**
1. RC-Android-Konfiguration (Play-API-Key via Env je Flavor); gleiche
   `RevenueCatPurchaseService`-Implementierung, keine Fork-Logik.
2. Billing-Permission/Manifest prüfen; ProGuard/R8-Regeln falls nötig.
3. Paywall-UI auf Android verifizieren (Preisformatierung, Back-Verhalten,
   Dark Mode, 150 % Schrift).
4. Play-Data-Safety-Delta dokumentieren (RevenueCat als Verarbeiter,
   Käufe-Datenkategorie) → Nachtrag zu `docs/PRIVACY_LABELS_DRAFT.md`.
**Akzeptanz:** Testkauf + Restore mit Lizenz-Tester auf physischem
Android-Gerät belegt; Kauf auf iOS → Entitlement auf Android desselben
Kontos sichtbar (Cross-Plattform-Beleg); Flag-aus-Regression beide
Plattformen; Suite grün.
**Nicht-Ziele:** kein Play-Store-Listing/Release (eigener Launch-Track).

### T25.4 — E2E-Evidenz + Review-Unterlagen *(Gate: T25.1–T25.3)*

**Scope:** Sandbox-E2E beider Plattformen dokumentieren (Kauf, Restore,
Kündigung→Ablauf, Billing-Retry soweit simulierbar); App-Review-Notes für
IAP (Demo-Konto, Paywall-Fundort, „Aktivierung per Flag" erklären);
`docs/RELEASE_READINESS_CHECKLIST.md` um IAP-Zeilen ergänzen.
**Akzeptanz:** Evidenz-Ordner vollständig; Tracker/Backlog fortgeschrieben.

## 6. Aktivierung (bleibt eigener Founder-Go, unverändert R8)

Aktiviert wird erst wenn ALLE erfüllt: Launch stabil + Nutzer erreichen
Paket 2 (R8-Trigger) · AGB/Widerruf vom Anwalt (Baustein 8) · T25.4-Evidenz ·
Bestandsschutz kommuniziert. **Vorformulierte Bestandsschutz-Formel zur
Freigabe (R8):**

> „Wer sich vor Aktivierung der Paywall registriert hat, behält Paket 1
> dauerhaft kostenlos — daran ändert sich nichts. Gründungsnutzer-Codes
> gelten unverändert weiter."

Aktivierungsschritte: `kPaywallEnabled=true` → Prod-Build → Store-Review
(beide Stores) → Release. Kill Switch = Flag zurück + Store-Update (Käufe
bleiben gültig; Entitlements bleiben serverseitig bestehen).

## 7. Kostenbild (ehrlich, je getrennt ausgewiesen)

| Posten | iOS | Android |
|---|---|---|
| Store-Provision | 15 % (Small Business Program, beantragen!) | 15 % (Stufe aktivieren!) |
| USt | Apple ist Händler → führt EU-USt ab | Google desgl. |
| RevenueCat | voraussichtlich 0 € zum Start (Schwelle verifizieren) | dito |
| Fixkosten | Apple Developer 99 €/Jahr (läuft) | Play Console 25 $ einmalig |
| § 19 UStG / Auszahlungs-Verbuchung | → Steuerberater (offen, wie in Eval §Offene) | dito |

Keine „15 % vs. 4 %"-Vergleiche mehr — Stripe ist vollständig gestrichen.

## 8. Offene Founder-Entscheidungen aus DIESEM Plan

| ID | Entscheidung | Empfehlung | Fällig |
|---|---|---|---|
| PM-1 | Play-Konto: Organisation (Kleingewerbe) vs. privat | **Organisation** (kein 12-Tester-Gate, seriöser Auftritt) | vor T25.3, früh wegen Verifikationsdauer |
| PM-2 | Android-Nutzer-Abo: gleicher Launch wie iOS oder Fast-Follow? | **Fast-Follow** (iOS-Launch nicht an Play-Verifikation ketten; Code ist ab T25.3 identisch) | vor Launch-Kommunikation |
| PM-3 | R8-Bestandsschutz-Wortlaut (Entwurf oben) | Entwurf freigeben | vor erster Launch-Kommunikation |
| PM-4 | Termin für gemeinsame ASC-Sitzung (R4 + Produkte + SBP) | sofort terminieren — Wurzel-Blocker von allem | jetzt |

Studio-spezifische Entscheidungen (TS-6/TS-7/TS-10) stehen mit Empfehlungen
in `docs/TRAINER_STUDIO_BUILD_PROMPTS.md`.
