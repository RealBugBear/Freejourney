BEGIN;

CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SET LOCAL search_path = public, extensions;

SELECT no_plan();

-- ---------------------------------------------------------------------------
-- Schema and privacy contract
-- ---------------------------------------------------------------------------

SELECT has_table('public', 'entitlement_grants', 'entitlement grant ledger exists');
SELECT has_table('public', 'benefit_campaigns', 'benefit campaign table exists');
SELECT has_table('public', 'benefit_codes', 'digest-only benefit code table exists');
SELECT has_table('public', 'benefit_redemptions', 'benefit redemption ledger exists');
SELECT has_table('public', 'sales_rollout', 'sales rollout is separate');
SELECT has_table('public', 'feature_rollout', 'feature rollout is separate');
SELECT has_column('public', 'benefit_codes', 'code_digest', 'benefit code stores a digest');
SELECT hasnt_column('public', 'benefit_codes', 'code', 'benefit code never stores cleartext');
SELECT hasnt_column(
  'public',
  'benefit_redemptions',
  'account_subject_hash',
  'deleted-account audit retains no linkable subject hash'
);
SELECT has_function(
  'public',
  'get_my_effective_entitlements',
  ARRAY[]::text[],
  'authenticated effective-entitlement RPC exists'
);
SELECT has_function(
  'public',
  'get_paid_rollout',
  ARRAY['text'],
  'paid-rollout RPC exists'
);
SELECT has_function(
  'public',
  'redeem_access_code',
  ARRAY['text', 'uuid', 'text', 'text'],
  'compatible four-argument redemption RPC exists'
);
SELECT ok(
  has_function_privilege(
    'service_role',
    'public.redeem_access_code(text,uuid,text,text)',
    'EXECUTE'
  ),
  'service role may execute redemption RPC'
);
SELECT ok(
  NOT has_function_privilege(
    'authenticated',
    'public.redeem_access_code(text,uuid,text,text)',
    'EXECUTE'
  ),
  'authenticated role has no redemption RPC execute privilege'
);
SELECT ok(
  (
    SELECT count(*) >= 3
      FROM regexp_matches(
        pg_get_functiondef(
          'public.redeem_access_code(text,uuid,text,text)'::regprocedure
        ),
        'FOR UPDATE',
        'g'
      )
  ),
  'redemption transaction locks benefit code, campaign, and legacy code rows'
);
SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.entitlement_grants'::regclass),
  'entitlement grants have RLS enabled'
);
SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'public.benefit_codes'::regclass),
  'benefit codes have RLS enabled'
);

-- ---------------------------------------------------------------------------
-- Synthetic accounts. These UUIDs/emails exist only inside this transaction.
-- ---------------------------------------------------------------------------

SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
)
SELECT
  '00000000-0000-0000-0000-000000000000'::uuid,
  fixture.id,
  'authenticated',
  'authenticated',
  fixture.email,
  '',
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{}'::jsonb,
  now(),
  now(),
  '',
  '',
  '',
  ''
FROM (
  VALUES
    ('25190000-0000-4000-8000-000000000001'::uuid, 't25-user-1@example.invalid'),
    ('25190000-0000-4000-8000-000000000002'::uuid, 't25-user-2@example.invalid'),
    ('25190000-0000-4000-8000-000000000003'::uuid, 't25-user-3@example.invalid'),
    ('25190000-0000-4000-8000-000000000004'::uuid, 't25-admin@example.invalid'),
    ('25190000-0000-4000-8000-000000000005'::uuid, 't25-trainer-1@example.invalid'),
    ('25190000-0000-4000-8000-000000000006'::uuid, 't25-user-6@example.invalid'),
    ('25190000-0000-4000-8000-000000000007'::uuid, 't25-user-7@example.invalid'),
    ('25190000-0000-4000-8000-000000000008'::uuid, 't25-trainer-2@example.invalid'),
    ('25190000-0000-4000-8000-000000000009'::uuid, 't25-code-profile@example.invalid'),
    ('25190000-0000-4000-8000-000000000010'::uuid, 't25-generic-permanent@example.invalid'),
    ('25190000-0000-4000-8000-000000000011'::uuid, 't25-null-future@example.invalid'),
    ('25190000-0000-4000-8000-000000000012'::uuid, 't25-null-past@example.invalid')
) AS fixture(id, email)
ON CONFLICT (id) DO NOTHING;

UPDATE public.profiles
   SET role = CASE id
     WHEN '25190000-0000-4000-8000-000000000004'::uuid THEN 'admin'
     WHEN '25190000-0000-4000-8000-000000000005'::uuid THEN 'trainer'
     WHEN '25190000-0000-4000-8000-000000000008'::uuid THEN 'trainer'
     ELSE 'practitioner'
   END
 WHERE id::text LIKE '25190000-0000-4000-8000-%';

-- Test-only untrusted nested writer. It proves trigger nesting cannot bypass
-- the SECURITY INVOKER premium guard; all objects roll back with this test.
CREATE TABLE public._t25_untrusted_projection_probe (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid()
);

