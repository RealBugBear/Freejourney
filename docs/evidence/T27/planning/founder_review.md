# T27 · P0 — Founder-Review

**Review-Datum:** 2026-07-23  
**Status:** ✅ Founder bestätigt  
**Entscheidungsdatum:** 2026-07-23  
**Scope:** Entscheidungsvorlage und Bestandsaufnahme, kein
Implementierungsauftrag

## Kurze Entscheidungsvorlage

### Problem

Solo-Trainer organisieren Termine, freigegebene Verläufe und kurze Notizen
heute über eine Mischung aus App, Kalender, Papier und Messenger. Dadurch
kosten der Tagesüberblick und besonders die Vorbereitung auf die nächste
Sitzung unnötig Zeit. Trainer Studio soll Organisation verbessern — nicht
Wirkung, Diagnose oder Behandlung versprechen.

### Primäre Zielgruppe

Solo-Trainer mit etwa 3–15 aktiven Reflex-Journey-Klienten, die diese
verteilten Werkzeuge heute tatsächlich nutzen. Die vier Kernmomente sind
Tagesstart, Vorbereitung vor einer Sitzung, Terminplanung und Abschluss nach
einer Sitzung.

### Vorläufige v1-Fähigkeiten

Der vorläufige TS-8-Scope enthält zwei Studio-Fähigkeiten. Beide werden im
ersten geschlossenen MVP kostenlos erprobt; alles heute kostenlos Klickbare
bleibt kostenlos.

1. **Klienten-Briefing:** „Seit dem letzten Termin“,
   8-Wochen-Trainingsrhythmus, freigegebene neutrale Trends und
   Verlaufseinstieg.
2. **Termin-Automation:** Terminserien, automatische Push-Erinnerungen unter
   Beachtung von Opt-out und Quiet Hours sowie `.ics`-Export.

Strukturierte Sitzungsprotokolle und neue Notizfunktionen gehören nicht zu
diesem Zweier-Scope. Sie bleiben ein separates Add-on hinter einem eigenen
Legal-, Security-, Transparenz- und Aktivierungs-Gate.

### Nicht-Ziele

- kein Praxisverwaltungssystem und keine Patientenakte;
- keine Diagnose, Behandlung, Heilungs-, Wirkungs- oder Risikoprognose;
- keine Abrechnung oder Zahlungen zwischen Trainer und Klient;
- keine Team-/Praxis-Accounts, Praxis-KPIs oder Benchmarks;
- kein Web-Portal, kein Vollkalender-Schreibzugriff und kein bezahltes
  Suchranking;
- keine KI-Zusammenfassungen, Empfehlungen oder Risikoscores;
- keine garantierte Reminder-Zustellung und keine unbelegte ROI-Aussage.

### Gates

- **P0:** Founder bestätigt oder korrigiert die Produktausrichtung.
- **P1/P2:** Problem-Interviews und Low-Fi-Konzepttest validieren Problem und
  finalen TS-8-Scope.
- **P3A:** Datenvertrag sowie Rechts-/Datenschutzprüfung müssen Briefing und
  Termin-Automation freigeben.
- **P4A:** Erst ein dokumentiertes GO autorisiert Produktivcode für
  T27.1–T27.4 und den späteren kostenlosen MVP-Pilot.
- **P3B/P4B:** Store-/Pricing-Entscheid ist Pflicht für P4B; erst ein
  dokumentiertes P4B-GO öffnet den bezahlten Pilot.
- **Notizen:** separates vollständiges Legal-/Security-/Transparenz-Gate,
  unabhängig vom übrigen Studio-Scope.
- Vor dem jeweiligen GO: kein Produktivcode, keine Migration, kein Deploy,
  keine Store-Konfiguration und keine neue externe Kommunikation.

## Freigegebene Richtung und verbleibende Hypothesen

| ID | Seit 2026-07-19 freigegebene Richtung | Weiter offen / Hypothese |
|---|---|---|
| TS-6 | Gründer-Vorteil ohne ungesicherte Prozent- oder Wiederanmeldegarantie | Konkrete Mechanik und finaler Wortlaut erst nach Store-Prüfung und Interviews |
| TS-7 | Plattformneutral; Free MVP darf iOS-first starten, Android folgt nach stabiler Build-Verfügbarkeit | Bezahlter Android-Pilot zusätzlich erst nach T25.4-E2E |
| TS-8 | Vorläufig: Briefing + Termin-Automation | Finaler v1-Scope erst nach P1/P2 |
| TS-9 | Sitzungsprotokolle/Notizen separat gegated | Bau und Aktivierung nur nach vollständigem Legal-/Security-Go |
| TS-10 | Preis und Trial bleiben Research-Hypothesen | 14,99 €/Monat, 119,99 €/Jahr und 14 Tage Trial sind keine Zusage |
| TS-11 | Free-Pilot-Rahmen: 3–5 Trainer, 6–8 Wochen, befristet, kostenlos, kein Auto-Abo | Enddatum, Teilnehmer und weitere Pilotdetails werden erst vor Stufe A final |

Diese Richtungsfreigaben sind weder Research-Ergebnisse noch ein
P4A-/P4B-Go.

## Inventar bestehender externer Gründerpreis-Versprechen

### 1. Als bestehendes Versprechen intern dokumentiert

Die Planungsunterlagen behandeln genau eine Aussage als bereits bestehendes
externes Versprechen:

> **Eintrag und Sichtbarkeit für Gründungs-Trainer bleiben dauerhaft
> kostenlos.**

Belege für diesen dokumentierten Bestand:

