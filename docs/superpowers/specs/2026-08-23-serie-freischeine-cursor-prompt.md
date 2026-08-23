# Cursor-Prompt — Serie und Freischeine

> Dieser Prompt ist eigenständig. Er wird als erste Nachricht in eine frische
> Cursor-Sitzung eingefügt. Alles ab „## Auftrag“ ist der Prompt selbst.

---

## Auftrag

Du machst in diesem Repository die tägliche Trainingsserie („Serie“) sichtbar
und korrekt, und baust ein Guthaben aus höchstens zwei „Freischeinen“, das einen
verpassten Tag automatisch rettet.

**Arbeitsverzeichnis:** `/Users/alexandermessinger/dev/claudvibes/reflexjourney`
(Flutter-App, eigenes git-Repo). Alles in diesem Auftrag passiert in **diesem**
Repo. Der Admin-Bereich, die Website und die Produkt-Specs liegen in einem
**anderen** Repo eine Ebene höher — die fasst du nicht an. Prüfe vor jedem
Commit mit `git rev-parse --show-toplevel`, wo du bist.

### Verbindliche Quellen, in dieser Reihenfolge

1. `docs/superpowers/plans/2026-08-23-serie-und-freischeine.md`
   — **der Umsetzungsplan.** Zwölf Schritte, jeder mit Test, Code und Commit.
   Er ist deine Arbeitsanweisung. Arbeite ihn der Reihe nach ab.
2. `docs/superpowers/specs/2026-08-23-serie-und-freischeine-design.md`
   — **die maßgebliche Spezifikation.** Sie begründet, warum der Plan so
   aussieht, und enthält die vierzehn Entscheidungen des Auftraggebers (D1–D14).
   Bei jedem Widerspruch zwischen Plan und Spec gewinnt die **Spec**. Fällt dir
   ein Widerspruch auf, melde ihn, statt ihn eigenmächtig aufzulösen.
3. `CLAUDE.md` und `AGENTS.md` im Wurzelverzeichnis — Hausregeln, Architektur,
   Qualitätsschranken, bekannte Fehlerquellen. Bindend.
4. `tasks/lessons.md` — Fehler, die schon einmal gemacht wurden.

Lies 1 und 2 vollständig, bevor du die erste Datei anfasst.

### Grundhaltung

Der Auftraggeber ist Einzelunternehmer und nicht technisch. Erkläre in einfacher
Sprache, was du tust. Erfinde keine Belege: „getestet“, „verifiziert“, Commit-
Hashes und Testzahlen schreibst du erst, nachdem der Befehl tatsächlich gelaufen
ist und du seine Ausgabe gesehen hast.

Die App ist gesundheitsnah und enthält Daten von Kindern. Sei entsprechend
vorsichtig.

---

## Harte Verbote

Diese Punkte sind nicht verhandelbar. Wenn du glaubst, einen davon brechen zu
müssen, halte an und frage.

1. **Schritt 10 des Plans ist nicht Teil dieses Auftrags.** Du legst **keine**
   Migrationsdatei an, fasst `supabase/` nicht an und ergänzt **keine**
   Rehydrierung in `SyncService`. Du springst von Schritt 9 direkt zu Schritt 11.
   Grund: Das ist der einzige Schritt, der die Live-Datenbank berührt, und er
   braucht die persönliche Freigabe des Auftraggebers.
2. **`kStreakCreditsServerSyncEnabled` bleibt `false`.** Diese Konstante
   entsteht in Schritt 5 und gehört zu Schritt 10. Setze sie nicht auf `true`.
   Solange die Server-Tabelle nicht existiert, würde jeder Sync-Auftrag
   fehlschlagen und als Leiche in der Warteschlange liegen bleiben.
3. **Kein `git push`.** Ein Push kann den Produktions-Deploy auslösen. Lokale
   Commits sind erwünscht — einer pro Schritt, wie im Plan.
