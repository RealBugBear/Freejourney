# Monetization + Trainer Studio — Master Execution Prompt

**Stand:** 2026-07-19
**Zweck:** Ein Einstiegsprompt für den vollständigen Weg von Founder-
Entscheidungen über Apple/Android-Payments bis Trainer-Studio-Pilot.
**Modus heute:** T25.0 ist lokal abgeschlossen. T25.1 bleibt durch X3
blockiert; der nächste ausführbare Punkt ist Studio-P0. Kein Live-/Portal-/
Aktivierungs-Go allein durch die Existenz dieses Dokuments.

## 1. Source of Truth

Bei Widerspruch gilt diese Reihenfolge:

1. `CLAUDE.md` und `docs/LAUNCH_MASTER_PROMPT.md` für Arbeits-/Safety-Regeln;
2. `docs/PAYMENTS_MASTER_PLAN.md` für Commerce, Stores und Entitlements;
3. `docs/PAYMENTS_BUILD_PROMPTS.md` für T25-Ausführung;
4. `docs/superpowers/specs/2026-07-08-trainer-studio-design.md` für Produkt/UX;
5. `docs/TRAINER_STUDIO_PROMPT.md` für Discovery-/Readiness-Gates;
6. `docs/TRAINER_STUDIO_BUILD_PROMPTS.md` für T27-Ausführung;
7. dieser Statusblock für Reihenfolge;
8. `docs/MONETARISIERUNG_EVALUATION.md` und `docs/TRAINER_TOOL_PLAN.md` nur als
   historische Begründung, nicht als aktuelle Architektur.

## 2. Nicht verhandelbare Regeln

1. Eine Session bearbeitet genau **einen** Statuspunkt/Task.
2. Nie Entscheidung, externen Accountzustand oder Founder-Go erfinden.
3. Vor jedem Task aktuelle Code-Realität und zuständige Primärquellen prüfen;
   Store-/Gebühren-/SDK-Angaben können sich ändern.
4. Keine Live-DDL, Deploys, Store-/RevenueCat-Mutation, Aktivierung,
   Kommunikation oder `git push` ohne die dafür vorgesehene ausdrückliche
   Freigabe.
5. Bestehende Useränderungen im Dirty Worktree erhalten; nur explizite Dateien
   anfassen und lokale Commits mit bewusster Dateiliste.
6. Keine PII, Secrets oder echten Klientendaten in Chat/Repo/Evidenz.
7. Kein ✅ ohne beobachteten Beleg; externer Zustand bekommt Screenshot oder
   redigierte Bestätigung.
8. Kein Code vor dem jeweiligen Gate. Fertige Build-Prompts heben Gates nicht
   auf.
9. Serverseitige Berechtigung kommt aus effektiven Multi-Grants; nie aus einem
   einzelnen `premium_type`, `studio_source` oder Client-CustomerInfo.
10. Compile-Flag ist kein echter Kill Switch; Sales- und Feature-Rollout sind
    serverseitig getrennt.

## 3. Persistenter Status

Statuswerte: `☐ offen · 🔄 in Arbeit · ✅ erledigt (+ Beleg) · ⛔ blockiert:
Grund · ⏸ wartet auf Gate`.

### Entscheidungen

| ID | Status |
|---|---|
| PM-D1–PM-D12 Payments/Codes/Rollout-Regel | ✅ 2026-07-19 — wie empfohlen freigegeben; Preise bleiben Hypothesen; Live-/Portal-/Aktivierungsgates separat |
| TS-6–TS-11 Studio/Free MVP | ✅ 2026-07-19 — wie empfohlen freigegeben; TS-8 und finale Free-MVP-Daten bleiben bis Research/Pilotplanung Hypothesen |
| R8 Bestandsschutz Nutzer | ☐ Founder-Freigabe offen |

### Externe Grundlagen

