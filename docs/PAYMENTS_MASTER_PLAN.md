# Payments Master Plan — Premium + Codes + Trainer Studio, Apple + Android

**Stand:** 2026-07-10
**Status:** Founder-Review ausstehend — ausführungsreife Planung, kein aktueller
Build-Auftrag
**Gilt für:** iPhone, iPad, Android-Smartphone und Android-Tablet
**Nicht im Scope:** macOS, Windows, Web-Checkout und Trainer↔Klient-Zahlungen
**Orchestrierung:** `docs/MONETIZATION_STUDIO_MASTER_PROMPT.md`

Dieser Plan ersetzt die erste Fassung vom 2026-07-10. Er bewahrt Claudes gute
Grundentscheidung — RevenueCat als gemeinsame Store-Abstraktion — korrigiert
aber das Entitlement-Modell, die RevenueCat-Identität, Google-Play-Produkte,
Gebühren, Kill-Switch-Semantik und Lifecycle-Lücken.

## 0. Review der ersten Fassung

### Richtig und beibehalten

- Nutzer-Premium und Trainer Studio werden als digitale App-Funktionen über
  Apple IAP bzw. Google Play Billing verkauft.
- RevenueCat verbindet beide Stores mit einem gemeinsamen App-Account.
- Storepreise und Trial-Berechtigung kommen zur Laufzeit aus dem Store.
- Premium und Studio sind getrennte Entitlements; Trainer↔Klient-Zahlungen
  bleiben vollständig außerhalb der Plattform.
- Der Gründer-Startpreis kann für aktive Abonnenten erhalten werden.
- Store-, RevenueCat- und Live-Backend-Aktionen bleiben Founder-gated.

### Korrigiert

1. **Ein Feld wie `premium_type` oder `studio_source` reicht nicht.** Ein Konto
   kann gleichzeitig Code + Store-Abo oder Lifetime + alte Store-Events haben.
   Store-Ablauf darf einen anderen gültigen Grant nie löschen.
2. **RevenueCat ist Purchase-Status-Quelle; Supabase ist Autorisierungs-
   projektion.** Storetransaktionen sind die zugrunde liegende Autorität.
   `profiles.is_premium` bleibt vorerst eine Legacy-Projektion, nicht das
   vollständige Ledger.
3. **Kein `Purchases.logOut()` beim App-Logout.** RevenueCat erzeugt sonst eine
   anonyme ID. Da die App Login voraussetzt, wird das SDK nur mit der
   Supabase-UID konfiguriert; bei Accountwechsel wird direkt `logIn(neueUid)`
   genutzt. Im ausgeloggten Zustand gibt es keine Kaufoberfläche.
4. **Webhook-Events werden nicht als geordnete Wahrheit interpretiert.** Sie
   können doppelt oder verzögert eintreffen. Ein Event löst eine
   Reconciliation des aktuellen RevenueCat-Kundenstatus aus.
5. **Compile-Flags sind kein operativer Kill Switch.** Sie benötigen ein
   Store-Update. Serverseitig werden Verkaufs-Rollout und Feature-Zugang
   getrennt; Compile-Flags bleiben nur zusätzliche Release-Sicherung.
6. **Google-Produkte brauchen Subscription + Base Plans.** Monat/Jahr sind auf
   Google in diesem Plan Base Plans eines Premium- bzw. Studio-Abos; RevenueCat
   referenziert Subscription-ID plus Base-Plan-ID.
7. **Google-Gebühren sind regions-/zeitabhängig.** Seit 2026-06-30 weist Google
   für EWR/UK/USA bei Auto-Renew-Abos 10 % Service Fee + 5 % Billing Fee aus;
   Lifetime und andere Einmalkäufe folgen anderen Regeln.
8. **„Organisation“ ist kein kostenloser Shortcut.** Ein Google-
   Organisationskonto benötigt u. a. eine D-U-N-S-Nummer. Das richtige Konto
   richtet sich nach der realen Unternehmensidentität, nicht nur nach dem
   Wunsch, das Personal-Account-Testgate zu vermeiden.
9. **Family Sharing, Doppelkauf, Accountlöschung, Planwechsel, Lifetime bei
   aktivem Abo, Grace Period und Restore brauchen explizite Regeln.** Sie sind
   jetzt unten festgelegt.

## 1. Zahlungsinventar

