-- CoreJourney - Training Reminder System V1
-- Additive migration for server-side training reminder preferences and queue.

CREATE TABLE IF NOT EXISTS public.user_reminder_preferences (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  enabled boolean NOT NULL DEFAULT false,
  timezone text NOT NULL,
  quiet_start time NOT NULL DEFAULT '20:00',
  quiet_end time NOT NULL DEFAULT '08:00',
  weekly_goal int CHECK (weekly_goal IS NULL OR weekly_goal > 0),
  weekly_goal_source text NOT NULL DEFAULT 'default',
  server_reminders_enabled boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_reminder_preferences_weekly_goal_source_check
    CHECK (weekly_goal_source IN ('curriculum', 'user_setting', 'default')),
  CONSTRAINT user_reminder_preferences_timezone_not_blank
    CHECK (length(trim(timezone)) > 0)
);

CREATE OR REPLACE FUNCTION public._user_reminder_preferences_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_reminder_preferences_updated_at
  ON public.user_reminder_preferences;
CREATE TRIGGER trg_user_reminder_preferences_updated_at
  BEFORE UPDATE ON public.user_reminder_preferences
  FOR EACH ROW
  EXECUTE FUNCTION public._user_reminder_preferences_set_updated_at();

CREATE OR REPLACE FUNCTION public._user_reminder_preferences_protect_rollout()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF auth.role() = 'authenticated' THEN
    IF TG_OP = 'INSERT' THEN
      NEW.server_reminders_enabled = false;
    ELSE
      NEW.server_reminders_enabled = OLD.server_reminders_enabled;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_user_reminder_preferences_protect_rollout
  ON public.user_reminder_preferences;
CREATE TRIGGER trg_user_reminder_preferences_protect_rollout
  BEFORE INSERT OR UPDATE ON public.user_reminder_preferences
  FOR EACH ROW
  EXECUTE FUNCTION public._user_reminder_preferences_protect_rollout();

CREATE TABLE IF NOT EXISTS public.notification_jobs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type text NOT NULL,
  scheduled_for timestamptz NOT NULL,
  local_date date NOT NULL,
  timezone text NOT NULL,
  status text NOT NULL DEFAULT 'pending',
  attempt_count int NOT NULL DEFAULT 0,
  idempotency_key text NOT NULL,
  sent_token_count int NOT NULL DEFAULT 0,
  failed_token_count int NOT NULL DEFAULT 0,
  last_error text,
  fcm_message_ids jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  sent_at timestamptz,
  CONSTRAINT notification_jobs_type_check
    CHECK (type IN ('training_soft', 'streak_warning', 'comeback')),
  CONSTRAINT notification_jobs_status_check
    CHECK (status IN ('pending', 'sending', 'sent', 'failed', 'skipped')),
  CONSTRAINT notification_jobs_attempt_count_check
    CHECK (attempt_count >= 0),
  CONSTRAINT notification_jobs_counts_check
    CHECK (sent_token_count >= 0 AND failed_token_count >= 0),
  CONSTRAINT notification_jobs_timezone_not_blank
    CHECK (length(trim(timezone)) > 0)
);

CREATE UNIQUE INDEX IF NOT EXISTS notification_jobs_idempotency_key_key
  ON public.notification_jobs(idempotency_key);

CREATE UNIQUE INDEX IF NOT EXISTS notification_jobs_user_type_local_date_key
  ON public.notification_jobs(user_id, type, local_date);

CREATE INDEX IF NOT EXISTS notification_jobs_status_scheduled_for_idx
  ON public.notification_jobs(status, scheduled_for);

CREATE INDEX IF NOT EXISTS notification_jobs_user_local_date_idx
  ON public.notification_jobs(user_id, local_date DESC);

ALTER TABLE public.user_reminder_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_jobs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cj: user_reminder_preferences select own"
  ON public.user_reminder_preferences;
DROP POLICY IF EXISTS "cj: user_reminder_preferences insert own"
  ON public.user_reminder_preferences;
DROP POLICY IF EXISTS "cj: user_reminder_preferences update own"
  ON public.user_reminder_preferences;
DROP POLICY IF EXISTS "cj: notification_jobs select own"
  ON public.notification_jobs;

CREATE POLICY "cj: user_reminder_preferences select own"
  ON public.user_reminder_preferences
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "cj: user_reminder_preferences insert own"
  ON public.user_reminder_preferences
  FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "cj: user_reminder_preferences update own"
  ON public.user_reminder_preferences
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "cj: notification_jobs select own"
  ON public.notification_jobs
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION public.claim_due_notification_jobs(
  p_limit int DEFAULT 100
)
RETURNS SETOF public.notification_jobs
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_limit int := LEAST(GREATEST(COALESCE(p_limit, 100), 1), 500);
BEGIN
  RETURN QUERY
  WITH claimed AS (
    SELECT id
    FROM public.notification_jobs
    WHERE status = 'pending'
      AND scheduled_for <= now()
    ORDER BY scheduled_for ASC, created_at ASC
    LIMIT v_limit
    FOR UPDATE SKIP LOCKED
  )
  UPDATE public.notification_jobs nj
  SET
    status = 'sending',
    attempt_count = nj.attempt_count + 1,
    last_error = NULL
  FROM claimed
  WHERE nj.id = claimed.id
  RETURNING nj.*;
END;
$$;

CREATE OR REPLACE FUNCTION public.training_reminder_local_to_utc(
  p_local_date date,
  p_local_time time,
  p_timezone text
)
RETURNS timestamptz
LANGUAGE sql
STABLE
AS $$
  SELECT (p_local_date::text || ' ' || p_local_time::text)::timestamp
    AT TIME ZONE p_timezone;
$$;

REVOKE ALL ON FUNCTION public.claim_due_notification_jobs(int) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.claim_due_notification_jobs(int) FROM authenticated;
GRANT EXECUTE ON FUNCTION public.claim_due_notification_jobs(int) TO service_role;

GRANT EXECUTE ON FUNCTION public.training_reminder_local_to_utc(date, time, text)
  TO authenticated, service_role;
