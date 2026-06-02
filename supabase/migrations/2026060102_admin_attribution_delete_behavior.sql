-- Admin/test accounts that have performed admin actions should still be
-- deletable after demotion. Keep historical rows, but null attribution FKs
-- instead of blocking auth.users -> profiles cascade deletes.

CREATE OR REPLACE FUNCTION public._replace_profile_fk_with_set_null(
  p_table regclass,
  p_column text
)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_constraint text;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_attribute
    WHERE attrelid = p_table
      AND attname = p_column
      AND NOT attisdropped
  ) THEN
    RETURN;
  END IF;

  EXECUTE format(
    'ALTER TABLE %s ALTER COLUMN %I DROP NOT NULL',
    p_table,
    p_column
  );

  FOR v_constraint IN
    SELECT c.conname
    FROM pg_constraint c
    JOIN pg_attribute a
      ON a.attrelid = c.conrelid
     AND a.attnum = ANY(c.conkey)
    WHERE c.conrelid = p_table
      AND c.contype = 'f'
      AND a.attname = p_column
  LOOP
    EXECUTE format(
      'ALTER TABLE %s DROP CONSTRAINT IF EXISTS %I',
      p_table,
      v_constraint
    );
  END LOOP;

  EXECUTE format(
    'ALTER TABLE %s ADD CONSTRAINT %I FOREIGN KEY (%I) REFERENCES public.profiles(id) ON DELETE SET NULL',
    p_table,
    replace(replace(p_table::text, '.', '_'), '"', '') || '_' || p_column || '_profiles_set_null_fkey',
    p_column
  );
END;
$$;

SELECT public._replace_profile_fk_with_set_null('public.admin_audit_events'::regclass, 'actor_id');

SELECT public._replace_profile_fk_with_set_null('public.trainer_application_audit_events'::regclass, 'actor_id');
SELECT public._replace_profile_fk_with_set_null('public.trainer_applications'::regclass, 'background_check_verified_by');
SELECT public._replace_profile_fk_with_set_null('public.trainer_applications'::regclass, 'assigned_reviewer');
SELECT public._replace_profile_fk_with_set_null('public.trainer_applications'::regclass, 'reviewed_by');

SELECT public._replace_profile_fk_with_set_null('public.trainer_profiles'::regclass, 'approved_by');

SELECT public._replace_profile_fk_with_set_null('public.trainer_invite_codes'::regclass, 'created_by');
SELECT public._replace_profile_fk_with_set_null('public.trainer_invite_codes'::regclass, 'used_by');

SELECT public._replace_profile_fk_with_set_null('public.access_codes'::regclass, 'created_by');

SELECT public._replace_profile_fk_with_set_null('public.video_calls'::regclass, 'started_by');

DROP FUNCTION public._replace_profile_fk_with_set_null(regclass, text);
