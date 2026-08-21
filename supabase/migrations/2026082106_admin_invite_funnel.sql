-- Admin invite funnel metrics (Phase 8).
-- Aggregates only — no invitee names, emails, or invitee_user_id in the payload.
-- Same return shape as get_admin_metrics_v1 for admin-web merge.
-- Does not modify benefit_campaigns, entitlement_grants, or Stage-2 surfaces.

CREATE OR REPLACE FUNCTION public.get_admin_invite_funnel_v1()
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
DECLARE
  v_share numeric := 0;
  v_landing numeric := 0;
  v_redeemed numeric := 0;
  v_pending numeric := 0;
  v_activated numeric := 0;
  v_blocked numeric := 0;
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE id = auth.uid()
      AND role = 'admin'
  ) THEN
    RAISE EXCEPTION 'Only admins can read invite funnel metrics';
  END IF;

  SELECT COALESCE(sum(rc.share_action_tapped_count), 0)::numeric,
         COALESCE(sum(rc.landing_view_count), 0)::numeric
    INTO v_share, v_landing
    FROM public.referral_codes rc;

  SELECT
    count(*)::numeric,
    count(*) FILTER (WHERE r.status = 'pending')::numeric,
    count(*) FILTER (WHERE r.status = 'activated')::numeric,
    count(*) FILTER (WHERE r.status = 'blocked')::numeric
    INTO v_redeemed, v_pending, v_activated, v_blocked
    FROM public.referrals r;

  RETURN QUERY
  SELECT
    'invites'::text,
    'funnel'::text,
    'share_action_tapped_count'::text,
    'Teilen-Knopf gedrueckt'::text,
    v_share,
    'count'::text,
    jsonb_build_object(
      'definition',
      'Sum of referral_codes.share_action_tapped_count. Counts the button press before the native share sheet; does not claim a share completed.'
    )
  UNION ALL
  SELECT
    'invites',
    'funnel',
    'landing_view_count',
    'Zielseite aufgerufen',
    v_landing,
    'count',
    jsonb_build_object(
      'definition',
      'Sum of referral_codes.landing_view_count. Well-formed /einladung?c= views that hit log_invite_landing_view for an active code.'
    )
  UNION ALL
  SELECT
    'invites',
    'funnel',
    'redeemed_count',
    'Eingeloest',
    v_redeemed,
    'count',
    jsonb_build_object(
      'definition',
      'Count of referrals rows (pending + activated + blocked). Created when redeem_invite_code succeeds.'
    )
  UNION ALL
  SELECT
    'invites',
    'status',
    'pending_count',
    'Pending',
    v_pending,
    'count',
    jsonb_build_object(
      'definition',
      'referrals.status = pending (redeemed, first completed training not yet recorded).'
    )
  UNION ALL
  SELECT
    'invites',
    'funnel',
    'activated_count',
    'Aktiviert',
    v_activated,
    'count',
    jsonb_build_object(
      'definition',
      'referrals.status = activated. Counted by status row, independent of invitee_user_id (ON DELETE SET NULL does not reduce this).'
    )
  UNION ALL
  SELECT
    'invites',
    'status',
    'blocked_count',
    'Blocked',
    v_blocked,
    'count',
    jsonb_build_object(
      'definition',
      'referrals.status = blocked.'
    )
  UNION ALL
  SELECT
    'invites',
    'conversion',
    'conv_landing_per_share',
    'Conversion Zielseite / Teilen-Knopf',
    CASE WHEN v_share = 0 THEN NULL ELSE round((v_landing / v_share) * 100, 1) END,
    'percent',
    jsonb_build_object(
      'definition', 'landing_view_count / share_action_tapped_count * 100',
      'numerator', v_landing,
      'denominator', v_share,
      'zero_denominator', 'null'
    )
  UNION ALL
  SELECT
    'invites',
    'conversion',
    'conv_redeem_per_landing',
    'Conversion Einloesung / Zielseite',
    CASE WHEN v_landing = 0 THEN NULL ELSE round((v_redeemed / v_landing) * 100, 1) END,
    'percent',
    jsonb_build_object(
      'definition', 'redeemed_count / landing_view_count * 100',
      'numerator', v_redeemed,
      'denominator', v_landing,
      'zero_denominator', 'null'
    )
  UNION ALL
  SELECT
    'invites',
    'conversion',
    'conv_activated_per_redeemed',
    'Conversion Aktivierung / Einloesung',
    CASE WHEN v_redeemed = 0 THEN NULL ELSE round((v_activated / v_redeemed) * 100, 1) END,
    'percent',
    jsonb_build_object(
      'definition', 'activated_count / redeemed_count * 100',
      'numerator', v_activated,
      'denominator', v_redeemed,
      'zero_denominator', 'null'
    );
END;
$$;

REVOKE ALL ON FUNCTION public.get_admin_invite_funnel_v1() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.get_admin_invite_funnel_v1() TO authenticated;

COMMENT ON FUNCTION public.get_admin_invite_funnel_v1()
  IS 'Aggregated invite funnel for admin metrics page. Admin-only. No invitee identifiers.';
