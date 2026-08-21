# Begleitung beenden — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
>
> **Executing without Superpowers (e.g. Cursor):** ignore the line above and work the tasks in order, top to bottom. Every task is self-contained: write the failing test, run it, confirm it fails for the stated reason, implement, re-run, commit. Do not batch tasks.

**Goal:** Let a client end a trainer accompaniment themselves, durably — revoking reflex profile access, cancelling open appointments, ending chat write rights, and notifying the trainer exactly once.

**Architecture:** Server-side first. A new `end_trainer_relationship` RPC performs the end; the already-shipped trigger `trg_revoke_reflex_shares_on_relationship_end` handles share revocation and is *not* reimplemented. Durability comes from a new `ended_by_client_at` marker that `ensure_trainer_client_relationship()` refuses to resurrect. Chat write authorization moves from pure channel membership to membership plus an active relationship, bound to `auth.uid()`. The Flutter layer only calls the RPC and renders a confirmation dialog.

**Tech Stack:** PostgreSQL 15 / Supabase RLS + pgTAP, Deno Edge Functions, Flutter 3.38 + Riverpod, `flutter gen-l10n`.

**Spec:** `docs/superpowers/specs/2026-08-21-begleitung-beenden-design.md` — read it first. This plan implements it and does not restate its reasoning.

## Amendment 2026-08-21 — Task 4 policy shape

Tasks 1–3 are implemented and committed (`942bb26`, `ee168bb`, `1357fd2`); a
clean `supabase db reset --local` replayed green and the suites stand at
26 / 10 / 95.

Task 4 was **blocked and its policy has been corrected.** The original inline
`EXISTS (… JOIN chat_channel_members other …)` in `messages_insert_member`
cannot work: RLS applies to subqueries inside a policy expression, and
`members_select_own` is `user_id = auth.uid()`, so the sender sees only their
own membership row. The subquery matched zero rows and denied **every**
direct-channel write, including legitimate ones. Reproduced independently on
2026-08-21: `other_members_visible_to_sender = 0` while the definer function
returned `true` for the same actor and channel.

The predicate now lives solely in `public.can_write_chat_channel(uuid)` and the
policy delegates to it. The function was renamed from `can_write_direct_channel`
because after the delegation it decides for every channel type. Both the
delegating policy and the three-clause shape below were verified live on the
local database before this amendment was written.

Anyone re-reading Task 4: do **not** "simplify" the delegation back into an
inline subquery. It looks equivalent and is not.

If you already applied the earlier version of
`2026082103_direct_chat_write_requires_relationship.sql` locally, replace the
file with the corrected version below and re-run
`supabase db reset --local` rather than layering a second policy edit on top.

## Global Constraints

- **Working directory:** `/Users/alexandermessinger/dev/claudvibes/reflexjourney`. Never `/Users/alexandermessinger/dev/corejourney` (obsolete clone) and never `claudvibes/corejourney/app` (empty shell).
- **`git push` is forbidden.** A push can trigger the production deploy workflow. Local commits only.
- **No live database changes.** Every migration in this plan is verified with `supabase db reset --local` only. Applying to `sxvpiggednbftfqeokyd` needs a separate founder go.
- **No Edge Function deploy.** Task 5 writes and type-checks a function; deploying it needs a separate founder go.
- **Migration naming:** `YYYYMMDDNN_descriptive_snake_case.sql`, idempotent, replays green under `supabase db reset --local`.
- **Every `SECURITY DEFINER` function:** `SET search_path = public, pg_temp`, all objects schema-qualified, and `REVOKE ALL ON FUNCTION … FROM PUBLIC, anon;` **before** `GRANT EXECUTE … TO authenticated;`. PostgreSQL grants EXECUTE to PUBLIC on `CREATE FUNCTION`; granting to `authenticated` alone leaves the function callable by `anon`.
- **Localization:** every user-facing string goes into **both** `lib/l10n/app_en.arb` and `lib/l10n/app_de.arb`, then `flutter gen-l10n`. Never hardcode a string in a widget. German addresses the user as "du".
- **Copy rules:** no healing, therapy, diagnosis or medical-benefit claims. Never assert notification delivery — "informiert" / "wird benachrichtigt", never "erhält" or "bekommt zugestellt".
- **No real user data** in tests, evidence or logs. Synthetic UUIDs and `@example.invalid` emails only. Report counts and booleans, never rows.
- **Quality bar per code change:** `flutter analyze --no-fatal-infos` → 0 errors, 0 warnings; `flutter test` → 100% pass. Both run together via `make release-readiness-mobile`.
- **Before every commit:** run `git diff --cached --name-status` and confirm the staged list is exactly the files in that task. The working tree already carries unrelated modifications to `android/settings.gradle.kts`, `firebase.json` and `pubspec.yaml` — **never** sweep those in.

## Environment note

`supabase/config.toml` was recreated on 2026-08-21 via `supabase init` and is untracked. It is required for local verification.

`supabase db reset --local` currently **fails** on the pre-existing migration `2026072301_moro_content_snapshot_v1.sql` (`ERROR: column "rhythm_type" of relation "exercises" does not exist` — the column lives only in the hand-run `supabase/exercises_migration.sql`). This is unrelated to this plan and is tracked separately. Until it is fixed, verify by temporarily moving that one file out of `supabase/migrations/`, running the reset, then putting it back unchanged. Never commit its removal.

Start the stack once before Task 1:

```bash
supabase start
```

Run a pgTAP file against the local database with:

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/<file>.sql
```

## File Structure

| File | Responsibility |
|---|---|
| `supabase/migrations/2026082102_relationship_end_lifecycle.sql` | Both marker columns, `end_trainer_relationship`, resurrection guard, switch marking |
| `supabase/migrations/2026082103_direct_chat_write_requires_relationship.sql` | Chat write authorization only |
| `supabase/tests/2026082102_relationship_end_lifecycle_test.sql` | pgTAP for Tasks 1–3 |
| `supabase/tests/2026082103_direct_chat_write_test.sql` | pgTAP for Task 4 |
| `supabase/functions/_shared/notification_copy.ts` | + `buildAccompanimentEndedCopy` |
| `supabase/functions/notify-accompaniment-ended/index.ts` | One-off push with atomic claim |
| `lib/features/trainer/presentation/providers/trainer_provider.dart` | + `endTrainerRelationship()` |
| `lib/features/accompaniment/presentation/widgets/end_accompaniment_dialog.dart` | Confirmation dialog (new file — the screen is already 1055 lines) |
| `lib/features/accompaniment/presentation/screens/accompaniment_screen.dart` | Third action in the switch section |
| `lib/features/chat/presentation/screens/chat_channel_screen.dart` | Locked-composer state |
| `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb` | New copy, both languages |
| `test/features/accompaniment/end_accompaniment_dialog_test.dart` | Widget test |
| `docs/evidence/begleitung-beenden/README.md` | Evidence |

Two migrations, not one: relationship lifecycle and chat authorization are separate concerns and must be separately reviewable and revertable.

---

## Task 1: Marker columns and the `end_trainer_relationship` RPC

**Files:**
- Create: `supabase/migrations/2026082102_relationship_end_lifecycle.sql`
- Create: `supabase/tests/2026082102_relationship_end_lifecycle_test.sql`

**Interfaces:**
- Consumes: `trg_revoke_reflex_shares_on_relationship_end` from the already-applied `2026082101_revoke_reflex_shares_on_relationship_end.sql`. Do not reimplement share revocation.
- Produces: `public.end_trainer_relationship(p_trainer_id uuid) RETURNS void`; columns `trainer_client_relationships.ended_by_client_at timestamptz` and `.end_notification_sent_at timestamptz`.

- [ ] **Step 1: Write the failing test**

Create `supabase/tests/2026082102_relationship_end_lifecycle_test.sql`:

```sql
BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path = public, extensions;

SELECT no_plan();

SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
)
SELECT
  '00000000-0000-0000-0000-000000000000'::uuid, f.id, 'authenticated',
  'authenticated', f.email, '', now(),
  '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
  now(), now(), '', '', '', ''
FROM (VALUES
  ('2b100000-0000-4000-8000-000000000001'::uuid, 'bb-trainer-a@example.invalid'),
  ('2b100000-0000-4000-8000-000000000002'::uuid, 'bb-trainer-b@example.invalid'),
  ('2b100000-0000-4000-8000-000000000003'::uuid, 'bb-parent@example.invalid'),
  ('2b100000-0000-4000-8000-000000000004'::uuid, 'bb-stranger@example.invalid')
) AS f(id, email)
ON CONFLICT (id) DO NOTHING;

UPDATE public.profiles SET role = 'trainer'
 WHERE id IN ('2b100000-0000-4000-8000-000000000001',
              '2b100000-0000-4000-8000-000000000002');

-- Schema contract
SELECT has_column('public','trainer_client_relationships','ended_by_client_at',
  'client-end marker column exists');
SELECT has_column('public','trainer_client_relationships','end_notification_sent_at',
  'notification claim column exists');
SELECT has_function('public','end_trainer_relationship', ARRAY['uuid'],
  'end RPC exists');
SELECT ok(
  NOT has_function_privilege('anon','public.end_trainer_relationship(uuid)','EXECUTE'),
  'anon cannot execute the end RPC'
);
SELECT ok(
  has_function_privilege('authenticated','public.end_trainer_relationship(uuid)','EXECUTE'),
  'authenticated can execute the end RPC'
);

-- Fixture: active relationship, shared reflex profile, mixed appointments
INSERT INTO public.trainer_client_relationships (id, trainer_id, client_id, status, linked_at)
VALUES ('2b300000-0000-4000-8000-000000000001',
        '2b100000-0000-4000-8000-000000000001',
        '2b100000-0000-4000-8000-000000000003', 'active', now());

