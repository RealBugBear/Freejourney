# Training Start Flow + Reflexbasierte Dauerempfehlung

## Ziel

Der Einstieg in ein Trainingspaket soll fachlich vollständiger und für Nutzer verständlicher werden. Wenn ein Nutzer vom Dashboard aus `Paket starten` wählt, soll der Flow nicht nur die isometrische Partnertraining-Frage stellen, sondern auch:

1. die Vorrunde als empfohlenen Einstieg vor dem Moro-Paket anbieten,
2. die vorhandene Reflexprofil-Auswertung für das gewählte Paket berücksichtigen,
3. daraus eine nachvollziehbare Wochenempfehlung ableiten,
4. die Empfehlung schriftlich erklären, bevor das Enrollment angelegt wird.

## Aktueller Stand

- Dashboard ohne aktives Paket zeigt `Paket starten`.
- Dieser Button führt aktuell direkt zu `Routes.intakeAssessment`.
- `IntakeAssessmentScreen` fragt nur: isometrisches Partnertraining ja/nein.
- Danach führt der Flow über `TrainerOnboardingPromptScreen` zu `DurationRecommendationScreen`.
- `DurationRecommendationScreen` nutzt aktuell nur:
  - ja isometrisches Partnertraining -> 4 Wochen
  - nein -> 8 Wochen
- Die Vorrunde ist bereits als `VorrundeInterstitialScreen` vorhanden, wird aber nur im `PackagesScreen` gezeigt.
- Die Reflexprofil-Auswertung liegt in `ReflexProfileAssessment.scores` als Map mit Reflex-Key und `percent`.

## Neuer Ziel-Flow

```text
Dashboard
  -> Paket starten
  -> TrainingStartFlow
       1. Ist eine Vorrunde-Entscheidung offen?
          -> Ja: Vorrunde empfehlen
             - Vorrunde starten
             - Direkt mit Paket fortfahren
          -> Nein: weiter
       2. Gibt es fuer das ausgewaehlte Profil ein abgeschlossenes Reflexprofil?
          -> Ja: kurze Auswertungs-Zusammenfassung zeigen
          -> Nein: Reflexprofil anbieten oder bewusst ueberspringen
       3. Isometrisches Partnertraining abfragen
          -> Falls Nein: Trainer-Begleitung anbieten
       4. Dauerempfehlung berechnen und erklaeren
       5. Nutzer bestaetigt oder passt Dauer manuell an
       6. Enrollment + Intake Assessment speichern
       7. Dashboard zeigt aktives Paket
```

Wichtig: Die Vorrunde ist eine Empfehlung vor Moro, kein harter Blocker. Wer direkt mit Moro starten will, kann fortfahren. Nach Moro oder bei anderen Paketen erscheint sie nicht mehr im Paket-Startflow.

Zusätzlich soll die Vorrunde unabhängig vom Paketverlauf als freier Modus erreichbar bleiben. Dieser freie Start ist nicht Teil der Paketlogik, zählt nicht auf einen Paket-Abschlusstag ein und soll nicht den Fortschritt eines Reflexpakets verändern.

Bei mehreren Profilen muss der Startflow vorab klar anzeigen, fuer welches Profil das Paket gestartet wird. Nutzer sollen nicht versehentlich fuer das falsche Kind starten.
Das gilt auch fuer die freie Vorrunde: sie läuft immer im Kontext des aktuell ausgewählten Profils. Jedes Profil trainiert autonom.
Wenn das aktive Profil gewechselt wird, gelten freie Vorrunde, Streak und Verlauf sofort fuer dieses Profil.

## Dauerlogik

### Eingaben

- `hadIsometricWithTrainer`: bool
- `packageId`: aktuelles Trainingspaket
- `assessment.scores`: pro Reflex ein Prozentwert
- Mapping `packageId -> relevante Reflexe`

### Reflex-Mapping

Start mit den Paketen, die bereits konkret existieren:

| Package | Relevante Reflexe fuer Empfehlung |
| --- | --- |
| `moro` | `moro`, `flr` |
| `spinal_galant` | `spinalGalant` |
| `tlr` | `tlr` |

Offene Pakete werden spaeter erweitert:

| Package | Vorschlag |
| --- | --- |
| `atnr` | `atnr` |
| `stnr` | `stnr` |
| `babkin` | `babkin`, `palmar`, `plantar` |
| `such_saug` | `rootingSucking` |
| `babinski` | `babinski` |
| `landau` | `landau` |

Für Pakete mit mehreren Reflexen zählt der höchste Prozentwert der zugeordneten Reflexe. Beispiel Moro: `max(moro.percent, flr.percent)`.

Bei Moro soll die Erklärung beides leisten:

- Die Dauer wird aus dem stärkeren Wert von Moro und FLR berechnet.
- In der schriftlichen Erklärung werden Moro und FLR beide genannt, damit transparent ist, welche Reflexbereiche in die Einschätzung eingeflossen sind.
- Auf dem Dauer-Screen werden beide Einzelwerte sichtbar angezeigt, z.B. `Moro 68%` und `FLR 82%`.

### Wochen-Matrix

| Isometrisches Partnertraining | Reflexwert unter 75% | Reflexwert 75-85% | Reflexwert ueber 85% |
| --- | ---: | ---: | ---: |
| Ja | 4 Wochen | 5 Wochen | 6 Wochen |
| Nein | 6 Wochen | 7 Wochen | 8 Wochen |

