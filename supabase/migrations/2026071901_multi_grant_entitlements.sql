-- T25.0 (2026-07-19): multi-grant entitlement and benefit-code foundation.
--
-- This migration is deliberately additive. Apple/Google purchases remain out of
-- scope until T25.1+, and applying this file to the live project remains a
-- separate Founder gate. New benefit codes contain only a keyed-HMAC digest;
-- the HMAC secret and raw code stay in the Edge Function boundary.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------
-- Entitlement ledger
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.entitlement_grants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  entitlement_key text NOT NULL
    CONSTRAINT entitlement_grants_key_check
    CHECK (entitlement_key IN ('premium', 'studio')),
  source text NOT NULL
    CONSTRAINT entitlement_grants_source_check
    CHECK (source IN ('revenuecat', 'benefit_code', 'pilot', 'review', 'admin')),
  source_ref text NOT NULL
    CONSTRAINT entitlement_grants_source_ref_nonempty
    CHECK (btrim(source_ref) <> ''),
  status text NOT NULL DEFAULT 'active'
    CONSTRAINT entitlement_grants_status_check
    CHECK (status IN ('active', 'grace', 'expired', 'revoked')),
  store text
    CONSTRAINT entitlement_grants_store_check
    CHECK (store IS NULL OR store IN ('app_store', 'play_store', 'promotional')),
  product_id text,
  starts_at timestamptz NOT NULL DEFAULT now(),
  expires_at timestamptz,
  revoked_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now(),
  is_permanent boolean NOT NULL DEFAULT false,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  CONSTRAINT entitlement_grants_unique_source
    UNIQUE (source, source_ref, entitlement_key),
  CONSTRAINT entitlement_grants_expiry_shape_check CHECK (
    (is_permanent AND expires_at IS NULL)
    OR (NOT is_permanent AND expires_at IS NOT NULL)
  ),
  CONSTRAINT entitlement_grants_revocation_shape_check CHECK (
    (status = 'revoked' AND revoked_at IS NOT NULL)
    OR (status <> 'revoked' AND revoked_at IS NULL)
  ),
  CONSTRAINT entitlement_grants_grace_source_check CHECK (
    status <> 'grace' OR source = 'revenuecat'
  ),
  CONSTRAINT entitlement_grants_metadata_object_check CHECK (
    jsonb_typeof(metadata) = 'object'
  )
);

CREATE INDEX IF NOT EXISTS entitlement_grants_user_key_idx
  ON public.entitlement_grants (user_id, entitlement_key, status, expires_at);

CREATE INDEX IF NOT EXISTS entitlement_grants_active_idx
  ON public.entitlement_grants (user_id, entitlement_key)
  WHERE status IN ('active', 'grace') AND revoked_at IS NULL;

-- ---------------------------------------------------------------------------
-- Benefit campaigns, digest-only codes, and the redemption audit ledger
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.benefit_campaigns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  internal_name text NOT NULL UNIQUE
    CONSTRAINT benefit_campaigns_name_nonempty CHECK (btrim(internal_name) <> ''),
  purpose text NOT NULL
    CONSTRAINT benefit_campaigns_purpose_nonempty CHECK (btrim(purpose) <> ''),
  internal_description text,
  entitlement_key text NOT NULL
    CONSTRAINT benefit_campaigns_entitlement_check
    CHECK (entitlement_key IN ('premium', 'studio')),
  benefit_kind text NOT NULL
    CONSTRAINT benefit_campaigns_kind_check
    CHECK (benefit_kind IN ('internal_grant', 'store_offer')),
  grant_source text
    CONSTRAINT benefit_campaigns_grant_source_check
    CHECK (grant_source IS NULL OR grant_source IN ('benefit_code', 'pilot', 'review', 'admin')),
  grant_type text
    CONSTRAINT benefit_campaigns_grant_type_check
    CHECK (grant_type IS NULL OR grant_type IN ('permanent', 'duration_days', 'fixed_end')),
  duration_days integer
    CONSTRAINT benefit_campaigns_duration_positive CHECK (duration_days IS NULL OR duration_days > 0),
  fixed_end_at timestamptz,
  target_role text NOT NULL DEFAULT 'both'
    CONSTRAINT benefit_campaigns_target_role_check
    CHECK (target_role IN ('user', 'trainer', 'both')),
  eligibility_rules jsonb NOT NULL DEFAULT '{}'::jsonb
    CONSTRAINT benefit_campaigns_eligibility_object_check
    CHECK (jsonb_typeof(eligibility_rules) = 'object')
    CONSTRAINT benefit_campaigns_eligibility_unsupported_check
    CHECK (eligibility_rules = '{}'::jsonb),
  starts_at timestamptz,
  ends_at timestamptz,
  total_redemption_limit integer
    CONSTRAINT benefit_campaigns_total_limit_positive
    CHECK (total_redemption_limit IS NULL OR total_redemption_limit > 0),
  per_account_limit integer NOT NULL DEFAULT 1
    CONSTRAINT benefit_campaigns_account_limit_positive CHECK (per_account_limit > 0),
  -- Campaign creation and campaign activation are separate operator actions.
  -- Omitting the activation field must therefore remain fail-closed.
  is_active boolean NOT NULL DEFAULT false,
  revoked_at timestamptz,
  apple_offer_ref text
    CONSTRAINT benefit_campaigns_apple_offer_nonblank
    CHECK (apple_offer_ref IS NULL OR btrim(apple_offer_ref) <> ''),
  google_offer_ref text
    CONSTRAINT benefit_campaigns_google_offer_nonblank
    CHECK (google_offer_ref IS NULL OR btrim(google_offer_ref) <> ''),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT benefit_campaigns_window_check CHECK (
    starts_at IS NULL OR ends_at IS NULL OR ends_at > starts_at
  ),
  CONSTRAINT benefit_campaigns_revocation_check CHECK (
    revoked_at IS NULL OR NOT is_active
  ),
  -- Internal grants carry access duration, never store-offer references.
  -- Store offers carry only opaque store references, never an internal price.
  CONSTRAINT benefit_campaigns_kind_shape_check CHECK (
    (
      benefit_kind = 'internal_grant'
      AND grant_source IS NOT NULL
      AND grant_type IS NOT NULL
      AND apple_offer_ref IS NULL
      AND google_offer_ref IS NULL
      AND (
        (grant_type = 'permanent' AND duration_days IS NULL AND fixed_end_at IS NULL)
        OR (grant_type = 'duration_days' AND duration_days IS NOT NULL AND fixed_end_at IS NULL)
        OR (grant_type = 'fixed_end' AND duration_days IS NULL AND fixed_end_at IS NOT NULL)
      )
    )
    OR
    (
      benefit_kind = 'store_offer'
      AND grant_source IS NULL
      AND grant_type IS NULL
      AND duration_days IS NULL
      AND fixed_end_at IS NULL
      AND (apple_offer_ref IS NOT NULL OR google_offer_ref IS NOT NULL)
    )
  )
);

