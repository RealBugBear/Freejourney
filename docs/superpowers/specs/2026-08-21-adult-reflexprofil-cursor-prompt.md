# Cursor-Prompt — Erwachsenen-Reflexprofil `adult_v3` (Phasen 2–7)

> Dieser Prompt ist eigenständig. Er wird als erste Nachricht in eine frische
> Cursor-Sitzung eingefügt. Alles ab „## Auftrag“ ist der Prompt selbst.

---

## Auftrag

Du implementierst in diesem Repository den **Erwachsenen-Fragebogen
„Reflexprofil“ (`adult_v3`)** und die zugehörige Ergebnisdarstellung: ein nicht
diagnostisches Selbstreflexionsangebot für Personen ab 16 Jahren, 87
Score-Fragen, 4 Kontextfragen, 10 Sicherheitsfragen, 2 vorerst deaktivierte
Bewegungsprüfungen und 7 Filterfragen.

Umfang dieses Auftrags: **Phasen 2 bis 7** des Implementierungsplans. Phase 1
(Architekturentscheidung) ist abgeschlossen. Die Phasen 8 und 9 sind **nicht**
Teil dieses Auftrags.

**Arbeitsverzeichnis:** `/Users/alexandermessinger/dev/claudvibes/reflexjourney`
(Flutter-App, eigenes git-Repo). Prüfe vor jedem Commit mit
`git rev-parse --show-toplevel`, in welchem Repo du bist.

### Verbindliche Quellen, in dieser Reihenfolge

1. `docs/superpowers/plans/2026-08-21-adult-reflexprofil-questionnaire.md`
   — **die maßgebliche Spezifikation dieses Auftrags, Revision 2026-08-21b.**
   Lies sie vollständig, bevor du irgendetwas tust. Bei jedem Widerspruch
   zwischen diesem Prompt und dem Plan gewinnt der Plan. Fällt dir ein
   Widerspruch auf, melde ihn, statt ihn eigenmächtig aufzulösen.
2. `docs/superpowers/specs/Reflexprofil_Erwachsenenfragebogen_adult_v3_Arbeitsfassung.docx`
   — Fragetexte, Item-Mapping, Polung, Filterbedingungen. **Alle Fragetexte und
   alle Reflexzuordnungen kommen wörtlich aus diesem Dokument.** Nichts
   umformulieren, nichts ergänzen, nichts weglassen.
3. `docs/superpowers/specs/Reflexprofil_Gesamtkonzept_adult_v2.docx`
   — Zweckbestimmung, Sprachregeln, Bänder, Ergebnisanforderungen.
4. `docs/superpowers/specs/Reflexprofil_Sicherheitspruefung_Experten.docx`
   — Sicherheitstexte. **Die einzige zulässige Quelle für Warntexte.**
5. `CLAUDE.md` im Wurzelverzeichnis — Hausregeln, Architektur,
   Qualitätsschranken. Bindend, insbesondere §15 (Sprache/Heilversprechen).
6. `tasks/lessons.md` — Fehler, die schon einmal gemacht wurden.

Die `.docx` liest du mit `pandoc -t markdown <datei>`.

### Grundhaltung

Der Auftraggeber ist Einzelunternehmer und nicht technisch. Erkläre in einfacher
Sprache, was du tust. Erfinde keine Belege: „getestet“, „verifiziert“ und
Commit-Hashes schreibst du erst, nachdem der Befehl tatsächlich gelaufen ist und
du seine Ausgabe gesehen hast.

Dieses Produkt berührt Gesundheitsthemen. Wenn dir eine Formulierung fehlt,
**erfindest du sie nicht** — du meldest die Lücke und setzt einen als
`expertPending` markierten Platzhalter.

---

## Harte Verbote

Diese Punkte sind nicht verhandelbar. Wenn du glaubst, einen davon brechen zu
müssen, halte an und frage.

1. **Kein `git push`.** Ein Push kann den Produktions-Deploy auslösen.
2. **Keine mutierenden Befehle auf der Live-Datenbank.** Es gibt nur ein
   Supabase-Projekt und es enthält echte Nutzerdaten. Lesende Abfragen sind
   erlaubt und in Phase 7 sogar verlangt. Migrationen werden geschrieben und
   lokal mit `supabase db reset --local` geprüft — angewendet nur nach
   ausdrücklicher Freigabe.
