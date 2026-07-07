# Monetarisierung & Paywall — Design

Status: Approved v1 (2026-05-28) — **TEILWEISE VERWORFEN, siehe Update unten**
Owner: Alexander Messinger

> **⚠️ Update 2026-07-07 (Founder-Entscheidung D5):** Der komplette
> **Trainer-Payments-Teil ist GESTRICHEN** — die Abrechnung von
> Trainer-Sitzungen läuft **ausschließlich direkt zwischen Trainer und
> Klient**, ohne die Plattform: keine Session-Provision, kein Stripe
> Connect, keine `session_payments`-Tabelle, keine Payment-Edge-Functions,
> kein DAC7 (entfällt, weil die Plattform keine Zahlungen vermittelt oder
> kennt). Betroffen: §1 Punkt 2, §4 komplett, §5 (Connect-/Payment-Teile),
> §6 (Stripe-Connect-Zeilen + DAC7-Absatz). Trainer-Monetarisierung läuft
> künftig — falls überhaupt — über ein **Trainer-Werkzeug-Abo** (Details:
> `docs/MONETARISIERUNG_EVALUATION.md`).
>
> Ebenfalls überholt: **Phase 1 (Stripe-Checkout fürs Nutzer-Abo)** —
> durch die Entscheidung „Launch kostenlos“ (8.4) wird direkt auf Phase 2
> (RevenueCat + Apple IAP) gezielt; Stripe wird gar nicht mehr benötigt.
> **Weiter gültig:** §3 Paywall-Logik/Produkte (Trio B) und das
> profiles-Entitlement-Datenmodell — umgesetzt in T23 (Migration
> `2026070701_premium_entitlements.sql`, `premium_type` um `'code'`
> erweitert, plus Schutz-Trigger gegen Client-Selbstfreischaltung).

---

## 1. Überblick

CoreJourney monetarisiert über zwei unabhängige Geldflüsse:

1. **Platform-Abo** — Nutzer zahlen für den Zugang zu Trainingspaketen ab Paket 2
2. **Trainer-Sessions** — Nutzer buchen und bezahlen Einzelstunden direkt bei Trainern; die Plattform zieht automatisch eine Provision ab

Beide Flüsse laufen über Stripe. Die App fragt ausschließlich Supabase ab — Stripe-Daten werden nur serverseitig (Edge Functions + Webhooks) verarbeitet.

---

## 2. Phasenmodell

### Phase 1 — TestFlight MVP

- Platform-Abo: Stripe Checkout im externen Browser (kein In-App Purchase)
- Trainer-Payments: Stripe Connect Express
- Kein App Store, kein RevenueCat, kein Apple-Schnitt
- Ziel: Geschäftsmodell validieren bevor App-Store-Aufwand investiert wird

### Phase 2 — App Store

- Platform-Abo: RevenueCat + Apple IAP (iOS) + Google Play Billing (Android)
- Trainer-Payments: unverändert Stripe Connect
- Apple IAP ist für das Platform-Abo im App Store Pflicht (digitale Inhalte)
- Trainer-Sessions sind von Apple IAP ausgenommen (physische Dienstleistung durch Dritte)

---

## 3. Paywall-Logik

### Freie vs. bezahlte Inhalte

| Bereich | Zugang |
|---|---|
| Paket 1 (Moro-Reflex) | Kostenlos für alle |
| Paket 2+ | Nur mit aktivem Premium-Status |
| Trainer-Session buchen | Kostenlos für alle, unabhängig vom Abo |

### Paywall-Trigger

Nutzer schließt Paket 1 ab und startet Paket 2 → App prüft `isPremium` → false → Paywall-Screen mit drei Produkten.

### Produkte (Trio B)

| Produkt | Preis | Typ |
|---|---|---|
| Monatsabo | €12,99/Monat | Stripe Subscription (recurring) |
| Jahresabo | €89,99/Jahr | Stripe Subscription (recurring) |
| Lifetime | €149,00 | Stripe Payment Intent (einmalig) |

