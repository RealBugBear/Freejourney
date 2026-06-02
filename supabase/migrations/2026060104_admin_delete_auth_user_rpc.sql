-- Controlled auth user delete for the admin web dashboard.
-- Supabase Auth Admin API can return a generic "Database error deleting user"
-- even when a direct auth.users delete succeeds. This RPC keeps the same
-- safety checks and performs the database delete through SQL.

CREATE OR REPLACE FUNCTION public.admin_delete_auth_user(
  p_actor_id uuid,
  p_user_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_target_role text;
BEGIN
  IF p_actor_id IS NULL OR p_user_id IS NULL THEN
    RAISE EXCEPTION 'p_actor_id and p_user_id are required';
  END IF;

  IF p_actor_id = p_user_id THEN
    RAISE EXCEPTION 'Admins cannot delete their own account';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = p_actor_id
      AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can delete users';
  END IF;

  SELECT role INTO v_target_role
  FROM public.profiles
  WHERE id = p_user_id;

  IF v_target_role = 'admin' THEN
    RAISE EXCEPTION 'Deleting admin accounts is blocked here. Demote first if this is intentional.';
  END IF;

  DELETE FROM auth.users
  WHERE id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Auth user not found';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_delete_auth_user(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_delete_auth_user(uuid, uuid) TO service_role;

COMMENT ON FUNCTION public.admin_delete_auth_user(uuid, uuid)
  IS 'Service-role-only RPC for admin web user deletion after explicit admin and target-role checks.';