CREATE FUNCTION public._t25_untrusted_nested_projection_write()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $function$
BEGIN
  UPDATE public.profiles
     SET is_premium = false,
         premium_type = NULL,
         premium_valid_until = NULL
   WHERE id = auth.uid();
  RETURN NEW;
END;
$function$;

CREATE TRIGGER trg_t25_untrusted_nested_projection_write
  BEFORE INSERT ON public._t25_untrusted_projection_probe
  FOR EACH ROW
  EXECUTE FUNCTION public._t25_untrusted_nested_projection_write();

GRANT INSERT ON public._t25_untrusted_projection_probe TO authenticated;

-- ---------------------------------------------------------------------------
-- Idempotent T24 + pre-ledger profile backfill, executed twice.
-- ---------------------------------------------------------------------------

INSERT INTO public.access_codes (
  id,
  code,
  type,
  redemption_count,
  redeemed_by,
  redeemed_at,
  created_by
) VALUES (
  '25190000-0000-4000-8000-000000000091',
  'T25-REDEEMED-LEGACY',
  'free',
  1,
  '25190000-0000-4000-8000-000000000001',
  now() - interval '1 day',
  '25190000-0000-4000-8000-000000000004'
);

UPDATE public.profiles
   SET is_premium = true,
       premium_type = 'code',
       premium_valid_until = NULL
 WHERE id = '25190000-0000-4000-8000-000000000001';

UPDATE public.profiles
   SET is_premium = true,
       premium_type = 'yearly',
       premium_valid_until = now() + interval '180 days'
 WHERE id = '25190000-0000-4000-8000-000000000002';

UPDATE public.profiles
   SET is_premium = true,
       premium_type = NULL,
       premium_valid_until = NULL
 WHERE id = '25190000-0000-4000-8000-000000000010';

UPDATE public.profiles
   SET is_premium = true,
       premium_type = NULL,
       premium_valid_until = now() + interval '30 days'
 WHERE id = '25190000-0000-4000-8000-000000000011';

UPDATE public.profiles
   SET is_premium = true,
       premium_type = NULL,
       premium_valid_until = now() - interval '30 days'
 WHERE id = '25190000-0000-4000-8000-000000000012';

SELECT public._backfill_legacy_entitlements();
SELECT public._backfill_legacy_entitlements();

SELECT is(
  (
    SELECT count(*)::integer
      FROM public.entitlement_grants
     WHERE source = 'benefit_code'
       AND source_ref = 'legacy-access-code:25190000-0000-4000-8000-000000000091'
  ),
  1,
  'T24 redeemed-code backfill remains single after two runs'
);
SELECT is(
  (
    SELECT count(*)::integer
      FROM public.entitlement_grants
     WHERE source_ref = 'legacy-profile:25190000-0000-4000-8000-000000000001'
  ),
  0,
  'a represented T24 user does not receive a duplicate legacy-profile grant'
);
SELECT is(
  (
    SELECT count(*)::integer
      FROM public.entitlement_grants
     WHERE source_ref = 'legacy-profile:25190000-0000-4000-8000-000000000002'
  ),
  1,
  'a pre-ledger premium profile receives exactly one compatibility grant'
);
SELECT ok(
  (SELECT is_premium FROM public.profiles WHERE id = '25190000-0000-4000-8000-000000000002'),
  'legacy-profile backfill preserves existing premium access'
);
SELECT is(
  (
    SELECT source
      FROM public.entitlement_grants
     WHERE source_ref = 'legacy-profile:25190000-0000-4000-8000-000000000010'
  ),
  'admin',
  'generic permanent legacy profile backfills as an admin grant'
);
SELECT is(
  (
    SELECT premium_type
      FROM public.profiles
     WHERE id = '25190000-0000-4000-8000-000000000010'
  ),
  'lifetime',
  'generic permanent legacy profile projects as lifetime, never code'
);
SELECT is(
  (
    SELECT is_permanent
      FROM public.entitlement_grants
     WHERE source_ref = 'legacy-profile:25190000-0000-4000-8000-000000000011'
  ),
  false,
  'null-type future finite legacy profile backfills as non-permanent'
);
SELECT is(
  (
    SELECT status
      FROM public.entitlement_grants
     WHERE source_ref = 'legacy-profile:25190000-0000-4000-8000-000000000011'
  ),
  'active',
  'null-type future finite legacy profile remains active'
);
SELECT is(
  (
    SELECT status
      FROM public.entitlement_grants
     WHERE source_ref = 'legacy-profile:25190000-0000-4000-8000-000000000012'
  ),
  'expired',
  'null-type past finite legacy profile remains expired'
);
SELECT is(
  (
    SELECT is_permanent
      FROM public.entitlement_grants
     WHERE source_ref = 'legacy-profile:25190000-0000-4000-8000-000000000012'
  ),
  false,
  'null-type past finite legacy profile is never extended permanently'
);