Grenzwerte:

- `< 75%` -> niedrigere Stufe
- `>= 75% && <= 85%` -> mittlere Stufe
- `> 85%` -> hohe Stufe

Wenn kein verwertbarer Reflexwert vorhanden ist:

- mit isometrischem Partnertraining: 4 Wochen
- ohne isometrisches Partnertraining: 8 Wochen
- Erklärung: Standardlogik, weil kein vollständiger Reflexwert vorliegt.

Eine vorhandene Reflexprofil-Auswertung gilt vorerst nie als veraltet. Es gibt keine Ablaufgrenze nach 3 oder 6 Monaten.

## Empfehlungstext

Die Erklärung soll direkt auf dem Dauer-Screen stehen und nicht wie eine Diagnose klingen.

Sprache: nicht diagnostisch, sondern als Tendenz. Bevorzugte Formulierung:

```text
starke Hinweise auf eine Reflex-Tendenz
```

### Mit Reflexprofil

```text
Aufgrund deiner ermittelten Reflex-Tendenz empfehlen wir fuer dieses Paket eine Dauer von X Wochen.

In die Empfehlung fliesst der staerkste Wert der zum Paket gehoerenden Reflexe ein. Bei deinem Profil liegt dieser Wert bei Y%.
Da du [bereits / noch nicht] isometrisches Partnertraining gemacht hast, startet die Empfehlung im Bereich [4-6 / 6-8] Wochen.
```

Ausführlichere Variante fuer den Screen:

```text
Aufgrund deiner ermittelten Reflex-Tendenz empfehlen wir fuer dieses Paket eine Dauer von X Wochen.

Für das Moro-Paket betrachten wir sowohl Moro als auch FLR, weil beide in dieser Auswertung relevant sind. Der stärkere Hinweis liegt bei Y% und bestimmt die Dauerstufe.

Da du [bereits / noch nicht] isometrisches Partnertraining mit einer Fachperson gemacht hast, verwenden wir den Empfehlungsbereich [4 bis 6 / 6 bis 8] Wochen.
Du kannst die Empfehlung übernehmen oder die Dauer manuell anpassen.
```

Zusätzlich sollen die berücksichtigten Einzelwerte als kleine Zeilen oder Chips sichtbar sein:

```text
Moro-Tendenz: 68%
FLR-Tendenz: 82%
Für die Dauer zählt der stärkere Hinweis.
```

Wenn ein einzelner Wert trotz vorhandener Auswertung nicht belastbar ist, wird das explizit angezeigt:

```text
FLR-Tendenz: keine ausreichenden Daten
```

Wenn das Reflexprofil übersprungen wurde, werden keine Einzelwerte angezeigt; stattdessen wird klar erklärt, dass die Empfehlung aus der Standardlogik stammt.

### Ohne Reflexprofil oder uebersprungen

```text
Du hast das Reflexprofil uebersprungen oder es liegt fuer dieses Profil noch keine Auswertung vor.
Die Empfehlung nutzt deshalb die Standardlogik anhand deiner Angabe zum isometrischen Partnertraining.
```

### Vorrunde-Hinweis

```text
Die Vorrunde dient dazu, den Körper auf die kommende Integration der Reflexe vorzubereiten.
Die rhythmischen Bewegungen geben deinem Gehirn Signale, die es an den Zeitraum erinnern, in dem diese Reflexe sich ursprünglich selbst integrieren sollten.

Diese Übungen kannst du später immer wieder zur Beruhigung und Entspannung nutzen.
```

## UX-Vorschlag

### Schritt 1: Vorrunde-Karte

Zeigen, wenn:

- `vorrunde_status == unseen`
- und Nutzer startet `packageId == moro` vom Dashboard
- und fuer Moro existiert noch kein aktives oder abgeschlossenes Enrollment

Aktionen:

- `Vorrunde starten` -> `TrainingSessionScreen(packageId: 'vorrunde')` im vorbereitenden Startflow
- `Direkt mit Paket fortfahren` -> Status `skipped`, weiter im Startflow

Nach Abschluss der Vorrunde:

- `vorrunde_status = completed`
- es erscheint eine Anschlussseite mit der primären Aktion `Jetzt Moro starten`
- kein Moro-Enrollment wird automatisch erstellt
- die Moro-Dauerempfehlung wird erst beim anschliessenden Moro-Start berechnet
- die Vorrunde hat keine strenge Wochenfrequenz-Logik
- mit `Vorrunde starten` im Paketstartflow beginnt eine 4-wöchige Vorrundenphase
- die 4 Kalenderwochen zählen ab dem ersten Start der Vorrunde, nicht erst ab dem ersten abgeschlossenen Durchlauf
- der Nutzer darf nach 4 Kalenderwochen ins Moro-Paket starten, auch wenn die Vorrunde nicht oft genug pro Woche gemacht wurde
- der Nutzer darf Moro auch vor Ablauf der 4 Wochen starten; in diesem Fall erscheint nur ein Hinweis, keine Sperre
- die Anschlussseite soll direkt nach einer Vorrunden-Session erscheinen, wenn die 4 Wochen erreicht sind oder der Nutzer den vorbereitenden Vorrunden-Flow abschliesst
- die App soll aktiv anzeigen, wenn die Vorrundenphase abgeschlossen ist und Moro gestartet werden kann
- bei Moro-Start vor Ablauf der 4 Wochen reicht ein kleiner Infotext, kein eigener Confirm-Screen
- während der 4-wöchigen Vorrundenphase zeigt das Dashboard primär die Vorrunde
- nach Ablauf der 4 Wochen fokussiert das Dashboard aktiv auf `Jetzt Moro starten`; freie Vorrunde bleibt danach sekundär erreichbar

