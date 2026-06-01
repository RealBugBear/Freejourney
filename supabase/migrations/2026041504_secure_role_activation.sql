-- Prevent clients from directly escalating their own role via the Supabase API.
-- The role column may only be changed by requests authenticated with the
-- service_role key (i.e. Edge Functions). Authenticated-user requests that
-- attempt to write a different role value are rejected at the DB level,
-- regardless of what RLS policies allow.

CREATE OR REPLACE FUNCTION public.prevent_direct_role_change()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- auth.role() returns 'service_role' when the request comes through an Edge
  -- Function using the service-role key, and 'authenticated' for normal users.
  IF auth.role() != 'service_role' AND OLD.role IS DISTINCT FROM NEW.role THEN
    RAISE EXCEPTION
      'Changing the role column directly is not permitted. '
      'Use the activate-trainer Edge Function.';
  END IF;
  RETURN NEW;
END;
$$;

-- Drop first so the migration is idempotent on re-run.
DROP TRIGGER IF EXISTS trg_prevent_direct_role_change ON public.profiles;

CREATE TRIGGER trg_prevent_direct_role_change
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.prevent_direct_role_change();
