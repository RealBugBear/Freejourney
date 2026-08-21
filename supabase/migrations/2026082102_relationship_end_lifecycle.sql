-- Client-initiated end of a trainer accompaniment.
-- Spec: docs/superpowers/specs/2026-08-21-begleitung-beenden-design.md
-- Idempotent: safe to replay.

ALTER TABLE public.trainer_client_relationships
  ADD COLUMN IF NOT EXISTS ended_by_client_at       timestamptz,
  ADD COLUMN IF NOT EXISTS end_notification_sent_at timestamptz;

COMMENT ON COLUMN public.trainer_client_relationships.ended_by_client_at IS
  'Set when the client deliberately ended or switched away. Blocks automatic '
  'resurrection by ensure_trainer_client_relationship(). Cleared pair-wide by '
  'accept_invite().';
COMMENT ON COLUMN public.trainer_client_relationships.end_notification_sent_at IS
  'Atomic claim for notify-accompaniment-ended. At-most-once by design.';

CREATE OR REPLACE FUNCTION public.end_trainer_relationship(p_trainer_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  v_client uuid := auth.uid();
  v_relationship_id uuid;
BEGIN
  IF v_client IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  -- The caller must be the CLIENT of the relationship being ended.
  SELECT id
    INTO v_relationship_id
    FROM public.trainer_client_relationships
   WHERE trainer_id = p_trainer_id
     AND client_id  = v_client
     AND status     = 'active'
   LIMIT 1;

  IF v_relationship_id IS NULL THEN
    RAISE EXCEPTION 'Keine aktive Begleitung mit diesem Trainer';
  END IF;

  -- Fires trg_revoke_reflex_shares_on_relationship_end, which revokes the
  -- reflex profile shares. Deliberately not duplicated here.
  UPDATE public.trainer_client_relationships
     SET status             = 'disconnected',
         ended_by_client_at = now()
   WHERE id = v_relationship_id;

  -- Every open appointment, regardless of date: a past unresolved proposal
  -- would otherwise linger as a zombie.
  UPDATE public.appointments
     SET status     = 'cancelled',
         updated_at = now()
   WHERE trainer_id = p_trainer_id
     AND trainee_id = v_client
     AND status IN ('proposed', 'planned', 'confirmed');
END;
$function$;

REVOKE ALL ON FUNCTION public.end_trainer_relationship(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.end_trainer_relationship(uuid) TO authenticated;
