# Trainer Studio — Product-, UX- und Delivery-Spec (T27)

**Stand:** 2026-07-10
**Status:** Founder-Review ausstehend — Planung, kein Build-Auftrag
**Owner:** Founder
**Verwandt:** `docs/TRAINER_STUDIO_PROMPT.md` ·
`docs/TRAINER_STUDIO_BUILD_PROMPTS.md` · `docs/PAYMENTS_MASTER_PLAN.md` ·
`docs/MONETIZATION_STUDIO_MASTER_PROMPT.md` · `docs/TRAINER_TOOL_PLAN.md`

> Diese Fassung ist der geprüfte Nachfolger des Entwurfs vom 2026-07-08. Sie
> behält die gute Grundidee, macht aber Research, Produktentscheidung,
> Rechtsprüfung und Build-Start zu getrennten Gates. Bis zum dokumentierten
> Build-Go werden weder Produktivcode noch Store-Produkte angelegt.

## 0. Review-Ergebnis

Die Richtung stimmt: Das Studio gehört zunächst in die bestehende App, soll
Organisation statt Wirkung verkaufen und darf nichts heute Kostenloses
wegnehmen. Folgende Aussagen des ersten Entwurfs waren jedoch zu endgültig:

1. **IAP ist die aktuelle Präferenz, noch kein unumkehrbarer Architekturentscheid.**
   In-App freigeschaltete Funktionen sprechen auf iOS grundsätzlich für IAP.
   Apple kennt aber regionale Link-Regeln und Sonderfälle; für Android gelten
   eigene Store-Regeln. Vor dem Build ist deshalb ein dokumentierter
   iOS-/Android-Entscheid nötig.
2. **Vier Abo-Produkte lösen den Gründerpreis nicht automatisch sauber.**
   Produkte und Namen können in Store-/Abo-Oberflächen sichtbar werden;
   Nutzer können innerhalb einer Abo-Gruppe wechseln. „Dauerhaft 50 %“ bleibt
   ein Produktversprechen, dessen Store-Mechanik vor einer Zusage geprüft wird.
3. **Der vorhandene Code liefert noch nicht alle geplanten Trends.** Der heutige
   Beobachtungs-Query filtert auf Textnotizen und 20 Einträge; Sessions reichen
   nur 30 Tage zurück. Ein 8-Wochen-Stimmungs- oder Fortschrittsverlauf ist damit
   nicht ohne Datenvertragsänderung möglich.
4. **„Keine neuen Datenflüsse“ war zu weitgehend.** Neue Aggregationen,
   Trainer-Notizen und automatische Erinnerungen sind neue Verarbeitungen bzw.
   neue Zwecke, auch wenn die Rohdaten schon existieren.
5. **Die Rollenverteilung nach DSGVO ist eine Arbeitshypothese.** Ob und wo
   Reflex Journey Verantwortlicher, Auftragsverarbeiter oder gemeinsam
   Verantwortlicher ist, ergibt sich aus tatsächlichen Zwecken und Mitteln und
   muss der Anwalt je Verarbeitung prüfen.
6. **Der bestehende Freitext `trainer_notes` ist ein aktuelles Launch-Thema.**
   Die Rechts-/Transparenzfrage darf nicht bis zum Studio-Build warten.
7. **Conversion-Grenzen bei etwa zehn Trainern wären Scheingenauigkeit.** Der
   erste Pilot wird qualitativ und mit absoluten Zahlen bewertet; Prozentwerte
   werden erst bei ausreichend großer Basis entscheidungsrelevant.

## 1. Produktkern

### 1.1 North Star

**Trainer Studio gibt Trainern in weniger als zwei Minuten Klarheit darüber,
wer heute Aufmerksamkeit braucht und wie die nächste Sitzung vorbereitet ist.**

Es ist kein Praxisverwaltungssystem, keine Patientenakte, kein Diagnosewerkzeug
und kein Abrechnungssystem. Es ist eine ruhige Arbeitsoberfläche für die
Begleitung innerhalb von Reflex Journey.

### 1.2 Die drei Versprechen

- **Überblick:** Relevantes sehen, ohne Chat, Kalender und Verlauf einzeln zu
  durchsuchen.
- **Vorbereitung:** Vor einem Termin den freigegebenen Verlauf schnell
  verstehen.