Das Wochenabo ist technisch verfügbar (als Schnupperoption nach Onboarding oder Kündigungsflow) aber nicht auf dem Haupt-Paywall-Screen sichtbar.

### Premium-Status in Supabase

Neue Felder in der bestehenden `profiles`-Tabelle:

```sql
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_premium boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS premium_type text
    CHECK (premium_type IN ('monthly', 'yearly', 'lifetime')),
  ADD COLUMN IF NOT EXISTS premium_valid_until timestamptz,
  ADD COLUMN IF NOT EXISTS stripe_customer_id text;
```

- `is_premium = true` + `premium_type = 'lifetime'` + `premium_valid_until = null` → läuft nie ab
- `is_premium = true` + `premium_type IN ('monthly', 'yearly')` + `premium_valid_until` gesetzt → Stripe Webhook setzt `is_premium = false` wenn Abo abläuft
- App liest `isPremium` beim Start und nach jeder Zahlung via Riverpod Provider

---

## 4. Trainer-Marketplace

### Geldfluss

```
Nutzer zahlt €70 (Beispiel-Sessionpreis)
  → Stripe verteilt automatisch:
     Trainer:   €59,50  (85%)
     Plattform: €10,50  (15% Application Fee)
```

Die Plattformgebühr beträgt 15%. Dieser Wert ist in der Edge Function konfigurierbar.

### Trainer-Onboarding (Stripe Connect Express)

1. Trainer tippt "Zahlungen einrichten" im Trainer-Dashboard
2. App ruft Edge Function `create-connect-onboarding-link` auf
3. Edge Function erstellt Stripe Connect Express Account + Account Link
4. Trainer öffnet Link im Browser und durchläuft Stripe KYC:
   - Name, Adresse, IBAN
   - Steuernummer
   - Bei >€2.500/Monat: Personalausweis-Foto (Stripe fordert automatisch an)
5. Stripe sendet Webhook `account.updated` → Edge Function setzt `stripe_onboarding_complete = true`

### Buchungs- und Zahlungsflow

1. Nutzer wählt Trainer + Termin → Appointment wird angelegt (Status: `proposed`)
2. Trainer bestätigt → Status: `confirmed`
3. Nutzer tippt "Jetzt bezahlen" → Edge Function erstellt Stripe Payment Intent mit Application Fee
4. Nutzer zahlt im Browser (Karte, Apple Pay, Google Pay)
5. Webhook `payment_intent.succeeded` → `session_payments` aktualisiert, Appointment Status: `paid`

### Neue DB-Tabellen

```sql
-- Felder in trainer_profiles ergänzen
ALTER TABLE public.trainer_profiles
  ADD COLUMN IF NOT EXISTS stripe_account_id text,
  ADD COLUMN IF NOT EXISTS stripe_onboarding_complete boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS stripe_payouts_enabled boolean NOT NULL DEFAULT false;

-- Zahlungen pro Session
CREATE TABLE IF NOT EXISTS public.session_payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id uuid NOT NULL REFERENCES public.appointments(id) ON DELETE RESTRICT,
  stripe_payment_intent_id text NOT NULL,
  amount_cents int NOT NULL,
  platform_fee_cents int NOT NULL,
  currency text NOT NULL DEFAULT 'eur',
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'paid', 'refunded', 'failed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  paid_at timestamptz
);
```

---

## 5. Technische Architektur

### Edge Functions (Supabase)

| Function | Auslöser | Aufgabe |
|---|---|---|
| `stripe-webhook` | Stripe POST | Verarbeitet alle Stripe-Events, aktualisiert DB |
| `create-checkout-session` | App-Request | Erstellt Stripe Checkout für Abo-Produkte |
| `create-connect-onboarding-link` | App-Request | Erstellt Stripe Connect Onboarding-URL für Trainer |
| `create-session-payment` | App-Request | Erstellt Payment Intent für Trainer-Session |

### Webhook-Events die verarbeitet werden müssen

