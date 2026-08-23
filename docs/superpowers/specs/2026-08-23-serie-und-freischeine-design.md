# Serie & Freischeine — Design

**Stand:** 2026-08-23
**Status:** Design, vom Founder freigegeben. **Kein Build-Go.** Der Umsetzungsplan
entsteht separat.
**Ziel des Founders:** Nutzer sollen möglichst **jeden Tag** trainieren.

---

## 1. In einfachen Worten

Die App zählt heute schon mit, an wie vielen Tagen am Stück trainiert wurde — zeigt
es dem Nutzer aber nie, und rechnet es an drei Stellen unterschiedlich. Daraus wird
**eine** Zahl, die man auch sieht.

Dazu kommen Freischeine: Wer dreimal trainiert, bekommt einen geschenkt, höchstens
zwei auf einmal. Vergisst man einen Tag, wird automatisch einer eingelöst und die
Serie bleibt stehen. Abends kommt eine Nachricht aufs Handy. Zwei Ausfalltage am
Stück deckt das Guthaben ab, beim dritten ist die Serie vorbei. Jedes Kind hat
seine eigene Serie und seine eigenen Freischeine.

---

## 2. Founder-Entscheidungen (2026-08-23)

| # | Entscheidung |
|---|---|
| D1 | **Ein Ziel: täglich.** Der Wochen-Streak entfällt. |
| D2 | **Alle drei Trainingswege zählen** — geführte Einheit, „Heute geübt eintragen", Vorrunde. |
| D3 | **Die Serie hängt am Kind, nicht am Paket.** Paketwechsel, Pause und Neustart lassen sie unberührt. |
| D4 | **Eine Benachrichtigung am Ende des Erinnerungsfensters**, die warnt statt im Nachhinein zu melden. |
| D5 | **Die Nachricht hängt am bestehenden Erinnerungsschalter.** Die Reichweite löst das nachfolgende Alltags-Thema. |
| D6 | **Anzeige: eine Zeile** auf dem Dashboard, die den heutigen Wochen-Streifen ersetzt. |
| D7 | **Lösungsweg: die Serie wird ausgerechnet, nicht gespeichert.** Gespeichert werden nur die Freischeine. |
| D8 | Höchstens **2** Freischeine, Nachladen nach **3** Trainingstagen, Start bei **0**. |
| D9 | Ein Freischein **hält** die Serie, er zählt sie nicht hoch. |
| D10 | **Zwei Ausfalltage hintereinander sind erlaubt**, ab dem dritten bricht die Serie. Eine zusätzliche „nie zwei am Stück"-Regel wurde ausdrücklich abgelehnt — das Guthaben ist die Grenze. |
| D11 | Ein Freischein wird **nur eingesetzt, wenn er die Serie tatsächlich rettet.** Sonst bleibt er erhalten. |

---

## 3. Ist-Zustand (im Code verifiziert, 2026-08-23)

- **Drei getrennte Streak-Rechnungen:**
  `training_completion_repository.dart` (~Z. 478, geführte Einheit inkl.
  mittrainierender Geschwister), `progress_provider.saveCompletedSession`
  (~Z. 755, manuelles Eintragen) und `progress_provider.saveVorrundeRegulationSession`
  (~Z. 864, Vorrunde). Die dritte aktualisiert die Wochenzahlen gar nicht.
- **Der Wochen-Streak zählt nie hoch.** Die Bedingung
  `trainingsThisWeek >= weeklyGoal && isNewWeek` ist nicht erfüllbar: in einer neuen
  Woche steht der Zähler immer auf 1, das Ziel ist 5. Betrifft zwei der drei Stellen.
- **Der Nutzer sieht die Serie nirgends.** Nur die Entwickler-Tools und die
  Trainer-Klientenansicht zeigen sie.
- **Konkurrierende Anzeige:** `_WeeklyRegularityStrip` auf dem Dashboard rechnet
  Regelmäßigkeit unabhängig aus `thisWeekSessionsProvider`.
- **`consecutiveInactiveDays`** wird überall stur auf 0 gesetzt, nie hochgezählt.
- **Die Serie hängt an der Paket-Anmeldung.** `progress_entries` hängt an
  `enrollments`; ein neues Paket bedeutet eine neue Zeile und damit Serie 0 —
  auch für jemanden, der keinen Tag ausgelassen hat.
- **Alle drei Wege schreiben bereits eine `training_sessions`-Zeile** mit
  `session_date`, `subject_profile_id` und `is_completed`. Das ist die Grundlage
  für D7.
- **`weekly_goal` hat keine Oberfläche.** Der Wert steht auf 5 und ist für Nutzer
  weder sichtbar noch änderbar. Er wird aber von der Admin-Kennzahl
  „Wochenziel erreicht" (`2026060105_admin_metrics_v1.sql`) und von
  `user_reminder_preferences` gelesen — er bleibt deshalb bestehen.

