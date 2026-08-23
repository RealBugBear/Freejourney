# Cursor-Prompt — Trainingszeitpunkt im Alltag

> Dieser Prompt ist eigenständig. Er wird als erste Nachricht in eine frische
> Cursor-Sitzung eingefügt. Alles ab „## Auftrag“ ist der Prompt selbst.

---

## Auftrag

Du baust in diesem Repository eine einzelne Frage ein: **„Wann sollen wir dich
erinnern?“** Sie erscheint einmalig nach dem ersten abgeschlossenen Training,
und die Antwort schaltet die Erinnerungen ein.

**Arbeitsverzeichnis:** `/Users/alexandermessinger/dev/claudvibes/reflexjourney`
(Flutter-App, eigenes git-Repo). Alles in diesem Auftrag passiert in **diesem**
Repo. Prüfe vor jedem Commit mit `git rev-parse --show-toplevel`, wo du bist.

### Verbindliche Quellen, in dieser Reihenfolge

1. `docs/superpowers/plans/2026-08-23-trainingszeitpunkt.md`
   — **der Umsetzungsplan.** Sechs Schritte, jeder mit Test, Code und Commit.
   Er ist deine Arbeitsanweisung. Arbeite ihn der Reihe nach ab.
2. `docs/superpowers/specs/2026-08-23-trainingszeitpunkt-design.md`
   — **die maßgebliche Spezifikation** mit den vier Founder-Entscheidungen
   A1–A4. Bei jedem Widerspruch zwischen Plan und Spec gewinnt die **Spec**.
   Fällt dir einer auf, melde ihn, statt ihn eigenmächtig aufzulösen.
3. `CLAUDE.md` und `AGENTS.md` im Wurzelverzeichnis — Hausregeln, Architektur,
   Qualitätsschranken, bekannte Fehlerquellen. Bindend.
4. `tasks/lessons.md` — Fehler, die schon einmal gemacht wurden.

Lies 1 und 2 vollständig, bevor du die erste Datei anfasst.

### Grundhaltung

Der Auftraggeber ist Einzelunternehmer und nicht technisch. Erkläre in einfacher
Sprache, was du tust. Erfinde keine Belege: „getestet“, „verifiziert“,
Commit-Hashes und Testzahlen schreibst du erst, nachdem der Befehl tatsächlich
gelaufen ist und du seine Ausgabe gesehen hast.

---

## Harte Verbote

Diese Punkte sind nicht verhandelbar. Wenn du glaubst, einen davon brechen zu
müssen, halte an und frage.

1. **Kein Wort über Medikamente, Alkohol oder Drogen.** Nirgends in dieser
   Funktion — nicht im Auswahltext, nicht im Hinweis, nicht als Nebensatz, nicht
   auskommentiert. Der Grund steht in der Spec §6: Es gibt dazu eine stehende
   Entscheidung aus einer Expertenprüfung, die ausdrücklich lautet, diese Lücke
   **nicht durch eigene Formulierungen zu schließen**. Der Abend-Hinweis spricht
   ausschließlich vom Einschlafen.
2. **Keine Heil-, Wirk-, Therapie- oder Diagnoseaussagen.** Beschrieben werden
   Tätigkeiten und Beobachtungen, nie Wirkung. „Vielen fällt das Einschlafen
   schwerer“ ist eine Beobachtung und in Ordnung. „Die Übungen aktivieren das
   Nervensystem“ wäre eine Wirkaussage und ist es nicht.
3. **Keine Datenbankarbeit.** Dieser Auftrag fasst `supabase/` nicht an, legt
   keine Migration an, führt kein SQL aus und ändert kein Drift-Schema. Alles
   liegt in `SharedPreferences`. Wenn ein Schritt danach aussieht, als bräuchte
   er eine Datenbank, halte an und frage.
4. **Kein `git push`.** Ein Push kann den Produktions-Deploy auslösen. Lokale
   Commits sind erwünscht — einer pro Schritt, wie im Plan.
5. **Keine Nutzerdaten in die Ausgabe.** Keine Namen, E-Mails, Journal- oder
   Nachrichteninhalte, keine Tokens. Zähler und Wahrheitswerte sind erlaubt.
6. **Keine generierten Dateien von Hand bearbeiten.** `app_localizations*.dart`
   entsteht über `flutter gen-l10n` und wird committet, aber nie editiert.
7. **Die Empfehlung gilt nur für Erwachsene.** Beim Kinderprofil wird **keine**
   Option als empfohlen markiert und die Reihenfolge nicht umgestellt
   (Entscheidung A2). Das ist bewusst so: Der Schulmorgen ist für Familien der
   Zeitpunkt, den sie am wenigsten verlässlich liefern können.

---

## Arbeitsweise

- **Ein Schritt nach dem anderen.** Fange keinen an, bevor der vorherige grün
  ist und committet.
- **Test zuerst.** Jeder Schritt beginnt mit einem Test, der fehlschlagen
  **muss**. Lass ihn laufen und sieh den Fehlschlag, bevor du implementierst.
  Ein Test, der sofort grün ist, testet nichts.
