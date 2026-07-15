# Trainer Studio (T27) — Planning Master Prompt & Status

**Stand:** 2026-07-10
**Modus:** Planung/Validierung. Kein Produktivcode, keine Migrationen, keine
Store-/RevenueCat-Änderungen, bis Build-Readiness und Founder-Go dokumentiert
sind.
**Product Source of Truth:**
`docs/superpowers/specs/2026-07-08-trainer-studio-design.md`
**Gesamt-Orchestrierung:** `docs/MONETIZATION_STUDIO_MASTER_PROMPT.md`
**Vorbereitete Build-Prompts:** `docs/TRAINER_STUDIO_BUILD_PROMPTS.md`

Dieses Dokument steuert das Vorhaben phasenweise. Der frühere Entwurf sprang
von einer groben Feature-Idee direkt in sechs Build-Sessions. Diese Fassung
setzt Research, UX-Test, Recht/Daten und Store-Mechanik davor und konkretisiert
Build-Tasks erst, wenn die offenen Entscheidungen gefallen sind.

## Harte Regeln

1. Vor jeder Phase `CLAUDE.md`, `docs/LAUNCH_MASTER_PROMPT.md`, diese Datei und
   nur die für die Phase genannten Quellen lesen.
2. Pro Session genau eine Phase bearbeiten; Status und Evidenz am Ende
   aktualisieren.
3. Keine personenbezogenen Interviewdaten, echten Klientendaten oder Secrets in
   Chat, Repo, Screenshots oder Logs.
4. Keine Heil-/Wirkversprechen, Diagnosen, Risiko-Scores oder garantierten
   Reminder-/ROI-Aussagen.
5. Was heute kostenlos klickbar ist, bleibt kostenlos.
6. Rechts- und Store-Aussagen als Hypothesen kennzeichnen und mit aktuellen
   Primärquellen prüfen.
7. Produktivcode, DDL, Deploys, App Store Connect, RevenueCat, Flag-Aktivierung,
   externe Kommunikation und `git push` brauchen den jeweils vorgesehenen
   Founder-Go.
8. Kein ✅ ohne beobachtbares Ergebnis und redigierte Evidenz.

## Status

| Abschnitt | Status |
|---|---|
| P0 — Founder-Review dieser Spec | ☐ offen |
| P1 — Problem-Interviews | ☐ offen |
| P2 — Low-Fi-Konzept + Usability-Test | ☐ offen |
| P3A — Daten-/Rechts-Entscheid | ☐ offen |
| P3B — Store-/Pricing-Entscheid | ⏸ darf parallel laufen; Pflicht vor P4B |
| P4A — Free-MVP-Build-Readiness | ⏸ wartet auf P0–P3A + T25.0 |
| P4B — Paid-Pilot-Readiness | ⏸ wartet auf Free-MVP-Auswertung + P3B + T25.5 |
| T27.1 — Entitlement + Rollout-Fundament | ⏸ wartet auf P4A + T25.0 |
| T27.2 — Studio-Einstieg + kostenlose Kohorten-UX | ⏸ wartet auf P4A + T27.1 |
| T27.3 — Klienten-Briefing | ⏸ wartet auf P4A + T27.1 |
| T27.4 — Termin-Automation | ⏸ wartet auf P4A + T27.1 |
| T27.5 — Sitzungsprotokolle (optional) | ⏸ wartet auf Legal-/Security-Go |
| T27.6A — kostenloser MVP-Pilot | ⏸ wartet auf P4A + T27.1–T27.4 |
| T27.6B — Store-Paywall + bezahlter Pilot | ⏸ wartet auf P4B + T25.5 |
| Studio GA | ⏸ wartet auf Paid-Pilot-Auswertung + Founder-Go |

Statuswerte: `☐ offen · 🔄 in Arbeit · ✅ erledigt (+ Evidenz) · ⛔ blockiert:
<Grund> · ⏸ wartet auf <Gate>`.

