# Training-Announcements — Produktionsskript v1

Dieses Dokument ist der verbindliche Aufnahme-, Export- und QA-Vertrag für
`assets/sounds/announcements/manifest.v1.json`.

## Aktueller Gate-Status

| Prüfschritt | Stand |
| --- | --- |
| Manifest-Schema | `1` |
| Content-Version | `moro-2026.07.23-v1` |
| Sprachen | `de`, `en` |
| Event-IDs | 48 pro Sprache, 96 Manifest-Einträge insgesamt |
| Sprechertexte | vollständig spezifiziert; fachliche und muttersprachliche Freigabe ausstehend |
| Aufgenommene Release-MP3s | 0 von 96 |
| Gesetzte `assetKey` | 0 von 96; alle Werte sind bewusst `null` |
| Audio-Preflight | **nicht bereit**; 48 unassigned IDs pro Vollkatalog |
| Runtime-Preflight einer Solo-/Duo-Session | **nicht bereit**; 41 benötigte IDs der gewählten Sprache sind unassigned |
| Voice-Guidance-Release-Gate | **geschlossen** |

Der Skriptvertrag ist technisch vorbereitet, aber weder als fachlich
freigegeben noch als muttersprachlich abgenommen zu verstehen. Serienaufnahme
und Audioauslieferung sind ausdrücklich noch nicht freigegeben. Solange ein
`assetKey` `null` ist, darf die Runtime keine Datei annehmen, keinen
Platzhalter abspielen und nicht auf die andere Sprache ausweichen.

## Abdeckung des Runtime-Vertrags

| Gruppe | Anzahl pro Sprache |
| --- | ---: |
| Session- und globale Übungsereignisse | 10 |
| Übungsnamen (`moro_ex1` bis `moro_ex7`) | 7 |
| Solo-Positionen | 7 |
| Duo-Positionen | 7 |
| Phasenansagen (3 + 2 + 2 + 4 + 4 + 1 + 1) | 17 |
| **Gesamt** | **48** |

Eine konkrete Session benötigt 41 Einträge: die 10 globalen Ereignisse,
7 Namen, 17 Phasen und genau eine der beiden Positionsvarianten je Übung.
Der Vollkatalog enthält beide Varianten, damit Solo und Duo unabhängig
freigegeben werden können.

## Verbindliches Sprecherbriefing

- Pro Sprache wird eine professionelle muttersprachliche Stimme eingesetzt.
  Deutsch und Englisch dürfen nicht von derselben nicht-muttersprachlichen
  Ersatzstimme aufgenommen werden.
- Tonalität: ruhig, warm, klar, erwachsen und zugewandt; weder kindlich noch
  werblich, dramatisch, klinisch oder antreibend.
- Die Texte in der Tabelle sind wort- und satzzeichengenau. Es darf nichts
  übersetzt, gekürzt, ergänzt, gegendert oder improvisiert werden.
- Jeder Satz wird natürlich gesprochen. Punkte markieren eine hörbare,
  kurze Schlusskadenz; sie werden selbstverständlich nicht ausgesprochen.
- Vor der Serienaufnahme werden je Sprache ein Namens-, ein Positions- und
  ein Phasen-Sample durch Content und Audio Direction freigegeben. Dabei wird
  insbesondere die Aussprache von „Moro“ verbindlich festgelegt.
- Pro Text entstehen mindestens zwei vollständige Takes. Versprecher,
  hörbare Atemstöße, Mundgeräusche, Klicks oder angeschnittene Laute führen
  zur Neuaufnahme.
- Identische Solo-/Duo-Texte behalten zwei getrennte Event-IDs und zwei
  getrennte Release-Dateien. Ein freigegebener Master darf nur dann
  bytegleich für beide Exporte verwendet werden, wenn die Texte exakt
  identisch sind und dies im Handoff protokolliert wird.

## Dateibenennung und Manifestzuordnung

Jede Event-ID erhält genau eine Release-Datei je Sprache.

- WAV-Master:
  `<contentVersion>__<locale>__<eventId>__take<NN>.wav`
- Datei im Repository:
  `assets/sounds/announcements/<locale>/<eventId>.mp3`
- Wert in `assetKey`:
  `sounds/announcements/<locale>/<eventId>.mp3`

Beispiel:

- Master:
  `moro-2026.07.23-v1__en__exercise.moro_ex1.position.solo__take01.wav`
- Repository:
  `assets/sounds/announcements/en/exercise.moro_ex1.position.solo.mp3`
- Manifest:
  `sounds/announcements/en/exercise.moro_ex1.position.solo.mp3`

