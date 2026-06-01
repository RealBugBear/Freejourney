-- Migration: age snapshot on assessments + birth_date on subject profiles
-- Run in Supabase SQL editor (dev project first, then prod)

-- 1. Age snapshot columns on reflex_profile_assessments
ALTER TABLE public.reflex_profile_assessments
  ADD COLUMN IF NOT EXISTS age_years_at_assessment  int,
  ADD COLUMN IF NOT EXISTS age_months_at_assessment int,
  ADD COLUMN IF NOT EXISTS age_group_at_assessment  text;

-- 2. Replace submit_reflex_profile_assessment to compute age snapshot from birth_date
CREATE OR REPLACE FUNCTION public.submit_reflex_profile_assessment(
  p_subject_profile_id      uuid,
  p_package_id              text,
  p_questionnaire_type      text,
  p_questionnaire_version   text,
  p_answers                 jsonb,
  p_scores                  jsonb,
  p_warning_confirmations   jsonb DEFAULT '[]'::jsonb,
  p_safety_status           text  DEFAULT 'clear'
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id     uuid := auth.uid();
  v_assessment_id uuid;
  v_birth_date  date;
  v_age_months  int;
  v_age_years   int;
  v_age_group   text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt.';
  END IF;

  IF p_subject_profile_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.reflex_subject_profiles rsp
    WHERE rsp.id = p_subject_profile_id
      AND rsp.owner_user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Profil nicht gefunden.';
  END IF;

  -- Compute age at time of assessment from birth_date
  IF p_subject_profile_id IS NOT NULL THEN
    SELECT birth_date INTO v_birth_date
    FROM public.reflex_subject_profiles
    WHERE id = p_subject_profile_id;

    IF v_birth_date IS NOT NULL THEN
      v_age_months := (
        EXTRACT(YEAR  FROM AGE(CURRENT_DATE, v_birth_date))::int * 12 +
        EXTRACT(MONTH FROM AGE(CURRENT_DATE, v_birth_date))::int
      );
      v_age_years := v_age_months / 12;
      v_age_group := CASE
        WHEN v_age_years <= 2  THEN '0-2'
        WHEN v_age_years <= 4  THEN '3-4'
        WHEN v_age_years <= 7  THEN '5-7'
        WHEN v_age_years <= 10 THEN '8-10'
        WHEN v_age_years <= 13 THEN '11-13'
        WHEN v_age_years <= 17 THEN '14-17'
        ELSE '18+'
      END;
    END IF;
  END IF;

  INSERT INTO public.reflex_profile_assessments (
    user_id,
    subject_profile_id,
    package_id,
    questionnaire_type,
    questionnaire_version,
    scoring_version,
    status,
    answers,
    scores,
    warning_confirmations,
    safety_status,
    completed_at,
    age_years_at_assessment,
    age_months_at_assessment,
    age_group_at_assessment
  )
  VALUES (
    v_user_id,
    p_subject_profile_id,
    p_package_id,
    p_questionnaire_type,
    p_questionnaire_version,
    'score_equal_weight_v1',
    'completed',
    COALESCE(p_answers, '{}'::jsonb),
    COALESCE(p_scores, '{}'::jsonb),
    COALESCE(p_warning_confirmations, '[]'::jsonb),
    COALESCE(p_safety_status, 'clear'),
    now(),
    v_age_years,
    v_age_months,
    v_age_group
  )
  RETURNING id INTO v_assessment_id;

  RETURN v_assessment_id;
END;
$$;

-- Re-apply grants (signature unchanged, so existing grants remain valid — but be explicit)
REVOKE ALL ON FUNCTION public.submit_reflex_profile_assessment(
  uuid, text, text, text, jsonb, jsonb, jsonb, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_reflex_profile_assessment(
  uuid, text, text, text, jsonb, jsonb, jsonb, text
) TO authenticated;
