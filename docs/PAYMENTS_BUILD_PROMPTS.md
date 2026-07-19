# Payments — kopierfertige Build-Prompts T25.0–T25.5

**Stand:** 2026-07-19
**Architektur:** `docs/PAYMENTS_MASTER_PLAN.md`
**Orchestrator:** `docs/MONETIZATION_STUDIO_MASTER_PROMPT.md`

PM-D1–PM-D12 wurden am 2026-07-19 wie empfohlen freigegeben. T25.0 ist lokal
abgeschlossen (`docs/evidence/T25.0/README.md`); T25.1 ist der nächste Payment-
Task, bleibt aber bis zum RevenueCat-Projekt X3 blockiert. T25.2–T25.5 warten
weiter auf ihre jeweiligen Gates. Eine Session pro Task. Jede Live-/Storeaktion
bleibt separat Founder-gated.

## T25.0 — Multi-Grant-Entitlement-Fundament

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Task: T25.0 — Multi-Grant-Entitlement-Fundament. Lies CLAUDE.md,
docs/LAUNCH_MASTER_PROMPT.md, docs/PAYMENTS_MASTER_PLAN.md §0–§6/§10–§12,
Migrationen 2026070701 und 2026070802, Premium-Modell/Repository/Tests und den
Masterstatus. Verifiziere PM-D1–PM-D12-Founder-Go; sonst NO-GO ohne Änderungen.
Bei PM-D12-GO ergänze CLAUDE.md §4 und den launch_flags.dart-Kommentar um die
genehmigte, eng begrenzte Rollout-Ausnahme.

Erstelle additive Migrationen für entitlement_grants, benefit_campaigns,
HMAC-basierte benefit_codes, benefit_redemptions sowie getrennten sales_rollout
und feature_rollout gemäß Masterplan. Clients dürfen nichts schreiben.
Implementiere eine
serverseitige effektive-Entitlement-Funktion und eine transaktionale
Legacy-Projektion auf profiles.is_premium/premium_type/premium_valid_until.
Mehrere Grants müssen koexistieren; Ablauf/Widerruf eines Grants darf andere
nicht berühren. Backfill bestehende T24-Codeeinlösungen und vorhandene
premium_type='code'-Profile idempotent, ohne bestehende Zugänge zu verlieren.
Definiere klare Priorität nur für die Legacy-Anzeige, nicht als Löschlogik.
Unterstütze single-/multi-use Campaignlimits, Rolle/Entitlement, permanent,
duration/fixed-end, atomare Redemption und Campaign-Revoke ohne rückwirkenden
Grant-Entzug. Ein Store-Rabattcode speichert nur Offer-Referenzen und setzt
keinen internen Kaufpreis.

Evolviere den bestehenden redeem-access-code-Serverweg kompatibel auf Benefit-
Codes: alte Founder-Codes bleiben gültig, neue Codes werden per keyed HMAC
gefunden, Response nennt Entitlement/Enddatum neutral. Die vorhandene
Einlöse-UI wird rollenbewusst für Premium und Studio, zeigt bei internem Grant
klar „kein Abo/keine automatische Belastung“. Store-Rabattkampagnen starten
stattdessen den plattformspezifischen Offer-Flow.

Ergänze Repository/Domain so, dass effektiver Status und Grant-Ursprung
darstellbar sind, der heutige T23-Flow aber kompatibel bleibt. Offlinecache darf
nicht über expires_at hinaus gelten und ist keine Server-Sicherheitsgrenze.

