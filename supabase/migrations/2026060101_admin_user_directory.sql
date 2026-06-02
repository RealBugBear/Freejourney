-- Admin-only user directory for the web dashboard.
-- Email addresses are personal data; expose them only to authenticated admins
-- for account support and role/subscription administration.
CREATE OR REPLACE FUNCTION public.get_admin_user_directory(
  p_search text DEFAULT NULL,
  p_limit int DEFAULT 500
)
RETURNS TABLE (
  id uuid,
  email text,
  display_name text,
  role text,
  subscription_tier text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_search text := NULLIF(trim(COALESCE(p_search, '')), '');
  v_limit int := LEAST(GREATEST(COALESCE(p_limit, 500), 1), 500);
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE profiles.id = auth.uid()
      AND profiles.role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can read the user directory';
  END IF;

  RETURN QUERY
  SELECT
    p.id,
    u.email::text,
    p.display_name,
    p.role,
    p.subscription_tier
  FROM public.profiles p
  LEFT JOIN auth.users u
    ON u.id = p.id
  WHERE
    v_search IS NULL
    OR p.display_name ILIKE '%' || v_search || '%'
    OR u.email ILIKE '%' || v_search || '%'
    OR p.id::text ILIKE '%' || v_search || '%'
  ORDER BY
    lower(COALESCE(p.display_name, u.email, p.id::text))
  LIMIT v_limit;
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_user_directory(text, int) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_user_directory(text, int) TO authenticated;

COMMENT ON FUNCTION public.get_admin_user_directory(text, int)
  IS 'Admin-only directory joining profiles with auth.users email for account support and role administration.';