3. **Der Kinderpfad bleibt unverändert.** Nicht anfassen: die Fragetexte in
   `lib/features/assessment/domain/reflex_questionnaire_definitions.dart`, die
   Schwellen `strongPercent: 100 / elevatedPercent: 80 / indicationPercent: 50`,
   `ReflexProfileScoringService`, das Radar-Diagramm, die Band-Labels
   strong/elevated/indication/inconspicuous. Die bestehenden Tests unter
   `test/features/assessment/` müssen unverändert grün bleiben — nicht anpassen,
   damit sie grün werden.
4. **Kein öffentlicher Gesamtscore.** Kein Durchschnitt über Reflexe, kein
   Radar für Erwachsene, keine Gesamtprozentzahl, keine Ampel, keine
   Punktzahl — auch nicht klein, auch nicht als Nebeninformation. Das
   Gesamtkonzept §8 verbietet ihn ausdrücklich.
5. **Keine Diagnose-, Ursachen- oder Wirkungssprache.** Verboten sind unter
   anderem: „Reflex aktiv“, „nicht integriert“, „Diagnose“, „Ursache“,
   „nachgewiesen“, „das Training wirkt“. Erlaubt ist die Sprache aus dem
   Gesamtkonzept: „passende Angaben“, „Antwortmuster“, „Hinweiswert“.
6. **Keine erfundenen medizinischen Texte.** Warn-, Sicherheits- und
   Rücksprachetexte stammen wörtlich aus Quelle 4. Fehlt dort etwas, fehlt es —
   melden, nicht dichten.
7. **Bewegungsprüfungen bleiben aus.** `kAdultMovementChecksEnabled = false`.
   Der Code entsteht, die Oberfläche ist nicht erreichbar.
8. **Keine Antwortinhalte ins Log.** Keine Antworten, Namen, E-Mails,
   Geburtsdaten, Sicherheitsangaben in `appLogger`, `print` oder Sentry — auch
   nicht als „Beleg“. Zähler und Wahrheitswerte sind erlaubt.
9. **Keine fremden Änderungen mitcommitten.** Der Branch hat unrelated dirty
   files (`android/settings.gradle.kts`, `firebase.json`, `pubspec.yaml`) und
   untracked Dateien aus anderen Vorhaben. Die gehören **nicht** in deine
   Commits.
10. **Kein Analytics-SDK, kein Tracking-Dienst.** Zeitmessung nach §11.4 des
    Plans ist erlaubt und gewollt; Verhaltensanalytik ist Phase 8 und damit
    außerhalb dieses Auftrags.

---

## Sechs Punkte, die erfahrungsgemäß falsch gemacht werden

Diese sechs sind im Plan (Revision 2026-08-21b) bereits entschieden. Sie sind
hier wiederholt, weil sie leicht zu übersehen sind und jeweils zu falschen Zahlen
auf dem Ergebnisschirm führen.

1. **`possibleCount` zählt sichtbare Items, nicht unbeantwortete.** Jedes unter
   den aktuellen Filtern sichtbare Score-Item erhöht `possibleCount` — egal ob
   beantwortet oder nicht. `answeredCount` erhöht sich nur bei „ja“ oder „nein“.
   Es gilt immer `answeredCount <= possibleCount`. Sichere das mit der Invariante
   `answered + unknown + not_applicable + missing == possible_count` ab.
2. **Filterantwort „?“ blendet nicht aus.** Nur ein ausdrückliches „Nein“ auf
   eine Filterfrage versteckt die abhängigen Items. „Weiß ich nicht“ ist
   fehlendes Wissen, nicht „trifft nicht zu“ — die Person kann die Einzelfragen
   sehr wohl beantworten.
3. **`meta.movement_included` wird immer geschrieben.** Das Movement-Flag
   verändert den Nenner, ohne dass sich `questionnaire_version` oder
   `scoring_version` ändern. Ohne dieses Feld vergleicht der Verlauf später
   zwei unterschiedlich berechnete Profile.
4. **Der Ergebnis-Branch prüft die Version, nicht den Typ.** In der Datenbank
   kann es `adult_self_report`-Zeilen aus einer früheren Iteration geben. Nur
   `questionnaire_version == 'adult_v3'` bekommt die neue Darstellung.