UPDATE public.profiles
   SET is_premium = true,
       premium_type = 'monthly',
       premium_valid_until = now() - interval '7 days'
 WHERE id = '25190000-0000-4000-8000-000000000004';

SELECT public._backfill_legacy_entitlements();
SELECT public._backfill_legacy_entitlements();

SELECT is(
  (
    SELECT status
      FROM public.entitlement_grants
     WHERE source_ref = 'legacy-profile:25190000-0000-4000-8000-000000000004'
  ),
  'expired',
  'expired finite legacy projection remains expired during backfill'
);
SELECT is(
  (
    SELECT is_permanent
      FROM public.entitlement_grants
     WHERE source_ref = 'legacy-profile:25190000-0000-4000-8000-000000000004'
  ),
  false,
  'expired monthly/yearly projection is never extended into permanent access'
);

-- A legacy code profile without an access_codes row retains code provenance.
UPDATE public.profiles
   SET is_premium = true,
       premium_type = 'code',
       premium_valid_until = NULL
 WHERE id = '25190000-0000-4000-8000-000000000009';

SELECT public._backfill_legacy_entitlements();
SELECT public._backfill_legacy_entitlements();

SELECT is(
  (
    SELECT source
      FROM public.entitlement_grants
     WHERE source_ref = 'legacy-profile:25190000-0000-4000-8000-000000000009'
  ),
  'benefit_code',
  'profile-only premium_type code backfill preserves benefit-code origin'
);
SELECT is(
  (
    SELECT count(*)::integer
      FROM public.entitlement_grants
     WHERE source_ref = 'legacy-profile:25190000-0000-4000-8000-000000000009'
  ),
  1,
  'profile-only code backfill remains idempotent'
);

-- Generic permanent admin grants are displayed as lifetime, never monthly
-- with a null expiry.
INSERT INTO public.entitlement_grants (
  user_id, entitlement_key, source, source_ref, status,
  starts_at, expires_at, is_permanent, metadata
) VALUES (
  '25190000-0000-4000-8000-000000000004',
  'premium',
  'admin',
  'test:permanent-admin',
  'active',
  now(),
  NULL,
  true,
  '{}'::jsonb
);

SELECT is(
  (SELECT premium_type FROM public.profiles WHERE id = '25190000-0000-4000-8000-000000000004'),
  'lifetime',
  'generic permanent admin grant projects as lifetime'
);

-- ---------------------------------------------------------------------------
-- Multi-grant matrix and transactional legacy projection.
-- ---------------------------------------------------------------------------

-- An expired store grant cannot win over a permanent code grant.
INSERT INTO public.entitlement_grants (
  user_id, entitlement_key, source, source_ref, status, store, product_id,
  starts_at, expires_at, is_permanent
) VALUES (
  '25190000-0000-4000-8000-000000000003',
  'premium',
  'revenuecat',
  'test:expired-store',
  'expired',
  'app_store',
  'premium_monthly',
  now() - interval '60 days',
  now() - interval '30 days',
  false
);

INSERT INTO public.entitlement_grants (
  user_id, entitlement_key, source, source_ref, status, starts_at,
  expires_at, is_permanent, metadata
) VALUES (
  '25190000-0000-4000-8000-000000000003',
  'premium',
  'benefit_code',
  'test:permanent-code',
  'active',
  now(),
  NULL,
  true,
  '{"premium_type":"code"}'::jsonb
);

SELECT is(
  public._effective_entitlement(
    '25190000-0000-4000-8000-000000000003',
    'premium'
  )->>'is_active',
  'true',
  'code plus expired store grant remains active'
);
SELECT is(
  public._effective_entitlement(
    '25190000-0000-4000-8000-000000000003',
    'premium'
  )->>'source',
  'benefit_code',
  'effective source identifies the active code grant'
);

-- Premium and Studio coexist independently.
INSERT INTO public.entitlement_grants (
  user_id, entitlement_key, source, source_ref, status, starts_at,
  expires_at, is_permanent
) VALUES (
  '25190000-0000-4000-8000-000000000003',
  'studio',
  'pilot',
  'test:studio-pilot',
  'active',
  now(),
  now() + interval '30 days',
  false
);

SELECT ok(
  (public._effective_entitlement(
    '25190000-0000-4000-8000-000000000003', 'premium'
  )->>'is_active')::boolean
  AND
  (public._effective_entitlement(
    '25190000-0000-4000-8000-000000000003', 'studio'
  )->>'is_active')::boolean,
  'premium and studio may both be active'
);

-- A lifetime grant survives refund/revocation of another store grant.
INSERT INTO public.entitlement_grants (
  user_id, entitlement_key, source, source_ref, status, store, product_id,
  starts_at, expires_at, revoked_at, is_permanent, metadata
) VALUES
  (
    '25190000-0000-4000-8000-000000000008',
    'premium',
    'revenuecat',
    'test:lifetime',
    'active',
    'play_store',
    'premium_lifetime',
    now(),
    NULL,
    NULL,
    true,
    '{"product_type":"lifetime"}'::jsonb
  ),
  (
    '25190000-0000-4000-8000-000000000008',
    'premium',
    'revenuecat',
    'test:refunded-monthly',
    'revoked',
    'app_store',
    'premium_monthly',
    now() - interval '10 days',
    now() + interval '20 days',
    now(),
    false,
    '{}'::jsonb
  );

