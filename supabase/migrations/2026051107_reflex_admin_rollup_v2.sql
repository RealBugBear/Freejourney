-- Migration: fix get_reflex_profile_admin_rollup to use age_group_at_assessment
-- so historical assessments are bucketed by the age at the time they were taken,
-- not the subject's current age group.

DROP FUNCTION IF EXISTS public.get_reflex_profile_admin_rollup();

CREATE FUNCTION public.get_reflex_profile_admin_rollup()
RETURNS TABLE (
  questionnaire_type text,
  age_group          text,
  assessment_count   bigint,
  scores             jsonb,
  answer_counts      jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Nur Admins koennen Reflexprofil-Auswertungen sehen.';
  END IF;

  RETURN QUERY
  SELECT
    rpa.questionnaire_type,
    COALESCE(rpa.age_group_at_assessment, rsp.age_group, 'unknown') AS age_group,
    count(*) AS assessment_count,
    jsonb_agg(rpa.scores)  AS scores,
    jsonb_agg(rpa.answers) AS answer_counts
  FROM public.reflex_profile_assessments rpa
  LEFT JOIN public.reflex_subject_profiles rsp
    ON rsp.id = rpa.subject_profile_id
  WHERE rpa.status = 'completed'
    AND rpa.questionnaire_type <> 'demo_child_short'
  GROUP BY
    rpa.questionnaire_type,
    COALESCE(rpa.age_group_at_assessment, rsp.age_group, 'unknown')
  ORDER BY rpa.questionnaire_type, age_group;
END;
$$;

REVOKE ALL ON FUNCTION public.get_reflex_profile_admin_rollup() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_reflex_profile_admin_rollup()
  TO authenticated;
