-- Migration: add subject_profile_id to completion_questionnaires
-- and backfill from enrollments (completion questionnaires inherit their
-- enrollment's subject_profile_id — same person, same training context).

ALTER TABLE public.completion_questionnaires
  ADD COLUMN IF NOT EXISTS subject_profile_id uuid
    REFERENCES public.reflex_subject_profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_completion_questionnaires_subject_profile
  ON public.completion_questionnaires (subject_profile_id)
  WHERE subject_profile_id IS NOT NULL;

-- Backfill from enrollments
UPDATE public.completion_questionnaires cq
SET subject_profile_id = e.subject_profile_id
FROM public.enrollments e
WHERE e.id = cq.enrollment_id
  AND cq.subject_profile_id IS NULL
  AND e.subject_profile_id IS NOT NULL;