SELECT is(
  public._effective_entitlement(
    '25190000-0000-4000-8000-000000000008', 'premium'
  )->>'is_permanent',
  'true',
  'lifetime remains effective when a separate purchase is refunded'
);

-- Store grant alone.
INSERT INTO public.entitlement_grants (
  user_id, entitlement_key, source, source_ref, status, store, product_id,
  starts_at, expires_at, is_permanent
) VALUES (
  '25190000-0000-4000-8000-000000000006',
  'premium',
  'revenuecat',
  'test:store-only',
  'active',
  'app_store',
  'premium_yearly',
  now(),
  now() + interval '365 days',
  false
);

SELECT is(
  public._effective_entitlement(
    '25190000-0000-4000-8000-000000000006', 'premium'
  )->>'is_active',
  'true',
  'store grant alone is effective'
);

-- Expired review access is not effective.
INSERT INTO public.entitlement_grants (
  user_id, entitlement_key, source, source_ref, status, starts_at,
  expires_at, is_permanent
) VALUES (
  '25190000-0000-4000-8000-000000000007',
  'studio',
  'review',
  'test:expired-review',
  'expired',
  now() - interval '10 days',
  now() - interval '1 day',
  false
);

SELECT is(
  public._effective_entitlement(
    '25190000-0000-4000-8000-000000000007', 'studio'
  )->>'is_active',
  'false',
  'expired review grant is ineffective'
);

-- Add lifetime to the code user: code is display priority only. Revoking code
-- changes the projection reason but leaves lifetime access and the row intact.
INSERT INTO public.entitlement_grants (
  user_id, entitlement_key, source, source_ref, status, store, product_id,
  starts_at, expires_at, is_permanent, metadata
) VALUES (
  '25190000-0000-4000-8000-000000000003',
  'premium',
  'revenuecat',
  'test:lifetime-behind-code',
  'active',
  'app_store',
  'premium_lifetime',
  now(),
  NULL,
  true,
  '{"product_type":"lifetime"}'::jsonb
);

SELECT is(
  (SELECT premium_type FROM public.profiles WHERE id = '25190000-0000-4000-8000-000000000003'),
  'code',
  'legacy projection uses code before lifetime for display only'
);

UPDATE public.entitlement_grants
   SET status = 'revoked',
       revoked_at = now(),
       updated_at = now()
 WHERE source_ref = 'test:permanent-code';

SELECT ok(
  (SELECT is_premium FROM public.profiles WHERE id = '25190000-0000-4000-8000-000000000003'),
  'revoking one grant does not remove access supplied by another'
);
SELECT is(
  (SELECT premium_type FROM public.profiles WHERE id = '25190000-0000-4000-8000-000000000003'),
  'lifetime',
  'legacy display reason recomputes transactionally'
);
SELECT is(
  (
    SELECT count(*)::integer
      FROM public.entitlement_grants
     WHERE user_id = '25190000-0000-4000-8000-000000000003'
       AND entitlement_key = 'premium'
  ),
  3,
  'projection never deletes coexisting ledger rows'
);

