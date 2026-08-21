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

SELECT * FROM finish();
ROLLBACK;
