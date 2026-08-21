# Begleitung beenden — Design-Spec

**Stand:** 2026-08-21
**Status:** Entwurf zur Founder-Review — kein Build-Auftrag
**Owner:** Founder
**Verwandt:** `docs/evidence/reflex-share-revocation/README.md` ·
`supabase/migrations/2026082101_revoke_reflex_shares_on_relationship_end.sql`

## 1. Problem

Ein Klient kann eine Trainer-Begleitung heute **nicht beenden**. Der einzige
Ausweg ist, den Einladungscode eines *anderen* Trainers anzunehmen. „Ich möchte
nicht mehr begleitet werden" ist im Produkt nicht vorgesehen.

Schlimmer: **Trennung ist derzeit nicht dauerhaft.**
`TrainerClientsNotifier._fetch()` ruft bei *jedem* Laden der Klientenliste
`reconcile_trainer_clients()` auf (`trainer_provider.dart:40`). Diese Funktion
leitet Beziehungen aus zwei Signalen neu ab — einem offenen Termin oder einer
**Direct-Chat-Mitgliedschaft** — und `ensure_trainer_client_relationship()`
setzt eine `'disconnected'`-Zeile ausdrücklich wieder auf `'active'`
(`2026042503_harden_trainer_client_relationships.sql:51-66`).

Lokal am 2026-08-21 verifiziert: nach `status='disconnected'` und einem
Reconcile-Lauf steht die Beziehung wieder auf `active`.

**Damit ist auch die bestehende Trainerwechsel-Funktion gebrochen.** Die Copy
`accompanimentSwitchAccessBody` verspricht „Dein bisheriger Trainer verliert den
Zugriff auf deine Klientenübersicht" — tatsächlich kehrt der frühere Trainer
zurück, sobald er seine Liste öffnet, weil der Direct-Chat-Kanal fortbesteht.

**Nicht betroffen:** Reflexprofile. Die Migration vom 2026-08-21 widerruft Shares
beim Beziehungsende und verlangt in der RLS *sowohl* eine aktive Beziehung *als
auch* eine nicht widerrufene Share. Im selben Testlauf blieb der Zugriff auch
nach der Wiederbelebung bei `0`. Diese Ebene hält.

## 2. Scope

**In Scope:** Beenden durch den Klienten; dauerhafte Trennung; **Reparatur der
gebrochenen Wechsel-Semantik** (ein Wechsel markiert die verdrängte Beziehung
ebenfalls als klientenbeendet, §4.1); Widerruf der Reflexprofil-Freigabe; Absage
offener Termine; Ende der Chat-Schreibrechte; Benachrichtigung des Trainers;
Bestätigungsdialog.

**Nicht in Scope:** Löschen von Chatverläufen, `trainer_notes` oder
Vergangenheitsterminen (Retention ist eine Rechtsfrage, siehe
`docs/legal/DATENSCHUTZERKLAERUNG_ENTWURF.md` §7.2). Trainerseitiges Beenden.
Mehrfachbegleitung.

## 3. Entscheidungen (Founder, 2026-08-21)

| ID | Entscheidung |
|---|---|
| BB-1 | Clean Cut: Verlauf bleibt erhalten, nichts wird gelöscht |
| BB-2 | Trainer **wird** benachrichtigt |
| BB-3 | Bestätigungsdialog benennt ausdrücklich alle drei Folgen |
| BB-4 | Alle offenen Termine werden abgesagt |
| BB-5 | Chat-Sperre bleibt **symmetrisch** — nach dem Ende schreibt keine Seite mehr |
| BB-6 | **Kein** automatischer Backfill historischer `disconnected`-Zeilen. Zuerst ein Dry-Run-Count nach vermuteter Ursache (§8.1). Künftige Wechsel werden aber sofort korrekt markiert |

## 4. Design

### 4.1 Dauerhafte Trennung

Neue Spalte `trainer_client_relationships.ended_by_client_at timestamptz`.