Event-ID, Locale und Groß-/Kleinschreibung werden nie verändert. Es gibt
keine Leerzeichen, Versionssuffixe oder Alternativnamen in Release-Dateien.
Ein `assetKey` wird erst gesetzt, nachdem die exakt benannte MP3 existiert,
die Locale als Flutter-Asset registriert ist und alle QA-Schritte bestanden
sind. Leere oder stumme Platzhalterdateien sind verboten.

## Technischer Aufnahme- und Exportstandard

### Master

- Mono, Linear PCM WAV, 48 kHz, 24 Bit.
- Trockene Sprachaufnahme ohne Musik, Hall, Delay, Exciter oder hörbares
  Noise-Gating.
- 100 ms Anfangsstille mit Toleranz ±50 ms; 200 ms Endstille mit Toleranz
  ±50 ms. Kein Nutzlaut darf angeschnitten sein.
- Rauschpegel in der Anfangs-/Endstille höchstens -60 dBFS; kein Brummen,
  Netzton, digitales Knistern oder wahrnehmbarer Raumwechsel zwischen Takes.

### Release-Datei

- MP3, Mono, 48 kHz, konstante Bitrate 128 kbit/s.
- Zielpegel -16 LUFS mit Toleranz ±1 LU. Bei Clips, für die das integrierte
  Gate keinen stabilen Wert liefert, gilt derselbe Zielbereich für den
  maximalen Short-Term-Wert.
- True Peak höchstens -1.0 dBTP; keine geclippten Samples.
- Keine Cover-Art, Kapitel, unnötigen ID3-Tags oder nachträgliche
  Geschwindigkeitsänderung.
- Kompression und Limiting dürfen Verständlichkeit und natürliche Dynamik
  nicht hörbar beeinträchtigen. Lautheitssprünge zwischen aufeinanderfolgenden
  Cues sind nicht zulässig.

## Exaktes DE/EN-Sprecherskript

Die Reihenfolge entspricht dem Manifest. Jede Tabellenzeile ist eine
eigenständige Event-ID und benötigt pro Sprache eine eigene Release-Datei.

