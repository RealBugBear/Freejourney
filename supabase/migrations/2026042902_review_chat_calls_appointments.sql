-- CoreJourney — Review chat video calls and appointment proposals
-- Allows admins to schedule and start video calls inside trainer application
-- review channels, reusing the existing video_calls and appointments tables.

CREATE OR REPLACE FUNCTION public.start_direct_call(p_channel_id uuid)
RETURNS public.video_calls
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_channel public.chat_channels%ROWTYPE;
  v_call public.video_calls%ROWTYPE;
BEGIN
  SELECT *
  INTO v_channel
  FROM public.chat_channels
  WHERE id = p_channel_id;

  IF NOT FOUND OR v_channel.type NOT IN ('direct', 'application_review') THEN
    RAISE EXCEPTION 'Call channel not found';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.chat_channel_members
    WHERE channel_id = p_channel_id
      AND user_id = auth.uid()
      AND role = 'moderator'
  ) THEN
    RAISE EXCEPTION 'Only moderators can start calls';
  END IF;

  UPDATE public.video_calls
  SET ended_at = COALESCE(ended_at, now())
  WHERE channel_id = p_channel_id
    AND ended_at IS NULL
    AND started_at < now() - interval '2 minutes';

  SELECT *
  INTO v_call
  FROM public.video_calls
  WHERE channel_id = p_channel_id
    AND ended_at IS NULL
  ORDER BY started_at DESC
  LIMIT 1;

  IF FOUND THEN
    RETURN v_call;
  END IF;

  INSERT INTO public.video_calls (
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

GRANT EXECUTE ON FUNCTION public.start_direct_call(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.propose_application_review_appointment(
  p_channel_id uuid,
  p_applicant_id uuid,
  p_proposed_slots timestamptz[],
  p_location text DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS public.appointments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_admin_id uuid := auth.uid();
  v_appointment public.appointments%ROWTYPE;
  v_slot_count int := COALESCE(array_length(p_proposed_slots, 1), 0);
  v_proposal_label text;
BEGIN
  IF v_admin_id IS NULL THEN
    RAISE EXCEPTION 'Nicht eingeloggt';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = v_admin_id
      AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Nur Admins koennen Review-Termine vorschlagen';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.chat_channels c
    JOIN public.trainer_applications ta
      ON ta.id = c.application_id
     AND ta.user_id = p_applicant_id
    JOIN public.chat_channel_members admin_member
      ON admin_member.channel_id = c.id
     AND admin_member.user_id = v_admin_id
     AND admin_member.role = 'moderator'
    JOIN public.chat_channel_members applicant_member
      ON applicant_member.channel_id = c.id
     AND applicant_member.user_id = p_applicant_id
     AND applicant_member.role = 'member'
    WHERE c.id = p_channel_id
      AND c.type = 'application_review'
      AND c.application_id IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'Review-Kanal oder Bewerber nicht gefunden';
  END IF;

  IF v_slot_count < 1 THEN
    RAISE EXCEPTION 'Bitte mindestens einen Slot auswaehlen';
  END IF;

  IF v_slot_count > 8 THEN
    RAISE EXCEPTION 'Bitte maximal acht Slots vorschlagen';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM unnest(p_proposed_slots) AS slot_start
    WHERE slot_start <= now()
  ) THEN
    RAISE EXCEPTION 'Terminvorschlaege muessen in der Zukunft liegen';
  END IF;

  INSERT INTO public.appointments (
    trainer_id,
    trainee_id,
    title,
    scheduled_for,
    proposed_slots,
    duration_minutes,
    location,
    notes,
    status,
    trigger,
    trainee_day_number
  )
  VALUES (
    v_admin_id,
    p_applicant_id,
    'Video-Bewerbungsgespraech',
    NULL,
    p_proposed_slots,
    60,
    COALESCE(NULLIF(trim(COALESCE(p_location, '')), ''), 'Video-Call'),
    NULLIF(trim(COALESCE(p_notes, '')), ''),
    'proposed',
    'manual',
    NULL
  )
  RETURNING * INTO v_appointment;

  v_proposal_label := CASE
    WHEN v_slot_count = 1 THEN 'einen Video-Termin'
    ELSE v_slot_count::text || ' Video-Termine'
  END;

  INSERT INTO public.chat_messages (
    channel_id,
    sender_id,
    content,
    is_bot_response,
    is_call_request
  )
  VALUES (
    p_channel_id,
    v_admin_id,
    'Ich habe dir ' || v_proposal_label ||
      ' fuer das Bewerbungsgespraech vorgeschlagen. Bitte waehle einen passenden Slot aus.',
    false,
    false
  );

  RETURN v_appointment;
END;
$$;

GRANT EXECUTE ON FUNCTION public.propose_application_review_appointment(
  uuid,
  uuid,
  timestamptz[],
  text,
  text
) TO authenticated;

NOTIFY pgrst, 'reload schema';
