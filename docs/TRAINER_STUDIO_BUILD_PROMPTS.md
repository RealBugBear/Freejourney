# Trainer Studio — ausführbare Build-Prompts T27.1–T27.6B

**Stand:** 2026-07-19
**Status:** Prompts fertig; Ausführung wartet auf P4A-/P4B-Go und jeweilige Gates
**Product Source of Truth:**
`docs/superpowers/specs/2026-07-08-trainer-studio-design.md`
**Discovery/Gates:** `docs/TRAINER_STUDIO_PROMPT.md`
**Payments/Entitlements:** `docs/PAYMENTS_MASTER_PLAN.md`
**Orchestrator:** `docs/MONETIZATION_STUDIO_MASTER_PROMPT.md`

Die Prompts existieren jetzt vollständig, damit nach einem Gate keine neue
Planungsrunde nötig ist. Ihre Existenz hebt kein Gate auf. Insbesondere werden
P1–P3B nicht in einen Build-Task verschoben: P4A braucht Research,
Konzepttest, Datenvertrag und Recht; P4B zusätzlich Store/Pricing.

## 1. Founder-Entscheidungspaket

> **Founder-Entscheid 2026-07-19:** TS-6–TS-11 wie empfohlen freigegeben.
> TS-8 und die finalen Free-MVP-Daten bleiben bis Research/Pilotplanung
> Hypothesen. Live-/Portal-/Aktivierungsgates bleiben separat; insbesondere
> ist dies kein P4A-/P4B-Go.

### TS-6 — Gründer-Vorteil

**Empfehlung:** Startpreis-Grandfathering gemäß Payments Plan PM-D5. Copy nur:

> „Als Gründungs-Trainer behältst du deinen Startpreis, solange dein Abo aktiv
> bleibt.“

Kein Prozent- oder Wiederanmeldeversprechen.

### TS-7 — Plattformen

**Freigegebene Auslegung:** Eine plattformneutrale Codebasis für iPhone, iPad,
Android Phone und Tablet. Der kostenlose geschlossene MVP darf iOS-first
starten; Android folgt, sobald der Build stabil verfügbar ist. Ein späterer
bezahlter Pilot startet iOS-first; Android folgt unmittelbar nach T25.4-E2E.
GA erst, wenn beide Plattformen die jeweilige Store-Testmatrix erfüllen,
sofern der Founder Android nicht ausdrücklich als Fast-Follow kommuniziert.

### TS-8 — v1-Scope

Vorläufig: Klienten-Briefing + Termin-Automation. Final nach P1/P2. Die
Arbeitsübersicht ist Einstieg/Komposition, kein drittes Premium-Feature.

### TS-9 — Sitzungsprotokolle

Separater optionaler Workstream. Kein Build und keine Sichtbarkeit ohne das
vollständige Legal-/Security-Gate aus der Spec.

### TS-10 — Preis/Trial

Standard 14,99 €/Monat, 119,99 €/Jahr, 14-Tage-Trial; Gründer-Startpreis z. B.
7,99 €/Monat, 69,99 €/Jahr. Alles Research-Hypothesen bis P1 und Storeprüfung.

### TS-11 — Kostenloser erster MVP

**Empfehlung:** 3–5 Trainer starten 6–8 Wochen kostenlos über befristete
`pilot`-Grants. Festes Enddatum, keine Zahlungsdaten, kein Auto-Abo. Danach
separater aktiver Opt-in in den bezahlten Founding-Pilot.

Freigabesatz:

> „GO TS-6 bis TS-11 wie empfohlen; TS-8/TS-10/TS-11-Details bleiben bis
> Research bzw. Pilotplanung final offen.“

## 2. Voraussetzungen vor dem kostenlosen MVP-Build

