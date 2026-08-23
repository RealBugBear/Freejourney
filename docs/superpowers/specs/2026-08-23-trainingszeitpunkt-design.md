# Trainingszeitpunkt im Alltag — Design

**Stand:** 2026-08-23
**Status:** Design, vom Founder freigegeben. **Kein Build-Go.**
**Ziel des Founders:** Nutzer sollen möglichst **jeden Tag** trainieren. Ein
fester Platz im Tagesablauf ist dafür der stärkste Hebel.

---

## 1. In einfachen Worten

Nach dem ersten Training fragt die App einmal: **„Wann sollen wir dich
erinnern?"** Man wählt einen Zeitpunkt, der zum eigenen Tag passt, und ab dann
kommt die Erinnerung. Wer nicht will, tippt „Später" — und wird nicht wieder
gefragt.

Erwachsenen, die für sich selbst trainieren, empfiehlt die App **direkt nach dem
Aufwachen, noch im Liegen**. Bei Familien schlägt sie nichts vor, sondern bietet
nur die Auswahl an.

Nebeneffekt, der wichtig ist: Erst dadurch werden Erinnerungen überhaupt
eingeschaltet — und damit auch die Abendnachricht aus dem Serie-Design sichtbar.

---

## 2. Founder-Entscheidungen (2026-08-23)

