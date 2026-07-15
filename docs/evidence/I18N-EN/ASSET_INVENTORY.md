# I18N-EN Asset-Inventar

Stand: 2026-07-15, 22:52 CEST
Geprüfter Git-Stand: `57182b9` mit laufenden, nicht für diese Inventur
veränderten Arbeitskopie-Diffs

## Ergebnis

- **Trainingsbilder: PASS.** Alle 29 vorhandenen Rasterbilder unter
  `assets/images/trainings/` wurden einzeln visuell geprüft. Keines enthält
  eingebetteten deutschen oder sonstigen Text. Sichtbar sind nur Personen,
  Gegenstände und sprachneutrale Bewegungspfeile.
- **Weitere sichtbare Raster: PASS für eingebetteten Text.** Die Brand-,
  App-Icon-, Launch- und Plattformfamilien wurden vollständig inventarisiert
  und je eigenständiger Familie visuell stichprobenartig geprüft. Es wurde kein
  eingebetteter Text gefunden.
- **SVG: nicht vorhanden.** Im Runtime-/Packaging-Scope gibt es keine
  `.svg`-Dateien.
- **Audio-Announcements: BLOCKIERT.** Unter
  `assets/sounds/announcements/` liegt keine einzige Audiodatei. Der
  vorhandene deutsche Baum enthält nur `.gitkeep`; ein englischer Baum fehlt
  vollständig. Damit ist nicht nur die bestätigte EN-Audio-Lücke offen, sondern
  auch die aktuell vom Code referenzierte deutsche Sprachansage nicht im Bundle
  vorhanden.

Die deutschsprachigen Bestandteile mancher **Dateinamen** (zum Beispiel
`Vorbereitung` oder `Spinaler Galant Reflex`) sind nicht in die Pixel
eingebrannt und werden von `Image.asset` nicht angezeigt. Sie sind daher kein
nutzersichtbarer Übersetzungsfehler. Sie dürfen jedoch nicht später als
Fallback-Anzeigename in der UI verwendet werden.

## Prüfumfang und Methode

Inventarisiert wurden:

1. alle Raster-/SVG-Dateien unter `assets/`;
2. alle paketierten App-Icon- und Launch-Raster unter `android/`, `ios/`,
   `macos/`, `web/` sowie das Windows-ICO;
3. der vollständige Inhalt von `assets/sounds/announcements/`;
4. alle in `lib/` referenzierten lokalen Bild- und Announcement-Pfade sowie die
   Asset-Deklarationen in `pubspec.yaml`.

Werkzeuge: `rg --files`, `file`, `sips`, `ffprobe`, SHA-256-Vergleich und
manuelle Bildansicht. Alle 29 Trainingsbilder wurden vollständig betrachtet;
bei reinen Größen-/Density-Ableitungen von App-Icons wurde jeweils der Master
und mindestens ein Repräsentant jeder Plattformfamilie betrachtet.

| Bereich | Inventarisiert | Visuell geprüft | Ergebnis eingebetteter Text |
|---|---:|---:|---|
| `assets/images/trainings/**` | 29 | 29 | keiner |
| weitere Raster unter `assets/**` | 48 | 8 repräsentative Dateien | keiner |
| paketierte Plattform-Raster/ICO | 42 | 8 repräsentative Dateien | keiner |
| SVG | 0 | 0 | nicht vorhanden |
| Announcement-Audiodateien | 0 | 0 | nicht prüfbar; Dateien fehlen |
| **Gesamt Raster/ICO** | **119** | **45** | **kein sichtbarer Text gefunden** |

Nicht als Produktassets gezählt wurden `docs/evidence/**` und
`design/icon_previews*/**`: Das sind QA-Evidenz beziehungsweise
Designarbeitsdateien, keine von der App ausgelieferten UI-Assets.

## Trainingsbilder: vollständiges Pfadinventar

### Moro — 6 Dateien, alle visuell textfrei

```text
assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_06.png
assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_1.png
assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_2.png
assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_3.png
assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_4.png
assets/images/trainings/moro/FRI_App_FLR und Moro Reflex_5.png
```

