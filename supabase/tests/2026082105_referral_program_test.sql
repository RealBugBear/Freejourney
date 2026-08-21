BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path = public, extensions;

SELECT no_plan();

-- ---------------------------------------------------------------------------
-- Synthetic accounts (transaction-local only)
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
  ('3e100000-0000-4000-8000-000000000001'::uuid, 'ref-inviter@example.invalid'),
  ('3e100000-0000-4000-8000-000000000002'::uuid, 'ref-invitee@example.invalid'),
  ('3e100000-0000-4000-8000-000000000003'::uuid, 'ref-invitee2@example.invalid'),
  ('3e100000-0000-4000-8000-000000000004'::uuid, 'ref-old@example.invalid'),
  ('3e100000-0000-4000-8000-000000000005'::uuid, 'ref-other-inviter@example.invalid'),
  ('3e100000-0000-4000-8000-000000000006'::uuid, 'ref-delete-invitee@example.invalid'),
  ('3e100000-0000-4000-8000-000000000007'::uuid, 'ref-delete-inviter@example.invalid'),
  ('3e100000-0000-4000-8000-000000000008'::uuid, 'ref-delete-invitee-b@example.invalid'),
  ('3e100000-0000-4000-8000-000000000009'::uuid, 'ref-prior-train@example.invalid'),
  ('3e100000-0000-4000-8000-00000000000a'::uuid, 'ref-landing@example.invalid')
) AS f(id, email)
ON CONFLICT (id) DO NOTHING;

UPDATE public.profiles
   SET created_at = now() - interval '31 days'
 WHERE id = '3e100000-0000-4000-8000-000000000004';

CREATE TEMP TABLE _ref_stage1_baselines AS
SELECT
  (SELECT count(*) FROM public.entitlement_grants) AS entitlement_grants_n,
  (SELECT count(*) FROM public.benefit_campaigns) AS benefit_campaigns_n,
  (SELECT count(*) FROM public.benefit_codes) AS benefit_codes_n;

-- ---------------------------------------------------------------------------
-- Schema / RLS posture
-- ---------------------------------------------------------------------------

SELECT has_table('public', 'referral_codes', 'referral_codes exists');
SELECT has_table('public', 'referrals', 'referrals exists');
SELECT has_function('public', 'get_my_invite_overview', ARRAY[]::text[]);
SELECT has_function('public', 'redeem_invite_code', ARRAY['text']);
SELECT has_function('public', 'log_invite_share_action_tapped', ARRAY[]::text[]);
SELECT has_function('public', 'log_invite_landing_view', ARRAY['text']);
SELECT has_function(
  'public',
  'activate_referral_on_first_completed_session',
  ARRAY[]::text[]
);

SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.referral_codes'::regclass),
  'referral_codes has RLS enabled'
);
SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.referrals'::regclass),
  'referrals has RLS enabled'
);
SELECT is(
  (SELECT count(*)::integer FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('referral_codes', 'referrals')),
  0,
  'referral tables have zero RLS policies'
);

-- ---------------------------------------------------------------------------
-- Function privileges
-- ---------------------------------------------------------------------------

SELECT ok(
  has_function_privilege(
    'authenticated', 'public.get_my_invite_overview()', 'EXECUTE'
  ),
  'authenticated may execute get_my_invite_overview'
);
SELECT ok(
  has_function_privilege(
    'authenticated', 'public.redeem_invite_code(text)', 'EXECUTE'
  ),
  'authenticated may execute redeem_invite_code'
);
SELECT ok(
  has_function_privilege(
    'authenticated', 'public.log_invite_share_action_tapped()', 'EXECUTE'
  ),
  'authenticated may execute log_invite_share_action_tapped'
);
SELECT ok(
  has_function_privilege(
    'authenticated', 'public.log_invite_landing_view(text)', 'EXECUTE'
  ),
  'authenticated may execute log_invite_landing_view'
);
SELECT ok(
  has_function_privilege(
    'anon', 'public.log_invite_landing_view(text)', 'EXECUTE'
  ),
  'anon may execute log_invite_landing_view'
);
SELECT ok(
  NOT has_function_privilege(
    'anon', 'public.get_my_invite_overview()', 'EXECUTE'
  ),
  'anon may not execute get_my_invite_overview'
);
SELECT ok(
  NOT has_function_privilege(
    'anon', 'public.redeem_invite_code(text)', 'EXECUTE'
  ),
  'anon may not execute redeem_invite_code'
);
SELECT ok(
  NOT has_function_privilege(
    'anon', 'public.log_invite_share_action_tapped()', 'EXECUTE'
  ),
  'anon may not execute log_invite_share_action_tapped'
);
SELECT ok(
  NOT has_function_privilege('public', 'public._referral_code()', 'EXECUTE'),
  'PUBLIC may not execute _referral_code'
);
SELECT ok(
  NOT has_function_privilege(
    'public',
    'public.activate_referral_on_first_completed_session()',
    'EXECUTE'
  ),
  'PUBLIC may not execute activate_referral_on_first_completed_session'
);