### Freie Vorrunde als Beruhigungsmodus

Unabhängig vom Paket-Startflow soll es einen separaten Button geben:

```text
Vorrunde frei starten
```

Dieser Button startet die Vorrunde als eigenständige Session zur Beruhigung, Regulation oder Entspannung.

Regeln:

- Der freie Vorrundenmodus ist jederzeit erreichbar, auch nach Moro.
- Er erstellt kein Moro-Enrollment.
- Er verändert kein aktives Paket-Enrollment.
- Er zählt nicht als Paket-Trainingstag.
- Er wird als Ereignis/Session mit `packageId: 'vorrunde'` gespeichert, muss aber in Progress-/Completion-Logik getrennt behandelt werden.
- Er darf nicht dazu führen, dass der Nutzer im Moro-Paket schneller einen Abschluss erreicht.
- Er hat keine Mindestfrequenz und keine Abschlussdruck-Logik.
- Er soll im Dashboard als `heute etwas gemacht` sichtbar sein.
- Er zählt fuer dieselbe Streak/Regelmäßigkeit wie Pakettraining.
- Er zählt nicht fuer den Fortschritt des aktiven Reflexpakets.
- Diese Streak ist als motivierendes Feedback zu verstehen: Nutzer sollen nicht benachteiligt werden, wenn sie eine Pause vom aktuellen Paket brauchen und stattdessen Vorrunde machen.
- Streak wird im ersten Schnitt lokal bzw. aus den gespeicherten Sessions abgeleitet, nicht als eigene serverseitige Streak-Tabelle.
- Wenn Pakettraining und Vorrunde am selben Tag gemacht wurden, wird in der sichtbaren Tagesaktivität einfach das Pakettraining angezeigt.
- Doppelte Ereignisse bleiben nur intern/History-seitig unterscheidbar; es braucht keine eigene sichtbare Doppel-Dokumentation.

UI-Position:

- Auf dem Dashboard unter dem aktuellen Tagespaket.
- Kein neues Banner. Die freie Vorrunde soll direkt in der aktuellen Tagespaket-Card als sekundäre Aktion/Option erscheinen.
- Der Button ist nur sichtbar, wenn ein aktives Tagespaket existiert. Wenn noch kein Paket aktiv ist, soll die Vorrunde nicht separat sichtbar sein, weil der Paketstart selbst die Einführung übernimmt.
- Wenn freie Vorrunde heute gemacht wurde, erscheint nur ein kleiner Text in der Tagespaket-Card, z.B. `Heute Vorrunde gemacht`.
- Der Paket-Button `Einheit beginnen` bleibt weiterhin verfügbar.
- Wenn Pakettraining und freie Vorrunde am selben Tag gemacht wurden, hat das Reflexpaket in Dokumentation und Tagesstatus Vorrang.
- Die Streak zählt den Tag nur einmal; beide Ereignisse können in der History sichtbar sein.
- Textlich klar getrennt vom Paket:

```text
Vorrunde zur Beruhigung
Rhythmische Bewegungen zur Beruhigung und Entspannung, unabhängig von deinem aktuellen Paket.
```

Primäre Aktion:

```text
Vorrunde frei starten
```

### Schritt 2: Reflexprofil-Auswertung

Wenn Assessment vorhanden:

- kleine Zusammenfassung zeigen:
  - Paket: Moro
  - beruecksichtigte Reflexe: Moro, FLR
  - stärkster Wert: z.B. 82%
  - resultierende Stufe: hoch

Wenn Assessment fehlt:

- `Reflexprofil machen` als primäre Aktion
- `Ohne Auswertung fortfahren` als sekundäre Aktion
- das Reflexprofil soll stark empfohlen werden, darf aber übersprungen werden
- Beim Überspringen erscheint eine Nachfrage:

```text
Ohne persönliches Reflexprofil zur Einschätzung deines Standes fortfahren?
```

### Schritt 3: Isometrisches Partnertraining

Bestehende Frage bleibt, aber Text präzisieren:

```text
Hast du zu diesem Reflex bereits isometrisches Partnertraining mit einer Fachperson gemacht?
```

Wenn die Antwort `Nein` ist, soll der bestehende Trainer-Finden-/Kontaktieren-Flow angeboten werden. Das ist eine Empfehlung, keine Sperre.

Darstellung: eigener Entscheidungsscreen, nicht nur ein kleiner Hinweis.

Vorschlag:

```text
Isometrisches Partnertraining kann die Integration vorbereiten und begleiten.
Wenn du möchtest, kannst du eine Trainerin oder einen Trainer finden und Kontakt aufnehmen.
```

Aktionen:

- `Trainer finden`
- `Ohne Trainer fortfahren`

Der bestehende Trainer-Onboarding-/Kontaktflow wird weiterverwendet. Danach führt der Startflow zurück zur Dauerempfehlung oder lässt den Nutzer bewusst ohne Trainer fortfahren.