## Startanweisung für eine frische Session

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app
Lies CLAUDE.md, docs/LAUNCH_MASTER_PROMPT.md,
docs/TRAINER_STUDIO_PROMPT.md und
docs/superpowers/specs/2026-07-08-trainer-studio-design.md vollständig.
Bestimme den ersten offenen Planungsabschnitt P0–P4B. Kündige ihn an, setze nur
diesen Abschnitt auf 🔄 und führe exakt seinen Prompt aus. Kein Produktivcode,
keine Migration, kein Deploy und keine Store-Konfiguration vor dokumentiertem
P4A-/P4B-Go.
```

## P0 — Founder-Review

**Ziel:** Die Produktausrichtung ist verstanden und die offenen
Founder-Entscheidungen TS-6 bis TS-11 sind sichtbar, ohne sie vorwegzunehmen.

**Aufgabe:**

1. Spec als kurze Entscheidungsvorlage zusammenfassen: Problem, Zielgruppe,
   v1-Fähigkeiten, Nicht-Ziele, Gates.
2. Founder bestätigt oder korrigiert North Star, Zielgruppe und die Regel
   „Briefing + Termin-Automation; Notizen separat“.
3. Bestehende externe Versprechen zum Gründerpreis inventarisieren. Nichts
   Neues kommunizieren.
4. Ergebnis als datierten Founder-Entscheid in der Spec dokumentieren.

**Output:** P0-Notiz unter `docs/evidence/T27/planning/founder_review.md` ohne
Implementierungsauftrag.

## P1 — Problem-Interviews

**Ziel:** Belegen, welche Arbeitsprobleme häufig, teuer oder emotional belastend
sind, bevor Features präsentiert werden.

**Lies:** Spec §2, §10 und bestehende Akquise-/Trainer-Research-Dokumente.

**Aufgabe:**

1. Einseitigen Interviewleitfaden und neutralen Einladungstext erstellen.
2. 5–7 passende Trainer rekrutieren; Founder führt 20–30-Minuten-Gespräche.
3. Nur anonymisierte Befunde dokumentieren: beobachtetes Verhalten, Häufigkeit,
   heutige Alternative, Schmerzstärke, Datenschutzgrenze, Preisantworten.
4. Widersprechende Befunde ausdrücklich erhalten.
5. Empfehlung: unverändert weiter / Problem neu schneiden / stoppen.

**Gate:** Mindestens fünf verwertbare Gespräche oder klar dokumentieren, warum
die Evidenz für eine Scope-Entscheidung noch nicht reicht.

**Output:** `docs/evidence/T27/planning/problem_interviews.md`.

## P2 — Low-Fi-Konzept und Usability-Test

**Ziel:** Die vier Kernaufgaben funktionieren als klickbarer oder
papierähnlicher Low-Fi-Ablauf, bevor Flutter-Code entsteht.

**Lies:** Spec §4–§6, aktueller `trainer_dashboard_screen.dart` und
`trainer_client_detail_screen.dart` nur zur Ist-Orientierung.

**Aufgabe:**

1. Zustände entwerfen: Start, Briefing, Verlauf, Terminserie, Reminder,
   Paywall, leer, offline, Fehler, Freigabe beendet.
2. Mit fiktiven Daten einen Low-Fi-Prototyp erstellen; keine Produktions-UI.
3. Fünf Trainer führen die vier Aufgaben aus Spec §10 ohne Erklärung durch.
4. Erfolgsquote, Fehlklicks, Missverständnisse und sensible Stellen notieren.
5. Informationsarchitektur und Copy iterieren, bis keine kritische
   Fehlinterpretation mehr offen ist.

**Gate:** Mindestens 4/5 lösen jede Kernaufgabe ohne Hilfe; sonst P2 bleibt
offen und wird iteriert.

**Output:** `docs/evidence/T27/planning/concept_test.md` + redigierte Screens.

## P3A — Daten und Recht

**Ziel:** Die bisher spekulativen Stellen werden vor Architekturentscheidungen
geschlossen.

**Aufgabe A — Datenvertrag:**

1. Für jede Anzeige Quelle, Zeitraum, Beziehung/Freigabe, RLS, Entzug,
   Offline-Verhalten und Löschung erfassen.
2. Code-Ist belegen: `get_client_sessions` (30 Tage), Mood-Query (Notizfilter +
   Limit), Paket-Historie, Appointment-Subject-Modell, Reminder-Infrastruktur.
3. Lücken als Anforderungen beschreiben, nicht vorzeitig implementieren.

**Aufgabe B — Recht/Datenschutz:**

1. Separates, versandfertiges Anwalts-Briefing erstellen; Rollen nicht
   vorwegnehmen.
2. Bestehendes `trainer_notes` und heutige Mood-Freigabe als dringenden
   Ist-Zustand behandeln.
3. Notizen-Go umfasst Rollen/Verträge, Transparenz, Retention, Export/Löschung,
   Sicherheitsmaßnahmen und DSFA-Entscheid.

**Outputs:**

- `docs/evidence/T27/planning/data_contract_matrix.md`
- `docs/legal/ANWALTS_BRIEFING_STUDIO.md`

## P3B — Store und Pricing

P3B darf parallel zu Free-MVP-Build/Pilot laufen. Es blockiert P4B, nicht P4A.

**Aufgabe:**

1. Aktuelle Apple-Guidelines, Trial-Regeln, Subscription Groups, sichtbare
   Produktnamen, Offer Codes und Small Business Program aus Primärquellen
   prüfen.
2. Android explizit entscheiden; „RevenueCat“ nicht mit „nur Apple“
   gleichsetzen.
3. Drei realistische Gründerpreis-Mechaniken mit Risiken gegenüberstellen.
4. StoreKit-Preis/Trial-Berechtigung als UI-Quelle festlegen; keine
   hardcodierten Preise.
5. Vollkostenvergleich ohne vereinfachte Apple-vs.-Stripe-Prozentrechnung.

**Founder-Gates:** TS-6 Gründer-Vorteil, TS-7 Plattform, TS-9 Notizenrichtung,
TS-10 Preis/Trial.

**Output:** `docs/evidence/T27/planning/store_pricing_decision.md`

## P4A — Free-MVP-Build-Readiness

**Ziel:** Nüchterner GO/NO-GO-Entscheid für Bau und späteren kostenlosen,
geschlossenen MVP. Erst ein GO autorisiert T27.1–T27.4.

**Prüfung:**

- P0–P2 und P3A abgeschlossen;
- T25.0 Multi-Grant-/Benefit-Code-Fundament abgeschlossen;
- 3–5 erreichbare Design-/Pilottrainer;
- P1/P2 abgeschlossen und v1-Scope TS-8 bestätigt;
- P3A-Datenvertrag und aktuelle Datenflüsse freigegeben;
- kein offenes Legal-/Security-Problem, das Briefing oder Termin-Automation
  blockiert;
- kostenlose Pilotkohorte, festes Enddatum, Supportweg, Nutzungs-Messplan und
  getrennte Sales-/Feature-Rollouts definiert.

Apple-/Google-Storeprodukte und T25.5 sind kein Free-MVP-Build-Gate.

**Output:** `docs/evidence/T27/planning/free_mvp_build_readiness.md` mit
GO/NO-GO je Kriterium.

## P4B — Paid-Pilot-Readiness

**Ziel:** Nach Auswertung des kostenlosen MVP entscheiden, ob Zahlungs-
bereitschaft getestet werden soll.

**Prüfung:**

- kostenloser T27.6A-Pilot abgeschlossen und real genutzt;
- mindestens drei Trainer nutzen Kernfunktionen wiederholt;
- P3B Store-/Pricing-Entscheid abgeschlossen;
- T25.5 mit Apple-/Google-E2E abgeschlossen;
- Launch ≥ 4 Wochen stabil, kein offener P0;
- TS-6/7/8/10 final; Paid-Pilot-Preis/Trial/Plattform beschlossen;
- Store-/Legal-/Support-/Kill-Switch-Readiness belegt.

**Output:** `docs/evidence/T27/planning/paid_pilot_readiness.md`. Nur ein GO
öffnet T27.6B. Der kostenlose Pilot wandelt sich nie automatisch um.

## Build-Workstreams — nach dem jeweiligen P4A-/P4B-Go ausführen

Die IDs, Ergebnisse und kopierfertigen Prompts stehen in
`docs/TRAINER_STUDIO_BUILD_PROMPTS.md`. P4A öffnet T27.1–T27.4 und T27.6A;
P4B öffnet T27.6B. Eine Session arbeitet genau einen Workstream ab.

### T27.1 — Entitlement + Rollout

Ergebnis: Studio auf dem Multi-Grant-Ledger, Restore-/Ablauf-Semantik,
getrennter Sales-/Feature-Rollout. Keine UI.

### T27.2 — Einstieg + kostenlose Kohorten-UX

Ergebnis: getesteter Studio-Einstieg nur für die kostenlose Pilotkohorte,
transparentes Enddatum, keine Paywall oder automatische Umwandlung.

### T27.3 — Klienten-Briefing

Ergebnis: „Seit letztem Termin“ und freigegebene Verläufe nach der
Datenvertragsmatrix, einschließlich Entzug/Empty/Offline/Accessibility.

### T27.4 — Termin-Automation

Ergebnis: Serien, Vorschau, Terminzeitzone, idempotente Reminder, Opt-out,
Quiet Hours und `.ics`; keine Behauptung garantierter Zustellung.

### T27.5 — Sitzungsprotokolle

Optional. Wird nur geplant und gebaut, wenn TS-9 plus vollständiges
Legal-/Security-Go vorliegen. Ein Feature-Flag allein ist kein ausreichendes
Schutzkonzept.

### T27.6A/B — kostenloser MVP, dann Store + Paid Pilot

T27.6A: befristete Pilotkampagne ohne Store/Auto-Billing. T27.6B erst nach
P4B/T25.5: Paywall, Produkte/Offerings, Sandbox-E2E, App-Review-Unterlagen und
bezahlter Founding-Pilot. Jede Aktivierung/Kommunikation separat Founder-gated.

## Pilot-/GA-Gate

Stufe A: 3–5 Trainer 6–8 Wochen kostenlos, befristeter Pilotgrant, keine
automatische Belastung. Stufe B: nur nach P4B-GO 5–10 Trainer mit aktivem
Storekauf/Trial. GA nur bei wiederholter realer Nutzung, Zahlungsbereitschaft,
vertretbarem Support und keinem offenen Trust-/Legal-Risiko. Notizen haben ein
eigenes Gate.

## Stoppbedingungen

- Problem-Interviews widerlegen den angenommenen Nutzen;
- Konzepttest zeigt wiederholt Missverständnisse über Freigaben oder Daten;
- aktueller Code/Datenfluss widerspricht der Spec;
- Store-Mechanik kann Gründer-Versprechen nicht zuverlässig tragen;
- Legal-/Security-Lücke betrifft bereits das kostenlose Produkt;
- Build-Trigger oder Founder-Go fehlt.

In jedem Fall: Status ehrlich aktualisieren, Befund dokumentieren und keine
stillschweigende Ersatzentscheidung treffen.