| Struktur | Produkt | Kaufweg | Entitlement |
|---|---|---|---|
| Nutzer Premium Monat | wiederkehrend | Apple/Google via RevenueCat | `premium` |
| Nutzer Premium Jahr | wiederkehrend | Apple/Google via RevenueCat | `premium` |
| Nutzer Premium Lifetime | einmalig, non-consumable/one-time | Apple/Google via RevenueCat | `premium` |
| Gründungsnutzer-Code | interner dauerhafter Grant | vorhandene sichere Code-Einlösung | `premium` |
| Freunde-/Familiencode | interner befristeter oder dauerhafter Grant | Benefit-Code-System | `premium` oder `studio` |
| Studio Monat | wiederkehrend | Apple/Google via RevenueCat | `studio` |
| Studio Jahr | wiederkehrend | Apple/Google via RevenueCat | `studio` |
| Studio Free-MVP-Pilot | befristeter interner Grant | Pilotkampagne/Code/Allowlist | `studio` |
| Studio-Test-/Reviewzugang | befristeter interner Grant | Review-/Admin-Runbook | `studio` |
| Trainer-Sitzung | direkte Zahlung Trainer↔Klient | außerhalb der App/Plattform | keines |

Kein Einzelpaket-Verkauf und kein Studio-Lifetime zum Start.

## 2. Verbindliche Produktentscheidungen

### PM-D1 — Storestrategie

**Empfehlung:** Apple IAP auf iOS/iPadOS und Google Play Billing auf Android,
beides via RevenueCat. Keine alternative Android-Abrechnung und kein externer
Checkout in Phase 1. Die seit 2026 möglichen regionalen Alternativen erhöhen
Steuer-, Verbraucherrechts-, Support- und Abrechnungsaufwand und widersprechen
dem Ziel eines einfachen Solo-Founder-Betriebs.

### PM-D2 — Plattform- und Accountzugang

Ein Kauf entsperrt das jeweilige Entitlement für denselben angemeldeten
Supabase-Account auf iPhone, iPad und Android. Kauf vor Login ist verboten.
Kinderprofile besitzen keine eigenen Käufe; der Grant gilt für alle Profile
unter dem Eltern-/Hauptkonto.

### PM-D3 — Family Sharing

**Empfehlung: AUS.** Reflex Journey hat bereits Familienprofile innerhalb eines
Accounts. Apple Family Sharing würde bis zu fünf weitere Apple-Accounts mit
eigenen App-Accounts einbeziehen und Support/Datenschutz/Restore unnötig
verkomplizieren. Apple weist darauf hin, dass aktiviertes Family Sharing für
ein IAP nicht wieder deaktiviert werden kann. Google teilt In-App-Käufe ohnehin
nicht über die Family Library.

### PM-D4 — Premium-Preisleiter

Research-/Launch-Hypothese:

| Produkt | Deutschland/EUR |
|---|---:|
| Premium Monat | 12,99 € |
| Premium Jahr | 89,99 € |
| Premium Lifetime | 149,00 € |

Kein zusätzlicher Premium-Trial: Paket 1 ist der reale Produkttest. Alle
Storefront-Preise werden im Store gepflegt und in der App lokalisiert angezeigt.

### PM-D5 — Studio-Preisleiter

Standardhypothese: 14,99 €/Monat und 119,99 €/Jahr, 14 Tage Trial für
store-berechtigte Neukunden. Final nach Trainer-Research.

Gründungsmechanik: Das Studio startet für Gründungs-Trainer zu einem niedrigeren
Basispreis, z. B. 7,99 €/Monat und 69,99 €/Jahr. Beim allgemeinen Launch wird
dasselbe Produkt erhöht; aktive Bestandsabonnenten bleiben bewusst in der
erhaltenen Apple- bzw. Google-Preiskohorte.

Zulässige Copy:

> „Als Gründungs-Trainer behältst du deinen Startpreis, solange dein Abo aktiv
> bleibt.“

Nicht versprechen: „50 % für immer“. Nach Kündigung/Wiederabschluss gelten die
jeweiligen Store-Regeln; Apple nennt für erhaltene Preise eine mögliche
60-Tage-Wiederanmeldung, Google arbeitet mit Legacy-Preiskohorten. Die App
garantiert darüber hinaus nichts.

### PM-D6 — Planwechsel

- Monat → Jahr und Jahr → Monat laufen über Store-Planwechsel, nicht über
  eigene Proration.
- Die UI zeigt nur storeseitig zulässige Wechsel und erklärt, wann sie wirksam
  werden.
- Premium ↔ Studio ist niemals ein Wechsel; beide können gleichzeitig aktiv
  sein.