5. **`f_handwriting` steuert genau neun IDs:** `s061`, `s066`, `s068`, `s069`,
   `s070`, `s072`, `s073`, `s074`, `a074`. **`s067` und `s071` existieren
   nicht** — sie wurden in adult_v3 Teil C gestrichen. Schreibe nie einen
   Bereich `s066`–`s074`.
6. **Die Sicherheitstexte existieren bereits** als Entwurf in Quelle 4,
   Abschnitt 6. Verwende sie wörtlich statt eines leeren Platzhalters — mit der
   im Plan §8.2 beschriebenen Kürzung, solange das Movement-Flag aus ist.

---

## Arbeitsweise

Du arbeitest die Phasen 2 bis 7 **in dieser Reihenfolge** ab. Für jede Phase gilt
derselbe Vierschritt:

1. **Muster verifizieren, bevor du etwas änderst.** Öffne die vergleichbare
   Stelle im Kinderpfad und übernimm deren Form: Benennung, Ordnerschnitt,
   Fehlerbehandlung, Teststil. Wenn die Wirklichkeit im Repo von der
   Spezifikation abweicht, ist die Wirklichkeit die Tatsache — melde die
   Abweichung, statt sie zu überschreiben.
2. **Umsetzen**, im kleinstmöglichen Umfang, der die Phase erfüllt. Kein
   Aufräumen nebenbei, keine Umbauten an fremden Stellen.
3. **Testen.** Die Tests der Phase schreiben und laufen lassen, dazu
   `make release-readiness-mobile` (`flutter analyze --no-fatal-infos` plus
   `flutter test`). Rot heißt: die Phase ist nicht fertig.
4. **Berichten und anhalten.** Melde: was geändert wurde (Dateiliste), welche
   Tests mit welchem Ergebnis liefen, was dir aufgefallen ist, und welche
   Annahme du triffst. Dann warte auf Freigabe, bevor du die nächste Phase
   beginnst.

Commits: eine Sache pro Commit, Nachricht im Repo-Stil mit Referenz `P2.A`
(`feat(assessment): … (P2.A)`, `test(assessment): … (P2.A)`). Die empfohlene
Reihenfolge steht in §19 des Plans. Vor jedem Commit
`git diff --cached --name-status` prüfen — es darf ausschließlich enthalten, was
zu deinem Commit gehört.

---

## Phase 2 — Datenmodell und Katalog

Vorbild, vorher lesen: `lib/features/assessment/domain/reflex_questionnaire.dart`
und `reflex_questionnaire_definitions.dart` (Aufbau der Helfer `_q`, `_context`,
`_warning`; Struktur von `ReflexQuestionnaireDefinition`).

Liefere:

- Erweiterungen an `reflex_questionnaire.dart` nach §5.2 des Plans:
  `ReflexItemPolarity`, `ReflexAnswerChoice` mit `notApplicable`,
  `AdultQuestionModule` (**14 Werte**, inklusive `lifeContext` für das
  Filtermodul), `AdultHintBand`, `AmphibianDisplay`, `ApplicabilityFilter`,
  `ReflexQuestionRole.movement`, `PrimitiveReflex.amphibian`.
  Alle Erweiterungen **rückwärtskompatibel** — der Kinderkatalog kompiliert und
  verhält sich unverändert.
- `lib/features/assessment/domain/adult_reflex_questionnaire_definitions.dart`
  mit `adultSelfQuestionnaireV3`: 7 Filter + 87 Score + 4 Kontext + 10 Safety +
  2 Movement = **110 Items**.
- `lib/features/assessment/domain/adult_reflex_result_copy.dart` — pro
  erwachsenenrelevantem Reflex Kurzbeschreibung, Alternativerklärungen, Grenzen,
  Hinweis auf persönliche Überprüfung. Wo dir der Fachtext fehlt: neutraler
  Platzhalter plus `expertPending`. **Nicht erfinden.**

Fragetexte Deutsch wörtlich aus Quelle 2. Englisch professionell übersetzen —
sachlich, gleiche Bedeutung, keine Verharmlosung und keine Verschärfung.

Tests: Itemzahlen je Rolle, Mapping jeder ID gegen Quelle 2, DE/EN-Parität,
Guard aus Punkt 5 oben (`s067`/`s071` existieren nicht), Kinderkatalog-Tests
unverändert grün.

**Noch keine Oberfläche.** Nach dieser Phase ist der Adult-Pfad weiterhin
„coming soon“.