- **Verlässlichkeit:** Termine und Erinnerungen mit weniger Handarbeit
  organisieren.

### 1.3 Nicht versprechen

- keine Heilung, Diagnose, Behandlung oder Wirksamkeit;
- keine „KI erkennt Risiko“- oder Prognose-Sprache;
- keine garantierte Push-Zustellung oder garantierte Vermeidung von Ausfällen;
- keine vollständige Praxis-, Patienten- oder Abrechnungsverwaltung;
- keinen konkreten ROI, solange Interviews und Pilot ihn nicht belegen.

## 2. Zielgruppe und Kernaufgaben

### Primäre Zielgruppe

Solo-Trainer mit etwa 3–15 aktiven Reflex-Journey-Klienten, die Termine,
Verläufe und kurze Notizen heute über eine Mischung aus App, Kalender, Papier
und Messenger organisieren.

### Kernaufgaben

| Moment | Trainerfrage | Erfolgszustand |
|---|---|---|
| Tagesstart | „Was ist heute wichtig?“ | Nächste Termine und offene Punkte in < 60 Sek. erfassbar |
| Vor Sitzung | „Was ist seit dem letzten Termin passiert?“ | Briefing in < 2 Min. verstanden |
| Terminplanung | „Wie organisiere ich die nächsten Termine?“ | Termin/Serie in < 60 Sek. erstellt |
| Nach Sitzung | „Was muss ich festhalten oder als Nächstes tun?“ | Abschluss in < 90 Sek.; kein Zwang zu sensiblen Notizen |

Der Produktwert wird an diesen Aufgaben getestet, nicht an der Anzahl gebauter
Charts.

## 3. Produktprinzipien

1. **Heute vor Historie.** Zuerst die nächste sinnvolle Handlung, Details erst
   auf Abruf.
2. **Signal vor Dashboard.** Höchstens drei priorisierte Hinweise; keine Wand
   aus KPIs.
3. **Quelle und Zeitpunkt sichtbar.** Jeder Verlauf zeigt, woher ein Wert kommt
   und wann er zuletzt aktualisiert wurde.
4. **Keine Bewertung von Menschen.** Keine Scores wie „riskant“, „schlecht“
   oder „unzuverlässig“. Neutrale Zustände wie „seit 8 Tagen keine geteilte
   Aktivität“.
5. **Freigabe bleibt verständlich.** Trainer sehen nur Daten, die im aktuellen
   Beziehungs- und Freigabemodell vorgesehen und für Klienten transparent sind.
6. **Premium addiert, es enteignet nicht.** Alles heute Klickbare bleibt
   kostenlos.
7. **Mobile zuerst, aber nicht mobile für immer.** v1 funktioniert auf dem
   Smartphone; die Informationsarchitektur verbaut ein späteres Web-Dashboard
   nicht.
8. **Ruhig, warm, professionell.** Bestehendes Grün, klare Typografie, großzügige
   Abstände, keine Gamification und keine klinische Optik.

## 4. Informationsarchitektur

Die bestehende Trainer-Navigation bleibt erhalten. Das Studio wird nicht als
zweite App und nicht als paralleler „Premium-Bereich“ angehängt, sondern wertet
die vorhandenen Arbeitswege auf.

```text
Begleitung (Trainer-Root)
├── Klienten
│   ├── Arbeitsüberblick / „Heute“
│   ├── Klientenliste
│   └── Klientendetail
│       ├── Kurzüberblick
│       ├── Verlauf
│       ├── Termine
│       └── Sitzungsprotokolle (nur nach Legal-Go)
├── Termine
│   ├── Anstehend
│   ├── Termin erstellen
│   └── Serien & Erinnerungen (Studio)
├── Anfragen
├── Nachrichten
└── Studio-Einstellungen / Abo verwalten
```

„Heute“ ist eine verbesserte Einstiegsschicht im vorhandenen Klienten-Tab, kein
drittes Haupt-Tab. So bleibt die Navigation klein und die kostenlose
Klientenliste zentral.

## 5. UX-Blueprint

### 5.1 Trainer-Start: Arbeitsüberblick