- Ein Nutzer mit aktivem Premium-Abo bekommt Lifetime nicht als einfachen
  Kaufbutton angeboten. Erst Abo verwalten/kündigen; Lifetime wird nach Ablauf
  angeboten. So entsteht keine versehentliche Doppelzahlung.

### PM-D7 — Cross-Store-Doppelkauf

Ist `premium` oder `studio` bereits über den anderen Store aktiv, zeigt die App
„Über Apple/Google aktiv“ und keinen zweiten Kaufbutton. Verwaltung führt zum
ursprünglichen Store. Ein zweites paralleles Abo wird aktiv verhindert, soweit
der synchronisierte RevenueCat-Status vorliegt.

### PM-D8 — Restore und Accountwechsel

RevenueCat Restore Behavior: **Transfer to new App User ID** als empfohlener
Startwert. Ein Storekauf kann dadurch nach Accountlöschung/-neuanlage dem
aktuell angemeldeten Konto zugeordnet werden; die Übertragung wird auditiert.
Vor Produktion wird dieser Flow mit zwei Testkonten geprüft.

Interne Code-Grants sind nicht im Store und daher nicht automatisch restorable.
Bei Accountlöschung wird klar gewarnt: Storekäufe sind wiederherstellbar,
Codezugänge nicht automatisch. Support kann nach Prüfung des ursprünglichen
Codes einen alten Code sperren und einen Ersatzcode ausstellen. Keine
personenbezogene Schattenakte nur für Restore anlegen.

### PM-D9 — Grace, Retry, Pause, Refund

- `CANCELLATION` bedeutet nur Auto-Renew aus; Zugriff bleibt bis Ablauf.
- Billing Issue entzieht nicht automatisch. Während aktiver Store-Grace-Period
  bleibt Zugriff bestehen.
- Entzug erfolgt beim aktuell reconcilierten inaktiven/abgelaufenen Status.
- Google-Pause entzieht erst beim tatsächlichen Ablauf/Pausebeginn gemäß
  aktuellem Entitlement.
- Refund/Revocation wird durch Reconciliation wirksam; ein separater gültiger
  Code- oder Lifetime-Grant bleibt davon unberührt.
- Apple Billing Grace Period wird bewusst konfiguriert (Empfehlung 16 Tage,
  Paid-to-Paid; final vor Launch), Google-Grace analog bewusst festlegen.

### PM-D10 — Offline

- Gratisumfang funktioniert offline wie bisher.
- Letzter serververifizierter Store-/Code-Status darf bis zum früheren von
  `expires_at` oder 72 Stunden offline gecacht werden.
- Permanent Grants dürfen offline gecacht werden, werden aber beim nächsten
  Netzstart erneut geprüft.
- SharedPreferences ist Komfortcache, keine Sicherheitsgrenze. Server-RPCs und
  Studio-Daten prüfen immer das effektive serverseitige Entitlement.

### PM-D11 — Freunde, Familie, Founder und Pilot-Codes

**Empfehlung:** Ein allgemeines Benefit-System für Nutzer **und** Trainer,
nicht weitere Sonderfelder pro Kampagne.

Es trennt zwei grundverschiedene Vorteile:

1. **Interner Freizugang:** Reflex Journey vergibt ohne Kauf einen `premium`-
   oder `studio`-Grant. Möglich sind permanent, X Tage/Monate oder bis zu einem
   festen Datum. Kein Abo, keine automatische Verlängerung, keine spätere
   Belastung.
2. **Store-Rabatt:** Der eigentliche Kauf bleibt beim Store. Apple nutzt
   Subscription Offer Codes; Google nutzt Base-Plan-Offers bzw. Promo Codes.
   Eine interne Kampagne kann auf die jeweilige Storeaktion verweisen, setzt
   aber niemals selbst einen billigeren Kaufpreis.

Damit sind dauerhaft möglich:

- permanente Gründungsnutzer-Freischaltung;
- befristeter kostenloser Freunde-/Familienzugang;
- permanenter persönlicher Comp-Zugang;
- kostenloser Trainer-MVP für eine geschlossene Kohorte;
- Support-/Kulanzverlängerung;
- zeitlich begrenzter Apple-/Google-Aborabatt.

Ein Rabattcode kann storebedingt nicht auf beiden Plattformen exakt dieselbe
Mechanik oder Eligibility garantieren. Die App zeigt deshalb nach Plattform
den passenden Store-Offer-Flow. Für garantiert identisches Cross-Platform-
Verhalten ist ein interner Freizugangs-Grant die einfachere Variante.