Pflichttests: Code allein; Storegrant allein; Code+abgelaufener Storegrant;
Lifetime+Refund eines anderen Grants; Premium+Studio; abgelaufener Reviewgrant;
Client-Schreibversuch; Backfill zweimal; Sales-/Feature-Rollout; Migration
lokaler Full Replay. sales_rollout=off darf gültigen Zugang nicht entziehen;
incident_disabled ist ein separater Pfad. Kein RevenueCat-SDK/Webhook, keine
UI, kein Live-Apply ohne separates Founder-Go. Evidenz T25.0.
```

## T25.1 — RevenueCat Core + Test Store

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Task: T25.1 — RevenueCat Core + Test Store. Lies CLAUDE.md,
docs/LAUNCH_MASTER_PROMPT.md, Payments Master Plan §5/§7/§10–§11,
T25.0-Ergebnis, PurchaseService/Paywall und aktuelle offizielle RevenueCat-
Flutter-Doku. Verifiziere T25.0 und ein Founder-eingerichtetes RevenueCat-
Projekt/Test Store.

Integriere die aktuell kompatible purchases_flutter-Version. Die App verlangt
Login: SDK nur mit Supabase auth.uid konfigurieren, keine anonymen Käufe. Beim
App-Logout NICHT Purchases.logOut aufrufen; Kauf-UI sperren, bei nächstem
Account direkt logIn(neueUid) und CustomerInfo des alten Accounts nie anzeigen.
Keys je Plattform/Flavor aus Secret-/Build-Konfiguration, nie im Repo.

Erweitere PurchaseService um Offerings, lokalisierte StoreProduct-Daten,
Trial/Intro-Eligibility, Kauf, Restore, Manage-Subscription-Ziel und
CustomerInfo-Refresh sowie plattformneutrale Offer-Referenzen. Produktidentität/Reihenfolge ist lokal; Preis/Trial kommt
vom Store. T23-Paywall nutzt den Service und zeigt loading/offline/error/pending.
Nach Kauf: UI-Erfolg aus CustomerInfo, Backend-Projektion pollen; keinen
servergeschützten Zugriff clientseitig umgehen.

Nutze RevenueCat Test Store für Monat/Jahr/Lifetime sowie studio month/year,
ohne echte ASC-/Play-Produkte. Tests: init erst nach Auth, Account A→B,
ausgeloggt, offering fehlt, eligibility, cancel, pending, error, restore,
CustomerInfo anderer Account, Flag/Rollout aus. Suite + beide Plattformbuilds.
Keine echten Store-/Webhook-Schritte. Evidenz T25.1.
```

## T25.2 — Webhook, HMAC und Reconciliation

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Task: T25.2 — RevenueCat Webhook + Reconciliation. Lies CLAUDE.md,
docs/LAUNCH_MASTER_PROMPT.md, Payments Master Plan §3–§6/§10,
T25.0/T25.1-Evidenz, bestehende Edge-Function-Secret-/Cron-Muster und aktuelle
RevenueCat Webhook/Event/REST-Doku. Verifiziere T25.0/T25.1.

Migration: revenuecat_events als minimale idempotente Inbox mit Event-ID,
Environment, Typ, Status, Versuchen, Zeitstempeln, redigiertem Fehler; kein
voller PII-Payload. Edge Function prüft Authorization UND HMAC über Raw Body,
fail-closed bei fehlender Konfiguration, Größenlimit und Basisvalidierung.

Behandle Event nicht als geordnete Delta-Wahrheit. Bestimme betroffene App User
IDs/Aliases/Transferseiten, hole aktuellen Customer-/Entitlement-Status über
serverseitige RevenueCat-API und upserte revenuecat-Grants transaktional.
Recompute effektive Entitlements/Legacy-Projektion. Unterstütze premium und
studio, Store/Product/Expiry/Grace. CANCELLATION entzieht nicht; Billing Issue
nur entsprechend aktuellem Status; Transfer reconciled alt+neu; unbekannte
Events future-proof speichern/alerten. Temporärer Fehler non-2xx für Retry,
Duplikat No-op. Ergänze einen idempotenten täglichen Repair-Reconcile für
kürzlich aktive Storekunden.

Tests mit signierten Fixtures: falscher Auth/HMAC, duplicate, out-of-order,
initial/renew/cancel/expire/grace/recover/refund/non-renewing/transfer/unknown,
Code+Store-Ablauf, Lifetime+altes Event, Sandbox≠Production. Keine E-Mail/PII-
Logs. deno check, lokaler Replay. Deploy/Secrets/Cron live nur nach einzelnem
Founder-Go; danach unauth/wrong-HMAC Smoke + redigierte Evidenz T25.2.
```

## T25.3 — Apple IAP, iPhone + iPad

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Task: T25.3 — Apple IAP Production Wiring. Lies CLAUDE.md,
docs/LAUNCH_MASTER_PROMPT.md, Payments Master Plan §2/§7–§10,
T25.1/T25.2 und aktuelle Apple-/RevenueCat-Primärdoku. Gate: ASC App Record,
Paid Apps Agreement/Tax/Banking, RevenueCat-Appverbindung und Founder-Go für
jede Portalmutation.

Erstelle zuerst eine exakte Founder-Klickcheckliste. Founder legt Produkte an:
Premium month/year in einer Subscription Group, Lifetime non-consumable,
Family Sharing AUS; Studio noch nur wenn T27.6B fällig. Nutze aktuelle IAP-Key-
Verbindung statt veraltete Shared-Secret-Annahmen. Produkt-IDs erst nach Review
fixieren und im Katalogmapping dokumentieren. Billing Grace Period bewusst
konfigurieren/testen; Empfehlung 16 Tage paid-to-paid bleibt Founder-Entscheid.

Verkabele Production Offering und teste auf physischem iPhone und iPad bzw.
begründetem iPad-Simulator+StoreKit nur ergänzend: month/year/lifetime,
localized price, purchase/cancel/pending/restore, month↔year, cancellation until
expiry, grace/recovery, refund/revocation soweit Sandbox zulässt,
Neuinstallation, zwei App-Accounts/Restore-Transfer, aktives Abo versteckt
Lifetime. Implementiere/teste Apple Subscription Offer Codes für befristete
Freunde-/Familienrabatte (neue/aktive/abgelaufene Eligibility je Kampagne);
interne Freizugangscodes bleiben der eigene Benefit-Flow. App Review
Notes/Demo/Terms/Privacy/Restore/Manage Subscription.

Keine Paywall-Aktivierung. Suite, Prod-Build, redigierte Evidenz T25.3.
```