- P0–P2 und P3A in `TRAINER_STUDIO_PROMPT.md` abgeschlossen;
- P4A = dokumentiertes Free-MVP-Build-GO;
- T25.0 abgeschlossen, insbesondere Multi-Grant-/Benefit-Code-Fundament;
- mindestens 3–5 erreichbare Design-/Pilottrainer;
- Datenvertragsmatrix durch Founder geprüft;
- bestehendes `trainer_notes`/`mood_checkins` rechtlich eingeordnet;
- TS-6/7/8/10/11 dokumentiert;
- T27.5 zusätzlich TS-9 + volles Legal-/Security-Go.

Apple-/Google-Produkte, RevenueCat-Webhooks und T25.5 sind **nicht** nötig, um
das Studio für eine kostenlose geschlossene Kohorte zu bauen/testen. Sie sind
Voraussetzung für T27.6B, den bezahlten Founding-Pilot.

## 3. Gemeinsame Regeln aller Prompts

1. Eine Session bearbeitet genau einen Task.
2. Vor Arbeit: `CLAUDE.md`, `docs/LAUNCH_MASTER_PROMPT.md`, relevante Spec-
   Abschnitte und aktuellen Taskstatus lesen.
3. Keine Live-DDL, Deploys, Store-/RevenueCat-Änderungen, Aktivierung,
   Kommunikation oder `git push` ohne jeweiliges Founder-Go.
4. Zwei Gates:
   - Compile-Flag als Release-Sicherung;
   - getrennte serverseitige `sales_rollout`-/`feature_rollout`-Zustände aus
     dem Payments Plan.
5. Vor öffentlichem Launch bedeutet Feature-Rollout aus heutiges Verhalten.
   Nach bezahltem Launch stoppt `sales_rollout=off` nur neue Käufe; gültige
   Käufe/Grants bleiben zugänglich. Incident-Abschaltung ist separat.
6. Bestehendes Kostenloses bleibt kostenlos.
7. Studio-RPCs prüfen `effective_entitlements('studio')` serverseitig;
   RevenueCat CustomerInfo allein autorisiert keine sensiblen Daten.
8. Keine Wirk-, Diagnose-, Risiko-, ROI- oder Zustellgarantie-Aussagen.
9. DE/EN, Light/Dark, 150 % Text, 44-pt-Ziele und Empty/Loading/Offline/Error/
   Locked/Freigabe-beendet/abgelaufen gestalten.
10. Keine echten Personen-/Klientendaten in Evidenz. Suite, relevante
    RLS-Negativtests und Prod-Build vor ✅.

## 4. Kopierfertige Prompts

### T27.1 — Studio-Entitlement und Rollout

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Task: T27.1 — Studio-Entitlement und Rollout. Lies zuerst CLAUDE.md,
docs/LAUNCH_MASTER_PROMPT.md, docs/TRAINER_STUDIO_BUILD_PROMPTS.md §2–§4,
docs/PAYMENTS_MASTER_PLAN.md §3–§6 und §12 sowie die Premium-
Entitlement-Implementierung aus T25.0. Verifiziere P4A-GO und T25.0; sonst liefere
NO-GO und ändere nichts.

Baue Studio auf dem bestehenden Multi-Grant-Ledger auf; erfinde keine parallelen
studio_active/studio_source-Wahrheiten. Ergänze Entitlement-Key/Projektion nur,
falls T25 sie noch nicht vollständig liefert. Implementiere Flutter-Modell,
Repository und Provider für den effektiven serververifizierten Studio-Status
mit begrenztem Offline-Cache. Ergänze Compile-Release-Sicherung und getrennten
sales_rollout/feature_rollout für studio. Servergeschützte Studio-RPCs müssen
später denselben effektiven Status prüfen können.