CREATE TABLE IF NOT EXISTS public.benefit_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id uuid NOT NULL
    REFERENCES public.benefit_campaigns(id) ON DELETE RESTRICT,
  code_digest text NOT NULL UNIQUE
    CONSTRAINT benefit_codes_hmac_sha256_check
    CHECK (code_digest ~ '^[0-9a-f]{64}$'),
  display_hint text NOT NULL
    CONSTRAINT benefit_codes_hint_check
    CHECK (char_length(display_hint) BETWEEN 2 AND 12),
  usage_type text NOT NULL DEFAULT 'single_use'
    CONSTRAINT benefit_codes_usage_check
    CHECK (usage_type IN ('single_use', 'multi_use')),
  redemption_limit integer NOT NULL DEFAULT 1
    CONSTRAINT benefit_codes_redemption_limit_positive CHECK (redemption_limit > 0),
  is_active boolean NOT NULL DEFAULT true,
  expires_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT benefit_codes_single_use_limit_check CHECK (
    usage_type <> 'single_use' OR redemption_limit = 1
  ),
  CONSTRAINT benefit_codes_revocation_check CHECK (
    revoked_at IS NULL OR NOT is_active
  )
);

CREATE INDEX IF NOT EXISTS benefit_codes_campaign_idx
  ON public.benefit_codes (campaign_id);

CREATE TABLE IF NOT EXISTS public.benefit_redemptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  benefit_code_id uuid NOT NULL
    REFERENCES public.benefit_codes(id) ON DELETE RESTRICT,
  campaign_id uuid NOT NULL
    REFERENCES public.benefit_campaigns(id) ON DELETE RESTRICT,
  entitlement_key text NOT NULL
    CONSTRAINT benefit_redemptions_entitlement_check
    CHECK (entitlement_key IN ('premium', 'studio')),
  -- Keep durable, pseudonym-free consumption after account deletion so global
  -- single-use/code/campaign limits remain consumed. The account link is
  -- nulled and no replacement hash is retained.
  user_id uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  redeemed_at timestamptz NOT NULL DEFAULT now(),
  outcome text NOT NULL
    CONSTRAINT benefit_redemptions_outcome_check
    CHECK (outcome IN ('granted', 'store_offer')),
  grant_id uuid REFERENCES public.entitlement_grants(id) ON DELETE SET NULL,
  platform text NOT NULL DEFAULT 'unknown'
    CONSTRAINT benefit_redemptions_platform_check
    CHECK (platform IN ('ios', 'android', 'unknown')),
  store_offer_ref text
    CONSTRAINT benefit_redemptions_store_offer_ref_nonblank
    CHECK (store_offer_ref IS NULL OR btrim(store_offer_ref) <> ''),
  CONSTRAINT benefit_redemptions_code_user_unique
    UNIQUE (benefit_code_id, user_id),
  CONSTRAINT benefit_redemptions_outcome_shape_check CHECK (
    -- A granted audit row may outlive its deleted entitlement grant.
    (outcome = 'granted' AND store_offer_ref IS NULL)
    OR (
      outcome = 'store_offer'
      AND grant_id IS NULL
      AND platform IN ('ios', 'android')
      AND store_offer_ref IS NOT NULL
    )
  )
);