4. **Keine mutierenden Befehle auf der Live-Datenbank.** Es gibt genau ein
   Supabase-Projekt und es enthält echte Nutzerdaten. Kein `supabase db push`,
   kein SQL über die API, keine Änderung an Secrets, Auth-Einstellungen oder
   Edge Functions.
5. **Keine Nutzerdaten in die Ausgabe.** Keine Namen, E-Mails, Journal- oder
   Nachrichteninhalte, keine Tokens, keine Geheimniswerte — auch nicht als
   „Beleg“. Zähler, Wahrheitswerte, Tabellen- und Policy-Namen sind erlaubt.
6. **Keine generierten Dateien von Hand bearbeiten.** `app_localizations*.dart`
   und `*.g.dart` entstehen ausschließlich über `flutter gen-l10n` bzw.
   `dart run build_runner build`. Sie werden committet, aber nie editiert.
7. **Keine Heilversprechen** in Texten. Beschrieben werden Tätigkeiten, nie
   Wirkung, Therapie oder Diagnose.
8. **Keine Belohnungsanimation, kein Popup, keine Bestenliste.** Die Spec listet
   das unter Nicht-Zielen. Eine Serie soll bei Eltern von Kindern mit
   Auffälligkeiten keinen Druck erzeugen — die Freischeine sind genau die
   Gegenmaßnahme, und laute Feiern arbeiten dagegen.

---

## Arbeitsweise

- **Ein Schritt nach dem anderen.** Fange keinen Schritt an, bevor der
  vorherige grün ist und committet.
- **Test zuerst.** Jeder Schritt im Plan beginnt mit einem Test, der
  fehlschlagen **muss**. Lass ihn laufen und sieh den Fehlschlag, bevor du die
  Implementierung schreibst. Ein Test, der sofort grün ist, testet nichts.
- **Der Code im Plan ist der Code.** Wo der Plan einen Codeblock zeigt,
  übernimm ihn. Wenn er nicht kompiliert oder nicht in den umliegenden Code
  passt, ist das ein Planfehler — melde ihn, statt ihn stillschweigend
  umzuschreiben.
- **Ein Commit pro Schritt**, mit der im Plan angegebenen Nachricht. Prüfe
  unmittelbar davor `git diff --cached --name-status`: Es dürfen genau die
  geplanten Dateien drinstehen und nichts aus einer früheren, fremden Änderung.
- **Melde dich zwischen den Schritten** mit zwei bis drei Sätzen, was gelaufen
  ist und mit welchem Testergebnis.
- Ist der Arbeitsbaum beim Start nicht sauber, halte an und zeige, was
  offensteht. Vermische fremde Änderungen niemals mit deinen Commits.

---

## Die Schritte

Der Plan beschreibt sie vollständig. Hier nur die Reihenfolge und was jeweils
dabei herauskommt:

| Schritt | Ergebnis |
|---|---|
| 1 | Wertobjekt für das Freischein-Konto, DST-sichere Datumshelfer |
| 2 | Verdienen: drei Trainingstage ergeben einen Freischein |
| 3 | Einsetzen: nur wenn das Guthaben die ganze Lücke deckt |
| 4 | Serienlänge und die zusammengesetzte Auswertung |
| 5 | Lokale Tabelle, Repository, Trainingstage aus `training_sessions` |
| 6 | Auswertungsdienst und Riverpod-Verdrahtung |
| 7 | Die Serien-Zeile auf dem Dashboard |
| 8 | Die drei alten Streak-Rechnungen entfernen |
| 9 | Die Abend-Benachrichtigung |
| ~~10~~ | **entfällt** — siehe Verbot 1 |
| 11 | Gemeinsame Abfrage „wer trainiert mit?“ |
| 12 | Dieselbe Abfrage beim manuellen Eintragen |

Nach Schritt 12 ist der Auftrag fertig. Die Freischeine liegen dann nur auf dem
Gerät — das ist der beabsichtigte Zwischenstand, kein Mangel.

---

## Fallen in diesem Auftrag