```text
┌─────────────────────────────────────┐
│ Begleitung                    ⟳  ✉ │
│ Klienten              Termine      │
├─────────────────────────────────────┤
│ GUTEN MORGEN                        │
│ Heute im Blick                      │
│ 10:00  Lena · Termin                │
│ 15:30  Noah · Termin                │
│ [Alle Termine]                      │
├─────────────────────────────────────┤
│ AUFMERKSAMKEIT · 2                  │
│ Mila · Paket endet bald   [Öffnen]  │
│ Sam · neue Freigabe       [Öffnen]  │
├─────────────────────────────────────┤
│ KLIENTEN                    Suchen  │
│ ○ Lena  Paket 2 · Tag 11            │
│ ○ Noah  seit 4 Tagen ohne Aktivität │
└─────────────────────────────────────┘
```

- Maximal drei priorisierte Hinweise; Rest hinter „Alle anzeigen“.
- Keine rote Alarmfarbe für normale Inaktivität.
- Jede Karte hat genau eine primäre Aktion.
- Die bestehende Arbeitsübersicht bleibt gratis. Studio darf sie nur um neue
  Automatik/Verlaufssignale ergänzen.

### 5.2 Klienten-Briefing

```text
┌─────────────────────────────────────┐
│ ‹ Lena                              │
│ Paket 2 · Tag 11 · zuletzt gestern  │
│ [Nachricht] [Termin]                │
├─────────────────────────────────────┤
│ SEIT DEM LETZTEN TERMIN             │
│ 4 Trainings · 1 geteilte Beobachtung│
│ Nächster Termin: Di, 10:00          │
├─────────────────────────────────────┤
│ VERLAUF                             │
│ Trainingsrhythmus    8 Wochen  ›    │
│ Geteiltes Befinden   8 Wochen  ›    │
│ Paketverlauf                    ›    │
├─────────────────────────────────────┤
│ TERMINE                             │
│ Di, 10:00 · Erinnerung geplant      │
└─────────────────────────────────────┘
```

- Oberhalb des Folds: Identität, aktueller Stand, zwei häufigste Aktionen.
- „Seit dem letzten Termin“ ist der wichtigste Studio-Baustein; Charts sind
  sekundär.
- Stimmung, Energie und Stress werden getrennt und neutral benannt. Kein
  synthetischer Score.
- Bei weniger als zwei sinnvollen Datenpunkten wird kein Chart gezeichnet.

### 5.3 Termin-Plus

- Ein Termin bleibt der kostenlose Standardfluss.
- Studio ergänzt: wöchentlich/zweiwöchentlich, klares Enddatum, Vorschau der
  erzeugten Termine und Erinnerungseinstellung.
- Vor Speichern zeigt eine Zusammenfassung Zeitzone, Anzahl Termine und
  Erinnerungszeitpunkt.
- Statussprache: „Erinnerung geplant“ oder „nicht geplant“; nicht „zugestellt“,
  solange keine belastbare Zustellbestätigung existiert.
- Klienten können Termin-Erinnerungen unabhängig von Trainings-Erinnerungen
  steuern. Quiet Hours und Push-Berechtigung werden respektiert.

### 5.4 Sitzungsprotokoll — optionale spätere Stufe

Erst nach Legal-, Sicherheits- und Transparenz-Go. Falls gebaut:

- kurze, strukturierte Felder vor Freitext: Datum, vereinbarter nächster Schritt,
  optionale private Notiz;
- sichtbarer Hinweis, wer die Notiz sehen kann;
- Autosave-Status und explizites „gespeichert“;
- Export, Berichtigung und Löschung nach festgelegtem Prozess;
- keine Diagnosen, ICD-Codes, automatische Auswertung oder KI-Zusammenfassung
  in v1.

## 6. Scope und Freemium-Grenze

### Kostenlos — unverändert

- Profil, Suche/Karte und Gründungskennzeichnung;
- 1:1-Nachrichten;
- heutige Klientenliste, heutige Arbeitsübersicht und Momentaufnahme;
- bestehende Terminverwaltung;
- bestehende Freigaben, Beobachtungen und das bestehende einfache Notizfeld;
- Einladungen und Anfragen.

### Studio v1 — zwei Studio-Fähigkeiten (im Free MVP kostenlos)

1. **Klienten-Briefing:** „Seit dem letzten Termin“, 8-Wochen-
   Trainingsrhythmus, freigegebene Trends und Verlaufseinstieg.