Wenn der Nutzer `Trainer finden` öffnet und keinen Trainer kontaktiert, führt die App zurück in den Startflow, damit der Paketstart trotzdem abgeschlossen werden kann.

Diese Erinnerung erscheint bei jedem neuen Paketstart erneut, wenn `hadIsometricWithTrainer == false` ist. Sie erscheint nicht vor jeder einzelnen Trainingseinheit, sondern nur beim Start eines neuen Pakets, z.B. erneut nach Moro beim Start von Spinaler Galant.

Empfehlung fuer Trainerkontakt-Status:

- Die App empfiehlt Trainerbegleitung vor jedem neuen Paket.
- Der Paketstart bleibt ohne Trainertermin möglich, damit das Training selbstständig und ohne große Hürden funktioniert.
- Wenn Nutzer einen Trainer kontaktiert haben, aber noch kein isometrisches Partnertraining stattgefunden hat, bleibt `hadIsometricWithTrainer == false`.
- In diesem Wartezustand schlägt die App vor, die Vorrunde als niedrigschwellige Zwischenübung zu nutzen, bis ein Termin stattfindet.
- Dieser Vorrunden-Vorschlag erscheint nur, wenn der Nutzer tatsächlich `Trainer finden` gewählt hat, nicht bei direktem `Ohne Trainer fortfahren`.
- Begründung: Für die Vorrunde gibt es kein isometrisches Partnertraining; sie ist dadurch gut als harmlose, vorbereitende Regulationseinheit vertretbar.

Bestehende technische Grundlage:

- `trainer_client_relationships.status = 'pending'` bedeutet: Anfrage/Kontakt wurde gesendet, aber noch nicht aktiv angenommen.
- `trainer_client_relationships.status = 'active'` bedeutet: Trainerbeziehung ist verbunden.
- `clientTrainerConnectionsProvider` lädt bereits `pending` und `active`.

Empfehlung:

- Keinen neuen Trainerkontakt-Status einführen.
- Für den Startflow vorhandene `ClientTrainerConnection.isPending` und `.isActive` nutzen.
- Bei `pending`: Nutzer ist in Wartephase, Vorrunde als Zwischenoption anbieten.
- Bei `active`, aber ohne tatsächlich gemachtes isometrisches Partnertraining: weiterhin `hadIsometricWithTrainer == false`, aber Text auf bestehende Trainerbeziehung anpassen.

Vorschlagstext nach Trainerkontakt oder bei Wartezeit:

```text
Während du auf Rückmeldung oder einen Termin wartest, kannst du die Vorrunde nutzen.
Sie bereitet rhythmisch vor und ist unabhängig vom isometrischen Partnertraining.
```

### Schritt 4: Dauerempfehlung

Screen zeigt:

- Empfohlene Dauer groß: `6 Wochen`
- Unterzeile: `42 Tage`
- Erklärungskarte mit genutzten Faktoren
- Slider bleibt, damit Nutzer manuell anpassen kann
- Bei manueller Änderung speichern wir weiterhin:
  - `recommendedDurationWeeks`
  - `finalDurationWeeks`
  - `userAcceptedRecommendation`

Die manuelle Anpassung soll sekundär sein. Standardzustand:

- primäre Aktion: `Empfehlung übernehmen`
- sekundäre Aktion: `Dauer anpassen`

Erst nach `Dauer anpassen` wird der Slider bzw. die Wochen-Auswahl sichtbar.
Wenn Nutzer die Dauer anpassen, dürfen sie frei zwischen 4 und 8 Wochen wählen, unabhängig davon, ob isometrisches Partnertraining gemacht wurde.

Wenn kein isometrisches Partnertraining gemacht wurde, soll zusätzlich ein dezenter Hinweis bleiben:

```text
Da du noch kein isometrisches Partnertraining gemacht hast, rechnen wir mit dem längeren Empfehlungsbereich von 6 bis 8 Wochen. Du kannst jederzeit zusätzlich Kontakt zu einem Trainer aufnehmen.
```

Die Erklärung muss außerdem klar sagen, worauf die Empfehlung basiert:

- auf persönlicher Reflexprofil-Auswertung, wenn vorhanden
- auf Standardlogik, wenn Reflexprofil fehlt oder übersprungen wurde

Beispiel:

```text
Diese Empfehlung basiert auf deiner persönlichen Reflexprofil-Auswertung.
```

oder:

```text
Diese Empfehlung basiert auf der Standardlogik, weil kein persönliches Reflexprofil vorliegt.
```

## Technischer Plan

### 1. Recommendation Service

Neue kleine Domain-Datei:

`lib/features/assessment/domain/services/training_duration_recommendation_service.dart`

Verantwortung:

- `packageId -> PrimitiveReflex[]` mappen
- relevante Scores aus `ReflexProfileAssessment.scores` lesen
- höchsten Prozentwert bestimmen
- Wochenempfehlung berechnen
- erklärbare Result-Struktur zurückgeben

Vorgeschlagene API:

```dart
class TrainingDurationRecommendation {
  final int weeks;
  final double? strongestPercent;
  final Map<PrimitiveReflex, double> consideredPercents;
  final List<PrimitiveReflex> consideredReflexes;
  final bool usedAssessment;
  final bool hadIsometricWithTrainer;
}

TrainingDurationRecommendation recommendTrainingDuration({
  required String packageId,
  required bool hadIsometricWithTrainer,
  ReflexProfileAssessment? assessment,
});
```

