-- supabase/migrations/20260415_get_channel_list.sql
-- Single-query replacement for the N+1 channel list query.
-- Returns channels the calling user is a member of, with last message
-- and unread count, sorted: direct first, then community; newest-last-message first.

CREATE OR REPLACE FUNCTION public.get_channel_list(p_user_id uuid)
RETURNS TABLE (
  id                    uuid,
  type                  text,
  package_id            text,
  created_at            timestamptz,
  member_role           text,
  last_read_at          timestamptz,
  last_message_content  text,
  last_message_at       timestamptz,
  unread_count          bigint
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  WITH memberships AS (
    SELECT
      ccm.channel_id,
      ccm.role          AS member_role,
      ccm.last_read_at
    FROM chat_channel_members ccm
    WHERE ccm.user_id = p_user_id
  ),
  last_msgs AS (
    SELECT DISTINCT ON (cm.channel_id)
      cm.channel_id,
      cm.content      AS last_message_content,
      cm.created_at   AS last_message_at
    FROM chat_messages cm
    JOIN memberships m ON m.channel_id = cm.channel_id
    WHERE cm.deleted_at IS NULL
    ORDER BY cm.channel_id, cm.created_at DESC
  ),
  unread AS (
    SELECT
      cm.channel_id,
      COUNT(*)::bigint AS unread_count
    FROM chat_messages cm
    JOIN memberships m ON m.channel_id = cm.channel_id
    WHERE cm.created_at > m.last_read_at
      AND cm.sender_id  != p_user_id
      AND cm.deleted_at IS NULL
    GROUP BY cm.channel_id
  )
  SELECT
    c.id,
    c.type,
    c.package_id,
    c.created_at,
    m.member_role,
    m.last_read_at,
    lm.last_message_content,
    lm.last_message_at,
    COALESCE(u.unread_count, 0) AS unread_count
  FROM chat_channels c
  JOIN memberships m   ON m.channel_id = c.id
  LEFT JOIN last_msgs lm ON lm.channel_id = c.id
  LEFT JOIN unread u     ON u.channel_id  = c.id
  ORDER BY
    CASE WHEN c.type = 'direct' THEN 0 ELSE 1 END,
    lm.last_message_at DESC NULLS LAST;
$$;