-- Public effective RPC is account-bound.
SELECT set_config('request.jwt.claim.sub', '25190000-0000-4000-8000-000000000003', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"25190000-0000-4000-8000-000000000003","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.get_my_effective_entitlements()->'premium'->>'source',
  'revenuecat',
  'effective-entitlement RPC reads only the JWT account'
);
SELECT is(
  public.get_my_effective_entitlements()->'studio'->>'is_active',
  'true',
  'effective-entitlement RPC returns both independent keys'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- ---------------------------------------------------------------------------
-- Benefit campaigns and atomic redemption.
-- ---------------------------------------------------------------------------

INSERT INTO public.benefit_campaigns (
  internal_name,
  purpose,
  entitlement_key,
  benefit_kind,
  grant_source,
  grant_type,
  target_role
) VALUES (
  't25-default-inactive',
  'activation_gate_test',
  'premium',
  'internal_grant',
  'benefit_code',
  'permanent',
  'both'
);
SELECT is(
  (
    SELECT is_active
      FROM public.benefit_campaigns
     WHERE internal_name = 't25-default-inactive'
  ),
  false,
  'new campaigns remain inactive until a separate activation action'
);

INSERT INTO public.benefit_campaigns (
  id, internal_name, purpose, entitlement_key, benefit_kind, grant_source,
  grant_type, duration_days, fixed_end_at, target_role,
  total_redemption_limit, per_account_limit, apple_offer_ref, is_active
) VALUES
  (
    '25190000-0000-4000-8000-000000000101',
    't25-permanent-multi',
    'friends_family',
    'premium',
    'internal_grant',
    'benefit_code',
    'permanent',
    NULL,
    NULL,
    'both',
    3,
    1,
    NULL,
    true
  ),
  (
    '25190000-0000-4000-8000-000000000102',
    't25-trainer-duration',
    'trainer_free_mvp',
    'studio',
    'internal_grant',
    'pilot',
    'duration_days',
    42,
    NULL,
    'trainer',
    NULL,
    1,
    NULL,
    true
  ),
  (
    '25190000-0000-4000-8000-000000000103',
    't25-fixed-end',
    'support',
    'premium',
    'internal_grant',
    'benefit_code',
    'fixed_end',
    NULL,
    now() + interval '90 days',
    'both',
    NULL,
    1,
    NULL,
    true
  ),
  (
    '25190000-0000-4000-8000-000000000104',
    't25-apple-offer',
    'store_discount',
    'premium',
    'store_offer',
    NULL,
    NULL,
    NULL,
    NULL,
    'user',
    2,
    1,
    'offer_ref_synthetic',
    true
  );

SELECT throws_like(
  $$
    INSERT INTO public.benefit_campaigns (
      internal_name,
      purpose,
      entitlement_key,
      benefit_kind,
      target_role,
      apple_offer_ref
    ) VALUES (
      't25-blank-offer',
      'store_discount',
      'premium',
      'store_offer',
      'both',
      '   '
    )
  $$,
  '%benefit_campaigns_apple_offer_nonblank%',
  'store offer reference rejects blank or whitespace values'
);
SELECT throws_like(
  $$
    INSERT INTO public.benefit_campaigns (
      internal_name,
      purpose,
      entitlement_key,
      benefit_kind,
      grant_source,
      grant_type,
      target_role,
      eligibility_rules
    ) VALUES (
      't25-unsupported-eligibility',
      'eligibility_fail_closed_test',
      'premium',
      'internal_grant',
      'benefit_code',
      'permanent',
      'both',
      '{"region":"DE"}'::jsonb
    )
  $$,
  '%benefit_campaigns_eligibility_unsupported_check%',
  'nonempty eligibility rules fail closed until an evaluator exists'
);

INSERT INTO public.benefit_codes (
  id, campaign_id, code_digest, display_hint, usage_type, redemption_limit
) VALUES
  (
    '25190000-0000-4000-8000-000000000201',
    '25190000-0000-4000-8000-000000000101',
    repeat('a', 64),
    '…A001',
    'multi_use',
    5
  ),
  (
    '25190000-0000-4000-8000-000000000202',
    '25190000-0000-4000-8000-000000000101',
    repeat('2', 64),
    '…A002',
    'multi_use',
    5
  ),
  (
    '25190000-0000-4000-8000-000000000203',
    '25190000-0000-4000-8000-000000000102',
    repeat('b', 64),
    '…B001',
    'single_use',
    1
  ),
  (
    '25190000-0000-4000-8000-000000000204',
    '25190000-0000-4000-8000-000000000103',
    repeat('c', 64),
    '…C001',
    'single_use',
    1
  ),
  (
    '25190000-0000-4000-8000-000000000205',
    '25190000-0000-4000-8000-000000000103',
    repeat('e', 64),
    '…C002',
    'multi_use',
    5
  ),
  (
    '25190000-0000-4000-8000-000000000206',
    '25190000-0000-4000-8000-000000000104',
    repeat('d', 64),
    '…D001',
    'multi_use',
    2
  );

INSERT INTO public.benefit_codes (
  id,
  campaign_id,
  code_digest,
  display_hint,
  usage_type,
  redemption_limit,
  is_active,
  revoked_at
) VALUES (
  '25190000-0000-4000-8000-000000000207',
  '25190000-0000-4000-8000-000000000101',
  repeat('f', 64),
  '…F001',
  'single_use',
  1,
  false,
  now()
);

SELECT throws_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000007',
      repeat('9', 64),
      'ios'
    )
  $$,
  'P0001',
  'benefit_code_not_found',
  'unknown valid HMAC has a distinct legacy-retry signal'
);
SELECT throws_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000007',
      repeat('f', 64),
      'ios'
    )
  $$,
  'P0001',
  'benefit_code_inactive',
  'matching inactive HMAC cannot fall through to legacy lookup'
);

SELECT is(
  public.redeem_access_code(
    NULL,
    '25190000-0000-4000-8000-000000000007',
    repeat('a', 64),
    'ios'
  )->>'benefit_kind',
  'internal_grant',
  'multi-use HMAC code creates an internal grant'
);
SELECT is(
  (
    SELECT count(*)::integer
      FROM public.entitlement_grants
     WHERE user_id = '25190000-0000-4000-8000-000000000007'
       AND source = 'benefit_code'
       AND is_permanent
  ),
  1,
  'permanent campaign creates one permanent ledger row'
);
UPDATE public.benefit_codes
   SET is_active = false,
       revoked_at = now()
 WHERE id = '25190000-0000-4000-8000-000000000201';
UPDATE public.benefit_campaigns
   SET is_active = false,
       revoked_at = now()
 WHERE id = '25190000-0000-4000-8000-000000000101';
