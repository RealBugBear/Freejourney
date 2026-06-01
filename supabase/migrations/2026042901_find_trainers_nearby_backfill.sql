-- Backfill trainer discovery foundations when the trainer-network migration was
-- not applied yet or PostgREST missed the function in its schema cache.

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS public.trainer_profiles (
  id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  display_name text NOT NULL,
  bio text,
  photo_url text,
  location_private geography(POINT, 4326),
  location_public geography(POINT, 4326),
  location_precision_m int NOT NULL DEFAULT 1000,
  location_updated_at timestamptz,
  status text NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'active', 'suspended')),
  approved_at timestamptz,
  approved_by uuid REFERENCES public.profiles(id),
  submitted_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_trainer_profiles_location_private
  ON public.trainer_profiles USING GIST (location_private);

CREATE INDEX IF NOT EXISTS idx_trainer_profiles_status
  ON public.trainer_profiles(status);

CREATE TABLE IF NOT EXISTS public.trainer_profile_private (
  trainer_id uuid PRIMARY KEY REFERENCES public.trainer_profiles(id) ON DELETE CASCADE,
  contact_email text NOT NULL,
  contact_phone text,
  admin_notes text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.trainer_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.trainer_profile_private ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS trainer_profiles_select_own_or_admin
  ON public.trainer_profiles;
CREATE POLICY trainer_profiles_select_own_or_admin
  ON public.trainer_profiles FOR SELECT
  USING (
    auth.uid() = id
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS trainer_profiles_admin_all
  ON public.trainer_profiles;
CREATE POLICY trainer_profiles_admin_all
  ON public.trainer_profiles FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS trainer_profile_private_select_own_or_admin
  ON public.trainer_profile_private;
CREATE POLICY trainer_profile_private_select_own_or_admin
  ON public.trainer_profile_private FOR SELECT
  USING (
    auth.uid() = trainer_id
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS trainer_profile_private_admin_all
  ON public.trainer_profile_private;
CREATE POLICY trainer_profile_private_admin_all
  ON public.trainer_profile_private FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

CREATE OR REPLACE FUNCTION public._jitter_location(
  p_location geography,
  p_precision_m int DEFAULT 1000
)
RETURNS geography
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_angle float8 := random() * 2 * pi();
  v_radius_deg float8 := (random() * p_precision_m / 111000.0);
  v_lat float8 := ST_Y(p_location::geometry);
  v_lng float8 := ST_X(p_location::geometry);
  v_offset_lat float8 := v_radius_deg * sin(v_angle);
  v_offset_lng float8 := v_radius_deg * cos(v_angle)
                          / NULLIF(cos(v_lat * pi() / 180.0), 0);
BEGIN
  RETURN ST_MakePoint(v_lng + v_offset_lng, v_lat + v_offset_lat)::geography;
END;
$$;

REVOKE ALL ON FUNCTION public._jitter_location(geography, int) FROM PUBLIC;

ALTER TABLE public.trainer_client_relationships
  ADD COLUMN IF NOT EXISTS source_type text NOT NULL DEFAULT 'invite';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.trainer_client_relationships'::regclass
      AND conname = 'trainer_client_relationships_source_type_check'
  ) THEN
    ALTER TABLE public.trainer_client_relationships
      ADD CONSTRAINT trainer_client_relationships_source_type_check
      CHECK (source_type IN ('invite', 'discovery'));
  END IF;
END $$;

DO $$
DECLARE
  v_con text;
BEGIN
  SELECT conname INTO v_con
  FROM pg_constraint
  WHERE conrelid = 'public.trainer_client_relationships'::regclass
    AND contype = 'u'
    AND array_to_string(
          ARRAY(
            SELECT attname
            FROM pg_attribute
            WHERE attrelid = conrelid
              AND attnum = ANY(conkey)
            ORDER BY attnum
          ),
          ','
        ) = 'trainer_id,client_id';

  IF v_con IS NOT NULL THEN
    EXECUTE format(
      'ALTER TABLE public.trainer_client_relationships DROP CONSTRAINT %I',
      v_con
    );
  END IF;
END $$;

CREATE UNIQUE INDEX IF NOT EXISTS uq_trainer_client_pending_discovery
  ON public.trainer_client_relationships(trainer_id, client_id)
  WHERE status = 'pending'
    AND source_type = 'discovery'
    AND client_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_trainer_client_active_pair
  ON public.trainer_client_relationships(trainer_id, client_id)
  WHERE status = 'active';

DROP FUNCTION IF EXISTS public.find_trainers_nearby(float8, float8, float8);

CREATE OR REPLACE FUNCTION public.find_trainers_nearby(
  lat       float8,
  lng       float8,
  radius_km float8 DEFAULT 25
)
RETURNS TABLE (
  id               uuid,
  display_name     text,
  bio              text,
  photo_url        text,
  distance_km      float8,
  public_latitude  float8,
  public_longitude float8,
  verified         boolean,
  status           text,
  submitted_at     timestamptz,
  has_location     boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tp.id,
    tp.display_name,
    tp.bio,
    tp.photo_url,
    ROUND((ST_Distance(
      tp.location_private,
      ST_MakePoint(lng, lat)::geography
    ) / 1000.0)::numeric, 0)::float8 AS distance_km,
    ST_Y(tp.location_public::geometry) AS public_latitude,
    ST_X(tp.location_public::geometry) AS public_longitude,
    (tp.status = 'active') AS verified,
    tp.status,
    tp.submitted_at,
    (tp.location_private IS NOT NULL) AS has_location
  FROM public.trainer_profiles tp
  WHERE
    auth.uid() IS NOT NULL
    AND lat BETWEEN -90 AND 90
    AND lng BETWEEN -180 AND 180
    AND radius_km BETWEEN 1 AND 100
    AND tp.status = 'active'
    AND tp.location_private IS NOT NULL
    AND tp.location_public IS NOT NULL
    AND ST_DWithin(
      tp.location_private,
      ST_MakePoint(lng, lat)::geography,
      radius_km * 1000
    )
  ORDER BY distance_km ASC;
$$;

GRANT EXECUTE ON FUNCTION public.find_trainers_nearby(float8, float8, float8)
  TO authenticated;

CREATE OR REPLACE FUNCTION public.send_discovery_request(p_trainer_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_client_id uuid := auth.uid();
  v_rel_id uuid;
BEGIN
  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.trainer_profiles
    WHERE id = p_trainer_id AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Trainer nicht gefunden oder nicht aktiv';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.trainer_client_relationships
    WHERE trainer_id = p_trainer_id
      AND client_id = v_client_id
      AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Bereits mit diesem Trainer verbunden';
  END IF;

  IF EXISTS (
    SELECT 1 FROM public.trainer_client_relationships
    WHERE trainer_id = p_trainer_id
      AND client_id = v_client_id
      AND status = 'pending'
      AND source_type = 'discovery'
  ) THEN
    RAISE EXCEPTION 'Anfrage bereits gesendet';
  END IF;

  INSERT INTO public.trainer_client_relationships (
    trainer_id,
    client_id,
    status,
    source_type
  )
  VALUES (
    p_trainer_id,
    v_client_id,
    'pending',
    'discovery'
  )
  RETURNING id INTO v_rel_id;

  RETURN v_rel_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_incoming_discovery_requests()
RETURNS TABLE (
  relationship_id uuid,
  client_id uuid,
  display_name text,
  created_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tcr.id AS relationship_id,
    tcr.client_id,
    p.display_name,
    tcr.created_at
  FROM public.trainer_client_relationships tcr
  JOIN public.profiles p ON p.id = tcr.client_id
  WHERE
    tcr.trainer_id = auth.uid()
    AND tcr.status = 'pending'
    AND tcr.source_type = 'discovery'
    AND tcr.client_id IS NOT NULL
  ORDER BY tcr.created_at ASC;
$$;

CREATE OR REPLACE FUNCTION public.respond_discovery_request(
  p_relationship_id uuid,
  p_accept boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trainer_id uuid := auth.uid();
  v_client_id uuid;
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  SELECT client_id INTO v_client_id
  FROM public.trainer_client_relationships
  WHERE id = p_relationship_id
    AND trainer_id = v_trainer_id
    AND status = 'pending'
    AND source_type = 'discovery';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Anfrage nicht gefunden';
  END IF;

  IF p_accept THEN
    UPDATE public.trainer_client_relationships
    SET status = 'disconnected'
    WHERE client_id = v_client_id AND status = 'active';

    UPDATE public.trainer_client_relationships
    SET status = 'active',
        linked_at = now()
    WHERE id = p_relationship_id;

    PERFORM public.ensure_trainer_client_relationship(v_client_id);
  ELSE
    UPDATE public.trainer_client_relationships
    SET status = 'disconnected'
    WHERE id = p_relationship_id;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.send_discovery_request(uuid)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_incoming_discovery_requests()
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.respond_discovery_request(uuid, boolean)
  TO authenticated;

NOTIFY pgrst, 'reload schema';
