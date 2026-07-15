-- ============================================================================
-- experience_shares baseline (launch tracker T08)
--
-- Purpose:
--   Encode the pre-existing live state of public.experience_shares and
--   public.moderator_delete_experience_share into the migrations pipeline.
--
-- Source of truth:
--   Live catalog dump via Supabase Management API on 2026-07-08
--   (columns, constraints, indexes/PK, pg_policies, pg_get_functiondef).
--
-- Safety:
--   Idempotent. On production this migration is effectively a no-op because
--   these objects already exist; it exists to keep repo and DB in sync.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.experience_shares (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  package_id text NOT NULL,
  mood_checkin_id uuid REFERENCES public.mood_checkins(id) ON DELETE SET NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  is_anonymous boolean NOT NULL DEFAULT false,
  content text,
  mood smallint,
  energy smallint,
  stress smallint,
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.experience_shares ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'experience_shares_mood_check'
      AND conrelid = 'public.experience_shares'::regclass
  ) THEN
    ALTER TABLE public.experience_shares
      ADD CONSTRAINT experience_shares_mood_check
      CHECK ((mood IS NULL) OR ((mood >= 1) AND (mood <= 5)));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'experience_shares_energy_check'
      AND conrelid = 'public.experience_shares'::regclass
  ) THEN
    ALTER TABLE public.experience_shares
      ADD CONSTRAINT experience_shares_energy_check
      CHECK ((energy IS NULL) OR ((energy >= 1) AND (energy <= 5)));
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'experience_shares_stress_check'
      AND conrelid = 'public.experience_shares'::regclass
  ) THEN
    ALTER TABLE public.experience_shares
      ADD CONSTRAINT experience_shares_stress_check
      CHECK ((stress IS NULL) OR ((stress >= 1) AND (stress <= 5)));
  END IF;
END $$;

DROP POLICY IF EXISTS shares_read ON public.experience_shares;
CREATE POLICY shares_read
  ON public.experience_shares
  FOR SELECT
  USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS shares_insert ON public.experience_shares;
CREATE POLICY shares_insert
  ON public.experience_shares
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS shares_delete_own ON public.experience_shares;
CREATE POLICY shares_delete_own
  ON public.experience_shares
  FOR DELETE
  USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.moderator_delete_experience_share(share_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_package_id TEXT;
  v_share_owner UUID;
BEGIN
  SELECT package_id, user_id INTO v_package_id, v_share_owner
    FROM public.experience_shares WHERE id = share_id;

  IF v_share_owner IS NULL THEN
    RETURN; -- share not found
  END IF;

  -- Allow if caller owns the share
  IF v_share_owner = auth.uid() THEN
    DELETE FROM public.experience_shares WHERE id = share_id;
    RETURN;
  END IF;

  -- Allow if caller is moderator of the community channel for this package
  IF EXISTS (
    SELECT 1
    FROM   public.chat_channels cc
    JOIN   public.chat_channel_members ccm ON ccm.channel_id = cc.id
    WHERE  cc.package_id  = v_package_id
      AND  cc.type        = 'community'
      AND  ccm.user_id    = auth.uid()
      AND  ccm.role       = 'moderator'
  ) THEN
    DELETE FROM public.experience_shares WHERE id = share_id;
  END IF;
END;
$function$;