UPDATE public.profiles
   SET role = 'admin'
 WHERE id = '25190000-0000-4000-8000-000000000007';

SELECT is(
  public.redeem_access_code(
    NULL,
    '25190000-0000-4000-8000-000000000007',
    repeat('a', 64),
    'ios'
  )->>'grant_id',
  (
    SELECT grant_id::text
      FROM public.benefit_redemptions
     WHERE benefit_code_id = '25190000-0000-4000-8000-000000000201'
       AND user_id = '25190000-0000-4000-8000-000000000007'
  ),
  'same-account retry reconstructs the grant after code/campaign/role stop'
);
SELECT is(
  (
    SELECT count(*)::integer
      FROM public.benefit_redemptions
     WHERE benefit_code_id = '25190000-0000-4000-8000-000000000201'
       AND user_id = '25190000-0000-4000-8000-000000000007'
  ),
  1,
  'same-account retry does not add a redemption or consume another limit'
);

UPDATE public.benefit_codes
   SET is_active = true,
       revoked_at = NULL
 WHERE id = '25190000-0000-4000-8000-000000000201';
UPDATE public.benefit_campaigns
   SET is_active = true,
       revoked_at = NULL
 WHERE id = '25190000-0000-4000-8000-000000000101';
UPDATE public.profiles
   SET role = 'practitioner'
 WHERE id = '25190000-0000-4000-8000-000000000007';
SELECT throws_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000007',
      repeat('2', 64),
      'ios'
    )
  $$,
  'P0001',
  'redemption_limit_reached',
  'per-account limit applies atomically across campaign codes'
);

SELECT lives_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000008',
      repeat('a', 64),
      'android'
    )
  $$,
  'multi-use code accepts a second account'
);
SELECT lives_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000006',
      repeat('a', 64),
      'ios'
    )
  $$,
  'multi-use code accepts up to the campaign total limit'
);
SELECT throws_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000003',
      repeat('a', 64),
      'ios'
    )
  $$,
  'P0001',
  'redemption_limit_reached',
  'campaign total limit blocks the next account'
);

SELECT throws_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000003',
      repeat('b', 64),
      'ios'
    )
  $$,
  'P0001',
  'role_not_eligible',
  'trainer-only campaign rejects a practitioner'
);
SELECT lives_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000005',
      repeat('b', 64),
      'android'
    )
  $$,
  'duration campaign redemption succeeds for an eligible trainer'
);
SELECT ok(
  (
    SELECT expires_at
      FROM public.entitlement_grants
     WHERE user_id = '25190000-0000-4000-8000-000000000005'
       AND source = 'pilot'
       AND entitlement_key = 'studio'
     ORDER BY starts_at DESC
     LIMIT 1
  ) BETWEEN now() + interval '41 days' AND now() + interval '43 days',
  'duration campaign creates the requested finite grant'
);

SELECT lives_ok(
  $$
    DELETE FROM auth.users
     WHERE id = '25190000-0000-4000-8000-000000000005'
  $$,
  'deleting a redeemed account succeeds through grant projection cleanup'
);
SELECT is(
  (
    SELECT user_id::text
      FROM public.benefit_redemptions
     WHERE benefit_code_id = '25190000-0000-4000-8000-000000000203'
  ),
  NULL,
  'deleted-account redemption survives without a user identifier'
);
SELECT is(
  (
    SELECT grant_id::text
      FROM public.benefit_redemptions
     WHERE benefit_code_id = '25190000-0000-4000-8000-000000000203'
  ),
  NULL,
  'deleted grant leaves its historical granted redemption intact'
);
SELECT is(
  (
    SELECT count(*)::integer
      FROM public.benefit_redemptions
     WHERE benefit_code_id = '25190000-0000-4000-8000-000000000203'
  ),
  1,
  'deleted-account consumption still counts against the code limit'
);
SELECT throws_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000008',
      repeat('b', 64),
      'android'
    )
  $$,
  'P0001',
  'redemption_limit_reached',
  'single-use code remains consumed after the first account is deleted'
);

SELECT lives_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000003',
      repeat('c', 64),
      'unknown'
    )
  $$,
  'fixed-end campaign redemption succeeds'
);
SELECT ok(
  (
    SELECT expires_at
      FROM public.entitlement_grants
     WHERE user_id = '25190000-0000-4000-8000-000000000003'
       AND metadata->>'campaign_id' = '25190000-0000-4000-8000-000000000103'
     LIMIT 1
  ) BETWEEN now() + interval '89 days' AND now() + interval '91 days',
  'fixed-end campaign uses its exact campaign deadline'
);

UPDATE public.benefit_campaigns
   SET is_active = false,
       revoked_at = now(),
       updated_at = now()
 WHERE id = '25190000-0000-4000-8000-000000000103';

