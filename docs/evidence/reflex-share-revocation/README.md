# Reflex profile shares outliving the trainer relationship — fix evidence

**Datum:** 2026-08-21
**Migration:** `supabase/migrations/2026082101_revoke_reflex_shares_on_relationship_end.sql`
**Test:** `supabase/tests/2026082101_reflex_share_revocation_test.sql`
**Live-Apply:** ❌ nicht erfolgt — Founder-Go steht aus (CLAUDE.md §3)

## Befund

`reflex_profile_trainer_shares.revoked_at` war das einzige Gate in den
Trainer-RLS-Policies, aber **nichts im Beziehungs-Lebenszyklus hat es gesetzt**:

- `accept_invite()` (`20260424_atomic_trainer_switch.sql`) setzt beim
  Trainerwechsel alte Beziehungen auf `status = 'disconnected'`, fasst Shares
  aber nicht an.
- Kein Trigger auf `trainer_client_relationships`.
- Einziger Revoke-Pfad: `revokeReflexProfileTrainerShare()`
  (`reflex_profile_provider.dart:526`), aufgerufen aus einem Toggle, das nur
  für den **aktuell aktiven** Trainer gerendert wird
  (`accompaniment_screen.dart:542`; Trainer kommt aus
  `clientTrainerIdProvider`, gefiltert auf `status = 'active'`).

Folge: Nach einem Trainerwechsel behielt der frühere Trainer SELECT auf
`reflex_subject_profiles` und `reflex_profile_assessments` des Kindes — und der
Elternaccount konnte das nicht mehr rückgängig machen, weil der alte Trainer aus
der eigenen UI verschwunden war.

Zusätzlich: `relationship_id` ist `ON DELETE SET NULL`, ein gelöschter
Beziehungs-Datensatz hinterließ also eine unverankerte, weiterhin gültige Share.

## Fix — drei bewusst redundante Ebenen

1. **Trigger** `trg_revoke_reflex_shares_on_relationship_end`
   (AFTER UPDATE OR DELETE). Reagiert nur auf `active` → nicht-`active` bzw.
   DELETE. `SECURITY DEFINER` ist notwendig, nicht kosmetisch: `cj: tcr all
   trainer` erlaubt Trainern das Update ihrer eigenen Beziehungszeile, während
   Schreibrechte auf Shares nur der Owner hat — ein INVOKER-Trigger hätte
   ausgerechnet dann **stillschweigend 0 Zeilen** aktualisiert.
2. **RLS**: Trainer-Reads verlangen zusätzlich eine **aktive Beziehung**, nicht
   nur eine Share-Zeile. Damit kann eine veraltete Share für sich genommen nie
   mehr Zugriff gewähren (fail-safe, unabhängig vom Trigger).
3. **Backfill**: bereits verwaiste Shares werden geschlossen.
   Lokal `UPDATE 0` (frische DB); auf der Live-DB ist das die eigentlich
   wirksame Zeile.

Owner-Zugriff bleibt unverändert und umfasst weiterhin widerrufene Zeilen, damit
Klienten auditieren können, was sie je freigegeben haben.

## Verifikation (lokal, `supabase db reset --local`)

| Schritt | Ergebnis |
|---|---|
| pgTAP **vor** Fix | **5 von 10 rot** — u. a. „former trainer cannot read the subject profile / assessment after the relationship ends" |
| Migration angewandt | CREATE FUNCTION/TRIGGER/INDEX, 3 Policies ersetzt, Backfill `UPDATE 0` |
| pgTAP **nach** Fix | **10/10 grün** |
| Clean Replay `supabase db reset --local` | grün inkl. neuer Migration |
| Regression pgTAP T25.0 | **95/95 grün** |
| Idempotenz | Migration 2× erneut angewandt → OK, Tests weiter 10/10 |
| Objektdump | Trigger vorhanden, `prosecdef = t`, 8 Policies auf den 3 Tabellen |

Keine Dart-Änderung nötig: Der Owner-seitige Lookup
(`reflexProfileTrainerShareProvider`) läuft über die unveränderte
Owner-Policy, und `trainerClientSharedProfilesProvider` liefert nach der
RLS-Verschärfung für beendete Beziehungen schlicht nichts mehr.

## Dabei aufgefallen — getrennt zu behandeln, NICHT in dieser Änderung gefixt

1. **`supabase db reset --local` war vorher nicht replaybar.**
   `2026072301_moro_content_snapshot_v1.sql` schreibt `exercises.rhythm_type`;
   diese Spalte existiert nur in der handgefahrenen `supabase/exercises_migration.sql`
   und in keiner Migration → `ERROR: column "rhythm_type" of relation "exercises"
   does not exist`. Das ist CLAUDE.md-Fehlermuster #11 (SQL-Editor-Drift). Für
   die Verifikation oben wurde diese eine Migration temporär beiseitegelegt und
   danach unverändert zurückgelegt.
2. **`supabase/config.toml` fehlte komplett** — beim Verzeichnisumzug am
   2026-08-10 verloren gegangen (war nie in git). Mit `supabase init` neu
   erzeugt; liegt untracked vor, Commit-Entscheidung offen.
3. **Es gibt keinen Weg, sich von einem Trainer zu trennen.** Der einzige Ausstieg
   ist das Annehmen eines anderen Einladungscodes. „Ich möchte nicht mehr
   begleitet werden" ist im Produkt nicht vorgesehen.
