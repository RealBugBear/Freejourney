# Security finding — `trainer_client_relationships` is client- and trainer-writable

**Datum:** 2026-08-21
**Schweregrad:** P0 (Rechteausweitung, Gesundheits-/Kinderdaten)
**Status:** gefunden und lokal belegt; **nicht behoben**
**Ausgangspunkt:** Prüfung des Freitextfelds `trainer_notes`
**Live-DB geprüft:** nein — alle Belege stammen aus der lokalen Replay-DB

## Kurzfassung

`trainer_client_relationships` **ist** das Autorisierungsmodell: die
Trainer-Lesepolicies auf `enrollments`, `training_sessions`, `progress_entries`
und `mood_checkins` prüfen alle exakt
`EXISTS (… trainer_id = auth.uid() AND client_id = X AND status = 'active')`.

Die RLS auf dieser Tabelle ist aber zeilen-, nicht spaltenbezogen, und
`authenticated` besitzt `UPDATE`/`INSERT` auf **allen** Spalten (verifiziert
über `information_schema.column_privileges` — keine Spalteneinschränkung).
Beide Parteien dürfen damit genau die Spalten schreiben, die den Zugriff
definieren.

Es gibt keinen Schutz-Trigger analog `trg_prevent_direct_role_change` /
`trg_prevent_direct_premium_change`.

## Belege (lokal, jeweils in einer Transaktion mit ROLLBACK)

| # | Als | Aktion | Ergebnis |
|---|---|---|---|
| 1 | Klient | `SELECT trainer_notes` der eigenen Beziehung | liest den als „privat" gelabelten Trainer-Text |
| 2 | Klient | `UPDATE … SET trainer_notes = 'ÜBERSCHRIEBEN'` | erfolgreich |
| 3 | Klient | `UPDATE … SET trainer_id = <fremder Trainer>` | erfolgreich — Beziehung auf einen Trainer umgehängt, der nie zugestimmt hat |
| 4 | Trainer | `INSERT (trainer_id = self, client_id = <fremder Nutzer>, status='active')` | erfolgreich — aktive Beziehung ohne Einladungscode, ohne Zustimmung |
| 5 | Ex-Trainer | `UPDATE … SET ended_by_client_at = NULL` | erfolgreich |

Befund 4 bedeutet: **der Einladungscode ist kein Gate.** `accept_invite()` ist
der vorgesehene Weg, aber nicht der einzige. Jeder freigeschaltete Trainer kann
sich per direktem PostgREST-Aufruf an ein beliebiges Konto hängen und erhält
damit Lesezugriff auf dessen Trainings-, Fortschritts- und Stimmungsdaten.

## Erreichbarkeit — nüchtern

- **Nicht** über die App-UI. Kein Dart-Code führt diese Schreibvorgänge aus.
- **Aber** über die öffentliche REST-API: der anon key liegt im App-Binary,
  der Nutzer hat sein eigenes JWT. Ein `curl` genügt. Kein Exploit-Werkzeug.
- Befund 4 setzt `profiles.role = 'trainer'` voraus. Die Rolle ist per Trigger
  gegen Selbstvergabe geschützt, die Angreiferpopulation ist also auf
  freigeschaltete Trainer begrenzt — externe Personen, kein internes Personal.
- Befunde 1–3 und 5 brauchen nur ein normales Konto bzw. die eigene Beziehung.

## Sofort relevant für die laufende Arbeit

Befund 5 **hebt das gerade in Umsetzung befindliche Feature auf**
(`docs/superpowers/plans/2026-08-21-begleitung-beenden.md`).

Die Dauerhaftigkeit der Trennung beruht dort vollständig darauf, dass
`ended_by_client_at` gesetzt bleibt und `ensure_trainer_client_relationship()`
markierte Zeilen nicht wiederbelebt. Ein früherer Trainer kann den Marker aber
selbst löschen (`cj: tcr all trainer` ist `FOR ALL`) und sich anschließend über
den ganz normalen Reconcile-Lauf zurückholen.

Das Feature bleibt trotzdem richtig gebaut — die Reflexprofil-Freigabe bleibt
widerrufen, weil `2026082101` zusätzlich eine aktive Beziehung **und** eine
nicht widerrufene Share verlangt. Aber die Beziehung selbst, und damit Zugriff
auf Trainings-, Fortschritts- und Stimmungsdaten, ist ohne diesen Fix nicht
verlässlich beendbar.

## Ursache

Die Policies stammen aus `20260702_rls_baseline_core_tables.sql`. Dieses
Migrationsfile hat den **Live-Zustand abgebildet**, der zuvor per Hand im SQL
Editor entstanden war (siehe Backlog P0.1). Die Policies wurden also nie
entworfen, sondern kodifiziert. `cj: tcr update client` hat im Code keinen
einzigen Aufrufer.

## Vorgeschlagener Fix — ohne Anwalt, reine Codeänderung

Alle legitimen Mutationen laufen bereits über `SECURITY DEFINER`-RPCs:
`accept_invite()`, `ensure_trainer_client_relationship()`, `create_invite_code`,
und neu `end_trainer_relationship()`. Die einzige direkte Client-Library-
Schreiboperation ist `saveNotes` (`trainer_provider.dart:58-63`) — und die
gehört ohnehin hinter einen RPC, weil sie heute keine Statusprüfung hat.

1. **`cj: tcr update client` ersatzlos droppen.** Kein Aufrufer.
2. **`cj: tcr all trainer` von `FOR ALL` auf `FOR SELECT` reduzieren** — Lesen
   deckt bereits `cj: tcr select participant` ab, die Policy kann vermutlich
   ganz entfallen.
3. **`save_trainer_notes(p_relationship_id uuid, p_notes text)`** als
   `SECURITY DEFINER`-RPC, der Trainerschaft **und** `status='active'` prüft;
   `saveNotes` im Dart darauf umstellen.
4. **`REVOKE INSERT, UPDATE ON public.trainer_client_relationships FROM
   authenticated, anon`** als Defense in Depth — nach 1–3 schreibt kein
   Client-Pfad mehr direkt.
5. Regressionstests: alle fünf Belege oben als pgTAP-Negativtests.

Punkt 4 ist der eigentliche Riegel; 1–3 machen ihn möglich, ohne Funktionen zu
brechen.

## Warum jetzt nicht umgesetzt

Cursor arbeitet parallel im selben Working Tree an
`2026082102`/`2026082103` und ändert dabei `accept_invite()` sowie dieselbe
Tabelle. Gleichzeitige Policy-Änderungen an `trainer_client_relationships`
würden kollidieren. Reihenfolge: erst „Begleitung beenden" landen lassen, dann
diesen Fix als eigene Spec/Plan-Runde.

## Nicht enthalten

- Die Rechtsfrage zu `trainer_notes` (Rollen, AVV, Retention) bleibt offen und
  ist getrennt zu behandeln — siehe `docs/legal/DATENSCHUTZERKLAERUNG_ENTWURF.md`
  §7.2, dort als wichtigste offene Stelle markiert.
- Ob auf der **Live-DB** bereits Zeilen existieren, die auf so einen Schreibweg
  hindeuten (z. B. aktive Beziehungen ohne je vergebenen `invite_code`), ist
  ungeprüft. Eine reine Zähl-Abfrage dafür braucht ein Founder-Go.
