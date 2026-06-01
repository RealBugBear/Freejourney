-- supabase/migrations/20260415_enrollment_community_trigger.sql
-- 1. Unique constraint so ON CONFLICT works for community channels.
-- 2. Trigger: when a user enrolls in a package, auto-create/join the community channel.

-- 1. Unique constraint on community channels (direct channels are excluded via CHECK constraint
--    which ensures package_id IS NULL for direct, so (direct, NULL) never conflicts with
--    (community, <id>))
ALTER TABLE public.chat_channels
  ADD CONSTRAINT uq_chat_channels_community_package
  UNIQUE (type, package_id);

-- 2. Trigger function
CREATE OR REPLACE FUNCTION public.fn_enrollment_join_community()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_channel_id  uuid;
  v_trainer_id  uuid;
BEGIN
  -- Only act on active enrollments
  IF NEW.status != 'active' THEN
    RETURN NEW;
  END IF;

  -- Create community channel if it doesn't exist yet (idempotent)
  INSERT INTO public.chat_channels (type, package_id)
  VALUES ('community', NEW.package_id)
  ON CONFLICT ON CONSTRAINT uq_chat_channels_community_package DO NOTHING;

  SELECT id INTO v_channel_id
  FROM public.chat_channels
  WHERE type = 'community' AND package_id = NEW.package_id;

  -- Add enrolling user as member
  INSERT INTO public.chat_channel_members (channel_id, user_id, role)
  VALUES (v_channel_id, NEW.user_id, 'member')
  ON CONFLICT (channel_id, user_id) DO NOTHING;

  -- Find the user's active trainer and add as moderator
  SELECT trainer_id INTO v_trainer_id
  FROM public.trainer_client_relationships
  WHERE client_id = NEW.user_id AND status = 'active'
  LIMIT 1;

  IF v_trainer_id IS NOT NULL THEN
    INSERT INTO public.chat_channel_members (channel_id, user_id, role)
    VALUES (v_channel_id, v_trainer_id, 'moderator')
    ON CONFLICT (channel_id, user_id) DO UPDATE SET role = 'moderator';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_enrollment_join_community ON public.enrollments;
CREATE TRIGGER trg_enrollment_join_community
  AFTER INSERT ON public.enrollments
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_enrollment_join_community();