- `docs/MONETARISIERUNG_EVALUATION.md`, Zeilen 14–17
  (stärkster Bestandsvermerk: „Eintrag/die Sichtbarkeit dauerhaft kostenlos
  versprochen — nicht mehr“);
- `docs/superpowers/specs/2026-07-08-trainer-studio-design.md`, §8.3;
- `docs/APPSTORE_LAUNCH_ROADMAP.md`, Zeilen 184, 220 und 232;
- `docs/TRAINER_TOOL_PLAN.md`, Zeilen 18–30
  (archivierte Vorarbeit, aber eindeutige Beschreibung des Altversprechens).

Die Zusage bezieht sich nur auf Verzeichnis-Eintrag und Sichtbarkeit, nicht auf
Trainer Studio, künftige Werkzeuge oder einen Abo-Rabatt. Im Repo liegt kein
versandter Text und keine Empfängerliste, mit denen sich Kanal, Wortlaut oder
Adressaten unabhängig belegen lassen. Dafür ist die Founder-Bestätigung unten
erforderlich.

### 2. Öffentlich auffindbare Flächen am 2026-07-23

- `https://reflexjourney.app/` zeigt nur den Marken-Platzhalter und enthält
  kein Trainer-, Studio- oder Preisversprechen.
- `https://reflexjourney.app/trainer` antwortet mit HTTP 404; die geplante
  Gründungs-Trainer-Seite ist nicht veröffentlicht.
- Die von der Startseite verlinkte Domain `reflexjourney.de` sowie
  `www.reflexjourney.de` waren beim Check nicht per DNS auflösbar.
- Die lokalen Website-Quellen, der Store-Listing-Entwurf und die App-Copy
  enthalten kein veröffentlichtes Studio-Gründerpreis-Versprechen. Die
  aktuelle App-Copy erklärt zwar allgemein Benefit-Codes und mögliche
  Premium-/Studio-Freischaltungen, nennt aber keinen Founder-Preis, Rabatt,
  Trial oder Daueranspruch.

Damit wurde auf den prüfbaren öffentlichen Flächen kein zusätzliches
Preisversprechen gefunden.

### 3. Vorbereitet, aber ausdrücklich nicht kommuniziert

- `docs/legal/TRAINER_ERSTANSPRACHE_ART14_ENTWURF.md` nennt ein
  „Gründungs-Trainer“-Angebot und beschreibt den Verzeichnis-Eintrag, enthält
  aber keine Studio-Preis- oder Rabattzusage. Der Dateikopf verbietet die
  Verwendung vor anwaltlichem Go.
- Die geplante Website-Seite W5 existiert nur im Bauplan; live ist `/trainer`
  nicht vorhanden.

### 4. Interne Hypothesen — keine externen Zusagen

- Der archivierte Satz „Studio für immer zum halben Preis“ in
  `docs/TRAINER_TOOL_PLAN.md`, Zeilen 50–56, ist verworfene Vorarbeit und darf
  nicht kommuniziert werden.
- Der aktuelle interne Richtungswortlaut „Startpreis, solange dein Abo aktiv
  bleibt“ und alle Beispielpreise sind bis P1/P3B Hypothesen. Sie wurden in
  den geprüften öffentlichen Flächen nicht gefunden.
- Bestehende technische Legacy-Codes belegen nur Kompatibilität des
  Einlösewegs, nicht ihre Verteilung oder eine dazu gegebene Preiszusage.
- Private E-Mails, DMs, Kontaktformulare, Gespräche oder bereits versandte
  Unterlagen sind aus dem Repo nicht prüfbar. Der Founder ergänzt unten jede
  solche Zusage mit exaktem Wortlaut, Kanal und grobem Empfängerkreis — ohne
  personenbezogene Daten im Repo.

**Kommunikationsprotokoll dieser P0-Session:** Es wurde nichts neu nach außen
kommuniziert.

## Founder-Bestätigung

### 1. North Star

> Trainer Studio gibt Trainern in weniger als zwei Minuten Klarheit darüber,
> wer heute Aufmerksamkeit braucht und wie die nächste Sitzung vorbereitet
> ist.

- [x] bestätigt
- [ ] korrigiert: _Wortlaut_

### 2. Primäre Zielgruppe

> Solo-Trainer mit etwa 3–15 aktiven Reflex-Journey-Klienten, die Termine,
> Verläufe und kurze Notizen heute über App, Kalender, Papier und Messenger
> organisieren.

- [x] bestätigt
- [ ] korrigiert: _Wortlaut_

### 3. Scope-Regel

> Briefing + Termin-Automation; Notizen separat.

- [x] bestätigt
- [ ] korrigiert: _Wortlaut_

### 4. Externe Altversprechen

- [x] bestätigt: Extern zugesagt wurde nur „Eintrag/Sichtbarkeit dauerhaft
  kostenlos“; keine Studio-Preis-, Prozent- oder Wiederanmeldezusage.
- [ ] korrigiert/ergänzt: _exakter Wortlaut, Kanal und grober Empfängerkreis;
  keine Namen oder Kontaktdaten_

**Founder:** Founder  
**Entscheidungsdatum:** 2026-07-23  
**Begründung/Korrekturen:** Founder-Antwort: „ist okay“. Der Wunsch nach einem
späteren Trainer-Tester-Account und anschließender Installation auf dem
Founder-Gerät ist als Testwunsch verstanden, aber nicht Teil von P0 und kein
P4A-/P4B-Go.

## Abschlussregel für P0

Die Founder-Antwort vom 2026-07-23 bestätigt die vier P0-Punkte. P0 darf auf
✅ gesetzt werden; P1 und alle Build-Abschnitte bleiben unangetastet.
