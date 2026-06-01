-- Public trainer discovery without a radius constraint.
-- Used by the global trainer list and global map view.

CREATE OR REPLACE FUNCTION public.list_public_trainers()
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
    NULL::float8 AS distance_km,
    ST_Y(tp.location_public::geometry) AS public_latitude,
    ST_X(tp.location_public::geometry) AS public_longitude,
    (tp.status = 'active') AS verified,
    tp.status,
    tp.submitted_at,
    (tp.location_private IS NOT NULL) AS has_location
  FROM public.trainer_profiles tp
  WHERE
    auth.uid() IS NOT NULL
    AND tp.status = 'active'
  ORDER BY lower(tp.display_name) ASC;
$$;

REVOKE ALL ON FUNCTION public.list_public_trainers() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.list_public_trainers() TO authenticated;