2. **Termin-Automation:** Serien, automatische Push-Erinnerungen und `.ics`-
   Export.

### Separates Add-on hinter eigenem Gate

- strukturierte Sitzungsprotokolle, nur nach Anwalts- und Sicherheits-Go.

### Nicht v1

- Abrechnung, Rechnungen, Zahlungen Trainer↔Klient;
- Vollkalender-Synchronisation mit Schreibzugriff;
- Warteliste, Kapazitätsplanung, Video-Portfolio;
- Praxis-KPIs, Benchmarks, Team-/Praxis-Accounts;
- KI-Zusammenfassungen, Empfehlungen oder Risikoprognosen;
- Web-Portal;
- bezahltes Suchranking.

## 7. Daten- und Berechtigungskonzept

Vor jedem Build entsteht eine Datenvertragsmatrix:

| Anzeige/Funktion | Quelle heute | Lücke vor Build |
|---|---|---|
| Trainingsrhythmus | `get_client_sessions` | heute nur 30 Tage; Zeitraum/Consent/RLS prüfen |
| Befindenstrend | `mood_checkins` | heutiger Query filtert Notizen + Limit 20; Transparenz und Zweck prüfen |
| Paketverlauf | Enrollment/Progress/Sessions | belastbare historische Quelle noch festlegen |
| „Seit letztem Termin“ | Termine + Sessions + Freigaben | Definition von „letztem Termin“ und Zeitzonen testen |
| Erinnerungen | Appointments + Device Tokens | Opt-out, Quiet Hours, Push-Permission und Idempotenz |
| Sitzungsprotokolle | neu | Legal Basis, Rollen, AVV, Retention, Export/Löschung |

Verbindliche Regeln:

- Berechtigung wird serverseitig aus aktiver Trainer-Klient-Beziehung und
  Freigabe abgeleitet, nicht nur in der UI versteckt.
- Bei Beziehungsende endet der Trainerzugriff sofort; Retention/Export für
  Trainer-Notizen wird separat rechtlich entschieden.
- Keine echten Klientendaten in Screenshots, Analytics oder Support-Logs.
- Aggregierte Produktmetriken enthalten keine Notiztexte oder Gesundheitswerte.
- Soft Delete ist keine endgültige Löschung und wird nicht ohne festgelegte
  Aufbewahrungsregel als Lösung vorausgesetzt.

## 8. Kaufweg und Pricing

### 8.1 Aktuelle Präferenz

**Store-Pilot: Apple IAP auf iOS/iPadOS, Google Play Billing auf Android,
durch ein gemeinsames RevenueCat-Projekt verwaltet.** Der bezahlte Pilot darf
iOS-first starten; Android folgt nach dem T25.4-E2E. RevenueCat ist dabei
Entitlement-/Store-Abstraktion, nicht der Verkäufer anstelle des Stores.

Vor Build-Go sind vier Punkte schriftlich zu bestätigen:

1. aktuelle Apple-Regeln für die vorgesehenen Storefronts;
2. Android-Readiness und kommunizierter Fast-Follow-Termin;
3. T25-Identitäts- und Webhook-Modell einschließlich Restore, Refund, Grace
   Period und Billing Retry;
4. App-Review-Demo und Review Notes für die Trainerrolle.

**Der erste Studio-MVP ist kostenlos und braucht noch kein Storeprodukt.** Eine
geschlossene Kohorte erhält befristete interne `pilot`-Grants aus dem
Multi-Grant-/Benefit-System. `sales_rollout=off`, `feature_rollout=cohort`.
Vor Start wird transparent kommuniziert: kostenlos bis zu einem festen Datum,
keine automatische Verlängerung oder Belastung, ein späteres Bezahlangebot ist
eine neue ausdrückliche Entscheidung.

### 8.2 Preis-Hypothese, keine Zusage

| Variante | Research-Hypothese |
|---|---:|
| Monat | 14,99 € |
| Jahr | 119,99 € |
| Trial | 14 Tage, nur für berechtigte Nutzer |

StoreKit liefert lokalisierte Preise und Trial-Berechtigung. Preise werden nie
als selbst gepflegte UI-Konstanten behandelt.

Der Satz „rechnet sich ab drei Klienten“ und die Rechnung mit einem verhinderten
70-€-Ausfall werden erst verwendet, wenn Interviews das realistisch belegen.

