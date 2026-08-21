# Cursor-Prompt — Einladungen und Wirkungs-Visual (MVP)

> Dieser Prompt ist eigenständig. Er wird als erste Nachricht in eine frische
> Cursor-Sitzung eingefügt. Alles ab „## Auftrag“ ist der Prompt selbst.

---

## Auftrag

Du implementierst in diesem Repository das Feature „Einladungen und
Wirkungs-Visual (MVP)“ — eine Nutzer-zu-Nutzer-Einladung mit anonymem,
aggregiertem Wirkungs-Visual.

**Arbeitsverzeichnis:** `/Users/alexandermessinger/dev/claudvibes/reflexjourney`
(Flutter-App, eigenes git-Repo). Die Website liegt in einem **anderen** Repo:
`/Users/alexandermessinger/dev/claudvibes/corejourney/reflexjourney-app-site`.
Prüfe vor jedem Commit mit `git rev-parse --show-toplevel`, in welchem Repo du
bist, und vermische die beiden niemals.

### Verbindliche Quellen, in dieser Reihenfolge

1. `docs/superpowers/specs/2026-08-21-einladungen-und-wirkungsvisual-design.md`
   — **die maßgebliche Spezifikation dieses Auftrags.** Lies sie vollständig,
   bevor du irgendetwas tust. Bei jedem Widerspruch zwischen diesem Prompt und
   dem Dokument gewinnt das Dokument. Fällt dir ein Widerspruch auf, melde ihn,
   statt ihn eigenmächtig aufzulösen.
2. `CLAUDE.md` im Wurzelverzeichnis — Hausregeln, Architektur, Qualitätsschranken,
   bekannte Fehlerquellen. Bindend.
3. `tasks/lessons.md` — Fehler, die schon einmal gemacht wurden.

### Grundhaltung

Der Auftraggeber ist Einzelunternehmer und nicht technisch. Erkläre in einfacher
Sprache, was du tust. Erfinde keine Belege: „getestet“, „verifiziert“ und
Commit-Hashes schreibst du erst, nachdem der Befehl tatsächlich gelaufen ist und
du seine Ausgabe gesehen hast.

---

## Harte Verbote

Diese Punkte sind nicht verhandelbar. Wenn du glaubst, einen davon brechen zu
müssen, halte an und frage.

1. **Keine Stufe 2.** Es entsteht kein Eintrag in `entitlement_grants`, keine
   Zeile in `benefit_campaigns` oder `benefit_codes`, keine Funktion, die ein
   Belohnungsprogramm abfragt, keine vorbereitende Spalte und kein Feld dafür.
   Auch nicht „schon mal vorbereitet“ und auch nicht auskommentiert. Weder App
   noch Website dürfen irgendeine Vergünstigung erwähnen.
2. **Kein `git push`.** Ein Push kann den Produktions-Deploy auslösen.
3. **Keine mutierenden Befehle auf der Live-Datenbank.** Es gibt nur ein
   Supabase-Projekt und es enthält echte Nutzerdaten. Migrationen werden
   geschrieben und lokal mit `supabase db reset --local` geprüft — angewendet
   werden sie nur nach ausdrücklicher Freigabe des Auftraggebers.
4. **Keine Nutzerdaten in die Ausgabe.** Keine Namen, E-Mails, Journal- oder
   Nachrichteninhalte, keine Tokens, keine Geheimniswerte — auch nicht als
   „Beleg“. Zähler, Wahrheitswerte und Tabellennamen sind erlaubt.
5. **Kein Push und kein Badge** für das Feature. Der Stand wird ausschließlich
   sichtbar, wenn der Nutzer die Einladungsseite öffnet.
6. **Keine Heilversprechen** in Texten. Beschrieben werden Tätigkeiten, nie
   Wirkung, Therapie, Diagnose oder gesundheitlicher Nutzen.
7. **Nie automatisch einlösen.** Jede Einlösung braucht die ausdrückliche
   Bestätigung des Eingeladenen.