#### Benefit-Datenmodell

`benefit_campaigns`:

- `id`, interner Name und Zweck (`founder_user`, `friends_family`,
  `trainer_free_mvp`, `support`, frei erweiterbar);
- `entitlement_key` (`premium|studio`);
- `benefit_kind` (`internal_grant|store_offer`);
- bei intern: `permanent|duration_days|fixed_end`, Wert/Enddatum;
- Zielgruppe/Rolle (`user|trainer|both`) und optionale Eligibility-Regeln;
- Start/Ende, Gesamtlimit, Pro-Account-Limit, aktiv/widerrufen;
- bei Store-Offer: Apple-Offer-Referenz und Google-Offer-/Promo-Referenz;
- auditierbare, nicht öffentliche Beschreibung.

`benefit_codes`:

- Campaign-Bezug, `single_use|multi_use`, Redemption-Limit;
- Code nie im Klartext speichern: keyed HMAC mit Server-Secret + kurze
  Anzeige-Hilfe; ausreichend lange zufällige Codes;
- aktiv/widerrufen/ablaufend.

`benefit_redemptions`:

- Code/Campaign/User, Zeitpunkt, Ergebnis/Grant-ID, Plattform;
- unique pro Campaign+User, soweit Kampagne nichts anderes erlaubt;
- atomare Limitprüfung; keine Race-Doppel-Einlösung.

Ein eingelöster interner Code erzeugt einen normalen `entitlement_grants`-
Datensatz mit `source=benefit_code` oder `source=pilot`. Kampagnenstopp sperrt
neue Einlösungen; bereits gewährte Grants werden nur durch eine getrennte,
auditierte Revocation geändert.

## 3. Zielarchitektur

```text
Apple IAP ─┐
           ├─> RevenueCat Customer/Entitlements ──> Webhook + REST-Reconcile
Google Play┘              │                                  │
                          │ CustomerInfo                     ▼
                          ▼                         entitlement_grants
                    Flutter Purchase UI            + effective_entitlements
                                                          │
Access Code ───────────── secure server grant ─────────────┤
Review/Test grant ─────── admin/runbook grant ─────────────┘
                                                          │
                                                          ▼
                                           legacy profile projections
                                           + server authorization
```

Autoritätskette:

1. Apple/Google autorisieren die Storetransaktion.
2. RevenueCat normalisiert Storestatus und ist Purchase-Status-Quelle.
3. Supabase führt Store- und interne Grants zusammen und ist Quelle für
   serverseitige App-Autorisierung.
4. `profiles.is_premium` und spätere Studio-Kurzfelder sind abgeleitete
   Kompatibilitätsprojektionen.

## 4. Entitlement-Ledger

### 4.1 Additive Tabelle `entitlement_grants`

Planfelder:

- `id uuid`
- `user_id uuid`
- `entitlement_key text CHECK IN ('premium','studio')`
- `source text CHECK IN ('revenuecat','benefit_code','pilot','review','admin')`
- `source_ref text` — stabiler, nicht geheimer externer/interner Schlüssel
- `status text CHECK IN ('active','grace','expired','revoked')`
- `store text NULL CHECK IN ('app_store','play_store','promotional')`
- `product_id text NULL`
- `starts_at`, `expires_at`, `revoked_at`, `updated_at`
- `is_permanent boolean`
- minimale technische `metadata jsonb` ohne E-Mail, Namen oder Notiztexte

Eindeutigkeit: `(source, source_ref, entitlement_key)`. Clients erhalten keinen
direkten Schreibzugriff.

### 4.2 Effektiver Status

Ein Entitlement ist aktiv, wenn mindestens ein nicht widerrufener Grant aktiv
ist und entweder permanent ist oder `expires_at > now()` gilt. Grace zählt nur,
wenn RevenueCat den Storezugriff aktuell als berechtigt meldet.

Mehrere Grants sind erlaubt:

```text
Code aktiv + Store abgelaufen       => premium aktiv
Lifetime aktiv + Refund altes Abo   => premium aktiv
Studio Reviewgrant abgelaufen       => studio inaktiv, außer Storegrant aktiv
Premium aktiv                       => sagt nichts über studio aus
```

### 4.3 Legacy-Projektion

Eine serverseitige Funktion aktualisiert die bestehenden
`profiles.is_premium/premium_type/premium_valid_until` aus dem Ledger, damit
T23-Code zunächst weiterarbeitet. `premium_type` zeigt nur den wirksamen
Anzeigegrund mit Priorität `code > lifetime > yearly > monthly`; es löscht
keine Grants. Später kann der Client direkt den effektiven Status lesen.