INSERT INTO public.reflex_subject_profiles (id, owner_user_id, profile_type, display_name)
VALUES ('2b200000-0000-4000-8000-000000000001',
        '2b100000-0000-4000-8000-000000000003', 'child', 'Testkind');

INSERT INTO public.reflex_profile_trainer_shares
  (id, subject_profile_id, owner_user_id, trainer_id, relationship_id)
VALUES ('2b400000-0000-4000-8000-000000000001',
        '2b200000-0000-4000-8000-000000000001',
        '2b100000-0000-4000-8000-000000000003',
        '2b100000-0000-4000-8000-000000000001',
        '2b300000-0000-4000-8000-000000000001');

INSERT INTO public.appointments (id, trainer_id, trainee_id, scheduled_for, status)
VALUES
  ('2b500000-0000-4000-8000-000000000001','2b100000-0000-4000-8000-000000000001',
   '2b100000-0000-4000-8000-000000000003', now() + interval '7 days','confirmed'),
  ('2b500000-0000-4000-8000-000000000002','2b100000-0000-4000-8000-000000000001',
   '2b100000-0000-4000-8000-000000000003', now() - interval '30 days','proposed'),
  ('2b500000-0000-4000-8000-000000000003','2b100000-0000-4000-8000-000000000001',
   '2b100000-0000-4000-8000-000000000003', now() - interval '60 days','done');

