-- PostGIS installs this static coordinate reference table in public.
-- It is safe to read, but clients must not be able to write to it.
--
-- On hosted Supabase (and the local CLI stack) spatial_ref_sys is owned by
-- supabase_admin, so the migration role cannot ALTER it — attempting to do so
-- aborts the whole migration run with SQLSTATE 42501. The table holds only
-- static PostGIS reference data (no user data) and is not client-writable
-- anyway, so when we lack ownership we skip with a NOTICE instead of failing.

DO $$
BEGIN
  IF to_regclass('public.spatial_ref_sys') IS NOT NULL THEN
    ALTER TABLE public.spatial_ref_sys ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS spatial_ref_sys_select_all ON public.spatial_ref_sys;
    CREATE POLICY spatial_ref_sys_select_all
      ON public.spatial_ref_sys FOR SELECT
      USING (true);
  END IF;
EXCEPTION
  WHEN insufficient_privilege THEN
    RAISE NOTICE 'spatial_ref_sys: not owner, skipping RLS enable (static PostGIS reference table)';
END;
$$;
