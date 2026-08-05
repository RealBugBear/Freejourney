# Eine App, zwei Zielgruppen — Entscheidung gegen die Produkttrennung

**Datum:** 2026-08-05
**Status:** Vom Founder im Brainstorming freigegeben
**Scope:** Produktzuschnitt, Zielgruppenansprache, Preisarchitektur, v1-Umfang
**Nicht im Scope:** Konkrete Preishöhen (bleiben Hypothesen bis Research, siehe
`docs/PAYMENTS_MASTER_PLAN.md`), Trainer-Studio-Design, i18n-Planung

## Ausgangsfrage

Der Founder erwog, die App in zwei getrennte Produkte zu spalten: eines für
Kinder und Jugendliche (Eltern als Käufer), eines für Erwachsene. Motive:
schärfere Ansprache je Zielgruppe, unterschiedliche Preisstrukturen, dazu die
Vermutung, der Kindermarkt sei verbreitet und preissensibel, der
Erwachsenenmarkt kaum existent, aber premiumfähig. Offene Unterfragen: Reihenfolge
(erst Kinder, dann Erwachsene?), gleicher Name für zwei Apps, getrennte Domains
mit herkunftsbasiertem Umrouten.

## Befundlage

Vier Fakten aus dem Repo, die die Frage beantworten:

1. **Die Trennung existiert architektonisch bereits.** `reflex_subject_profiles`
   unterscheidet `adult_self` und `child`; ein Konto verwaltet mehrere
   Trainingsprofile. Vollständig umgesetzt seit 2026-05-11
   (`docs/product/multi-subject-implementation-status.md`).
2. **Das Bewegungsprogramm ist nicht altersdifferenziert.** `age_group` erscheint
   im Flutter-Code nur in Assessment-, Admin- und Trainer-Kontexten, nicht in den
   Trainingspaketen. Real unterschiedlich sind: Fragebogen (Kind = Elternbericht,
   Erwachsen = Selbstbericht), Tonalität, und wer das Gerät bedient.
3. **Ein `premium`-Entitlement deckt alle Profile eines Kontos** (PM-D2,
   `docs/PAYMENTS_MASTER_PLAN.md`). Das ist als Verkaufsargument gedacht, nicht
   als Upsell-Schranke.
4. **Die Zahlungsbereitschaft beider Segmente wurde bereits gemeinsam bewertet.**
   `docs/MONETARISIERUNG_EVALUATION.md` nennt „Eltern mit konkretem Leidensdruck
   + erwachsene Selbstanwender" in einem Atemzug als hohe Zahlungsbereitschaft in
   einem Vertrauensmarkt.

## Geprüfte Prämissen

**„Bei Kindern kann man preislich nicht hoch gehen."** Nicht belegt. Der
vermutete Deckel stammt aus der Kids-App-Kategorie (Spiele, Edutainment). Dieses
Produkt ist keine Kinder-App, sondern eine Eltern-App im Gesundheitskontext —
dieselben Eltern zahlen Therapiestundensätze. Die Preisintuition ist eher
invertiert: elterlicher Leidensdruck gehört zu den stärksten Treibern von
Zahlungsbereitschaft im Consumer-Health.

**„Für Erwachsene existiert der Markt kaum."** Zweideutig: „unerschlossen" und
„keine Nachfrage" sehen vor dem Launch identisch aus. Ein zweites Binary zu
bauen, um das zu unterscheiden, wäre die teuerste denkbare Messmethode. Die
Warteliste liefert dasselbe Signal kostenlos — das Formular sendet bereits ein
`segment`-Feld (`reflexjourney-app-site/src/components/WaitlistForm.astro`).

**„Zwei Preise brauchen zwei Apps."** Falsch. RevenueCat-Offerings mit Targeting
können die Preistafel an den Profiltyp koppeln. Die reale Einschränkung ist eine
andere: Preise sind sichtbar (Google Play zeigt eine Preisspanne, Apple listet
die wichtigsten In-App-Käufe). Zwei Preise für dieselbe Leistung wirken
willkürlich, sobald jemand beide sieht. Das ist ein Legitimations-, kein
Technikproblem — und zwei Apps hätten es versteckt, nicht gelöst.

**„Zwei Zielgruppen, zwei Reihenfolgen."** Zwei unabhängige Entscheidungen waren
zu einer verschmolzen: „welches Segment zuerst?" und „ein Binary oder zwei?"
haben nichts miteinander zu tun.

**Der Doppelnutzer.** Der wahrscheinlichste Premium-Käufer ist der Elternteil,
der über das Kind zur Reflexintegration kommt und sich selbst darin wiedererkennt.
Heute: ein Konto, zwei Profile, ein Abo. Bei zwei Apps: zweimal zahlen. Die
Trennung hätte genau den wertvollsten Nutzungspfad zerschnitten.

**Herkunftsbasiertes Umrouten zwischen zwei Domains.** Verworfen. Es zerlegt die
SEO-Signale auf zwei Domains, rät bei jedem Besucher und rät regelmäßig falsch
(Vater sucht für den Sohn; Erwachsene kommt über den Eltern-Artikel), und
erzeugt Erklärungsbedarf beim Nutzer. Aufwand hoch, Nutzen negativ.

## Entscheidung

### 1. Ein Produkt

Eine App, ein Binary, eine Marke, eine Domain. Die Zielgruppentrennung passiert
in Ansprache und Angebotsform, nicht im Code und nicht im Store.