T24-Backfill: Für jeden erfolgreich eingelösten Code entsteht genau ein
permanenter `benefit_code`-Grant. Bestehende kurze Klartextcodes werden vor
neuer Ausgabe in das HMAC-basierte System migriert oder ersetzt. Erst danach
darf der Webhook live gehen.

## 5. RevenueCat-Identität

- App User ID ist exakt die Supabase `auth.uid()`.
- SDK erst konfigurieren, wenn eine authentifizierte UID vorliegt.
- Keine anonymen Käufe.
- Bei Wechsel von Account A zu B direkt `Purchases.logIn(B)`; nicht vorher
  `logOut()` aufrufen.
- Nach App-Logout: Kauf-UI unzugänglich, lokale CustomerInfo nicht als Status
  eines späteren Nutzers anzeigen.
- Derselbe RevenueCat-Project-Container enthält die iOS- und Android-App, damit
  Entitlements projektweit geteilt werden.
- Restore-/Transfer-Ereignisse werden für alte und neue App User IDs
  reconciliert.
- Supportscreen zeigt eine kopierbare technische Account-ID, keine Secrets.

## 6. Webhook und Reconciliation

### Eingangsschutz

- eigener Production- und Sandbox-Webhook;
- Authorization Header **und** RevenueCat-HMAC aktivieren/verifizieren;
- Payload-Größenlimit, JSON-Schema-Basisprüfung, keine PII-Logs;
- Event-ID idempotent in `revenuecat_events` speichern;
- Eventtyp, Umgebung, Empfangs-/Verarbeitungsstatus, Versuchszahl und
  redigierter Fehler — kein kompletter Payload-Dump.

### Verarbeitung

Ein Webhook ist ein Reconcile-Trigger:

1. Event authentifizieren und idempotent registrieren.
2. Betroffene App User ID(s), einschließlich Aliases/Transfer-Seiten,
   bestimmen.
3. Aktuellen Customer-/Entitlement-Status serverseitig von RevenueCat lesen.
4. `revenuecat`-Grants transaktional upserten/ablaufen lassen.
5. effektiven Status/Legacy-Projektion neu berechnen.
6. Erfolg markieren; bei temporärem Fehler non-2xx für RevenueCat-Retry.

Unbekannte Eventtypen werden gespeichert, alarmiert und mit 200 quittiert,
wenn kein Reconcile nötig ist. Ein täglicher Reconciliation-Job prüft kürzlich
aktive Storekunden, damit ein endgültig verlorener Webhook keinen dauerhaften
Fehlstatus erzeugt.

### Client nach Kauf

RevenueCat CustomerInfo darf sofort einen UI-Erfolg anzeigen. Für
servergeschützte Studio-Funktionen wartet die App auf die Backend-Projektion
und zeigt kurz „Zugang wird aktiviert“ mit Retry; sie umgeht nie serverseitige
RLS/RPC-Prüfungen.

## 7. Storekatalog

### Apple

| Gruppe/Typ | Product ID (Vorschlag) | RevenueCat Package |
|---|---|---|
| Premium Monat | `rj_premium_monthly` | `$rc_monthly` |
| Premium Jahr | `rj_premium_yearly` | `$rc_annual` |
| Premium Lifetime (non-consumable) | `rj_premium_lifetime` | `$rc_lifetime` |
| Studio Monat, eigene Gruppe | `rj_studio_monthly` | `$rc_monthly` im Studio-Offering |
| Studio Jahr, eigene Gruppe | `rj_studio_yearly` | `$rc_annual` im Studio-Offering |

Premium und Studio sind getrennte Subscription Groups. Lifetime gehört keiner
Abo-Gruppe an. Family Sharing nicht aktivieren.

### Google Play

| Subscription/Produkt | Base Plan | RevenueCat-Referenz |
|---|---|---|
| `rj_premium` | `monthly` | Subscription + Base Plan |
| `rj_premium` | `yearly` | Subscription + Base Plan |
| `rj_premium_lifetime` (one-time) | — | One-time Product |
| `rj_studio` | `monthly` | Subscription + Base Plan |
| `rj_studio` | `yearly` | Subscription + Base Plan |

Trials sind Offers auf den Studio-Base-Plans, keine separaten Produkte.
RevenueCat Offerings `premium` und `studio` mappen pro Package das jeweilige
Apple- und Google-Produkt.

## 8. Gebühren und Steuer — Stand 2026-07-10

