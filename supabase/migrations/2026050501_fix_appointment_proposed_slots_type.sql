-- CoreJourney - repair appointment proposal slot type drift.
--
-- Some databases still have appointments.proposed_slots as jsonb from an
-- earlier proposal model. The current RPCs use timestamptz[] so proposed
-- appointment creation fails unless the column type is aligned.

CREATE OR REPLACE FUNCTION public._corejourney_jsonb_to_timestamptz_array(
  p_value jsonb
)
RETURNS timestamptz[]
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT COALESCE(
    array_agg(slot_value::timestamptz ORDER BY slot_order),
    ARRAY[]::timestamptz[]
  )
  FROM jsonb_array_elements_text(
    CASE
      WHEN p_value IS NOT NULL AND jsonb_typeof(p_value) = 'array' THEN p_value
      ELSE '[]'::jsonb
    END
  ) WITH ORDINALITY AS slots(slot_value, slot_order);
$$;

DO $$
DECLARE
  v_column_type text;
BEGIN
  SELECT format_type(attribute.atttypid, attribute.atttypmod)
  INTO v_column_type
  FROM pg_attribute attribute
  JOIN pg_class relation
    ON relation.oid = attribute.attrelid
  JOIN pg_namespace namespace
    ON namespace.oid = relation.relnamespace
  WHERE namespace.nspname = 'public'
    AND relation.relname = 'appointments'
    AND attribute.attname = 'proposed_slots'
    AND NOT attribute.attisdropped;

  IF v_column_type IS NULL THEN
    ALTER TABLE public.appointments
      ADD COLUMN proposed_slots timestamptz[] NOT NULL DEFAULT '{}';
  ELSIF v_column_type = 'jsonb' THEN
    ALTER TABLE public.appointments
      ALTER COLUMN proposed_slots DROP DEFAULT;

    ALTER TABLE public.appointments
      ALTER COLUMN proposed_slots TYPE timestamptz[]
      USING public._corejourney_jsonb_to_timestamptz_array(proposed_slots);

    ALTER TABLE public.appointments
      ALTER COLUMN proposed_slots SET DEFAULT '{}',
      ALTER COLUMN proposed_slots SET NOT NULL;
  ELSIF v_column_type = 'timestamp with time zone[]' THEN
    ALTER TABLE public.appointments
      ALTER COLUMN proposed_slots SET DEFAULT '{}',
      ALTER COLUMN proposed_slots SET NOT NULL;
  ELSE
    RAISE EXCEPTION
      'appointments.proposed_slots has unsupported type: %',
      v_column_type;
  END IF;
END;
$$;

DROP FUNCTION public._corejourney_jsonb_to_timestamptz_array(jsonb);

NOTIFY pgrst, 'reload schema';
