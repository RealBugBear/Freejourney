-- CoreJourney — Trainer Network
-- PostGIS extension, trainer_profiles, trainer_profile_private,
-- source_type on trainer_client_relationships, all RPCs, RLS.
-- Idempotent: safe to re-run.

-- ── 0. PostGIS ────────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS postgis;

-- ── 1. trainer_profiles ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS trainer_profiles (
  id                   uuid PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  display_name         text NOT NULL,
  bio                  text,
  photo_url            text,
  location_private     geography(POINT, 4326),
  location_public      geography(POINT, 4326),
  location_precision_m int  NOT NULL DEFAULT 1000,
  location_updated_at  timestamptz,
  status               text NOT NULL DEFAULT 'pending'
                       CHECK (status IN ('pending', 'active', 'suspended')),
  approved_at          timestamptz,
  approved_by          uuid REFERENCES profiles(id),
  submitted_at         timestamptz NOT NULL DEFAULT now(),
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_trainer_profiles_location_private
  ON trainer_profiles USING GIST (location_private);

CREATE INDEX IF NOT EXISTS idx_trainer_profiles_status
  ON trainer_profiles (status);

-- ── 2. trainer_profile_private ───────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS trainer_profile_private (
  trainer_id    uuid PRIMARY KEY REFERENCES trainer_profiles(id) ON DELETE CASCADE,
  contact_email text NOT NULL,
  contact_phone text,
  admin_notes   text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

-- ── 3. source_type on trainer_client_relationships ───────────────────────────

ALTER TABLE trainer_client_relationships
  ADD COLUMN IF NOT EXISTS source_type text NOT NULL DEFAULT 'invite'
  CHECK (source_type IN ('invite', 'discovery'));

-- Drop the old blanket-unique constraint (added by 20260424_atomic_trainer_switch.sql)
-- to allow multiple rows per (trainer_id, client_id) across different source_types and statuses.
DO $$
DECLARE
  v_con text;
BEGIN
  SELECT conname INTO v_con
  FROM pg_constraint
  WHERE conrelid = 'trainer_client_relationships'::regclass
    AND contype = 'u'
    AND array_to_string(
          ARRAY(SELECT attname FROM pg_attribute
                WHERE attrelid = conrelid
                  AND attnum = ANY(conkey)
                ORDER BY attnum),
          ',') = 'trainer_id,client_id';
  IF v_con IS NOT NULL THEN
    EXECUTE format('ALTER TABLE trainer_client_relationships DROP CONSTRAINT %I', v_con);
  END IF;
END;
$$;

-- One pending discovery request per trainer-client pair
CREATE UNIQUE INDEX IF NOT EXISTS uq_trainer_client_pending_discovery
  ON trainer_client_relationships(trainer_id, client_id)
  WHERE status = 'pending' AND source_type = 'discovery' AND client_id IS NOT NULL;

-- One active relationship per trainer-client pair (invariant: a client has at most one active trainer)
CREATE UNIQUE INDEX IF NOT EXISTS uq_trainer_client_active_pair
  ON trainer_client_relationships(trainer_id, client_id)
  WHERE status = 'active';

-- ── 4. RLS ────────────────────────────────────────────────────────────────────

ALTER TABLE trainer_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Trainer reads own profile" ON trainer_profiles;
CREATE POLICY "Trainer reads own profile"
  ON trainer_profiles FOR SELECT
  USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins manage all trainer profiles" ON trainer_profiles;
CREATE POLICY "Admins manage all trainer profiles"
  ON trainer_profiles FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

ALTER TABLE trainer_profile_private ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Trainer sees own private profile" ON trainer_profile_private;
CREATE POLICY "Trainer sees own private profile"
  ON trainer_profile_private FOR SELECT
  USING (auth.uid() = trainer_id);

DROP POLICY IF EXISTS "Admins manage private trainer profiles" ON trainer_profile_private;
CREATE POLICY "Admins manage private trainer profiles"
  ON trainer_profile_private FOR ALL
  USING (
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ── 5. Helper: jitter a geography point ──────────────────────────────────────

CREATE OR REPLACE FUNCTION _jitter_location(
  p_location    geography,
  p_precision_m int DEFAULT 1000
)
RETURNS geography
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_angle       float8 := random() * 2 * pi();
  v_radius_deg  float8 := (random() * p_precision_m / 111000.0);
  v_lat         float8 := ST_Y(p_location::geometry);
  v_lng         float8 := ST_X(p_location::geometry);
  v_offset_lat  float8 := v_radius_deg * sin(v_angle);
  v_offset_lng  float8 := v_radius_deg * cos(v_angle)
                          / NULLIF(cos(v_lat * pi() / 180.0), 0);
BEGIN
  RETURN ST_MakePoint(v_lng + v_offset_lng, v_lat + v_offset_lat)::geography;
END;
$$;

REVOKE ALL ON FUNCTION _jitter_location(geography, int) FROM PUBLIC;

-- ── 6. upsert_trainer_profile ─────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION upsert_trainer_profile(
  p_display_name  text,
  p_bio           text    DEFAULT NULL,
  p_photo_url     text    DEFAULT NULL,
  p_contact_email text    DEFAULT NULL,
  p_contact_phone text    DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = v_user_id AND role = 'trainer') THEN
    RAISE EXCEPTION 'Nur Trainer können ein Trainer-Profil anlegen';
  END IF;

  IF trim(COALESCE(p_display_name, '')) = '' THEN
    RAISE EXCEPTION 'Anzeigename fehlt';
  END IF;

  INSERT INTO trainer_profiles (id, display_name, bio, photo_url)
  VALUES (v_user_id, trim(p_display_name), NULLIF(trim(COALESCE(p_bio, '')), ''), NULLIF(trim(COALESCE(p_photo_url, '')), ''))
  ON CONFLICT (id) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    bio          = EXCLUDED.bio,
    photo_url    = EXCLUDED.photo_url,
    updated_at   = now();

  IF p_contact_email IS NOT NULL THEN
    INSERT INTO trainer_profile_private (trainer_id, contact_email, contact_phone)
    VALUES (v_user_id, trim(p_contact_email), NULLIF(trim(COALESCE(p_contact_phone, '')), ''))
    ON CONFLICT (trainer_id) DO UPDATE SET
      contact_email = EXCLUDED.contact_email,
      contact_phone = EXCLUDED.contact_phone,
      updated_at    = now();
  END IF;
END;
$$;

-- ── 7. upsert_trainer_location ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION upsert_trainer_location(
  p_lat         float8,
  p_lng         float8,
  p_precision_m int DEFAULT 1000
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id      uuid := auth.uid();
  v_location_prv geography;
  v_location_pub geography;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF p_lat NOT BETWEEN -90 AND 90 OR p_lng NOT BETWEEN -180 AND 180 THEN
    RAISE EXCEPTION 'Ungültige Koordinaten';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM trainer_profiles WHERE id = v_user_id) THEN
    RAISE EXCEPTION 'Trainer-Profil nicht gefunden';
  END IF;

  v_location_prv := ST_MakePoint(p_lng, p_lat)::geography;
  v_location_pub := _jitter_location(v_location_prv, p_precision_m);

  UPDATE trainer_profiles
  SET
    location_private     = v_location_prv,
    location_public      = v_location_pub,
    location_precision_m = p_precision_m,
    location_updated_at  = now(),
    updated_at           = now()
  WHERE id = v_user_id;
END;
$$;

-- ── 8. find_trainers_nearby ───────────────────────────────────────────────────

DROP FUNCTION IF EXISTS public.find_trainers_nearby(float8, float8, float8);

CREATE OR REPLACE FUNCTION find_trainers_nearby(
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
LANGUAGE sql STABLE SECURITY DEFINER
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
  FROM trainer_profiles tp
  WHERE
    auth.uid() IS NOT NULL
    AND lat BETWEEN -90 AND 90
    AND lng BETWEEN -180 AND 180
    AND radius_km BETWEEN 1 AND 100
    AND tp.status = 'active'
    AND tp.location_private IS NOT NULL
    AND tp.location_public  IS NOT NULL
    AND ST_DWithin(
      tp.location_private,
      ST_MakePoint(lng, lat)::geography,
      radius_km * 1000
    )
  ORDER BY distance_km ASC;
$$;

-- ── 9. get_pending_trainers (admin) ───────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_pending_trainers()
RETURNS TABLE (
  id            uuid,
  display_name  text,
  bio           text,
  photo_url     text,
  contact_email text,
  contact_phone text,
  admin_notes   text,
  submitted_at  timestamptz,
  admin_latitude  float8,
  admin_longitude float8
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tp.id,
    tp.display_name,
    tp.bio,
    tp.photo_url,
    tpp.contact_email,
    tpp.contact_phone,
    tpp.admin_notes,
    tp.submitted_at,
    CASE WHEN tp.location_private IS NOT NULL
      THEN ST_Y(tp.location_private::geometry) ELSE NULL END AS admin_latitude,
    CASE WHEN tp.location_private IS NOT NULL
      THEN ST_X(tp.location_private::geometry) ELSE NULL END AS admin_longitude
  FROM trainer_profiles tp
  LEFT JOIN trainer_profile_private tpp ON tpp.trainer_id = tp.id
  WHERE
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
    AND tp.status = 'pending'
  ORDER BY tp.submitted_at ASC;
$$;

-- ── 10. admin_approve_trainer ─────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION admin_approve_trainer(p_trainer_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Nur Admins können Trainer freigeben';
  END IF;

  UPDATE trainer_profiles
  SET
    status      = 'active',
    approved_at = now(),
    approved_by = auth.uid(),
    updated_at  = now()
  WHERE id = p_trainer_id AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trainer nicht gefunden oder nicht im pending-Status';
  END IF;
END;
$$;

-- ── 11. admin_suspend_trainer ─────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION admin_suspend_trainer(
  p_trainer_id uuid,
  p_notes      text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Nur Admins können Trainer suspendieren';
  END IF;

  UPDATE trainer_profiles
  SET
    status     = 'suspended',
    updated_at = now()
  WHERE id = p_trainer_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trainer nicht gefunden';
  END IF;

  IF p_notes IS NOT NULL THEN
    INSERT INTO trainer_profile_private (trainer_id, contact_email, admin_notes)
    VALUES (p_trainer_id, '', p_notes)
    ON CONFLICT (trainer_id) DO UPDATE SET
      admin_notes = EXCLUDED.admin_notes,
      updated_at  = now();
  END IF;
END;
$$;

-- ── 12. send_discovery_request ────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION send_discovery_request(p_trainer_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_client_id uuid := auth.uid();
  v_rel_id    uuid;
BEGIN
  IF v_client_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM trainer_profiles
    WHERE id = p_trainer_id AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Trainer nicht gefunden oder nicht aktiv';
  END IF;

  -- Block if already active with this trainer
  IF EXISTS (
    SELECT 1 FROM trainer_client_relationships
    WHERE trainer_id = p_trainer_id AND client_id = v_client_id AND status = 'active'
  ) THEN
    RAISE EXCEPTION 'Bereits mit diesem Trainer verbunden';
  END IF;

  -- Block if already has a pending discovery request for this trainer
  IF EXISTS (
    SELECT 1 FROM trainer_client_relationships
    WHERE trainer_id = p_trainer_id
      AND client_id  = v_client_id
      AND status     = 'pending'
      AND source_type = 'discovery'
  ) THEN
    RAISE EXCEPTION 'Anfrage bereits gesendet';
  END IF;

  INSERT INTO trainer_client_relationships (
    trainer_id, client_id, status, source_type
  ) VALUES (
    p_trainer_id, v_client_id, 'pending', 'discovery'
  )
  RETURNING id INTO v_rel_id;

  RETURN v_rel_id;
END;
$$;

-- ── 13. get_incoming_discovery_requests (trainer view) ────────────────────────

CREATE OR REPLACE FUNCTION get_incoming_discovery_requests()
RETURNS TABLE (
  relationship_id uuid,
  client_id       uuid,
  display_name    text,
  created_at      timestamptz
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tcr.id AS relationship_id,
    tcr.client_id,
    p.display_name,
    tcr.created_at
  FROM trainer_client_relationships tcr
  JOIN profiles p ON p.id = tcr.client_id
  WHERE
    tcr.trainer_id   = auth.uid()
    AND tcr.status       = 'pending'
    AND tcr.source_type  = 'discovery'
    AND tcr.client_id IS NOT NULL
  ORDER BY tcr.created_at ASC;
$$;

-- ── 14. respond_discovery_request ────────────────────────────────────────────

CREATE OR REPLACE FUNCTION respond_discovery_request(
  p_relationship_id uuid,
  p_accept          boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trainer_id uuid := auth.uid();
  v_client_id  uuid;
BEGIN
  IF v_trainer_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  SELECT client_id INTO v_client_id
  FROM trainer_client_relationships
  WHERE id          = p_relationship_id
    AND trainer_id  = v_trainer_id
    AND status      = 'pending'
    AND source_type = 'discovery';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Anfrage nicht gefunden';
  END IF;

  IF p_accept THEN
    -- Deactivate existing active relationships for this client
    UPDATE trainer_client_relationships
    SET status = 'disconnected'
    WHERE client_id = v_client_id AND status = 'active';

    -- Activate this request
    UPDATE trainer_client_relationships
    SET
      status    = 'active',
      linked_at = now()
    WHERE id = p_relationship_id;

    -- Create direct chat channel
    PERFORM ensure_trainer_client_relationship(v_client_id);
  ELSE
    UPDATE trainer_client_relationships
    SET status = 'disconnected'
    WHERE id = p_relationship_id;
  END IF;
END;
$$;

-- ── 15. get_own_trainer_profile ───────────────────────────────────────────────

CREATE OR REPLACE FUNCTION get_own_trainer_profile()
RETURNS TABLE (
  id           uuid,
  display_name text,
  bio          text,
  photo_url    text,
  status       text,
  submitted_at timestamptz,
  has_location boolean
)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    tp.id,
    tp.display_name,
    tp.bio,
    tp.photo_url,
    tp.status,
    tp.submitted_at,
    (tp.location_private IS NOT NULL) AS has_location
  FROM trainer_profiles tp
  WHERE tp.id = auth.uid();
$$;

-- ── 16. Grants ────────────────────────────────────────────────────────────────

GRANT EXECUTE ON FUNCTION upsert_trainer_profile(text, text, text, text, text)    TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_trainer_location(float8, float8, int)             TO authenticated;
GRANT EXECUTE ON FUNCTION find_trainers_nearby(float8, float8, float8)             TO authenticated;
GRANT EXECUTE ON FUNCTION get_pending_trainers()                                   TO authenticated;
GRANT EXECUTE ON FUNCTION admin_approve_trainer(uuid)                              TO authenticated;
GRANT EXECUTE ON FUNCTION admin_suspend_trainer(uuid, text)                        TO authenticated;
GRANT EXECUTE ON FUNCTION send_discovery_request(uuid)                             TO authenticated;
GRANT EXECUTE ON FUNCTION get_incoming_discovery_requests()                        TO authenticated;
GRANT EXECUTE ON FUNCTION respond_discovery_request(uuid, boolean)                 TO authenticated;
GRANT EXECUTE ON FUNCTION get_own_trainer_profile()                                TO authenticated;
