-- Recover interrupted workers and transient provider failures with bounded retry.
-- updated_at is the claim lease; attempt_count fences stale worker results.
-- Existing statuses and RPC return shape are preserved for older deployments.
ALTER TABLE public.notification_jobs ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

CREATE INDEX IF NOT EXISTS notification_jobs_retry_due_idx
  ON public.notification_jobs(status, updated_at)
  WHERE status IN ('failed', 'sending');

CREATE OR REPLACE FUNCTION public.claim_due_notification_jobs(p_limit int DEFAULT 50)
RETURNS SETOF public.notification_jobs
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- A worker that died on its last attempt must not remain 'sending' forever.
  UPDATE public.notification_jobs
    SET status = 'failed', last_error = 'retry_exhausted', updated_at = now()
    WHERE status = 'sending' AND attempt_count >= 5
      AND updated_at < now() - interval '10 minutes';

  RETURN QUERY
  WITH due AS (
    SELECT id FROM public.notification_jobs
    WHERE attempt_count < 5 AND scheduled_for <= now() AND (
      status = 'pending'
      OR (status = 'sending' AND updated_at < now() - interval '10 minutes')
      OR (status = 'failed' AND updated_at < now() -
        interval '1 second' * LEAST(1800, 30 * power(2, LEAST(attempt_count, 6))))
    )
    ORDER BY scheduled_for, id
    FOR UPDATE SKIP LOCKED
    LIMIT LEAST(GREATEST(COALESCE(p_limit, 50), 1), 100)
  )
  UPDATE public.notification_jobs AS job
    SET status = 'sending', attempt_count = job.attempt_count + 1,
        updated_at = now(), last_error = NULL
    FROM due WHERE job.id = due.id
    RETURNING job.*;
END;
$$;
REVOKE ALL ON FUNCTION public.claim_due_notification_jobs(int) FROM PUBLIC, authenticated;
GRANT EXECUTE ON FUNCTION public.claim_due_notification_jobs(int) TO service_role;
