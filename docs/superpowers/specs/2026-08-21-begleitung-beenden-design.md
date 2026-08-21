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

**In Scope:** Beenden durch den Klienten; dauerhafte Trennung; Widerruf der
Reflexprofil-Freigabe; Absage offener Termine; Ende der Chat-Schreibrechte;
Benachrichtigung des Trainers; Bestätigungsdialog.

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

## 4. Design

### 4.1 Dauerhafte Trennung

Neue Spalte `trainer_client_relationships.ended_by_client_at timestamptz`.

- `ensure_trainer_client_relationship()` prüft **vor** allen anderen Zweigen, ob
  für das Paar eine Zeile mit gesetztem `ended_by_client_at` existiert. Wenn ja:
  sofort `RETURN NULL`, ohne zu reaktivieren **und ohne neu anzulegen**.

  Dieser frühe Ausstieg ist der entscheidende Teil. Ein bloßes „Überspringen"
  der Reaktivierung würde in den `INSERT`-Zweig am Ende der Funktion fallen und
  eine *neue* aktive Beziehung anlegen — der Auferstehungspfad wäre offen
  geblieben, nur unter neuer ID.

  `reconcile_trainer_clients()` wertet den Rückgabewert ohnehin nicht aus
  (`PERFORM`), `NULL` ist dort also unproblematisch.
- `accept_invite()` — eine ausdrückliche Klientenhandlung — setzt das Feld beim
  Reaktivieren zurück auf `NULL`. Nur der Klient bringt die Beziehung zurück.
- Bestehende Wechsel-Semantik bleibt: `accept_invite()` deaktiviert weiterhin
  alte aktive Beziehungen, ohne sie als klientenbeendet zu markieren.

Warum eine Spalte und kein neuer `status`-Wert: `status` wird an vielen Stellen
in Dart und SQL auf genau `pending|active|disconnected` geprüft; ein vierter
Wert wäre eine breite, riskante Änderung. Die Spalte ist additiv.

### 4.2 RPC `end_trainer_relationship(p_trainer_id uuid)`

`SECURITY DEFINER`, `GRANT EXECUTE` nur an `authenticated`. Eine Transaktion:

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

Additiv, nullable, kein Backfill. Bestehende `disconnected`-Zeilen bleiben
`NULL` und damit weiterhin reconcile-fähig — das ist gewollt: sie stammen aus
Wechseln, nicht aus bewussten Beendigungen.

## 6. Sicherheit und RLS

| Objekt | Änderung | Wirkung |
|---|---|---|
| `end_trainer_relationship` | neu, `SECURITY DEFINER`, nur `authenticated` | prüft `auth.uid()` als `client_id`; fremde Beziehungen unmöglich |
| `ensure_trainer_client_relationship` | belebt klientenbeendete Zeilen nicht mehr | schließt den Auferstehungspfad |
| `accept_invite` | setzt `ended_by_client_at = NULL` | nur der Klient holt die Beziehung zurück |
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

## 9. Offene Punkte

1. **Symmetrische Chat-Sperre** — als Empfehlung gesetzt (§4.3). Falls nur der
   Trainer gesperrt werden soll, ist das eine Einzeiler-Änderung an der Policy.
2. **Bestehende `disconnected`-Zeilen** bleiben reconcile-fähig (§5). Wer die
   gebrochene Wechsel-Semantik rückwirkend schließen will, braucht einen
   separaten Backfill-Entscheid — dann würden alte Wechsel endgültig.
3. **`trainer_notes`** bleibt bewusst unangetastet; eigene Rechtsfrage.