8. **Kein Analytics-SDK, kein Tracking-Dienst, kein Kontaktbuchzugriff.**

---

## Arbeitsweise

Du arbeitest die Phasen 0 bis 8 **in dieser Reihenfolge** ab. Für jede Phase gilt
derselbe Vierschritt:

1. **Muster verifizieren, bevor du etwas änderst.** Öffne die vergleichbaren
   Stellen im Repo und übernimm deren Form: Benennung, Ordnerschnitt,
   Fehlerbehandlung, Teststil. Konkrete Vorbilder stehen bei den Phasen. Wenn die
   Wirklichkeit im Repo von der Spezifikation abweicht, ist die Wirklichkeit die
   Tatsache — melde die Abweichung, statt sie zu überschreiben.
2. **Umsetzen**, im kleinstmöglichen Umfang, der die Phase erfüllt. Kein
   Aufräumen nebenbei, keine Umbauten an fremden Stellen.
3. **Testen.** Die Tests der Phase schreiben und laufen lassen, dazu
   `make release-readiness-mobile` (`flutter analyze --no-fatal-infos` plus
   `flutter test`). Rot heißt: die Phase ist nicht fertig.
4. **Berichten und anhalten.** Melde: was geändert wurde (Dateiliste), welche
   Tests mit welchem Ergebnis liefen, was dir aufgefallen ist, und welche
   Annahme du triffst. Dann warte auf Freigabe, bevor du die nächste Phase
   beginnst.

Commits: eine Sache pro Commit, Nachricht im Repo-Stil
(`feat(invite): …`, `test(invite): …`). Vor jedem Commit
`git diff --cached --name-status` prüfen — es darf ausschließlich enthalten, was
zu deinem Commit gehört. Committe nicht ungefragt fremde, bereits vorhandene
Änderungen mit.

---

## Phase 0 — Linkarchitektur verifizieren. Blockierend.

**Vor jeder Zeile Code.** Wenn diese Phase scheitert, hört die Arbeit hier auf,
weil Linkformat, AASA-Pfade und die gesamte Zielseiten-Architektur davon abhängen.

Prüfe und protokolliere:

1. `https://reflexjourney.app/.well-known/apple-app-site-association` → HTTP 200,
   `Content-Type: application/json`, enthält die AppIDs `de.reflexjourney.app`,
   `.staging`, `.dev`
2. `https://reflexjourney.app/.well-known/assetlinks.json` → HTTP 200, enthält
   `de.reflexjourney.app`
3. `https://reflexjourney.app/selbstcheck` und `https://reflexjourney.app/en/selbstcheck`
   → HTTP 200
4. Ein bestehender Universal Link (`/auth/reset-password`) öffnet auf einem
   echten iPhone **und** einem echten Android-Gerät die App statt des Browsers

Ergebnis: eine kurze Notiz unter `docs/evidence/invite-phase0/` mit den vier
Befunden und den tatsächlichen Statuscodes. Punkt 4 kann der Auftraggeber
übernehmen — dann sag ihm genau, was er tippen und was er sehen soll.

Scheitert einer der Punkte: **anhalten, melden, nicht weiterbauen.**

---

## Phase 1 — Datenbank

Vorbilder, vorher lesen: `supabase/migrations/2026071901_multi_grant_entitlements.sql`
(RLS-Haltung, `REVOKE`, Constraint-Stil), `supabase/migrations/20260428_trainer_applications.sql`
(insbesondere `_trainer_activation_code()` und die Kollisionsschleife),
`supabase/tests/2026082104_relationship_lifecycle_protection_test.sql` (Teststil).

Liefere:
- `supabase/migrations/<YYYYMMDDNN>_referral_program.sql` — Datum des heutigen
  Tages, `NN` die nächste freie Nummer dieses Tages. Idempotent.
- `supabase/tests/<gleiche-ID>_referral_program_test.sql`

