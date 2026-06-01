-- CoreJourney local-dev baseline
--
-- The hosted project already has these foundational objects. Local Supabase,
-- however, starts from an empty database and only replays timestamped files in
-- supabase/migrations. Several early migrations assume this schema exists.
--
-- Keep this migration additive and idempotent so it is safe on environments
-- where the tables were created manually before migrations were tracked.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── Profiles ────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name text,
  role text NOT NULL DEFAULT 'practitioner'
    CHECK (role IN ('practitioner', 'trainer', 'admin')),
  locale text NOT NULL DEFAULT 'de'
    CHECK (locale IN ('de', 'en')),
  child_assist_mode boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id) VALUES (NEW.id)
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at,
  confirmation_token,
  email_change,
  email_change_token_new,
  recovery_token
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  'd714e822-83a2-474f-ba01-2e59ad20dcae',
  'authenticated',
  'authenticated',
  'assistant@corejourney.local',
  '',
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"display_name":"CoreJourney Assistent"}'::jsonb,
  now(),
  now(),
  '',
  '',
  '',
  ''
)
ON CONFLICT (id) DO NOTHING;

-- ── Static training content tables ──────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.reflex_packages (
  id text PRIMARY KEY,
  sequence_number int NOT NULL UNIQUE,
  name_de text NOT NULL,
  name_en text NOT NULL,
  description_de text,
  description_en text,
  is_free boolean NOT NULL DEFAULT false,
  is_paywall_enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.exercises (
  id text PRIMARY KEY,
  package_id text NOT NULL REFERENCES public.reflex_packages(id),
  sequence_number int NOT NULL,
  title_de text NOT NULL,
  title_en text NOT NULL,
  position_instructions_de text[] NOT NULL,
  position_instructions_en text[] NOT NULL,
  movement_instructions_de text[] NOT NULL,
  movement_instructions_en text[] NOT NULL,
  hints_de text[],
  hints_en text[],
  execution_guide_de text NOT NULL,
  execution_guide_en text NOT NULL,
  duration_seconds int NOT NULL,
  repetitions int NOT NULL,
  image_path text NOT NULL,
  video_path text,
  audio_cue_path text
);

INSERT INTO public.reflex_packages (
  id,
  sequence_number,
  name_de,
  name_en,
  description_de,
  description_en,
  is_free,
  is_paywall_enabled
) VALUES
  (
    'moro',
    1,
    'Moro Reflex',
    'Moro Reflex',
    'Der Moro-Reflex ist der erste Reflex, der integriert werden muss. Er liegt allen anderen zugrunde.',
    'The Moro reflex is the foundation - it must be integrated before all others.',
    true,
    false
  ),
  ('spinal_galant', 2, 'Spinaler Galant + Amphibien', 'Spinal Galant + Amphibian', null, null, false, true),
  ('tlr', 3, 'Tonischer Labirint Reflex (TLR)', 'Tonic Labyrinthine Reflex (TLR)', null, null, false, true),
  ('babkin', 4, 'Babkin + Plantar + Greifen', 'Babkin + Plantar + Grasp', null, null, false, true),
  ('such_saug', 5, 'Such-Saug Reflex', 'Rooting-Sucking Reflex', null, null, false, true),
  ('atnr', 6, 'ATNR', 'ATNR', null, null, false, true),
  ('stnr', 7, 'STNR', 'STNR', null, null, false, true),
  ('babinski', 8, 'Babinski Reflex', 'Babinski Reflex', null, null, false, true),
  ('landau', 9, 'Landau Reflex', 'Landau Reflex', null, null, false, true)
ON CONFLICT (id) DO NOTHING;

-- ── Training state ──────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.enrollments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  package_id text NOT NULL REFERENCES public.reflex_packages(id),
  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'paused', 'completed', 'abandoned')),
  assigned_duration_weeks int NOT NULL CHECK (assigned_duration_weeks BETWEEN 4 AND 8),
  start_date date NOT NULL,
  target_completion_date date NOT NULL,
  completed_at timestamptz,
  paused_at timestamptz,
  preceding_enrollment_id uuid REFERENCES public.enrollments(id),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_enrollments_user_id
  ON public.enrollments(user_id);

CREATE INDEX IF NOT EXISTS idx_enrollments_status
  ON public.enrollments(status);

