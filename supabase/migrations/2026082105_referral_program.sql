-- Referral program (invite + impact visual MVP).
-- Stage-1 only: no entitlement_grants, no benefit_campaigns, no benefit_codes.
-- Access is SECURITY DEFINER RPCs only — RLS enabled, zero policies, REVOKE ALL
-- from anon/authenticated (same posture as benefit_codes inventory tables).

-- ---------------------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.referral_codes (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  code text NOT NULL UNIQUE
    CONSTRAINT referral_codes_code_shape_check
    CHECK (code ~ '^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{8}$'),
  is_active boolean NOT NULL DEFAULT true,
  share_action_tapped_count integer NOT NULL DEFAULT 0
    CONSTRAINT referral_codes_share_count_check CHECK (share_action_tapped_count >= 0),
  landing_view_count integer NOT NULL DEFAULT 0
    CONSTRAINT referral_codes_landing_count_check CHECK (landing_view_count >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.referrals (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  inviter_user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  invitee_user_id uuid UNIQUE REFERENCES public.profiles(id) ON DELETE SET NULL,
  code text NOT NULL,
  status text NOT NULL DEFAULT 'pending'
    CONSTRAINT referrals_status_check CHECK (status IN ('pending', 'activated', 'blocked')),
  created_at timestamptz NOT NULL DEFAULT now(),
  activated_at timestamptz,
  blocked_at timestamptz,
  blocked_reason text,
  CONSTRAINT referrals_no_self_check
    CHECK (invitee_user_id IS NULL OR invitee_user_id <> inviter_user_id),
  CONSTRAINT referrals_activation_shape_check
    CHECK ((status = 'activated') = (activated_at IS NOT NULL)),
  CONSTRAINT referrals_block_shape_check
    CHECK ((status = 'blocked') = (blocked_at IS NOT NULL))
);

CREATE INDEX IF NOT EXISTS referrals_inviter_status_idx
  ON public.referrals (inviter_user_id, status);

ALTER TABLE public.referral_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.referral_codes FROM anon, authenticated;
REVOKE ALL ON TABLE public.referrals FROM anon, authenticated;

-- ---------------------------------------------------------------------------
-- Internal code generator (alphabet + length match trainer activation codes)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public._referral_code()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_chars text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_code text := '';
  i int;
BEGIN
  FOR i IN 1..8 LOOP
    v_code := v_code || substr(v_chars, 1 + floor(random() * length(v_chars))::int, 1);
  END LOOP;
  RETURN v_code;
END;
$$;

REVOKE ALL ON FUNCTION public._referral_code() FROM PUBLIC, anon, authenticated;

-- ---------------------------------------------------------------------------
-- get_my_invite_overview — create personal code on first call
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_my_invite_overview()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_code text;
  v_activated integer;
  v_attempts int := 0;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  SELECT rc.code
    INTO v_code
    FROM public.referral_codes rc
   WHERE rc.user_id = v_uid;

  IF v_code IS NULL THEN
    LOOP
      v_attempts := v_attempts + 1;
      IF v_attempts > 20 THEN
        RAISE EXCEPTION 'referral_code_generation_failed';
      END IF;

      v_code := public._referral_code();

      BEGIN
        INSERT INTO public.referral_codes (user_id, code, updated_at)
        VALUES (v_uid, v_code, now());
        EXIT;
      EXCEPTION
        WHEN unique_violation THEN
          -- Collision on code (or rare concurrent insert for same user): retry.
          SELECT rc.code
            INTO v_code
            FROM public.referral_codes rc
           WHERE rc.user_id = v_uid;
          IF v_code IS NOT NULL THEN
            EXIT;
          END IF;
      END;
    END LOOP;
  END IF;

  SELECT count(*)::integer
    INTO v_activated
    FROM public.referrals r
   WHERE r.inviter_user_id = v_uid
     AND r.status = 'activated';

  RETURN jsonb_build_object(
    'code', v_code,
    'activated_count', COALESCE(v_activated, 0)
  );
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_invite_overview()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_invite_overview() TO authenticated;

-- ---------------------------------------------------------------------------
-- redeem_invite_code — single machine-readable field `result`, never auto-redeem
-- Contract: {"result": "accepted"|"unknown_code"|"code_inactive"|"own_code"|
--           "already_referred"|"account_too_old"}
-- If the invitee already has a completed training session, the row is inserted
-- as activated (the AFTER-session trigger would otherwise have already fired).
--
-- Race with activate_referral_on_first_completed_session:
-- A concurrent completed-session sync can fire the trigger between our
-- "already trained?" check and the INSERT. Both paths take the same
-- transaction-scoped advisory lock on the invitee id so one of them always
-- sees the other's write:
--   • redeem first → inserts pending; trigger then activates it
--   • trigger first → no row yet; redeem then inserts activated
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.redeem_invite_code(p_code text)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_normalized text := upper(btrim(COALESCE(p_code, '')));
  v_row public.referral_codes%ROWTYPE;
  v_profile_created timestamptz;
  v_already_trained boolean;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  IF v_normalized !~ '^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{8}$' THEN
    RETURN jsonb_build_object('result', 'unknown_code');
  END IF;

  SELECT *
    INTO v_row
    FROM public.referral_codes
   WHERE code = v_normalized
   FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'unknown_code');
  END IF;

  IF NOT v_row.is_active THEN
    RETURN jsonb_build_object('result', 'code_inactive');
  END IF;

  IF v_row.user_id = v_uid THEN
    RETURN jsonb_build_object('result', 'own_code');
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.referrals r WHERE r.invitee_user_id = v_uid
  ) THEN
    RETURN jsonb_build_object('result', 'already_referred');
  END IF;

  SELECT p.created_at
    INTO v_profile_created
    FROM public.profiles p
   WHERE p.id = v_uid;

  IF v_profile_created IS NULL
     OR v_profile_created <= (now() - interval '30 days') THEN
    RETURN jsonb_build_object('result', 'account_too_old');
  END IF;

  -- Serialize with activate_referral_on_first_completed_session for this invitee.
  -- Lock namespace 87201405 = 'referral_invitee' (stable int4 key).
  PERFORM pg_advisory_xact_lock(87201405, hashtext(v_uid::text));

  SELECT EXISTS (
    SELECT 1
      FROM public.training_sessions ts
     WHERE ts.user_id = v_uid
       AND ts.is_completed IS TRUE
  ) INTO v_already_trained;

  BEGIN
    IF v_already_trained THEN
      INSERT INTO public.referrals (
        inviter_user_id, invitee_user_id, code, status, activated_at
      ) VALUES (
        v_row.user_id, v_uid, v_normalized, 'activated', now()
      );
    ELSE
      INSERT INTO public.referrals (
        inviter_user_id, invitee_user_id, code, status
      ) VALUES (
        v_row.user_id, v_uid, v_normalized, 'pending'
      );
    END IF;
  EXCEPTION
    WHEN unique_violation THEN
      RETURN jsonb_build_object('result', 'already_referred');
  END;

  RETURN jsonb_build_object('result', 'accepted');