Inhalt nach Abschnitt 5 der Spezifikation: die Tabellen `referral_codes` und
`referrals`, sechs Funktionen, ein Trigger auf `training_sessions`. Beide
Tabellen bekommen RLS **ohne jede Policy** plus `REVOKE ALL ... FROM anon,
authenticated` — der gesamte Zugriff läuft über `SECURITY DEFINER`-Funktionen.

Tests, die grün sein müssen: Selbst-Einlösung abgewiesen, Doppel-Einlösung
abgewiesen, Konto älter als 30 Tage abgewiesen, stillgelegter Code abgewiesen,
`authenticated` kann beide Tabellen nicht direkt lesen, Trigger aktiviert genau
einmal auch bei mehrfacher Synchronisation, Trigger rührt fremde Zeilen nicht an,
`activated → blocked` wird abgewiesen, Kontolöschung des Eingeladenen setzt
`invitee_user_id` auf NULL ohne den Zähler zu verändern, Kontolöschung des
Einladenden entfernt Code und Zeilen, zwei Aufrufe von `get_my_invite_overview`
liefern denselben Code, **und**: nirgends entsteht ein `entitlement_grants`-,
`benefit_campaigns`- oder `benefit_codes`-Eintrag.

Prüfen mit `supabase db reset --local`. **Nicht live anwenden.**

---

## Phase 2 — Datenschicht in der App

Vorbild: ein bestehendes Feature mit demselben Schnitt, etwa
`lib/features/trainer/` — abstraktes Repository in `domain/repositories/`,
Supabase-Implementierung in `data/repositories/supabase_*_repository.dart`,
Riverpod in `presentation/providers/`.

Liefere `lib/features/invite/` mit Modell, Repository-Schnittstelle,
Supabase-Implementierung und Providern. Tests unter `test/features/invite/` mit
handgeschriebenen Fakes — `mocktail` wird in diesem Projekt nicht verwendet.

---

## Phase 3 — Einladen-Screen und Baumkarte

Route `/einladen`, Registrierung in `lib/core/navigation/app_router.dart`,
Gate-Konstante `kInviteEnabled` in `lib/config/launch_flags.dart` nach dem
Muster von `kPaywallEnabled` — inklusive Doc-Kommentar, der jede gegatete Fläche
und die Voraussetzungen zur Reaktivierung aufzählt. Die Konstante gated
**ausschließlich die Oberfläche der App**.

Der Baum ist ein `CustomPainter` mit einer **festen Positionstabelle** — nichts
Zufälliges, sonst sind die Golden-Tests wertlos. Zustände, Überschriften und das
Semantics-Label stehen wörtlich in Abschnitt 7 der Spezifikation; das Label nennt
bewusst keine Zweigzahl.

Alle Zeichenketten in `lib/l10n/app_de.arb` **und** `lib/l10n/app_en.arb`, danach
`flutter gen-l10n`. Die generierten Dateien werden mitcommittet. Keine
Zeichenkette direkt im Widget.

Tests: Golden-Tests der Karte bei 0, 1, 5 und 12 Aktivierungen, hell und dunkel;
Textskalierung 200 % ohne Überlauf.

---

## Phase 4 — Einlösen mit Bestätigung

Bestätigungsschritt, Onboarding-Schritt und Eintrag in den Einstellungen. Der
dauerhafte Eintrag steht **nur** in den Einstellungen, nicht zusätzlich im Profil.

Den genauen Platz des Onboarding-Schritts bestimmst du an der Weiterleitungslogik
in `lib/core/navigation/app_router.dart` (`_postAuthHome`, ab Zeile 177);
vorgesehen ist der letzte Schritt vor dem Dashboard. Melde, was du dort
vorgefunden hast, bevor du ihn einbaust.

Alle sechs Fehlerfälle bekommen ihre eigene Meldung aus Abschnitt 7 — keine
generische Fehlermeldung. Tests für jeden davon.

---

## Phase 5 — Deep Link

- `lib/core/storage/pending_invite_store.dart`, gebaut nach dem Vorbild von
  `lib/core/storage/file_local_storage.dart`. **Nicht `SharedPreferences`** —
  deren Kanal fällt auf iOS 26 aus, ein dort abgelegter Code überlebt keinen
  Neustart mitten in der Registrierung.