### 2. DurationRecommendationScreen umbauen

- latest Assessment für ausgewähltes Subject laden:
  - `latestReflexProfileForSelectedSubjectProvider`
- Empfehlung mit neuem Service berechnen
- `_computeRecommendedWeeks` ersetzen
- Info-Text dynamisch aus `TrainingDurationRecommendation` erzeugen
- `createIntakeAssessment` weiterhin mit finaler Auswahl speichern

### 3. Startflow am Dashboard korrigieren

Aktuell:

```dart
onStartPackage: () => context.push(Routes.intakeAssessment)
```

Ziel:

- entweder eigene `TrainingStartFlowScreen`
- oder bestehende Screens in korrekter Reihenfolge verbinden

Pragmatische Variante:

1. Neue Route `Routes.trainingStart`
2. `TrainingStartFlowScreen` entscheidet:
   - aktives Profil sichtbar bestätigen
   - Vorrunde anzeigen oder weiterleiten
   - Assessment vorhanden/fehlt behandeln
- Reflexprofil stark empfehlen, aber Überspringen erlauben
- Trainer-Entscheidungsscreen bei fehlendem isometrischen Partnertraining anzeigen
   - bei Trainerkontakt ohne Termin/Training zurück in Startflow und Vorrunde als Warteoption anbieten
   - danach zu `IntakeAssessmentScreen`
3. Dashboard ruft nur noch `Routes.trainingStart` auf.

### 4. Vorrunde in echten Startflow integrieren

- `VorrundeInterstitialScreen` wiederverwenden
- nicht nur im `PackagesScreen` anzeigen
- Status bleibt in `VorrundeStatusSettings`
- Anschlussseite nach 4 Wochen oder nach Abschluss der Vorrundenphase: `Jetzt Moro starten`
- keine Pflicht-Frequenz wie bei Reflexpaketen
- Moro-Start vor Ablauf der 4 Wochen erlaubt, aber mit Hinweis
- freie Vorrunde bleibt danach ueber den Dashboard-Button erreichbar
- Vorrundenphase ab erstem Startdatum berechnen
- App zeigt aktiv an, wenn Moro nach Vorrunde bereit ist
- während aktiver Vorrundenphase Dashboard primär auf Vorrunde ausrichten
- nach 4 Wochen Dashboard primär auf Moro-Start ausrichten
- serverseitig in Supabase speichern; lokal nur Cache/Fallback

Speicherung:

- Vorrundenphase und Status sollen auch in Supabase gespeichert werden, damit Startdatum und Status geräteübergreifend stimmen.
- Lokale Speicherung via SharedPreferences/Drift bleibt nur Cache/Fallback.
- Der Status muss pro `subject_profile_id` geführt werden, weil jedes Profil autonom trainiert.

Vorschlag fuer Datenmodell:

```sql
create table vorrunde_phases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references profiles(id) on delete cascade,
  subject_profile_id uuid references reflex_subject_profiles(id) on delete cascade,
  status text not null default 'started'
    check (status in ('started', 'skipped', 'completed')),
  first_started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id, subject_profile_id)
);
```

Kein `package_id` speichern: Die Vorrunde ist fachlich nur Vorbereitung vor Moro, daher reicht der profilbezogene Vorrundenstatus.

Statusregeln:

- `skipped` wird serverseitig gespeichert, damit der Hinweis auf anderen Geräten nicht erneut erscheint.
- Wenn Status `skipped` ist und Nutzer später freie Vorrunde macht, bleibt der Paket-Hinweis-Status `skipped`; freie Vorrundenereignisse werden separat geloggt.
- Wenn Nutzer Moro vor Ablauf der 4 Wochen startet, bleibt die Vorrundenphase `started`. Moro-Start bedeutet nicht automatisch `completed`.
- `completed` wird nur gesetzt, wenn die 4 Wochen seit erstem Vorrundenstart erreicht sind oder die App diesen Zustand server-/clientseitig ableitet und persistiert.
- Später kann für eine vollständig 4 Wochen durchgehaltene Vorrunde ein kleines Badge/Gamification-Element ergänzt werden.
- Bei Sync-Konflikten zwischen Geräten gewinnt `updated_at` bzw. der jüngste Status.

RLS:

- Nutzer dürfen nur eigene `vorrunde_phases` lesen/schreiben.
- Trainer brauchen vorerst keinen Zugriff.

Kein Completion-Fragebogen:

- Vorrunde löst keinen Completion-Fragebogen aus.
- Das gilt für vorbereitende Vorrunde und freie Vorrunde.

### 5. Tests

Mindestens Unit-Tests fuer Recommendation Service:

- isometrisch ja, Moro 65% -> 4 Wochen
- isometrisch ja, Moro 75% -> 5 Wochen
- isometrisch ja, Moro 86% -> 6 Wochen
- isometrisch nein, Moro 65% -> 6 Wochen
- isometrisch nein, Moro 75% -> 7 Wochen
- isometrisch nein, Moro 86% -> 8 Wochen
- isometrisch ja, Moro 74.9% -> 4 Wochen
- isometrisch ja, Moro 85% -> 5 Wochen
- Moro nutzt max aus Moro/FLR
- Moro-Dauer-Screen zeigt Moro- und FLR-Einzelwerte
- Reflexwerte werden als `Moro-Tendenz` und `FLR-Tendenz` angezeigt
- fehlendes Assessment nutzt Fallback
- unbekanntes Package nutzt Fallback

