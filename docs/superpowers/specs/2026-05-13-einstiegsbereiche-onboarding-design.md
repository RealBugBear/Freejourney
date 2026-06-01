# Einstiegsbereiche & Onboarding-Umstrukturierung

Status: Approved  
Date: 2026-05-13  
Author: Product (Alexander) + Claude

---

## 1. Zusammenfassung

Zwei zusammenhängende Änderungen:

1. **Onboarding-Flow-Umstrukturierung**: Der bestehende Flow hat einen Fehler — `for_whom_screen` erscheint doppelt (einmal als eigener Schritt, einmal innerhalb des Intake Assessments). Gleichzeitig erscheint Consent zu spät. Beides wird bereinigt.

2. **Neuer Screen "Viele Wege führen hierher"**: Ein edukativer Onboarding-Schritt direkt nach dem Username-Setup zeigt fünf Einstiegsbereiche für Reflexintegration. Ziel: Nutzer validieren und informieren — kein Pflichtfeld, keine funktionale Änderung am Training.

---

## 2. Onboarding-Flow (neu)

### Vorher (fehlerhaft)

```
Login → Username-Setup → for_whom_screen → Consent → Intake Assessment (ruft for_whom nochmal auf) → Dashboard
```

### Nachher (korrekt)

```
1. Sprachauswahl
2. Login / Registrierung
3. Consent
4. Username-Setup
5. Einstiegsbereiche "Viele Wege führen hierher"  ← NEU
6. Reflexprofil / Intake Assessment  (enthält "für wen" bereits)
7. Dashboard
```

### Router-Änderungen

- `Routes.onboardingForWhom` wird aus dem Haupt-Onboarding-Flow entfernt. Der Screen `for_whom_screen.dart` kann bestehen bleiben, wird aber nicht mehr aus dem primären Flow angesteuert.
- Consent-Redirect: nach erfolgreichem Login / Registrierung → Consent (vor Username-Setup)
- Nach Username-Setup: Weiterleitung zu neuem `Routes.onboardingEntryPoints`
- Nach Einstiegsbereiche: weiter zu bestehendem Intake Assessment / Reflexprofil

---

## 3. Neuer Screen: Einstiegsbereiche

### Position im Flow

Schritt 5 — direkt nach Username-Setup, vor Reflexprofil / Intake Assessment.

Begründung: Der Nutzer hat gerade Consent gegeben und einen Namen gewählt — er ist committed aber noch nicht im inhaltlichen Teil. Das ist der optimale Moment für einen Bildungsschritt: Neugier ist hoch, Ablenkung gering.

### Zweck

- **Primär edukativer Moment**: Nutzer sieht, dass Menschen aus sehr unterschiedlichen Bereichen Reflexintegration nutzen — Validierung ohne Druck.
- **Sekundär stille Datenerfassung**: Optionale Chip-Auswahl wird gespeichert für spätere Analytics / Personalisierung. Kein Einfluss auf das Training.

### Sprache

Gemäß App-Sprachregeln: beobachtend, nicht diagnostisch. Kein "du hast X", kein "Y führt zu Z".

Screentitel: **Viele Wege führen hierher**  
Untertitel: *Reflexintegration ist für sehr unterschiedliche Menschen relevant. Schau, was für dich klingt.*

---

## 4. Einstiegsbereiche (5 Karten)

Jede Karte hat: Icon · Titel · Teaser (immer sichtbar) · Detailtext + Literaturhinweis (aufklappbar).

### 1. Körper & Therapie

**Teaser:** Verspannungen, Fehlhaltungen, Empfehlung vom Therapeuten

**Detail:** Aktive Reflexmuster können zu dauerhafter Muskelanspannung führen — unabhängig von äußeren Auslösern. Physiotherapeut·innen und Ergotherapeut·innen empfehlen Reflexintegration häufig ergänzend, wenn klassische Behandlung nicht vollständig greift.

Typische Hinweise: chronische Rücken- oder Nackenverspannungen, Kieferspannung, Fehlhaltungen die immer wiederkehren.

*Vgl. Goddard Blythe: (Über)leben mit Reflexen*

**Chip-Key:** `koerper_therapie`

---

### 2. Koordination & Leistung

**Teaser:** Bewegungsqualität, Gleichgewicht, sportliche Koordination

**Detail:** Unintegrierte Reflexe binden motorische Ressourcen — was sich in eingeschränkter Koordination, verlangsamten Reaktionen oder Gleichgewichtsproblemen zeigen kann. Sportler·innen nutzen Reflexintegration um koordinative Grenzen zu erweitern, die durch klassisches Training nicht erreichbar sind.

Typische Hinweise: Bewegungsabläufe fühlen sich schwerer an als nötig, Asymmetrien, Gleichgewicht unter Druck.

*Vgl. Blomberg: Bewegungen die heilen*

**Chip-Key:** `koordination_leistung`

---

### 3. Emotionale Regulation & Innenwelt

**Teaser:** Stressreaktionen, Reizempfindlichkeit, Selbstwahrnehmung