- Deep-Link-Behandlung in `lib/app.dart` um `/einladung` **und** `/en/einladung`
  erweitern (heute nur `/auth/reset-password`).
- `android/app/src/main/AndroidManifest.xml`: neuer `intent-filter` mit
  `pathPrefix="/einladung"`.
- Im Website-Repo: AASA-Pfade um `/einladung`, `/einladung/*`, `/en/einladung`,
  `/en/einladung/*` für alle drei AppIDs erweitern.

Fertig, wenn ein Link in allen drei Anmeldezuständen korrekt landet und der Code
einen App-Neustart übersteht.

---

## Phase 6 — Impulse

`lib/features/invite/domain/invite_prompt_policy.dart` als **reine, testbare
Logik ohne Flutter-Abhängigkeit**: höchstens ein Impuls in 30 Tagen, höchstens
drei im ersten Jahr, nach zweimaligem Anzeigen ohne Antippen dauerhaft still,
unterdrückt bei einem Mood-Check-in mit `mood <= 2` in den letzten 24 Stunden,
nie während einer laufenden Trainingssitzung.

Impuls I1 (unter dem Reflexprofil-Ergebnis) ist aktiv. Impuls I2 (Golden Day)
wird vollständig gebaut und getestet, aber hinter einer eigenen Konstante
**deaktiviert ausgeliefert**.

Beide sind ruhige Karten im Fluss, **nie ein Dialog**.

---

## Phase 7 — Website (anderes Repo)

In `/Users/alexandermessinger/dev/claudvibes/corejourney/reflexjourney-app-site`:
`src/pages/einladung.astro`, `src/pages/en/einladung.astro`,
`src/content-pages/EinladungPage.astro`, Texte in `src/i18n/`. Vorbild ist exakt
`selbstcheck.astro` → `SelbstcheckPage.astro`.

Der Code kommt aus dem Query-Parameter `?c=` — die Seite ist statisch gebaut, eine
Pfad-Route wäre nicht generierbar. `SelfCheck.astro` unverändert wiederverwenden.
`noindex` setzen und die Seite aus der Sitemap ausschließen.

Kein Satz auf dieser Seite verspricht eine Vergünstigung.

---

## Phase 8 — Messung

Admin-Sicht für den Vier-Stufen-Trichter, angeschlossen an die bestehende
Admin-Metrik (`2026060105_admin_metrics_v1.sql`). Die vier Größen sind
`share_action_tapped`, Zielseitenaufruf, Einlösung, Aktivierung — mit genau
diesen Namen. `share_action_tapped` zählt den Knopfdruck; behaupte nirgends, es
sei ein Teilen-Vorgang.

Selbstcheck-Abschlüsse werden **nicht** gemessen.

---

## Definition of Done je Phase

- `flutter analyze --no-fatal-infos` → keine Fehler, keine Warnungen
- `flutter test` → vollständig grün (beides über `make release-readiness-mobile`)
- neue Verhaltensweise hat mindestens einen Test
- neue Zeichenketten in beiden `.arb`-Dateien, `flutter gen-l10n` gelaufen
- bei berührten Screens: Vorher-Nachher-Screenshots unter `docs/evidence/<task>/`,
  und kein Screen zeigt eine leere Sektion, eine verwaiste Überschrift oder eine
  Sackgasse
- bei Datenbankänderungen: Migration idempotent, `supabase db reset --local`
  läuft grün, RLS-Auswirkung ausdrücklich benannt

## Abschlussbericht

Wenn alle Phasen abgenommen sind, liefere: die vollständige Dateiliste, die
Testergebnisse mit tatsächlichen Zahlen, die Liste der offenen Punkte, und die
ausdrückliche Bestätigung, dass weder `entitlement_grants` noch
`benefit_campaigns` noch `benefit_codes` an irgendeiner Stelle berührt wurden.
