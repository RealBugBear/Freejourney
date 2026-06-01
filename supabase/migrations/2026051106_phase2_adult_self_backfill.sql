-- Phase-2 backfill: adult_self subject profiles for legacy users
--
-- Before multi-profile support, one account = one trainable person (the user
-- themselves). Every row without subject_profile_id therefore belongs to the
-- user's "Ich" / adult_self profile. This migration:
--
--   1. Creates an adult_self profile for each user who has training data but
--      no adult_self profile yet.
--   2. Points all unlinked rows in training tables to that profile.
--   3. Backfills reflex_profile_assessments for adult_self_report type only
--      (child_parent_report rows cannot be assigned to a child profile
--       retroactively — they remain account-scoped / unlinked).
--
-- Idempotent: the NOT EXISTS / ON CONFLICT guards make it safe to re-run.

BEGIN;

-- ── Step 1: create adult_self profiles ───────────────────────────────────────

INSERT INTO public.reflex_subject_profiles (
  owner_user_id,
  profile_type,
  display_name
)
SELECT DISTINCT ON (p.id)
  p.id,
  'adult_self',
  COALESCE(NULLIF(TRIM(p.display_name), ''), 'Ich')
FROM public.profiles p
WHERE
  -- User has at least one piece of training data
  (
    EXISTS (SELECT 1 FROM public.enrollments         WHERE user_id = p.id)
    OR
    EXISTS (SELECT 1 FROM public.mood_checkins       WHERE user_id = p.id)
    OR
    EXISTS (SELECT 1 FROM public.journal_entries     WHERE user_id = p.id)
    OR
    EXISTS (SELECT 1 FROM public.training_sessions   WHERE user_id = p.id)
    OR
    EXISTS (SELECT 1 FROM public.reflex_profile_assessments WHERE user_id = p.id)
  )
  -- But no adult_self profile exists yet
  AND NOT EXISTS (
    SELECT 1 FROM public.reflex_subject_profiles
    WHERE owner_user_id = p.id AND profile_type = 'adult_self'
  );

-- ── Step 2: backfill enrollments ─────────────────────────────────────────────
-- Non-active rows: backfill freely (no unique constraint applies).
-- Active rows: only backfill the most-recent enrollment per user — older active
-- enrollments remain unlinked (covered by enrollments_legacy_user_package_active_unique).

UPDATE public.enrollments e
SET subject_profile_id = rsp.id
FROM public.reflex_subject_profiles rsp
WHERE rsp.owner_user_id = e.user_id
  AND rsp.profile_type  = 'adult_self'
  AND e.subject_profile_id IS NULL
  AND (
    e.status <> 'active'
    OR e.id = (
      SELECT id FROM public.enrollments e2
      WHERE e2.user_id = e.user_id
        AND e2.status = 'active'
        AND e2.subject_profile_id IS NULL
      ORDER BY e2.created_at DESC
      LIMIT 1
    )
  );

-- ── Step 3: backfill training_sessions ───────────────────────────────────────

UPDATE public.training_sessions ts
SET subject_profile_id = rsp.id
FROM public.reflex_subject_profiles rsp
WHERE rsp.owner_user_id = ts.user_id
  AND rsp.profile_type  = 'adult_self'
  AND ts.subject_profile_id IS NULL;

-- ── Step 4: backfill progress_entries ────────────────────────────────────────

UPDATE public.progress_entries pe
SET subject_profile_id = rsp.id
FROM public.reflex_subject_profiles rsp
WHERE rsp.owner_user_id = pe.user_id
  AND rsp.profile_type  = 'adult_self'
  AND pe.subject_profile_id IS NULL;

-- ── Step 5: backfill mood_checkins ───────────────────────────────────────────

UPDATE public.mood_checkins mc
SET subject_profile_id = rsp.id
FROM public.reflex_subject_profiles rsp
WHERE rsp.owner_user_id = mc.user_id
  AND rsp.profile_type  = 'adult_self'
  AND mc.subject_profile_id IS NULL;

-- ── Step 6: backfill journal_entries ─────────────────────────────────────────

UPDATE public.journal_entries je
SET subject_profile_id = rsp.id
FROM public.reflex_subject_profiles rsp
WHERE rsp.owner_user_id = je.user_id
  AND rsp.profile_type  = 'adult_self'
  AND je.subject_profile_id IS NULL;

-- ── Step 7: backfill reflex_profile_assessments (adult_self_report only) ─────

UPDATE public.reflex_profile_assessments rpa
SET subject_profile_id = rsp.id
FROM public.reflex_subject_profiles rsp
WHERE rsp.owner_user_id    = rpa.user_id
  AND rsp.profile_type     = 'adult_self'
  AND rpa.subject_profile_id IS NULL
  AND rpa.questionnaire_type = 'adult_self_report';

COMMIT;

-- ── Verify ────────────────────────────────────────────────────────────────────

SELECT
  'adult_self profiles created or pre-existing' AS metric,
  count(*) AS value
FROM public.reflex_subject_profiles
WHERE profile_type = 'adult_self'

UNION ALL

SELECT 'enrollments still unlinked',
  count(*) FROM public.enrollments WHERE subject_profile_id IS NULL

UNION ALL

SELECT 'mood_checkins still unlinked',
  count(*) FROM public.mood_checkins WHERE subject_profile_id IS NULL

UNION ALL

SELECT 'journal_entries still unlinked',
  count(*) FROM public.journal_entries WHERE subject_profile_id IS NULL

UNION ALL

SELECT 'assessments unlinked (child_parent_report — expected)',
  count(*) FROM public.reflex_profile_assessments
  WHERE subject_profile_id IS NULL AND questionnaire_type = 'child_parent_report'

UNION ALL

SELECT 'assessments unlinked (adult_self_report — should be 0)',
  count(*) FROM public.reflex_profile_assessments
  WHERE subject_profile_id IS NULL AND questionnaire_type = 'adult_self_report';
