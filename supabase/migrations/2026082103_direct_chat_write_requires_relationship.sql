-- Direct-channel chat writes require an ACTIVE trainer-client relationship.
-- Reading is deliberately untouched: both sides keep their history.
-- Spec: docs/superpowers/specs/2026-08-21-begleitung-beenden-design.md §4.3
-- Idempotent: safe to replay.

-- The whole predicate lives in ONE SECURITY DEFINER function, used by both the
-- policy and the UI.
--
-- It cannot be written inline in the policy. RLS applies to subqueries inside a
-- policy expression too, and members_select_own is `user_id = auth.uid()`, so
-- the sender sees ONLY THEIR OWN row in chat_channel_members. An inline
-- `EXISTS (… JOIN chat_channel_members other … WHERE other.user_id <> auth.uid())`
-- therefore always matches zero rows and denies every direct-channel write,
-- even with a perfectly valid active relationship. Verified locally on
-- 2026-08-21: other_members_visible_to_sender = 0 while the definer function
-- returns true for the same actor and channel.
--
-- Named can_write_chat_channel, not …_direct_channel: after the delegation it
-- decides for EVERY channel type, not only direct ones.
CREATE OR REPLACE FUNCTION public.can_write_chat_channel(p_channel_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $function$
  SELECT
    EXISTS (
      SELECT 1 FROM public.chat_channel_members m
       WHERE m.channel_id = p_channel_id AND m.user_id = auth.uid()
    )
    AND (
      NOT EXISTS (
        SELECT 1 FROM public.chat_channels c
         WHERE c.id = p_channel_id AND c.type = 'direct'
      )
      OR EXISTS (
        SELECT 1
          FROM public.chat_channel_members other
          JOIN public.trainer_client_relationships r
            ON r.status = 'active'
           AND (
                (r.trainer_id = auth.uid() AND r.client_id  = other.user_id)
             OR (r.client_id  = auth.uid() AND r.trainer_id = other.user_id)
           )
         WHERE other.channel_id = p_channel_id
           AND other.user_id   <> auth.uid()
      )
    );
$function$;

REVOKE ALL ON FUNCTION public.can_write_chat_channel(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.can_write_chat_channel(uuid) TO authenticated;

DROP POLICY IF EXISTS messages_insert_member ON public.chat_messages;
CREATE POLICY messages_insert_member ON public.chat_messages
  FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    -- Deliberately redundant with the function's own first check: this is the
    -- one clause the sender CAN evaluate under RLS, so the definer function is
    -- not the sole gate.
    AND EXISTS (
      SELECT 1
        FROM public.chat_channel_members m
       WHERE m.channel_id = chat_messages.channel_id
         AND m.user_id    = auth.uid()
    )
    AND public.can_write_chat_channel(chat_messages.channel_id)
  );