END;
$$;

REVOKE ALL ON FUNCTION public.redeem_invite_code(text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.redeem_invite_code(text) TO authenticated;

-- ---------------------------------------------------------------------------
-- Share-button tap counter (button press, not a completed share)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.log_invite_share_action_tapped()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated';
  END IF;

  UPDATE public.referral_codes
     SET share_action_tapped_count = share_action_tapped_count + 1,
         updated_at = now()
   WHERE user_id = v_uid;
END;
$$;

REVOKE ALL ON FUNCTION public.log_invite_share_action_tapped()
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.log_invite_share_action_tapped() TO authenticated;

-- ---------------------------------------------------------------------------
-- Landing-page view counter (callable by anon; inflate-able by design)
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.log_invite_landing_view(p_code text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_normalized text := upper(btrim(COALESCE(p_code, '')));
BEGIN
  IF v_normalized !~ '^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{8}$' THEN
    RETURN;
  END IF;

  UPDATE public.referral_codes
     SET landing_view_count = landing_view_count + 1,
         updated_at = now()
   WHERE code = v_normalized
     AND is_active IS TRUE;
END;
$$;

REVOKE ALL ON FUNCTION public.log_invite_landing_view(text)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.log_invite_landing_view(text) TO anon, authenticated;

-- Activation trigger — first completed training session, idempotent on pending.
-- Shares pg_advisory_xact_lock(87201405, hashtext(invitee)) with
-- redeem_invite_code so a concurrent redeem cannot insert pending after this
-- trigger has already looked for (and missed) a referral row.
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.activate_referral_on_first_completed_session()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.is_completed IS TRUE THEN
    -- Same lock key as redeem_invite_code for this invitee (see comment there).
    PERFORM pg_advisory_xact_lock(87201405, hashtext(NEW.user_id::text));

    UPDATE public.referrals
       SET status = 'activated',
           activated_at = now()
     WHERE invitee_user_id = NEW.user_id
       AND status = 'pending';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.activate_referral_on_first_completed_session()
  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS activate_referral_after_completed_session
  ON public.training_sessions;

CREATE TRIGGER activate_referral_after_completed_session
  AFTER INSERT OR UPDATE OF is_completed ON public.training_sessions
  FOR EACH ROW
  WHEN (NEW.is_completed)
  EXECUTE FUNCTION public.activate_referral_on_first_completed_session();