CREATE INDEX IF NOT EXISTS benefit_redemptions_campaign_idx
  ON public.benefit_redemptions (campaign_id, redeemed_at);

CREATE INDEX IF NOT EXISTS benefit_redemptions_user_idx
  ON public.benefit_redemptions (user_id, redeemed_at DESC);

-- ---------------------------------------------------------------------------
-- Paid-surface rollout. Sales and feature availability are intentionally
-- separate: stopping sales must never revoke an already valid grant.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.sales_rollout (
  entitlement_key text NOT NULL
    CONSTRAINT sales_rollout_entitlement_check
    CHECK (entitlement_key IN ('premium', 'studio')),
  platform text NOT NULL DEFAULT 'all'
    CONSTRAINT sales_rollout_platform_check
    CHECK (platform IN ('all', 'ios', 'android')),
  rollout_state text NOT NULL DEFAULT 'off'
    CONSTRAINT sales_rollout_state_check
    CHECK (rollout_state IN ('off', 'internal', 'cohort', 'public')),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (entitlement_key, platform)
);

CREATE TABLE IF NOT EXISTS public.feature_rollout (
  entitlement_key text NOT NULL
    CONSTRAINT feature_rollout_entitlement_check
    CHECK (entitlement_key IN ('premium', 'studio')),
  platform text NOT NULL DEFAULT 'all'
    CONSTRAINT feature_rollout_platform_check
    CHECK (platform IN ('all', 'ios', 'android')),
  rollout_state text NOT NULL DEFAULT 'public'
    CONSTRAINT feature_rollout_state_check
    CHECK (rollout_state IN ('internal', 'cohort', 'public', 'incident_disabled')),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (entitlement_key, platform)
);

-- Safe initial state: no new paid sales, but valid grants remain usable.
INSERT INTO public.sales_rollout (entitlement_key, platform, rollout_state)
VALUES
  ('premium', 'all', 'off'),
  ('studio', 'all', 'off')
ON CONFLICT (entitlement_key, platform) DO NOTHING;

INSERT INTO public.feature_rollout (entitlement_key, platform, rollout_state)
VALUES
  ('premium', 'all', 'public'),
  ('studio', 'all', 'public')
ON CONFLICT (entitlement_key, platform) DO NOTHING;

-- ---------------------------------------------------------------------------
-- RLS and privileges: owners may read their own ledger/redemptions; paid
-- rollout state is authenticated-read-only; campaign and digest inventories
-- are server-only. There are no client write policies on any T25.0 table.
-- ---------------------------------------------------------------------------

ALTER TABLE public.entitlement_grants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.benefit_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.benefit_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.benefit_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_rollout ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.feature_rollout ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS entitlement_grants_select_own
  ON public.entitlement_grants;
CREATE POLICY entitlement_grants_select_own
  ON public.entitlement_grants FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS benefit_redemptions_select_own
  ON public.benefit_redemptions;
CREATE POLICY benefit_redemptions_select_own
  ON public.benefit_redemptions FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS sales_rollout_authenticated_read
  ON public.sales_rollout;
CREATE POLICY sales_rollout_authenticated_read
  ON public.sales_rollout FOR SELECT
  USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS feature_rollout_authenticated_read
  ON public.feature_rollout;
CREATE POLICY feature_rollout_authenticated_read
  ON public.feature_rollout FOR SELECT
  USING (auth.role() = 'authenticated');

REVOKE ALL ON TABLE public.entitlement_grants FROM anon, authenticated;
REVOKE ALL ON TABLE public.benefit_campaigns FROM anon, authenticated;
REVOKE ALL ON TABLE public.benefit_codes FROM anon, authenticated;
REVOKE ALL ON TABLE public.benefit_redemptions FROM anon, authenticated;
REVOKE ALL ON TABLE public.sales_rollout FROM anon, authenticated;
REVOKE ALL ON TABLE public.feature_rollout FROM anon, authenticated;

GRANT SELECT ON TABLE public.entitlement_grants TO authenticated;
GRANT SELECT ON TABLE public.benefit_redemptions TO authenticated;
GRANT SELECT ON TABLE public.sales_rollout TO authenticated;
GRANT SELECT ON TABLE public.feature_rollout TO authenticated;

-- ---------------------------------------------------------------------------
-- Effective-entitlement evaluation and legacy profile projection
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public._effective_entitlement(
  p_user_id uuid,
  p_entitlement_key text,
  p_at timestamptz DEFAULT now()
)
RETURNS jsonb
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
  WITH eligible AS (
    SELECT g.*
      FROM public.entitlement_grants AS g
     WHERE g.user_id = p_user_id
       AND g.entitlement_key = p_entitlement_key
       AND g.revoked_at IS NULL
       AND g.starts_at <= p_at
       AND (
         g.status = 'active'
         OR (g.status = 'grace' AND g.source = 'revenuecat')
       )
       AND (g.is_permanent OR g.expires_at > p_at)
  ),
  preferred AS (
    SELECT source
      FROM eligible
     ORDER BY
       is_permanent DESC,
       CASE source
         WHEN 'benefit_code' THEN 5
         WHEN 'pilot' THEN 4
         WHEN 'review' THEN 3
         WHEN 'admin' THEN 2
         ELSE 1
       END DESC,
       expires_at DESC NULLS LAST,
       updated_at DESC,
       id
     LIMIT 1
  )
  SELECT jsonb_build_object(
    'is_active', EXISTS (SELECT 1 FROM eligible),
    'expires_at', CASE
      WHEN EXISTS (SELECT 1 FROM eligible WHERE is_permanent) THEN NULL
      ELSE (SELECT max(expires_at) FROM eligible)
    END,
    'is_permanent', EXISTS (SELECT 1 FROM eligible WHERE is_permanent),
    'source', (SELECT source FROM preferred)
  );