Teste: kein Grant; aktives/abgelaufenes RevenueCat-Grant; befristeter
Reviewgrant; mehrere Grants; Sales-/Feature-Rollout; fremder Client
kann keinen Grant oder Rollout ändern; Compile-Flag aus = keine sichtbare
Änderung. Dokumentiere Kill-Switch-Semantik und Rollback. Live-DDL nur nach
separatem Founder-Go. Keine UI, keine Storeprodukte.
```

### T27.2 — Studio-Einstieg und kostenlose Kohorten-UX

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Task: T27.2 — Studio-Einstieg und kostenlose Kohorten-UX. Lies zuerst
CLAUDE.md, docs/LAUNCH_MASTER_PROMPT.md, die Spec §3–§6 und §13, P2-
Konzepttest-Evidenz, T27.1-Ergebnis sowie den Payments Plan PM-D5–PM-D10.
Verifiziere P4A-GO, T27.1 und bestandenen P2-Test; sonst NO-GO.

Setze exakt die getestete IA um: Arbeitsüberblick als Einstiegsschicht im
bestehenden Klienten-Tab, maximal drei neue Studio-Signale, kostenlose
Bestandsfunktionen frei. Bei feature_rollout=cohort sehen ausschließlich
Pilottrainer mit aktivem befristetem Grant die Studio-Einstiege; alle anderen
sehen exakt die bisherige UI, keine Paywall und kein „bald kostenpflichtig“.
Pilotstatus zeigt transparent „Kostenloser MVP bis <Datum> · keine automatische
Verlängerung“ sowie Feedback-/Supportweg. Kein künstlicher Countdown.

Teste Pilotgrant aktiv/abgelaufen/widerrufen, Kohorte/fremde Kohorte,
Sales-Rollout off, Feature-Rollout, Flag-aus-Regression, Gratisumfang nach Ablauf,
DE/EN, Light/Dark, iPhone/iPad/Android Phone/Tablet und Accessibility.
Keine Paywall/Storepreise, Briefing-Daten oder Termin-Automation bauen.
```

### T27.3 — Klienten-Briefing

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Task: T27.3 — Klienten-Briefing. Lies zuerst CLAUDE.md,
docs/LAUNCH_MASTER_PROMPT.md, Spec §5.2/§7/§13, die in P3A freigegebene
data_contract_matrix.md, get_client_sessions, aktuelle Trainer-Mood-Queries,
Relationship-/Share-RLS und T27.1. Fehlt Matrix/Founder-Sichtung/Legal-
Einordnung, melde NO-GO; verschiebe das Gate nicht in den Build.

Implementiere nur die freigegebenen Verträge. Serverseitige RPCs prüfen aktive
Trainer-Klient-Beziehung, konkrete Freigabe und effektives Studio-Entitlement.
Liefer „Seit dem letzten Termin“, 8-Wochen-Trainingsrhythmus und nur die
freigegebenen neutralen Befindensreihen. Keine Notiztexte in Trend-RPCs, kein
synthetischer Score, keine Prognose. Paketverlauf nur, wenn die Matrix eine
historisch belastbare Quelle bestätigt.

UI gemäß Spec: Identität/Stand/zwei Aktionen oberhalb des Folds, „seit letztem
Termin“ vor Charts, Quelle + Aktualität, <2 Datenpunkte als ehrlicher Empty-
State/Text statt Chart, Chart-Inhalt zusätzlich semantisch als Text. Bei
Beziehungs-/Freigabeende sofort kein Zugriff.

