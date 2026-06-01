-- Harden static/config public tables that are safe to read but must never be
-- writable from anon/authenticated clients.

DO $$
BEGIN
  IF to_regclass('public.feature_flags') IS NOT NULL THEN
    ALTER TABLE public.feature_flags ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS feature_flags_select_all ON public.feature_flags;
    CREATE POLICY feature_flags_select_all
      ON public.feature_flags FOR SELECT
      USING (true);
  END IF;

  IF to_regclass('public.reflex_packages') IS NOT NULL THEN
    ALTER TABLE public.reflex_packages ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "cj: reflex_packages select all" ON public.reflex_packages;
    CREATE POLICY "cj: reflex_packages select all"
      ON public.reflex_packages FOR SELECT
      USING (true);
  END IF;

  IF to_regclass('public.exercises') IS NOT NULL THEN
    ALTER TABLE public.exercises ENABLE ROW LEVEL SECURITY;
    DROP POLICY IF EXISTS "cj: exercises select all" ON public.exercises;
    CREATE POLICY "cj: exercises select all"
      ON public.exercises FOR SELECT
      USING (true);
  END IF;
END;
$$;
