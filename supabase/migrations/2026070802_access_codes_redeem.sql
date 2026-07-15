-- T24 (2026-07-08): Founding access-code redemption flow.
-- Extends access_codes with redemption metadata and adds an atomic,
-- server-side redemption RPC used by the redeem-access-code Edge Function.
-- RLS stays deny-all for clients (0 policies on access_codes).

ALTER TABLE public.access_codes
  ADD COLUMN IF NOT EXISTS redeemed_by uuid
    REFERENCES public.profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS redeemed_at timestamptz,
  ADD COLUMN IF NOT EXISTS grants jsonb NOT NULL
    DEFAULT '{"premium": true, "premium_type": "code"}'::jsonb;

CREATE OR REPLACE FUNCTION public.redeem_access_code(
  p_code text,
  p_user_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_code public.access_codes%ROWTYPE;
  v_now timestamptz := now();
  v_normalized text := upper(trim(p_code));
BEGIN
  IF v_normalized IS NULL OR v_normalized = '' THEN
    RAISE EXCEPTION 'invalid_code';
  END IF;

  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  SELECT *
    INTO v_code
    FROM public.access_codes
   WHERE upper(code) = v_normalized
   LIMIT 1
   FOR UPDATE;

  IF v_code.id IS NULL THEN
    RAISE EXCEPTION 'invalid_code';
  END IF;

  IF v_code.expires_at IS NOT NULL AND v_code.expires_at < v_now THEN
    RAISE EXCEPTION 'expired_code';
  END IF;

  -- Founding codes are one-time grants per code.
  IF v_code.redemption_count > 0 OR v_code.redeemed_at IS NOT NULL THEN
    RAISE EXCEPTION 'already_redeemed';
  END IF;

  -- T24 scope intentionally excludes discount logic.
  IF v_code.type <> 'free' THEN
    RAISE EXCEPTION 'unsupported_code_type';
  END IF;

  UPDATE public.access_codes
     SET redemption_count = 1,
         redeemed_by = p_user_id,
         redeemed_at = v_now
   WHERE id = v_code.id;

  UPDATE public.profiles
     SET is_premium = true,
         premium_type = 'code',
         premium_valid_until = NULL
   WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'unauthorized';
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'premium_type', 'code',
    'redeemed_at', v_now
  );
END;
$function$;