Ein Split hätte Store-Listing, App-Review, Rechtstexte, Privacy-Labels, ASO,
Support, Build-Pipeline und Website verdoppelt — bei einem Solo-Founder vor dem
ersten Umsatz.

### 2. Segmentierung nach außen

- Website behält die Segmentseiten unter `/fuer/<slug>` auf einer Domain.
- Kein herkunftsbasiertes Routing, keine zweite Domain, kein zweiter Markenname.
- Für zielgruppenscharfe Store-Ansprache später: Apple Custom Product Pages bzw.
  Google Custom Store Listings — pro Kampagne eigene Screenshots und Texte auf
  demselben Eintrag. Marketing-Thema nach dem Launch, kein Launch-Blocker.
- Die Warteliste sammelt weiterhin das Segment. Sie ist die Datenquelle für jede
  spätere Revision dieser Entscheidung.

### 3. Preisarchitektur

- Es bleibt bei einem `premium`-Entitlement für alle Profile eines Kontos.
- Falls später zwei Preistafeln gewünscht sind: über RevenueCat-Offerings, aber
  differenziert nach **Umfang**, nie nach **Zielgruppe**. Zielgruppenpreise sind
  sichtbar und nicht erzählbar.
- Der hochpreisige Umsatz — Begleitung online und in Präsenz, Vorträge, später
  ggf. Leistungssport — läuft außerhalb von IAP über Website und Trainerkanal.
  Das ist konsistent mit D5 (Trainer rechnen direkt mit Klienten ab) und mit den
  Store-Regeln: rein digitale In-App-Inhalte erfordern IAP, Leistungen mit
  Live-/Präsenzanteil nicht.
- Am `PAYMENTS_MASTER_PLAN` ändert diese Entscheidung nichts.

### 4. v1-Umfang

**Founder-Entscheidung: Kinder- und Erwachsenen-Fragebogen beide in v1.**

Empfohlen war ein kinderfokussierter v1 mit Nachreichen des Erwachsenen-Tracks,
weil der Kinder-Fragebogen freigegeben und vollständig gemappt ist, während der
Erwachsenen-Fragebogen noch offene Schritte hat. Der Founder hat sich dagegen
entschieden. Damit kommen auf den kritischen Pfad:

| Schritt | Art | Parallelisierbar |
|---|---|---|
| Sicherheitsfragen Erwachsene ins Anwalts-Briefing | sequenziell, **vor Versand** | nein |
| Freigabe pro Frage in der `Freigabe`-Spalte | Founder-Arbeit | ja |
| Grounding-Rate-Realitätscheck | Feldtest | ja |
| Verständlichkeitstest | Feldtest | ja |

Quelle der offenen Schritte: `docs/specs/reference/CONTENT-STATUS.md` im Repo
`ReflexJourney`.

### 5. Bewusst nicht

Kein zweites Binary. Kein zweiter Store-Eintrag. Keine zweite Domain. Kein
Origin-Routing. Keine zielgruppenbasierte Preisdiskriminierung. Keine
Leistungssport-Positionierung vor dem Launch — sie hat eine eigene Rechtslage
(Leistungsaussagen statt Heilaussagen) und einen eigenen Vertriebsweg
(Vereine, Physios, Athletiktrainer), beides ungeprüft.

## Zeitkritischer Befund

Das Anwalts-Briefing (`docs/legal/ANWALTS_BRIEFING.md`, Stand 2026-07-19) kennt
den Erwachsenen-Fragebogen nicht — dieser entstand am 2026-08-01. Die
Sicherheitsfragen und besonders die fünf *vorgeschlagenen* kommen im Briefing
nicht vor. Das Versandpaket in `docs/legal/versand/` ist seit 2026-07-19
unverändert, also offenbar noch nicht versendet.

**Solange das Paket nicht raus ist, kostet ein zusätzlicher Baustein
„Sicherheitsfragen Erwachsenen-Screening" nur die Schreibarbeit. Nach dem
Versand kostet er eine zweite Mandantenrunde — bei dem Blocker mit der längsten
Durchlaufzeit.** Dieser Schritt gilt unabhängig vom v1-Zuschnitt.

## Offene Punkte

- Ob der Erwachsenen-Fragebogen zum EN-Launch übersetzt sein muss (~127 Items,
  Spalte `Frage_EN` ist bewusst leer). Hängt am i18n-Endspurt
  (`docs/I18N_EN_TRACKER.md`), nicht an dieser Entscheidung.
- Konkrete Preishöhen und Stufenzuschnitt bleiben Hypothesen bis zum jeweiligen
  Validierungsgate im `PAYMENTS_MASTER_PLAN`.

## Wann diese Entscheidung neu zu prüfen ist

Diese Entscheidung ist bewusst reversibel. Sie sollte neu geprüft werden, wenn
**einer** dieser Punkte eintritt:

- Die Wartelisten-Segmente zeigen zwei Gruppen mit sehr geringer Überschneidung
  (wenige Konten mit Kind- *und* `adult_self`-Profil).
- Der Erwachsenen-Track entwickelt eigene Übungen oder eine eigene
  Programmstruktur — dann wäre die Trennung inhaltlich begründet statt nur
  vermarktungsseitig.
- Ein Kanal verlangt einen eigenen Eintrag (z. B. B2B-/Vereinsvertrieb mit
  Lizenzmodell statt Einzelabo).
- Die Store-Ansprache über Custom Product Pages erweist sich als unzureichend,
  um beide Segmente sauber zu adressieren.

Kein einzelner Punkt erzwingt den Split — sie sind Anlass zur Neubewertung, nicht
deren Ergebnis.