| ID | Status |
|---|---|
| X1 ASC App Record + Paid Apps/Tax/Banking | ⛔ extern: Founder |
| X2 Apple Small Business Status | ⛔ extern: Founder |
| X3 RevenueCat Projekt | ⛔ extern: Founder |
| X4 Google Accounttyp/D-U-N-S-Entscheid | ⛔ extern: Founder |
| X5 Play Console App/Payments/Tests | ⛔ extern: Founder |

### Aktueller Legal-/Discovery-Pfad

| ID | Status |
|---|---|
| L0 bestehendes `trainer_notes`/`mood_checkins` im Launch-Briefing | ⛔ extern: Plantext ergänzt, anwaltliche Antwort/Einordnung ausstehend |
| P0 Founder-Review Studio-Spec | ☐ offen |
| P1 Problem-Interviews | ☐ offen |
| P2 Low-Fi-Konzepttest | ☐ offen |
| P3A Daten-/Rechts-Entscheid | ☐ offen |
| P3B Store-/Pricing-Entscheid | ⏸ parallel möglich; Pflicht vor P4B |
| P4A Free-MVP-Build-Readiness | ⏸ wartet auf P0–P3A; T25.0 lokal erfüllt |
| P4B Paid-Pilot-Readiness | ⏸ wartet auf Free-MVP-Auswertung + P3B + T25.5 |

### Payments

| Task | Status |
|---|---|
| T25.0 Multi-Grant-/Benefit-Code-Fundament | ✅ 2026-07-19 lokal implementiert/verifiziert — `docs/evidence/T25.0/README.md`; kein Live-Apply/Deploy |
| T25.1 RevenueCat Core + Test Store | ⛔ blockiert: X3 RevenueCat-Projekt |
| T25.2 Webhook + Reconciliation | ⏸ wartet auf T25.1 + X3 |
| T25.3 Apple IAP | ⏸ wartet auf T25.1/T25.2 + X1 |
| T25.4 Google Play Billing | ⏸ wartet auf T25.1/T25.2 + X4/X5 |
| T25.5 Operations/Activation Readiness | ⏸ wartet auf T25.1–T25.4 |
| Nutzer-Paywall-Aktivierung | ⏸ wartet auf T25.5 + R8 + Legal + Founder-Go |

### Trainer Studio

| Task | Status |
|---|---|
| T27.1 Studio-Entitlement/Rollout | ⏸ wartet auf P4A; T25.0 lokal erfüllt |
| T27.2 kostenlose Kohorten-UX | ⏸ wartet auf T27.1 + P2 |
| T27.3 Klienten-Briefing | ⏸ wartet auf T27.1 + P3A-Matrix/Legal |
| T27.4 Termin-Automation | ⏸ wartet auf T27.1 |
| T27.5 Sitzungsprotokolle | ⏸ wartet auf TS-9 + volles Legal/Security-Go |
| T27.6A kostenloser MVP-Pilot | ⏸ wartet auf T27.1–T27.4 + Aktivierungs-Go |
| T27.6B Paywall/bezahlter Pilot | ⏸ wartet auf Free-MVP-Auswertung + P4B + T25.5 |
| Studio-GA | ⏸ wartet auf Pilot-Auswertung + Founder-Go |

## 4. Auswahlalgorithmus für den nächsten Task

Die Session wählt genau einen Punkt:

1. Sind PM-/TS-Entscheidungen offen? Lege dem Founder das Entscheidungspaket
   wörtlich vor und stoppe. Keine Implementierung.
2. Ist eine notwendige Founder-Portalaktion der einzige Blocker des nächsten
   technischen Tasks? Erstelle/verwende die exakte gemeinsame Klickcheckliste;
   mutiere Portale nur interaktiv mit Founder-Go.
3. Ist T25.0 noch offen und freigegeben? Das Multi-Grant-/Benefit-Fundament hat
   Priorität vor Store- oder Studio-Code.
4. Während X1–X5 blockieren, arbeite den nächsten offenen P0–P3B-
   Discoverypunkt; Wartezeit wird so genutzt, Gate aber nicht gestrichen.