CREATE TABLE IF NOT EXISTS public.intake_assessments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id uuid NOT NULL UNIQUE REFERENCES public.enrollments(id) ON DELETE CASCADE,
  had_isometric_with_trainer boolean NOT NULL,
  additional_answers jsonb,
  recommended_duration_weeks int NOT NULL,
  user_accepted_recommendation boolean NOT NULL,
  final_duration_weeks int NOT NULL,
  completed_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.completion_questionnaires (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  enrollment_id uuid NOT NULL REFERENCES public.enrollments(id) ON DELETE CASCADE,
  attempt_number int NOT NULL DEFAULT 1,
  response boolean NOT NULL,
  result text NOT NULL CHECK (result IN ('passed', 'extend')),
  next_enrollment_created boolean NOT NULL DEFAULT false,
  submitted_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.training_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  enrollment_id uuid NOT NULL REFERENCES public.enrollments(id),
  session_date date NOT NULL,
  day_number int NOT NULL,
  completed_exercise_ids text[] NOT NULL,
  is_completed boolean NOT NULL DEFAULT false,
  completed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_sessions_user_date
  ON public.training_sessions(user_id, session_date);

CREATE INDEX IF NOT EXISTS idx_sessions_enrollment
  ON public.training_sessions(enrollment_id, session_date);

CREATE TABLE IF NOT EXISTS public.progress_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  enrollment_id uuid NOT NULL UNIQUE REFERENCES public.enrollments(id) ON DELETE CASCADE,
  current_day int NOT NULL DEFAULT 1,
  last_activity_date date,
  consecutive_inactive_days int NOT NULL DEFAULT 0,
  daily_streak int NOT NULL DEFAULT 0,
  weekly_streak int NOT NULL DEFAULT 0,
  trainings_this_week int NOT NULL DEFAULT 0,
  last_training_week_start date,
  weekly_goal int NOT NULL DEFAULT 5,
  total_sessions_since_disclaimer int NOT NULL DEFAULT 0,
  last_disclaimer_accepted_at timestamptz,
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_progress_user
  ON public.progress_entries(user_id);

CREATE TABLE IF NOT EXISTS public.mood_checkins (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  enrollment_id uuid NOT NULL REFERENCES public.enrollments(id),
  session_id uuid REFERENCES public.training_sessions(id),
  recorded_at timestamptz NOT NULL DEFAULT now(),
  day_key bigint NOT NULL,
  mood smallint CHECK (mood BETWEEN 1 AND 5),
  energy smallint CHECK (energy BETWEEN 1 AND 5),
  stress smallint CHECK (stress BETWEEN 1 AND 5),
  note text,
  source text NOT NULL CHECK (source IN ('post_training', 'manual')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mood_user_time
  ON public.mood_checkins(user_id, recorded_at);

CREATE TABLE IF NOT EXISTS public.journal_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  enrollment_id uuid REFERENCES public.enrollments(id) ON DELETE SET NULL,
  content text NOT NULL CHECK (char_length(content) > 0),
  day_key integer NOT NULL,
  checkin_id uuid,
  mood smallint CHECK (mood BETWEEN 1 AND 5),
  energy smallint CHECK (energy BETWEEN 1 AND 5),
  stress smallint CHECK (stress BETWEEN 1 AND 5),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_journal_entries_user_enrollment
  ON public.journal_entries(user_id, enrollment_id, day_key DESC);

CREATE INDEX IF NOT EXISTS idx_journal_entries_checkin_id
  ON public.journal_entries(checkin_id)
  WHERE checkin_id IS NOT NULL;

-- ── Trainer/client base tables ──────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.trainer_client_relationships (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  client_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'active', 'disconnected')),
  trainer_notes text,
  invite_code text UNIQUE,
  linked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.access_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code text NOT NULL UNIQUE,
  type text NOT NULL CHECK (type IN ('free', 'discount')),
  discount_percent int CHECK (discount_percent BETWEEN 1 AND 100),
  applicable_package_ids text[],
  max_redemptions int,
  redemption_count int NOT NULL DEFAULT 0,
  expires_at timestamptz,
  created_by uuid NOT NULL REFERENCES public.profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

-- ── Push and feature flags ──────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token text NOT NULL,
  platform text NOT NULL CHECK (platform IN ('ios', 'android', 'macos', 'web', 'unknown')),
  environment text NOT NULL DEFAULT 'development'
    CHECK (environment IN ('development', 'staging', 'production')),
  app_version text,
  device_id text,
  enabled boolean NOT NULL DEFAULT true,
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX IF NOT EXISTS ux_device_tokens_token
  ON public.device_tokens(token);

CREATE INDEX IF NOT EXISTS device_tokens_user_id_idx
  ON public.device_tokens(user_id);

CREATE INDEX IF NOT EXISTS device_tokens_enabled_user_idx
  ON public.device_tokens(user_id, enabled)
  WHERE revoked_at IS NULL;

CREATE TABLE IF NOT EXISTS public.feature_flags (
  key text PRIMARY KEY,
  value boolean NOT NULL DEFAULT false,
  description text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

INSERT INTO public.feature_flags (key, value, description) VALUES
  ('training_enabled', true, 'Master switch for training feature'),
  ('mood_tracking_enabled', true, 'Enable mood check-in feature'),
  ('social_sharing_enabled', false, 'Social sharing'),
  ('trainer_accounts_enabled', true, 'Trainer account features')
ON CONFLICT (key) DO NOTHING;

-- ── Appointments baseline ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.appointments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  trainer_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  trainee_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title text NOT NULL DEFAULT 'Isometrische Partnerübung',
  scheduled_for timestamptz,
  proposed_slots timestamptz[] NOT NULL DEFAULT '{}',
  duration_minutes int NOT NULL DEFAULT 60,
  location text,
  notes text,
  status text NOT NULL DEFAULT 'planned'
    CHECK (status IN ('proposed', 'planned', 'confirmed', 'cancelled', 'done')),
  trigger text CHECK (trigger IN ('early_warning', 'completion_day', 'manual')),
  trainee_day_number int,
  calendar_event_id text,
  calendar_id text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_appointments_trainer
  ON public.appointments(trainer_id, scheduled_for);

CREATE INDEX IF NOT EXISTS idx_appointments_trainee
  ON public.appointments(trainee_id);

-- RLS is enabled and policy-managed by later focused migrations/scripts.
