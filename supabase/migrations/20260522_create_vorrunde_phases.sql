-- CoreJourney — Vorrunde phases
-- Additive migration: stores the per-subject Moro preparation phase.

CREATE TABLE IF NOT EXISTS public.vorrunde_phases (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subject_profile_id uuid REFERENCES public.reflex_subject_profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'started'
    CHECK (status IN ('started', 'skipped', 'completed')),
  first_started_at timestamptz,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, subject_profile_id)
);

CREATE INDEX IF NOT EXISTS idx_vorrunde_phases_user_subject
  ON public.vorrunde_phases(user_id, subject_profile_id);

CREATE INDEX IF NOT EXISTS idx_vorrunde_phases_status
  ON public.vorrunde_phases(status);

CREATE UNIQUE INDEX IF NOT EXISTS idx_vorrunde_phases_user_null_subject
  ON public.vorrunde_phases(user_id)
  WHERE subject_profile_id IS NULL;

CREATE OR REPLACE FUNCTION public._vorrunde_phases_set_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_vorrunde_phases_updated_at ON public.vorrunde_phases;
CREATE TRIGGER trg_vorrunde_phases_updated_at
  BEFORE UPDATE ON public.vorrunde_phases
  FOR EACH ROW EXECUTE FUNCTION public._vorrunde_phases_set_updated_at();

ALTER TABLE public.vorrunde_phases ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cj: vorrunde_phases select own" ON public.vorrunde_phases;
DROP POLICY IF EXISTS "cj: vorrunde_phases insert own" ON public.vorrunde_phases;
DROP POLICY IF EXISTS "cj: vorrunde_phases update own" ON public.vorrunde_phases;
DROP POLICY IF EXISTS "cj: vorrunde_phases delete own" ON public.vorrunde_phases;

CREATE POLICY "cj: vorrunde_phases select own"
  ON public.vorrunde_phases FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "cj: vorrunde_phases insert own"
  ON public.vorrunde_phases FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "cj: vorrunde_phases update own"
  ON public.vorrunde_phases FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "cj: vorrunde_phases delete own"
  ON public.vorrunde_phases FOR DELETE
  USING (auth.uid() = user_id);