### 8.3 Gründer-Vorteil — offener Entscheid

Das bestehende Versprechen „Eintrag/Sichtbarkeit dauerhaft gratis“ bleibt. Ein
zusätzlicher dauerhafter Studio-Rabatt wird erst kommuniziert, wenn eine
belastbare Store-Lösung gewählt ist. Zu prüfen:

- zeitlich begrenzter Launchpreis mit Preisbestandsschutz für aktive Abonnenten;
- separates günstiges Produkt mit akzeptiertem Sichtbarkeits-/Wechselrisiko;
- Offer Code (nur begrenzte Rabattdauer, daher nicht automatisch „dauerhaft“);
- einfacher Gründer-Bonus ohne Prozentversprechen.

Founder-Entscheid **TS-6** wird nach Store-Prüfung + Interviews dokumentiert.

### 8.4 Kostenrechnung

Keine pauschale Gegenüberstellung „15 % Apple vs. 4 % Stripe“. Der Business
Case weist Store-Provision, Umsatzsteuerbehandlung, RevenueCat-Kosten,
Zahlungsausfälle, Support und Verwaltungsaufwand getrennt aus.

## 9. Recht, Datenschutz und Sicherheit

Keine Rechtsbehauptung in dieser Spec ersetzt anwaltliche Prüfung.

### Sofort vor Launch klären

- heutiges `trainer_notes` und bestehender Trainerzugriff auf `mood_checkins`;
- Transparenz gegenüber Erwachsenen, Eltern und betroffenen Kindern;
- Rechtsgrundlage, Rollenverteilung, Zweckbindung und Beziehungsende;
- ob bestehende Notizen bis zur Klärung eingeschränkt werden müssen.

### Vor Studio-Build klären

- Rollenmatrix je Verarbeitung statt einer pauschalen AVV-Annahme;
- Art.-9-/Kinderdaten-Einordnung;
- AVV und Unterauftragsverarbeiter, falls Auftragsverarbeitung vorliegt;
- Lösch-, Berichtigungs-, Export- und Aufbewahrungskonzept;
- technische Schutzmaßnahmen, Incident-Prozess und Supportzugriff;
- Studio-B2B-Bedingungen, Apple-Abwicklung und P2B-Relevanz;
- Datenschutz-Folgenabschätzung: erforderlich, empfehlenswert oder nicht —
  begründet durch Anwalt/Datenschutzexpertise.

### Aktivierungs-Gate für Sitzungsprotokolle

Legal-Go allein reicht nicht. Benötigt werden: freigegebene Texte,
Rollen-/AVV-Prozess, Sicherheitsreview, RLS-Negativtests, Export/Löschung und
Klienten-Transparenz. Erst dann darf das Feature sichtbar werden.

## 10. Research-Plan

### Runde A — Problem-Interviews (5–7 Trainer)

Keine Feature-Präsentation in den ersten 12 Minuten. Erfragt werden letzter
realer Arbeitstag, heutige Werkzeuge, konkrete Zeitverluste, Ausfälle,
Vorbereitung und Datenschutzbedenken.

Kernfragen:

1. „Erzähl mir vom letzten Tag mit mehreren Klienten — wie hast du ihn
   organisiert?“
2. „Wie hast du dich auf den letzten Termin vorbereitet?“
3. „Wann ist zuletzt etwas untergegangen oder doppelt gepflegt worden?“
4. „Wie laufen Erinnerungen heute, und was passiert bei einem Ausfall?“
5. „Welche Informationen würdest du bewusst nicht in dieser App notieren?“
6. Erst danach: Konzeptkarten ranken und streichen lassen.
7. Preis mit vier Fragen testen: zu günstig/zweifelhaft, günstig, teuer aber
   erwägenswert, zu teuer.

### Runde B — Konzepttest (5 Trainer, Low-Fi)

Aufgaben ohne Erklärung:

- „Du startest deinen Arbeitstag. Was ist heute wichtig?“
- „Bereite dich auf Lenas Termin vor.“
- „Lege vier zweiwöchentliche Termine mit Erinnerung an.“
- „Finde heraus, welche Daten Lena freigegeben hat.“