-- ---------------------------------------------------------------------------
-- get_my_invite_overview is stable across calls
-- ---------------------------------------------------------------------------

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

CREATE TEMP TABLE _ref_overview AS
SELECT public.get_my_invite_overview() AS first_call;

SELECT ok(
  (SELECT first_call->>'code' ~ '^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{8}$'
     FROM _ref_overview),
  'overview returns an 8-char referral code'
);
SELECT is(
  (SELECT (first_call->>'activated_count')::integer FROM _ref_overview),
  0,
  'new inviter has activated_count 0'
);
SELECT is(
  public.get_my_invite_overview()->>'code',
  (SELECT first_call->>'code' FROM _ref_overview),
  'second get_my_invite_overview call returns the same code'
);

-- ---------------------------------------------------------------------------
-- authenticated cannot read or mutate tables directly
-- ---------------------------------------------------------------------------

SELECT throws_ok(
  $$ SELECT * FROM public.referral_codes $$,
  '42501',
  NULL,
  'authenticated cannot SELECT referral_codes'
);
SELECT throws_ok(
  $$ SELECT * FROM public.referrals $$,
  '42501',
  NULL,
  'authenticated cannot SELECT referrals'
);
SELECT throws_ok(
  $$ INSERT INTO public.referral_codes (user_id, code)
     VALUES ('3e100000-0000-4000-8000-000000000001', 'ABCD2345') $$,
  '42501',
  NULL,
  'authenticated cannot INSERT referral_codes'
);
SELECT throws_ok(
  $$ INSERT INTO public.referrals (inviter_user_id, invitee_user_id, code)
     VALUES (
       '3e100000-0000-4000-8000-000000000001',
       '3e100000-0000-4000-8000-000000000002',
       'ABCD2345'
     ) $$,
  '42501',
  NULL,
  'authenticated cannot INSERT referrals'
);
SELECT throws_ok(
  $$ UPDATE public.referral_codes SET is_active = false $$,
  '42501',
  NULL,
  'authenticated cannot UPDATE referral_codes'
);
SELECT throws_ok(
  $$ UPDATE public.referrals SET status = 'blocked', blocked_at = now() $$,
  '42501',
  NULL,
  'authenticated cannot UPDATE referrals'
);
SELECT throws_ok(
  $$ DELETE FROM public.referral_codes $$,
  '42501',
  NULL,
  'authenticated cannot DELETE referral_codes'
);
SELECT throws_ok(
  $$ DELETE FROM public.referrals $$,
  '42501',
  NULL,
  'authenticated cannot DELETE referrals'
);

CREATE TEMP TABLE _ref_inviter_code AS
SELECT public.get_my_invite_overview()->>'code' AS code;

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- Self-redeem rejected (result contract)
-- ---------------------------------------------------------------------------

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

CREATE TEMP TABLE _ref_own AS
SELECT public.redeem_invite_code((SELECT code FROM _ref_inviter_code)) AS payload;