Alle sechs Dateien sind 3750 × 3750 px. Die Bilder zeigen
Bewegungspositionen und Pfeile, aber keine Beschriftungen.

### Spinal Galant — 4 Dateien, alle visuell textfrei

```text
assets/images/trainings/spinal_galant/FRI_App_Spinaler Galant Reflex_0.png
assets/images/trainings/spinal_galant/FRI_App_Spinaler Galant Reflex_02.png
assets/images/trainings/spinal_galant/FRI_App_Spinaler Galant Reflex_03.png
assets/images/trainings/spinal_galant/FRI_App_Spinaler Galant Reflex_04.png
```

Alle vier Dateien sind 3750 × 3750 px. Die Bilder zeigen Positionen und
Bewegungspfeile, aber keine Beschriftungen.

### TLR — 5 Dateien, alle visuell textfrei

```text
assets/images/trainings/tlr/tlr1.jpeg
assets/images/trainings/tlr/tlr2.jpeg
assets/images/trainings/tlr/tlr3.jpeg
assets/images/trainings/tlr/tlr4.jpeg
assets/images/trainings/tlr/tlr5.jpeg
```

Die JPEGs sind 706–857 px breit und 278–615 px hoch. Zu sehen sind
Bewegungsillustrationen, Pfeile, ein Kissen und ein Fahrrad; es gibt keine
Beschriftungen.

### Babkin — 1 Datei, visuell textfrei

```text
assets/images/trainings/babkin/1babkin.jpeg
```

Das Bild ist 768 × 288 px und zeigt eine Position mit Bewegungspfeil, aber
keine Beschriftung.

### Vorrunde/Vorbereitung — 13 Dateien, alle visuell textfrei

```text
assets/images/trainings/vorrunde/FRI_App_Vorbereitung_0.png
assets/images/trainings/vorrunde/Vorbereitung_duo_01.png
assets/images/trainings/vorrunde/Vorbereitung_duo_02.png
assets/images/trainings/vorrunde/Vorbereitung_duo_03.png
assets/images/trainings/vorrunde/Vorbereitung_duo_04.png
assets/images/trainings/vorrunde/Vorbereitung_duo_05.png
assets/images/trainings/vorrunde/Vorbereitung_duo_06.png
assets/images/trainings/vorrunde/Vorbereitung_solo_01.png
assets/images/trainings/vorrunde/Vorbereitung_solo_02.png
assets/images/trainings/vorrunde/Vorbereitung_solo_03.png
assets/images/trainings/vorrunde/Vorbereitung_solo_04.png
assets/images/trainings/vorrunde/Vorbereitung_solo_05.png
assets/images/trainings/vorrunde/Vorbereitung_solo_06.png
```

Alle 13 Dateien sind 3750 × 3750 px. Die Bilder zeigen Solo- beziehungsweise
begleitete Ausgangspositionen und Pfeile, aber keine Beschriftungen.

### Deklarierte, aber leere Trainingsbildfamilien

Diese in `pubspec.yaml` deklarierten Verzeichnisse enthalten derzeit keine
Raster-/SVG-Datei, sondern nur `.gitkeep`:

```text
assets/images/trainings/atnr/
assets/images/trainings/babinski/
assets/images/trainings/landau/
assets/images/trainings/stnr/
assets/images/trainings/such_saug/
```

## Weitere Raster- und Plattformfamilien

### Runtime-Brand-Assets

| Pfad | Größe | Prüfung |
|---|---:|---|
| `assets/images/brand/free.png` | 138 × 132 | Origami-Vogel, textfrei |
| `assets/images/brand/origami_bird_mark.png` | 1024 × 1024 | Origami-Vogelmarke, textfrei |
| `assets/icon.png` | 138 × 132 | bytegleich mit `brand/free.png`, textfrei |
| `assets/icon_original.png` | 1024 × 1024 | ältere abstrakte Icon-Idee, textfrei |

`pubspec.yaml` bindet den gesamten Brand-Ordner als Runtime-Asset ein und
verwendet `origami_bird_mark.png` als Quelle für `flutter_launcher_icons`.