Keine globale Pauschale in Umsatzprognosen. Storefront, Installationsdatum,
Produkttyp und Programmanmeldung beeinflussen die Gebühr.

### Apple

- 15 % bei angenommener Teilnahme am Small Business Program; Teilnahme und
  $1M-Grenze verifizieren.
- Ohne Teilnahme/außerhalb der Voraussetzungen gelten Apples aktuelle
  Standardregeln.

### Google Play

- EWR/UK/USA seit 2026-06-30: Auto-Renew-Abos über Play Billing laut Google
  10 % Service Fee + 5 % Billing Fee.
- Andere Transaktionen, insbesondere Lifetime, unterscheiden sich nach neuer/
  bestehender Installation und Programmen; im ersten-$1M-Modell über Play
  Billing ergibt sich laut aktueller Tabelle 10 % + 5 %, sofern die
  Voraussetzungen erfüllt sind.
- Noch nicht umgestellte Märkte folgen bis zu ihrem Rollout den dort genannten
  bisherigen Regeln.

RevenueCat-Gebühr und Schwelle werden beim Accountsetup aus der aktuellen
Preisseite übernommen. Steuerliche Einordnung, §19 UStG, Belege und
Auszahlungsverbuchung gehen vor Aktivierung zum Steuerberater. Nicht pauschal
„Apple/Google ist Händler und alles erledigt“ in Rechts- oder Buchhaltungsdoku
schreiben.

## 9. Externe Founder-Checkliste

### Apple

1. App-Store-Connect-App-Record für `de.reflexjourney.app`.
2. Paid Apps Agreement, Banking und Tax vollständig.
3. Small Business Program beantragen/Status dokumentieren.
4. Premium-Produkte erst nach finaler ID-/Preisprüfung anlegen.
5. Studio-Produkte erst vor T27-Pilot anlegen.
6. Billing Grace Period und Family Sharing bewusst konfigurieren.
7. Sandbox-Tester und Review-Demo-Account vorbereiten.

### RevenueCat

1. Ein Projekt, Apps für iOS Production und Android Production; Test Store für
   frühe Integrationstests.
2. Entitlements `premium` und `studio`; Offerings getrennt.
3. Aktuelle Apple In-App-Purchase-Key-/ASC-Verbindung nach RevenueCat-Doku;
   keine veraltete Shared-Secret-Anleitung blind übernehmen.
4. Restore Behavior PM-D8 setzen und screenshotten.
5. Sandbox-/Production-Webhooks getrennt, Authorization + HMAC.
6. Secret/API-Keys nur in Supabase Secrets bzw. Build-Secret-Konfiguration.

### Google

1. Accounttyp ehrlich wählen:
   - Organisation, wenn das reale Unternehmen verifiziert werden kann und eine
     D-U-N-S-Nummer vorhanden/beschaffbar ist;
   - Personal sonst, inklusive 12-Tester-/14-Tage-Produktionsgate für neue
     persönliche Konten.
2. Developer-/Payments-Profil und öffentliche Angaben prüfen.
3. App-Record, Signing, Internal/Closed Test Tracks.
4. Play-Billing-Produkte/Base Plans/Offers.
5. Service Account/API-Zugriff für RevenueCat nach aktueller Anleitung.
6. Gebührenprogramm/-status anhand der dann sichtbaren Console und Region
   dokumentieren; nicht „Play Media Experience“ als Standardweg verwenden.
7. License Tester, Testkarten und Subscription-Testzeiten vorbereiten.

## 10. Pflicht-Testmatrix

### Kauf und Restore

- Premium Monat/Jahr/Lifetime je Store;
- Studio Monat/Jahr + Trial eligible/ineligible je Store;
- Kaufabbruch, Storefehler, Netzwerkverlust, Pending Purchase;
- Restore nach Neuinstallation;
- iOS-Kauf → Android-Zugriff und Android-Kauf → iOS-Zugriff;
- zwei App-Accounts auf einem Gerät, Restore-Transfer PM-D8;
- Kauf bei aktivem Entitlement des anderen Stores verhindert.

### Lifecycle

- freiwillige Kündigung: Zugriff bis Ablauf;
- Renewal, Uncancellation, Product Change;
- Billing Issue ohne/mit Grace, Recovery und endgültiger Ablauf;
- Google Pause/Resume;
- Refund/Revocation;
- doppelte und absichtlich vertauschte Webhook-Events;
- verlorener Webhook, durch täglichen Reconcile geheilt.

