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
SELECT is(
  public.can_write_chat_channel('2c200000-0000-4000-8000-000000000001'),
  false,
  'function: unrelated third member is not allowed to write'
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
SELECT is(
  public.can_write_chat_channel('2c200000-0000-4000-8000-000000000001'),
  true,
  'function: active trainer is allowed to write'
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
SELECT is(
  public.can_write_chat_channel('2c200000-0000-4000-8000-000000000001'),
  false,
  'function: former trainer is not allowed to write'
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
INSERT INTO public.reflex_packages (id, sequence_number, name_de, name_en)
VALUES ('cc-pkg', 99001, 'Testpaket', 'Test package')
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
SELECT is(
  public.can_write_chat_channel('2c200000-0000-4000-8000-000000000002'),
  true,
  'function: community channels stay writable'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
