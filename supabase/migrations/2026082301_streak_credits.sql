-- Freischein ledger, one row per subject profile.
--
-- The streak itself is NOT stored: it is derived from training_sessions rows
-- (docs/superpowers/specs/2026-08-23-serie-und-freischeine-design.md §4.1).
-- Only rescued_days cannot be derived — that a missed day was forgiven leaves
-- no other trace.
--
-- Additive only: creates one new table, touches no existing row or column.
-- Rollback: DROP TABLE public.streak_credits;

CREATE TABLE IF NOT EXISTS public.streak_credits (
  -- '<user_id>::<subject_profile_id>', built client-side so the row is stable
  -- across devices without a round trip.
  id text PRIMARY KEY,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subject_profile_id uuid NOT NULL
    REFERENCES public.reflex_subject_profiles(id) ON DELETE CASCADE,
  available int NOT NULL DEFAULT 0
    CHECK (available BETWEEN 0 AND 2),
  progress_to_next int NOT NULL DEFAULT 0
    CHECK (progress_to_next BETWEEN 0 AND 2),
  last_counted_day date,
  rescued_days date[] NOT NULL DEFAULT '{}',
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, subject_profile_id)
);

CREATE INDEX IF NOT EXISTS idx_streak_credits_user
  ON public.streak_credits(user_id);

ALTER TABLE public.streak_credits ENABLE ROW LEVEL SECURITY;

-- Owner: full access to their own rows.
DROP POLICY IF EXISTS "cj: streak_credits all own" ON public.streak_credits;
CREATE POLICY "cj: streak_credits all own"
  ON public.streak_credits FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Trainer: read-only, and only through an active relationship. Mirrors
-- "cj: progress_entries trainer read" from 20260702_rls_baseline_core_tables.sql.
DROP POLICY IF EXISTS "cj: streak_credits trainer read" ON public.streak_credits;
CREATE POLICY "cj: streak_credits trainer read"
  ON public.streak_credits FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM trainer_client_relationships
      WHERE trainer_id = auth.uid()
        AND client_id = streak_credits.user_id
        AND status = 'active'
    )
  );
