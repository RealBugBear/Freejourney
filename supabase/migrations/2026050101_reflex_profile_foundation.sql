-- Reflexprofil foundation.
-- The expert questionnaire content is intentionally not hardcoded here.
-- This table stores versioned status, answers and future scores so the expert
-- questionnaire can be added without changing onboarding semantics.

CREATE TABLE IF NOT EXISTS public.reflex_profile_assessments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  package_id text REFERENCES public.reflex_packages(id),
  questionnaire_version text NOT NULL DEFAULT 'pending_expert_v1',
  status text NOT NULL CHECK (status IN ('skipped', 'completed')),
  answers jsonb NOT NULL DEFAULT '{}'::jsonb,
  scores jsonb NOT NULL DEFAULT '{}'::jsonb,
  skipped_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (
    (status = 'skipped' AND skipped_at IS NOT NULL)
    OR (status = 'completed' AND completed_at IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_reflex_profile_assessments_user_created
  ON public.reflex_profile_assessments(user_id, created_at DESC);

ALTER TABLE public.reflex_profile_assessments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS reflex_profile_assessments_select_own
  ON public.reflex_profile_assessments;
CREATE POLICY reflex_profile_assessments_select_own
  ON public.reflex_profile_assessments FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS reflex_profile_assessments_insert_own
  ON public.reflex_profile_assessments;
CREATE POLICY reflex_profile_assessments_insert_own
  ON public.reflex_profile_assessments FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.record_reflex_profile_skip(
  p_package_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_assessment_id uuid;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt.';
  END IF;

  INSERT INTO public.reflex_profile_assessments (
    user_id,
    package_id,
    status,
    skipped_at
  )
  VALUES (
    v_user_id,
    p_package_id,
    'skipped',
    now()
  )
  RETURNING id INTO v_assessment_id;

  RETURN v_assessment_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_latest_reflex_profile_assessment()
RETURNS TABLE (
  id uuid,
  package_id text,
  questionnaire_version text,
  status text,
  answers jsonb,
  scores jsonb,
  skipped_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    rpa.id,
    rpa.package_id,
    rpa.questionnaire_version,
    rpa.status,
    rpa.answers,
    rpa.scores,
    rpa.skipped_at,
    rpa.completed_at,
    rpa.created_at
  FROM public.reflex_profile_assessments rpa
  WHERE rpa.user_id = auth.uid()
  ORDER BY rpa.created_at DESC
  LIMIT 1;
$$;

REVOKE ALL ON FUNCTION public.record_reflex_profile_skip(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.record_reflex_profile_skip(text) TO authenticated;

REVOKE ALL ON FUNCTION public.get_latest_reflex_profile_assessment() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_latest_reflex_profile_assessment() TO authenticated;

COMMENT ON TABLE public.reflex_profile_assessments
  IS 'Versioned Reflexprofil status, answers and future scores. Not diagnostic.';