| # | Entscheidung |
|---|---|
| A1 | **Medikamente kommen in dieser Funktion nicht vor.** Ein neutraler Verweis an Praxis oder Trainer gehört an eine Reflexprofil-Stelle, nicht in die Alltagsfrage. Der inhaltliche Punkt wird Anforderung für `adult_v4`. |
| A2 | **Zwei Empfehlungen, getrennt nach Zielgruppe.** Erwachsenenprofil: „direkt nach dem Aufwachen, im Liegen" als ausgewiesene Empfehlung. Kinderprofil: dieselbe Frage, **ohne** Empfehlung. |
| A3 | **Die Frage kommt direkt nach dem ersten abgeschlossenen Training** — nicht im Einstieg, nicht als Dauerkarte. |
| A4 | **Die Frage ist als Erinnerungsfrage formuliert** („Wann sollen wir dich erinnern?"). Damit ist die Zustimmung im Wortlaut enthalten, und die Antwort schaltet Erinnerungen ein. |

**Abgelehnte Alternativen**, damit sie nicht wiederkehren: eine einheitliche
Empfehlung für alle (trifft Familien mit Schulkindern am schlechtesten
möglichen Punkt); die Frage im Einstieg (die Vor-Payoff-Kette hat bewusst genau
vier Schritte, und man plant nichts, was man noch nie getan hat); nur den
Zeitpunkt merken ohne Erinnerung (dann bleibt die Abendnachricht unsichtbar,
also genau das Problem, das diese Funktion lösen soll).

---

## 3. Ist-Zustand (im Code verifiziert, 2026-08-23)

- **Es gibt nichts dazu.** Kein Text zu Tageszeit, Schlaf, Alkohol oder
  Medikamenten in `app_de.arb`.
- **Erinnerungen sind standardmäßig aus** (`AppSettings.remindersEnabled =
  false`). Das Erinnerungsfenster steht auf 08:00–20:00
  (`reminderStartMinutes`, `reminderEndMinutes`) und ist in den Einstellungen
  einstellbar.
- **Die Taktung** (`ReminderProfileSettings`, minimal/ausgewogen) existiert im
  Code, taucht in den Einstellungen aber gar nicht auf.
- **Die Impuls-Karte** auf dem Dashboard zeigt sieben allgemeine Sprüche, einen
  pro Wochentag. Nichts davon ist umsetzbar.
- **Ein Ein-Mal-Hinweis existiert bereits** und liefert das Muster:
  `RoutineTipSettings` (`lib/core/training/routine_tip_settings.dart`) zählt
  abgeschlossene Sitzungen in `SharedPreferences`, und das Dashboard zeigt ab
  der **zweiten** Sitzung einmalig ein Bodenblatt („Du kennst die Übungen
  jetzt"), ausgelöst über `addPostFrameCallback` beim Zurückkehren.
- **Nach dem Training** läuft heute: Paketende-Dialog (falls erreicht) →
  Erfahrungs-Bodenblatt (falls fällig) → `incrementSessionCount` → zurück zum
  Dashboard (`training_session_screen.dart:448`).

---

## 4. Ablauf

### 4.1 Auslöser

Beim Zurückkehren aufs Dashboard, im selben `addPostFrameCallback`, der heute
schon den Routine-Tipp prüft. Bedingung: **genau eine** abgeschlossene Sitzung,
und die Frage wurde noch nicht gestellt.

Da der Routine-Tipp erst **ab zwei** Sitzungen greift, können die beiden nicht
am selben Rückweg auftreten. Trotzdem gilt: **höchstens ein Bodenblatt pro
Rückkehr**; die Alltagsfrage hat Vorrang, der Routine-Tipp verschiebt sich dann
auf die nächste Rückkehr.

Nicht ausgelöst nach einer **Vorrunde**-Einheit — dort ist noch kein Paket im
Gang, über dessen Rhythmus man sinnvoll entscheiden könnte.

### 4.2 Die Karte

Ein Bodenblatt im Stil des bestehenden Routine-Tipps. Kein blockierender
Dialog.

```text
┌─────────────────────────────────────┐
│ Wann sollen wir dich erinnern?      │
│ Am verlässlichsten läuft es, wenn   │
│ das Training einen festen Platz im  │
│ Tag hat.                            │
│                                     │
│ ○ Direkt nach dem Aufwachen         │
│   geht im Liegen        EMPFOHLEN   │
│ ○ Nach dem Frühstück                │
│ ○ Mittags oder in einer Pause       │
│ ○ Am Abend                          │
│                                     │
│         [ Später ]  [ Erinnern ]    │
└─────────────────────────────────────┘
```

Nach der Wahl erscheint in derselben Ansicht die vorgeschlagene Uhrzeit mit der
Möglichkeit, sie zu verschieben (§4.4).

### 4.3 Die Auswahl je Zielgruppe (A2)

Maßgeblich ist `selectedSubjectProfileProvider.profileType`.

**`adult_self`** — mit ausgewiesener Empfehlung an erster Stelle:

| Anker | Vorgeschlagene Uhrzeit |
|---|---|
| Direkt nach dem Aufwachen — geht im Liegen **(empfohlen)** | 07:00 |
| Nach dem Frühstück | 08:30 |
| Mittags oder in einer Pause | 12:30 |
| Am Abend | 19:00 |

**`child`** — dieselbe Frage, **keine** Kennzeichnung als Empfehlung, keine
Umsortierung:

| Anker | Vorgeschlagene Uhrzeit |
|---|---|
| Morgens nach dem Aufwachen | 07:00 |
| Nach Kita oder Schule | 15:30 |
| Nach dem Abendessen | 18:30 |
| Zu einer festen Uhrzeit | 17:00 |

### 4.4 Ereignis gegen Uhrzeit

Der Anker ist ein **Ereignis**, die Erinnerung braucht eine **Uhrzeit**. „Direkt
nach dem Aufwachen" heißt bei den einen 6:00 und bei den anderen 9:00.

Deshalb schlägt die App nach der Wahl die Uhrzeit aus der Tabelle oben vor und
lässt sie in derselben Ansicht verschieben. Der Anker bleibt gespeichert, damit
die Einstellungen die Uhrzeit später nicht ohne Zusammenhang zeigen.

### 4.5 Der Schlaf-Hinweis

Erscheint **nur**, wenn eine Abend-Option gewählt ist, als ruhige Zeile unter
der Auswahl:

> Vielen fällt das Einschlafen nach den Übungen schwerer. Plane etwas Abstand
> zum Zubettgehen ein.

Kontextbezogen statt als allgemeine Warnung, die alle lesen müssen. Es ist eine
Beobachtung, keine Wirkaussage.

### 4.6 Was die Antwort bewirkt

1. Anker und Uhrzeit werden gespeichert.
2. `reminderStartMinutes` wird auf die gewählte Uhrzeit gesetzt.
3. `remindersEnabled` wird auf `true` gesetzt — dadurch erscheint die
   iOS-Systemabfrage für Mitteilungen an dieser Stelle, angekündigt durch den
   Wortlaut der Frage (A4).
4. Die bestehende Erinnerungs-Synchronisierung plant daraufhin sowohl die
   Trainingserinnerung als auch die **Streak-Abendnachricht** ein.

Bei „Später" wird nichts gesetzt und nichts eingeschaltet. Die Frage gilt als
gestellt und kommt nicht wieder.

**Wenn der Nutzer die iOS-Abfrage ablehnt**, bleibt `remindersEnabled = true`,
aber es kommt nichts an. Das ist der bestehende Zustand der App und wird hier
nicht neu gelöst — vermerkt in §8.

---

## 5. Später ändern

In den Einstellungen, im bestehenden Erinnerungsblock. Der gewählte Anker steht
als Zeile über dem Zeitfenster („Trainingszeitpunkt: Nach Kita oder Schule"),
antippbar, öffnet dieselbe Auswahl. Ändert man dort den Anker, wird die
vorgeschlagene Uhrzeit **nicht** automatisch überschrieben — wer sie einmal
angepasst hat, soll sie nicht wieder verlieren.

---

## 6. Medikamente (A1)

Kommt in dieser Funktion **nicht** vor — kein Wort, auch nicht als Nebensatz.

Hintergrund: Der Founder meint Stimulanzien wie Methylphenidat und hält es für
besser, sie erst nach dem Training einzunehmen. Das ist eine Aussage über den
Einnahmezeitpunkt eines verschreibungspflichtigen Medikaments. Bei einem
Schulkind verschiebt eine spätere Einnahme das Wirkfenster in den
Schulvormittag. Solche Aussagen trifft die verschreibende Praxis, nicht eine
App, die ausdrücklich kein Medizinprodukt ist.

Zusätzlich steht es bereits als **stehende Entscheidung** im Fragebogen-Plan
(`2026-08-21-adult-reflexprofil-questionnaire.md` §17): Das Expertendokument
führt „Medikamente — noch nicht strukturiert berücksichtigt", `adult_v3` hat
kein Item dazu, und die Anweisung lautet ausdrücklich: **„Bis dahin nicht durch
eigene Formulierungen schließen."**

Was stattdessen bleibt:

- **Anforderung an `adult_v4`**: ein Safety-Item zu regelmäßiger Medikation,
  nach Expertenfreigabe. Nicht Teil dieses Designs.
- **Neutraler Verweis**, ohne jede Zeitangabe, an einer Reflexprofil-Stelle:
  sinngemäß, den passenden Trainingszeitpunkt mit der behandelnden Praxis oder
  dem Trainer zu besprechen. Eigener Vorgang, eigene Freigabe.
- **Trainer** können im 1:1-Gespräch sagen, was sie für richtig halten. Das ist
  außerhalb des App-Textes.

---

## 7. Bewusst nicht Teil dieser Funktion

- **Die Impuls-Karte bleibt unverändert.** Anker-passende Sprüche wären sieben
  Texte mal vier Anker — eigene Inhaltsarbeit, die dem Ziel nicht dient. Die
  Aufgabe dieser Funktion ist der feste Zeitpunkt.
- Kein Nachfassen, wenn niemand antwortet.
- Keine zweite Erinnerung am selben Tag.
- Keine unterschiedlichen Zeitpunkte je Wochentag.
- **Kein eigener Anker pro Kind.** Die Erinnerung ist geräteweit, nicht pro
  Profil — konsistent mit der Abendnachricht aus dem Serie-Design, die
  ebenfalls eine Meldung pro Abend schickt.
- Keine Aussage zu Alkohol. Der Founder hatte ihn genannt; er gehört zur
  Unverfälschtheit des **Fragebogens**, nicht zum täglichen Training, und würde
  aus einer ruhigen Gewohnheit eine medizinische Prozedur machen.

---

## 8. Offene Punkte

- **Abgelehnte iOS-Mitteilungen.** Lehnt jemand die Systemabfrage ab, meint die
  App weiterhin, Erinnerungen seien an. Bestehendes Verhalten, hier nicht
  gelöst; eigener Vorgang.
- **Der Anker verfällt nicht.** Wer im Winter „nach der Schule" wählt und im
  Sommer anders lebt, wird nicht erneut gefragt. Bewusst — einmal fragen,
  nicht nerven; ändern geht in den Einstellungen.
- **Wirkung unbelegt.** Dass ein fester Ankerpunkt die Regelmäßigkeit erhöht,
  ist die Annahme hinter dieser Funktion. Ob sie stimmt, zeigt erst der
  Vergleich der Serien-Längen zwischen Nutzern mit und ohne gesetzten Anker.
  Diese Messung ist **nicht** Teil dieser Stufe.
- **Die Taktungs-Einstellung** (minimal/ausgewogen) bleibt weiterhin ohne
  Oberfläche. Unberührt.
