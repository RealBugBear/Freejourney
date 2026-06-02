-- Admin metrics v1.
-- Aggregated, read-only metrics for growth, training adherence, trainer ops,
-- reflex profile patterns, and integrity checks. Test users created through
-- the admin web tool are excluded automatically.

CREATE OR REPLACE FUNCTION public.get_admin_metrics_v1()
RETURNS TABLE (
  page text,
  group_key text,
  metric_key text,
  label text,
  value numeric,
  unit text,
  metadata jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can read metrics';
  END IF;

  RETURN QUERY
  WITH eligible_profiles AS (
    SELECT p.*
    FROM public.profiles p
    LEFT JOIN auth.users u ON u.id = p.id
    WHERE COALESCE((u.raw_user_meta_data ->> 'test_user')::boolean, false) = false
  ),
  active_events AS (
    SELECT ts.user_id, COALESCE(ts.completed_at, ts.created_at) AS occurred_at
    FROM public.training_sessions ts
    WHERE ts.is_completed = true
    UNION ALL
    SELECT rpa.user_id, COALESCE(rpa.completed_at, rpa.skipped_at, rpa.created_at)
    FROM public.reflex_profile_assessments rpa
    UNION ALL
    SELECT mc.user_id, mc.created_at
    FROM public.mood_checkins mc
    UNION ALL
    SELECT je.user_id, je.created_at
    FROM public.journal_entries je
  ),
  weekly_sessions AS (
    SELECT ts.user_id, count(*) AS completed_count
    FROM public.training_sessions ts
    JOIN eligible_profiles ep ON ep.id = ts.user_id
    WHERE ts.is_completed = true
      AND COALESCE(ts.completed_at, ts.created_at) >= date_trunc('week', now())
    GROUP BY ts.user_id
  ),
  enrollment_last_training AS (
    SELECT
      e.id,
      e.user_id,
      e.status,
      e.start_date,
      max(COALESCE(ts.completed_at, ts.created_at)) FILTER (WHERE ts.is_completed = true) AS last_completed_at
    FROM public.enrollments e
    JOIN eligible_profiles ep ON ep.id = e.user_id
    LEFT JOIN public.training_sessions ts ON ts.enrollment_id = e.id
    GROUP BY e.id, e.user_id, e.status, e.start_date
  )
  SELECT 'overview', 'users', 'users_total', 'Nutzer gesamt', count(*)::numeric, 'count', '{}'::jsonb
  FROM eligible_profiles
  UNION ALL
  SELECT 'overview', 'users', 'users_new_7d', 'Neue Nutzer 7 Tage', count(*)::numeric, 'count', '{}'::jsonb
  FROM eligible_profiles
  WHERE created_at >= now() - interval '7 days'
  UNION ALL
  SELECT 'overview', 'users', 'users_new_30d', 'Neue Nutzer 30 Tage', count(*)::numeric, 'count', '{}'::jsonb
  FROM eligible_profiles
  WHERE created_at >= now() - interval '30 days'
  UNION ALL
  SELECT 'overview', 'users', 'active_30d', 'Aktive Nutzer 30 Tage', count(DISTINCT ae.user_id)::numeric, 'count', '{}'::jsonb
  FROM active_events ae
  JOIN eligible_profiles ep ON ep.id = ae.user_id
  WHERE ae.occurred_at >= now() - interval '30 days'
  UNION ALL
  SELECT 'overview', 'users', 'paying_users', 'Premium-Nutzer', count(*)::numeric, 'count', '{}'::jsonb
  FROM eligible_profiles
  WHERE subscription_tier = 'premium'
  UNION ALL
  SELECT 'overview', 'training', 'training_sessions_7d', 'Trainings 7 Tage', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.training_sessions ts
  JOIN eligible_profiles ep ON ep.id = ts.user_id
  WHERE ts.is_completed = true
    AND COALESCE(ts.completed_at, ts.created_at) >= now() - interval '7 days'
  UNION ALL
  SELECT 'overview', 'training', 'weekly_consistent_users', 'Woechentlich konsistent', count(*)::numeric, 'count', jsonb_build_object('definition', 'Mindestens 3 abgeschlossene Trainings seit Wochenbeginn')
  FROM weekly_sessions
  WHERE completed_count >= 3
  UNION ALL
  SELECT 'overview', 'trainers', 'active_trainers', 'Aktive Trainer', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.trainer_profiles tp
  JOIN eligible_profiles ep ON ep.id = tp.id
  WHERE tp.status = 'active'
  UNION ALL
  SELECT 'overview', 'trainers', 'pending_applications', 'Offene Bewerbungen', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.trainer_applications ta
  JOIN eligible_profiles ep ON ep.id = ta.user_id
  WHERE ta.status IN ('submitted', 'in_review', 'needs_more_info')
  UNION ALL
  SELECT 'overview', 'reflex', 'reflex_completed_30d', 'Reflexprofile 30 Tage', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.reflex_profile_assessments rpa
  JOIN eligible_profiles ep ON ep.id = rpa.user_id
  WHERE rpa.status = 'completed'
    AND rpa.questionnaire_type <> 'demo_child_short'
    AND COALESCE(rpa.completed_at, rpa.created_at) >= now() - interval '30 days'
  UNION ALL
  SELECT 'overview', 'integrity', 'failed_reminder_jobs', 'Fehlgeschlagene Reminder', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.notification_jobs nj
  JOIN eligible_profiles ep ON ep.id = nj.user_id
  WHERE nj.status = 'failed'
    AND nj.created_at >= now() - interval '30 days'
  UNION ALL
  SELECT 'overview', 'integrity', 'missing_exercise_media', 'Uebungen ohne Medien', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.exercises e
  WHERE NULLIF(COALESCE(e.image_url, e.image_path), '') IS NULL
     OR NULLIF(COALESCE(e.video_url, e.video_path), '') IS NULL;

  RETURN QUERY
  WITH eligible_profiles AS (
    SELECT p.*
    FROM public.profiles p
    LEFT JOIN auth.users u ON u.id = p.id
    WHERE COALESCE((u.raw_user_meta_data ->> 'test_user')::boolean, false) = false
  ),
  active_events AS (
    SELECT ts.user_id, COALESCE(ts.completed_at, ts.created_at) AS occurred_at, 'training' AS source
    FROM public.training_sessions ts
    WHERE ts.is_completed = true
    UNION ALL
    SELECT rpa.user_id, COALESCE(rpa.completed_at, rpa.skipped_at, rpa.created_at), 'reflex'
    FROM public.reflex_profile_assessments rpa
    UNION ALL
    SELECT mc.user_id, mc.created_at, 'mood'
    FROM public.mood_checkins mc
    UNION ALL
    SELECT je.user_id, je.created_at, 'journal'
    FROM public.journal_entries je
  )
  SELECT 'users', 'segments', 'role_' || COALESCE(role, 'unknown'), 'Rolle: ' || COALESCE(role, 'unknown'), count(*)::numeric, 'count', '{}'::jsonb
  FROM eligible_profiles
  GROUP BY role
  UNION ALL
  SELECT 'users', 'segments', 'tier_' || COALESCE(subscription_tier, 'free'), 'Abo: ' || COALESCE(subscription_tier, 'free'), count(*)::numeric, 'count', '{}'::jsonb
  FROM eligible_profiles
  GROUP BY subscription_tier
  UNION ALL
  SELECT 'users', 'activity', 'active_7d', 'Aktive Nutzer 7 Tage', count(DISTINCT ae.user_id)::numeric, 'count', '{}'::jsonb
  FROM active_events ae
  JOIN eligible_profiles ep ON ep.id = ae.user_id
  WHERE ae.occurred_at >= now() - interval '7 days'
  UNION ALL
  SELECT 'users', 'activity', 'active_30d', 'Aktive Nutzer 30 Tage', count(DISTINCT ae.user_id)::numeric, 'count', '{}'::jsonb
  FROM active_events ae
  JOIN eligible_profiles ep ON ep.id = ae.user_id
  WHERE ae.occurred_at >= now() - interval '30 days'
  UNION ALL
  SELECT 'users', 'activity', 'training_active_30d', 'Training aktiv 30 Tage', count(DISTINCT ae.user_id)::numeric, 'count', '{}'::jsonb
  FROM active_events ae
  JOIN eligible_profiles ep ON ep.id = ae.user_id
  WHERE ae.source = 'training'
    AND ae.occurred_at >= now() - interval '30 days'
  UNION ALL
  SELECT 'users', 'activity', 'high_intent_30d', 'High Intent 30 Tage', count(DISTINCT user_id)::numeric, 'count', '{}'::jsonb
  FROM (
    SELECT rpa.user_id
    FROM public.reflex_profile_assessments rpa
    JOIN eligible_profiles ep ON ep.id = rpa.user_id
    WHERE COALESCE(rpa.completed_at, rpa.skipped_at, rpa.created_at) >= now() - interval '30 days'
    UNION
    SELECT e.user_id
    FROM public.enrollments e
    JOIN eligible_profiles ep ON ep.id = e.user_id
    WHERE e.created_at >= now() - interval '30 days'
  ) high_intent
  UNION ALL
  SELECT 'users', 'activity', 'paying_active_30d', 'Premium aktiv 30 Tage', count(DISTINCT ae.user_id)::numeric, 'count', '{}'::jsonb
  FROM active_events ae
  JOIN eligible_profiles ep ON ep.id = ae.user_id
  WHERE ep.subscription_tier = 'premium'
    AND ae.occurred_at >= now() - interval '30 days';

  RETURN QUERY
  WITH eligible_profiles AS (
    SELECT p.*
    FROM public.profiles p
    LEFT JOIN auth.users u ON u.id = p.id
    WHERE COALESCE((u.raw_user_meta_data ->> 'test_user')::boolean, false) = false
  ),
  weekly_sessions AS (
    SELECT ts.user_id, count(*) AS completed_count
    FROM public.training_sessions ts
    JOIN eligible_profiles ep ON ep.id = ts.user_id
    WHERE ts.is_completed = true
      AND COALESCE(ts.completed_at, ts.created_at) >= date_trunc('week', now())
    GROUP BY ts.user_id
  ),
  enrollment_last_training AS (
    SELECT
      e.id,
      e.user_id,
      e.status,
      e.start_date,
      max(COALESCE(ts.completed_at, ts.created_at)) FILTER (WHERE ts.is_completed = true) AS last_completed_at
    FROM public.enrollments e
    JOIN eligible_profiles ep ON ep.id = e.user_id
    LEFT JOIN public.training_sessions ts ON ts.enrollment_id = e.id
    GROUP BY e.id, e.user_id, e.status, e.start_date
  )
  SELECT 'training', 'volume', 'sessions_7d', 'Abgeschlossene Trainings 7 Tage', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.training_sessions ts
  JOIN eligible_profiles ep ON ep.id = ts.user_id
  WHERE ts.is_completed = true
    AND COALESCE(ts.completed_at, ts.created_at) >= now() - interval '7 days'
  UNION ALL
  SELECT 'training', 'volume', 'sessions_30d', 'Abgeschlossene Trainings 30 Tage', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.training_sessions ts
  JOIN eligible_profiles ep ON ep.id = ts.user_id
  WHERE ts.is_completed = true
    AND COALESCE(ts.completed_at, ts.created_at) >= now() - interval '30 days'
  UNION ALL
  SELECT 'training', 'consistency', 'weekly_consistent_users', 'Mindestens 3 Trainings diese Woche', count(*)::numeric, 'count', '{}'::jsonb
  FROM weekly_sessions
  WHERE completed_count >= 3
  UNION ALL
  SELECT 'training', 'consistency', 'weekly_goal_met_users', 'Wochenziel erreicht', count(*)::numeric, 'count', '{}'::jsonb
  FROM weekly_sessions ws
  JOIN public.progress_entries pe ON pe.user_id = ws.user_id
  WHERE ws.completed_count >= pe.weekly_goal
  UNION ALL
  SELECT 'training', 'enrollments', 'active_enrollments', 'Aktive Enrollments', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.enrollments e
  JOIN eligible_profiles ep ON ep.id = e.user_id
  WHERE e.status = 'active'
  UNION ALL
  SELECT 'training', 'enrollments', 'completed_enrollments', 'Abgeschlossene Enrollments', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.enrollments e
  JOIN eligible_profiles ep ON ep.id = e.user_id
  WHERE e.status = 'completed'
  UNION ALL
  SELECT 'training', 'risk', 'at_risk_7d', 'At risk: 7 Tage ohne Training', count(*)::numeric, 'count', '{}'::jsonb
  FROM enrollment_last_training
  WHERE status = 'active'
    AND COALESCE(last_completed_at, start_date::timestamptz) < now() - interval '7 days'
  UNION ALL
  SELECT 'training', 'risk', 'slipping_14d', 'Slipping: 14 Tage ohne Training', count(*)::numeric, 'count', '{}'::jsonb
  FROM enrollment_last_training
  WHERE status = 'active'
    AND COALESCE(last_completed_at, start_date::timestamptz) < now() - interval '14 days'
  UNION ALL
  SELECT 'training', 'risk', 'dropout_30d', 'Dropout: 30 Tage oder abandoned', count(*)::numeric, 'count', '{}'::jsonb
  FROM enrollment_last_training
  WHERE status = 'abandoned'
     OR (status = 'active' AND COALESCE(last_completed_at, start_date::timestamptz) < now() - interval '30 days')
  UNION ALL
  SELECT 'training', 'risk', 'never_started', 'Enrollment ohne erstes Training', count(*)::numeric, 'count', '{}'::jsonb
  FROM enrollment_last_training
  WHERE last_completed_at IS NULL;

  RETURN QUERY
  WITH eligible_profiles AS (
    SELECT p.*
    FROM public.profiles p
    LEFT JOIN auth.users u ON u.id = p.id
    WHERE COALESCE((u.raw_user_meta_data ->> 'test_user')::boolean, false) = false
  ),
  assessments AS (
    SELECT rpa.*, rsp.profile_type, rsp.age_group
    FROM public.reflex_profile_assessments rpa
    JOIN eligible_profiles ep ON ep.id = rpa.user_id
    LEFT JOIN public.reflex_subject_profiles rsp ON rsp.id = rpa.subject_profile_id
    WHERE rpa.questionnaire_type <> 'demo_child_short'
  ),
  score_rows AS (
    SELECT
      COALESCE(a.profile_type, CASE WHEN a.questionnaire_type = 'adult_self_report' THEN 'adult_self' ELSE 'child' END) AS profile_type,
      a.questionnaire_type,
      a.package_id,
      score.key AS reflex_key,
      NULLIF(score.value ->> 'percent', '')::numeric AS percent,
      COALESCE(score.value ->> 'band', 'unknown') AS band
    FROM assessments a
    CROSS JOIN LATERAL jsonb_each(a.scores) AS score(key, value)
    WHERE a.status = 'completed'
      AND jsonb_typeof(score.value) = 'object'
      AND (score.value ->> 'percent') ~ '^[0-9]+(\.[0-9]+)?$'
  )
  SELECT 'reflex', 'volume', 'completed_total', 'Abgeschlossene Reflexprofile', count(*)::numeric, 'count', '{}'::jsonb
  FROM assessments
  WHERE status = 'completed'
  UNION ALL
  SELECT 'reflex', 'volume', 'completed_7d', 'Abgeschlossen 7 Tage', count(*)::numeric, 'count', '{}'::jsonb
  FROM assessments
  WHERE status = 'completed'
    AND COALESCE(completed_at, created_at) >= now() - interval '7 days'
  UNION ALL
  SELECT 'reflex', 'volume', 'completed_30d', 'Abgeschlossen 30 Tage', count(*)::numeric, 'count', '{}'::jsonb
  FROM assessments
  WHERE status = 'completed'
    AND COALESCE(completed_at, created_at) >= now() - interval '30 days'
  UNION ALL
  SELECT 'reflex', 'volume', 'skipped_total', 'Uebersprungen', count(*)::numeric, 'count', '{}'::jsonb
  FROM assessments
  WHERE status = 'skipped'
  UNION ALL
  SELECT 'reflex', 'safety', 'warning_confirmations', 'Warnhinweise bestaetigt', count(*)::numeric, 'count', '{}'::jsonb
  FROM assessments
  WHERE jsonb_array_length(COALESCE(warning_confirmations, '[]'::jsonb)) > 0
  UNION ALL
  SELECT 'reflex', 'sharing', 'active_trainer_shares', 'Aktive Trainer-Freigaben', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.reflex_profile_trainer_shares s
  JOIN eligible_profiles ep ON ep.id = s.owner_user_id
  WHERE s.revoked_at IS NULL
  UNION ALL
  SELECT 'reflex', 'funnel', 'profile_no_training', 'Reflexprofil ohne Training', count(DISTINCT a.user_id)::numeric, 'count', '{}'::jsonb
  FROM assessments a
  WHERE a.status = 'completed'
    AND NOT EXISTS (
      SELECT 1
      FROM public.training_sessions ts
      WHERE ts.user_id = a.user_id
        AND ts.is_completed = true
    )
  UNION ALL
  SELECT 'reflex', 'profile_type', 'profile_type_' || COALESCE(profile_type, 'unknown'), 'Profiltyp: ' || COALESCE(profile_type, 'unknown'), count(*)::numeric, 'count', '{}'::jsonb
  FROM assessments
  WHERE status = 'completed'
  GROUP BY profile_type
  UNION ALL
  SELECT 'reflex', 'age_group', 'age_group_' || COALESCE(age_group, 'unknown'), 'Altersgruppe: ' || COALESCE(age_group, 'unknown'), count(*)::numeric, 'count', '{}'::jsonb
  FROM assessments
  WHERE status = 'completed'
  GROUP BY age_group
  UNION ALL
  SELECT 'reflex', 'package', 'package_' || COALESCE(package_id, 'unknown'), 'Paket: ' || COALESCE(package_id, 'unknown'), count(*)::numeric, 'count', '{}'::jsonb
  FROM assessments
  WHERE status = 'completed'
  GROUP BY package_id
  UNION ALL
  SELECT
    'reflex',
    'score_distribution',
    'reflex_' || reflex_key,
    'Reflex: ' || reflex_key,
    round(avg(percent), 1),
    'percent',
    jsonb_build_object(
      'profile_type', profile_type,
      'questionnaire_type', questionnaire_type,
      'package_id', package_id,
      'assessment_count', count(*),
      'low_lt_75', count(*) FILTER (WHERE percent < 75),
      'medium_75_85', count(*) FILTER (WHERE percent >= 75 AND percent <= 85),
      'high_gt_85', count(*) FILTER (WHERE percent > 85),
      'bands', jsonb_object_agg(band, band_count)
    )
  FROM (
    SELECT
      profile_type,
      questionnaire_type,
      package_id,
      reflex_key,
      percent,
      band,
      count(*) OVER (PARTITION BY profile_type, questionnaire_type, package_id, reflex_key, band) AS band_count
    FROM score_rows
  ) scored
  GROUP BY profile_type, questionnaire_type, package_id, reflex_key;

  RETURN QUERY
  WITH eligible_profiles AS (
    SELECT p.*
    FROM public.profiles p
    LEFT JOIN auth.users u ON u.id = p.id
    WHERE COALESCE((u.raw_user_meta_data ->> 'test_user')::boolean, false) = false
  )
  SELECT 'trainers', 'status', 'status_' || COALESCE(tp.status, 'unknown'), 'Trainerstatus: ' || COALESCE(tp.status, 'unknown'), count(*)::numeric, 'count', '{}'::jsonb
  FROM public.trainer_profiles tp
  JOIN eligible_profiles ep ON ep.id = tp.id
  GROUP BY tp.status
  UNION ALL
  SELECT 'trainers', 'clients', 'active_client_relationships', 'Aktive Trainer-Client Beziehungen', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.trainer_client_relationships tcr
  JOIN eligible_profiles trainer ON trainer.id = tcr.trainer_id
  LEFT JOIN eligible_profiles client ON client.id = tcr.client_id
  WHERE tcr.status = 'active'
    AND (tcr.client_id IS NULL OR client.id IS NOT NULL)
  UNION ALL
  SELECT 'trainers', 'clients', 'trainers_with_clients', 'Trainer mit aktiven Clients', count(DISTINCT tcr.trainer_id)::numeric, 'count', '{}'::jsonb
  FROM public.trainer_client_relationships tcr
  JOIN eligible_profiles trainer ON trainer.id = tcr.trainer_id
  LEFT JOIN eligible_profiles client ON client.id = tcr.client_id
  WHERE tcr.status = 'active'
    AND (tcr.client_id IS NULL OR client.id IS NOT NULL)
  UNION ALL
  SELECT 'trainers', 'applications', 'application_' || COALESCE(ta.status, 'unknown'), 'Bewerbung: ' || COALESCE(ta.status, 'unknown'), count(*)::numeric, 'count', '{}'::jsonb
  FROM public.trainer_applications ta
  JOIN eligible_profiles ep ON ep.id = ta.user_id
  GROUP BY ta.status
  UNION ALL
  SELECT 'trainers', 'appointments', 'appointment_' || COALESCE(a.status, 'unknown'), 'Termin: ' || COALESCE(a.status, 'unknown'), count(*)::numeric, 'count', '{}'::jsonb
  FROM public.appointments a
  JOIN eligible_profiles trainer ON trainer.id = a.trainer_id
  JOIN eligible_profiles trainee ON trainee.id = a.trainee_id
  GROUP BY a.status;

  RETURN QUERY
  WITH eligible_profiles AS (
    SELECT p.*
    FROM public.profiles p
    LEFT JOIN auth.users u ON u.id = p.id
    WHERE COALESCE((u.raw_user_meta_data ->> 'test_user')::boolean, false) = false
  ),
  daily_training AS (
    SELECT ts.user_id, COALESCE(ts.completed_at, ts.created_at)::date AS day, count(*) AS sessions
    FROM public.training_sessions ts
    JOIN eligible_profiles ep ON ep.id = ts.user_id
    WHERE ts.is_completed = true
      AND COALESCE(ts.completed_at, ts.created_at) >= now() - interval '30 days'
    GROUP BY ts.user_id, COALESCE(ts.completed_at, ts.created_at)::date
  ),
  reflex_submissions AS (
    SELECT rpa.user_id, count(*) AS submissions
    FROM public.reflex_profile_assessments rpa
    JOIN eligible_profiles ep ON ep.id = rpa.user_id
    WHERE rpa.created_at >= now() - interval '30 days'
    GROUP BY rpa.user_id
  )
  SELECT 'integrity', 'activity', 'users_with_impossible_training_days', 'Nutzer mit >3 Trainings/Tag', count(DISTINCT user_id)::numeric, 'count', jsonb_build_object('definition', 'Mehr als 3 abgeschlossene Sessions an einem Kalendertag in den letzten 30 Tagen')
  FROM daily_training
  WHERE sessions > 3
  UNION ALL
  SELECT 'integrity', 'activity', 'users_with_many_reflex_submissions', 'Nutzer mit >5 Reflexprofilen/30 Tage', count(*)::numeric, 'count', '{}'::jsonb
  FROM reflex_submissions
  WHERE submissions > 5
  UNION ALL
  SELECT 'integrity', 'reminders', 'pending_reminder_jobs', 'Pending Reminder-Jobs', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.notification_jobs nj
  JOIN eligible_profiles ep ON ep.id = nj.user_id
  WHERE nj.status = 'pending'
  UNION ALL
  SELECT 'integrity', 'reminders', 'failed_reminder_jobs_30d', 'Failed Reminder-Jobs 30 Tage', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.notification_jobs nj
  JOIN eligible_profiles ep ON ep.id = nj.user_id
  WHERE nj.status = 'failed'
    AND nj.created_at >= now() - interval '30 days'
  UNION ALL
  SELECT 'integrity', 'content', 'missing_image_media', 'Uebungen ohne Bild', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.exercises e
  WHERE NULLIF(COALESCE(e.image_url, e.image_path), '') IS NULL
  UNION ALL
  SELECT 'integrity', 'content', 'missing_video_media', 'Uebungen ohne Video', count(*)::numeric, 'count', '{}'::jsonb
  FROM public.exercises e
  WHERE NULLIF(COALESCE(e.video_url, e.video_path), '') IS NULL;
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_metrics_v1() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_admin_metrics_v1() TO authenticated;

COMMENT ON FUNCTION public.get_admin_metrics_v1()
  IS 'Aggregated admin metrics for dashboard pages. Excludes admin-created test users via auth.users raw_user_meta_data.test_user.';
