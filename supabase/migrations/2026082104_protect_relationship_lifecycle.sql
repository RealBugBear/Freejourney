-- trainer_client_relationships IS the authorization model: the trainer read
-- policies on enrollments, training_sessions, progress_entries and
-- mood_checkins all test for an active row in it. RLS there is row-level and
-- authenticated holds UPDATE on every column, so without this trigger either
-- party can rewrite the columns that define access.
--
-- Idempotent: safe to replay.

-- Drop first so a replay after the DEFINER draft does not preserve SECURITY
-- DEFINER via CREATE OR REPLACE (PostgreSQL keeps the old security mode when
-- the clause is omitted).
DROP TRIGGER IF EXISTS trg_prevent_direct_relationship_lifecycle_change
  ON public.trainer_client_relationships;
DROP FUNCTION IF EXISTS public.prevent_direct_relationship_lifecycle_change();

-- SECURITY INVOKER (PostgreSQL default): current_user must remain the session
-- role. SECURITY DEFINER would force current_user = postgres on every path and
-- the guard below would never fire. Nested under a DEFINER RPC, invoker still
-- sees current_user = postgres (the outer owner), so accept_invite /
-- end_trainer_relationship keep working. Do not switch to auth.role() — the
-- JWT claim stays 'authenticated' inside those RPCs and cannot separate paths.
CREATE OR REPLACE FUNCTION public.prevent_direct_relationship_lifecycle_change()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public, pg_temp
AS $function$
BEGIN
  -- current_user, NOT auth.role(). See comment above the function.
  IF current_user NOT IN ('authenticated', 'anon') THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    RAISE EXCEPTION
      'Relationships are created through accept_invite() only. '
      'Direct inserts are not permitted.';
  END IF;

  IF OLD.status                   IS DISTINCT FROM NEW.status
  OR OLD.trainer_id               IS DISTINCT FROM NEW.trainer_id
  OR OLD.client_id                IS DISTINCT FROM NEW.client_id
  OR OLD.ended_by_client_at       IS DISTINCT FROM NEW.ended_by_client_at
  OR OLD.end_notification_sent_at IS DISTINCT FROM NEW.end_notification_sent_at
  THEN
    RAISE EXCEPTION
      'Changing relationship lifecycle columns directly is not permitted. '
      'Use accept_invite() or end_trainer_relationship().';
  END IF;

  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION public.prevent_direct_relationship_lifecycle_change()
  FROM PUBLIC, anon, authenticated;

CREATE TRIGGER trg_prevent_direct_relationship_lifecycle_change
  BEFORE INSERT OR UPDATE ON public.trainer_client_relationships
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_direct_relationship_lifecycle_change();