| Event-ID | Deutsch (`de`) | English (`en`) |
| --- | --- | --- |
| `session.pause` | Pause. | Pause. |
| `session.resume` | Weiter. | Continue. |
| `session.complete` | Einheit abgeschlossen. | Session complete. |
| `session.safety` | Stoppe bei Schmerzen, Schwindel, Übelkeit oder deutlichem Unwohlsein. Lass anhaltende Beschwerden fachlich abklären. | Stop if you feel pain, dizziness, nausea, or significant discomfort. Seek professional advice if symptoms persist. |
| `session.countdown.3` | Drei. | Three. |
| `session.countdown.2` | Zwei. | Two. |
| `session.countdown.1` | Eins. | One. |
| `exercise.repetition.complete` | Wiederholung abgeschlossen. | Repetition complete. |
| `exercise.switch_side` | Wechsel. | Switch sides. |
| `exercise.rest` | Pause. | Rest. |
| `exercise.moro_ex1.name` | Moro fünf. | Moro five. |
| `exercise.moro_ex1.position.solo` | Lege dich auf den Rücken und strecke beide Beine aus. Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden. Du hebst abwechselnd ein Bein an. Bein hoch, halten, zurück, Seite wechseln. | Lie on your back with both legs extended. Rest your arms alongside your body with your palms facing down. You alternately raise one leg. Leg up, hold, return, switch sides. |
| `exercise.moro_ex1.position.duo` | Lege dich auf den Rücken und strecke beide Beine aus. Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden. Du hebst abwechselnd ein Bein an. Bein hoch, halten, zurück, Seite wechseln. | Lie on your back with both legs extended. Rest your arms alongside your body with your palms facing down. You alternately raise one leg. Leg up, hold, return, switch sides. |
| `exercise.moro_ex1.phase.1` | Hoch. | Up. |
| `exercise.moro_ex1.phase.2` | Halten. | Hold. |
| `exercise.moro_ex1.phase.3` | Runter. | Down. |
| `exercise.moro_ex2.name` | Moro drei. Halber Frosch. | Moro three. Half frog. |
| `exercise.moro_ex2.position.solo` | Lege dich auf den Rücken und strecke beide Beine aus. Lass beide Beine gerade und entspannt nebeneinander liegen. Du lässt abwechselnd einen Fuß am anderen Bein entlanggleiten. Fuß hochgleiten, zurück, Seite wechseln. | Lie on your back with both legs extended. Let both legs rest straight and relaxed beside each other. You alternately slide one foot along the opposite leg. Slide foot up, return, switch sides. |
| `exercise.moro_ex2.position.duo` | Lege dich auf den Rücken und strecke beide Beine aus. Lass beide Beine gerade und entspannt nebeneinander liegen. Du lässt abwechselnd einen Fuß am anderen Bein entlanggleiten. Fuß hochgleiten, zurück, Seite wechseln. | Lie on your back with both legs extended. Let both legs rest straight and relaxed beside each other. You alternately slide one foot along the opposite leg. Slide foot up, return, switch sides. |
| `exercise.moro_ex2.phase.1` | Hoch. | Up. |
| `exercise.moro_ex2.phase.2` | Runter. | Down. |
| `exercise.moro_ex3.name` | Moro vier. Frosch. | Moro four. Frog. |
| `exercise.moro_ex3.position.solo` | Lege dich auf den Rücken und strecke beide Beine aus. Führe die Fußsohlen zusammen. Du bewegst beide Füße gemeinsam. Füße heran, Knie öffnen, Füße zurück. | Lie on your back with both legs extended. Bring the soles of your feet together. You move both feet together. Feet in, knees open, feet back. |
| `exercise.moro_ex3.position.duo` | Lege dich auf den Rücken und strecke beide Beine aus. Führe die Fußsohlen zusammen. Du bewegst beide Füße gemeinsam. Füße heran, Knie öffnen, Füße zurück. | Lie on your back with both legs extended. Bring the soles of your feet together. You move both feet together. Feet in, knees open, feet back. |
| `exercise.moro_ex3.phase.1` | Ran. | In. |
| `exercise.moro_ex3.phase.2` | Zurück. | Back. |
| `exercise.moro_ex4.name` | Moro eins. | Moro one. |
| `exercise.moro_ex4.position.solo` | Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie zusammen. Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden. Du bewegst beide Knie zu jeder Seite. Rechts, Mitte, links, Mitte. | Lie on your back. Place your feet on the floor and keep your knees together. Rest your arms alongside your body with your palms facing down. You move both knees to each side. Right, centre, left, centre. |
| `exercise.moro_ex4.position.duo` | Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie zusammen. Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden. Du bewegst beide Knie zu jeder Seite. Rechts, Mitte, links, Mitte. | Lie on your back. Place your feet on the floor and keep your knees together. Rest your arms alongside your body with your palms facing down. You move both knees to each side. Right, centre, left, centre. |
| `exercise.moro_ex4.phase.1` | Rechts. | Right. |
| `exercise.moro_ex4.phase.2` | Mitte. | Centre. |
| `exercise.moro_ex4.phase.3` | Links. | Left. |
| `exercise.moro_ex4.phase.4` | Mitte. | Centre. |
| `exercise.moro_ex5.name` | Moro zwei. | Moro two. |
| `exercise.moro_ex5.position.solo` | Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie zusammen. Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden. Du rollst Kopf und Oberkörper mit der Ausatmung an. Ausatmen, hochrollen, halten, ablegen. | Lie on your back. Place your feet on the floor and keep your knees together. Rest your arms alongside your body with your palms facing down. You curl your head and upper body as you exhale. Exhale, roll up, hold, lower. |
| `exercise.moro_ex5.position.duo` | Lege dich auf den Rücken. Stelle die Füße auf und halte die Knie zusammen. Lege die Arme lang neben den Körper. Die Handflächen zeigen zum Boden. Du rollst Kopf und Oberkörper mit der Ausatmung an. Ausatmen, hochrollen, halten, ablegen. | Lie on your back. Place your feet on the floor and keep your knees together. Rest your arms alongside your body with your palms facing down. You curl your head and upper body as you exhale. Exhale, roll up, hold, lower. |
| `exercise.moro_ex5.phase.1` | Ausatmen. | Exhale. |
| `exercise.moro_ex5.phase.2` | Hochrollen. | Roll up. |
| `exercise.moro_ex5.phase.3` | Halten. | Hold. |
| `exercise.moro_ex5.phase.4` | Ablegen. | Lower. |
| `exercise.moro_ex6.name` | Moro sechs. Isometrischer Gegendruck. | Moro six. Isometric counterpressure. |
| `exercise.moro_ex6.position.solo` | Lege dich auf den Rücken und winkle beide Beine an. Lege die überkreuzten Hände auf Knie oder Schienbeine. Baue leichten Gegendruck auf. Halte sieben Sekunden. Löse drei Sekunden. Wechsle nach drei Wiederholungen das Armkreuz. | Lie on your back with both legs bent. Place your crossed hands on your knees or shins. Build gentle counterpressure. Hold for seven seconds. Release for three seconds. Switch the arm cross after three repetitions. |
| `exercise.moro_ex6.position.duo` | Lege dich auf den Rücken und winkle beide Beine an. Lege die überkreuzten Hände auf Knie oder Schienbeine. Baue leichten Gegendruck auf. Halte sieben Sekunden. Löse drei Sekunden. Wechsle nach drei Wiederholungen das Armkreuz. | Lie on your back with both legs bent. Place your crossed hands on your knees or shins. Build gentle counterpressure. Hold for seven seconds. Release for three seconds. Switch the arm cross after three repetitions. |
| `exercise.moro_ex6.phase.1` | Spannung. | Tension. |
| `exercise.moro_ex7.name` | Moro sieben. Überkreuzter Gegendruck. | Moro seven. Crossed counterpressure. |
| `exercise.moro_ex7.position.solo` | Lege dich auf den Rücken und winkle beide Beine an. Lege die überkreuzten Hände auf Oberschenkel oder Knie. Lass Beine und Hände kontrolliert gegeneinander arbeiten. Halte sieben Sekunden. Löse drei Sekunden. Wechsle nach drei Wiederholungen das Armkreuz. | Lie on your back with both legs bent. Place your crossed hands on your thighs or knees. Let your legs and hands work against each other with control. Hold for seven seconds. Release for three seconds. Switch the arm cross after three repetitions. |
| `exercise.moro_ex7.position.duo` | Lege dich auf den Rücken und winkle beide Beine an. Lege die überkreuzten Hände auf Oberschenkel oder Knie. Lass Beine und Hände kontrolliert gegeneinander arbeiten. Halte sieben Sekunden. Löse drei Sekunden. Wechsle nach drei Wiederholungen das Armkreuz. | Lie on your back with both legs bent. Place your crossed hands on your thighs or knees. Let your legs and hands work against each other with control. Hold for seven seconds. Release for three seconds. Switch the arm cross after three repetitions. |
| `exercise.moro_ex7.phase.1` | Spannung. | Tension. |