5. Nach T25.0 und P0–P3A: P4A. Nur P4A-GO öffnet Free-MVP-Build/T27.6A.
6. P3B und T25.1–T25.5 laufen parallel weiter; erst Free-MVP-Auswertung +
   P3B + T25.5 öffnen P4B und den bezahlten T27.6B-Pilot.
7. Danach T27-Reihenfolge aus `TRAINER_STUDIO_BUILD_PROMPTS.md`.
8. T27.5 nie automatisch auswählen; nur nach eigenem dokumentierten Go.
9. Pilot-/GA-Aktivierungen nie automatisch auswählen.

Wenn mehrere Tasks unblocked sind, Priorität: Security/Legal-Istproblem →
T25.0-Fundament → Studio-Discovery → Free-MVP-Build → Payment-Store-E2E →
Free-MVP-Aktivierung → Paid-Readiness.

## 5. Startanweisung — diesen Block in eine frische Session einfügen

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Arbeite als Orchestrator für Monetization + Trainer Studio. Lies vollständig:
CLAUDE.md, docs/LAUNCH_MASTER_PROMPT.md,
docs/MONETIZATION_STUDIO_MASTER_PROMPT.md,
docs/PAYMENTS_MASTER_PLAN.md,
docs/PAYMENTS_BUILD_PROMPTS.md,
docs/TRAINER_STUDIO_PROMPT.md,
docs/TRAINER_STUDIO_BUILD_PROMPTS.md und
docs/superpowers/specs/2026-07-08-trainer-studio-design.md.

Prüfe danach den Statusblock gegen Tracker, Code und vorhandene Evidenz.
Korrigiere keinen Status ohne Beleg. Bestimme nach dem Auswahlalgorithmus genau
den nächsten unblocked Punkt, kündige ihn an und bearbeite nur diesen Punkt.

Falls eine Founder-Entscheidung oder externe Portalaktion fällig ist: lege die
konkrete Empfehlung/Checkliste vor und stoppe vor jeder Mutation, bis das
explizite Go vorliegt. Falls ein Build-Task fällig ist: nutze seinen
kopierfertigen Prompt bzw. Taskvertrag, erfülle Tests/Evidenz, aktualisiere
Masterstatus + LAUNCH_TASK_PROMPTS/Backlog konsistent und gib am Ende den
nächsten fälligen Prompt wörtlich aus.

Fertige Prompts sind keine Freigabe. Keine Live-DDL, Deploys, Store-/RevenueCat-
Änderungen, Aktivierung, externe Kommunikation oder git push ohne separates Go.
```

## 6. Erste Founder-Antwort

Wenn die Empfehlungen passen, reicht:

> „GO PM-D1 bis PM-D12 und TS-6 bis TS-11 wie empfohlen. Preise, TS-8 und die
> finalen Free-MVP-Daten bleiben bis Research/Pilotplanung Hypothesen.
> Live-/Portal-/Aktivierungsgates bleiben separat.“
>
> PM-D12 (serverseitige Rollout-Zustände = bewusste Abweichung von der
> CLAUDE.md-Regel „No remote config") kann auch einzeln abgelehnt werden —
> dann bleiben Compile-Flags die einzige Gate-Mechanik und der Kill Switch
> braucht ein Store-Update.

Zum Zeitpunkt dieser Freigabe war T25.0 der erste technische Task; er ist
inzwischen lokal abgeschlossen. Während X3 den nächsten Payment-Task blockiert,
ist P0 der nächste ausführbare Discoverypunkt.

## 7. Session-Abschlussvertrag

Jede Session endet mit:

- Outcome und beobachteter Evidenz;
- geänderte Dateien;
- Tests/Checks und Ergebnis;
- nicht ausgeführte gated Actions;
- aktualisierte Statuszeile hier und im Tracker;
- exakt ein nächster Prompt oder eine konkrete Founder-Aktion;
- kein pauschales „alles fertig“, solange ein Pflichtgate offen ist.