**Detail:** Manche Reflexmuster beeinflussen direkt wie das Nervensystem auf Reize reagiert — Stressempfindlichkeit, emotionale Reaktivität, Reizüberflutung. Rhythmische Bewegung kann helfen, das Nervensystem zu regulieren und Zugang zu inneren Zuständen zu finden.

Typische Hinweise: schnelle emotionale Überflutung, Schwierigkeit zur Ruhe zu kommen, Körperspannung in Stress. Verläuft sehr individuell.

*Vgl. Blomberg: Bewegungen die heilen*

**Chip-Key:** `emotionale_regulation`

---

### 4. Mein Kind: Schule & Entwicklung

**Teaser:** Konzentration, Lernen, Schule — als Elternteil

**Detail:** Frühkindliche Reflexmuster die nicht vollständig integriert wurden, können sich später in Schwierigkeiten beim Lesen, Schreiben oder Konzentrieren zeigen — oft ohne klare organische Ursache.

Typische Hinweise: Kind kommt in der Schule nicht mit, kann sich schwer fokussieren, ist unruhig im Unterricht, Feinmotorik oder Lesen bereitet Mühe.

*Vgl. Goddard Blythe: (Über)leben mit Reflexen*

**Chip-Key:** `mein_kind`

---

### 5. Neugierde & Entdeckung

**Teaser:** Kein konkretes Problem — einfach erkunden

**Detail:** Manche Menschen kommen ohne konkretes Symptom — sie haben von Reflexintegration gehört und sind neugierig was rhythmische Bewegung über mehrere Wochen verändert. Das ist ein vollständig gültiger Einstieg.

Das Training wirkt unabhängig davon ob man ein "Problem" benennen kann oder nicht.

**Chip-Key:** `neugierde`

---

## 5. Interaktion

### Aufklappbare Karten

- Jede Karte zeigt standardmäßig nur Titel und Teaser
- Tippen öffnet den Detailtext und den Literaturhinweis
- "Mehr ↓" / "Weniger ↑" als Indikator
- Mehrere Karten können gleichzeitig offen sein

### Optionale Chip-Auswahl

- Unterhalb der Karten: "Was klingt für dich vertraut? (optional, Mehrfachauswahl)"
- 5 Chips entsprechend der 5 Bereiche
- Mehrfachauswahl erlaubt
- Expliziter Hinweistext: "Deine Auswahl ändert nichts am Training — sie hilft uns zu verstehen, wer die App nutzt."
- Kein Chip muss ausgewählt sein — "Weiter" ist immer aktiv

### Weiter-Button

- Immer aktiv, keine Pflichtauswahl
- Speichert Chip-Auswahl beim Tippen (auch leeres Array)

---

## 6. Datenmodell

Keine neuen Tabellen oder Migrations nötig.

Chip-Auswahl wird in das bestehende Feld `intake_assessments.additionalAnswers` (nullable JSON) geschrieben:

```json
{
  "entry_points": ["koerper_therapie", "mein_kind"]
}
```

**Mögliche Werte (ASCII-Keys):** `koerper_therapie` · `koordination_leistung` · `emotionale_regulation` · `mein_kind` · `neugierde`

**Timing und technische Abhängigkeit:**

`intake_assessments` erfordert eine `enrollmentId`. Die Enrollment wird aber erst in Schritt 6 (Intake Assessment) angelegt — der Einstiegsbereiche-Screen ist Schritt 5. Direkte Persistenz beim Screen ist daher nicht möglich.

Lösung: Die Chip-Auswahl wird in einem Riverpod-Provider im lokalen State gehalten und beim Abschluss des Intake Assessments (Schritt 6) als Teil von `additionalAnswers` persistiert. Wird das Intake Assessment übersprungen, wird die Auswahl verworfen — das ist für V1 akzeptabel.

**Timing für Unterscheidung:** Da Nutzer die das Intake überspringen keine Daten liefern, bedeutet `null` in `additionalAnswers.entry_points` immer "übersprungen oder Screen nicht gesehen". Das ist ausreichend für V1-Analytics.

---

## 7. Consent-Anpassung

Der bestehende Consent-Screen (`features/consent`) muss einen zusätzlichen Listenpunkt aufnehmen:

> "Deine optionale Angabe dazu, was dich hierher geführt hat (Einstiegsbereich)"

Keine strukturelle Änderung am Consent-Screen — nur ein Listenpunkt im bestehenden Text.

---

## 8. Nicht in Scope (V1)

- Personalisierung des Trainings oder Onboardings basierend auf Chip-Auswahl
- Zweiter Entry Point außerhalb Onboarding (z.B. in Profil) — das ist Ansatz C, möglicher nächster Schritt nach V1
- Mehr als 5 Bereiche
- Animationen oder progressive Disclosure über mehrere Screens

---

## 9. Offene Fragen

- Soll `entry_points` direkt beim Einstiegsbereiche-Screen als separater Supabase-Call gespeichert werden, oder gebündelt wenn das Intake Assessment abgeschlossen wird? (Empfehlung: separater Call direkt beim Screen, sonst gehen Daten verloren wenn Nutzer das Intake überspringt)
- Müssen die Literaturhinweise rechtlich geprüft werden (Quellenangabe ausreichend, oder Disclaimer nötig)?