---

## 4. Architektur

### 4.1 Die Serie wird abgeleitet

Es gibt **keinen gespeicherten Serienwert** mehr. Ein neuer Baustein
`StreakService` beantwortet zwei Fragen für ein Kind-Profil:

- Welche Kalendertage gelten als Trainingstage?
- Wie lang ist die aktuelle Serie?

**Trainingstag** für Profil `P` = ein lokaler Kalendertag, an dem mindestens eine
Zeile in `training_sessions` mit `is_completed = true` existiert, deren
`subject_profile_id` gleich `P` ist. **Altlast:** Zeilen mit
`subject_profile_id IS NULL` zählen für das Profil, auf das ihre `enrollment_id`
zeigt — solche Zeilen stammen aus der Zeit vor der Profilverknüpfung.

**Serienlänge** (lokales Datum `T` = heute):

```
gerettet = Menge der Datumswerte im Freischein-Konto von P
tag      = T, falls Trainingstag(T), sonst T - 1
länge    = 0
solange Trainingstag(tag) oder tag in gerettet:
    länge += 1
    tag   -= 1 Tag
```

Der heutige Tag zählt nicht gegen den Nutzer, solange er läuft. Rückblick ist auf
**400 Tage** begrenzt.

### 4.2 Was gespeichert wird

Neue Tabelle `profile_streak_credits`, eine Zeile pro (`user_id`,
`subject_profile_id`) — lokal in Drift und auf Supabase, mit denselben
RLS-Regeln wie die übrigen Nutzerdaten (Eigentümer voll, Trainer lesend nur über
die bestehende Beziehung).

| Feld | Bedeutung |
|---|---|
| `available` | Verfügbare Freischeine, 0–2 |
| `progress_to_next` | Punkte zum nächsten Freischein, 0–2 |
| `last_counted_day` | Letzter Tag, der auf den Punktestand angerechnet wurde |
| `rescued_days` | Liste der Tage, die ein Freischein gerettet hat |

`rescued_days` ist der einzige Teil der Serie, der nicht ableitbar ist — dass ein
Ausfalltag verziehen wurde, steht in keinem Trainingseintrag. Einträge älter als
der Rückblick von 400 Tagen werden bei jeder Auswertung verworfen, damit die Liste
nicht unbegrenzt wächst.

### 4.3 Die Auswertung

Eine **Auswertung** läuft an genau drei Zeitpunkten: beim App-Start nach
abgeschlossenem Sync, nach jedem abgeschlossenen Training und nach jedem
eingehenden Sync von Trainingseinträgen.

Sie hat eine feste Reihenfolge:

1. **Verdienen** (§4.4) — damit frisch synchronisierte Trainingstage ihr Guthaben
   noch beisteuern, bevor darüber entschieden wird.
2. **Einsetzen** (§4.5) — damit dieses Guthaben eine Lücke noch retten kann.
3. **Spiegeln** (§7) — der abgeleitete Wert wandert in die Trainer-Ansicht.

Die Auswertung ist als Ganzes idempotent: zweimal am selben Tag ausgeführt ändert
sie nichts.

### 4.4 Verdienen

```
neueTage = Trainingstage von P im Zeitraum (last_counted_day, T], aufsteigend
für jeden tag in neueTage:
    wenn available < 2:
        progress_to_next += 1
        wenn progress_to_next == 3:
            available += 1
            progress_to_next = 0
    # bei available == 2 ruht der Punktestand
last_counted_day = max(last_counted_day, letzter neuerTag)
```

