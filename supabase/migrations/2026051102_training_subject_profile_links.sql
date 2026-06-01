-- Link package enrollment and training data to concrete subject profiles.
-- Nullable first: existing account-scoped rows remain valid until backfill.

ALTER TABLE public.enrollments
  ADD COLUMN IF NOT EXISTS subject_profile_id uuid
    REFERENCES public.reflex_subject_profiles(id) ON DELETE SET NULL;

ALTER TABLE public.progress_entries
  ADD COLUMN IF NOT EXISTS subject_profile_id uuid
    REFERENCES public.reflex_subject_profiles(id) ON DELETE SET NULL;

ALTER TABLE public.training_sessions
  ADD COLUMN IF NOT EXISTS subject_profile_id uuid
    REFERENCES public.reflex_subject_profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_enrollments_subject_profile
  ON public.enrollments(subject_profile_id, status);

CREATE INDEX IF NOT EXISTS idx_progress_entries_subject_profile
  ON public.progress_entries(subject_profile_id);

CREATE INDEX IF NOT EXISTS idx_training_sessions_subject_profile_date
  ON public.training_sessions(subject_profile_id, session_date DESC);

-- Previous guardrail was account+package. Multi-subject training needs one
-- active enrollment per profile, while legacy rows without subject_profile_id
-- keep the old account+package behavior until migration/backfill completes.
DROP INDEX IF EXISTS enrollments_user_package_active_unique;

CREATE UNIQUE INDEX IF NOT EXISTS enrollments_subject_profile_active_unique
  ON public.enrollments(subject_profile_id)
  WHERE status = 'active' AND subject_profile_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS enrollments_legacy_user_package_active_unique
  ON public.enrollments(user_id, package_id)
  WHERE status = 'active' AND subject_profile_id IS NULL;
