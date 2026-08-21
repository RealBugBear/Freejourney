# Invite Phase 8 — Admin invite funnel

**Date:** 2026-08-21  
**Repos:** `supabase/migrations/2026082106_admin_invite_funnel.sql`  
**Tests:** `supabase/tests/2026082106_admin_invite_funnel_test.sql`  
**Admin UI:** `/admin/metrics/invites` (outer repo `admin-web`)  
**Live-Apply:** nicht ausgeführt (Founder-Gate)  
**`kInviteEnabled`:** bleibt `false`

## Metric definitions

| `metric_key` | Definition | Source |
|---|---|---|
| `share_action_tapped_count` | Sum of button presses before the native share sheet. Does **not** claim a share completed. | `sum(referral_codes.share_action_tapped_count)` |
| `landing_view_count` | Well-formed `/einladung?c=` hits that incremented via `log_invite_landing_view` for an active code. | `sum(referral_codes.landing_view_count)` |
| `redeemed_count` | Referral rows created by successful `redeem_invite_code` (all statuses). | `count(*)` on `referrals` |
| `pending_count` | Redeemed, first completed training not yet recorded. | `status = 'pending'` |
| `activated_count` | First completed training recorded. Counted by **status row**; `invitee_user_id` NULL after user delete does **not** reduce this. | `status = 'activated'` |
| `blocked_count` | Blocked referral rows. | `status = 'blocked'` |
| `conv_landing_per_share` | `landing / share * 100` | percent; **NULL** if share = 0 |
| `conv_redeem_per_landing` | `redeemed / landing * 100` | percent; **NULL** if landing = 0 |
| `conv_activated_per_redeemed` | `activated / redeemed * 100` | percent; **NULL** if redeemed = 0 |

Zero-denominator policy: rates return SQL `NULL`; admin UI shows `—`. Metadata includes `zero_denominator: "null"`.

Self-check completions are **not** measured. No analytics SDK. No Stage-2 / `benefit_campaigns` / `entitlement_grants` changes.

## Authorization

- `SECURITY DEFINER` RPC `get_admin_invite_funnel_v1`
- Gate: `profiles.role = 'admin'` for `auth.uid()`, else exception
- `REVOKE … FROM PUBLIC, anon, authenticated` then `GRANT EXECUTE … TO authenticated`
- Anon: no EXECUTE; non-admin authenticated: EXECUTE but fails closed with exception
- Payload: aggregates only — no `invitee_user_id`, names, emails, or codes in columns/metadata values

Admin-web: existing `requireAdmin()` layout gate unchanged. `getAdminMetrics()` merges `get_admin_metrics_v1` + `get_admin_invite_funnel_v1`; missing invite RPC (pre-live-apply) soft-fails so other metric pages keep working.

## Verification (observed)

Local `supabase db reset --local` with pre-existing Moro migration temporarily aside (same Phase-1 workaround; file restored; **not** committed removed).

```text
2026082106_admin_invite_funnel_test.sql → 1..23, 0 failures
2026082105_referral_program_test.sql    → 1..58, 0 failures
kInviteEnabled = false (unchanged)
admin-web tsc --noEmit → clean after invites page wiring
```

## Changed files

**App repo (`reflexjourney`):**
- `supabase/migrations/2026082106_admin_invite_funnel.sql`
- `supabase/tests/2026082106_admin_invite_funnel_test.sql`
- `docs/evidence/invite-phase7/README.md` (post-launch store task)
- `docs/evidence/invite-phase8/README.md` (this file)
- `docs/superpowers/specs/2026-08-21-einladungen-und-wirkungsvisual-design.md` (§13/§14 post-launch)
- `tasks/todo.md`

**Outer / website (`corejourney`):**
- `reflexjourney-app-site/FOUNDER_TODO.md` (F9.6)
- `reflexjourney-app-site/WEBSITE_BACKLOG.md` (W-024)
- `admin-web/lib/metrics/config.ts`
- `admin-web/lib/metrics/data.ts`
- `admin-web/components/metrics/metric-card.tsx`
- `admin-web/components/metrics/metrics-page.tsx`
- `admin-web/app/admin/metrics/invites/page.tsx`
- `admin-web/app/admin/nav.tsx`

## Still-open rollout gates

1. Live-apply `2026082105` + `2026082106` (Founder go)
2. Website deploy of `/einladung` + AASA invite paths
3. Real-device Universal Link QA (Phase 5 exit)
4. Privacy policy / processing register updates (Spec §14)
5. `kInviteEnabled = true` in a later release
6. Post-launch store buttons (W-024 / F9.6) after public App Store / Play availability — no placeholder/TestFlight links
