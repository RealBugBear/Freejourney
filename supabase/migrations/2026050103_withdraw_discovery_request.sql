-- Let clients withdraw their own open trainer discovery request.
-- We delete the pending discovery relationship instead of introducing a new
-- status because trainer_client_relationships only allows pending, active,
-- and disconnected in the canonical schema.

CREATE OR REPLACE FUNCTION public.withdraw_discovery_request(
  p_relationship_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_client_id uuid := auth.uid();
  v_relationship_id uuid;
BEGIN
  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt.';
  END IF;

  SELECT id
  INTO v_relationship_id
  FROM public.trainer_client_relationships
  WHERE id = p_relationship_id
    AND client_id = v_client_id
    AND status = 'pending'
    AND source_type = 'discovery'
  FOR UPDATE;

  IF v_relationship_id IS NULL THEN
    RAISE EXCEPTION 'Anfrage nicht gefunden oder nicht mehr offen.';
  END IF;

  DELETE FROM public.trainer_client_relationships
  WHERE id = v_relationship_id;
END;
$$;

REVOKE ALL ON FUNCTION public.withdraw_discovery_request(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.withdraw_discovery_request(uuid) TO authenticated;

COMMENT ON FUNCTION public.withdraw_discovery_request(uuid)
  IS 'Withdraws the authenticated client''s own pending discovery request.';