### Grant-Kombinationen

- Code + ablaufendes Monatsabo;
- Code + Refund;
- Lifetime + altes Aboevent;
- Reviewgrant + Storegrant;
- Premium + Studio gleichzeitig;
- Accountlöschung: Store-Restore vs. interner Codehinweis.

### Benefit-/Rabattcodes

- interner Premium- und Studio-Code, permanent/duration/fixed-end;
- Single-use, Multi-use, Gesamtlimit und Pro-Account-Limit unter Konkurrenz;
- falsche Rolle, abgelaufene/widerrufene Kampagne, bereits eingelöst;
- Kampagnenstopp lässt bestehende Grants unangetastet; gezielte Revocation
  separat;
- Apple Offer Code: new/active/expired Eligibility und Auto-Renew-Copy;
- Google Base-Plan-Offer/Promo: Eligibility, Offer-Tags und richtige Auswahl;
- gleicher interne Freizugangscode funktioniert accountgebunden auf Apple und
  Android; Store-Rabatte dürfen plattformspezifisch abweichen.

### UX/Compliance

- lokalisierter Preis/Zeitraum/Verlängerung;
- Trial nur bei Eligibility;
- Restore und Aboverwaltung auffindbar;
- Terms/Privacy/Support/Refund-Hinweise;
- DE/EN, Light/Dark, iPhone/iPad, Android Phone/Tablet, 150 % Text;
- Gratisumfang bleibt nach Ablauf und bei Storeausfall nutzbar.

## 11. Build-Reihenfolge und ausführbare Tasks

### T25.0 — Multi-Grant- und Benefit-Code-Fundament

**Gate:** Founder bestätigt PM-D1–D12.
**Ergebnis:** `entitlement_grants`, Benefit-Kampagnen/-Codes/-Redemptions,
effektive Statusfunktion, Legacy-Projektion, T24-Code-Backfill,
RLS/Trigger/Negativtests. Alles additiv; Live-DDL separat Founder-gated.

### T25.1 — RevenueCat Core + Test Store

**Gate:** RevenueCat-Projekt.
**Ergebnis:** `purchases_flutter`, authentifizierte UID-Initialisierung ohne
anonyme IDs/Logout, Offerings/Produkte/Eligibility-Abstraktion, Test-Store-E2E,
kein echter Store nötig.

### T25.2 — Webhook + Reconciliation

**Gate:** T25.0 + RevenueCat Server-Zugang.
**Ergebnis:** Event-Inbox, Authorization/HMAC, Customer-Reconcile, Ledger-
Upsert, Transfer/Alias, Retry, täglicher Repair-Job, Tests. Deploy separat
Founder-gated.

### T25.3 — Apple IAP Production Wiring

**Gate:** ASC Record + Agreements + Produkte.
**Ergebnis:** iPhone/iPad Sandbox-Käufe, Restore, Planwechsel, Grace/Refund-
Tests, Review Notes, Family Sharing aus, redigierte Evidenz.

### T25.4 — Google Play Billing Production Wiring

**Gate:** Play Account + App + Produkte/Base Plans + RevenueCat-Verbindung.
**Ergebnis:** Android Phone/Tablet License-Testkäufe, Restore, Planwechsel,
Pause/Grace/Refund, Cross-Platform-E2E, Data-Safety-Delta.

### T25.5 — Operations + Aktivierungs-Readiness

**Gate:** T25.0–T25.4.
**Ergebnis:** Support-/Refund-/Transfer-/Accountlöschungs-Runbook, Monitoring,
Reconciliation-Audit, Kill-Switch-Test, vollständige Testmatrix,
GO/NO-GO-Bericht. Aktivierung bleibt eigener Founder-Go nach R8/Legal.

Kopierfertige Session-Prompts: `docs/PAYMENTS_BUILD_PROMPTS.md`. Der
Orchestrator gibt sie exakt in dieser Reihenfolge aus; eine Session bearbeitet
immer nur einen Task.

## 12. Aktivierung, Sales-Rollout und Incident-Schalter

Zwei serverseitig getrennte Zustände plus Release-Sicherung:

1. Compile-Flag schützt unreife UI vor dem ersten Release.
2. `sales_rollout = off | internal | cohort | public` steuert neue
   Kaufoberflächen je Entitlement/Plattform.
3. `feature_rollout = internal | cohort | public | incident_disabled` steuert
   die freigegebene Zielgruppe. `incident_disabled` ist nur für belegte
   Sicherheits-/Datenintegritätsvorfälle mit Incident-Runbook, Kommunikation
   und Wiederherstellungsplan.