Widget-/Flow-Tests optional, aber sinnvoll:

- Dashboard ohne aktives Paket führt zu Startflow statt direkt Intake
- Vorrunde unseen zeigt Interstitial
- skipped führt weiter zum Intake
- Duration-Screen zeigt Reflex-Erklärung
- Vorrunde nach 4 Wochen erlaubt Moro-Start auch bei geringer Frequenz
- Moro-Start vor 4 Wochen ist erlaubt und zeigt nur Hinweis
- freier Vorrundenstart erzeugt keine Paketfortschritte
- freier Vorrundenstart zählt fuer `heute etwas gemacht` und Streak
- freier Vorrundenstart erscheint direkt in der Tagespaket-Card, nicht als Banner
- freie Vorrunde ist ohne aktives Paket nicht sichtbar
- nach freier Vorrunde bleibt `Einheit beginnen` fuer das Reflexpaket verfügbar
- wenn Pakettraining und Vorrunde am selben Tag gemacht wurden, hat Pakettraining Vorrang in Tagesstatus/Dokumentation
- Profilwechsel trennt Streak/History je Profil
- Trainer-Entscheidungsscreen erscheint bei `hadIsometricWithTrainer == false`
- Trainer-Flow kehrt bei Abbruch/ohne Kontakt zurück in den Startflow
- Trainerkontakt ohne isometrisches Training bleibt `hadIsometricWithTrainer == false`
- nach Trainerkontakt/Wartezeit wird Vorrunde als Zwischenoption angeboten
- Vorrunden-Warteoption erscheint nur nach Klick auf `Trainer finden`
- vorhandene Trainerbeziehungen werden über `clientTrainerConnectionsProvider` ermittelt
- `pending` gilt als Wartephase nach Kontakt; `active` gilt als verbundener Trainer
- Reflexprofil fehlt: stark empfohlen, aber überspringbar
- Reflexprofil-Skip fragt `Ohne persönliches Reflexprofil zur Einschätzung deines Standes fortfahren?`
- Dauerempfehlung zeigt Quelle: persönliche Auswertung oder Standardlogik
- fehlende Einzelwerte zeigen `keine ausreichenden Daten`
- freie Vorrunde ist in Journal/Erfahrungen dokumentierbar
- nach freier Vorrunde soll wie bei Reflexpaketen ein Erfahrungs-/Journal-Eintrag angeboten werden, damit Nutzer die Dokumentation früh einüben
- Trainer haben keinen Zugriff auf `vorrunde_phases`
- bei Sync-Konflikten gewinnt der jüngste `updated_at` Stand
- wenn Moro vor Ablauf der 4 Wochen gestartet wurde, hat das aktive Moro-Enrollment im Dashboard Vorrang; Vorrunde bleibt nur sekundär

## Offene Entscheidungen

1. Gilt die Vorrunde nur vor Moro oder vor jedem allerersten Paket?
   - Entscheidung: nur vor Moro im Paket-Startflow.
2. Soll die Vorrunde nach Abschluss automatisch ein 4-Wochen-Enrollment bekommen?
   - Entscheidung: nein. Die Vorrunde bleibt vom Paketabschluss getrennt. Sie darf einen eigenen Status haben (`unseen`, `started`, `skipped`, `completed`), aber kein normales Reflexpaket-Enrollment mit Abschlusstag erzeugen.
3. Wenn mehrere Profile existieren: soll der Startflow vorab das aktive Profil deutlich anzeigen?
   - Entscheidung: ja, sonst können Eltern versehentlich mit dem falschen Kind starten.
4. Soll bei sehr hohen Reflexwerten trotz isometrischem Training ein Trainer-Hinweis erscheinen?
   - Empfehlung: nur als sanfter Hinweis, keine harte Sperre.
5. Soll die freie Vorrunde als Training-Session gespeichert werden?
   - Entscheidung: ja, aber nur als getrenntes Ereignis mit `packageId: 'vorrunde'` und ohne Einfluss auf `activeProgressProvider` fuer Reflexpakete.
6. Wie stark soll der Trainer-Hinweis sein, wenn kein isometrisches Partnertraining gemacht wurde?
   - Entscheidung: eigener Entscheidungsscreen mit `Trainer finden` und `Ohne Trainer fortfahren`.
7. Soll die Daueranpassung direkt sichtbar sein?
   - Entscheidung: nein. Empfehlung übernehmen ist primär, Dauer anpassen ist sekundär.
8. Zählt freie Vorrunde fuer Streak oder Tagesaktivität?
   - Entscheidung: ja, sie zählt als `heute etwas gemacht` und fuer die Streak, aber nicht fuer Paketfortschritt.
9. Wann gilt die Vorrunde als abgeschlossen?
   - Entscheidung: 4 Kalenderwochen nach dem ersten Start der Vorrunde.
10. Darf Moro vor Ablauf der 4 Vorrunden-Wochen gestartet werden?
   - Entscheidung: ja, mit kleinem Infotext, ohne Sperre.
11. Wird eine Reflexprofil-Auswertung irgendwann als veraltet behandelt?
   - Entscheidung: vorerst nein, nie.
