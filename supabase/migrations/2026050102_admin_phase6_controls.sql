-- Admin controls for Phase 6.
-- Trainer role and public trainer visibility are intentionally separate:
-- - profiles.role controls product capabilities.
-- - trainer_profiles.status controls public discovery visibility.

CREATE OR REPLACE FUNCTION public.admin_set_trainer_public_status(
  p_trainer_id uuid,
  p_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id uuid := auth.uid();
BEGIN
  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = v_admin_id AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Nur Admins koennen die Trainer-Sichtbarkeit verwalten.';
  END IF;

  IF p_status NOT IN ('active', 'suspended') THEN
    RAISE EXCEPTION 'Ungueltiger Trainer-Status.';
  END IF;

  UPDATE public.trainer_profiles
  SET status = p_status,
      approved_at = CASE
        WHEN p_status = 'active' THEN COALESCE(approved_at, now())
        ELSE approved_at
      END,
      approved_by = CASE
        WHEN p_status = 'active' THEN COALESCE(approved_by, v_admin_id)
        ELSE approved_by
      END,
      updated_at = now()
  WHERE id = p_trainer_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trainer-Profil nicht gefunden.';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_trainer_public_status(uuid, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_trainer_public_status(uuid, text) TO authenticated;

COMMENT ON FUNCTION public.admin_set_trainer_public_status(uuid, text)
  IS 'Admin-only control for public trainer discovery visibility.';