| Event | Aktion |
|---|---|
| `customer.subscription.created` | `is_premium = true` setzen |
| `customer.subscription.deleted` | `is_premium = false` setzen |
| `invoice.payment_failed` | Nutzer benachrichtigen |
| `payment_intent.succeeded` | Session-Payment auf `paid` setzen |
| `account.updated` | Trainer Connect-Status aktualisieren |

### Flutter-seitig

- `PremiumRepository` — liest `is_premium` aus Supabase, exposed als Riverpod Provider
- `PaywallScreen` — zeigt Trio B, öffnet Stripe Checkout per `url_launcher`
- `TrainerPaymentScreen` — öffnet Session-Payment per `url_launcher`
- Kein Stripe SDK nötig in Phase 1 — alles läuft über Edge Functions und Browser

---

## 6. Genehmigungen & Hürden

### Stripe (vor Go-Live)

| Was | Aufwand | Zeitrahmen |
|---|---|---|
| Stripe-Konto anlegen (Kleingewerbe) | 30 Min | Sofort |
| Stripe Connect Express beantragen | 1–2h | Genehmigung 1–3 Werktage |
| Produkte + Preise anlegen | 30 Min | Nach Konto-Aktivierung |
| Webhook-Endpoint konfigurieren | Dev-Aufgabe | In der Implementierung |

### Rechtliches (vor erstem Geldfluss Pflicht)

| Was | Aufwand | Risiko wenn fehlend |
|---|---|---|
| AGB (inkl. 14-Tage-Widerrufsrecht für digitale Inhalte) | Anwalt oder IT-Recht-Dienst, ~200–500€ | Abmahnbar, Zahlungen angreifbar |
| Datenschutzerklärung (Stripe als Auftragsverarbeiter ergänzen) | 1–2h selbst | DSGVO-Verstoß |
| Trainer-Plattformvertrag (Provision, Haftung, DAC7-Hinweis) | Anwalt ~300–600€ | Plattform haftet für Trainer-Fehler |
| Impressum prüfen (Kleingewerbe-Pflichtangaben) | 30 Min | Abmahnbar |

**DAC7-Meldepflicht:** Ab 25 Transaktionen oder €2.000 Jahresumsatz pro Trainer muss die Plattform an das Finanzamt melden. Stripe erledigt die Meldung automatisch — muss aber in den AGB und im Trainer-Vertrag erwähnt werden.

### App Store Phase 2

| Was | Aufwand | Besonderheit |
|---|---|---|
| Apple Developer Account | €99/Jahr | |
| App Store Review | 1–7 Tage pro Version | Jedes Update durchläuft Review |
| Age Rating | Kritisch prüfen | App richtet sich an Eltern, nicht direkt an Kinder — klar kommunizieren um COPPA/DSGVO-K zu vermeiden |
| Apple IAP Produkte anlegen | 2–3h | In App Store Connect |
| RevenueCat Integration | Dev-Aufgabe | Ersetzt Stripe Checkout für Abo in Phase 2 |

**Age Rating Hinweis:** Die App richtet sich an Eltern und Betreuende — nicht an Kinder unter 13. Das muss im Onboarding, in der App Store Beschreibung und in den AGB explizit stehen. Kinderprofile (Name, Geburtsdatum) dürfen nur über den Eltern-Account verwaltet werden.

---

## 7. Was zuerst gebaut wird (MVP-Scope)

### In Scope für Phase 1

- Supabase Migration: neue Felder in `profiles` und `trainer_profiles`, neue Tabelle `session_payments`
- 4 Edge Functions: Webhook, Checkout-Session, Connect-Onboarding, Session-Payment
- `PremiumRepository` + Riverpod Provider in Flutter
- Paywall-Screen (Trio B) mit `url_launcher`
- Trainer "Zahlungen einrichten"-Flow im Trainer-Dashboard
- Nutzer "Session bezahlen"-Button im Appointment-Detail

### Nicht in Scope für Phase 1

- RevenueCat / Apple IAP / Google Play Billing
- Wochenabo-Screen (technisch vorbereiten, UI erst in Phase 2)
- Rückerstattungs-Flow (manuell über Stripe Dashboard)
- Umsatz-Dashboard für Trainer (Phase 2)
