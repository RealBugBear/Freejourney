-- CoreJourney — Trainer application code generation hotfix
-- Fixes ambiguous `code` references in approve_trainer_application after the
-- function was changed to return a column named `code`.

CREATE OR REPLACE FUNCTION public.approve_trainer_application(
  p_application_id uuid
)
RETURNS TABLE (
  code text,
  expires_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id uuid := auth.uid();
  v_application public.trainer_applications%ROWTYPE;
  v_code text;
  v_code_id uuid;
  v_expires_at timestamptz := now() + interval '14 days';
BEGIN
  IF NOT public._is_admin(v_admin_id) THEN
    RAISE EXCEPTION 'Nur Admins können Bewerbungen freigeben';
  END IF;

  SELECT * INTO v_application
  FROM public.trainer_applications
  WHERE id = p_application_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Bewerbung nicht gefunden';
  END IF;

  IF v_application.status NOT IN ('submitted', 'in_review', 'needs_more_info') THEN
    RAISE EXCEPTION 'Bewerbung ist nicht freigabefähig';
  END IF;

  IF v_application.background_check_required
     AND v_application.background_check_verified_at IS NULL THEN
    RAISE EXCEPTION 'Führungszeugnis-Sichtprüfung fehlt';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = v_application.user_id AND role = 'trainer'
  ) THEN
    RAISE EXCEPTION 'Nutzer ist bereits Trainer';
  END IF;

  LOOP
    v_code := public._trainer_activation_code();
    EXIT WHEN NOT EXISTS (
      SELECT 1 FROM public.trainer_invite_codes tic WHERE tic.code = v_code
    );
  END LOOP;

  INSERT INTO public.trainer_invite_codes (
    code,
    created_by,
    expires_at,
    trainer_application_id,
    purpose
  )
  VALUES (
    v_code,
    v_admin_id,
    v_expires_at,
    p_application_id,
    'trainer_application_approval'
  )
  RETURNING id INTO v_code_id;

  UPDATE public.trainer_applications
  SET status = 'approved',
      reviewed_by = v_admin_id,
      reviewed_at = now(),
      activation_code_id = v_code_id,
      updated_at = now()
  WHERE id = p_application_id;

  PERFORM public._trainer_application_audit(
    p_application_id,
    v_admin_id,
    'activation_code_created',
    jsonb_build_object('code_id', v_code_id, 'expires_at', v_expires_at)
  );

  RETURN QUERY SELECT v_code, v_expires_at;
END;
$$;

GRANT EXECUTE ON FUNCTION public.approve_trainer_application(uuid)
  TO authenticated;

NOTIFY pgrst, 'reload schema';