- `ensure_trainer_client_relationship()` erhält einen Marker-Guard. Die
  **Reihenfolge der Zweige ist Teil des Vertrags**:

  ```text
  1. Auth- und Rollenprüfung                        (unverändert)
  2. Aktive Zeile für das Paar?      -> RETURN deren id
  3. IRGENDEINE Zeile des Paares mit
     ended_by_client_at IS NOT NULL? -> RETURN NULL
  4. Neueste disconnected Zeile?     -> reaktivieren, RETURN deren id
  5. sonst                           -> INSERT, RETURN neue id
  ```

  **Zu Schritt 3 — der frühe Ausstieg ist der entscheidende Teil.** Ein bloßes
  „Überspringen" der Reaktivierung in Schritt 4 würde in den `INSERT`-Zweig 5
  fallen und eine *neue* aktive Beziehung anlegen — der Auferstehungspfad wäre
  offen geblieben, nur unter neuer ID.

  **Zu Schritt 2 vor Schritt 3 — ebenfalls bewusst.** Eine aktive Beziehung ist
  die Grundwahrheit. Läge der Guard davor, würde eine übrig gebliebene markierte
  Altzeile den Rückgabewert einer gültigen aktiven Beziehung auf `NULL` ziehen.
  `reconcile_trainer_clients()` wertet den Rückgabewert zwar nicht aus
  (`PERFORM`), aber der Vertrag der Funktion darf nicht von Altlasten abhängen.

  Der Guard ist bewusst **paarweit** („irgendeine Zeile"), nicht zeilenweise —
  siehe §4.1.1.
- **Der Trainerwechsel markiert ebenfalls.** `accept_invite()` Schritt 2
  deaktiviert heute alle aktiven Beziehungen des Klienten, ohne sie zu
  markieren — damit bliebe der verdrängte Trainer über Reconcile wiederbelebbar
  und die gebrochene Wechsel-Semantik aus §1 ungefixt. Ein Wechsel ist genauso
  eine bewusste Klientenhandlung wie ein Beenden, also setzt Schritt 2 künftig
  `ended_by_client_at = now()` für jede verdrängte Zeile mit.
- `accept_invite()` setzt das Feld beim Reaktivieren zurück — **paarweit**, nicht
  nur auf der ausgewählten Zeile (§4.1.1). Nur der Klient bringt eine Beziehung
  zurück.

Warum eine Spalte und kein neuer `status`-Wert: `status` wird an vielen Stellen
in Dart und SQL auf genau `pending|active|disconnected` geprüft; ein vierter
Wert wäre eine breite, riskante Änderung. Die Spalte ist additiv.

### 4.1.1 Mehrere `disconnected`-Zeilen pro Paar

**Das Schema erlaubt beliebig viele `disconnected`-Zeilen pro Trainer-Klient-Paar.**
Verifiziert am 2026-08-21: die Unique-Indizes decken nur
`WHERE status='active'` (`uq_trainer_client_active`, `uq_trainer_client_active_pair`)
und `pending+discovery` ab. Für `disconnected` existiert keine Eindeutigkeit.

Damit ist jede zeilenweise Markerlogik fehlerhaft. Konkret: würde
`accept_invite()` den Marker nur auf der von ihm ausgewählten Zeile löschen,
bliebe eine zweite markierte Zeile stehen — und der paarweite Guard aus §4.1
Schritt 3 würde die Beziehung danach dauerhaft von der Reconciliation
ausschließen. Das Paar wäre still verklemmt.

Verschärfend: `accept_invite()` wählt seine Zeile heute mit `LIMIT 1` **ganz
ohne `ORDER BY`** (`20260424_atomic_trainer_switch.sql`), also
nichtdeterministisch. `ensure_trainer_client_relationship()` ordnet immerhin
nach `linked_at DESC NULLS LAST, created_at DESC`.

**Verbindliche Paar-Semantik:**

1. **Eine kanonische Reihenfolge**, identisch in beiden Funktionen:
   `ORDER BY linked_at DESC NULLS LAST, created_at DESC, id DESC`.
   Der `id`-Tiebreaker macht die Auswahl auch bei identischen Zeitstempeln
   deterministisch.
2. **Wiederverwendet wird immer genau diese eine Zeile** — es entsteht keine
   weitere `disconnected`-Zeile für ein Paar, das schon eine hat.
3. **Marker werden paarweit gesetzt und paarweit gelöscht**:
   `UPDATE ... WHERE trainer_id = :t AND client_id = :c`, nie `WHERE id = :one`.

Ein Unique-Index auf `disconnected` pro Paar wäre die sauberere Lösung, würde
aber an vorhandenen Duplikaten in der Live-DB scheitern. Deduplizierung ist eine
mögliche spätere Aufräumarbeit und **nicht** Teil dieser Änderung.

**Nebenbefund:** `uq_trainer_client_active` und `uq_trainer_client_active_pair`
sind zwei identische partielle Unique-Indizes auf demselben Prädikat. Redundant,
harmlos, hier nicht angefasst.

### 4.2 RPC `end_trainer_relationship(p_trainer_id uuid)`

**Härtung — verbindlich für diesen und jeden neuen `SECURITY DEFINER`-RPC:**

```sql
CREATE OR REPLACE FUNCTION public.end_trainer_relationship(p_trainer_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$ ... $function$;

REVOKE ALL ON FUNCTION public.end_trainer_relationship(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.end_trainer_relationship(uuid)
  TO authenticated;
```

Das `REVOKE` ist **nicht optional**. PostgreSQL vergibt `EXECUTE` bei
`CREATE FUNCTION` standardmäßig an `PUBLIC`; „wir granten nur `authenticated`"
ist ohne vorheriges `REVOKE` schlicht falsch. Am 2026-08-21 lokal belegt: eine
frisch angelegte Funktion liefert für `public`, `anon` **und** `authenticated`
jeweils `has_function_privilege = t`. Ohne `REVOKE` wäre der RPC für `anon`
aufrufbar.

Ebenfalls verbindlich: `search_path` gepinnt und **alle** Objekte im Rumpf
schema-qualifiziert (`public.trainer_client_relationships`, `public.appointments`),
damit ein untergeschobenes Objekt die Definer-Rechte nicht kapern kann.
`pg_temp` steht am Ende, damit temporäre Objekte nichts überschatten — konsistent
mit der bereits ausgelieferten `2026082101`, deren Trigger-Funktion die Härtung
schon so umsetzt (dort verifiziert: `has_function_privilege('public', …) = f`).

Eine Transaktion:

1. Prüft, dass **der Aufrufer** (`auth.uid()`) eine `active` Beziehung zu
   `p_trainer_id` als `client_id` hat. Sonst `RAISE EXCEPTION`. Niemand kann
   fremde Beziehungen beenden.
2. Setzt `status='disconnected'`, `ended_by_client_at=now()`.
   → der bestehende Trigger `trg_revoke_reflex_shares_on_relationship_end`
   widerruft die Reflexprofil-Shares. **Keine Duplizierung dieser Logik.**
3. Setzt alle Termine des Paares mit
   `status IN ('proposed','planned','confirmed')` auf `'cancelled'`.
   `'done'` und bereits `'cancelled'` bleiben unangetastet.
   Bewusst ohne Datumsfilter: auch vergangene, nie aufgelöste Vorschläge werden
   geschlossen, statt als Zombies stehen zu bleiben.

Rückgabe: `void`. Idempotenz: ein zweiter Aufruf findet keine aktive Beziehung
mehr und schlägt sauber fehl.

### 4.3 Chat — Schreibrechte enden, Lesen bleibt

Heute hängt das Schreibrecht ausschließlich an der Kanalmitgliedschaft
(`messages_insert_member`), nicht an der Beziehung. Ein getrennter Trainer kann
weiterschreiben. Nachrichten werden direkt per
`.from('chat_messages').insert(...)` eingefügt
(`supabase_chat_repository.dart:225`), die Policy ist also der reale Gate.

`messages_insert_member` wird erweitert: bei Kanälen vom Typ `'direct'` ist
zusätzlich eine **aktive Trainer-Klient-Beziehung zwischen den beiden
Kanalmitgliedern** erforderlich. `'community'` und `'application_review'`
bleiben unverändert.

Die Regel ist **symmetrisch** — nach dem Ende schreibt keine Seite mehr, damit
der Klient nicht ins Leere sendet. `messages_select_member` bleibt unangetastet:
beide Seiten behalten ihren Verlauf (BB-1).

UI: Der Composer im Thread wird bei beendeter Beziehung durch einen ruhigen
Hinweis ersetzt, kein deaktiviertes Eingabefeld ohne Erklärung
(CLAUDE.md-Fehlermuster #14).

### 4.4 Trainer-Benachrichtigung

Neue Edge Function `notify-accompaniment-ended` nach dem Muster von
`notify-appointment-confirmed`: JWT-Verifikation, Aufrufer muss der Klient der
beendeten Beziehung sein, Device-Tokens des Trainers laden
(`enabled = true AND revoked_at IS NULL`), FCM senden. Copy über
`_shared/notification_copy.ts`, DE/EN, neutral formuliert — kein Grund, keine
Bewertung: „<Klient> hat die Begleitung beendet."

Fehlschlag der Benachrichtigung darf das Beenden **nie** blockieren: der RPC
läuft zuerst und committet; der Funktionsaufruf ist fire-and-forget.

Kein Kalender-, E-Mail- oder Chat-Hinweis. Keine Zustellgarantie in der Copy.

### 4.5 Klienten-UI

`_ConnectedTrainerCard` hat bereits einen Abschnitt `accompanimentSwitchTitle`
mit *Trainer finden* und *Code eingeben*. Dort kommt eine dritte, bewusst
zurückhaltende Aktion hinzu: `TextButton` in `colorScheme.error`, kein dritter
`OutlinedButton`, der mit dem Wechseln konkurriert.

Der Bestätigungsdialog benennt gemäß BB-3 ausdrücklich alle drei Folgen:

1. Der Trainer kann deine Reflexprofile nicht mehr sehen.
2. Ihr könnt euch keine Nachrichten mehr schreiben. Euer bisheriger Verlauf
   bleibt erhalten.
3. Alle offenen Termine werden abgesagt.

Dazu: „Dein Trainer wird darüber informiert." und „Du kannst dich später mit
einem neuen Code wieder verbinden." Aktionen: *Abbrechen* / *Begleitung
beenden* (destruktiv).

Nach Erfolg: Provider invalidieren, Snackbar, Rückfall auf das bestehende
`_NoTrainerCard`. Kein neuer Empty State.

Der Dialog kommt in eine eigene Datei — `accompaniment_screen.dart` hat bereits
1055 Zeilen.

## 5. Datenmodell

```sql
ALTER TABLE public.trainer_client_relationships
  ADD COLUMN IF NOT EXISTS ended_by_client_at timestamptz;
```

Additiv, nullable, kein Backfill (BB-6).

Bestehende `disconnected`-Zeilen bleiben `NULL` und damit weiterhin
reconcile-fähig. Das ist **keine** Aussage darüber, ob sie es verdienen — seit
§4.1 gilt ein Wechsel ausdrücklich als bewusste Beendigung, historische
Wechselzeilen wären also inhaltlich markierungswürdig. Sie bleiben nur deshalb
unangetastet, weil ein Massen-Update auf Beziehungen echter Nutzer eine eigene
Entscheidung ist: es macht jeden vergangenen Wechsel endgültig und kann
Begleitungen kappen, die faktisch weiterlaufen. Grundlage dafür ist der Dry-Run
aus §8.1, nicht diese Spec.

## 6. Sicherheit und RLS

| Objekt | Änderung | Wirkung |
|---|---|---|
| `end_trainer_relationship` | neu, `SECURITY DEFINER`, `search_path` gepinnt, `REVOKE ... FROM PUBLIC, anon` **vor** `GRANT ... TO authenticated` | prüft `auth.uid()` als `client_id`; fremde Beziehungen unmöglich; für `anon` nicht aufrufbar |
| `ensure_trainer_client_relationship` | paarweiter Marker-Guard nach der Aktiv-Prüfung | schließt den Auferstehungspfad, ohne gültige aktive Beziehungen zu beschädigen |
| `accept_invite` | markiert verdrängte Zeilen; löscht Marker paarweit; deterministische Zeilenauswahl | repariert die gebrochene Wechsel-Semantik; nur der Klient holt eine Beziehung zurück |
| `messages_insert_member` | Direct-Kanäle verlangen aktive Beziehung | Schreibrechte enden beidseitig; Lesen unberührt |

Keine Lockerung bestehender Policies. Keine neue Datenkategorie.

## 7. Tests

**pgTAP** (`supabase/tests/2026082102_end_trainer_relationship_test.sql`):

- beendet die Beziehung und setzt `ended_by_client_at`
- widerruft die Reflexprofil-Shares (über den bestehenden Trigger)
- **Regression Auferstehung:** nach Beenden + `reconcile_trainer_clients()`
  bleibt die Beziehung `disconnected` — **und** die Gesamtzahl der Zeilen für
  das Paar bleibt unverändert (deckt den `INSERT`-Zweig aus §4.1 ab: keine neue
  aktive Beziehung unter neuer ID)
- Auferstehung bleibt auch bei bestehendem Direct-Chat **und** offenem Termin
  ausgeschlossen — beide Reconcile-Signale einzeln geprüft
- sagt `proposed`/`planned`/`confirmed` ab, lässt `done` unberührt
- fremder Aufrufer kann eine Beziehung nicht beenden
- ohne aktive Beziehung schlägt der Aufruf sauber fehl
- getrennter Trainer kann nicht mehr in den Direct-Kanal schreiben
- getrennter Trainer **kann** den bisherigen Verlauf weiter lesen
- Community-Kanäle bleiben unbeeinflusst
- `accept_invite` mit neuem Code stellt die Beziehung wieder her und leert
  `ended_by_client_at`; Reflexprofil-Freigabe bleibt widerrufen und muss neu
  erteilt werden
- **Wechsel markiert:** nach `accept_invite` zu Trainer B ist die verdrängte
  Beziehung zu Trainer A `disconnected` **mit** gesetztem `ended_by_client_at`,
  und ein Reconcile-Lauf von A belebt sie nicht wieder
- **Duplikate (§4.1.1):** bei zwei `disconnected`-Zeilen für dasselbe Paar,
  davon eine markiert, stellt `accept_invite` die Beziehung wieder her und
  **keine** Zeile des Paares behält den Marker; ein anschließender
  Reconcile-Lauf lässt die Beziehung aktiv
- **Determinismus:** bei zwei `disconnected`-Zeilen mit identischem `linked_at`
  und `created_at` wählen `accept_invite` und
  `ensure_trainer_client_relationship` dieselbe Zeile
- `end_trainer_relationship` ist für `anon` **nicht** ausführbar
  (`has_function_privilege('anon', …) = false`)

**Flutter:** Widget-Test für Aktion + Dialog; Test, dass der Composer bei
beendeter Beziehung durch den Hinweis ersetzt wird.

**Deno:** `deno check` für die neue Edge Function.

## 8. Gates

- **Live-DDL** (Spalte, RPC, Policy, Funktionsänderungen): Founder-Go nötig.
  Diese Spec ist kein Go.
- **Edge-Function-Deploy**: Founder-Go nötig.
- Migration `2026082101` (Reflexprofil-Shares) ist ebenfalls **noch nicht live
  angewendet** und sollte gemeinsam mit dieser Änderung eingeplant werden.
- `git push`: nie.

### 8.1 Dry-Run vor jedem Backfill-Entscheid (BB-6)

Historische `disconnected`-Zeilen werden **nicht** automatisch markiert. Vor
einer Entscheidung darüber liefert eine **lesende** Abfrage eine Häufigkeits-
verteilung nach vermuteter Ursache — ausschließlich Aggregate, keine IDs, keine
Namen, keine Zeitstempel einzelner Nutzer (§5 der CLAUDE.md-Redaktionsregel):

| Bucket | Heuristik | Bedeutung |
|---|---|---|
| `likely_switch` | Klient hat eine andere **aktive** Beziehung | klassischer Trainerwechsel |
| `no_active_trainer` | Klient hat gar keine aktive Beziehung | Abbruch oder Altbestand |
| `resurrectable_chat` | Direct-Chat-Kanal zwischen dem Paar existiert | wird beim nächsten Reconcile wiederbelebt |
| `resurrectable_appt` | offener Termin (`proposed`/`planned`/`confirmed`) | wird beim nächsten Reconcile wiederbelebt |
| `duplicate_pair` | Paar hat > 1 `disconnected`-Zeile | betrifft §4.1.1 |

Die letzten drei überschneiden sich bewusst mit den ersten beiden; sie werden
als eigene Zähler ausgegeben, nicht als disjunkte Partition. Erst diese Zahlen
begründen einen Backfill-Vorschlag — oder belegen, dass keiner nötig ist.

Ohne Backfill gilt: künftige Wechsel und Beendigungen sind sauber, historische
Zeilen bleiben reconcile-fähig. Das ist der bewusst gewählte Zwischenstand.

## 9. Offene Punkte

1. **`trainer_notes`** bleibt bewusst unangetastet; eigene Rechtsfrage
   (`docs/legal/DATENSCHUTZERKLAERUNG_ENTWURF.md` §7.2).
2. **Deduplizierung** der `disconnected`-Zeilen und der beiden redundanten
   Aktiv-Indizes (§4.1.1) — spätere Aufräumarbeit, hier nur dokumentiert.
3. **Backfill-Entscheid** offen bis zum Dry-Run aus §8.1.
