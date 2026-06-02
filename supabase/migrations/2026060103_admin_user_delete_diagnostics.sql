-- Temporary-safe SQL Editor diagnostic helper for user deletion blockers.
-- It reports rows that still reference a user through foreign keys to
-- public.profiles or auth.users, including each FK's delete behavior.
-- Do not grant this helper to authenticated app users; it is intended for
-- privileged SQL Editor use while debugging admin/test-user deletion.

CREATE OR REPLACE FUNCTION public.get_admin_user_delete_references(
  p_email text DEFAULT NULL,
  p_user_id uuid DEFAULT NULL
)
RETURNS TABLE (
  table_name text,
  column_name text,
  constraint_name text,
  references_table text,
  delete_behavior text,
  row_count bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := p_user_id;
  v_ref record;
  v_count bigint;
BEGIN
  IF v_user_id IS NULL AND NULLIF(trim(COALESCE(p_email, '')), '') IS NOT NULL THEN
    SELECT id INTO v_user_id
    FROM auth.users
    WHERE lower(email) = lower(trim(p_email))
    LIMIT 1;
  END IF;

  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'p_email or p_user_id must identify an auth user';
  END IF;

  FOR v_ref IN
    SELECT
      n.nspname AS schema_name,
      cl.relname AS rel_name,
      a.attname AS column_name,
      c.conname AS constraint_name,
      rn.nspname || '.' || rcl.relname AS references_table,
      CASE c.confdeltype
        WHEN 'a' THEN 'NO ACTION'
        WHEN 'r' THEN 'RESTRICT'
        WHEN 'c' THEN 'CASCADE'
        WHEN 'n' THEN 'SET NULL'
        WHEN 'd' THEN 'SET DEFAULT'
        ELSE c.confdeltype::text
      END AS delete_behavior
    FROM pg_constraint c
    JOIN pg_class cl ON cl.oid = c.conrelid
    JOIN pg_namespace n ON n.oid = cl.relnamespace
    JOIN pg_class rcl ON rcl.oid = c.confrelid
    JOIN pg_namespace rn ON rn.oid = rcl.relnamespace
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
    WHERE c.contype = 'f'
      AND c.confrelid IN ('public.profiles'::regclass, 'auth.users'::regclass)
    ORDER BY n.nspname, cl.relname, a.attname
  LOOP
    EXECUTE format(
      'SELECT count(*) FROM %I.%I WHERE %I = $1',
      v_ref.schema_name,
      v_ref.rel_name,
      v_ref.column_name
    )
    INTO v_count
    USING v_user_id;

    IF v_count > 0 THEN
      table_name := v_ref.schema_name || '.' || v_ref.rel_name;
      column_name := v_ref.column_name;
      constraint_name := v_ref.constraint_name;
      references_table := v_ref.references_table;
      delete_behavior := v_ref.delete_behavior;
      row_count := v_count;
      RETURN NEXT;
    END IF;
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_user_delete_references(text, uuid) FROM PUBLIC;

COMMENT ON FUNCTION public.get_admin_user_delete_references(text, uuid)
  IS 'SQL Editor diagnostic report for rows that reference a user and may block auth user deletion.';
