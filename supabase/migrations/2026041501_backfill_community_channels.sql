-- supabase/migrations/20260415_backfill_community_channels.sql
-- One-time backfill: provision community channels for all existing active enrollments.
-- Safe to re-run (all operations are idempotent via ON CONFLICT).

DO $$
DECLARE
  rec         RECORD;
  v_channel_id uuid;
  v_trainer_id uuid;
BEGIN
  FOR rec IN
    SELECT DISTINCT user_id, package_id
    FROM public.enrollments
    WHERE status = 'active'
  LOOP
    -- Ensure community channel exists
    INSERT INTO public.chat_channels (type, package_id)
    VALUES ('community', rec.package_id)
    ON CONFLICT ON CONSTRAINT uq_chat_channels_community_package DO NOTHING;

    SELECT id INTO v_channel_id
    FROM public.chat_channels
    WHERE type = 'community' AND package_id = rec.package_id;

    -- Add user
    INSERT INTO public.chat_channel_members (channel_id, user_id, role)
    VALUES (v_channel_id, rec.user_id, 'member')
    ON CONFLICT (channel_id, user_id) DO NOTHING;

    -- Add trainer
    SELECT trainer_id INTO v_trainer_id
    FROM public.trainer_client_relationships
    WHERE client_id = rec.user_id AND status = 'active'
    LIMIT 1;

    IF v_trainer_id IS NOT NULL THEN
      INSERT INTO public.chat_channel_members (channel_id, user_id, role)
      VALUES (v_channel_id, v_trainer_id, 'moderator')
      ON CONFLICT (channel_id, user_id) DO UPDATE SET role = 'moderator';
    END IF;
  END LOOP;
END;
$$;