12. Wie ist die freie Vorrunde bei mehreren Profilen zugeordnet?
   - Entscheidung: immer dem aktuell ausgewählten Profil. Jedes Profil hat autonomen Trainingskontext.
13. Soll der Moro-Dauer-Screen beide Einzelwerte anzeigen?
   - Entscheidung: ja. Moro-Tendenz und FLR-Tendenz werden einzeln sichtbar angezeigt; die Dauer berechnet sich aus dem stärkeren Wert.
14. Wo erscheint die freie Vorrunde im Dashboard?
   - Entscheidung: direkt in der aktuellen Tagespaket-Card, kein neues Banner.
15. Ist die freie Vorrunde ohne aktives Paket sichtbar?
   - Entscheidung: nein. Der Paketstart selbst ist die Einführung.
16. Wie wird Trainerkontakt ohne bereits erfolgtes isometrisches Training bewertet?
   - Entscheidung: weiterhin `hadIsometricWithTrainer == false`. Die App empfiehlt Trainerbegleitung, lässt den Paketstart aber zu und schlägt während der Wartezeit Vorrunde vor.
17. Kann die Dauer frei angepasst werden?
   - Entscheidung: ja, frei zwischen 4 und 8 Wochen.
18. Wie wird freie Vorrunde in der Tagespaket-Card sichtbar?
   - Entscheidung: nur kleiner Text, z.B. `Heute Vorrunde gemacht`; `Einheit beginnen` fuer das Paket bleibt sichtbar.
19. Was hat Vorrang, wenn Pakettraining und Vorrunde am selben Tag gemacht wurden?
   - Entscheidung: das Reflexpaket hat Vorrang in Tagesstatus und Dokumentation. Die Streak zählt den Tag einmal, beide Ereignisse können in der History sichtbar sein.
20. Wann erscheint der Vorrunden-Vorschlag während Trainer-Wartezeit?
   - Entscheidung: nur wenn der Nutzer `Trainer finden` geklickt hat.
21. Was startet `Vorrunde starten` im Paketstartflow?
   - Entscheidung: eine 4-wöchige Vorrundenphase ab erstem Startdatum.
22. Was zeigt das Dashboard während der Vorrundenphase?
   - Entscheidung: primär Vorrunde. Nach 4 Wochen primär `Jetzt Moro starten`.
23. Wie wird Reflexprofil-Skip bestätigt?
   - Entscheidung: mit Nachfrage `Ohne persönliches Reflexprofil zur Einschätzung deines Standes fortfahren?`.
24. Muss die Dauerempfehlung ihre Quelle nennen?
   - Entscheidung: ja, persönliche Auswertung oder Standardlogik.
25. Was passiert bei fehlenden Einzelwerten?
   - Entscheidung: `keine ausreichenden Daten` anzeigen.
26. Ist freie Vorrunde in Journal/Erfahrungen dokumentierbar?
   - Entscheidung: ja.
27. Wo wird die Vorrundenphase gespeichert?
   - Entscheidung: in Supabase pro Profil; lokal nur Cache/Fallback.
28. Wie wird die Streak gespeichert?
   - Entscheidung: erstmal lokal bzw. aus Sessions abgeleitet.
29. Wo sind doppelte Ereignisse sichtbar, wenn Pakettraining und Vorrunde am selben Tag gemacht wurden?
   - Entscheidung: nur intern/History-seitig. Sichtbarer Tagesstatus zeigt Pakettraining.
30. Wie heißt der Dashboard-Hauptbutton während der Vorrundenphase?
   - Entscheidung: `Vorrunde fortsetzen`.
31. Wohin führt `Jetzt Moro starten` nach 4 Wochen?
   - Entscheidung: in den Startflow; wenn Reflexprofil/Trainerfragen schon erledigt sind, direkt zur Dauerempfehlung.
32. Gibt es schon gespeicherten Trainerkontakt-Status?
   - Entscheidung: ja. `trainer_client_relationships` und `clientTrainerConnectionsProvider` liefern `pending` und `active`; kein neuer Status nötig.
33. Bleibt freie Vorrunde bei späteren Paketen sichtbar?
   - Entscheidung: ja, wenn ein aktives Tagespaket existiert, z.B. auch bei Spinaler Galant.
34. Erscheint beim nächsten Paket nach Moro erneut Trainerempfehlung?
   - Entscheidung: ja, wenn kein Trainer verbunden ist bzw. kein isometrisches Partnertraining fuer das neue Paket gemacht wurde. Vorrundenempfehlung erscheint nicht erneut.
35. Umfang des Implementierungsplans?
   - Entscheidung: alles sauber integrieren, inklusive Supabase-Status, Startflow, Dashboard, Streak/History-Ableitung, Trainerstatus, Journal/Erfahrungen und Tests.
36. Wird `package_id` in `vorrunde_phases` gespeichert?
   - Entscheidung: nein, Vorrunde ist nur Vorbereitung vor Moro und wird pro Profil geführt.
37. Wird `skipped` serverseitig gespeichert?
   - Entscheidung: ja, damit der Hinweis geräteübergreifend nicht erneut erscheint.
38. Was passiert, wenn nach `skipped` später freie Vorrunde gemacht wird?
   - Entscheidung: Paket-Hinweis-Status bleibt `skipped`; freie Vorrundenereignisse werden separat geloggt.
