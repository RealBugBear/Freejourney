-- Link appointments to concrete subject profiles.
-- An appointment with no rows in this table targets the whole account (legacy).
-- One or more rows mean the appointment is for specific profiles, e.g. "Max + Emma".

CREATE TABLE IF NOT EXISTS public.appointment_subject_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  appointment_id uuid NOT NULL
    REFERENCES public.appointments(id) ON DELETE CASCADE,
  subject_profile_id uuid NOT NULL
    REFERENCES public.reflex_subject_profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (appointment_id, subject_profile_id)
);

CREATE INDEX IF NOT EXISTS idx_asp_appointment
  ON public.appointment_subject_profiles(appointment_id);

CREATE INDEX IF NOT EXISTS idx_asp_profile
  ON public.appointment_subject_profiles(subject_profile_id);

ALTER TABLE public.appointment_subject_profiles ENABLE ROW LEVEL SECURITY;

-- Trainee sees profile links for their own appointments
CREATE POLICY asp_trainee_select
  ON public.appointment_subject_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.appointments a
      WHERE a.id = appointment_id AND a.trainee_id = auth.uid()
    )
  );

-- Trainer sees profile links for appointments they created
CREATE POLICY asp_trainer_select
  ON public.appointment_subject_profiles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.appointments a
      WHERE a.id = appointment_id AND a.trainer_id = auth.uid()
    )
  );

-- Trainer inserts profile links when proposing appointments
CREATE POLICY asp_trainer_insert
  ON public.appointment_subject_profiles FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.appointments a
      WHERE a.id = appointment_id AND a.trainer_id = auth.uid()
    )
  );

-- Trainer or trainee can remove profile links
CREATE POLICY asp_delete
  ON public.appointment_subject_profiles FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.appointments a
      WHERE a.id = appointment_id
        AND (a.trainer_id = auth.uid() OR a.trainee_id = auth.uid())
    )
  );