Der Punktestand **ruht bei vollem Konto** — es lässt sich weder Guthaben noch
Fortschritt darauf ansparen (Founder-Vorgabe „nicht ansparen können").

Gerettete Tage zählen **nicht** als Trainingstage und geben keine Punkte.

Die Auswertung ist pro Tag idempotent: `last_counted_day` verhindert
Doppelzählung, und weil über Trainings**tage** statt über Schreibvorgänge gezählt
wird, ändert gemeinsames Training mit Geschwistern (eine Sitzung, mehrere
Profile) nichts an der Zählweise — jedes Profil bekommt seinen eigenen Tag.

### 4.5 Einsetzen

Zweiter Schritt jeder Auswertung (§4.3):

```
letzter = jüngster Tag <= T mit Trainingstag(tag) oder tag in gerettet
wenn letzter fehlt:            -> nichts tun (noch nie trainiert)
lücke = [letzter+1 .. T-1]     -> abgelaufene Tage ohne Training und ohne Rettung
wenn lücke leer:               -> nichts tun
wenn länge(lücke) <= available:
    für jeden tag in lücke: gerettet += tag; available -= 1
sonst:
    nichts tun                 -> die Serie bricht, das Guthaben bleibt erhalten
```

Der heutige Tag ist nie Teil der Lücke — er läuft noch.

**D11 im Klartext:** Wer zehn Tage weg war, verliert die Serie und behält beide
Freischeine. Ohne diese Regel würden sie beim ersten Öffnen sinnlos verbrannt.

**D10 im Klartext:** Mit höchstens zwei Freischeinen deckt die Lücke höchstens
zwei Tage. Der dritte Ausfalltag ist nicht abgedeckt, die Serie bricht.

---

## 5. Benachrichtigung

Eine **einmalige lokale Benachrichtigung pro Tag** zur Uhrzeit
`reminderEndMinutes` (Standard 20:00), nur wenn `remindersEnabled` gesetzt ist.

- Bei Guthaben: „Heute noch nicht geübt. Wenn der Tag ohne Training endet, springt
  ein Freischein ein — du hast noch {n}."
- Ohne Guthaben: „Heute noch nicht geübt. Ohne Freischein endet deine Serie heute."

Beide Formulierungen stimmen unabhängig davon, ob später am Abend doch noch
trainiert wird.

**Mechanik.** Eine geplante Benachrichtigung kann beim Auslösen nichts prüfen.
Deshalb werden Einzeltermine für die **nächsten 7 Tage** im Voraus eingeplant und
neu berechnet bei: App-Start, Abschluss eines Trainings, Änderung der
Erinnerungseinstellungen. Der Termin des laufenden Tages wird abgesagt, sobald an
diesem Tag trainiert wurde. Eigener ID-Bereich, getrennt von der bestehenden
Trainingserinnerung (`_kReminderId`) und den Trainer-Meldungen (500–899).

**Mehrere Kinder.** Es geht **eine** Meldung pro Abend raus, formuliert für das
gerade gewählte Profil. Eine Familie mit drei Kindern soll nicht drei Meldungen
bekommen. Bewusste Vereinfachung, in §10 als offener Punkt vermerkt.

**Grenze, die genannt sein muss.** `NotificationService` schaltet sich bei einem
Plugin-Fehler selbst ab (`disable()`) — auf iOS 26 ist das vorgekommen. Die
Benachrichtigung ist deshalb **bestmöglich, nicht garantiert.** Die App bestätigt
einen eingesetzten Freischein zusätzlich beim nächsten Öffnen in der Serien-Zeile;
das ist der verlässliche Weg.

---

## 6. Oberfläche

### 6.1 Serien-Zeile (Dashboard)

Ersetzt `_WeeklyRegularityStrip`. Eine Karte:

- Links: „Serie · {n} Tage"
- Rechts: Ticket-Symbol und die Zahl der verfügbaren Freischeine
- Darunter: sieben Wochentage — **trainiert** (voll), **vom Freischein gerettet**
  (eigene Farbe mit Rand), **heute noch offen** (gestrichelt), **leer**

Ein geretteter Tag muss sich sichtbar von einem trainierten unterscheiden, sonst
behauptet die Woche etwas Falsches.

Die Zeile gehört zum **gewählten Kind** und folgt dem Profilwechsel.

### 6.2 Rückmeldungen

- **Freischein eingesetzt:** Beim nächsten Öffnen ein deutlicher Hinweis in der
  Serien-Zeile, der beim Antippen verschwindet. Kein Popup.
- **Freischein verdient:** Die Zahl in der Zeile ändert sich, mehr nicht. Kein
  Popup, keine Belohnungsanimation.

### 6.3 Was verschwindet

- `_WeeklyRegularityStrip` in seiner heutigen Form
- Die Streak-Rechnung in allen drei Schreibpfaden
- Das Schreiben von `weekly_streak`, `trainings_this_week`,
  `last_training_week_start` und `consecutive_inactive_days`

Die **Spalten bleiben zunächst bestehen** — sie zu löschen ist ein Eingriff in die
Live-Datenbank ohne Nutzen. Eine Aufräum-Migration kann später folgen, wenn
nachweislich nichts mehr darauf zugreift.

`weekly_goal` **bleibt unangetastet** (Admin-Kennzahl und
`user_reminder_preferences`, siehe §3). Für Nutzer ändert sich dadurch nichts, weil
der Wert nie eine Oberfläche hatte.

---

## 7. Trainer-Ansicht

`get_trainer_clients` liest heute `pe.daily_streak`. Die Serie wird künftig
abgeleitet, der gespeicherte Wert wäre also veraltet.

**Lösung:** Die App schreibt den abgeleiteten Wert nach jeder Auswertung in
`progress_entries.daily_streak` der aktiven Paket-Anmeldung und stellt ihn in die
Sync-Warteschlange. Die Spalte ist damit ein **Spiegel**, keine Quelle. Der Trainer
sieht dieselbe Zahl wie die Eltern.

Bewusst **kein** Umbau der Server-Abfrage: das wäre eine Änderung an der
Live-Datenbank ohne zusätzlichen Nutzen für diese Stufe. Die Abfrage kann die Serie
später selbst ableiten, wenn ein Grund dafür entsteht.

---

## 8. Datenbank und Freigaben

Nötig ist **eine** Migration:
`supabase/migrations/YYYYMMDDNN_profile_streak_credits.sql` — neue Tabelle,
Index auf (`user_id`, `subject_profile_id`), RLS analog zu `progress_entries`
(Eigentümer voll; Trainer lesend nur über eine aktive Beziehung). Idempotent, muss
mit `supabase db reset --local` grün durchlaufen.

Lokal: neue Drift-Tabelle, Schema-Version hoch, Migration `v4 → v5`,
`dart run build_runner build`.

Sync: neuer Fall in `SyncService` für Upsert und Rehydrierung, Muster wie bei
`progress_entries` (Server gewinnt, außer `needsSync` ist lokal gesetzt).

**Gate:** Das Anwenden auf der Live-Datenbank braucht die ausdrückliche Freigabe
des Founders und wird vorher mit genauem SQL, Auswirkung und Rücknahmeweg gezeigt
(CLAUDE.md §3).

---

## 9. Tests

**Reine Rechenlogik** (ohne Datenbank, `StreakService` mit fester Uhr):

- Serie zählt nur zusammenhängende Tage; heute offen bricht sie nicht
- Ein Tag mit mehreren Sitzungen zählt einmal
- Gemeinsames Training zählt für jedes beteiligte Profil je einen Tag
- Paketwechsel unterbricht die Serie nicht (D3)
- Punktestand: 3 Trainingstage → 1 Freischein; bei 2 ruht der Zähler
- Gerettete Tage geben keine Punkte
- Lücke von 1 Tag mit 1 Freischein → gerettet, Serie läuft weiter
- Lücke von 2 Tagen mit 2 Freischeinen → gerettet (D10)
- Lücke von 3 Tagen mit 2 Freischeinen → Serie bricht, **beide Freischeine bleiben** (D11)
- Zweimaliges Auswerten am selben Tag ändert nichts (Idempotenz)
- Rückblick endet nach 400 Tagen

**Datenbank:** Auswertung über `AppDatabase.inMemory()` mit gesetzten
Trainingseinträgen; Spiegelschreiben nach `progress_entries.daily_streak`.

**Oberfläche:** Serien-Zeile zeigt Länge, Guthaben und die drei Tageszustände;
geretteter Tag unterscheidbar von trainiertem; Hinweis „Freischein eingesetzt"
erscheint und lässt sich schließen.

**Benachrichtigung:** Termine für 7 Tage geplant; nach einem Training ist der
heutige Termin abgesagt; bei `remindersEnabled = false` wird nichts geplant; bei
leerem Guthaben greift der zweite Wortlaut.

**Vorher/Nachher-Bildschirmfotos** der Dashboard-Zeile unter
`docs/evidence/serie-freischeine/` (CLAUDE.md §7).

---

## 10. Offene Punkte

- **Mehrere Kinder, eine Abendmeldung.** Formuliert für das gewählte Profil.
  Alternative wäre eine zusammengefasste Meldung („2 Kinder haben heute noch nicht
  geübt"). Bewusst zurückgestellt, bis es Familien mit mehreren aktiven Profilen
  in nennenswerter Zahl gibt.
- **Reichweite der Benachrichtigung.** Erinnerungen sind standardmäßig aus (D5).
  Bis das Alltags-Thema die Erinnerung aktiviert, sieht die Abendmeldung kaum
  jemand. Bewusst in Kauf genommen.
- **Verlorene Trainingseinträge.** Verschwindet eine Paket-Anmeldung
  serverseitig, räumt `_discardLocalEnrollmentGraph` die zugehörigen Einträge mit
  ab — die abgeleitete Serie wäre dann kürzer. Im Normalbetrieb werden Anmeldungen
  auf „pausiert"/„abgebrochen" gesetzt, nicht gelöscht.
- **Aufräum-Migration** für die stillgelegten Spalten: eigener Vorgang, eigene
  Freigabe.

---

## 11. Nicht-Ziele

Keine Wochen- oder Monatsrückschau, keine Bestenlisten, kein Teilen der Serie,
keine serverseitigen Push-Nachrichten, keine Freischeine als Kaufprodukt, keine
Belohnungsanimationen. Die Alltagsfrage („Wann passt das Training in euren Tag?")
ist ein eigenes, nachfolgendes Thema und **nicht** Teil dieses Designs.
