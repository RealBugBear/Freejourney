-- CoreJourney — Confirm proposed appointments from trainee side
-- Idempotent: safe to re-run.

CREATE OR REPLACE FUNCTION confirm_proposed_appointment(
  p_appointment_id uuid,
  p_chosen_slot timestamptz
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_appointment appointments%ROWTYPE;
BEGIN
  SELECT *
  INTO v_appointment
  FROM appointments
  WHERE id = p_appointment_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Terminvorschlag nicht gefunden';
  END IF;

  IF v_appointment.trainee_id <> auth.uid() THEN
    RAISE EXCEPTION 'Du kannst diesen Terminvorschlag nicht annehmen';
  END IF;

  IF v_appointment.status <> 'proposed' THEN
    RAISE EXCEPTION 'Dieser Terminvorschlag ist nicht mehr offen';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM unnest(v_appointment.proposed_slots) AS slot_start
    WHERE abs(extract(epoch from (slot_start - p_chosen_slot))) < 1
  ) THEN
    RAISE EXCEPTION 'Dieser Slot gehoert nicht zum Terminvorschlag';
  END IF;

  UPDATE appointments
  SET status = 'confirmed',
      scheduled_for = p_chosen_slot,
      updated_at = now()
  WHERE id = p_appointment_id;

  UPDATE appointments
  SET status = 'cancelled',
      updated_at = now()
  WHERE trainer_id = v_appointment.trainer_id
    AND trainee_id = v_appointment.trainee_id
    AND id <> p_appointment_id
    AND status IN ('planned', 'proposed');
END;
$$;

GRANT EXECUTE ON FUNCTION confirm_proposed_appointment(uuid, timestamptz)
  TO authenticated;