Diese Stellen gehen erfahrungsgemäß schief. Sie stehen alle im Plan, aber hier
noch einmal deutlich:

**Die alte Streak-Rechnung gibt es dreimal, nicht zweimal.** In
`training_completion_repository.dart` (geführtes Training), in
`progress_provider.saveCompletedSession` (manuelles Eintragen) und in
`progress_provider.saveVorrundeRegulationSession` (Vorrunde). Nach Schritt 8
muss

```bash
grep -rn "dailyStreak\|weeklyStreak\|trainingsThisWeek" lib/features/ --include="*.dart"
```

außerhalb der neuen Streak-Dateien und der Spiegel-Schreibung in
`streak_credits_repository.dart` **nichts** mehr finden. Wenn doch, ist der
Schritt nicht fertig.

**Datumsrechnung nie mit `Duration(days: 1)`.** Nutze ausschließlich `nextDay`
und `previousDay` aus Schritt 1. Über eine Zeitumstellung hinweg verschiebt sich
ein 24-Stunden-Sprung auf den falschen Kalendertag, und die Serie zählt still
falsch. Das ist der Grund, warum die Helfer überhaupt existieren.

**Nach der Drift-Änderung in Schritt 5** muss `dart run build_runner build
--delete-conflicting-outputs` laufen, und die Schema-Version geht von 8 auf 9.
Danach `flutter test` vollständig laufen lassen — eine Schema-Änderung kann
Tests kippen, die scheinbar nichts damit zu tun haben.

**Die Wochentag-Indizes im Test zu Schritt 7 sind Absicht.** Der 17. August 2026
ist ein Montag, also Index 0. Wenn dieser Test fehlschlägt, prüfe erst deine
Implementierung, bevor du die Erwartung änderst.

**Ein- und Mehrzahl in den Texten.** `streakTitle` und `streakCreditsLabel` sind
ICU-Plurale. „1 Freischeine“ ist falsches Deutsch und fällt dem Auftraggeber
sofort auf.

**In Schritt 11 gibt `_askForJointTrainingProfiles` `null` zurück, wenn der
Nutzer abbricht, und `const []`, wenn niemand mitmachen kann.** Diese beiden
Fälle dürfen nicht zusammenfallen — sonst trägt ein Abbruch in Schritt 12
trotzdem einen Trainingstag ein.

**Die Abfrage in Schritt 12 ersetzt den bestehenden Bestätigungsdialog**, sie
kommt nicht zusätzlich. Zwei Dialoge hintereinander sind ausdrücklich nicht
gewollt.

---

## Definition of Done je Schritt

- der neue Test war vor der Implementierung rot und ist danach grün
- `flutter analyze --no-fatal-infos` → keine Fehler, keine Warnungen
- `flutter test` → vollständig grün (beides über `make release-readiness-mobile`)
- neue Zeichenketten in **beiden** `.arb`-Dateien, `flutter gen-l10n` gelaufen,
  `make i18n-check` grün
- bei berührten Screens: Screenshots unter `docs/evidence/serie-freischeine/`,
  und kein Screen zeigt eine leere Sektion, eine verwaiste Überschrift oder eine
  Sackgasse
- genau ein Commit, dessen Dateiliste du vorher geprüft hast

---

## Abschlussbericht

Wenn alle elf Schritte abgenommen sind, liefere:

- die vollständige Liste der angelegten und geänderten Dateien
- die Commit-Kette mit echten Hashes und Nachrichten
- die tatsächlichen Testzahlen aus dem letzten `make release-readiness-mobile`
- die Ausgabe des oben genannten `grep`-Befehls als Beleg, dass keine alte
  Streak-Rechnung übrig ist
- die ausdrückliche Bestätigung, dass `supabase/` unberührt ist, dass
  `kStreakCreditsServerSyncEnabled` auf `false` steht und dass nichts gepusht
  wurde
- die Liste der offenen Punkte und alles, was dir am Plan widersprüchlich
  vorkam
