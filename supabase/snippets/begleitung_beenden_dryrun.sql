-- Read-only. Counts only. Basis for the BB-6 backfill decision.
SELECT
  count(*) FILTER (
    WHERE EXISTS (
      SELECT 1 FROM public.trainer_client_relationships a
       WHERE a.client_id = r.client_id AND a.status = 'active'
    )
  ) AS likely_switch,
  count(*) FILTER (
    WHERE NOT EXISTS (
      SELECT 1 FROM public.trainer_client_relationships a
       WHERE a.client_id = r.client_id AND a.status = 'active'
    )
  ) AS no_active_trainer,
  count(*) FILTER (
    WHERE EXISTS (
      SELECT 1
        FROM public.chat_channel_members m1
        JOIN public.chat_channels c  ON c.id = m1.channel_id AND c.type = 'direct'
        JOIN public.chat_channel_members m2 ON m2.channel_id = m1.channel_id
       WHERE m1.user_id = r.trainer_id AND m2.user_id = r.client_id
    )
  ) AS resurrectable_chat,
  count(*) FILTER (
    WHERE EXISTS (
      SELECT 1 FROM public.appointments ap
       WHERE ap.trainer_id = r.trainer_id
         AND ap.trainee_id = r.client_id
         AND ap.status IN ('proposed','planned','confirmed')
    )
  ) AS resurrectable_appt,
  count(*) FILTER (
    WHERE (
      SELECT count(*) FROM public.trainer_client_relationships d
       WHERE d.trainer_id = r.trainer_id
         AND d.client_id  = r.client_id
         AND d.status     = 'disconnected'
    ) > 1
  ) AS duplicate_pair,
  count(*) AS total_disconnected
FROM public.trainer_client_relationships r
WHERE r.status = 'disconnected'
  AND r.ended_by_client_at IS NULL;