$function$;

CREATE OR REPLACE FUNCTION public.get_my_effective_entitlements()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  RETURN jsonb_build_object(
    'premium', public._effective_entitlement(v_user_id, 'premium', now()),
    'studio', public._effective_entitlement(v_user_id, 'studio', now())
  );
END;
$function$;

-- This guard intentionally runs with the invoking SQL role. A projection
-- refresh is SECURITY DEFINER and therefore reaches the nested profile UPDATE
-- as the function owner; direct or indirectly-triggered client updates retain
-- current_user anon/authenticated and are denied at every trigger depth.
CREATE OR REPLACE FUNCTION public.prevent_direct_premium_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $function$
BEGIN
  IF current_user IN ('anon', 'authenticated')
     AND (
       OLD.is_premium IS DISTINCT FROM NEW.is_premium
       OR OLD.premium_type IS DISTINCT FROM NEW.premium_type
       OR OLD.premium_valid_until IS DISTINCT FROM NEW.premium_valid_until
       OR OLD.stripe_customer_id IS DISTINCT FROM NEW.stripe_customer_id
     ) THEN
    RAISE EXCEPTION
      'Changing premium entitlement columns directly is not permitted. '
      'Entitlements are granted server-side only.';
  END IF;
  RETURN NEW;
END;
$function$;