### Asset-interne Icon-/Store-Quellen

| Pfadfamilie | Anzahl | Prüfung |
|---|---:|---|
| `assets/images/AppIcons/Assets.xcassets/AppIcon.appiconset/*.png` | 37 | 1024-Master geprüft, textfrei |
| `assets/images/AppIcons/android/mipmap-*/corejourney1.png` | 5 | xxxhdpi geprüft, textfrei |
| `assets/images/AppIcons/appstore.png` | 1 | geprüft, textfrei; bytegleich mit 1024-Master |
| `assets/images/AppIcons/playstore.png` | 1 | geprüft, textfrei |

Diese Familie zeigt ein violett-blaues abstraktes Symbol und unterscheidet sich
von den aktuell paketierten mobilen Origami-Vogel-Icons. Der Ordner ist nicht
als Flutter-Runtime-Asset deklariert und wirkt wie eine ältere oder separate
Store-Designquelle.

### Tatsächlich paketierte Plattform-Raster

| Pfadfamilie | Anzahl | Repräsentativ geprüft | Befund |
|---|---:|---|---|
| `android/app/src/main/res/mipmap-*/ic_launcher.png` | 5 | xxxhdpi | Origami-Vogel, textfrei |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png` | 21 | 1024-Master | Origami-Vogel, textfrei |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png` | 3 | 3x | leere/weiße Launch-Grafik, textfrei |
| `macos/Runner/Assets.xcassets/AppIcon.appiconset/*.png` | 7 | 1024-Master | Flutter-Standardlogo, textfrei |
| `web/favicon.png`, `web/icons/*.png` | 5 | Favicon, normal, maskable | Flutter-Standardlogo, textfrei |
| `windows/runner/resources/app_icon.ico` | 1 | nach PNG konvertierte Ansicht | Flutter-Standardlogo, textfrei |

Für den aktuellen Mobile-Scope sind Android und iOS sprachneutral. Falls
macOS, Web oder Windows veröffentlicht werden sollen, ist das dort verbliebene
Flutter-Standardbranding ein separater Release-/Branding-Punkt, kein
Übersetzungsproblem.

## Audio-Announcement-Inventar

Vorhanden sind ausschließlich Platzhalterdateien:

```text
assets/sounds/announcements/de/.gitkeep
assets/sounds/announcements/de/exercises/.gitkeep
```

Nicht vorhanden:

```text
assets/sounds/announcements/en/
assets/sounds/announcements/en/exercises/
```

`pubspec.yaml` deklariert nur die beiden deutschen Verzeichnisse. Zum
Prüfzeitpunkt referenziert der Trainingscode folgende Muster als lokale MP3s:

```text
assets/sounds/announcements/de/wechsel.mp3
assets/sounds/announcements/de/weiter.mp3
assets/sounds/announcements/de/pause.mp3
assets/sounds/announcements/de/exercises/{exerciseId}_phase_{index}.mp3
assets/sounds/announcements/de/exercises/{exerciseId}_name.mp3
assets/sounds/announcements/de/exercises/{exerciseId}_position.mp3
assets/sounds/announcements/de/exercises/{exerciseId}_position_duo.mp3
```

Keine dieser Dateien existiert im Repository. `AudioAnnouncementService`
fängt den Ladefehler ab und schreibt ihn nur ins Debug-Log; der Sprachmodus
kann daher ohne Crash stumm bleiben. Für vollständiges DE/EN ist eine
produktseitige Entscheidung nötig: beide Sprachpakete liefern und
locale-abhängig wählen oder den Sprachmodus bis dahin nicht als verfügbare
Funktion anbieten.

Außerhalb des Announcement-Baums existieren zwei je 70 ms lange, nicht als
Sprache verwendete Rhythmus-Cues:

```text
assets/sounds/rhythm_arrive.wav
assets/sounds/rhythm_hold_end.wav
```

Sie sind kein DE/EN-Übersetzungsbedarf.

## Offene Asset-Risiken und Unsicherheiten

