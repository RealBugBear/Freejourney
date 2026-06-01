-- CoreJourney - Device token registry for remote push notifications
-- Idempotent: safe to re-run.
--
-- Extends the existing device_tokens table used by Edge Functions. This keeps
-- chat, call, appointment and future notifications on one shared registry.

CREATE TABLE IF NOT EXISTS device_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  token text NOT NULL,
  platform text NOT NULL CHECK (
    platform IN ('ios', 'android', 'macos', 'web', 'unknown')
  ),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE device_tokens
  DROP CONSTRAINT IF EXISTS device_tokens_platform_check;

ALTER TABLE device_tokens
  ADD CONSTRAINT device_tokens_platform_check
  CHECK (platform IN ('ios', 'android', 'macos', 'web', 'unknown'));

ALTER TABLE device_tokens
  DROP CONSTRAINT IF EXISTS device_tokens_user_id_platform_key;

ALTER TABLE device_tokens
  ADD COLUMN IF NOT EXISTS environment text NOT NULL DEFAULT 'development',
  ADD COLUMN IF NOT EXISTS app_version text,
  ADD COLUMN IF NOT EXISTS device_id text,
  ADD COLUMN IF NOT EXISTS enabled boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS last_seen_at timestamptz NOT NULL DEFAULT now(),
  ADD COLUMN IF NOT EXISTS revoked_at timestamptz,
  ADD COLUMN IF NOT EXISTS created_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE device_tokens
  DROP CONSTRAINT IF EXISTS device_tokens_environment_check;

ALTER TABLE device_tokens
  ADD CONSTRAINT device_tokens_environment_check
  CHECK (environment IN ('development', 'staging', 'production'));

CREATE UNIQUE INDEX IF NOT EXISTS ux_device_tokens_token
  ON device_tokens(token);

CREATE INDEX IF NOT EXISTS device_tokens_user_id_idx
  ON device_tokens(user_id);

CREATE INDEX IF NOT EXISTS device_tokens_enabled_user_idx
  ON device_tokens(user_id, enabled)
  WHERE revoked_at IS NULL;

ALTER TABLE device_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read their own device tokens" ON device_tokens;
CREATE POLICY "Users can read their own device tokens"
  ON device_tokens
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can insert their own device tokens" ON device_tokens;
CREATE POLICY "Users can insert their own device tokens"
  ON device_tokens
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their own device tokens" ON device_tokens;
CREATE POLICY "Users can update their own device tokens"
  ON device_tokens
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE OR REPLACE FUNCTION upsert_push_token(
  p_token text,
  p_platform text,
  p_environment text DEFAULT 'development',
  p_app_version text DEFAULT NULL,
  p_device_id text DEFAULT NULL
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_token_id uuid;
  v_platform text := COALESCE(NULLIF(trim(p_platform), ''), 'unknown');
  v_environment text := COALESCE(NULLIF(trim(p_environment), ''), 'development');
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF p_token IS NULL OR trim(p_token) = '' THEN
    RAISE EXCEPTION 'Push token fehlt';
  END IF;

  IF v_platform NOT IN ('ios', 'android', 'macos', 'web', 'unknown') THEN
    v_platform := 'unknown';
  END IF;

  IF v_environment NOT IN ('development', 'staging', 'production') THEN
    v_environment := 'development';
  END IF;

  INSERT INTO device_tokens (
    user_id,
    token,
    platform,
    environment,
    app_version,
    device_id,
    enabled,
    revoked_at,
    last_seen_at,
    updated_at
  )
  VALUES (
    v_user_id,
    trim(p_token),
    v_platform,
    v_environment,
    NULLIF(trim(COALESCE(p_app_version, '')), ''),
    NULLIF(trim(COALESCE(p_device_id, '')), ''),
    true,
    NULL,
    now(),
    now()
  )
  ON CONFLICT (token)
  DO UPDATE SET
    user_id = EXCLUDED.user_id,
    platform = EXCLUDED.platform,
    environment = EXCLUDED.environment,
    app_version = EXCLUDED.app_version,
    device_id = COALESCE(EXCLUDED.device_id, device_tokens.device_id),
    enabled = true,
    revoked_at = NULL,
    last_seen_at = now(),
    updated_at = now()
  RETURNING id INTO v_token_id;

  RETURN v_token_id;
END;
$$;

CREATE OR REPLACE FUNCTION revoke_push_token(p_token text)
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

  UPDATE device_tokens
  SET
    enabled = false,
    revoked_at = now(),
    updated_at = now()
  WHERE user_id = v_user_id
    AND token = trim(COALESCE(p_token, ''));
END;
$$;

GRANT EXECUTE ON FUNCTION upsert_push_token(text, text, text, text, text)
  TO authenticated;

GRANT EXECUTE ON FUNCTION revoke_push_token(text)
  TO authenticated;
