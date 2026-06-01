-- CoreJourney — Harden trainer/client relationship recovery
-- Idempotent: safe to re-run.
--
-- The canonical trainer client list is trainer_client_relationships.
-- This migration repairs missing active rows when an authenticated trainer has
-- already interacted with a client through appointments or a direct chat.

CREATE OR REPLACE FUNCTION ensure_trainer_client_relationship(p_client_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trainer_id uuid := auth.uid();
  v_relationship_id uuid;
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM profiles
    WHERE id = v_trainer_id
      AND role = 'trainer'
  ) THEN
    RAISE EXCEPTION 'Nur Trainer koennen Klienten verknuepfen';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM profiles
    WHERE id = p_client_id
  ) THEN
    RAISE EXCEPTION 'Klient nicht gefunden';
  END IF;

  SELECT id
  INTO v_relationship_id
  FROM trainer_client_relationships
  WHERE trainer_id = v_trainer_id
    AND client_id = p_client_id
    AND status = 'active'
  LIMIT 1;

  IF v_relationship_id IS NOT NULL THEN
    RETURN v_relationship_id;
  END IF;

  SELECT id
  INTO v_relationship_id
  FROM trainer_client_relationships
  WHERE trainer_id = v_trainer_id
    AND client_id = p_client_id
    AND status = 'disconnected'
  ORDER BY linked_at DESC NULLS LAST, created_at DESC
  LIMIT 1;

  IF v_relationship_id IS NOT NULL THEN
    UPDATE trainer_client_relationships
    SET status = 'active',
        linked_at = COALESCE(linked_at, now())
    WHERE id = v_relationship_id;

    RETURN v_relationship_id;
  END IF;

  INSERT INTO trainer_client_relationships (
    trainer_id,
    client_id,
    status,
    linked_at
  )
  VALUES (
    v_trainer_id,
    p_client_id,
    'active',
    now()
  )
  RETURNING id INTO v_relationship_id;

  RETURN v_relationship_id;
END;
$$;

CREATE OR REPLACE FUNCTION reconcile_trainer_clients()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trainer_id uuid := auth.uid();
  v_client_id uuid;
BEGIN
  IF v_trainer_id IS NULL THEN
    RETURN;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM profiles
    WHERE id = v_trainer_id
      AND role = 'trainer'
  ) THEN
    RETURN;
  END IF;

  -- Appointment history proves an operational trainer/client relationship.
  FOR v_client_id IN
    SELECT DISTINCT trainee_id
    FROM appointments
    WHERE trainer_id = v_trainer_id
      AND status IN ('proposed', 'planned', 'confirmed')
  LOOP
    PERFORM ensure_trainer_client_relationship(v_client_id);
  END LOOP;

  -- Direct chat membership is also a real operational link for the trainer UI.
  FOR v_client_id IN
    SELECT DISTINCT other_member.user_id
    FROM chat_channel_members self_member
    JOIN chat_channels channel
      ON channel.id = self_member.channel_id
     AND channel.type = 'direct'
    JOIN chat_channel_members other_member
      ON other_member.channel_id = self_member.channel_id
     AND other_member.user_id <> v_trainer_id
    LEFT JOIN profiles other_profile
      ON other_profile.id = other_member.user_id
    WHERE self_member.user_id = v_trainer_id
      AND self_member.role = 'moderator'
      AND COALESCE(other_profile.role, 'practitioner') <> 'trainer'
  LOOP
    PERFORM ensure_trainer_client_relationship(v_client_id);
  END LOOP;
END;
$$;

CREATE OR REPLACE FUNCTION get_trainer_clients()
RETURNS TABLE (
  relationship_id uuid,
  client_id uuid,
  display_name text,
  package_id text,
  current_day int,
  daily_streak int,
  last_activity_date date,
  trainer_notes text,
  linked_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM reconcile_trainer_clients();

  RETURN QUERY
  SELECT
    tcr.id AS relationship_id,
    tcr.client_id,
    COALESCE(NULLIF(p.display_name, ''), p.id::text) AS display_name,
    e.package_id,
    COALESCE(pe.current_day, 1) AS current_day,
    COALESCE(pe.daily_streak, 0) AS daily_streak,
    pe.last_activity_date,
    tcr.trainer_notes,
    tcr.linked_at
  FROM trainer_client_relationships tcr
  JOIN profiles p
    ON p.id = tcr.client_id
  LEFT JOIN enrollments e
    ON e.user_id = tcr.client_id
   AND e.status = 'active'
  LEFT JOIN progress_entries pe
    ON pe.enrollment_id = e.id
  WHERE tcr.trainer_id = auth.uid()
    AND tcr.status = 'active'
  ORDER BY pe.current_day DESC NULLS LAST, tcr.linked_at DESC NULLS LAST;
END;
$$;

GRANT EXECUTE ON FUNCTION ensure_trainer_client_relationship(uuid)
  TO authenticated;
GRANT EXECUTE ON FUNCTION reconcile_trainer_clients()
  TO authenticated;
GRANT EXECUTE ON FUNCTION get_trainer_clients()
  TO authenticated;