-- A stranger cannot end someone else's relationship
SELECT set_config('request.jwt.claims',
  '{"sub":"2b100000-0000-4000-8000-000000000004","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT throws_ok(
  $$ SELECT public.end_trainer_relationship('2b100000-0000-4000-8000-000000000001') $$,
  NULL,
  NULL,
  'a stranger cannot end a relationship they are not the client of'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

SELECT is(
  (SELECT status FROM public.trainer_client_relationships
    WHERE id='2b300000-0000-4000-8000-000000000001'),
  'active',
  'the failed attempt changed nothing'
);

-- The client ends it
SELECT set_config('request.jwt.claims',
  '{"sub":"2b100000-0000-4000-8000-000000000003","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT lives_ok(
  $$ SELECT public.end_trainer_relationship('2b100000-0000-4000-8000-000000000001') $$,
  'the client can end their own accompaniment'
);

SELECT throws_ok(
  $$ SELECT public.end_trainer_relationship('2b100000-0000-4000-8000-000000000001') $$,
  NULL,
  NULL,
  'ending twice fails cleanly instead of doing partial work'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

SELECT is(
  (SELECT status FROM public.trainer_client_relationships
    WHERE id='2b300000-0000-4000-8000-000000000001'),
  'disconnected',
  'relationship is disconnected'
);
SELECT isnt(
  (SELECT ended_by_client_at FROM public.trainer_client_relationships
    WHERE id='2b300000-0000-4000-8000-000000000001'),
  NULL,
  'relationship is marked as ended by the client'
);
SELECT isnt(
  (SELECT revoked_at FROM public.reflex_profile_trainer_shares
    WHERE id='2b400000-0000-4000-8000-000000000001'),
  NULL,
  'the existing trigger revoked the reflex profile share'
);
SELECT is(
  (SELECT status FROM public.appointments
    WHERE id='2b500000-0000-4000-8000-000000000001'),
  'cancelled',
  'a future confirmed appointment is cancelled'
);
SELECT is(
  (SELECT status FROM public.appointments
    WHERE id='2b500000-0000-4000-8000-000000000002'),
  'cancelled',
  'a stale past proposal is cancelled too, leaving no zombie'
);
SELECT is(
  (SELECT status FROM public.appointments
    WHERE id='2b500000-0000-4000-8000-000000000003'),
  'done',
  'a completed appointment stays as history'
);

SELECT * FROM finish();
ROLLBACK;
```

- [ ] **Step 2: Run the test and confirm it fails**

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026082102_relationship_end_lifecycle_test.sql 2>&1 | grep -E "^ (not ok|ok) [0-9]+|Looks like"
```

Expected: the `has_column` and `has_function` assertions fail — the columns and RPC do not exist yet. Do not proceed until you have seen real `not ok` lines.

- [ ] **Step 3: Write the migration**

Create `supabase/migrations/2026082102_relationship_end_lifecycle.sql`:

```sql
-- Client-initiated end of a trainer accompaniment.
-- Spec: docs/superpowers/specs/2026-08-21-begleitung-beenden-design.md
-- Idempotent: safe to replay.

ALTER TABLE public.trainer_client_relationships
  ADD COLUMN IF NOT EXISTS ended_by_client_at       timestamptz,
  ADD COLUMN IF NOT EXISTS end_notification_sent_at timestamptz;

COMMENT ON COLUMN public.trainer_client_relationships.ended_by_client_at IS
  'Set when the client deliberately ended or switched away. Blocks automatic '
  'resurrection by ensure_trainer_client_relationship(). Cleared pair-wide by '
  'accept_invite().';
COMMENT ON COLUMN public.trainer_client_relationships.end_notification_sent_at IS
  'Atomic claim for notify-accompaniment-ended. At-most-once by design.';

CREATE OR REPLACE FUNCTION public.end_trainer_relationship(p_trainer_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  v_client uuid := auth.uid();
  v_relationship_id uuid;
BEGIN
  IF v_client IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  -- The caller must be the CLIENT of the relationship being ended.
  SELECT id
    INTO v_relationship_id
    FROM public.trainer_client_relationships
   WHERE trainer_id = p_trainer_id
     AND client_id  = v_client
     AND status     = 'active'
   LIMIT 1;

  IF v_relationship_id IS NULL THEN
    RAISE EXCEPTION 'Keine aktive Begleitung mit diesem Trainer';
  END IF;

  -- Fires trg_revoke_reflex_shares_on_relationship_end, which revokes the
  -- reflex profile shares. Deliberately not duplicated here.
  UPDATE public.trainer_client_relationships
     SET status             = 'disconnected',
         ended_by_client_at = now()
   WHERE id = v_relationship_id;

  -- Every open appointment, regardless of date: a past unresolved proposal
  -- would otherwise linger as a zombie.
  UPDATE public.appointments
     SET status     = 'cancelled',
         updated_at = now()
   WHERE trainer_id = p_trainer_id
     AND trainee_id = v_client
     AND status IN ('proposed', 'planned', 'confirmed');
END;
$function$;

REVOKE ALL ON FUNCTION public.end_trainer_relationship(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.end_trainer_relationship(uuid) TO authenticated;
```

- [ ] **Step 4: Apply and re-run the test**

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres -v ON_ERROR_STOP=1 < supabase/migrations/2026082102_relationship_end_lifecycle.sql
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026082102_relationship_end_lifecycle_test.sql 2>&1 | grep -E "^ (not ok|ok) [0-9]+|Looks like"
```

Expected: all assertions `ok`, no `Looks like you failed` line.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/2026082102_relationship_end_lifecycle.sql supabase/tests/2026082102_relationship_end_lifecycle_test.sql
git diff --cached --name-status
git commit -m "feat(db): add end_trainer_relationship RPC and client-end markers"
```

---

## Task 2: Stop the resurrection

**Files:**
- Modify: `supabase/migrations/2026082102_relationship_end_lifecycle.sql` (append)
- Modify: `supabase/tests/2026082102_relationship_end_lifecycle_test.sql` (append before `SELECT * FROM finish();`)

**Interfaces:**
- Consumes: `ended_by_client_at` from Task 1.
- Produces: `public.ensure_trainer_client_relationship(p_client_id uuid) RETURNS uuid` with the branch order defined in spec §4.1. Returns `NULL` when the pair carries a client-end marker.

- [ ] **Step 1: Write the failing test**

Insert before `SELECT * FROM finish();`:

```sql
-- ── Resurrection guard ─────────────────────────────────────────────────────
-- The relationship from Task 1 is disconnected and marked. A reconcile run by
-- the trainer must not bring it back, and must not create a replacement row.

SELECT set_config('request.jwt.claims',
  '{"sub":"2b100000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.ensure_trainer_client_relationship('2b100000-0000-4000-8000-000000000003'),
  NULL,
  'ensure() refuses to resurrect a client-ended relationship'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

SELECT is(
  (SELECT count(*)::integer FROM public.trainer_client_relationships
    WHERE trainer_id='2b100000-0000-4000-8000-000000000001'
      AND client_id ='2b100000-0000-4000-8000-000000000003'),
  1,
  'no replacement row was inserted under a new id'
);
SELECT is(
  (SELECT count(*)::integer FROM public.trainer_client_relationships
    WHERE trainer_id='2b100000-0000-4000-8000-000000000001'
      AND client_id ='2b100000-0000-4000-8000-000000000003'
      AND status='active'),
  0,
  'the pair has no active relationship after the reconcile attempt'
);

-- An active relationship still wins over a stale marker on another row.
INSERT INTO public.trainer_client_relationships
  (id, trainer_id, client_id, status, linked_at, ended_by_client_at)
VALUES ('2b300000-0000-4000-8000-000000000009',
        '2b100000-0000-4000-8000-000000000002',
        '2b100000-0000-4000-8000-000000000003',
        'disconnected', now() - interval '10 days', now() - interval '10 days');
INSERT INTO public.trainer_client_relationships
  (id, trainer_id, client_id, status, linked_at)
VALUES ('2b300000-0000-4000-8000-000000000010',
        '2b100000-0000-4000-8000-000000000002',
        '2b100000-0000-4000-8000-000000000003', 'active', now());

SELECT set_config('request.jwt.claims',
  '{"sub":"2b100000-0000-4000-8000-000000000002","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.ensure_trainer_client_relationship('2b100000-0000-4000-8000-000000000003'),
  '2b300000-0000-4000-8000-000000000010'::uuid,
  'an active row is returned even when another row of the pair is marked'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

DELETE FROM public.trainer_client_relationships
 WHERE id IN ('2b300000-0000-4000-8000-000000000009',
              '2b300000-0000-4000-8000-000000000010');
```

- [ ] **Step 2: Run the test and confirm the new assertions fail**

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026082102_relationship_end_lifecycle_test.sql 2>&1 | grep -E "^ not ok"
```

Expected: `ensure() refuses to resurrect…` fails (it returns a uuid, having reactivated the row) and the two follow-up count assertions fail with it.

- [ ] **Step 3: Replace the function**

Append to `2026082102_relationship_end_lifecycle.sql`. Note the branch order — active check **before** the marker guard, and an early `RETURN NULL` so control never reaches the `INSERT`:

```sql
CREATE OR REPLACE FUNCTION public.ensure_trainer_client_relationship(p_client_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  v_trainer_id uuid := auth.uid();
  v_relationship_id uuid;
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
     WHERE id = v_trainer_id AND role = 'trainer'
  ) THEN
    RAISE EXCEPTION 'Nur Trainer koennen Klienten verknuepfen';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_client_id) THEN
    RAISE EXCEPTION 'Klient nicht gefunden';
  END IF;

  -- 2. An active row is the ground truth and wins over any stale marker.
  SELECT id INTO v_relationship_id
    FROM public.trainer_client_relationships
   WHERE trainer_id = v_trainer_id
     AND client_id  = p_client_id
     AND status     = 'active'
   LIMIT 1;

  IF v_relationship_id IS NOT NULL THEN
    RETURN v_relationship_id;
  END IF;

  -- 3. Pair-wide guard. Early RETURN NULL: merely skipping branch 4 would fall
  --    through to the INSERT and recreate the relationship under a new id.
  IF EXISTS (
    SELECT 1 FROM public.trainer_client_relationships
     WHERE trainer_id = v_trainer_id
       AND client_id  = p_client_id
       AND ended_by_client_at IS NOT NULL
  ) THEN
    RETURN NULL;
  END IF;

  -- 4. Reuse the canonical disconnected row. Ordering must match accept_invite.
  SELECT id INTO v_relationship_id
    FROM public.trainer_client_relationships
   WHERE trainer_id = v_trainer_id
     AND client_id  = p_client_id
     AND status     = 'disconnected'
   ORDER BY linked_at DESC NULLS LAST, created_at DESC, id DESC
   LIMIT 1;

  IF v_relationship_id IS NOT NULL THEN
    UPDATE public.trainer_client_relationships
       SET status    = 'active',
           linked_at = COALESCE(linked_at, now())
     WHERE id = v_relationship_id;
    RETURN v_relationship_id;
  END IF;

  -- 5. First contact.
  INSERT INTO public.trainer_client_relationships
    (trainer_id, client_id, status, linked_at)
  VALUES (v_trainer_id, p_client_id, 'active', now())
  RETURNING id INTO v_relationship_id;

  RETURN v_relationship_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.ensure_trainer_client_relationship(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ensure_trainer_client_relationship(uuid)
  TO authenticated;
```

- [ ] **Step 4: Apply and re-run**

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres -v ON_ERROR_STOP=1 < supabase/migrations/2026082102_relationship_end_lifecycle.sql
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026082102_relationship_end_lifecycle_test.sql 2>&1 | grep -E "^ (not ok|ok) [0-9]+|Looks like"
```

Expected: every assertion `ok`.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/2026082102_relationship_end_lifecycle.sql supabase/tests/2026082102_relationship_end_lifecycle_test.sql
git diff --cached --name-status
git commit -m "fix(db): stop reconcile from resurrecting a client-ended relationship"
```

---

## Task 3: Make trainer switching mark the displaced relationship

**Files:**
- Modify: `supabase/migrations/2026082102_relationship_end_lifecycle.sql` (append)
- Modify: `supabase/tests/2026082102_relationship_end_lifecycle_test.sql` (append before `finish()`)

**Interfaces:**
- Consumes: both marker columns; the canonical ordering from Task 2.
- Produces: `public.accept_invite(p_code text) RETURNS void` that marks displaced rows and clears both markers pair-wide.

- [ ] **Step 1: Write the failing test**

Insert before `SELECT * FROM finish();`:

```sql
-- ── Switching marks the displaced trainer, and re-linking clears markers ────

INSERT INTO public.trainer_client_relationships
  (id, trainer_id, client_id, status, linked_at)
VALUES ('2b300000-0000-4000-8000-000000000020',
        '2b100000-0000-4000-8000-000000000001',
        '2b100000-0000-4000-8000-000000000004', 'active', now());

INSERT INTO public.trainer_client_relationships
  (id, trainer_id, client_id, status, invite_code)
VALUES ('2b300000-0000-4000-8000-000000000021',
        '2b100000-0000-4000-8000-000000000002', NULL, 'pending', 'BBCODE01');

SELECT set_config('request.jwt.claims',
  '{"sub":"2b100000-0000-4000-8000-000000000004","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT lives_ok(
  $$ SELECT public.accept_invite('BBCODE01') $$,
  'client switches to a new trainer'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

SELECT isnt(
  (SELECT ended_by_client_at FROM public.trainer_client_relationships
    WHERE id='2b300000-0000-4000-8000-000000000020'),
  NULL,
  'switching marks the displaced relationship as client-ended'
);

SELECT set_config('request.jwt.claims',
  '{"sub":"2b100000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.ensure_trainer_client_relationship('2b100000-0000-4000-8000-000000000004'),
  NULL,
  'the displaced trainer cannot reconcile the client back'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

-- Duplicates: two disconnected rows for the same pair, one marked.
-- Re-linking must clear the marker on BOTH, or the pair wedges forever.
INSERT INTO public.trainer_client_relationships
  (id, trainer_id, client_id, status, linked_at, created_at, ended_by_client_at,
   end_notification_sent_at)
VALUES
  ('2b300000-0000-4000-8000-000000000030','2b100000-0000-4000-8000-000000000001',
   '2b100000-0000-4000-8000-000000000003','disconnected',
   now() - interval '5 days', now() - interval '5 days', now(), now()),
  ('2b300000-0000-4000-8000-000000000031','2b100000-0000-4000-8000-000000000001',
   '2b100000-0000-4000-8000-000000000003','disconnected',
   now() - interval '5 days', now() - interval '5 days', now(), NULL);

INSERT INTO public.trainer_client_relationships
  (id, trainer_id, client_id, status, invite_code)
VALUES ('2b300000-0000-4000-8000-000000000032',
        '2b100000-0000-4000-8000-000000000001', NULL, 'pending', 'BBCODE02');

SELECT set_config('request.jwt.claims',
  '{"sub":"2b100000-0000-4000-8000-000000000003","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT lives_ok(
  $$ SELECT public.accept_invite('BBCODE02') $$,
  'client re-links to a former trainer despite duplicate rows'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

SELECT is(
  (SELECT count(*)::integer FROM public.trainer_client_relationships
    WHERE trainer_id='2b100000-0000-4000-8000-000000000001'
      AND client_id ='2b100000-0000-4000-8000-000000000003'
      AND ended_by_client_at IS NOT NULL),
  0,
  'no row of the pair keeps a client-end marker after re-linking'
);
SELECT is(
  (SELECT count(*)::integer FROM public.trainer_client_relationships
    WHERE trainer_id='2b100000-0000-4000-8000-000000000001'
      AND client_id ='2b100000-0000-4000-8000-000000000003'
      AND end_notification_sent_at IS NOT NULL),
  0,
  'the notification claim is cleared too, so a later end can notify again'
);
SELECT is(
  (SELECT count(*)::integer FROM public.trainer_client_relationships
    WHERE trainer_id='2b100000-0000-4000-8000-000000000001'
      AND client_id ='2b100000-0000-4000-8000-000000000003'
      AND status='active'),
  1,
  'exactly one active relationship exists after re-linking'
);
```

- [ ] **Step 2: Run and confirm failure**

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026082102_relationship_end_lifecycle_test.sql 2>&1 | grep -E "^ not ok"
```

Expected: `switching marks the displaced relationship…` fails, and the duplicate-clearing assertions fail.

- [ ] **Step 3: Replace `accept_invite`**

Append to `2026082102_relationship_end_lifecycle.sql`:

```sql
CREATE OR REPLACE FUNCTION public.accept_invite(p_code text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  _invite public.trainer_client_relationships%rowtype;
  _client uuid := auth.uid();
  _exist  uuid;
BEGIN
  IF _client IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  SELECT * INTO _invite
    FROM public.trainer_client_relationships
   WHERE invite_code = upper(trim(p_code))
     AND status      = 'pending'
     AND client_id IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or already used invite code';
  END IF;

  -- Displacing a trainer is as deliberate an act as ending one, so it marks.
  -- Also fires the reflex-share revoke trigger for each displaced pair.
  UPDATE public.trainer_client_relationships
     SET status             = 'disconnected',
         ended_by_client_at = COALESCE(ended_by_client_at, now())
   WHERE client_id = _client
     AND status    = 'active';

  -- Clear markers PAIR-WIDE for the incoming trainer. Clearing only the row
  -- selected below would leave a second marked row behind, and the pair-wide
  -- guard in ensure_trainer_client_relationship() would then wedge the pair
  -- out of reconciliation permanently.
  UPDATE public.trainer_client_relationships
     SET ended_by_client_at       = NULL,
         end_notification_sent_at = NULL
   WHERE trainer_id = _invite.trainer_id
     AND client_id  = _client;

  -- Canonical row selection. Ordering must match ensure_trainer_client_relationship.
  SELECT id INTO _exist
    FROM public.trainer_client_relationships
   WHERE trainer_id = _invite.trainer_id
     AND client_id  = _client
     AND status     = 'disconnected'
   ORDER BY linked_at DESC NULLS LAST, created_at DESC, id DESC
   LIMIT 1;

  IF _exist IS NOT NULL THEN
    UPDATE public.trainer_client_relationships
       SET status = 'active', linked_at = now()
     WHERE id = _exist;

    DELETE FROM public.trainer_client_relationships WHERE id = _invite.id;
  ELSE
    UPDATE public.trainer_client_relationships
       SET client_id = _client,
           status    = 'active',
           linked_at = now()
     WHERE id = _invite.id;
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION public.accept_invite(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_invite(text) TO authenticated;
```

- [ ] **Step 4: Apply, re-run, and replay from scratch**

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres -v ON_ERROR_STOP=1 < supabase/migrations/2026082102_relationship_end_lifecycle.sql
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026082102_relationship_end_lifecycle_test.sql 2>&1 | grep -E "^ (not ok|ok) [0-9]+|Looks like"
```

Then a clean replay (see the environment note about temporarily moving `2026072301_moro_content_snapshot_v1.sql` aside):

```bash
supabase db reset --local
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026082102_relationship_end_lifecycle_test.sql 2>&1 | grep -E "Looks like|^ 1\.\."
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026082101_reflex_share_revocation_test.sql 2>&1 | grep -E "Looks like|^ 1\.\."
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026071901_multi_grant_entitlements_test.sql 2>&1 | grep -E "Looks like|^ 1\.\."
```

Expected: all three suites report their plan line and no `Looks like you failed`. The 2026082101 suite (10 tests) and 2026071901 suite (95 tests) must still pass — this task changes functions they exercise indirectly.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/2026082102_relationship_end_lifecycle.sql supabase/tests/2026082102_relationship_end_lifecycle_test.sql
git diff --cached --name-status
git commit -m "fix(db): mark displaced relationships on trainer switch and clear markers pair-wide"
```

---

## Task 4: Direct-channel chat writes require an active relationship

**Files:**
- Create: `supabase/migrations/2026082103_direct_chat_write_requires_relationship.sql`
- Modify: `lib/features/chat/presentation/providers/chat_providers.dart` (Task 8)
- Create: `supabase/tests/2026082103_direct_chat_write_test.sql`

**Interfaces:**
- Consumes: nothing from Tasks 1–3 at the SQL level; it reads `trainer_client_relationships.status` only.
- Produces: replaced policy `messages_insert_member` on `public.chat_messages`.

- [ ] **Step 1: Check for legitimate writers without an active relationship**

Before changing the policy, confirm no shipped flow writes into a `direct` channel without an active relationship — a pending discovery request, for example. Run against the **local** database:

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres -X -q -c "
SELECT c.type, count(*) AS channels
  FROM public.chat_channels c
 GROUP BY c.type;"
```

Then read `lib/features/accompaniment/presentation/screens/accompaniment_screen.dart` around `_PendingRequestCard` and `openDirectChatWithUser`, and confirm chat is only offered for `activeConnection`. If you find a flow that legitimately messages a *pending* trainer, **stop and report it** — the policy would need `status IN ('active','pending')` and the spec needs amending. Do not silently widen the policy.

- [ ] **Step 2: Write the failing test**

Create `supabase/tests/2026082103_direct_chat_write_test.sql`:

```sql
BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path = public, extensions;

SELECT no_plan();

SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

INSERT INTO auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
)
SELECT
  '00000000-0000-0000-0000-000000000000'::uuid, f.id, 'authenticated',
  'authenticated', f.email, '', now(),
  '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb,
  now(), now(), '', '', '', ''
FROM (VALUES
  ('2c100000-0000-4000-8000-000000000001'::uuid, 'cc-x@example.invalid'),
  ('2c100000-0000-4000-8000-000000000002'::uuid, 'cc-y@example.invalid'),
  ('2c100000-0000-4000-8000-000000000003'::uuid, 'cc-z@example.invalid')
) AS f(id, email)
ON CONFLICT (id) DO NOTHING;

UPDATE public.profiles SET role='trainer'
 WHERE id='2c100000-0000-4000-8000-000000000002';

-- One direct channel with THREE members. The schema allows this: there is no
-- constraint capping direct-channel membership.
INSERT INTO public.chat_channels (id, type)
VALUES ('2c200000-0000-4000-8000-000000000001', 'direct');

INSERT INTO public.chat_channel_members (channel_id, user_id)
VALUES
  ('2c200000-0000-4000-8000-000000000001','2c100000-0000-4000-8000-000000000001'),
  ('2c200000-0000-4000-8000-000000000001','2c100000-0000-4000-8000-000000000002'),
  ('2c200000-0000-4000-8000-000000000001','2c100000-0000-4000-8000-000000000003');

-- Y (trainer) and Z (client) are active. X is related to nobody.
INSERT INTO public.trainer_client_relationships (trainer_id, client_id, status, linked_at)
VALUES ('2c100000-0000-4000-8000-000000000002',
        '2c100000-0000-4000-8000-000000000003', 'active', now());

-- X must NOT be able to write just because Y and Z have a relationship.
SELECT set_config('request.jwt.claims',
  '{"sub":"2c100000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT throws_ok(
  $$ INSERT INTO public.chat_messages (channel_id, sender_id, content)
     VALUES ('2c200000-0000-4000-8000-000000000001',
             '2c100000-0000-4000-8000-000000000001','hallo') $$,
  '42501',
  NULL,
  'an unrelated third member cannot write into a direct channel'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

-- Counter-case: Y still can, or the test above would pass for the wrong reason.
SELECT set_config('request.jwt.claims',
  '{"sub":"2c100000-0000-4000-8000-000000000002","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT lives_ok(
  $$ INSERT INTO public.chat_messages (channel_id, sender_id, content)
     VALUES ('2c200000-0000-4000-8000-000000000001',
             '2c100000-0000-4000-8000-000000000002','hallo') $$,
  'a trainer with an active relationship to another member can write'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

-- End the relationship: both sides lose write, both keep read (BB-5, BB-1).
UPDATE public.trainer_client_relationships
   SET status='disconnected'
 WHERE trainer_id='2c100000-0000-4000-8000-000000000002'
   AND client_id ='2c100000-0000-4000-8000-000000000003';

SELECT set_config('request.jwt.claims',
  '{"sub":"2c100000-0000-4000-8000-000000000002","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT throws_ok(
  $$ INSERT INTO public.chat_messages (channel_id, sender_id, content)
     VALUES ('2c200000-0000-4000-8000-000000000001',
             '2c100000-0000-4000-8000-000000000002','nochmal') $$,
  '42501',
  NULL,
  'the former trainer cannot write after the relationship ends'
);
SELECT cmp_ok(
  (SELECT count(*) FROM public.chat_messages
    WHERE channel_id='2c200000-0000-4000-8000-000000000001'),
  '>', 0::bigint,
  'the former trainer can still read the existing history'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

SELECT set_config('request.jwt.claims',
  '{"sub":"2c100000-0000-4000-8000-000000000003","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT throws_ok(
  $$ INSERT INTO public.chat_messages (channel_id, sender_id, content)
     VALUES ('2c200000-0000-4000-8000-000000000001',
             '2c100000-0000-4000-8000-000000000003','hallo?') $$,
  '42501',
  NULL,
  'the client cannot write either — the lock is symmetric'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

-- Community channels are unaffected.
INSERT INTO public.reflex_packages (id, title_de, title_en)
VALUES ('cc-pkg','Testpaket','Test package')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.chat_channels (id, type, package_id)
VALUES ('2c200000-0000-4000-8000-000000000002','community','cc-pkg');
INSERT INTO public.chat_channel_members (channel_id, user_id)
VALUES ('2c200000-0000-4000-8000-000000000002','2c100000-0000-4000-8000-000000000001');

SELECT set_config('request.jwt.claims',
  '{"sub":"2c100000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT lives_ok(
  $$ INSERT INTO public.chat_messages (channel_id, sender_id, content)
     VALUES ('2c200000-0000-4000-8000-000000000002',
             '2c100000-0000-4000-8000-000000000001','community hallo') $$,
  'community channels keep working without any relationship'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
```

If the `reflex_packages` insert fails because the column names differ, run
`\d public.reflex_packages` and adjust the fixture — do not weaken the assertions.

- [ ] **Step 3: Run and confirm failure**

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026082103_direct_chat_write_test.sql 2>&1 | grep -E "^ not ok"
```

Expected: the three-member case, the former-trainer case and the symmetric-client case all fail — today any member may write.

- [ ] **Step 4: Write the migration**

Create `supabase/migrations/2026082103_direct_chat_write_requires_relationship.sql`:

```sql
-- Direct-channel chat writes require an ACTIVE trainer-client relationship.
-- Reading is deliberately untouched: both sides keep their history.
-- Spec: docs/superpowers/specs/2026-08-21-begleitung-beenden-design.md §4.3
-- Idempotent: safe to replay.

-- The whole predicate lives in ONE SECURITY DEFINER function, used by both the
-- policy and the UI.
--
-- It cannot be written inline in the policy. RLS applies to subqueries inside a
-- policy expression too, and members_select_own is `user_id = auth.uid()`, so
-- the sender sees ONLY THEIR OWN row in chat_channel_members. An inline
-- `EXISTS (… JOIN chat_channel_members other … WHERE other.user_id <> auth.uid())`
-- therefore always matches zero rows and denies every direct-channel write,
-- even with a perfectly valid active relationship. Verified locally on
-- 2026-08-21: other_members_visible_to_sender = 0 while the definer function
-- returns true for the same actor and channel.
--
-- Named can_write_chat_channel, not …_direct_channel: after the delegation it
-- decides for EVERY channel type, not only direct ones.
CREATE OR REPLACE FUNCTION public.can_write_chat_channel(p_channel_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
  SELECT
    EXISTS (
      SELECT 1 FROM public.chat_channel_members m
       WHERE m.channel_id = p_channel_id AND m.user_id = auth.uid()
    )
    AND (
      NOT EXISTS (
        SELECT 1 FROM public.chat_channels c
         WHERE c.id = p_channel_id AND c.type = 'direct'
      )
      OR EXISTS (
        SELECT 1
          FROM public.chat_channel_members other
          JOIN public.trainer_client_relationships r
            ON r.status = 'active'
           AND (
                (r.trainer_id = auth.uid() AND r.client_id  = other.user_id)
             OR (r.client_id  = auth.uid() AND r.trainer_id = other.user_id)
           )
         WHERE other.channel_id = p_channel_id
           AND other.user_id   <> auth.uid()
      )
    );
$function$;

REVOKE ALL ON FUNCTION public.can_write_chat_channel(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_write_chat_channel(uuid) TO authenticated;

DROP POLICY IF EXISTS messages_insert_member ON public.chat_messages;
CREATE POLICY messages_insert_member ON public.chat_messages
  FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    -- Deliberately redundant with the function's own first check: this is the
    -- one clause the sender CAN evaluate under RLS, so the definer function is
    -- not the sole gate.
    AND EXISTS (
      SELECT 1
        FROM public.chat_channel_members m
       WHERE m.channel_id = chat_messages.channel_id
         AND m.user_id    = auth.uid()
    )
    AND public.can_write_chat_channel(chat_messages.channel_id)
  );
```

Both shapes were verified on the local database on 2026-08-21: with the
delegating policy a trainer holding an active relationship inserts successfully,
while an unrelated third member of the same channel is still rejected with
`new row violates row-level security policy`.

Add these assertions to `2026082103_direct_chat_write_test.sql`, each immediately
after the corresponding `throws_ok`/`lives_ok` for the same actor and state.

**These are unit tests of the function, not proof that the policy works.** Since
the policy now calls the same function, an assertion that the two "agree" is
tautological. The real gate tests are the `INSERT` attempts — keep those
assertions exactly as written and never relax one to make a run go green:

```sql
-- as X, three-member channel, unrelated
SELECT is(
  public.can_write_chat_channel('2c200000-0000-4000-8000-000000000001'),
  false,
  'function: unrelated third member is not allowed to write'
);

-- as Y, while the relationship is active
SELECT is(
  public.can_write_chat_channel('2c200000-0000-4000-8000-000000000001'),
  true,
  'function: active trainer is allowed to write'
);

-- as Y, after the relationship ended
SELECT is(
  public.can_write_chat_channel('2c200000-0000-4000-8000-000000000001'),
  false,
  'function: former trainer is not allowed to write'
);

-- as X, community channel
SELECT is(
  public.can_write_chat_channel('2c200000-0000-4000-8000-000000000002'),
  true,
  'function: community channels stay writable'
);
```

- [ ] **Step 5: Apply and re-run**

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres -v ON_ERROR_STOP=1 < supabase/migrations/2026082103_direct_chat_write_requires_relationship.sql
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026082103_direct_chat_write_test.sql 2>&1 | grep -E "^ (not ok|ok) [0-9]+|Looks like"
```

Expected: every assertion `ok`.

- [ ] **Step 6: Commit**

```bash
git add supabase/migrations/2026082103_direct_chat_write_requires_relationship.sql supabase/tests/2026082103_direct_chat_write_test.sql
git diff --cached --name-status
git commit -m "fix(security): require an active relationship to write in a direct channel"
```

---

## Task 5: `notify-accompaniment-ended` Edge Function

**Files:**
- Modify: `supabase/functions/_shared/notification_copy.ts`
- Create: `supabase/functions/notify-accompaniment-ended/index.ts`

**Interfaces:**
- Consumes: `end_notification_sent_at` and `ended_by_client_at` from Task 1.
- Produces: `buildAccompanimentEndedCopy(locale: SupportedLocale, clientLabel: string): NotificationCopy`; an HTTP endpoint taking `{ relationship_id: string }`.

**Not deployed.** This task writes and type-checks the function only.

- [ ] **Step 1: Add the copy builder**

Append to `supabase/functions/_shared/notification_copy.ts`:

```ts
export function buildAccompanimentEndedCopy(
  locale: SupportedLocale,
  clientLabel: string,
): NotificationCopy {
  if (locale === 'en') {
    return {
      title: 'Accompaniment ended',
      body: `${clientLabel} has ended the accompaniment.`,
    };
  }
  return {
    title: 'Begleitung beendet',
    body: `${clientLabel} hat die Begleitung beendet.`,
  };
}
```

Open the file first and confirm `NotificationCopy` has exactly the fields `title` and `body`; if it carries more, fill them the way `buildAppointmentConfirmedCopy` does.

- [ ] **Step 2: Write the function**

Create `supabase/functions/notify-accompaniment-ended/index.ts`:

```ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import {
  buildAccompanimentEndedCopy,
  buildDefaultClientLabel,
  normalizeSupportedLocale,
} from '../_shared/notification_copy.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return json({ error: 'Missing Authorization header' }, 401);

    const { relationship_id } = await req.json();
    if (!relationship_id) return json({ error: 'Missing relationship_id' }, 400);

    const serviceClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const jwt = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await serviceClient.auth.getUser(jwt);
    if (userError || !user) return json({ error: 'Unauthorized' }, 401);

    // Atomic claim. Authorization alone is not enough: the RPC has already
    // committed, so the caller stays a valid client of the ended relationship
    // indefinitely and could otherwise loop this endpoint to spam the trainer.
    // Zero rows updated means somebody already claimed it.
    const { data: claimed, error: claimError } = await serviceClient
      .from('trainer_client_relationships')
      .update({ end_notification_sent_at: new Date().toISOString() })
      .eq('id', relationship_id)
      .eq('client_id', user.id)
      .not('ended_by_client_at', 'is', null)
      .is('end_notification_sent_at', null)
      .select('trainer_id, client_id')
      .maybeSingle();

    if (claimError) throw claimError;
    if (!claimed) return json({ sent: 0, skipped: 'already_sent' });

    const { data: tokens, error: tokenError } = await serviceClient
      .from('device_tokens')
      .select('token')
      .eq('user_id', claimed.trainer_id)
      .eq('enabled', true)
      .is('revoked_at', null);

    if (tokenError) throw tokenError;
    if (!tokens || tokens.length === 0) return json({ sent: 0, skipped: 'no_tokens' });

    const { data: trainerProfile } = await serviceClient
      .from('profiles')
      .select('locale')
      .eq('id', claimed.trainer_id)
      .maybeSingle();

    const { data: clientProfile } = await serviceClient
      .from('profiles')
      .select('display_name')
      .eq('id', claimed.client_id)
      .maybeSingle();

    const locale = normalizeSupportedLocale(trainerProfile?.locale);
    const clientLabel =
      (clientProfile?.display_name as string | null)?.trim() ||
      buildDefaultClientLabel(locale);
    const copy = buildAccompanimentEndedCopy(locale, clientLabel);

    const accessToken = await getFirebaseAccessToken();
    let sent = 0;
    for (const { token } of tokens as Array<{ token: string }>) {
      const ok = await sendFcmMessage(accessToken, token, {
        type: 'accompaniment_ended',
        relationship_id: relationship_id,
        client_name: clientLabel,
      }, copy);
      if (ok) sent += 1;
    }

    return json({ sent });
  } catch (err) {
    console.error('notify-accompaniment-ended error:', err);
    return json({ error: String(err) }, 500);
  }
});
```

The three helpers `getFirebaseAccessToken`, `importPrivateKey` and
`sendFcmMessage`, plus the `json` helper, are **identical** to the ones at the
bottom of `supabase/functions/notify-appointment-confirmed/index.ts`. Copy those
four function bodies verbatim into this file — do not rewrite them, and do not
change the FCM payload shape. They also require these two additional imports and
two constants at the top of the file:

```ts
import { create, getNumericDate } from 'https://deno.land/x/djwt@v2.8/mod.ts';
import type { NotificationCopy } from '../_shared/notification_copy.ts';

const FIREBASE_SERVICE_ACCOUNT_JSON = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON') ?? '';
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID') ?? 'corejourney-prod';
```

`profiles.locale` is confirmed to exist and is what
`notify-appointment-confirmed` reads, so the `trainerProfile` lookup above is
correct as written.

- [ ] **Step 3: Type-check**

```bash
cd supabase/functions && deno check notify-accompaniment-ended/index.ts _shared/notification_copy.ts
```

Expected: no errors.

- [ ] **Step 4: Add the concurrency test**

Append to `supabase/tests/2026082102_relationship_end_lifecycle_test.sql`, before `finish()`. This exercises the same claim predicate the function uses:

```sql
-- ── Notification claim is single-shot ───────────────────────────────────────

INSERT INTO public.trainer_client_relationships
  (id, trainer_id, client_id, status, linked_at, ended_by_client_at)
VALUES ('2b300000-0000-4000-8000-000000000040',
        '2b100000-0000-4000-8000-000000000002',
        '2b100000-0000-4000-8000-000000000004',
        'disconnected', now(), now());

SELECT is(
  (WITH claim AS (
     UPDATE public.trainer_client_relationships
        SET end_notification_sent_at = now()
      WHERE id = '2b300000-0000-4000-8000-000000000040'
        AND ended_by_client_at       IS NOT NULL
        AND end_notification_sent_at IS NULL
      RETURNING id
   ) SELECT count(*)::integer FROM claim),
  1,
  'the first claim succeeds'
);

SELECT is(
  (WITH claim AS (
     UPDATE public.trainer_client_relationships
        SET end_notification_sent_at = now()
      WHERE id = '2b300000-0000-4000-8000-000000000040'
        AND ended_by_client_at       IS NOT NULL
        AND end_notification_sent_at IS NULL
      RETURNING id
   ) SELECT count(*)::integer FROM claim),
  0,
  'a replayed call claims nothing and therefore sends nothing'
);
```

- [ ] **Step 5: Run the suite**

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026082102_relationship_end_lifecycle_test.sql 2>&1 | grep -E "^ (not ok|ok) [0-9]+|Looks like"
```

Expected: every assertion `ok`.

- [ ] **Step 6: Commit**

```bash
git add supabase/functions/_shared/notification_copy.ts supabase/functions/notify-accompaniment-ended/index.ts supabase/tests/2026082102_relationship_end_lifecycle_test.sql
git diff --cached --name-status
git commit -m "feat(notify): add idempotent accompaniment-ended trainer notification"
```

---

## Task 6: Dart provider call and localized copy

**Files:**
- Modify: `lib/features/trainer/presentation/providers/trainer_provider.dart`
- Modify: `lib/l10n/app_de.arb`, `lib/l10n/app_en.arb`

**Interfaces:**
- Consumes: the `end_trainer_relationship` RPC from Task 1; the Edge Function from Task 5.
- Produces: `Future<void> endTrainerRelationship(WidgetRef ref, {required String trainerId, required String relationshipId})` — top-level function in `trainer_provider.dart`, matching the existing style of `grantReflexProfileTrainerShare`.

- [ ] **Step 1: Add the l10n keys**

Add to **both** `lib/l10n/app_de.arb` and `lib/l10n/app_en.arb`. German first:

```json
"accompanimentEndAction": "Begleitung beenden",
"accompanimentEndDialogTitle": "Begleitung wirklich beenden?",
"accompanimentEndConsequenceProfiles": "Dein Trainer kann deine Reflexprofile nicht mehr sehen.",
"accompanimentEndConsequenceChat": "Ihr könnt euch keine Nachrichten mehr schreiben. Euer bisheriger Verlauf bleibt erhalten.",
"accompanimentEndConsequenceAppointments": "Alle offenen Termine werden abgesagt.",
"accompanimentEndTrainerNotice": "Dein Trainer wird darüber informiert.",
"accompanimentEndReconnectHint": "Du kannst dich später mit einem neuen Code wieder verbinden.",
"accompanimentEndConfirm": "Begleitung beenden",
"accompanimentEnded": "Begleitung beendet.",
"accompanimentEndFailed": "Begleitung konnte nicht beendet werden: {error}",
"@accompanimentEndFailed": {
  "placeholders": { "error": { "type": "String" } }
},
"chatWriteLockedNoRelationship": "Diese Begleitung ist beendet. Du kannst den Verlauf weiter lesen, aber keine Nachrichten mehr senden."
```

English:

```json
"accompanimentEndAction": "End accompaniment",
"accompanimentEndDialogTitle": "Really end this accompaniment?",
"accompanimentEndConsequenceProfiles": "Your trainer will no longer see your reflex profiles.",
"accompanimentEndConsequenceChat": "You will no longer be able to message each other. Your existing history stays.",
"accompanimentEndConsequenceAppointments": "All open appointments will be cancelled.",
"accompanimentEndTrainerNotice": "Your trainer will be informed.",
"accompanimentEndReconnectHint": "You can connect again later with a new code.",
"accompanimentEndConfirm": "End accompaniment",
"accompanimentEnded": "Accompaniment ended.",
"accompanimentEndFailed": "Couldn't end the accompaniment: {error}",
"@accompanimentEndFailed": {
  "placeholders": { "error": { "type": "String" } }
},
"chatWriteLockedNoRelationship": "This accompaniment has ended. You can still read the history, but you can no longer send messages."
```

Reuse the existing `cancel` key ("Abbrechen") for the dialog's dismiss button — do not add a new one.

- [ ] **Step 2: Generate and verify parity**

```bash
flutter gen-l10n
python3 scripts/i18n_check.py
```

Expected: gen-l10n succeeds; the parity check passes. `make i18n-check` additionally runs a quality check that currently fails on three **pre-existing** allowlist keys (`routineMode`, `trainingRoutineSubtitle`, `tutorialMode`) — that failure is not yours; the parity result is what matters.

- [ ] **Step 3: Add the provider function**

Append to `lib/features/trainer/presentation/providers/trainer_provider.dart`, following the file's existing top-level-function style:

```dart
/// Ends the accompaniment with [trainerId] for the signed-in client.
///
/// The RPC disconnects the relationship, marks it as deliberately ended,
/// cancels open appointments, and — through a database trigger — revokes the
/// reflex profile shares. The trainer notification is fire-and-forget: it must
/// never make a successful end look like a failure.
Future<void> endTrainerRelationship(
  WidgetRef ref, {
  required String trainerId,
  required String relationshipId,
}) async {
  final client = Supabase.instance.client;

  await client.rpc(
    'end_trainer_relationship',
    params: {'p_trainer_id': trainerId},
  );

  try {
    await client.functions.invoke(
      'notify-accompaniment-ended',
      body: {'relationship_id': relationshipId},
    );
  } catch (error, stackTrace) {
    appLogger.w(
      'accompaniment-ended notification failed',
      error: error,
      stackTrace: stackTrace,
    );
  }

  ref.invalidate(trainerClientsProvider);
  ref.invalidate(clientTrainerIdProvider);
  ref.invalidate(clientTrainerConnectionsProvider);
}
```

Check the file's existing imports for `appLogger` (`lib/core/logging/`). If it is not imported there, add the import — never `print`.

- [ ] **Step 4: Analyze**

```bash
flutter analyze --no-fatal-infos lib/features/trainer/presentation/providers/trainer_provider.dart
```

Expected: no errors, no warnings.

- [ ] **Step 5: Commit**

```bash
git add lib/features/trainer/presentation/providers/trainer_provider.dart lib/l10n/app_de.arb lib/l10n/app_en.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_de.dart lib/l10n/app_localizations_en.dart
git diff --cached --name-status
git commit -m "feat(accompaniment): add endTrainerRelationship provider call and copy"
```

---

## Task 7: Confirmation dialog and the client entry point

**Files:**
- Create: `lib/features/accompaniment/presentation/widgets/end_accompaniment_dialog.dart`
- Modify: `lib/features/accompaniment/presentation/screens/accompaniment_screen.dart`
- Create: `test/features/accompaniment/end_accompaniment_dialog_test.dart`

**Interfaces:**
- Consumes: `endTrainerRelationship` from Task 6; the l10n keys from Task 6.
- Produces: `Future<bool?> showEndAccompanimentDialog(BuildContext context)` — returns `true` only when the client confirmed.

- [ ] **Step 1: Write the failing widget test**

Create `test/features/accompaniment/end_accompaniment_dialog_test.dart`:

```dart
import 'package:corejourney/features/accompaniment/presentation/widgets/end_accompaniment_dialog.dart';
import 'package:corejourney/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host({required void Function(bool?) onResult}) {
  return MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () async =>
              onResult(await showEndAccompanimentDialog(context)),
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('names all three consequences before confirming',
      (tester) async {
    await tester.pumpWidget(_host(onResult: (_) {}));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Begleitung wirklich beenden?'), findsOneWidget);
    expect(
      find.text('Dein Trainer kann deine Reflexprofile nicht mehr sehen.'),
      findsOneWidget,
    );
    expect(find.textContaining('keine Nachrichten mehr schreiben'),
        findsOneWidget);
    expect(find.text('Alle offenen Termine werden abgesagt.'), findsOneWidget);
    expect(find.text('Dein Trainer wird darüber informiert.'), findsOneWidget);
  });

  testWidgets('cancelling returns a non-confirming result', (tester) async {
    bool? result = true;
    await tester.pumpWidget(_host(onResult: (value) => result = value));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abbrechen'));
    await tester.pumpAndSettle();

    expect(result, isNot(true));
  });

  testWidgets('confirming returns true', (tester) async {
    bool? result;
    await tester.pumpWidget(_host(onResult: (value) => result = value));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('end_accompaniment_confirm')));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
```

- [ ] **Step 2: Run and confirm it fails**

```bash
flutter test test/features/accompaniment/end_accompaniment_dialog_test.dart
```

Expected: compile failure — `end_accompaniment_dialog.dart` does not exist.

- [ ] **Step 3: Write the dialog**

Create `lib/features/accompaniment/presentation/widgets/end_accompaniment_dialog.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';

/// Asks the client to confirm ending the accompaniment.
///
/// Returns `true` only on an explicit confirmation. Every consequence is named
/// in the body: the dialog is the only place the client learns that reflex
/// profile access, messaging and open appointments all end at once.
Future<bool?> showEndAccompanimentDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);

  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final cs = Theme.of(dialogContext).colorScheme;

      return AlertDialog(
        title: Text(l10n.accompanimentEndDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Consequence(text: l10n.accompanimentEndConsequenceProfiles),
            _Consequence(text: l10n.accompanimentEndConsequenceChat),
            _Consequence(text: l10n.accompanimentEndConsequenceAppointments),
            const SizedBox(height: 12),
            Text(
              l10n.accompanimentEndTrainerNotice,
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.accompanimentEndReconnectHint,
              style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            key: const Key('end_accompaniment_confirm'),
            style: FilledButton.styleFrom(backgroundColor: cs.error),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.accompanimentEndConfirm),
          ),
        ],
      );
    },
  );
}

class _Consequence extends StatelessWidget {
  const _Consequence({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.remove_circle_outline, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run the test**

```bash
flutter test test/features/accompaniment/end_accompaniment_dialog_test.dart
```

Expected: all three tests pass.

- [ ] **Step 5: Wire it into the screen**

In `lib/features/accompaniment/presentation/screens/accompaniment_screen.dart`:

Add the import next to the other local imports:

```dart
import '../widgets/end_accompaniment_dialog.dart';
```

Add a parameter to `_ConnectedTrainerCard` — a new field beside `onSwitchWithCode`:

```dart
final VoidCallback onEndAccompaniment;
```

…declared in the constructor as `required this.onEndAccompaniment,`.

In the card's build method, immediately after the `Wrap` holding the *Trainer
finden* and *Code eingeben* buttons, append:

```dart
const SizedBox(height: 4),
Align(
  alignment: Alignment.centerLeft,
  child: TextButton(
    key: const Key('accompaniment_end_action'),
    onPressed: onEndAccompaniment,
    style: TextButton.styleFrom(foregroundColor: cs.error),
    child: Text(l10n.accompanimentEndAction),
  ),
),
```

At the call site (around line 250), add the handler:

```dart
onEndAccompaniment: () => _endAccompaniment(
  context,
  ref,
  trainerId: activeConnection.trainerId,
  relationshipId: activeConnection.relationshipId,
),
```

And add this top-level helper next to `_showSwitchTrainerDialog`:

```dart
Future<void> _endAccompaniment(
  BuildContext context,
  WidgetRef ref, {
  required String trainerId,
  required String relationshipId,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showEndAccompanimentDialog(context);
  if (confirmed != true) return;

  try {
    await endTrainerRelationship(
      ref,
      trainerId: trainerId,
      relationshipId: relationshipId,
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.accompanimentEnded)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accompanimentEndFailed('$e'))),
      );
    }
  }
}
```

The screen already falls back to `_NoTrainerCard` when `hasTrainer` is false, so no new empty state is needed.

- [ ] **Step 6: Analyze and run the full suite**

```bash
make release-readiness-mobile
```

Expected: `flutter analyze --no-fatal-infos` reports 0 errors and 0 warnings; `flutter test` is 100% green.

- [ ] **Step 7: Commit**

```bash
git add lib/features/accompaniment/presentation/widgets/end_accompaniment_dialog.dart lib/features/accompaniment/presentation/screens/accompaniment_screen.dart test/features/accompaniment/end_accompaniment_dialog_test.dart
git diff --cached --name-status
git commit -m "feat(accompaniment): let clients end a trainer accompaniment"
```

---

## Task 8: Locked chat composer

**Files:**
- Modify: `lib/features/chat/presentation/screens/chat_channel_screen.dart`

**Interfaces:**
- Consumes: `public.can_write_chat_channel(uuid)` from Task 4; `chatWriteLockedNoRelationship` from Task 6.
- Produces: `channelWritableProvider` — `FutureProvider.family<bool, String>` keyed by channel id.

Without this, the RLS from Task 4 turns a send into a raw Postgres error behind
a Send button that looks enabled. A gated feature must never leave a dead
control on screen (`docs`-level rule: "The Amputated Screen").

- [ ] **Step 1: Add the provider**

Append to `lib/features/chat/presentation/providers/chat_providers.dart`,
matching the file's existing provider style:

```dart
/// Whether the signed-in user may currently send into [channelId].
///
/// Calls the very predicate `messages_insert_member` delegates to, so the
/// composer and the policy cannot drift apart. The client cannot evaluate it
/// locally: `members_select_own` exposes only the user's own membership row,
/// so the other members of a direct channel are not readable from the app.
final channelWritableProvider =
    FutureProvider.family<bool, String>((ref, channelId) async {
  ref.watch(authStateProvider);
  if (Supabase.instance.client.auth.currentUser == null) return false;

  final result = await Supabase.instance.client.rpc(
    'can_write_chat_channel',
    params: {'p_channel_id': channelId},
  );
  return result == true;
});
```

Check the file's imports for `authStateProvider` and `Supabase`; add whichever
is missing, following the imports already used by neighbouring providers.

- [ ] **Step 2: Replace the composer when writing is locked**

In `lib/features/chat/presentation/screens/chat_channel_screen.dart`, the
`MessageInputBar(...)` mount sits at roughly line 501, directly after
`TypingIndicator(channelId: widget.channelId)`. Replace that mount with:

```dart
if (ref.watch(channelWritableProvider(widget.channelId)).valueOrNull ==
    false)
  Padding(
    padding: const EdgeInsets.all(16),
    child: Text(
      AppLocalizations.of(context).chatWriteLockedNoRelationship,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    ),
  )
else
  MessageInputBar(
    // every existing argument unchanged — channel, onSend,
    // onCallRequest, onTyping
  ),
```

Comparing against `false` rather than `!= true` is deliberate: while the
provider is loading, `valueOrNull` is `null` and the composer stays mounted, so
a slow network shows the normal input rather than flashing a "this has ended"
message at someone whose accompaniment is perfectly alive.

Invalidate it after a successful send failure path is **not** needed — the
provider re-evaluates when the screen rebuilds on `authStateProvider` change.

- [ ] **Step 3: Analyze and test**

```bash
make release-readiness-mobile
```

Expected: 0 errors, 0 warnings, all tests green.

- [ ] **Step 4: Capture before/after screenshots**

The composer is an entry point that disappears, so the "Amputated Screen" rule
applies. Run the app and capture both states:

```bash
make run-sim
```

Save the two screenshots to `docs/evidence/begleitung-beenden/`.

- [ ] **Step 5: Commit**

```bash
git add lib/features/chat/presentation/providers/chat_providers.dart lib/features/chat/presentation/screens/chat_channel_screen.dart docs/evidence/begleitung-beenden/
git diff --cached --name-status
git commit -m "feat(chat): explain the locked composer after an accompaniment ends"
```

---

## Task 9: Dry-run query and evidence

**Files:**
- Create: `docs/evidence/begleitung-beenden/README.md`
- Create: `supabase/snippets/begleitung_beenden_dryrun.sql`

**Interfaces:**
- Consumes: everything above. Produces no code.

- [ ] **Step 1: Write the dry-run query**

Create `supabase/snippets/begleitung_beenden_dryrun.sql`. **Read-only, aggregates
only** — no ids, names or per-user timestamps may leave the database:

```sql
-- Read-only. Counts only. Basis for the BB-6 backfill decision.
SELECT
  count(*) FILTER (
    WHERE EXISTS (
      SELECT 1 FROM public.trainer_client_relationships a
       WHERE a.client_id = r.client_id AND a.status = 'active'
    )
  ) AS likely_switch,
  count(*) FILTER (
    WHERE NOT EXISTS (
      SELECT 1 FROM public.trainer_client_relationships a
       WHERE a.client_id = r.client_id AND a.status = 'active'
    )
  ) AS no_active_trainer,
  count(*) FILTER (
    WHERE EXISTS (
      SELECT 1
        FROM public.chat_channel_members m1
        JOIN public.chat_channels c  ON c.id = m1.channel_id AND c.type = 'direct'
        JOIN public.chat_channel_members m2 ON m2.channel_id = m1.channel_id
       WHERE m1.user_id = r.trainer_id AND m2.user_id = r.client_id
    )
  ) AS resurrectable_chat,
  count(*) FILTER (
    WHERE EXISTS (
      SELECT 1 FROM public.appointments ap
       WHERE ap.trainer_id = r.trainer_id
         AND ap.trainee_id = r.client_id
         AND ap.status IN ('proposed','planned','confirmed')
    )
  ) AS resurrectable_appt,
  count(*) FILTER (
    WHERE (
      SELECT count(*) FROM public.trainer_client_relationships d
       WHERE d.trainer_id = r.trainer_id
         AND d.client_id  = r.client_id
         AND d.status     = 'disconnected'
    ) > 1
  ) AS duplicate_pair,
  count(*) AS total_disconnected
FROM public.trainer_client_relationships r
WHERE r.status = 'disconnected'
  AND r.ended_by_client_at IS NULL;
```

- [ ] **Step 2: Run it against the local database**

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/snippets/begleitung_beenden_dryrun.sql
```

Expected: it executes and returns a single row of zeros on a fresh local
database. The point of this step is to prove the SQL is valid before anyone
runs it anywhere else. **Do not run it against the live project** — that needs a
founder go, and the result belongs in the evidence file as counts only.

- [ ] **Step 3: Write the evidence file**

Create `docs/evidence/begleitung-beenden/README.md` recording, in the format of
`docs/evidence/reflex-share-revocation/README.md`: what was built, the red→green
transition for each pgTAP suite with real counts, the `supabase db reset --local`
result, `make release-readiness-mobile` output, `deno check` result, the
screenshot filenames from Task 8, and an explicit list of what is **not** done:
live apply, function deploy, backfill decision.

Every number must come from output you actually saw. Never write a count or a
"verified" claim before the command has run.

- [ ] **Step 4: Commit**

```bash
git add docs/evidence/begleitung-beenden/README.md supabase/snippets/begleitung_beenden_dryrun.sql
git diff --cached --name-status
git commit -m "docs(evidence): record accompaniment-end verification and backfill dry-run"
```

---

## Task 10: Lock the relationship lifecycle against direct writes

> **Do this immediately after Task 4.** It is numbered 10 only to avoid
> renumbering tasks already in flight; it has no dependency on Tasks 5–9. Until
> it lands, the durability guarantee of Tasks 1–3 is false.

**Files:**
- Create: `supabase/migrations/2026082104_protect_relationship_lifecycle.sql`
- Create: `supabase/tests/2026082104_relationship_lifecycle_protection_test.sql`

**Interfaces:**
- Consumes: the marker columns from Task 1; `end_trainer_relationship` and `accept_invite`.
- Produces: trigger `trg_prevent_direct_relationship_lifecycle_change`.

### Why this task exists

`ended_by_client_at` is not a guarantee, only a value in a table both parties can
write. `authenticated` holds `UPDATE` on every column and `cj: tcr all trainer`
is `FOR ALL`. Three bypasses were proven on the local database on 2026-08-21,
each in a rolled-back transaction:

| As | Action | Result |
|---|---|---|
| Ex-trainer | `UPDATE … SET ended_by_client_at = NULL` | succeeds |
| Ex-trainer | `UPDATE … SET status = 'active'` (marker untouched) | succeeds — **the marker is not even needed** |
| Ex-trainer | `INSERT` a fresh `active` row for the same pair | succeeds — 2 rows, 1 active |
| Client | `UPDATE … SET trainer_id = <other trainer>` | succeeds |

Protecting only the two marker columns would therefore be security theatre: the
second and third rows above never touch them. The protected set must include
`status`, `trainer_id` and `client_id`, and the guard must cover `INSERT` as
well as `UPDATE`.

`trainer_notes` is deliberately **not** protected here. `saveNotes`
(`trainer_provider.dart:58-63`) writes it directly today, and moving that behind
an RPC belongs to the separate finding round
(`docs/SECURITY_FINDING_2026-08-21_relationship_write_access.md`).

### Why `current_user`, not `auth.role()`

The house pattern (`prevent_direct_role_change`, `prevent_direct_premium_change`)
guards with `auth.role() != 'service_role'`. **That pattern does not transfer
here.** Those columns are written by Edge Functions holding the service-role key.
Ours are written by `SECURITY DEFINER` RPCs invoked *by ordinary users*, and the
JWT claim stays `authenticated` inside such a function — so an `auth.role()`
guard would reject `accept_invite()` and `end_trainer_relationship()` too.

Measured on 2026-08-21:

| Context | `current_user` | `auth.role()` |
|---|---|---|
| Inside `SECURITY DEFINER` | `postgres` | `authenticated` |
| Direct REST write | `authenticated` | `authenticated` |

`current_user` separates them; `auth.role()` does not.

Do **not** implement this with a session GUC (`set_config('app.…')`) that the
RPCs set and the trigger checks. `authenticated` may call `set_config` itself, so
an attacker can raise the flag before writing. It looks like a guard and is not.

- [ ] **Step 1: Write the failing test**

Create `supabase/tests/2026082104_relationship_lifecycle_protection_test.sql`.
Use the fixture style of the other suites in this directory (synthetic UUIDs,
`@example.invalid` emails, `BEGIN … ROLLBACK`). Assert, as `authenticated`:

```sql
-- Fixture: trainer T, client C, one disconnected+marked relationship REL,
-- plus a second trainer T2 for the re-point case.

-- 1. the client cannot clear the marker
SELECT throws_ok(
  $$ UPDATE public.trainer_client_relationships
        SET ended_by_client_at = NULL WHERE id = '<REL>' $$,
  NULL, NULL,
  'the client cannot clear the client-end marker directly'
);

-- 2. the former trainer cannot clear the marker
SELECT throws_ok(
  $$ UPDATE public.trainer_client_relationships
        SET ended_by_client_at = NULL WHERE id = '<REL>' $$,
  NULL, NULL,
  'the former trainer cannot clear the client-end marker directly'
);

-- 3. the former trainer cannot flip the status back, marker untouched
SELECT throws_ok(
  $$ UPDATE public.trainer_client_relationships
        SET status = 'active' WHERE id = '<REL>' $$,
  NULL, NULL,
  'the former trainer cannot reactivate the relationship directly'
);

-- 4. the former trainer cannot insert a replacement active row
SELECT throws_ok(
  $$ INSERT INTO public.trainer_client_relationships
       (trainer_id, client_id, status, linked_at)
     VALUES ('<T>', '<C>', 'active', now()) $$,
  NULL, NULL,
  'relationships cannot be created by a direct insert'
);

-- 5. the client cannot re-point the relationship at another trainer
SELECT throws_ok(
  $$ UPDATE public.trainer_client_relationships
        SET trainer_id = '<T2>' WHERE id = '<REL>' $$,
  NULL, NULL,
  'the client cannot re-point the relationship at another trainer'
);

-- 6. the notification claim column is protected too
SELECT throws_ok(
  $$ UPDATE public.trainer_client_relationships
        SET end_notification_sent_at = NULL WHERE id = '<REL>' $$,
  NULL, NULL,
  'the notification claim cannot be reset directly'
);

-- 7. no regression: the trainer can still write notes on an ACTIVE relationship
SELECT lives_ok(
  $$ UPDATE public.trainer_client_relationships
        SET trainer_notes = 'ok' WHERE id = '<ACTIVE_REL>' $$,
  'writing trainer notes directly still works'
);

-- 8+9. no regression: the definer paths still work.
--      Call end_trainer_relationship() on an active pair and accept_invite()
--      with a pending code, both as authenticated, both with lives_ok.
```

- [ ] **Step 2: Run and confirm every negative case fails**

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/2026082104_relationship_lifecycle_protection_test.sql 2>&1 | grep -E "^ not ok"
```

Expected: assertions 1–6 fail — today every one of those writes succeeds. 7–9
should already pass. **If any of 1–6 passes at this stage, stop** — your fixture
is not running as `authenticated` and the suite is proving nothing.

- [ ] **Step 3: Write the migration**

Create `supabase/migrations/2026082104_protect_relationship_lifecycle.sql`:

```sql
-- trainer_client_relationships IS the authorization model: the trainer read
-- policies on enrollments, training_sessions, progress_entries and
-- mood_checkins all test for an active row in it. RLS there is row-level and
-- authenticated holds UPDATE on every column, so without this trigger either
-- party can rewrite the columns that define access.
--
-- Idempotent: safe to replay.

CREATE OR REPLACE FUNCTION public.prevent_direct_relationship_lifecycle_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
BEGIN
  -- current_user, NOT auth.role(). Inside a SECURITY DEFINER RPC current_user
  -- is the function owner while the JWT claim stays 'authenticated', so
  -- auth.role() cannot tell a legitimate accept_invite() call from a direct
  -- REST write and would reject both.
  IF current_user NOT IN ('authenticated', 'anon') THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    RAISE EXCEPTION
      'Relationships are created through accept_invite() only. '
      'Direct inserts are not permitted.';
  END IF;

  IF OLD.status                   IS DISTINCT FROM NEW.status
  OR OLD.trainer_id               IS DISTINCT FROM NEW.trainer_id
  OR OLD.client_id                IS DISTINCT FROM NEW.client_id
  OR OLD.ended_by_client_at       IS DISTINCT FROM NEW.ended_by_client_at
  OR OLD.end_notification_sent_at IS DISTINCT FROM NEW.end_notification_sent_at
  THEN
    RAISE EXCEPTION
      'Changing relationship lifecycle columns directly is not permitted. '
      'Use accept_invite() or end_trainer_relationship().';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.prevent_direct_relationship_lifecycle_change()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_prevent_direct_relationship_lifecycle_change
  ON public.trainer_client_relationships;
CREATE TRIGGER trg_prevent_direct_relationship_lifecycle_change
  BEFORE INSERT OR UPDATE ON public.trainer_client_relationships
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_direct_relationship_lifecycle_change();
```

- [ ] **Step 4: Apply, re-run, and check for regressions across every suite**

```bash
docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres -v ON_ERROR_STOP=1 < supabase/migrations/2026082104_protect_relationship_lifecycle.sql
supabase db reset --local
for t in 2026071901_multi_grant_entitlements_test 2026082101_reflex_share_revocation_test \
         2026082102_relationship_end_lifecycle_test 2026082103_direct_chat_write_test \
         2026082104_relationship_lifecycle_protection_test; do
  echo "== $t"
  docker exec -i supabase_db_reflexjourney psql -U postgres -d postgres < supabase/tests/$t.sql 2>&1 | grep -E "Looks like|^ 1\.\."
done
```

Expected: every suite reports its plan line with no `Looks like you failed`. The
existing suites' fixtures run as `postgres`, so the trigger permits them — if one
of them now fails, that fixture was relying on a write path real users should not
have, and that is worth reporting rather than working around.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/2026082104_protect_relationship_lifecycle.sql supabase/tests/2026082104_relationship_lifecycle_protection_test.sql
git diff --cached --name-status
git commit -m "fix(security): block direct writes to relationship lifecycle columns"
```

---

## Definition of done

- [ ] `supabase db reset --local` replays green including all three new migrations
- [ ] `2026082102`, `2026082103` and `2026082104` suites green
- [ ] `2026082101` (10 tests) and `2026071901` (95 tests) still green — no regression
- [ ] **Task 10 landed** — the client-end marker is enforced by the database, not merely written. Without it the feature's central promise is false.
- [ ] `make release-readiness-mobile` → 0 errors, 0 warnings, 100% tests pass
- [ ] `deno check` clean for the new function
- [ ] Every new string in both `.arb` files; `python3 scripts/i18n_check.py` parity passes
- [ ] Before/after screenshots for the chat composer in `docs/evidence/begleitung-beenden/`
- [ ] Evidence file written from observed output only
- [ ] Nothing applied live; nothing deployed; nothing pushed

## Handover to the founder

Three things need an explicit decision and are deliberately **not** part of this plan:

1. **Live apply** of `2026082101` (already written, still unapplied), `2026082102` and `2026082103`, in that order.
2. **Deploy** of `notify-accompaniment-ended`.
3. **Backfill** of historical `disconnected` rows, based on the §8.1 dry-run counts.

## Related finding — partly closed here

`docs/SECURITY_FINDING_2026-08-21_relationship_write_access.md` (P0) records that
`trainer_client_relationships` is directly writable by both parties.

**Task 10 closes the part that defeats this feature**: status, both markers,
`trainer_id`, `client_id`, and direct inserts. What remains open there and is
*not* addressed by this plan:

- `trainer_notes` is still client-readable and client-writable, and `saveNotes`
  still writes it directly without a status check.
- `cj: tcr update client` still exists with no caller, and `cj: tcr all trainer`
  is still `FOR ALL` rather than `FOR SELECT`. Task 10 neutralises their effect
  on the lifecycle columns; it does not remove them.

Those belong to the separate finding round.