SELECT is(
  (SELECT payload->>'result' FROM _ref_own),
  'own_code',
  'self-redeem is rejected as own_code'
);
SELECT ok(
  (SELECT payload ? 'result'
      AND NOT (payload ? 'status')
      AND NOT (payload ? 'reason')
     FROM _ref_own),
  'redeem payload has only the result key'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- Inactive code rejected + landing view ignores inactive codes
-- ---------------------------------------------------------------------------

CREATE TEMP TABLE _ref_landing_before AS
SELECT landing_view_count AS n
  FROM public.referral_codes
 WHERE user_id = '3e100000-0000-4000-8000-000000000001';

UPDATE public.referral_codes
   SET is_active = false
 WHERE user_id = '3e100000-0000-4000-8000-000000000001';

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.redeem_invite_code((SELECT code FROM _ref_inviter_code))->>'result',
  'code_inactive',
  'inactive code is rejected as code_inactive'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- Pass the code via session GUC so anon does not need temp-table SELECT rights
SELECT set_config(
  'test.invite_code',
  (SELECT code FROM _ref_inviter_code),
  true
);
SELECT set_config('request.jwt.claim.role', 'anon', true);
SELECT set_config('request.jwt.claims', '{"role":"anon"}', true);
SET LOCAL ROLE anon;

SELECT lives_ok(
  $$ SELECT public.log_invite_landing_view(current_setting('test.invite_code')) $$,
  'anon can call log_invite_landing_view'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

SELECT is(
  (SELECT landing_view_count FROM public.referral_codes
    WHERE user_id = '3e100000-0000-4000-8000-000000000001'),
  (SELECT n FROM _ref_landing_before),
  'landing view does not count inactive codes'
);

UPDATE public.referral_codes
   SET is_active = true
 WHERE user_id = '3e100000-0000-4000-8000-000000000001';

SELECT set_config('request.jwt.claim.role', 'anon', true);
SELECT set_config('request.jwt.claims', '{"role":"anon"}', true);
SET LOCAL ROLE anon;
SELECT public.log_invite_landing_view(current_setting('test.invite_code'));

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

SELECT is(
  (SELECT landing_view_count FROM public.referral_codes
    WHERE user_id = '3e100000-0000-4000-8000-000000000001'),
  (SELECT n + 1 FROM _ref_landing_before),
  'landing view increments for active codes'
);

-- ---------------------------------------------------------------------------
-- Account older than 30 days rejected
-- ---------------------------------------------------------------------------

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000004","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.redeem_invite_code((SELECT code FROM _ref_inviter_code))->>'result',
  'account_too_old',
  'account older than 30 days is rejected'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- Happy-path redeem + sequential double redeem rejected
-- (Unique on invitee_user_id also guards concurrency; not exercised in parallel)
-- ---------------------------------------------------------------------------

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000002","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.redeem_invite_code((SELECT code FROM _ref_inviter_code))->>'result',
  'accepted',
  'valid redeem is accepted'
);
SELECT is(
  public.redeem_invite_code((SELECT code FROM _ref_inviter_code))->>'result',
  'already_referred',
  'second sequential redeem by same invitee is already_referred'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000005","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

CREATE TEMP TABLE _ref_other_code AS
SELECT public.get_my_invite_overview()->>'code' AS code;

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000003","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.redeem_invite_code((SELECT code FROM _ref_other_code))->>'result',
  'accepted',
  'second invitee can redeem a different inviter code'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- Prior completed training, then redeem → direct activated
-- ---------------------------------------------------------------------------

INSERT INTO public.enrollments (
  id, user_id, package_id, status, assigned_duration_weeks,
  start_date, target_completion_date
) VALUES (
  '3e200000-0000-4000-8000-000000000009',
  '3e100000-0000-4000-8000-000000000009',
  'moro',
  'active',
  4,
  current_date,
  current_date + 28
);

INSERT INTO public.training_sessions (
  id, user_id, enrollment_id, session_date, day_number,
  completed_exercise_ids, is_completed, completed_at
) VALUES (
  '3e300000-0000-4000-8000-000000000009',
  '3e100000-0000-4000-8000-000000000009',
  '3e200000-0000-4000-8000-000000000009',
  current_date,
  1,
  ARRAY['ex1'],
  true,
  now()
);

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000009","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.redeem_invite_code((SELECT code FROM _ref_inviter_code))->>'result',
  'accepted',
  'redeem after prior completed training is accepted'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

SELECT is(
  (SELECT status FROM public.referrals
    WHERE invitee_user_id = '3e100000-0000-4000-8000-000000000009'),
  'activated',
  'prior completed training yields activated row on redeem'
);
SELECT ok(
  (SELECT activated_at IS NOT NULL FROM public.referrals
    WHERE invitee_user_id = '3e100000-0000-4000-8000-000000000009'),
  'prior completed training sets activated_at on redeem'
);

-- ---------------------------------------------------------------------------
-- Trigger activates once; foreign pending rows untouched
-- ---------------------------------------------------------------------------

INSERT INTO public.enrollments (
  id, user_id, package_id, status, assigned_duration_weeks,
  start_date, target_completion_date
) VALUES (
  '3e200000-0000-4000-8000-000000000001',
  '3e100000-0000-4000-8000-000000000002',
  'moro',
  'active',
  4,
  current_date,
  current_date + 28
);

INSERT INTO public.training_sessions (
  id, user_id, enrollment_id, session_date, day_number,
  completed_exercise_ids, is_completed, completed_at
) VALUES (
  '3e300000-0000-4000-8000-000000000001',
  '3e100000-0000-4000-8000-000000000002',
  '3e200000-0000-4000-8000-000000000001',
  current_date,
  1,
  ARRAY['ex1'],
  true,
  now()
);

SELECT is(
  (SELECT status FROM public.referrals
    WHERE invitee_user_id = '3e100000-0000-4000-8000-000000000002'),
  'activated',
  'completed session activates pending referral'
);
SELECT is(
  (SELECT status FROM public.referrals
    WHERE invitee_user_id = '3e100000-0000-4000-8000-000000000003'),
  'pending',
  'trigger does not touch foreign pending referrals'
);

UPDATE public.training_sessions
   SET is_completed = true,
       completed_at = now()
 WHERE id = '3e300000-0000-4000-8000-000000000001';

SELECT is(
  (SELECT count(*)::integer FROM public.referrals
    WHERE invitee_user_id = '3e100000-0000-4000-8000-000000000002'
      AND status = 'activated'),
  1,
  're-synced completed session activates exactly once'
);

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  (public.get_my_invite_overview()->>'activated_count')::integer,
  2,
  'inviter overview counts activated referrals including prior-train redeem'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- activated → blocked is rejected by shape constraints
-- ---------------------------------------------------------------------------

SELECT throws_ok(
  $$ UPDATE public.referrals
        SET status = 'blocked',
            blocked_at = now()
      WHERE invitee_user_id = '3e100000-0000-4000-8000-000000000002' $$,
  '23514',
  NULL,
  'activated → blocked is rejected by check constraints'
);

-- ---------------------------------------------------------------------------
-- Invitee account deletion: SET NULL invitee_user_id, count unchanged
-- ---------------------------------------------------------------------------

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

CREATE TEMP TABLE _ref_count_before_invitee_delete AS
SELECT (public.get_my_invite_overview()->>'activated_count')::integer AS n;

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

CREATE TEMP TABLE _ref_activated_row AS
SELECT id FROM public.referrals
 WHERE inviter_user_id = '3e100000-0000-4000-8000-000000000001'
   AND invitee_user_id = '3e100000-0000-4000-8000-000000000002'
   AND status = 'activated'
 LIMIT 1;

DELETE FROM auth.users WHERE id = '3e100000-0000-4000-8000-000000000002';

SELECT ok(
  (SELECT invitee_user_id IS NULL FROM public.referrals
    WHERE id = (SELECT id FROM _ref_activated_row)),
  'invitee deletion nulls invitee_user_id'
);

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000001","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  (public.get_my_invite_overview()->>'activated_count')::integer,
  (SELECT n FROM _ref_count_before_invitee_delete),
  'invitee deletion does not change inviter activated_count'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- Inviter account deletion removes code and referral rows
-- ---------------------------------------------------------------------------

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000007","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

CREATE TEMP TABLE _ref_delete_inviter_code AS
SELECT public.get_my_invite_overview()->>'code' AS code;

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000008","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.redeem_invite_code((SELECT code FROM _ref_delete_inviter_code))->>'result',
  'accepted',
  'setup redeem before inviter deletion'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

DELETE FROM auth.users WHERE id = '3e100000-0000-4000-8000-000000000007';

SELECT is(
  (SELECT count(*)::integer FROM public.referral_codes
    WHERE user_id = '3e100000-0000-4000-8000-000000000007'),
  0,
  'inviter deletion removes referral_codes row'
);
SELECT is(
  (SELECT count(*)::integer FROM public.referrals
    WHERE inviter_user_id = '3e100000-0000-4000-8000-000000000007'),
  0,
  'inviter deletion cascades referrals rows'
);

SELECT set_config(
  'request.jwt.claims',
  '{"sub":"3e100000-0000-4000-8000-000000000006","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.redeem_invite_code((SELECT code FROM _ref_delete_inviter_code))->>'result',
  'unknown_code',
  'redeem after inviter deletion returns unknown_code'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- Stage 1: no entitlement / benefit rows created by this flow
-- ---------------------------------------------------------------------------

SELECT is(
  (SELECT count(*) FROM public.entitlement_grants),
  (SELECT entitlement_grants_n FROM _ref_stage1_baselines),
  'no entitlement_grants rows created by referral flow'
);
SELECT is(
  (SELECT count(*) FROM public.benefit_campaigns),
  (SELECT benefit_campaigns_n FROM _ref_stage1_baselines),
  'no benefit_campaigns rows created by referral flow'
);
SELECT is(
  (SELECT count(*) FROM public.benefit_codes),
  (SELECT benefit_codes_n FROM _ref_stage1_baselines),
  'no benefit_codes rows created by referral flow'
);

SELECT * FROM finish();
ROLLBACK;
