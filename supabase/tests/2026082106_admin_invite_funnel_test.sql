BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path = public, extensions;

SELECT no_plan();

-- ---------------------------------------------------------------------------
-- Synthetic accounts (transaction-local)
-- ---------------------------------------------------------------------------

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
  ('3e200000-0000-4000-8000-000000000001'::uuid, 'funnel-admin@example.invalid'),
  ('3e200000-0000-4000-8000-000000000002'::uuid, 'funnel-user@example.invalid'),
  ('3e200000-0000-4000-8000-000000000003'::uuid, 'funnel-inviter@example.invalid'),
  ('3e200000-0000-4000-8000-000000000004'::uuid, 'funnel-pending@example.invalid'),
  ('3e200000-0000-4000-8000-000000000005'::uuid, 'funnel-activated@example.invalid'),
  ('3e200000-0000-4000-8000-000000000006'::uuid, 'funnel-blocked@example.invalid'),
  ('3e200000-0000-4000-8000-000000000007'::uuid, 'funnel-deleted@example.invalid')
) AS f(id, email)
ON CONFLICT (id) DO NOTHING;

UPDATE public.profiles
   SET role = 'admin'
 WHERE id = '3e200000-0000-4000-8000-000000000001';

SELECT has_function('public', 'get_admin_invite_funnel_v1', ARRAY[]::text[]);

SELECT ok(
  has_function_privilege(
    'authenticated', 'public.get_admin_invite_funnel_v1()', 'EXECUTE'
  ),
  'authenticated may execute get_admin_invite_funnel_v1 (admin gate is inside)'
);
SELECT ok(
  NOT has_function_privilege(
    'anon', 'public.get_admin_invite_funnel_v1()', 'EXECUTE'
  ),
  'anon may not execute get_admin_invite_funnel_v1'
);

-- ---------------------------------------------------------------------------
-- Authz: anon / authenticated non-admin denied; admin allowed
-- ---------------------------------------------------------------------------

SELECT set_config('request.jwt.claim.role', 'anon', true);
SELECT set_config('request.jwt.claims', '{"role":"anon"}', true);
SET LOCAL ROLE anon;

SELECT throws_ok(
  $$ SELECT * FROM public.get_admin_invite_funnel_v1() $$,
  '42501',
  NULL,
  'anon cannot call get_admin_invite_funnel_v1'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e200000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);
SET LOCAL ROLE authenticated;