## QA- und Übergabeprozess

Für jeden der 96 Exporte enthält die Handoff-Liste mindestens:

- Content-Version, Event-ID, Locale und exakten Sprechertext,
- Sprecher:in, Session-/Take-Nummer und Aufnahmedatum,
- WAV- und MP3-Dateiname,
- Dauer, Sample-Rate, Bit-Tiefe beziehungsweise Bitrate, Kanalzahl,
- LUFS, True Peak und gemessenen Rauschpegel,
- SHA-256 von freigegebenem Master und Release-Datei,
- Content-Reviewer, Native-Language-Reviewer und Audio-QA mit Datum.

Freigabe erfolgt in dieser Reihenfolge:

1. **Text-QA:** Aufnahme wortgleich gegen die Tabellenzeile abhören.
2. **Native-Language-QA:** Aussprache, Betonung, Grammatik und Natürlichkeit
   durch eine muttersprachliche Person bestätigen.
3. **Technische QA:** Format, Kanalzahl, Sample-Rate, Bitrate, Lautheit,
   True Peak, Stille, Rauschen und Dateinamen automatisiert prüfen.
4. **Hör-QA:** Jeden Export vollständig über Studiokopfhörer und mindestens
   einen realen Telefonspeaker abhören.
5. **Sequenz-QA:** Name + Position, Countdown, Phasen, Wechsel, Pause/Weiter
   und Abschluss in realer Runtime-Reihenfolge prüfen; keine Cue darf
   abgeschnitten werden oder eine andere überlagern.
6. **Manifest-Ingest:** Erst jetzt Datei kopieren und ihren exakten
   `assetKey` eintragen. Die andere Sprache bleibt unabhängig gesperrt.
7. **Preflight:** Für `de` und `en` dürfen im freizugebenden Scope keine
   `missingEntryIds`, `unassignedEntryIds`, `invalidAssetKeys` oder
   `missingAssetKeys` verbleiben; `isReady` muss jeweils `true` sein.
8. **Release-Evidence:** Handoff-Liste, Prüfprotokoll, Hashes und Testergebnis
   versioniert ablegen.

Jede Textänderung nach der Aufnahme erfordert eine neue Content-Version,
Neuaufnahme des betroffenen Events und erneute QA. Eine Änderung am
Manifesttext ohne passende neue Audiodatei öffnet das Release-Gate nicht.