39. Wird Moro-Start vor Ablauf der 4 Wochen als Vorrunde-Completion gewertet?
   - Entscheidung: nein, Status bleibt `started`.
40. Gibt es einen Completion-Fragebogen für Vorrunde?
   - Entscheidung: nein.
41. Wird nach freier Vorrunde ein Erfahrungs-/Journal-Eintrag angeboten?
   - Entscheidung: ja, wie bei Reflexpaketen, damit Nutzer die Dokumentation einüben.
42. Haben Trainer Zugriff auf `vorrunde_phases`?
   - Entscheidung: nein, vorerst nur Nutzer selbst.
43. Wie werden Sync-Konflikte gelöst?
   - Entscheidung: jüngster `updated_at` Stand gewinnt.
44. Was zeigt das Dashboard, wenn Moro vor Ablauf der Vorrundenphase gestartet wurde?
   - Entscheidung: aktives Moro-Enrollment hat Vorrang; Vorrunde bleibt sekundär.
45. Wird aus dem Plan eine technische Spec?
   - Entscheidung: ja, als Umsetzungsgrundlage mit Dateiliste, Routen, Migrationen und Tests.

## Implementierungsreihenfolge

Enterprise-Level Umsetzung: keine Big-Bang-Änderung. Die Arbeit wird in saubere, reviewbare Schnitte geteilt, jeweils mit Tests und klarer Rollback-Möglichkeit.

### Phase 1 — Datenmodell und reine Domain-Logik

1. Supabase-Migration `vorrunde_phases` inkl. RLS, Indizes, updated_at-Trigger und Smoke-Verify-SQL.
2. Drift/Sync-/Repository-Schicht für Vorrundenphase, Supabase als Source of Truth, lokal nur Cache/Fallback.
3. `TrainingDurationRecommendationService` als reine Domain-Logik ohne UI-Abhängigkeiten.
4. Unit-Tests für Empfehlungsmatrix, Moro/FLR, fehlende Daten und Fallbacks.

Exit-Kriterien:

- Migration ist idempotent und RLS-geprüft.
- Domain-Tests laufen.
- Kein bestehender UI-Flow ist verändert.

### Phase 2 — Startflow und Dauerempfehlung

1. `TrainingStartFlowScreen` mit sichtbarer Profilbestätigung.
2. Reflexprofil stark empfehlen, Skip-Confirm ergänzen.
3. Trainer-Entscheidungsscreen mit bestehendem `pending`/`active` Status einbinden.
4. Duration-Screen auf neue Recommendation-Service-API umstellen.
5. Empfehlung-Quellenhinweis, Moro-/FLR-Tendenzen, `keine ausreichenden Daten`, sekundäre Daueranpassung.

Exit-Kriterien:

- Alter direkter Paketstart ist ersetzt.
- Nutzer kann alle Wege abschließen: mit/ohne Profil, mit/ohne Trainer, mit/ohne Vorrunde.
- Widget-/Flow-Tests für Hauptpfade vorhanden.

### Phase 3 — Vorrunde, Dashboard, Streak, Journal

1. Vorrundenphase im Startflow nur vor Moro.
2. Dashboard-Zustände: `Vorrunde fortsetzen`, nach 4 Wochen `Jetzt Moro starten`, Moro-Start vor 4 Wochen mit kleinem Infotext.
3. Freie Vorrunde in der Tagespaket-Card, kein Banner.
4. Freie Vorrunde zählt für Tagesaktivität/Streak, aber nicht Paketfortschritt.
5. Journal/Erfahrungen nach freier Vorrunde anbieten.
6. Completion-Fragebogen für Vorrunde explizit ausschließen.

Exit-Kriterien:

- Aktives Reflexpaket hat immer Vorrang im sichtbaren Tagesstatus.
- Freie Vorrunde kann Paketfortschritt nicht verändern.
- Streak/History bleibt profilbezogen.

### Phase 4 — Härtung und Release Readiness

1. `flutter analyze`
2. fokussierte Unit-/Widget-/Provider-Tests
3. RLS-Verify-SQL ausführen
4. manuelle QA-Matrix:
   - erstes Profil ohne Assessment
   - Assessment vorhanden
   - Trainer pending
   - Trainer active
   - Vorrunde skipped
   - Vorrunde started < 4 Wochen
   - Vorrunde ready >= 4 Wochen
   - Moro vor 4 Wochen
   - späteres Paket, z.B. Spinaler Galant
5. Rollback-Plan dokumentieren:
   - UI-Routing kann wieder auf alten `intakeAssessment` Flow zeigen
   - Datenmigration bleibt additive und muss nicht zurückgerollt werden

## Enterprise-Prinzipien

- Additive Datenbankänderungen: keine destructive Migrationen.
- RLS zuerst, App-Code danach.
- Domain-Logik isoliert und testbar.
- UI liest nur aus Providern/Services, keine verstreute Businesslogik in Widgets.
- Bestehende Trainer-/Session-/Progress-Strukturen wiederverwenden.
- Feature nicht halb in Settings/Dev-Tools verstecken; sobald gemerged, ersetzt der neue Startflow den alten sauber.
- Fehlerzustände sind explizit: offline, fehlendes Profil, fehlende Auswertung, pending Trainer, fehlende Reflexwerte.
- Rollback über Routing/Provider möglich, nicht über Datenbank-Downgrade.