SELECT throws_ok(
  $$ SELECT * FROM public.get_admin_invite_funnel_v1() $$,
  'P0001',
  'Only admins can read invite funnel metrics',
  'non-admin authenticated cannot read invite funnel'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- Seed funnel aggregates (service_role bypasses table REVOKE)
-- ---------------------------------------------------------------------------

INSERT INTO public.referral_codes (
  user_id, code, share_action_tapped_count, landing_view_count
) VALUES (
  '3e200000-0000-4000-8000-000000000003',
  'ABCDEFGH',
  10,
  4
)
ON CONFLICT (user_id) DO UPDATE
SET share_action_tapped_count = EXCLUDED.share_action_tapped_count,
    landing_view_count = EXCLUDED.landing_view_count,
    code = EXCLUDED.code;

INSERT INTO public.referrals (
  id, inviter_user_id, invitee_user_id, code, status, activated_at, blocked_at
) VALUES
  (
    '3e200000-0000-4000-8000-000000000101',
    '3e200000-0000-4000-8000-000000000003',
    '3e200000-0000-4000-8000-000000000004',
    'ABCDEFGH',
    'pending',
    NULL,
    NULL
  ),
  (
    '3e200000-0000-4000-8000-000000000102',
    '3e200000-0000-4000-8000-000000000003',
    '3e200000-0000-4000-8000-000000000005',
    'ABCDEFGH',
    'activated',
    now(),
    NULL
  ),
  (
    '3e200000-0000-4000-8000-000000000103',
    '3e200000-0000-4000-8000-000000000003',
    '3e200000-0000-4000-8000-000000000006',
    'ABCDEFGH',
    'blocked',
    NULL,
    now()
  ),
  (
    '3e200000-0000-4000-8000-000000000104',
    '3e200000-0000-4000-8000-000000000003',
    '3e200000-0000-4000-8000-000000000007',
    'ABCDEFGH',
    'activated',
    now(),
    NULL
  )
ON CONFLICT (id) DO NOTHING;

-- Soft-delete invitee: invitee_user_id SET NULL, activation row remains
DELETE FROM auth.users WHERE id = '3e200000-0000-4000-8000-000000000007';

SELECT is(
  (SELECT invitee_user_id IS NULL
     FROM public.referrals
    WHERE id = '3e200000-0000-4000-8000-000000000104'),
  true,
  'deleted invitee clears invitee_user_id via ON DELETE SET NULL'
);
SELECT is(
  (SELECT status
     FROM public.referrals
    WHERE id = '3e200000-0000-4000-8000-000000000104'),
  'activated',
  'activated status survives invitee deletion'
);

-- ---------------------------------------------------------------------------
-- Admin reads aggregates (no PII columns / ids in payload)
-- ---------------------------------------------------------------------------

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e200000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

CREATE TEMP TABLE _funnel AS
SELECT * FROM public.get_admin_invite_funnel_v1();

SELECT is(
  (SELECT value FROM _funnel WHERE metric_key = 'share_action_tapped_count'),
  10::numeric,
  'share_action_tapped_count aggregates taps'
);
SELECT is(
  (SELECT value FROM _funnel WHERE metric_key = 'landing_view_count'),
  4::numeric,
  'landing_view_count aggregates landings'
);
SELECT is(
  (SELECT value FROM _funnel WHERE metric_key = 'redeemed_count'),
  4::numeric,
  'redeemed_count counts all referral rows'
);
SELECT is(
  (SELECT value FROM _funnel WHERE metric_key = 'pending_count'),
  1::numeric,
  'pending_count distinguishes pending'
);
SELECT is(
  (SELECT value FROM _funnel WHERE metric_key = 'activated_count'),
  2::numeric,
  'activated_count includes rows with deleted invitee_user_id'
);
SELECT is(
  (SELECT value FROM _funnel WHERE metric_key = 'blocked_count'),
  1::numeric,
  'blocked_count distinguishes blocked'
);
SELECT is(
  (SELECT value FROM _funnel WHERE metric_key = 'conv_landing_per_share'),
  40.0::numeric,
  'conv_landing_per_share = 4/10 * 100'
);
SELECT is(
  (SELECT value FROM _funnel WHERE metric_key = 'conv_redeem_per_landing'),
  100.0::numeric,
  'conv_redeem_per_landing = 4/4 * 100'
);
SELECT is(
  (SELECT value FROM _funnel WHERE metric_key = 'conv_activated_per_redeemed'),
  50.0::numeric,
  'conv_activated_per_redeemed = 2/4 * 100'
);

SELECT ok(
  NOT EXISTS (
    SELECT 1
    FROM _funnel m,
         jsonb_each(m.metadata) e
    WHERE e.value::text ~* '3e200000'
       OR e.key ILIKE '%user_id%'
       OR e.key ILIKE '%email%'
       OR e.key ILIKE '%name%'
  ),
  'funnel metadata contains no invitee identifiers or names'
);
SELECT ok(
  NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = '_funnel'
      AND column_name IN ('invitee_user_id', 'email', 'display_name', 'code')
  ),
  'funnel result shape has no PII columns'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- Zero denominators → NULL (defined)
DELETE FROM public.referrals
 WHERE inviter_user_id = '3e200000-0000-4000-8000-000000000003';
UPDATE public.referral_codes
   SET share_action_tapped_count = 0,
       landing_view_count = 0
 WHERE user_id = '3e200000-0000-4000-8000-000000000003';

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e200000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT ok(
  (SELECT value IS NULL
     FROM public.get_admin_invite_funnel_v1()
    WHERE metric_key = 'conv_landing_per_share'),
  'conv_landing_per_share is NULL when share denominator is 0'
);
SELECT ok(
  (SELECT value IS NULL
     FROM public.get_admin_invite_funnel_v1()
    WHERE metric_key = 'conv_redeem_per_landing'),
  'conv_redeem_per_landing is NULL when landing denominator is 0'
);
SELECT ok(
  (SELECT value IS NULL
     FROM public.get_admin_invite_funnel_v1()
    WHERE metric_key = 'conv_activated_per_redeemed'),
  'conv_activated_per_redeemed is NULL when redeemed denominator is 0'
);
SELECT is(
  (SELECT metadata ->> 'zero_denominator'
     FROM public.get_admin_invite_funnel_v1()
    WHERE metric_key = 'conv_activated_per_redeemed'),
  'null',
  'zero-denominator policy documented as null in metadata'
);

-- Existing admin metrics still callable by admin
SELECT lives_ok(
  $$ SELECT count(*) FROM public.get_admin_metrics_v1() $$,
  'existing get_admin_metrics_v1 remains callable for admin'
);

SELECT * FROM finish();
ROLLBACK;
