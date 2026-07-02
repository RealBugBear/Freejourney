-- ============================================================================
-- RLS baseline for the core tables (launch backlog P0.1)
--
-- Converts the hand-run scripts `supabase/rls_apply.sql` and
-- `supabase/journal_entries_migration.sql` into the migrations pipeline, so a
-- replay from `20260412_core_schema_baseline.sql` produces the same RLS state
-- as the live database (verified against live pg_policies on 2026-07-02).
--
-- Idempotent and safe to re-run: ENABLE RLS is a no-op when already enabled,
-- and every policy is DROP IF EXISTS + CREATE.
--
-- On the live DB (which already ran the hand-run scripts) the only effective
-- change is dropping the redundant legacy policy "Users manage own journal"
-- (superseded by the four "cj: journal_entries *" policies below).
-- ============================================================================


-- ── STEP 1: Enable RLS ───────────────────────────────────────────────────────
-- device_tokens / user_consents / appointments already get RLS from their own
-- migrations; included again here (no-op) so this file is the one complete
-- baseline for every table it defines policies on.

ALTER TABLE public.profiles                     ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enrollments                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.intake_assessments           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.completion_questionnaires    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.training_sessions            ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.progress_entries             ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_checkins                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.journal_entries              ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_client_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_tokens                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_consents                ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.appointments                 ENABLE ROW LEVEL SECURITY;

-- access_codes: RLS on with NO policies = deny-all for client roles.
-- Access codes are handled exclusively via service-role (Edge Functions),
-- which bypasses RLS. Intentional — do not add client policies here.
ALTER TABLE public.access_codes                 ENABLE ROW LEVEL SECURITY;


-- ── STEP 2: Drop policies superseded by the "cj:" set ────────────────────────
-- These names are created by earlier migrations (or a pre-RLS-audit schema)
-- and were replaced on the live DB by rls_apply.sql. Dropping them here makes
-- a fresh migrations replay converge to the live state.

DROP POLICY IF EXISTS "Users manage own consent"          ON public.user_consents;   -- 2026041601_user_consents.sql
DROP POLICY IF EXISTS "Trainers manage own appointments"  ON public.appointments;    -- 2026042401_trainer_appointments.sql
DROP POLICY IF EXISTS "Trainees read own appointments"    ON public.appointments;    -- 2026042401_trainer_appointments.sql
DROP POLICY IF EXISTS "Users manage own journal"          ON public.journal_entries; -- legacy, still live before this migration

-- NOTE: device_tokens keeps BOTH the three "Users can … their own device
-- tokens" policies from 2026042701_push_tokens.sql AND the "cj:" ALL policy
-- below — that is the verified live state.


-- ── STEP 3: The policy set (matches live pg_policies, 2026-07-02) ────────────

-- profiles — profiles.id IS the user UUID (no user_id column).
-- (profiles_admin_read_all comes from 2026041505_subscription_tier.sql.)
DROP POLICY IF EXISTS "cj: profiles select own" ON public.profiles;
CREATE POLICY "cj: profiles select own"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "cj: profiles insert own" ON public.profiles;
CREATE POLICY "cj: profiles insert own"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "cj: profiles update own" ON public.profiles;
CREATE POLICY "cj: profiles update own"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);


-- enrollments
DROP POLICY IF EXISTS "cj: enrollments all own" ON public.enrollments;
CREATE POLICY "cj: enrollments all own"
  ON public.enrollments FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "cj: enrollments trainer read" ON public.enrollments;
CREATE POLICY "cj: enrollments trainer read"
  ON public.enrollments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM trainer_client_relationships
      WHERE trainer_id = auth.uid()
        AND client_id = enrollments.user_id
        AND status = 'active'
    )
  );


-- intake_assessments — no user_id; ownership via enrollment_id → enrollments.user_id
DROP POLICY IF EXISTS "cj: intake_assessments all own" ON public.intake_assessments;
CREATE POLICY "cj: intake_assessments all own"
  ON public.intake_assessments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM enrollments
      WHERE id = intake_assessments.enrollment_id
        AND user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM enrollments
      WHERE id = intake_assessments.enrollment_id
        AND user_id = auth.uid()
    )
  );


-- completion_questionnaires — same ownership pattern as intake_assessments
DROP POLICY IF EXISTS "cj: completion_questionnaires all own" ON public.completion_questionnaires;
CREATE POLICY "cj: completion_questionnaires all own"
  ON public.completion_questionnaires FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM enrollments
      WHERE id = completion_questionnaires.enrollment_id
        AND user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM enrollments
      WHERE id = completion_questionnaires.enrollment_id
        AND user_id = auth.uid()
    )
  );


-- training_sessions
DROP POLICY IF EXISTS "cj: training_sessions all own" ON public.training_sessions;
CREATE POLICY "cj: training_sessions all own"
  ON public.training_sessions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "cj: training_sessions trainer read" ON public.training_sessions;