SELECT is(
  (
    SELECT status
      FROM public.entitlement_grants
     WHERE source_ref LIKE 'benefit-redemption:%'
       AND user_id = '25190000-0000-4000-8000-000000000003'
     ORDER BY starts_at DESC
     LIMIT 1
  ),
  'active',
  'campaign revocation does not retroactively revoke its grant'
);
SELECT throws_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000007',
      repeat('e', 64),
      'ios'
    )
  $$,
  'P0001',
  'campaign_inactive',
  'revoked campaign blocks only new redemptions'
);

DELETE FROM public.entitlement_grants
 WHERE user_id = '25190000-0000-4000-8000-000000000003'
   AND metadata->>'campaign_id' = '25190000-0000-4000-8000-000000000103';

SELECT is(
  (
    SELECT grant_id::text
      FROM public.benefit_redemptions
     WHERE user_id = '25190000-0000-4000-8000-000000000003'
       AND campaign_id = '25190000-0000-4000-8000-000000000103'
  ),
  NULL,
  'explicit grant deletion preserves the historical redemption audit row'
);

SELECT throws_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000007',
      repeat('d', 64),
      'android'
    )
  $$,
  'P0001',
  'offer_unavailable',
  'platform without a configured store offer does not consume the code'
);
SELECT throws_ok(
  $$
    SELECT public.redeem_access_code(
      NULL,
      '25190000-0000-4000-8000-000000000007',
      repeat('d', 64),
      'unknown'
    )
  $$,
  'P0001',
  'offer_unavailable',
  'unknown platform does not consume a platform-specific store offer'
);
SELECT is(
  public.redeem_access_code(
    NULL,
    '25190000-0000-4000-8000-000000000007',
    repeat('d', 64),
    'ios'
  )->>'apple_offer_ref',
  'offer_ref_synthetic',
  'store-offer redemption returns only the opaque store reference'
);
SELECT is(
  (
    SELECT store_offer_ref
      FROM public.benefit_redemptions
     WHERE benefit_code_id = '25190000-0000-4000-8000-000000000206'
       AND user_id = '25190000-0000-4000-8000-000000000007'
  ),
  'offer_ref_synthetic',
  'store-offer redemption snapshots the issued platform reference'
);

UPDATE public.benefit_codes
   SET is_active = false,
       revoked_at = now()
 WHERE id = '25190000-0000-4000-8000-000000000206';
UPDATE public.benefit_campaigns
   SET is_active = false,
       revoked_at = now(),
       apple_offer_ref = 'changed_after_redemption',
       entitlement_key = 'studio'
 WHERE id = '25190000-0000-4000-8000-000000000104';
UPDATE public.profiles
   SET role = 'admin'
 WHERE id = '25190000-0000-4000-8000-000000000007';

SELECT is(
  public.redeem_access_code(
    NULL,
    '25190000-0000-4000-8000-000000000007',
    repeat('d', 64),
    'ios'
  )->>'apple_offer_ref',
  'offer_ref_synthetic',
  'store-offer retry returns the issued snapshot after later stop/change'
);
SELECT is(
  public.redeem_access_code(
    NULL,
    '25190000-0000-4000-8000-000000000007',
    repeat('d', 64),
    'ios'
  )->>'entitlement_key',
  'premium',
  'store-offer retry retains its original entitlement after campaign edits'
);
SELECT is(
  (
    SELECT count(*)::integer
      FROM public.benefit_redemptions
     WHERE campaign_id = '25190000-0000-4000-8000-000000000104'
       AND outcome = 'store_offer'
       AND grant_id IS NULL
  ),
  1,
  'store-offer retry creates no duplicate redemption or internal grant'
);

-- Legacy cleartext code remains valid through the default-compatible RPC.
INSERT INTO public.access_codes (
  id, code, type, redemption_count, created_by
) VALUES (
  '25190000-0000-4000-8000-000000000092',
  'T25-LEGACY-STILL-VALID',
  'free',
  0,
  '25190000-0000-4000-8000-000000000004'
);

SELECT throws_ok(
  $$
    SELECT public.redeem_access_code(
      'T25-LEGACY-STILL-VALID',
      '25190000-0000-4000-8000-000000000003',
      repeat('9', 64),
      'ios'
    )
  $$,
  'P0001',
  'benefit_code_not_found',
  'HMAC miss never falls through to raw legacy lookup in the same call'
);

SELECT is(
  public.redeem_access_code(
    ' t25-legacy-still-valid ',
    '25190000-0000-4000-8000-000000000003'
  )->>'entitlement_key',
  'premium',
  'two-argument legacy call remains valid through default arguments'
);
SELECT is(
  (
    SELECT count(*)::integer
      FROM public.entitlement_grants
     WHERE source_ref = 'legacy-access-code:25190000-0000-4000-8000-000000000092'
  ),
  1,
  'legacy redemption creates exactly one ledger grant'
);

-- ---------------------------------------------------------------------------
-- Sales/feature separation and fail-safe resolution.
-- ---------------------------------------------------------------------------

UPDATE public.sales_rollout
   SET rollout_state = 'public', updated_at = now()
 WHERE entitlement_key = 'premium' AND platform = 'all';