- **Der Code im Plan ist der Code.** Wo der Plan einen Codeblock zeigt, übernimm
  ihn. Wenn er nicht kompiliert oder nicht in den umliegenden Code passt, ist
  das ein Planfehler — melde ihn, statt ihn stillschweigend umzuschreiben.
- **Ein Commit pro Schritt**, mit der im Plan angegebenen Nachricht. Prüfe
  unmittelbar davor `git diff --cached --name-status`: genau die geplanten
  Dateien, nichts Fremdes.
- **Melde dich zwischen den Schritten** mit zwei bis drei Sätzen.
- Ist der Arbeitsbaum beim Start nicht sauber, halte an und zeige, was
  offensteht.

---

## Die Schritte

Alle sechs gehören zum Auftrag. Nichts wird ausgelassen.

| Schritt | Ergebnis |
|---|---|
| 1 | Anker-Modell: welche Optionen je Zielgruppe, welche Uhrzeit je Anker |
| 2 | Speicherung in den Einstellungen des Geräts |
| 3 | Texte in beiden Sprachen und das Auswahlblatt |
| 4 | Die Antwort anwenden: Uhrzeit setzen, Erinnerungen einschalten |
| 5 | Nach dem ersten Training fragen |
| 6 | Später in den Einstellungen ändern |

---

## Fallen in diesem Auftrag

**Die Vorrunde zählt nicht.** Der Sitzungszähler wird nur nach echten
Trainingseinheiten erhöht, nicht nach einer Vorrunde-Einheit. Baue dafür
**keine** zusätzliche Prüfung ein — sie ergibt sich von selbst. Wenn du eine
einbaust, wird sie beim nächsten Umbau falsch.

**„Genau eine Sitzung“, nicht „mindestens eine“.** Die Frage gehört in den
Moment direkt nach dem ersten Training. Wer schon fünf Einheiten hinter sich hat,
wird nicht nachträglich gefragt.

**Abhaken vor dem Öffnen.** Der Merker „schon gefragt“ wird gesetzt, **bevor**
das Blatt aufgeht — genauso wie beim bestehenden Routine-Tipp. Sonst kommt die
Frage nach einem Absturz oder einer Zurück-Geste wieder.

**Höchstens ein Blatt pro Rückkehr.** Es gibt bereits einen Ein-Mal-Hinweis
(„Du kennst die Übungen jetzt“, ab der zweiten Sitzung). In der Praxis
kollidieren die beiden nicht, weil unsere Frage bei Sitzung 1 kommt. Die Sperre
kommt trotzdem rein, damit ein späterer Umbau sie nicht stapeln kann.

**Anker und Uhrzeit sind zwei Dinge.** Der Anker ist ein Ereignis, die
Erinnerung braucht eine Uhrzeit. Wählt jemand einen **anderen** Anker, wird die
vorgeschlagene Uhrzeit ersetzt. Tippt jemand denselben Anker noch einmal an,
bleibt eine bereits angepasste Uhrzeit stehen.

**Der Abend-Hinweis erscheint nur bei den späten Ankern** — „Am Abend“ und
„Nach dem Abendessen“. Nicht bei „Zu einer festen Uhrzeit“, auch wenn dort
19:00 eingestellt wird.

**Keine neue Benachrichtigungs-Logik.** `remindersEnabled` und die Startzeit zu
setzen genügt — die bestehende Synchronisierung plant daraufhin sowohl die
Trainingserinnerung als auch die Abendnachricht der Serie ein. `lib/app.dart`
und `lib/core/notifications/` werden **nicht** angefasst.

---

## Definition of Done je Schritt

- der neue Test war vor der Implementierung rot und ist danach grün
- `flutter analyze --no-fatal-infos` → keine Fehler, keine Warnungen
- `flutter test` → vollständig grün (beides über `make release-readiness-mobile`)
- neue Zeichenketten in **beiden** `.arb`-Dateien, `flutter gen-l10n` gelaufen,
  `make i18n-check` grün
- bei berührten Screens: Screenshots unter `docs/evidence/trainingszeitpunkt/`,
  und kein Screen zeigt eine leere Sektion oder eine Sackgasse
- genau ein Commit, dessen Dateiliste du vorher geprüft hast

---

## Abschlussbericht

Wenn alle sechs Schritte abgenommen sind, liefere:

- die vollständige Liste der angelegten und geänderten Dateien
- die Commit-Kette mit echten Hashes und Nachrichten
- die tatsächlichen Testzahlen aus dem letzten `make release-readiness-mobile`
- die Ausgabe von
  `grep -rniE "medikament|alkohol|droge" lib/l10n/` als Beleg, dass Verbot 1
  eingehalten ist (erwartet: keine Treffer)
- die Bestätigung, dass `supabase/` unberührt ist, dass `lib/app.dart` und
  `lib/core/notifications/` unberührt sind, und dass nichts gepusht wurde
- die Liste der offenen Punkte und alles, was dir am Plan widersprüchlich vorkam