Erfolg: mindestens 4/5 lösen jede Kernaufgabe ohne Hilfe; kritische
Missverständnisse werden vor Build korrigiert.

### Research-Hygiene

- keine Namen, Praxen, Orte oder echten Klientendaten im Repo;
- Beobachtung und wörtliche Interpretation getrennt dokumentieren;
- Absicht („würde ich nutzen“) zählt weniger als vergangenes Verhalten;
- Gründer-Rabatt erst nach unaided Preisantwort zeigen.

## 11. Delivery-Plan und Gates

### Discovery darf jetzt starten

Sie verändert kein Produktivsystem und braucht nicht zehn aktive Trainer. Wenn
weniger als drei passende Trainer erreichbar sind, bleibt der Scope vorläufig.

### Free-MVP-Build-Trigger — alle erforderlich

- P0–P2 + Daten-/Legal-Stufe P3A abgeschlossen und Founder bestätigt TS-8;
- mindestens 3–5 erreichbare Design-/Pilottrainer;
- T25.0 Multi-Grant-/Benefit-Fundament verfügbar;
- bestehende Trainer-Datenflüsse rechtlich eingeordnet;
- Datenvertragsmatrix und Sicherheitsanforderungen freigegeben;
- Build bleibt flag-/cohort-gated; Aktivierung erst bei stabilem Core-Launch.

Der kostenlose Build/Pilot wartet **nicht** auf Apple-/Google-Produkte oder
T25.5. Zahlungsarbeit läuft parallel.

### Paid-Pilot-Trigger — zusätzlich erforderlich

- kostenloser MVP-Pilot ausgewertet;
- Launch mindestens vier Wochen stabil, kein offener P0;
- T25.5 abgeschlossen, beide Storewege und Sync/Restore dokumentiert;
- 5–10 aktive, erreichbare Trainer;
- Problem-Interviews und Konzepttest ausgewertet;
- Founder bestätigt v1-Scope, Preisrichtung und Plattform;
- kostenloser Nutzungswert belegt und Paid-Pilot-Scope bestätigt.

### Geplante Workstreams nach Build-Go

| ID | Ergebnis | Abhängigkeit |
|---|---|---|
| T27.1 | Multi-Grant-Studio-Entitlement + Sales-/Feature-Rollout | T25.0 + TS-8/11 |
| T27.2 | Studio-Einstieg + kostenlose Kohorten-UX | getesteter UX-Prototyp |
| T27.3 | Klienten-Briefing + belastbare Datenverträge | Consent-/RLS-Review |
| T27.4 | Terminserien, Erinnerungen, `.ics` | Notification-/Timezone-Design |
| T27.5 | Sitzungsprotokolle, optional | vollständiges Legal-/Security-Go |
| T27.6A | kostenlose Benefit-Kohorte + MVP-Pilot | T27.1–T27.4 + P4A |
| T27.6B | Paywall, Store-/RevenueCat-E2E, bezahlter Pilot | Free-MVP-Auswertung + T25.5 + P4B |

Jeder Workstream liefert Flag-aus-Regression, Accessibility-Check, DE/EN,
Dark Mode, Tests, redigierte Evidenz und Rollback-/Kill-Switch-Nachweis.

## 12. Zweistufiger Pilot und Erfolgsmessung

### Stufe A — kostenloser MVP-Pilot

- 3–5, später bis zu 10 eingeladene Trainer, 6–8 Wochen;
- Zugriff über befristete `pilot`-Grants oder einmalige Pilotcodes;
- kein Storeprodukt, kein Trial und keine Zahlungsdaten;
- eindeutiges Enddatum, keine automatische Umwandlung in ein Abo;
- iOS-first zulässig; Android sobald der Build stabil verfügbar ist;
- keine öffentliche GA-Kommunikation;
- wöchentliche kurze Check-ins in Woche 1/2, Abschlussinterview in Woche 4–6.

Diese Stufe misst ausschließlich Problem-/Nutzungswert: Wird das Briefing vor
realen Terminen geöffnet? Werden Reminder/Serien wiederholt genutzt? Spart das
Tool tatsächlich Arbeit? Sie misst **keine Zahlungsbereitschaft**.

### Stufe B — bezahlter Founding-Pilot