---

## Phase 3 — Antworten, Filter, Entwürfe

Vorbild: `lib/features/assessment/domain/draft_persistence_service.dart` und die
Sichtbarkeitslogik in `reflex_profile_screen.dart` (heute nur die eine Regel
`q032` wenn `q031 == no`).

Liefere:

- `lib/features/assessment/domain/adult_questionnaire_visibility.dart` — reine,
  testbare Logik ohne Flutter-Abhängigkeit, nach §6.1 des Plans.
- Serialisierung von `not_applicable` im Antwort-JSON. **Das Kinder-JSON bleibt
  Zeichen für Zeichen unverändert** (`yes` / `no` / `unknown`).
- Entwurfsdaten um `questionnaire_version`, `filter_answers` und die Zeitstempel
  aus §11.4 erweitern.

Tests: Filter „nein“ versteckt, Filter „?“ versteckt **nicht**, versteckte
Antworten bleiben im Entwurf erhalten und kommen bei erneutem „ja“ zurück,
Rundlauf über alle vier Antwortwerte, Wiederaufnahme stellt den Modulindex her.

---

## Phase 4 — Scoring-Engine

Liefere `lib/features/assessment/domain/adult_reflex_profile_scoring.dart` nach
§7 des Plans. Die Engine wirft, wenn ihr eine Kinderdefinition übergeben wird.

Achte auf: Polung (alle Score-Items `d`, Movement `i`), `unknown` und
`not_applicable` fallen aus Zähler **und** Nenner, Kontextfragen scoren nie,
Sicherheitsfragen scoren nur wenn das Mapping Reflexe nennt — in `adult_v3` ist
das ausschließlich `s046` mit ATNR und STNR. Amphibien laufen über einen eigenen
Pfad (`s017` und `s102`) mit der Anzeige 0/1/2 und dem Pflichtzusatztext; für
Galant und STNR wird `s017` ganz normal mitgezählt.

Bänder: 0–29 / 30–59 / 60–79 / 80–100. Grenztests bei 29/30, 59/60, 79/80.

Tests: die vollständige Liste aus §14.1 des Plans, **einschließlich 14a bis
14d**.

---

## Phase 5 — Fragebogen-Oberfläche

Vorbild: `reflex_profile_screen.dart`. Heute steht dort
`ReflexQuestionnaireDefinition get _definition => childParentQuestionnaireV1;`
(Zeile 48) — hart verdrahtet. Diese Stelle wird zur Verzweigung.

Liefere:

- Auswahl der Definition nach `_questionnaireFor`; `_buildAdultComingSoon()`
  entfällt, wenn `kAdultReflexQuestionnaireEnabled` an ist.
- Vier Antwortflächen (Ja / Nein / ? / n. z.) als 2×2-Raster mit ausreichender
  Trefferfläche und Semantics-Labels. „?“ und „n. z.“ visuell sekundär, aber
  gleich gut erreichbar.
- Filtermodul „Deine Lebenssituation“ direkt nach dem Einstiegstext.
- Altersprüfung: Profil ab 16 Jahren, berechnet aus dem Geburtsdatum.
  Unter 16 → Hinweis auf das Kinderprofil. Das ist richtig so: der Kinderbogen
  ist ein **Elternbericht über ein Kind**, keine Selbstauskunft.
- Zusammenfassung vor dem Absenden nach §6.3 — Zahl beantworteter,
  übersprungener und ausgeblendeter Angaben, Sprung zurück zu offenen Fragen.
- Zeitstempel nach §11.4 (Dauer, Modulzeiten). Keine Antwortinhalte.

Alle Bedienungstexte in `lib/l10n/app_de.arb` **und** `app_en.arb`, danach
`flutter gen-l10n`, generierte Dateien mitcommitten. Fragetexte bleiben im
Katalog (Muster des Kinderpfads).

Tests: Kinderpfad nutzt weiterhin die Kinderdefinition, Wiederaufnahme, Zurück
ohne Antwortverlust, Semantics auf den Antwortknöpfen.

---

## Phase 6 — Sicherheitsmodul, Bewegungsteil aus

Liefere die drei Flags in `lib/config/launch_flags.dart` nach dem Muster von
`kPaywallEnabled` — mit Doc-Kommentar, der jede gegatete Fläche und die
Voraussetzungen zur Reaktivierung aufzählt:
`kAdultReflexQuestionnaireEnabled`, `kAdultMovementChecksEnabled = false`,
`kAdultSafetyHardGateEnabled = false`.