`sales_rollout=off` verhindert neue Käufe, entzieht aber keinen gültigen Zugang
und löscht keine Grants. Nach öffentlichem bezahltem Launch bleibt
`feature_rollout=public`, außer ein echter Incident rechtfertigt die separate
Notabschaltung. Das Runbook unterscheidet immer „Verkauf stoppen“ von
„Leistung vorübergehend deaktivieren“.

### PM-D12 — Abweichung von der „No Remote Config“-Regel *(Review-Nachtrag 2026-07-10)*

Serverseitige Rollout-Zustände sind Remote-Konfiguration und weichen damit
bewusst von CLAUDE.md §4 („compile-time `const bool` only. No remote config",
Founder-Entscheidung D1/D2 2026-07-06) ab. Begründung: Ein Compile-Flag kann
laufende Verkäufe nicht ohne Store-Review-Zyklus stoppen; für bezahlte
Funktionen ist das operativ unzureichend.

**Empfehlung:** Abweichung genehmigen, aber eng begrenzt:

- Rollout-Zustände gelten ausschließlich für Verkaufs-/Paid-Flächen
  (`premium`, `studio`) — keine allgemeine Feature-Flag-Infrastruktur;
- Schreibzugriff nur service_role (Schutz-Trigger wie beim Entitlement),
  Clients lesen nur; unkonfiguriert/nicht erreichbar = fail-closed auf den
  jeweils sicheren Zustand (Verkauf aus, Feature-Zugang unverändert);
- Compile-Flags bleiben für alles Übrige die einzige Gate-Mechanik.

Bei GO werden CLAUDE.md §4 und der Doc-Kommentar in
`lib/config/launch_flags.dart` in T25.0 entsprechend ergänzt, damit Regel
und Realität nicht auseinanderlaufen. Bei NO-GO entfallen die Rollout-Tabellen
und der Kill Switch bleibt Compile-Flag + Store-Update (bewusst langsamer).

## 13. Founder-Entscheidungspaket

Ein Satz genügt:

> „GO PM-D1 bis PM-D12 wie empfohlen; Preise bleiben Hypothesen bis zu den
> jeweiligen Validierungsgates.“

Einzelne Abweichungen können mit ID genannt werden. Unabhängig davon bleiben
Live-DDL, Deploys, Store-Anlage, externe Kommunikation und Aktivierung separat
gated.

## 14. Aktuelle Primärquellen

- Apple App Review Guidelines:
  <https://developer.apple.com/app-store/review/guidelines/>
- Apple IAP-Konfiguration und Paid Apps Agreement:
  <https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/overview-for-configuring-in-app-purchases/>
- Apple Preisbestandsschutz:
  <https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/>
- Apple Family Sharing:
  <https://developer.apple.com/help/app-store-connect/configure-in-app-purchase-settings/turn-on-family-sharing-for-in-app-purchases/>
- Apple Billing Grace Period:
  <https://developer.apple.com/help/app-store-connect/manage-subscriptions/enable-billing-grace-period-for-auto-renewable-subscriptions/>
- Google Accounttypen/D-U-N-S:
  <https://support.google.com/android-developer-console/answer/16641046>
- Google Testgate für neue persönliche Konten:
  <https://support.google.com/googleplay/android-developer/answer/14151465>
- Google Gebühren ab 2026-06-30:
  <https://support.google.com/googleplay/android-developer/answer/112622>
- Google Subscriptions/Base Plans:
  <https://developer.android.com/google/play/billing/subscriptions>
- Google Legacy-Preiskohorten:
  <https://developer.android.com/google/play/billing/price-changes>
- RevenueCat Identität:
  <https://www.revenuecat.com/docs/customers/identifying-customers>
- RevenueCat Restore Behavior:
  <https://www.revenuecat.com/docs/projects/restore-behavior>
- RevenueCat Webhooks/Eventtypen:
  <https://www.revenuecat.com/docs/integrations/webhooks> ·
  <https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields>
- RevenueCat Google Product + Base Plan IDs:
  <https://www.revenuecat.com/docs/offerings/products-overview>
- Apple Subscription Offer Codes:
  <https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-subscription-offer-codes/>
- Google Play Offers und Promo Codes:
  <https://support.google.com/googleplay/android-developer/answer/140504> ·
  <https://support.google.com/googleplay/android-developer/answer/6321495>

Alle Store-/Gebührenangaben werden in T25.5 vor Aktivierung erneut geprüft.
