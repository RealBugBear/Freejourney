-- Migration: add subject_profile_id to mood_checkins and journal_entries
--
-- Flutter already sends this field on every upsert; without the column the
-- value is silently dropped by Supabase. Adding the column makes the writes
-- land and enables per-profile filtering in future queries.
--
-- FK is ON DELETE SET NULL: if a subject profile is deleted the rows stay,
-- they just lose their profile association — preferable to cascading deletes.

-- ── mood_checkins ─────────────────────────────────────────────────────────────

ALTER TABLE public.mood_checkins
  ADD COLUMN IF NOT EXISTS subject_profile_id uuid
    REFERENCES public.reflex_subject_profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_mood_checkins_subject_profile
  ON public.mood_checkins (subject_profile_id)
  WHERE subject_profile_id IS NOT NULL;

-- ── journal_entries ───────────────────────────────────────────────────────────

ALTER TABLE public.journal_entries
  ADD COLUMN IF NOT EXISTS subject_profile_id uuid
    REFERENCES public.reflex_subject_profiles(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_journal_entries_subject_profile
  ON public.journal_entries (subject_profile_id)
  WHERE subject_profile_id IS NOT NULL;