Pflichttests: fremder Trainer, beendete Beziehung, entzogenes Share, kein
Studio, abgelaufenes Studio, zwei Subjektprofile unter einem Elternkonto,
Zeitzone/letzter Termin, leere/lückenhafte Daten, Accessibility. Keine Notizen,
KI oder neue Datenkategorie außerhalb der Matrix.
```

### T27.4 — Termin-Automation

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Task: T27.4 — Termin-Automation. Lies zuerst CLAUDE.md,
docs/LAUNCH_MASTER_PROMPT.md, Spec §5.3/§7/§13, T27.1, appointment-Migrationen,
appointment_subject_profiles sowie die vorhandenen Tabellen/Functions
user_reminder_preferences, notification_jobs, schedule-training-reminders und
send-notification-jobs. Verifiziere P4A-GO und T27.1.

Erweitere die bestehende Reminder-Pipeline statt eines zweiten Push-Systems.
Plane die Migration bewusst: notification_jobs hat heute einen Type-CHECK und
einen Unique-Index (user_id,type,local_date), der mehrere Termin-Erinnerungen am
selben Tag blockieren würde. Passe das Modell additiv/sicher an (z. B. alter
Training-Dedupe als Partial Index; Appointment-Dedupe über stabilen
idempotency_key + appointment_id). Dokumentiere die konkrete Wahl.

Baue Serien wöchentlich/zweiwöchentlich mit Pflicht-Enddatum, Vorschau,
Zeitzone, gemeinsamer Serien-ID und klaren Regeln für „diesen Termin“ vs.
„diesen und folgende“. Bestehender Einzeltermin bleibt gratis. Reminder werden
nur für bestätigte zukünftige Termine, aktives Studio und Klienten-Opt-in
geplant; Termin-Opt-out getrennt von Trainingsremindern, Quiet Hours und
Push-Berechtigung respektieren. Änderungen/Absagen invalidieren alte Jobs
idempotent. Status nur geplant/nicht geplant/gesendet fehlgeschlagen, nie
zugestellt behaupten. .ics lokal via Share Sheet, kein device_calendar.

Teste doppelte Schedulerläufe, zwei Termine eines Nutzers am selben Tag,
Terminänderung/Absage, Serienänderung, DST, verschiedene Trainer-/Klienten-
Zeitzonen, Push aus, Quiet Hours, abgelaufenes Studio und Flag/Rollout aus.
Validiere .ics in Apple und Google Calendar. Deploy/Cron-Änderung separat
Founder-gated.
```

### T27.5 — Sitzungsprotokolle, optional

```text
Task T27.5 darf erst konkretisiert werden, wenn TS-9 und das vollständige
Legal-/Security-Go schriftlich vorliegen: Rollen/Verträge, Art.-9-/Kinderdaten,
Transparenztext, Retention, harte Löschung, Export/Berichtigung, Supportzugriff,
Security Review und DSFA-Entscheid. Fehlt ein Punkt: NO-GO, kein Schema und
keine UI.

Nach Go erstellt eine eigene Planning-Session zuerst einen Detailprompt aus der
anwaltlich freigegebenen Datenmatrix. Mindestprodukt: strukturierte Felder vor
Freitext, Sichtbarkeitshinweis, Autosave-Status, Export/Berichtigung/Löschung,
RLS-Negativtests. Keine Diagnose/ICD/KI. Ein Feature-Flag allein ist kein
Schutzkonzept.
```

### T27.6A — Kostenlosen MVP-Pilot vorbereiten/aktivieren

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Task: T27.6A — kostenloser Studio-MVP-Pilot. Lies CLAUDE.md,
docs/LAUNCH_MASTER_PROMPT.md, Spec §11–§12, Payments Plan PM-D11 und Evidenz
T27.1–T27.4. Gate: Free-MVP-Aktivierungs-Go, stabiler Core-Launch, freigegebene
Pilottexte, 3–5 Trainer; keine Store-/Payment-Voraussetzung.

Erstelle eine trainer_free_mvp-Benefitkampagne mit festem Start/Enddatum,
studio-Entitlement, single-use Codes oder expliziter Allowlist, Pro-Account-
Limit 1. Founder erzeugt/verteilt Codes über sicheres Runbook; keine Codes in
Repo/Chat. sales_rollout=off, feature_rollout=cohort. Keine Zahlungsdaten,
Storeprodukte, Trial- oder Auto-Renew-Sprache.