Sicherheitsmodul nach den Inhaltskapiteln, vor dem Bewegungsteil. Bei einer
sicherheitsrelevanten Antwort der Text aus Quelle 4 Abschnitt 6, gekürzt wie in
§8.2 beschrieben. Die Bestätigung dokumentiert **ausschließlich, dass der
Hinweis angezeigt wurde** — keine Formulierung, die Verantwortung überträgt.

`warning_confirmations` mit `message_version: 'adult_safety_expertdraft_v0'`.

**Nicht bauen:** automatische Trainingssperre, Stufen A/B/C, Notfallnummern,
Diagnosehinweise.

Test: mit den Standardflags ist der Bewegungsteil nicht erreichbar.

---

## Phase 7 — Ergebnisdarstellung

**Vor der ersten Zeile Code** die lesende Abfrage aus §10.4 des Plans ausführen
und das Ergebnis melden: gibt es `adult_self_report`-Zeilen aus einer früheren
Iteration, und mit welcher Version? Danach weiterbauen — der Legacy-Zweig
entsteht in jedem Fall.

Liefere `adult_reflex_hint_bar.dart`, `adult_reflex_detail_tile.dart`,
`adult_score_band_l10n.dart` und die Verzweigung im Ergebnisschirm nach §10.

Darstellung: Titel „Dein Reflexprofil“, Datum, Versionsangabe, Hinweis auf
subjektive Antwortmuster. Waagerechte Balken, nach Prozent absteigend, Amphibien
getrennt darunter. Pro Zeile: Name, Prozentwert, **Bandtext** und Datengrundlage
(„7 von 9 Merkmalen beantwortet“). Eine ruhige Grundfarbe plus Graustufen —
**kein Rot-gleich-schlecht, kein Grün-gleich-gut**, und Farbe nie die einzige
Information.

Aufklappbare Detailkarte nach §10.2. Kinderergebnis bleibt unverändert.

Tests: Titel vorhanden, **kein Widget zeigt einen Gesamtwert**, Bandtext auch
ohne Farbe lesbar, dunkles Design, 200 % Textskalierung ohne Überlauf,
Legacy-Zeile rendert den Hinweis statt der Balken, verbotene Zeichenketten
kommen in der Erwachsenen-Copy nicht vor.

Screenshots unter `docs/evidence/adult-reflexprofil/`.

---

## Definition of Done je Phase

- `flutter analyze --no-fatal-infos` → keine Fehler, keine Warnungen
- `flutter test` → vollständig grün (beides über `make release-readiness-mobile`)
- neue Verhaltensweise hat mindestens einen Test
- bestehende Tests unter `test/features/assessment/` unverändert grün, ohne dass
  du sie angepasst hast
- neue Bedienungstexte in beiden `.arb`-Dateien, `flutter gen-l10n` gelaufen
- bei berührten Screens: Screenshots unter `docs/evidence/adult-reflexprofil/`,
  und kein Screen zeigt eine leere Sektion, eine verwaiste Überschrift oder eine
  Sackgasse
- `git diff --cached --name-status` enthält keine fremden Dateien

## Abschlussbericht

Wenn alle Phasen abgenommen sind, liefere: die vollständige Dateiliste, die
Testergebnisse mit tatsächlichen Zahlen, die Liste der Stellen, an denen du einen
`expertPending`-Platzhalter gesetzt hast, das Ergebnis der Datenbankabfrage aus
Phase 7 — und die ausdrückliche Bestätigung, dass Kinderkatalog, Kinderschwellen
und Kinder-Scoring unverändert sind, dass nirgends ein Gesamtscore angezeigt
wird, und dass `kAdultMovementChecksEnabled` und `kAdultSafetyHardGateEnabled`
auf `false` stehen.

**Vor öffentlicher Freigabe** sind die Punkte in §17 des Plans offen (Fachprüfung
der Mehrfachzuordnungen, Amphibien, Sicherheitsfreigabe, Verständlichkeitstest,
Grundratencheck, Datenschutz ab 16, Medizinprodukte-Einordnung). Diese Phasen
liefern eine **intern testbare**, nicht eine veröffentlichungsreife Fassung.
Behaupte nichts anderes.