## T25.4 — Google Play Billing, Phone + Tablet

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Task: T25.4 — Google Play Billing Production Wiring. Lies CLAUDE.md,
docs/LAUNCH_MASTER_PROMPT.md, Payments Master Plan §2/§7–§10,
T25.1/T25.2 und aktuelle Google-/RevenueCat-Primärdoku. Gate: ehrlicher
Accounttyp (Organisation nur mit realer Business-/D-U-N-S-Verifikation, sonst
Personal samt Testgate), Play App/Payments und Founder-Go für Portalmutationen.

Founder-Klickcheckliste zuerst. Lege Premium als Subscription rj_premium mit
monthly/yearly Base Plans an, Lifetime als One-time Product; Studio erst in
T27.6B. RevenueCat-Import referenziert Subscription+Base-Plan-ID. Richte
Service-Account/API-Zugriff, License Tester, Internal/Closed Track ein. Prüfe
Data Safety und aktuelle Gebühren/Programme; kein Media-Experience-Programm als
Standardweg behaupten.

Teste auf physischem Android Phone und Tablet/geeignetem Tablet-Emulator mit
Play Store: month/year/lifetime, localized price, pending/cancel/restore,
Planwechsel Replacement Mode, cancel until expiry, grace/recovery,
pause/resume, refund/revoke, Neuinstallation, zwei App-Accounts/Transfer.
Cross-Platform: Apple-Kauf auf Android aktiv und Play-Kauf auf iOS aktiv; auf
zweitem Store kein Doppelkaufbutton. Aktives Abo bietet Lifetime nicht an.
Implementiere/teste Google Base-Plan-Offers bzw. Promo Codes für befristete
Freunde-/Familienrabatte; Eligibility/Offer-Tags explizit auswählen, damit
RevenueCat nicht versehentlich irgendein Developer-Determined Offer automatisch
anwendet. Interne Freizugangscodes bleiben plattformunabhängig.

Keine Paywall-Aktivierung. Suite/APK-AAB-Prod-Build, redigierte Evidenz T25.4.
```

## T25.5 — Operations und Aktivierungs-Readiness

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Task: T25.5 — Payment Operations + Activation Readiness. Lies CLAUDE.md,
docs/LAUNCH_MASTER_PROMPT.md, Payments Master Plan vollständig und Evidenz
T25.0–T25.4. Gate: alle vier Tasks belegt; sonst NO-GO mit exakter Lücke.

Führe die vollständige Pflicht-Testmatrix des Masterplans aus und erstelle
Runbooks für: Refund/Revocation, Billing Issue/Grace, Planwechsel,
Cross-Store-Doppelkauf, Restore/Transfer, Accountlöschung (Store vs Code),
Ersatz-Founder-Code, verlorenen Webhook/Repair-Reconcile, Secretrotation,
Store-/RevenueCat-Ausfall, Support-Eskalation. Definiere Monitoring ohne PII:
Webhook backlog/failures, reconcile age, Projektionsabweichung und Kauf-
Aktivierungsdauer. Teste getrennten sales_rollout und feature_rollout; Verkauf
stoppen darf Grants oder gültigen Zugang nicht entziehen. Incident-
Deaktivierung separat belegen.

Erstelle zusätzlich ein Founder-Runbook für Benefit-Kampagnen: permanente
Freischaltung, X-Tage-/Fixed-End-Freischaltung, Single-/Multi-use, Nutzer vs.
Trainer, Kampagne stoppen, Grant einzeln widerrufen, Apple Offer Code und Google
Offer/Promo. Jede Vorlage enthält klare Laufzeit-/Auto-Renew-Copy.

Aktualisiere Privacy Labels/Data Safety/Consent-/Anwalts-Delta, App-/Play-
Review-Notes und Release-Readiness. Verifiziere aktuelle Gebühren, SDK-/Billing-
Anforderungen und Store-Regeln erneut aus Primärquellen. Liefere GO/NO-GO für
Nutzer-Paywall-Aktivierung. Aktivierung, Preisänderung, Kommunikation und GA
bleiben separate Founder-Gates.
```
