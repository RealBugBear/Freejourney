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

CREATE OR REPLACE FUNCTION public.ensure_trainer_client_relationship(p_client_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  v_trainer_id uuid := auth.uid();
  v_relationship_id uuid;
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
     WHERE id = v_trainer_id AND role = 'trainer'
  ) THEN
    RAISE EXCEPTION 'Nur Trainer koennen Klienten verknuepfen';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM public.profiles WHERE id = p_client_id) THEN
    RAISE EXCEPTION 'Klient nicht gefunden';
  END IF;

  -- 2. An active row is the ground truth and wins over any stale marker.
  SELECT id INTO v_relationship_id
    FROM public.trainer_client_relationships
   WHERE trainer_id = v_trainer_id
     AND client_id  = p_client_id
     AND status     = 'active'
   LIMIT 1;

  IF v_relationship_id IS NOT NULL THEN
    RETURN v_relationship_id;
  END IF;

  -- 3. Pair-wide guard. Early RETURN NULL: merely skipping branch 4 would fall
  --    through to the INSERT and recreate the relationship under a new id.
  IF EXISTS (
    SELECT 1 FROM public.trainer_client_relationships
     WHERE trainer_id = v_trainer_id
       AND client_id  = p_client_id
       AND ended_by_client_at IS NOT NULL
  ) THEN
    RETURN NULL;
  END IF;

  -- 4. Reuse the canonical disconnected row. Ordering must match accept_invite.
  SELECT id INTO v_relationship_id
    FROM public.trainer_client_relationships
   WHERE trainer_id = v_trainer_id
     AND client_id  = p_client_id
     AND status     = 'disconnected'
   ORDER BY linked_at DESC NULLS LAST, created_at DESC, id DESC
   LIMIT 1;

  IF v_relationship_id IS NOT NULL THEN
    UPDATE public.trainer_client_relationships
       SET status    = 'active',
           linked_at = COALESCE(linked_at, now())
     WHERE id = v_relationship_id;
    RETURN v_relationship_id;
  END IF;

  -- 5. First contact.
  INSERT INTO public.trainer_client_relationships
    (trainer_id, client_id, status, linked_at)
  VALUES (v_trainer_id, p_client_id, 'active', now())
  RETURNING id INTO v_relationship_id;

  RETURN v_relationship_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.ensure_trainer_client_relationship(uuid)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.ensure_trainer_client_relationship(uuid)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.accept_invite(p_code text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
DECLARE
  _invite public.trainer_client_relationships%rowtype;
  _client uuid := auth.uid();
  _exist  uuid;
BEGIN
  IF _client IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  SELECT * INTO _invite
    FROM public.trainer_client_relationships
   WHERE invite_code = upper(trim(p_code))
     AND status      = 'pending'
     AND client_id IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid or already used invite code';
  END IF;

  -- Displacing a trainer is as deliberate an act as ending one, so it marks.
  -- Also fires the reflex-share revoke trigger for each displaced pair.
  UPDATE public.trainer_client_relationships
     SET status             = 'disconnected',
         ended_by_client_at = COALESCE(ended_by_client_at, now())
   WHERE client_id = _client
     AND status    = 'active';

  -- Clear markers PAIR-WIDE for the incoming trainer. Clearing only the row
  -- selected below would leave a second marked row behind, and the pair-wide
  -- guard in ensure_trainer_client_relationship() would then wedge the pair
  -- out of reconciliation permanently.
  UPDATE public.trainer_client_relationships
     SET ended_by_client_at       = NULL,
         end_notification_sent_at = NULL
   WHERE trainer_id = _invite.trainer_id
     AND client_id  = _client;

  -- Canonical row selection. Ordering must match ensure_trainer_client_relationship.
  SELECT id INTO _exist
    FROM public.trainer_client_relationships
   WHERE trainer_id = _invite.trainer_id
     AND client_id  = _client
     AND status     = 'disconnected'
   ORDER BY linked_at DESC NULLS LAST, created_at DESC, id DESC
   LIMIT 1;

  IF _exist IS NOT NULL THEN
    UPDATE public.trainer_client_relationships
       SET status = 'active', linked_at = now()
     WHERE id = _exist;

    DELETE FROM public.trainer_client_relationships WHERE id = _invite.id;
  ELSE
    UPDATE public.trainer_client_relationships
       SET client_id = _client,
           status    = 'active',
           linked_at = now()
     WHERE id = _invite.id;
  END IF;
END;
$function$;

REVOKE ALL ON FUNCTION public.accept_invite(text) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_invite(text) TO authenticated;