- 5–10 Trainer, 4–6 Wochen;
- regulärer Storekauf mit transparentem Gründer-Startpreis und ggf. Trial;
- kein automatischer Übergang aus Stufe A: Trainer entscheiden aktiv;
- misst Trial→Paid, wiederkehrende Nutzung und erste Verlängerung.

### Primäre Signale

- Medianzeit bis zum Verstehen des Tagesüberblicks;
- Anteil Pilottrainer, die das Briefing vor realen Terminen wiederholt öffnen;
- Anteil geeigneter Termine mit aktivierter Erinnerung;
- wiederkehrende Nutzung in mindestens drei verschiedenen Wochen;
- in Stufe B: Trial→Paid und erste Verlängerung als absolute Zahlen;
- Supportaufwand und Vertrauens-/Datenschutzprobleme.

### Entscheidungslogik

- **Von A nach B:** wiederholte reale Nutzung bei mindestens drei Trainern,
  belegter Arbeitsnutzen und keine ungelösten Trust-/Legal-Probleme.
- **Von B Richtung GA:** mindestens drei Trainer kaufen aktiv bzw. erklären
  nach beobachteter Nutzung konkret warum nicht; Nutzung bleibt wiederkehrend.
- **Überarbeiten:** Nutzen wird verstanden, aber Kernaufgaben scheitern oder
  Nutzung bleibt episodisch.
- **Stoppen:** höfliches Interesse ohne reales Verhalten, geringe
  Zahlungsbereitschaft oder unverhältnismäßiges Rechts-/Betriebsrisiko.

Prozentuale Conversion-Ziele werden erst ab einer sinnvollen Stichprobe gesetzt.

## 13. Qualitätskriterien für das spätere Design

- wichtigste Information bei 150 % Textskalierung ohne Abschneiden;
- Charts zusätzlich als Textzusammenfassung und nicht allein über Farbe;
- Touchziele mindestens 44×44 pt;
- Light/Dark Mode und Kontrast nach WCAG-AA-Ziel;
- Empty, Loading, Offline, Error, Locked und „Freigabe beendet“ gestaltet;
- kein horizontaler Scrollzwang für Kerninformationen;
- Push-Ablehnung blockiert Terminverwaltung nicht;
- bei abgelaufenem Abo bleiben kostenlose Funktionen und eigener Datenzugang
  erhalten; keine Daten werden als Druckmittel versteckt;
- Storepreis, Zeitraum, Verlängerung, Trial-Berechtigung, Restore und Kündigung
  sind vor Kauf klar.

## 14. Offene Founder-Entscheidungen

| ID | Entscheidung | Fällig |
|---|---|---|
| TS-6 | Mechanik und Wortlaut des Gründer-Vorteils | vor externer Zusage |
| TS-7 | iOS-first Free MVP, Android-Fast-Follow | vor Free-MVP-Build-Go |
| TS-8 | finaler v1-Scope nach Research | nach Konzepttest |
| TS-9 | Sitzungsprotokolle v1, später oder nie | nach Legal-/Security-Go |
| TS-10 | Preis/Trial | nach Interviews + Store-Prüfung |
| TS-11 | Dauer/Enddatum und Teilnehmer des kostenlosen MVP | vor Pilot-Stufe A |

## 15. Aktuelle Primärquellen für den späteren Re-Check

- Apple App Review Guidelines 3.1.1/3.1.2/3.1.3:
  <https://developer.apple.com/app-store/review/guidelines/>
- Apple Small Business Program:
  <https://developer.apple.com/app-store/small-business-program/>
- Apple Introductory Offers:
  <https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions>
- Apple Subscription Offer Codes:
  <https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-subscription-offer-codes/>
- RevenueCat Entitlements und Offerings:
  <https://www.revenuecat.com/docs/getting-started/entitlements> ·
  <https://www.revenuecat.com/docs/offerings/overview>
- DSGVO (insb. Art. 4, 5, 9, 25, 28, 32, 35):
  <https://eur-lex.europa.eu/eli/reg/2016/679/oj>
- EDPB Guidelines 07/2020 zu Controller/Processor:
  <https://www.edpb.europa.eu/our-work-tools/our-documents/guidelines/guidelines-072020-concepts-controller-and-processor-gdpr_en>

Diese Quellen werden bei Build-Readiness erneut geprüft; diese Spec ist keine
dauerhafte Rechts- oder Store-Auskunft.