### 1. Elf lokale Trainingsbildpfade lösen nicht auf

Ein statischer Abgleich aller `assets/images/...`-Literale in `lib/` ergab
elf nicht vorhandene Dateien:

```text
assets/images/trainings/moro/moro1.1.jpeg
assets/images/trainings/moro/moro1.2.jpeg
assets/images/trainings/moro/moro1.3.jpeg
assets/images/trainings/moro/moro4.png
assets/images/trainings/moro/moro5.png
assets/images/trainings/moro/moro6.png
assets/images/trainings/moro/moro7.png
assets/images/trainings/spinal_galant/1spin.jpeg
assets/images/trainings/spinal_galant/2spin.jpeg
assets/images/trainings/spinal_galant/3spin.jpeg
assets/images/trainings/spinal_galant/4spin.jpeg
```

In beiden Ordnern liegen anders benannte Bilder. Ob synchronisierte
Supabase-Daten diese lokalen Fallbackpfade im Produktbetrieb ersetzen, wurde
nicht geprüft; Produktions-DB und Storage waren ausdrücklich außerhalb des
Scopes. Vor Release ist ein Runtime-Abgleich der tatsächlichen Exercise-Daten
gegen die gebündelten Assetpfade erforderlich.

### 2. EXIF-GPS-Blöcke in sechs JPEGs

`file(1)` meldet in allen fünf TLR-JPEGs und in `1babkin.jpeg` EXIF-GPS-Daten
aus einem iPhone. Koordinaten wurden bewusst nicht extrahiert oder in diesen
Report übernommen. Das ist kein i18n-Fehler, aber ein separater
Privacy-/Asset-Hygiene-Punkt: Metadaten sollten vor Auslieferung entfernt oder
bewusst freigegeben werden.

### 3. Remote- und Video-Inhalte nicht inhaltlich geprüft

- Remote-Bilder, Remote-Audio und Exercise-Metadaten in Supabase wurden nicht
  abgerufen.
- Unter `assets/VIdeos/` liegen zwölf MOV-Dateien, während `pubspec.yaml`
  festhält, dass Videos aus Supabase Storage gestreamt und nicht gebündelt
  werden. Diese Videos wurden in diesem Raster-/SVG-/Announcement-Auftrag nicht
  auf eingebrannten Text, Untertitel oder gesprochene Sprache geprüft. Vor einer
  EN-Veröffentlichung benötigen tatsächlich ausgelieferte Videos einen
  separaten Medienaudit.

### 4. Grenzen der visuellen Prüfung

Rasterbilder haben keine durchsuchbare Textebene. Die Trainingsbilder wurden
deshalb vollständig manuell betrachtet; reine Density-Ableitungen wurden über
ihre Masters stichprobenartig geprüft. Es wurde kein sichtbarer Text gefunden.
Eine automatisierte OCR war nicht verfügbar, würde die hier sichtbaren großen,
textfreien Illustrationen aber voraussichtlich nicht materiell anders
bewerten.

## Abschlussstatus

| Teilbereich | Status | Nächster Owner-Schritt |
|---|---|---|
| Eingebetteter Text in Trainingsbildern | ✅ frei von DE-Text | keiner |
| Eingebetteter Text in Brand-/Mobile-Icons | ✅ frei von DE-Text | keiner für i18n |
| Englische Sprachansagen | ❌ fehlen vollständig | EN-Audiopaket/Produktentscheidung |
| Deutsche Sprachansagen | ❌ referenziert, aber nicht gebündelt | DE-Audiopaket/Produktentscheidung |
| Fehlende lokale Moro-/Spinal-Galant-Pfade | ⚠️ offen | Runtime-/Datenabgleich |
| Leere Trainingsbildfamilien | ⚠️ offen | Content-Scope bestätigen |
| JPEG-GPS-Metadaten | ⚠️ offen, nicht i18n | Privacy-/Asset-Hygiene-Prüfung |
| Remote-Videos und Remote-Assets | ⚠️ nicht geprüft | separater Medien-/Storage-Audit |