CREATE OR REPLACE FUNCTION public.refresh_legacy_premium_projection(
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_is_active boolean := false;
  v_is_permanent boolean := false;
  v_valid_until timestamptz;
  v_premium_type text;
BEGIN
  WITH eligible AS (
    SELECT g.*
      FROM public.entitlement_grants AS g
     WHERE g.user_id = p_user_id
       AND g.entitlement_key = 'premium'
       AND g.revoked_at IS NULL
       AND g.starts_at <= now()
       AND (
         g.status = 'active'
         OR (g.status = 'grace' AND g.source = 'revenuecat')
       )
       AND (g.is_permanent OR g.expires_at > now())
  )
  SELECT
    count(*) > 0,
    COALESCE(bool_or(is_permanent), false),
    CASE
      WHEN COALESCE(bool_or(is_permanent), false) THEN NULL
      ELSE max(expires_at)
    END
    INTO v_is_active, v_is_permanent, v_valid_until
    FROM eligible;

  IF v_is_active THEN
    WITH eligible AS (
      SELECT
        g.*,
        CASE
          WHEN g.source IN ('benefit_code', 'pilot', 'review') THEN 'code'
          WHEN g.metadata->>'premium_type' IN ('code', 'lifetime', 'yearly', 'monthly')
            THEN g.metadata->>'premium_type'
          WHEN g.metadata->>'product_type' IN ('lifetime', 'yearly', 'monthly')
            THEN g.metadata->>'product_type'
          WHEN g.is_permanent THEN 'lifetime'
          WHEN lower(COALESCE(g.product_id, '')) ~ '(lifetime|one.?time)' THEN 'lifetime'
          WHEN lower(COALESCE(g.product_id, '')) ~ '(year|annual)' THEN 'yearly'
          ELSE 'monthly'
        END AS display_type
      FROM public.entitlement_grants AS g
      WHERE g.user_id = p_user_id
        AND g.entitlement_key = 'premium'
        AND g.revoked_at IS NULL
        AND g.starts_at <= now()
        AND (
          g.status = 'active'
          OR (g.status = 'grace' AND g.source = 'revenuecat')
        )
        AND (g.is_permanent OR g.expires_at > now())
    )
    SELECT display_type
      INTO v_premium_type
      FROM eligible
     ORDER BY
       CASE display_type
         WHEN 'code' THEN 4
         WHEN 'lifetime' THEN 3
         WHEN 'yearly' THEN 2
         ELSE 1
       END DESC,
       is_permanent DESC,
       expires_at DESC NULLS LAST,
       updated_at DESC,
       id
     LIMIT 1;
  END IF;

  UPDATE public.profiles
     SET is_premium = v_is_active,
         premium_type = CASE WHEN v_is_active THEN v_premium_type ELSE NULL END,
         premium_valid_until = CASE
           WHEN v_is_active AND NOT v_is_permanent THEN v_valid_until
           ELSE NULL
         END
   WHERE id = p_user_id;

END;
$function$;

CREATE OR REPLACE FUNCTION public.sync_legacy_premium_projection_from_grant()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF TG_OP = 'DELETE' THEN
    PERFORM public.refresh_legacy_premium_projection(OLD.user_id);
    RETURN OLD;
  END IF;

  IF TG_OP = 'UPDATE' AND OLD.user_id IS DISTINCT FROM NEW.user_id THEN
    PERFORM public.refresh_legacy_premium_projection(OLD.user_id);
  END IF;

  PERFORM public.refresh_legacy_premium_projection(NEW.user_id);
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_sync_legacy_premium_projection
  ON public.entitlement_grants;
CREATE TRIGGER trg_sync_legacy_premium_projection
  AFTER INSERT OR UPDATE OR DELETE ON public.entitlement_grants
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_legacy_premium_projection_from_grant();

REVOKE ALL ON FUNCTION public._effective_entitlement(uuid, text, timestamptz)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.refresh_legacy_premium_projection(uuid)
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.sync_legacy_premium_projection_from_grant()
  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.get_my_effective_entitlements()
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_my_effective_entitlements()
  TO authenticated;

-- ---------------------------------------------------------------------------
-- Paid rollout read RPC. A missing sales row resolves to off. A missing
-- feature row resolves to null, which means "do not change valid access".
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_paid_rollout(
  p_platform text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_platform text := lower(btrim(COALESCE(p_platform, 'unknown')));
  v_result jsonb := '{}'::jsonb;
  v_key text;
  v_sales_state text;
  v_feature_state text;
  v_sales_configured boolean;
  v_feature_configured boolean;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  IF v_platform = '' THEN
    v_platform := 'unknown';
  END IF;
  IF v_platform NOT IN ('ios', 'android', 'unknown') THEN
    RAISE EXCEPTION 'invalid_platform';
  END IF;

  FOREACH v_key IN ARRAY ARRAY['premium', 'studio'] LOOP
    SELECT rollout_state
      INTO v_sales_state
      FROM public.sales_rollout
     WHERE entitlement_key = v_key
       AND platform IN ('all', v_platform)
     ORDER BY CASE WHEN platform = v_platform THEN 0 ELSE 1 END
     LIMIT 1;
    v_sales_configured := FOUND;

    SELECT rollout_state
      INTO v_feature_state
      FROM public.feature_rollout
     WHERE entitlement_key = v_key
       AND platform IN ('all', v_platform)
     ORDER BY CASE WHEN platform = v_platform THEN 0 ELSE 1 END
     LIMIT 1;
    v_feature_configured := FOUND;

    v_result := v_result || jsonb_build_object(
      v_key,
      jsonb_build_object(
        'sales_rollout', COALESCE(v_sales_state, 'off'),
        'feature_rollout', v_feature_state,
        'configured', v_sales_configured AND v_feature_configured,
        'sales_configured', v_sales_configured,
        'feature_configured', v_feature_configured
      )
    );

    v_sales_state := NULL;
    v_feature_state := NULL;
  END LOOP;

  RETURN v_result;
END;
$function$;

REVOKE ALL ON FUNCTION public.get_paid_rollout(text)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_paid_rollout(text)
  TO authenticated;

-- ---------------------------------------------------------------------------
-- Backfill T24 redemptions first, then preserve every other profile currently
-- marked premium. Re-running the migration is a no-op due to stable source
-- references. No existing profile loses access during the transition.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public._backfill_legacy_entitlements()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  INSERT INTO public.entitlement_grants (
    user_id,
    entitlement_key,
    source,
    source_ref,
    status,
    starts_at,
    expires_at,
    is_permanent,
    metadata
  )
  SELECT
    ac.redeemed_by,
    'premium',
    'benefit_code',
    'legacy-access-code:' || ac.id::text,
    'active',
    COALESCE(ac.redeemed_at, ac.created_at, now()),
    NULL,
    true,
    jsonb_build_object(
      'backfill', 't24_access_code',
      'legacy_access_code_id', ac.id,
      'premium_type', 'code'
    )
  FROM public.access_codes AS ac
  WHERE ac.type = 'free'
    AND ac.redeemed_by IS NOT NULL
    AND (ac.redeemed_at IS NOT NULL OR ac.redemption_count > 0)
  ON CONFLICT (source, source_ref, entitlement_key) DO NOTHING;

  INSERT INTO public.entitlement_grants (
    user_id,
    entitlement_key,
    source,
    source_ref,
    status,
    starts_at,
    expires_at,
    is_permanent,
    metadata
  )
  SELECT
    p.id,
    'premium',
    CASE
      WHEN p.premium_type = 'code' THEN 'benefit_code'
      ELSE 'admin'
    END,
    'legacy-profile:' || p.id::text,
    CASE
      WHEN COALESCE(p.premium_type, 'monthly') NOT IN ('code', 'lifetime')
           AND p.premium_valid_until IS NOT NULL
           AND p.premium_valid_until <= now() THEN 'expired'
      ELSE 'active'
    END,
    COALESCE(p.created_at, now()),
    CASE
      WHEN p.premium_type IN ('code', 'lifetime') THEN NULL
      ELSE p.premium_valid_until
    END,
    COALESCE(p.premium_type IN ('code', 'lifetime'), false)
      OR p.premium_valid_until IS NULL,
    jsonb_build_object(
      'backfill', 'legacy_profile_projection',
      'premium_type', p.premium_type
    )
  FROM public.profiles AS p
  WHERE p.is_premium
    AND NOT EXISTS (
      SELECT 1
        FROM public.entitlement_grants AS g
       WHERE g.user_id = p.id
         AND g.entitlement_key = 'premium'
         AND g.revoked_at IS NULL
         AND g.status IN ('active', 'grace')
         AND (g.is_permanent OR g.expires_at > now())
    )
  ON CONFLICT (source, source_ref, entitlement_key) DO NOTHING;
END;
$function$;

REVOKE ALL ON FUNCTION public._backfill_legacy_entitlements()
  FROM PUBLIC, anon, authenticated;

SELECT public._backfill_legacy_entitlements();

-- ---------------------------------------------------------------------------
-- Atomic legacy/new code redemption. The Edge Function calls HMAC-first with
-- p_code = NULL. Only a distinct benefit_code_not_found response permits a
-- second raw-only legacy lookup, keeping valid T25 raw codes out of the DB.
-- ---------------------------------------------------------------------------

DROP FUNCTION IF EXISTS public.redeem_access_code(text, uuid);

CREATE OR REPLACE FUNCTION public.redeem_access_code(
  p_code text,
  p_user_id uuid,
  p_code_hmac text DEFAULT NULL,
  p_platform text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_now timestamptz := now();
  v_normalized text := upper(btrim(COALESCE(p_code, '')));
  v_digest text := lower(btrim(COALESCE(p_code_hmac, '')));
  v_platform text := lower(btrim(COALESCE(p_platform, 'unknown')));
  v_role text;
  v_legacy_code public.access_codes%ROWTYPE;
  v_benefit_code public.benefit_codes%ROWTYPE;
  v_campaign public.benefit_campaigns%ROWTYPE;
  v_existing_redemption public.benefit_redemptions%ROWTYPE;
  v_existing_grant public.entitlement_grants%ROWTYPE;
  v_redemption_id uuid := gen_random_uuid();
  v_grant_id uuid;
  v_expires_at timestamptz;
  v_store_offer_ref text;
  v_is_permanent boolean := false;
  v_code_redemptions integer;
  v_campaign_redemptions integer;
  v_account_redemptions integer;
BEGIN
  IF auth.role() IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  SELECT role
    INTO v_role
    FROM public.profiles
   WHERE id = p_user_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  IF v_platform = '' THEN
    v_platform := 'unknown';
  END IF;
  IF v_platform NOT IN ('ios', 'android', 'unknown') THEN
    RAISE EXCEPTION 'invalid_platform';
  END IF;

  IF v_digest <> '' AND v_digest !~ '^[0-9a-f]{64}$' THEN
    RAISE EXCEPTION 'invalid_code';
  END IF;

  IF v_digest <> '' THEN
    SELECT *
      INTO v_benefit_code
      FROM public.benefit_codes
     WHERE code_digest = v_digest
     FOR UPDATE;

    IF v_benefit_code.id IS NULL THEN
      RAISE EXCEPTION 'benefit_code_not_found';
    END IF;
  END IF;

  IF v_benefit_code.id IS NOT NULL THEN
    SELECT *
      INTO v_existing_redemption
      FROM public.benefit_redemptions
     WHERE benefit_code_id = v_benefit_code.id
       AND user_id = p_user_id
     FOR UPDATE;

    -- A committed success must be safely replayable when the HTTP response is
    -- lost. Resolve it before current code/campaign/role gates: stopping future
    -- redemption never changes the result already issued to this account.
    IF v_existing_redemption.id IS NOT NULL THEN
      SELECT *
        INTO v_campaign
        FROM public.benefit_campaigns
       WHERE id = v_existing_redemption.campaign_id
       FOR UPDATE;

      IF v_existing_redemption.outcome = 'store_offer' THEN
        IF v_existing_redemption.platform <> v_platform THEN
          RAISE EXCEPTION 'already_redeemed';
        END IF;

        RETURN jsonb_build_object(
          'success', true,
          'benefit_kind', 'store_offer',
          'entitlement_key', v_existing_redemption.entitlement_key,
          'expires_at', NULL,
          'is_permanent', false,
          'source', NULL,
          'grant_id', NULL,
          'redeemed_at', v_existing_redemption.redeemed_at,
          'apple_offer_ref', CASE
            WHEN v_existing_redemption.platform = 'ios'
              THEN v_existing_redemption.store_offer_ref
            ELSE NULL
          END,
          'google_offer_ref', CASE
            WHEN v_existing_redemption.platform = 'android'
              THEN v_existing_redemption.store_offer_ref
            ELSE NULL
          END
        );
      END IF;

      IF v_existing_redemption.grant_id IS NULL THEN
        RAISE EXCEPTION 'already_redeemed';
      END IF;

      SELECT *
        INTO v_existing_grant
        FROM public.entitlement_grants
       WHERE id = v_existing_redemption.grant_id
         AND user_id = p_user_id;

      IF v_existing_grant.id IS NULL
         OR v_existing_grant.revoked_at IS NOT NULL
         OR v_existing_grant.status NOT IN ('active', 'grace')
         OR v_existing_grant.starts_at > v_now
         OR (
           NOT v_existing_grant.is_permanent
           AND v_existing_grant.expires_at <= v_now
         ) THEN
        RAISE EXCEPTION 'already_redeemed';
      END IF;

      RETURN jsonb_build_object(
        'success', true,
        'benefit_kind', 'internal_grant',
        'entitlement_key', v_existing_grant.entitlement_key,
        'expires_at', v_existing_grant.expires_at,
        'is_permanent', v_existing_grant.is_permanent,
        'source', v_existing_grant.source,
        'grant_id', v_existing_grant.id,
        'redeemed_at', v_existing_redemption.redeemed_at,
        'apple_offer_ref', NULL,
        'google_offer_ref', NULL
      );
    END IF;
  END IF;

  IF v_benefit_code.id IS NOT NULL THEN
    IF NOT v_benefit_code.is_active OR v_benefit_code.revoked_at IS NOT NULL THEN
      RAISE EXCEPTION 'benefit_code_inactive';
    END IF;
    IF v_benefit_code.expires_at IS NOT NULL
       AND v_benefit_code.expires_at <= v_now THEN
      RAISE EXCEPTION 'expired_code';
    END IF;

    SELECT *
      INTO v_campaign
      FROM public.benefit_campaigns
     WHERE id = v_benefit_code.campaign_id
     FOR UPDATE;

    IF v_campaign.id IS NULL
       OR NOT v_campaign.is_active
       OR v_campaign.revoked_at IS NOT NULL
       OR (v_campaign.starts_at IS NOT NULL AND v_campaign.starts_at > v_now)
       OR (v_campaign.ends_at IS NOT NULL AND v_campaign.ends_at <= v_now) THEN
      RAISE EXCEPTION 'campaign_inactive';
    END IF;

    IF (v_campaign.target_role = 'user' AND v_role <> 'practitioner')
       OR (v_campaign.target_role = 'trainer' AND v_role <> 'trainer')
       OR (v_campaign.target_role = 'both' AND v_role NOT IN ('practitioner', 'trainer')) THEN
      RAISE EXCEPTION 'role_not_eligible';
    END IF;

    SELECT count(*)::integer
      INTO v_code_redemptions
      FROM public.benefit_redemptions
     WHERE benefit_code_id = v_benefit_code.id;

    IF v_code_redemptions >= v_benefit_code.redemption_limit THEN
      RAISE EXCEPTION 'redemption_limit_reached';
    END IF;

    SELECT count(*)::integer
      INTO v_campaign_redemptions
      FROM public.benefit_redemptions
     WHERE campaign_id = v_campaign.id;

    IF v_campaign.total_redemption_limit IS NOT NULL
       AND v_campaign_redemptions >= v_campaign.total_redemption_limit THEN
      RAISE EXCEPTION 'redemption_limit_reached';
    END IF;

    SELECT count(*)::integer
      INTO v_account_redemptions
      FROM public.benefit_redemptions
     WHERE campaign_id = v_campaign.id
       AND user_id = p_user_id;

    IF v_account_redemptions >= v_campaign.per_account_limit THEN
      RAISE EXCEPTION 'redemption_limit_reached';
    END IF;

    IF v_campaign.benefit_kind = 'store_offer' THEN
      IF v_platform = 'unknown'
         OR (v_platform = 'ios' AND v_campaign.apple_offer_ref IS NULL)
         OR (v_platform = 'android' AND v_campaign.google_offer_ref IS NULL) THEN
        RAISE EXCEPTION 'offer_unavailable';
      END IF;

      v_store_offer_ref := CASE v_platform
        WHEN 'ios' THEN v_campaign.apple_offer_ref
        WHEN 'android' THEN v_campaign.google_offer_ref
      END;

      INSERT INTO public.benefit_redemptions (
        id,
        benefit_code_id,
        campaign_id,
        entitlement_key,
        user_id,
        redeemed_at,
        outcome,
        grant_id,
        platform,
        store_offer_ref
      ) VALUES (
        v_redemption_id,
        v_benefit_code.id,
        v_campaign.id,
        v_campaign.entitlement_key,
        p_user_id,
        v_now,
        'store_offer',
        NULL,
        v_platform,
        v_store_offer_ref
      );

      RETURN jsonb_build_object(
        'success', true,
        'benefit_kind', 'store_offer',
        'entitlement_key', v_campaign.entitlement_key,
        'expires_at', NULL,
        'is_permanent', false,
        'source', NULL,
        'grant_id', NULL,
        'redeemed_at', v_now,
        'apple_offer_ref', CASE
          WHEN v_platform = 'ios' THEN v_store_offer_ref
          ELSE NULL
        END,
        'google_offer_ref', CASE
          WHEN v_platform = 'android' THEN v_store_offer_ref
          ELSE NULL
        END
      );
    END IF;

    IF v_campaign.grant_type = 'permanent' THEN
      v_is_permanent := true;
      v_expires_at := NULL;
    ELSIF v_campaign.grant_type = 'duration_days' THEN
      v_expires_at := v_now + make_interval(days => v_campaign.duration_days);
    ELSIF v_campaign.grant_type = 'fixed_end' THEN
      IF v_campaign.fixed_end_at <= v_now THEN
        RAISE EXCEPTION 'campaign_inactive';
      END IF;
      v_expires_at := v_campaign.fixed_end_at;
    ELSE
      RAISE EXCEPTION 'campaign_inactive';
    END IF;

    v_grant_id := gen_random_uuid();

    -- Insert the grant first, then its audit row, in the same transaction.
    -- A grant source_ref uses the pre-generated redemption ID, but no raw code.
    INSERT INTO public.entitlement_grants (
      id,
      user_id,
      entitlement_key,
      source,
      source_ref,
      status,
      starts_at,
      expires_at,
      is_permanent,
      metadata
    ) VALUES (
      v_grant_id,
      p_user_id,
      v_campaign.entitlement_key,
      v_campaign.grant_source,
      'benefit-redemption:' || v_redemption_id::text,
      'active',
      v_now,
      v_expires_at,
      v_is_permanent,
      jsonb_build_object(
        'campaign_id', v_campaign.id,
        'benefit_code_id', v_benefit_code.id
      )
    );

    INSERT INTO public.benefit_redemptions (
      id,
      benefit_code_id,
      campaign_id,
      entitlement_key,
      user_id,
      redeemed_at,
      outcome,
      grant_id,
      platform
    ) VALUES (
      v_redemption_id,
      v_benefit_code.id,
      v_campaign.id,
      v_campaign.entitlement_key,
      p_user_id,
      v_now,
      'granted',
      v_grant_id,
      v_platform
    );

    RETURN jsonb_build_object(
      'success', true,
      'benefit_kind', 'internal_grant',
      'entitlement_key', v_campaign.entitlement_key,
      'expires_at', v_expires_at,
      'is_permanent', v_is_permanent,
      'source', v_campaign.grant_source,
      'grant_id', v_grant_id,
      'redeemed_at', v_now,
      'apple_offer_ref', NULL,
      'google_offer_ref', NULL
    );
  END IF;

  -- T24 compatibility path. Existing cleartext access codes remain readable
  -- only here and are never copied into the new benefit_codes table.
  IF v_normalized = '' THEN
    RAISE EXCEPTION 'invalid_code';
  END IF;

  SELECT *
    INTO v_legacy_code
    FROM public.access_codes
   WHERE upper(code) = v_normalized
   LIMIT 1
   FOR UPDATE;

  IF v_legacy_code.id IS NULL THEN
    RAISE EXCEPTION 'invalid_code';
  END IF;
  IF v_legacy_code.expires_at IS NOT NULL
     AND v_legacy_code.expires_at <= v_now THEN
    RAISE EXCEPTION 'expired_code';
  END IF;
  IF v_legacy_code.redemption_count > 0
     OR v_legacy_code.redeemed_at IS NOT NULL THEN
    RAISE EXCEPTION 'already_redeemed';
  END IF;
  IF v_legacy_code.type <> 'free' THEN
    RAISE EXCEPTION 'unsupported_code_type';
  END IF;

  UPDATE public.access_codes
     SET redemption_count = 1,
         redeemed_by = p_user_id,
         redeemed_at = v_now
   WHERE id = v_legacy_code.id;

  INSERT INTO public.entitlement_grants (
    user_id,
    entitlement_key,
    source,
    source_ref,
    status,
    starts_at,
    expires_at,
    is_permanent,
    metadata
  ) VALUES (
    p_user_id,
    'premium',
    'benefit_code',
    'legacy-access-code:' || v_legacy_code.id::text,
    'active',
    v_now,
    NULL,
    true,
    jsonb_build_object(
      'legacy_access_code_id', v_legacy_code.id,
      'premium_type', 'code'
    )
  )
  ON CONFLICT (source, source_ref, entitlement_key) DO NOTHING
  RETURNING id INTO v_grant_id;

  IF v_grant_id IS NULL THEN
    SELECT id
      INTO v_grant_id
      FROM public.entitlement_grants
     WHERE source = 'benefit_code'
       AND source_ref = 'legacy-access-code:' || v_legacy_code.id::text
       AND entitlement_key = 'premium';
    PERFORM public.refresh_legacy_premium_projection(p_user_id);
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'benefit_kind', 'internal_grant',
    'entitlement_key', 'premium',
    'expires_at', NULL,
    'is_permanent', true,
    'source', 'benefit_code',
    'grant_id', v_grant_id,
    'redeemed_at', v_now,
    'premium_type', 'code',
    'apple_offer_ref', NULL,
    'google_offer_ref', NULL
  );
END;
$function$;

REVOKE ALL ON FUNCTION public.redeem_access_code(text, uuid, text, text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.redeem_access_code(text, uuid, text, text)
  TO service_role;
