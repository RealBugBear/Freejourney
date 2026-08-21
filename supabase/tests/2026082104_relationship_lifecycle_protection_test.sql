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
  ('2e100000-0000-4000-8000-000000000001'::uuid, 'lc-trainer-t@example.invalid'),
  ('2e100000-0000-4000-8000-000000000002'::uuid, 'lc-trainer-t2@example.invalid'),
  ('2e100000-0000-4000-8000-000000000003'::uuid, 'lc-client-c@example.invalid')
) AS f(id, email)
ON CONFLICT (id) DO NOTHING;

UPDATE public.profiles SET role = 'trainer'
 WHERE id IN ('2e100000-0000-4000-8000-000000000001',
              '2e100000-0000-4000-8000-000000000002');

-- REL: disconnected + marked (the ended accompaniment under attack)
INSERT INTO public.trainer_client_relationships
  (id, trainer_id, client_id, status, linked_at,
   ended_by_client_at, end_notification_sent_at)
VALUES ('2e300000-0000-4000-8000-000000000001',
        '2e100000-0000-4000-8000-000000000001',
        '2e100000-0000-4000-8000-000000000003',
        'disconnected', now() - interval '1 day',
        now() - interval '1 day', now() - interval '1 day');

-- ACTIVE_REL: live accompaniment used for the notes regression
INSERT INTO public.trainer_client_relationships
  (id, trainer_id, client_id, status, linked_at)
VALUES ('2e300000-0000-4000-8000-000000000002',
        '2e100000-0000-4000-8000-000000000002',
        '2e100000-0000-4000-8000-000000000003',
        'active', now());

-- Pending invite for the accept_invite regression (after ACTIVE_REL is ended)
INSERT INTO public.trainer_client_relationships
  (id, trainer_id, client_id, status, invite_code)
VALUES ('2e300000-0000-4000-8000-000000000003',
        '2e100000-0000-4000-8000-000000000001',
        NULL, 'pending', 'LCCODE01');

-- 1. the client cannot clear the marker
SELECT set_config('request.jwt.claims',
  '{"sub":"2e100000-0000-4000-8000-000000000003","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT throws_ok(
  $$ UPDATE public.trainer_client_relationships
        SET ended_by_client_at = NULL
      WHERE id = '2e300000-0000-4000-8000-000000000001' $$,
  NULL, NULL,
  'the client cannot clear the client-end marker directly'
);

-- 5. the client cannot re-point the relationship at another trainer
SELECT throws_ok(
  $$ UPDATE public.trainer_client_relationships
        SET trainer_id = '2e100000-0000-4000-8000-000000000002'
      WHERE id = '2e300000-0000-4000-8000-000000000001' $$,
  NULL, NULL,
  'the client cannot re-point the relationship at another trainer'
);

-- 6. the notification claim column is protected too
SELECT throws_ok(
  $$ UPDATE public.trainer_client_relationships
        SET end_notification_sent_at = NULL
      WHERE id = '2e300000-0000-4000-8000-000000000001' $$,
  NULL, NULL,
  'the notification claim cannot be reset directly'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

-- 2–4 as the former trainer
SELECT set_config('request.jwt.claims',
  '{"sub":"2e100000-0000-4000-8000-000000000001","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT throws_ok(
  $$ UPDATE public.trainer_client_relationships
        SET ended_by_client_at = NULL
      WHERE id = '2e300000-0000-4000-8000-000000000001' $$,
  NULL, NULL,
  'the former trainer cannot clear the client-end marker directly'
);

SELECT throws_ok(
  $$ UPDATE public.trainer_client_relationships
        SET status = 'active'
      WHERE id = '2e300000-0000-4000-8000-000000000001' $$,
  NULL, NULL,
  'the former trainer cannot reactivate the relationship directly'
);

SELECT throws_ok(
  $$ INSERT INTO public.trainer_client_relationships
       (trainer_id, client_id, status, linked_at)
     VALUES ('2e100000-0000-4000-8000-000000000001',
             '2e100000-0000-4000-8000-000000000003',
             'active', now()) $$,
  NULL, NULL,
  'relationships cannot be created by a direct insert'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

-- 7. no regression: the trainer can still write notes on an ACTIVE relationship
SELECT set_config('request.jwt.claims',
  '{"sub":"2e100000-0000-4000-8000-000000000002","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT lives_ok(
  $$ UPDATE public.trainer_client_relationships
        SET trainer_notes = 'ok'
      WHERE id = '2e300000-0000-4000-8000-000000000002' $$,
  'writing trainer notes directly still works'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role','service_role', true);
SELECT set_config('request.jwt.claims','{"role":"service_role"}', true);

-- 8. no regression: end_trainer_relationship still works as authenticated
SELECT set_config('request.jwt.claims',
  '{"sub":"2e100000-0000-4000-8000-000000000003","role":"authenticated"}', true);
SELECT set_config('request.jwt.claim.role','authenticated', true);
SET LOCAL ROLE authenticated;

SELECT lives_ok(
  $$ SELECT public.end_trainer_relationship('2e100000-0000-4000-8000-000000000002') $$,
  'end_trainer_relationship still works through the definer path'
);

-- 9. no regression: accept_invite still works as authenticated
SELECT lives_ok(
  $$ SELECT public.accept_invite('LCCODE01') $$,
  'accept_invite still works through the definer path'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