Pilotkommunikation muss sagen: kostenlos bis Datum X, keine automatische
Verlängerung/Belastung, heutige Gratisfunktionen bleiben, Feedback erwünscht,
späteres Bezahlangebot separat. Founder gibt Wortlaut und Versand einzeln frei.
Teste Grant/Expiry/Revoke/Kampagnenlimit und dass Ablauf nur Studio-MVP-Zugang,
nicht Gratisfunktionen oder Daten, betrifft. Messplan erfasst reale wiederholte
Nutzung und Arbeitsnutzen, nicht Zahlungsconversion. Aktivierung und Versand
separat Founder-gated.
```

### T27.6B — Store-Paywall, E2E und bezahlter Founding-Pilot

```text
Arbeitsverzeichnis: /Users/alexandermessinger/dev/claudvibes/corejourney/app

Task: T27.6B — Storekatalog, Paywall, E2E und bezahlter Founding-Pilot. Lies zuerst CLAUDE.md,
docs/LAUNCH_MASTER_PROMPT.md, Payments Plan §7–§10/§12, Spec §8/§12,
T25.5-Evidenz, Auswertung T27.6A und T27.1–T27.4. Verifiziere
TS-6/7/8/10/11, Paid-Pilot-Go und alle Gates.

Erstelle zunächst die Studio-Paywall aus dem getesteten Design: lokalisierte
Storepreise, Trial-Eligibility, Restore, Aboverwaltung, anderer Store ohne
Doppelkauf, Terms/Privacy; bestehendes Gratisprodukt bleibt frei. Danach eine
Founder-Klickcheckliste; Founder führt ASC/Play/RC-
Mutationen aus. Lege Studio-Produkte/Base Plans/Offers exakt nach finaler
Preisentscheidung an: eigene Apple Subscription Group, Google Subscription
mit monthly/yearly Base Plans, RevenueCat studio-Offering, Trial-Eligibility,
Family Sharing aus. Dokumentiere Gründer-Startpreis und spätere Preserve-/
Legacy-Cohort-Schritte, ohne die Preiserhöhung jetzt auszuführen.

Führe Sandbox/License-E2E aus: Monat/Jahr, Trial eligible/ineligible, Restore,
Kündigung bis Ablauf, Grace/Recovery, Refund soweit testbar, iOS↔Android,
anderer Store ohne Doppelkauf, Backend-Aktivierungswartezeit. App Review erhält
ein Demo-Konto mit ausschließlich fiktiven Klientendaten und präzise Review
Notes.

Bezahlter Pilot: 5–10 Trainer, 4–6 Wochen, bewusster neuer Opt-in per
Storekauf/Trial; kein automatischer Übergang aus T27.6A. Interne Reviewgrants
nur für Review/Test, nicht als Ersatz. Supportweg, Messplan mit absoluten Zahlen,
Kill-Switch-Probe und Weiter/Überarbeiten/Stoppen-Entscheid dokumentieren.
Kein Versand, keine Aktivierung und kein GA ohne separates Founder-Go.
```

## 5. Reihenfolge

```text
ENTSCHEIDE:  ✅ PM-D1–PM-D12 + TS-6–TS-11 (Hypothesen bleiben markiert)
FOUNDATION:  ✅ T25.0 lokal; Live-Apply/Deploy separat gegated
DISCOVERY:   P0 → P1 → P2 → P3A → P4A Free-MVP-GO
FREE MVP:    T27.1 → T27.2 + T27.3 + T27.4 → T27.6A → Auswertung
PAYMENTS:    P3B + T25.1 → T25.2 → T25.3 + T25.4 → T25.5 (parallel)
PAID PILOT:  P4B-GO → T27.6B → Auswertung → GA-Entscheid
SEPARAT:     T27.5 nur nach vollem Legal-/Security-Go
```

Parallelisierung ist erst erlaubt, wenn Abhängigkeiten erfüllt sind. Die
Orchestrator-Datei gibt immer nur den nächsten tatsächlich fälligen Prompt aus.
