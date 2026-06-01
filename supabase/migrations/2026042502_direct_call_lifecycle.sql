-- CoreJourney — Direct video call lifecycle hardening
-- Idempotent: safe to re-run.

-- At most one active call per channel.
CREATE UNIQUE INDEX IF NOT EXISTS ux_video_calls_one_active_per_channel
  ON video_calls(channel_id)
  WHERE ended_at IS NULL;

-- Trainers/moderators start direct calls through a server-side guard.
CREATE OR REPLACE FUNCTION start_direct_call(p_channel_id uuid)
RETURNS video_calls
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_channel chat_channels%ROWTYPE;
  v_call video_calls%ROWTYPE;
BEGIN
  SELECT *
  INTO v_channel
  FROM chat_channels
  WHERE id = p_channel_id;

  IF NOT FOUND OR v_channel.type <> 'direct' THEN
    RAISE EXCEPTION 'Direct channel not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM chat_channel_members
    WHERE channel_id = p_channel_id
      AND user_id = auth.uid()
      AND role = 'moderator'
  ) THEN
    RAISE EXCEPTION 'Only trainers can start direct calls';
  END IF;

  -- Close stale ringing calls before reusing/starting one.
  UPDATE video_calls
  SET ended_at = COALESCE(ended_at, now())
  WHERE channel_id = p_channel_id
    AND ended_at IS NULL
    AND started_at < now() - interval '2 minutes';

  SELECT *
  INTO v_call
  FROM video_calls
  WHERE channel_id = p_channel_id
    AND ended_at IS NULL
  ORDER BY started_at DESC
  LIMIT 1;

  IF FOUND THEN
    RETURN v_call;
  END IF;

  INSERT INTO video_calls (
    channel_id,
    agora_channel_name,
    started_by
  )
  VALUES (
    p_channel_id,
    'cj_' || replace(p_channel_id::text, '-', '') || '_' ||
      floor(extract(epoch from clock_timestamp()) * 1000)::bigint::text,
    auth.uid()
  )
  RETURNING * INTO v_call;

  RETURN v_call;
END;
$$;

-- Either participant of the direct channel can end an active call.
CREATE OR REPLACE FUNCTION end_call(p_call_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_channel_id uuid;
BEGIN
  SELECT channel_id
  INTO v_channel_id
  FROM video_calls
  WHERE id = p_call_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Call not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM chat_channel_members
    WHERE channel_id = v_channel_id
      AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not a member of this call channel';
  END IF;

  UPDATE video_calls
  SET ended_at = COALESCE(ended_at, now())
  WHERE id = p_call_id;
END;
$$;

GRANT EXECUTE ON FUNCTION start_direct_call(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION end_call(uuid) TO authenticated;
