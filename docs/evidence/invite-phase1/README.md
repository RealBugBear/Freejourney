# Phase 1 — Referral program (local verification)

**Datum:** 2026-08-21  
**Migration:** `supabase/migrations/2026082105_referral_program.sql`  
**Tests:** `supabase/tests/2026082105_referral_program_test.sql`  
**Live-Apply:** nicht ausgeführt (Founder-Gate)

## RLS

- `referral_codes`, `referrals`: RLS enabled, **0 policies**
- `REVOKE ALL … FROM anon, authenticated`
- Zugriff nur über SECURITY-DEFINER-RPCs
- Funktionsrechte: `REVOKE … FROM PUBLIC, anon, authenticated`, danach gezieltes
  `GRANT` (Supabase vergibt sonst standardmäßig `EXECUTE` an `anon`/`authenticated`)

## RPC-Vertrag `redeem_invite_code`

Einziges Feld: `{"result": "<wert>"}`  
Werte: `accepted` | `unknown_code` | `code_inactive` | `own_code` | `already_referred` | `account_too_old`  
Kein `status`/`reason`.

## P1-Korrektur

Einlösen prüft auf bestehende `training_sessions` mit `is_completed = true`.  
Falls ja → Zeile direkt `activated` + `activated_at`; sonst `pending`.

Redeem und Aktivierungs-Trigger teilen sich
`pg_advisory_xact_lock(87201405, hashtext(invitee_id))`, damit ein
gleichzeitiger Session-Sync und die Einlösung einander nicht verpassen.

## Landing views

`log_invite_landing_view` erhöht den Zähler nur bei `is_active IS TRUE`.

## Doppel-Einlösung

Getestet: **zwei sequenzielle** Aufrufe → zweiter `already_referred`.  
Nebenläufigkeit: Unique Constraint auf `invitee_user_id` schützt strukturell; **kein** Paralleltest in dieser Suite.

## pgTAP (beobachtet nach Korrektur)

Nach `supabase db reset --local` (mit Moro-Aside, siehe unten):

| Suite | Plan | `not ok` |
|---|---|---|
| `2026082105_referral_program_test` | `1..58` | 0 |

## Lokaler Reset — bekannte vorbestehende Blockade

`supabase db reset --local` mit unverändertem Repo scheitert an:

`supabase/migrations/2026072301_moro_content_snapshot_v1.sql`

Ursprünglicher Fehler (vorbestehend, nicht durch dieses Feature verursacht):

```text
ERROR: column "rhythm_type" of relation "exercises" does not exist
```

Die Spalte existiert nur in der hand-run Datei `supabase/exercises_migration.sql`, nicht in einer früheren Migration.

**Verifikationsverfahren (wie bei Begleitung-beenden):** Datei temporär beiseite legen → Reset → Datei unverändert zurücklegen. Nie die Entfernung committen.

Damit ist der Reset **kein** vollständiger unveränderter Repo-Replay; die Blockade ist dokumentiert und akzeptiert.

## Stage 2

Keine Schreibvorgänge in `entitlement_grants`, `benefit_campaigns`, `benefit_codes`.
