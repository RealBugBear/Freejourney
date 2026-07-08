# Trainer-Werkzeug-Abo „Trainer Studio“ — Planung (T27)

Stand: 2026-07-07. Kontext: Mit **D5** (Trainer-Abrechnung direkt
Trainer↔Klient, keine Provision) ist das Werkzeug-Abo das **einzige**
Trainer-Monetarisierungsmodell. Dieses Dokument ist die Planungsgrundlage
für die spätere Design-Session — **Umsetzung erst post-launch** (Trigger
unten). Verwandt: `docs/MONETARISIERUNG_EVALUATION.md` (D5-Update).

## 1. Grundsatz: Was gratis bleibt (unantastbar)

Das Gründungs-Trainer-Versprechen (Entscheidung 8.7) deckt **Eintrag und
Sichtbarkeit** dauerhaft kostenlos ab. Zusätzlich bleibt gratis, was
Trainer heute schon nutzen (kein „Wegnehmen und zurückverkaufen“ —
zerstört Vertrauen im Aufbau-Markt):

- Trainer-Profil in der Suche (Liste + Karte)
- 1:1-Chat mit verbundenen Klienten
- Basis-Terminverwaltung (heutiger Stand)
- Ansehen geteilter Reflexprofile/Fortschritte (heutiger Stand)

**Bezahlt wird nur NEUER Wert.**

## 2. Feature-Kandidaten (priorisiert — Ranking in Phase 1 validieren)

**Kern (v1-Kandidaten):**
1. **Klienten-Cockpit:** strukturierte Verlaufsansicht pro Klient
   (Trainings-Frequenz, Paket-Fortschritt, Stimmungstrend), Sitzungs-Notizen.
   ⚠️ Rechtlich heikelster Teil — Notizen über Klienten-Gesundheitszustand:
   Verantwortlichkeits-Konstruktion klären (s. Abschnitt 5).
2. **Termin-Plus:** automatische Termin-Erinnerungen an Klienten (Push),
   Kalender-Export (.ics), Wiederholungstermine.
3. **Praxis-Übersicht:** aggregierte Statistik (aktive Klienten,
   Trainings-Aktivität der Woche, offene Anfragen).

**Später (v2+):** Profil-Extras (mehrere Fotos, Vorstellungsvideo),
Warteliste/Kapazitäts-Anzeige, Vorlagen für Übungsempfehlungen.

**Bewusst NICHT:** bezahltes Ranking in der Suche (P2B-Transparenzpflichten
+ Vertrauensschaden; falls je erwogen: klar als „gesponsert“ kennzeichnen).

## 3. Preis-Hypothese

12–19 €/Monat, Jahreszahlung mit Rabatt. **Gründungs-Trainer dauerhaft
~50 % vergünstigt** — sauber abgrenzbar vom Gratis-Versprechen (das nur
Eintrag/Sichtbarkeit betrifft) und ein starkes Akquise-Argument im Pilot:
„Als Gründungs-Trainer: Eintrag für immer gratis, Studio für immer zum
halben Preis.“ Preisvalidierung in Phase 1 (Interviews), nicht raten.

## 4. Kaufweg (wichtigste Architektur-Entscheidung)

**Empfehlung: Web-Checkout auf reflexjourney.app (Stripe Billing, B2B) —
Entitlement wird server-seitig in `trainer_profiles` gesetzt, die App
schaltet nur frei.** Begründung: (a) B2B-SaaS wird üblich per Rechnung/Web
verkauft; (b) Apple 3.1.3(b) „Multiplatform Services“ erlaubt das Nutzen
extern gekaufter Abos in der App, solange die App **nicht** auf den
externen Kauf verlinkt/hinweist (kein Steering — die App zeigt nur
„Studio aktiv/inaktiv“); (c) spart 15–30 % Apple-Provision; (d) einfaches
Stripe Billing, KEIN Stripe Connect (D5-Entscheidung unberührt — es
fließt weiterhin kein Klienten-Geld über uns, nur unsere eigene
SaaS-Rechnung an Trainer). Alternative (falls Apple-Weg gewünscht):
eigenes IAP-Abo — in der Design-Session final entscheiden.

Technisch: Entitlement-Muster aus T23 wiederverwenden —
`trainer_profiles.studio_active` (+ valid_until) mit Schutz-Trigger
(nur service_role, gesetzt vom Stripe-Webhook), Flag-gated bauen.

## 5. Offene Rechtsfragen (zum Anwalt, wenn T27 startet — NICHT im R1-Paket)

1. **AVV-Konstruktion Klienten-Notizen:** Wenn Trainer in unserer App
   strukturierte Notizen über Klienten führen, ist der Trainer
   Verantwortlicher und wir sein Auftragsverarbeiter → wir brauchen einen
   AVV MIT jedem Trainer + technische Mandantentrennung (RLS kann das).
   Das ist die zentrale juristische Weiche für Feature 1.
2. **B2B-AGB** fürs Studio-Abo (Rechnung, Kündigung, Verfügbarkeit).
3. **P2B-VO-Check** (gilt ggf. schon für die kostenlose Vermittlung).
4. USt/Rechnungsstellung (Steuerberater).

## 6. Trigger & Phasen

**Start-Trigger (alle drei):** Launch stabil · Trainer-Akquise-Pilot
ausgewertet · ~10+ aktive Trainer.

1. **Phase 1 — Validierung (1–2 Wochen):** 3–5 Gründungs-Trainer-Interviews;
   Feature-Ranking + Preispunkt bestätigen; Kaufweg-Entscheidung.
2. **Phase 2 — Design-Session:** v1-Scope schneiden (max. 2 Kern-Features),
   Anwalts-Paket (Abschnitt 5) beauftragen.
3. **Phase 3 — Build:** Flag-gated (`kTrainerStudioEnabled`),
   T23-Entitlement-Muster, Stripe-Billing-Webhook.
4. **Phase 4 — Pilot-Pricing:** Launch nur für Gründungs-Trainer
   (vergünstigt), 4–8 Wochen Feedback, dann allgemein.

## 7. Ehrliche Umsatz-Einordnung

Nische: 30 zahlende Trainer × ~15 €/Monat ≈ 450 €/Monat, bei 100 Trainern
~1.500 €. Das Studio ist **Bindungs- und Ökosystem-Werkzeug** (Trainer
bleiben aktiv → Nutzer bekommen Betreuung → Nutzer-Abos halten), kein
eigenständiger Umsatzmotor. Erwartung entsprechend setzen.
