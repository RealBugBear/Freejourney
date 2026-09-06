-- RLS establishes ownership of each row, but a foreign key only establishes
-- existence. Without this guard a caller can attach their own rows to another
-- account's child profile or enrollment, including occupying the globally
-- unique active-enrollment slot for that child.
--
-- No existing data is rewritten. Nullable legacy associations remain valid.
-- The primary-key lookups add bounded work per write. Existing RLS policies
-- and role grants are unchanged; service-side writes obey the same invariant.
CREATE OR REPLACE FUNCTION public.enforce_training_reference_ownership()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_row jsonb := to_jsonb(NEW);
  v_owner_id uuid := (v_row ->> 'user_id')::uuid;
  v_enrollment_id uuid := (v_row ->> 'enrollment_id')::uuid;
  v_subject_id uuid := (v_row ->> 'subject_profile_id')::uuid;
  v_enrollment_owner uuid;
  v_enrollment_subject uuid;
  v_session_id uuid := (v_row ->> 'session_id')::uuid;
  v_session_owner uuid;
  v_session_enrollment uuid;
BEGIN
  -- Completion questionnaires inherit ownership from their enrollment and
  -- deliberately have no user_id column.
  IF v_enrollment_id IS NOT NULL THEN
    SELECT user_id, subject_profile_id INTO v_enrollment_owner, v_enrollment_subject
      FROM public.enrollments WHERE id = v_enrollment_id;
    IF v_enrollment_owner IS NULL OR
       (v_owner_id IS NOT NULL AND v_owner_id <> v_enrollment_owner) THEN
      RAISE EXCEPTION USING ERRCODE = '23514',
        MESSAGE = 'training_reference_owner_mismatch';
    END IF;
    v_owner_id := COALESCE(v_owner_id, v_enrollment_owner);
    IF v_subject_id IS NOT NULL AND v_enrollment_subject IS NOT NULL
       AND v_subject_id <> v_enrollment_subject THEN
      RAISE EXCEPTION USING ERRCODE = '23514',
        MESSAGE = 'training_reference_owner_mismatch';
    END IF;
  END IF;

  IF v_session_id IS NOT NULL THEN
    SELECT user_id, enrollment_id INTO v_session_owner, v_session_enrollment
      FROM public.training_sessions WHERE id = v_session_id;
    IF v_session_owner IS DISTINCT FROM v_owner_id OR
       v_session_enrollment IS DISTINCT FROM v_enrollment_id THEN
      RAISE EXCEPTION USING ERRCODE = '23514',
        MESSAGE = 'training_reference_owner_mismatch';
    END IF;
  END IF;

  IF v_subject_id IS NOT NULL AND NOT EXISTS (
    SELECT 1 FROM public.reflex_subject_profiles
    WHERE id = v_subject_id AND owner_user_id = v_owner_id
  ) THEN
    -- Same neutral error for a missing or foreign reference: never disclose
    -- another account's identity or whether its subject profile exists.
    RAISE EXCEPTION USING ERRCODE = '23514',
      MESSAGE = 'training_reference_owner_mismatch';
  END IF;
  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.enforce_training_reference_ownership() FROM PUBLIC;

DO $$
DECLARE
  v_table text;
BEGIN
  FOREACH v_table IN ARRAY ARRAY[
    'enrollments', 'training_sessions', 'progress_entries', 'mood_checkins',
    'journal_entries', 'completion_questionnaires', 'streak_credits',
    'vorrunde_phases', 'reflex_profile_assessments'
  ] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS trg_training_reference_ownership ON public.%I', v_table);
    EXECUTE format(
      'CREATE TRIGGER trg_training_reference_ownership BEFORE INSERT OR UPDATE ON public.%I '
      'FOR EACH ROW EXECUTE FUNCTION public.enforce_training_reference_ownership()', v_table
    );
  END LOOP;
END;
$$;

COMMENT ON FUNCTION public.enforce_training_reference_ownership()
  IS 'Keeps training subjects and enrollment references within the owning account; does not replace row-level authorization.';