CREATE POLICY "cj: training_sessions trainer read"
  ON public.training_sessions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM trainer_client_relationships
      WHERE trainer_id = auth.uid()
        AND client_id = training_sessions.user_id
        AND status = 'active'
    )
  );


-- progress_entries
DROP POLICY IF EXISTS "cj: progress_entries all own" ON public.progress_entries;
CREATE POLICY "cj: progress_entries all own"
  ON public.progress_entries FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "cj: progress_entries trainer read" ON public.progress_entries;
CREATE POLICY "cj: progress_entries trainer read"
  ON public.progress_entries FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM trainer_client_relationships
      WHERE trainer_id = auth.uid()
        AND client_id = progress_entries.user_id
        AND status = 'active'
    )
  );


-- mood_checkins
DROP POLICY IF EXISTS "cj: mood_checkins all own" ON public.mood_checkins;
CREATE POLICY "cj: mood_checkins all own"
  ON public.mood_checkins FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "cj: mood_checkins trainer read" ON public.mood_checkins;
CREATE POLICY "cj: mood_checkins trainer read"
  ON public.mood_checkins FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM trainer_client_relationships
      WHERE trainer_id = auth.uid()
        AND client_id = mood_checkins.user_id
        AND status = 'active'
    )
  );


-- journal_entries — per-command policies (from journal_entries_migration.sql)
DROP POLICY IF EXISTS "cj: journal_entries select own" ON public.journal_entries;
CREATE POLICY "cj: journal_entries select own"
  ON public.journal_entries FOR SELECT
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "cj: journal_entries insert own" ON public.journal_entries;
CREATE POLICY "cj: journal_entries insert own"
  ON public.journal_entries FOR INSERT
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "cj: journal_entries update own" ON public.journal_entries;
CREATE POLICY "cj: journal_entries update own"
  ON public.journal_entries FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "cj: journal_entries delete own" ON public.journal_entries;
CREATE POLICY "cj: journal_entries delete own"
  ON public.journal_entries FOR DELETE
  USING (user_id = auth.uid());


-- trainer_client_relationships
DROP POLICY IF EXISTS "cj: tcr select participant" ON public.trainer_client_relationships;
CREATE POLICY "cj: tcr select participant"
  ON public.trainer_client_relationships FOR SELECT
  USING (auth.uid() = trainer_id OR auth.uid() = client_id);

DROP POLICY IF EXISTS "cj: tcr all trainer" ON public.trainer_client_relationships;
CREATE POLICY "cj: tcr all trainer"
  ON public.trainer_client_relationships FOR ALL
  USING (auth.uid() = trainer_id)
  WITH CHECK (auth.uid() = trainer_id);

DROP POLICY IF EXISTS "cj: tcr update client" ON public.trainer_client_relationships;
CREATE POLICY "cj: tcr update client"
  ON public.trainer_client_relationships FOR UPDATE
  USING (auth.uid() = client_id)
  WITH CHECK (auth.uid() = client_id);


-- device_tokens
DROP POLICY IF EXISTS "cj: device_tokens all own" ON public.device_tokens;
CREATE POLICY "cj: device_tokens all own"
  ON public.device_tokens FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- user_consents
DROP POLICY IF EXISTS "cj: user_consents all own" ON public.user_consents;
CREATE POLICY "cj: user_consents all own"
  ON public.user_consents FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- appointments — trainer manages, trainee reads + may confirm (update)
DROP POLICY IF EXISTS "cj: appointments all trainer" ON public.appointments;
CREATE POLICY "cj: appointments all trainer"
  ON public.appointments FOR ALL
  USING (auth.uid() = trainer_id)
  WITH CHECK (auth.uid() = trainer_id);

DROP POLICY IF EXISTS "cj: appointments select trainee" ON public.appointments;
CREATE POLICY "cj: appointments select trainee"
  ON public.appointments FOR SELECT
  USING (auth.uid() = trainee_id);

DROP POLICY IF EXISTS "Trainees confirm own appointments" ON public.appointments;
CREATE POLICY "Trainees confirm own appointments"
  ON public.appointments FOR UPDATE
  USING (auth.uid() = trainee_id);


-- ── STEP 4: journal_entries updated_at trigger ───────────────────────────────
-- From journal_entries_migration.sql; live-verified 2026-07-02
-- (trg_journal_entries_updated_at exists, function exists).

CREATE OR REPLACE FUNCTION _journal_entries_set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_journal_entries_updated_at ON public.journal_entries;
CREATE TRIGGER trg_journal_entries_updated_at
  BEFORE UPDATE ON public.journal_entries
  FOR EACH ROW EXECUTE FUNCTION _journal_entries_set_updated_at();