INSERT INTO public.sales_rollout (entitlement_key, platform, rollout_state)
VALUES ('premium', 'ios', 'off')
ON CONFLICT (entitlement_key, platform)
DO UPDATE SET rollout_state = EXCLUDED.rollout_state;

INSERT INTO public.feature_rollout (entitlement_key, platform, rollout_state)
VALUES ('studio', 'ios', 'incident_disabled')
ON CONFLICT (entitlement_key, platform)
DO UPDATE SET rollout_state = EXCLUDED.rollout_state;

SELECT set_config('request.jwt.claim.sub', '25190000-0000-4000-8000-000000000003', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"25190000-0000-4000-8000-000000000003","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.get_paid_rollout('ios')->'premium'->>'sales_rollout',
  'off',
  'platform-specific sales off overrides all-platform public sales'
);
SELECT is(
  public.get_paid_rollout('ios')->'studio'->>'feature_rollout',
  'incident_disabled',
  'incident feature state is a separate path from sales'
);
SELECT is(
  public.get_my_effective_entitlements()->'premium'->>'is_active',
  'true',
  'sales rollout off does not revoke valid premium access'
);

-- ---------------------------------------------------------------------------
-- RLS negatives: own reads only, no client writes/inventory reads/RPC grant.
-- ---------------------------------------------------------------------------

SELECT ok(
  (SELECT count(*) > 0 FROM public.entitlement_grants),
  'authenticated user can read own entitlement rows'
);
SELECT is(
  (
    SELECT count(*)::integer
      FROM public.entitlement_grants
     WHERE user_id = '25190000-0000-4000-8000-000000000008'
  ),
  0,
  'authenticated user cannot read another account ledger'
);
SELECT throws_like(
  $$
    INSERT INTO public.entitlement_grants (
      user_id, entitlement_key, source, source_ref, status,
      starts_at, expires_at, is_permanent
    ) VALUES (
      '25190000-0000-4000-8000-000000000003',
      'premium',
      'admin',
      'client-forgery',
      'active',
      now(),
      NULL,
      true
    )
  $$,
  '%permission denied%',
  'authenticated client cannot write an entitlement grant'
);
SELECT throws_like(
  $$ SELECT count(*) FROM public.benefit_codes $$,
  '%permission denied%',
  'authenticated client cannot read digest inventory'
);
SELECT throws_like(
  $$
    UPDATE public.sales_rollout
       SET rollout_state = 'public'
     WHERE entitlement_key = 'premium' AND platform = 'all'
  $$,
  '%permission denied%',
  'authenticated client cannot update sales rollout state'
);
SELECT throws_like(
  $$
    UPDATE public.feature_rollout
       SET rollout_state = 'incident_disabled'
     WHERE entitlement_key = 'premium' AND platform = 'all'
  $$,
  '%permission denied%',
  'authenticated client cannot update feature rollout state'
);
SELECT throws_like(
  $$
    SELECT public.redeem_access_code(
      'T25-LEGACY-STILL-VALID',
      '25190000-0000-4000-8000-000000000003'
    )
  $$,
  '%permission denied%',
  'authenticated client cannot invoke the service-only redemption RPC'
);
SELECT set_config('app.entitlement_projection', 'on', true);
SELECT throws_like(
  $$
    UPDATE public.profiles
       SET is_premium = false
     WHERE id = '25190000-0000-4000-8000-000000000003'
  $$,
  '%Changing premium entitlement columns directly is not permitted%',
  'caller-settable legacy GUC cannot bypass the projection guard'
);
SELECT throws_like(
  $$
    INSERT INTO public._t25_untrusted_projection_probe DEFAULT VALUES
  $$,
  '%Changing premium entitlement columns directly is not permitted%',
  'untrusted nested trigger cannot overwrite the legacy projection'
);

RESET ROLE;
SELECT set_config('request.jwt.claim.role', 'service_role', true);
SELECT set_config('request.jwt.claims', '{"role":"service_role"}', true);

-- Remove both Studio defaults to verify the documented missing-row behavior.
DELETE FROM public.sales_rollout WHERE entitlement_key = 'studio';
DELETE FROM public.feature_rollout WHERE entitlement_key = 'studio';

SELECT set_config('request.jwt.claim.sub', '25190000-0000-4000-8000-000000000003', true);
SELECT set_config(
  'request.jwt.claims',
  '{"sub":"25190000-0000-4000-8000-000000000003","role":"authenticated"}',
  true
);
SELECT set_config('request.jwt.claim.role', 'authenticated', true);
SET LOCAL ROLE authenticated;

SELECT is(
  public.get_paid_rollout('android')->'studio'->>'sales_rollout',
  'off',
  'missing sales configuration fails closed to off'
);
SELECT is(
  public.get_paid_rollout('android')->'studio'->>'feature_rollout',
  NULL,
  'missing feature configuration leaves valid access unchanged'
);
SELECT is(
  public.get_paid_rollout('android')->'studio'->>'configured',
  'false',
  'missing rollout rows are reported as unconfigured'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
