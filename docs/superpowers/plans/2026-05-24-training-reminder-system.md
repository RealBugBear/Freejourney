# Training Reminder System V1 - Implementation Plan

Date: 2026-05-24

Spec: `docs/superpowers/specs/2026-05-23-training-reminder-system-design.md`

## Goal

Build the server-side training reminder system from the spec without turning the first implementation into a broad push-notification rewrite.

V1 adds:

- `user_reminder_preferences`
- `notification_jobs`
- `schedule-training-reminders`
- `send-notification-jobs`
- app-side reminder preference sync
- app-side timezone refresh
- `training_reminder` push routing

The separate existing-push bugfix adds environment filtering to current video/call/appointment functions, but should be shipped as its own small change.

## Important Corrections To Avoid Known Traps

- Do not use `DateTime.now().timeZoneName` as the stored timezone. It often returns abbreviations like `CET` or `CEST`, not a stable IANA timezone. Add a real device-timezone provider, preferably via a Flutter timezone plugin, or a small platform channel if dependency compatibility is a concern.
- Do not put Deno testable helpers in an `index.ts` that calls `serve()` at top level and then import that file from tests. Put pure logic in `_shared/*.ts` modules and keep `index.ts` as the HTTP wrapper.
- Do not fake atomic job claiming in Supabase JS. Add a SQL RPC that claims jobs with `FOR UPDATE SKIP LOCKED`, increments `attempt_count`, and returns claimed rows.
- Do not create all future jobs for the whole day. The scheduler should create only jobs whose target send time falls inside the current scheduling horizon, e.g. now through now + 15 minutes. The sender must still revalidate before delivery.
- Do not use only `session_date` for "trained today" decisions. Use `completed_at` converted to the user's timezone, restricted to active enrollments. `session_date` can remain a supporting field, but `completed_at` is the delivery decision source.
- Do not permanently run local and server daily reminders for the same user. Local reminders are the rollout fallback when server reminders are off. For cohorts with server reminders enabled, cancel or suppress the local daily reminder to avoid duplicate notifications.
- Do not use `X von Y` copy unless `weekly_goal_source` is `curriculum` or `user_setting` and `weekly_goal` is present.

## File Map

New server files:

- `supabase/migrations/20260524_training_reminder_system.sql`
- `supabase/functions/_shared/reminder_time.ts`
- `supabase/functions/_shared/reminder_copy.ts`
- `supabase/functions/_shared/fcm.ts`
- `supabase/functions/schedule-training-reminders/index.ts`
- `supabase/functions/schedule-training-reminders/reminder_time_test.ts`
- `supabase/functions/send-notification-jobs/index.ts`
- `supabase/functions/send-notification-jobs/reminder_copy_test.ts`

New client files:

- `lib/core/reminders/device_timezone_provider.dart`
- `lib/core/reminders/reminder_preferences_repository.dart`
- `test/core/reminders/reminder_preferences_repository_test.dart`
- `test/core/reminders/device_timezone_provider_test.dart` if the implementation is testable without platform bindings

Modified client files:

- `pubspec.yaml`
- `lib/core/settings/settings_provider.dart`
- `lib/app.dart`
- `lib/core/push/push_notification_service.dart`
- `lib/core/navigation/app_router.dart` only if a better route constant is needed
- `lib/features/training/presentation/widgets/training_outro_widget.dart` only if the existing outro lacks the positive reinforcement required by the spec

Separate bugfix files:

- `supabase/functions/notify-video-call/index.ts`
- `supabase/functions/notify-call-request/index.ts`
- `supabase/functions/notify-appointment-proposal/index.ts`
- `supabase/functions/notify-appointment-confirmed/index.ts`

## Phase 0 - Preflight Decisions

- [ ] Confirm how to obtain a real IANA timezone on Android/iOS.
  - Preferred: add `flutter_timezone` if the current Flutter/Android build accepts it.
  - Fallback: implement a tiny platform channel returning `TimeZone.getDefault().id` on Android and `TimeZone.current.identifier` on iOS.
  - Reject: `DateTime.timeZoneName`, because it is not reliable enough for server scheduling.
- [ ] Confirm rollout environment names match `device_tokens.environment`: `development`, `staging`, `production`.
- [ ] Confirm Edge Function secret names:
  - `CRON_SECRET`
  - `APP_ENVIRONMENT`
  - `FIREBASE_SERVICE_ACCOUNT_JSON`
  - `FIREBASE_PROJECT_ID`
- [ ] Confirm whether `weeklyGoal` in local `AppSettings` is user-selected or merely default.
  - Use `SharedPreferences.containsKey('settings.weeklyGoal')`.
  - If the key exists, sync it as `weekly_goal_source = 'user_setting'`.
  - If it does not exist, sync `weekly_goal = null`, `weekly_goal_source = 'default'`.
- [ ] Confirm the active training context for V1:
  - `enrollments.user_id = user_id`
  - `enrollments.status = 'active'`
  - `training_sessions.enrollment_id in active enrollment ids`
  - if multiple active enrollments exist, aggregate across all active enrollments.

## Phase 1 - Database Migration

Create `supabase/migrations/20260524_training_reminder_system.sql`.

- [ ] Create `public.user_reminder_preferences`:
  - `user_id uuid primary key references public.profiles(id) on delete cascade`
  - `enabled boolean not null default false`
  - `timezone text not null`
  - `quiet_start time not null default '20:00'`
  - `quiet_end time not null default '08:00'`
  - `weekly_goal int null check (weekly_goal is null or weekly_goal > 0)`
  - `weekly_goal_source text not null default 'default'`
  - `server_reminders_enabled boolean not null default false`
  - timestamps
  - check `weekly_goal_source in ('curriculum', 'user_setting', 'default')`
- [ ] Add an `updated_at` trigger for `user_reminder_preferences`.
- [ ] Create `public.notification_jobs`:
  - `id uuid primary key default gen_random_uuid()`
  - `user_id uuid not null references public.profiles(id) on delete cascade`
  - `type text not null`
  - `scheduled_for timestamptz not null`
  - `local_date date not null`
  - `timezone text not null`
  - `status text not null default 'pending'`
  - `attempt_count int not null default 0`
  - `idempotency_key text not null`
  - `sent_token_count int not null default 0`
  - `failed_token_count int not null default 0`
  - `last_error text`
  - `fcm_message_ids jsonb`
  - `created_at timestamptz not null default now()`
  - `sent_at timestamptz`
- [ ] Add check constraints:
  - `type in ('training_soft', 'streak_warning', 'comeback')`
  - `status in ('pending', 'sending', 'sent', 'failed', 'skipped')`
- [ ] Add uniqueness and indexes:
  - unique `idempotency_key`
  - unique `(user_id, type, local_date)`
  - index `(status, scheduled_for)`
  - index `(user_id, local_date desc)`
- [ ] Add RLS:
  - users can select/insert/update their own `user_reminder_preferences`
  - users can select their own `notification_jobs`
  - no client insert/update/delete policies for `notification_jobs`
- [ ] Add SQL RPC `claim_due_notification_jobs(p_limit int default 100)`:
  - `SECURITY DEFINER`
  - claims rows where `status = 'pending'` and `scheduled_for <= now()`
  - uses `FOR UPDATE SKIP LOCKED`
  - sets `status = 'sending'`, increments `attempt_count`
  - returns claimed rows
- [ ] Add SQL helper RPC `training_reminder_local_to_utc(p_local_date date, p_local_time time, p_timezone text)`:
  - returns `timestamptz`
  - uses Postgres timezone conversion rather than hand-rolled JavaScript DST math.
  - implementation:

    ```sql
    CREATE OR REPLACE FUNCTION public.training_reminder_local_to_utc(
      p_local_date date,
      p_local_time time,
      p_timezone text
    )
    RETURNS timestamptz
    LANGUAGE sql
    STABLE
    AS $$
      SELECT (p_local_date::text || ' ' || p_local_time::text)::timestamp
        AT TIME ZONE p_timezone;
    $$;
    ```
- [ ] Add grants for authenticated users on preference RPCs only if RPCs are added for preferences. Job-claim RPC should be callable by service role only in practice; do not expose it through client code.
- [ ] Verify migration with:
  - bad `notification_jobs.type` fails
  - duplicate `idempotency_key` fails
  - duplicate `(user_id, type, local_date)` fails
  - authenticated user cannot insert a `notification_jobs` row
  - service role can claim pending jobs

## Phase 2 - Shared Edge Function Modules

Create shared modules so unit tests can import pure functions without booting HTTP servers.

### `_shared/reminder_time.ts`

- [ ] Implement `minuteOfDayInTimezone(utcIso, timezone)`.
- [ ] Implement `localDateInTimezone(utcIso, timezone)`.
- [ ] Implement `isInQuietHours(minuteOfDay, quietStartMinutes, quietEndMinutes)`.
- [ ] Implement `calculateMedianTrainingMinute(minutes)`:
  - fewer than 3 sessions -> `600` (`10:00`)
  - odd count -> middle value
  - even count -> lower-middle or rounded average; choose one and test it. Prefer rounded average for less surprising behavior.
- [ ] Implement `applyQuietHours(minute, quietStart, quietEnd)`:
  - if inside quiet hours, move to `quietEnd`
  - handle overnight quiet windows
- [ ] Keep local-to-UTC conversion out of JS if possible. Use the SQL RPC from Phase 1 for scheduling exact `scheduled_for` values.

Tests:

- [ ] default adaptive time under 3 sessions
- [ ] median with odd/even session counts
- [ ] overnight quiet hours
- [ ] morning training where `median - 20` lands before quiet end
- [ ] late training where streak warning must be skipped due 4-hour gap

### `_shared/reminder_copy.ts`

- [ ] Implement `buildTrainingReminderCopy(type, streakDaysOrWeeks, weeklyGoal, weeklyGoalSource)`.
- [ ] Use neutral German copy when `weekly_goal_source = 'default'`.
- [ ] Do not include undefined/null numbers.
- [ ] Keep copy motivating but not shaming.

Tests:

- [ ] `training_soft` with `default` source avoids `X von Y`.
- [ ] `training_soft` with `curriculum` and `weekly_goal` may use the goal.
- [ ] `streak_warning` with streak count uses count.
- [ ] `streak_warning` without count is neutral.
- [ ] `comeback` after streak is supportive.
- [ ] no text contains `undefined` or `null`.

### `_shared/fcm.ts`

- [ ] Move Firebase OAuth and FCM send helpers into one shared module.
- [ ] Return structured result:
  - `ok`
  - `messageId`
  - `errorCode`
  - `permanent`
- [ ] Treat permanent token errors as at least:
  - `UNREGISTERED`
  - token-specific `INVALID_ARGUMENT`
- [ ] Do not treat every `INVALID_ARGUMENT` as token-permanent if the whole payload is invalid. Log enough detail to distinguish this during implementation.

## Phase 3 - `schedule-training-reminders`

Create `supabase/functions/schedule-training-reminders/index.ts`.

Purpose: create due jobs only. It does not send FCM.

HTTP behavior:

- [ ] Require `x-cron-secret`.
- [ ] Accept optional JSON body for smoke tests:
  - `now` ISO override, only for non-production or when a separate test secret is used
  - `user_id` optional filter for manual testing
- [ ] Return aggregate counts:
  - users considered
  - users skipped by reason
  - jobs inserted
  - duplicate jobs ignored

Eligibility query:

- [ ] Load `user_reminder_preferences` where:
  - `enabled = true`
  - `server_reminders_enabled = true`
- [ ] Restrict to users with at least one active enrollment:
  - `enrollments.status = 'active'`
- [ ] Optionally prefilter users by active token existence in current `APP_ENVIRONMENT`, but do not make this the only check; sender handles final token state.

Training status queries:

- [ ] Use active enrollment ids:
  - `select id from enrollments where user_id = ... and status = 'active'`
- [ ] `trainedToday`:
  - `training_sessions.user_id = user_id`
  - `training_sessions.enrollment_id in activeEnrollmentIds`
  - `is_completed = true`
  - `completed_at is not null`
  - `(completed_at at time zone timezone)::date = localDate`
- [ ] `trainedYesterday` uses the same logic for `localDate - 1`.
- [ ] Adaptive history:
  - last 14 local dates
  - same active-enrollment restriction
  - same completed filters
  - convert each `completed_at` to local minute-of-day.

Scheduling logic:

- [ ] Calculate local `now`, `localDate`, and current local minute.
- [ ] Calculate target times:
  - `comeback` -> `09:00`
  - `training_soft` -> adaptive minute minus 20, quiet-hour adjusted
  - `streak_warning` -> `19:00`
- [ ] Use a scheduling horizon:
  - create a job only if `scheduled_for` is within `[now - 2 minutes, now + 15 minutes]`
  - this avoids creating stale future jobs that must later be invalidated.
  - documented tradeoff: if cron/Edge Functions are down longer than the lookback window, jobs for the missed window are not backfilled. For V1 reminders this is acceptable because late motivational pushes are worse than skipped reminders. If product later requires guaranteed reminder attempts, add a wider catch-up window or persistent future scheduling.
- [ ] Do not create any job when `trainedToday = true`.
- [ ] Comeback:
  - create only when `trainedYesterday = false`
  - create only if consecutive sent comeback count in prior 3 local dates is less than 3
  - creates no same-morning `training_soft`
- [ ] Soft:
  - create only when no comeback is due for that local date
- [ ] Streak warning:
  - create only if no training today
  - create only if today's latest sent or due `training_soft`/`comeback` is at least 4 hours earlier
  - if a soft reminder is too close to 19:00, skip warning rather than move it later.
- [ ] Insert jobs with idempotency keys:
  - `${user_id}:${type}:${local_date}`
- [ ] Use `insert` or `upsert ignoreDuplicates` against `idempotency_key`; the DB unique constraints are the final duplicate protection.

Tests:

- [ ] Unit-test pure time helpers from `_shared/reminder_time.ts`.
- [ ] Add function-level tests only if the Supabase client can be mocked without making tests brittle.
- [ ] Prefer a SQL fixture/smoke script for the integrated scheduler path.

Deploy:

- [ ] `supabase functions deploy schedule-training-reminders`
- [ ] Manual smoke call with one test user and `x-cron-secret`.
- [ ] Verify a second call does not create duplicate jobs.

Cron:

- [ ] Configure pg_cron manually through SQL editor or a clearly documented deployment script.
- [ ] Schedule every 15 minutes.
- [ ] Do not hardcode project URL or secret in migrations.

## Phase 4 - `send-notification-jobs`

Create `supabase/functions/send-notification-jobs/index.ts`.

Purpose: claim due jobs, revalidate, send FCM, update job aggregate result.

HTTP behavior:

- [ ] Require `x-cron-secret`.
- [ ] Accept optional `limit` body param, capped at a safe max.
- [ ] Return aggregate counts:
  - claimed
  - sent
  - skipped
  - failed
  - tokens disabled

Claiming:

- [ ] Call `claim_due_notification_jobs(limit)`.
- [ ] Do not fetch pending jobs and then update them in client code.
- [ ] If no rows claimed, return quickly.

Before sending each job, revalidate:

- [ ] job is not more than 60 minutes stale
- [ ] preferences still exist and `enabled = true`
- [ ] user still has an active enrollment
- [ ] user has not trained on `job.local_date` since the job was created
- [ ] for `comeback`, today's pre-09:00 training still suppresses send
- [ ] for `streak_warning`, 4-hour spacing still holds using already sent jobs that day

Token query:

- [ ] Load active tokens:
  - `device_tokens.user_id = job.user_id`
  - `enabled = true`
  - `revoked_at is null`
  - `environment = APP_ENVIRONMENT`
- [ ] If none, set job `skipped`, `last_error = 'no_tokens'`.

Copy:

- [ ] Use `buildTrainingReminderCopy`.
- [ ] Use streak count from `training_sessions` independent of `weekly_goal`.
- [ ] Use `X von Y` only when `weekly_goal_source != 'default'` and `weekly_goal is not null`.

FCM:

- [ ] Send notification messages, not data-only messages.
- [ ] Data payload must be strings:
  - `type = 'training_reminder'`
  - `reminder_type = job.type`
  - `job_id = job.id`
- [ ] Use normal priority unless product explicitly needs high priority.
- [ ] Store aggregate:
  - `sent_token_count`
  - `failed_token_count`
  - `fcm_message_ids`
  - `last_error`
  - `sent_at`
- [ ] Mark status:
  - `sent` when at least one token succeeds
  - `failed` when tokens exist but all fail
  - `skipped` when revalidation fails or no token exists
- [ ] Disable only permanent bad tokens.

Tests:

- [ ] Unit-test copy helpers.
- [ ] Unit-test FCM error classification with captured sample error payloads.
- [ ] Smoke-test with one manually inserted due job on a development device.

Deploy:

- [ ] `supabase functions deploy send-notification-jobs`
- [ ] Configure cron every 5 minutes.
- [ ] Smoke-test foreground and app-closed delivery.

## Phase 5 - Client Preference Sync

Create `lib/core/reminders/reminder_preferences_repository.dart`.

Repository behavior:

- [ ] Accept a `SupabaseClient`.
- [ ] Upsert `user_reminder_preferences` on `user_id`.
- [ ] Never set `server_reminders_enabled` from the client.
- [ ] Map local app reminder window to server quiet hours:
  - local `reminderEndMinutes` -> server `quiet_start`
  - local `reminderStartMinutes` -> server `quiet_end`
- [ ] Determine weekly goal source:
  - if local weekly goal was explicitly saved by the user, sync `weekly_goal` and `weekly_goal_source = 'user_setting'`
  - otherwise sync `weekly_goal = null` and `weekly_goal_source = 'default'`
- [ ] Fail softly when signed out or offline.

Create `lib/core/reminders/device_timezone_provider.dart`.

- [ ] Return an IANA timezone.
- [ ] Cache the last sent timezone locally to avoid unnecessary writes.
- [ ] Expose a method used on app start/sign-in and settings changes.

Modify `lib/core/settings/settings_provider.dart`.

- [ ] Inject or access `ReminderPreferencesRepository` through a provider, not by constructing hidden global instances inside setters.
- [ ] Keep local settings behavior intact.
- [ ] Sync to server when:
  - reminders enabled/disabled
  - reminder start/end changes
  - weekly goal changes
- [ ] Preserve current local fallback scheduling behavior while server reminders are not enabled for the user.

Modify `lib/app.dart`.

- [ ] On sign-in/token refresh, sync reminder preferences.
- [ ] On app start/resume, refresh stored timezone if changed.
- [ ] If the user is in a server-enabled cohort, suppress/cancel local daily reminders to prevent duplicate reminder pushes.
- [ ] If server reminders are later disabled for the user, local fallback can resume.

Tests:

- [ ] Repository maps reminder window to quiet hours correctly.
- [ ] Repository does not write `server_reminders_enabled`.
- [ ] Weekly goal source is `default` when no explicit user setting exists.
- [ ] Timezone sync writes only when changed.

Analyzer/test:

- [ ] `dart analyze lib/core/reminders lib/core/settings lib/app.dart`
- [ ] `flutter test test/core/reminders`

## Phase 6 - Push Routing

Modify `lib/core/push/push_notification_service.dart`.

- [ ] Foreground display handles `type = 'training_reminder'`.
- [ ] Prefer FCM notification title/body when present.
- [ ] Fallback copy is neutral:
  - title: `Training-Erinnerung`
  - body: `Tippe, um dein Training zu öffnen.`

Modify `lib/app.dart`.

- [ ] Add `training_reminder` handling in `_handleNotificationPayload`.
- [ ] Navigate to `Routes.trainingStart` or `Routes.dashboard`.
  - Prefer `Routes.trainingStart` if the active-enrollment state is ready.
  - Fall back to `Routes.dashboard` if training state is not loaded.
- [ ] Do not navigate into an active video call or destructive flow; if necessary, defer navigation until current route is safe.

Manual device tests:

- [ ] App foreground: local foreground display appears.
- [ ] App background: OS notification appears.
- [ ] App force-closed: OS notification appears.
- [ ] Tap notification routes to training/dashboard.

## Phase 7 - In-App Positive Reinforcement

Scope is intentionally small because V1 does not send positive OS pushes.

- [ ] Audit `lib/features/training/presentation/widgets/training_outro_widget.dart`.
- [ ] If current outro already has a strong completion/progress moment, document that no change is needed.
- [ ] If missing, add concise in-app reinforcement:
  - streak/progress when available
  - weekly progress only when goal is reliable
  - next sensible step
- [ ] Do not add a local notification.

## Phase 8 - Local Reminder Fallback Rollout

The fallback is not "run both forever".

- [ ] Define behavior:
  - `server_reminders_enabled = false`: existing local daily reminder remains the active reminder mechanism.
  - `server_reminders_enabled = true`: app cancels/suppresses local daily reminder to avoid duplicates.
  - emergency rollback: set `server_reminders_enabled = false`, app can re-enable local scheduling on next settings sync/app start.
- [ ] Add telemetry/logging enough to debug:
  - preference sync success/failure
  - timezone changed/synced
  - local reminder suppressed due server cohort
- [ ] Keep user-facing settings unchanged for V1 unless product wants to expose server/local distinction, which is not recommended.

## Phase 9 - Separate Priority Bugfix: Existing Push Environment Filter

This should be a separate PR/ticket from Reminder V1.

Modify:

- `supabase/functions/notify-video-call/index.ts`
- `supabase/functions/notify-call-request/index.ts`
- `supabase/functions/notify-appointment-proposal/index.ts`
- `supabase/functions/notify-appointment-confirmed/index.ts`

Implementation:

- [ ] Add `APP_ENVIRONMENT = Deno.env.get('APP_ENVIRONMENT') ?? 'production'`.
- [ ] Add `.eq('environment', APP_ENVIRONMENT)` to every `device_tokens` query.
- [ ] Preserve existing authorization and payload behavior.
- [ ] Deploy all four functions.

Smoke tests:

- [ ] Development device receives development push when `APP_ENVIRONMENT=development`.
- [ ] Production/TestFlight device receives production push when `APP_ENVIRONMENT=production`.
- [ ] A user with both dev and prod tokens receives only the intended environment push.

## Phase 10 - Verification Matrix

Database:

- [ ] RLS prevents client writes to `notification_jobs`.
- [ ] Idempotency prevents duplicate jobs on repeated scheduler calls.
- [ ] Claim RPC cannot double-claim a job under concurrent senders.

Scheduler:

- [ ] no preference -> no jobs
- [ ] disabled preference -> no jobs
- [ ] no active enrollment -> no jobs
- [ ] trained today -> no jobs
- [ ] default soft time -> `10:00`
- [ ] adaptive time after 3 sessions -> median minus 20
- [ ] quiet hours move scheduled time to quiet end
- [ ] comeback created after missed yesterday
- [ ] comeback not created after 3 sent consecutive comeback jobs
- [ ] streak warning skipped when 4-hour gap is impossible

Sender:

- [ ] stale job skipped after 60 minutes
- [ ] user trained after job creation -> skipped
- [ ] no matching environment token -> skipped
- [ ] one valid token -> sent
- [ ] permanent token failure -> token disabled
- [ ] temporary token failure -> token remains enabled and job result records failure

Client:

- [ ] enabling reminders requests permission and syncs prefs
- [ ] changing reminder window syncs inverse quiet hours
- [ ] app start syncs timezone changes
- [ ] server-enabled cohort suppresses local daily reminder
- [ ] training reminder tap routes correctly

End-to-end:

- [ ] Android dev build receives server training reminder with app foreground/background/force-closed.
- [ ] iOS/TestFlight receives existing appointment/video push after environment filter bugfix.
- [ ] No duplicate local + server training reminder for a server-enabled user.

## Deployment Order

1. Merge/deploy migration.
2. Deploy shared modules and both reminder Edge Functions.
3. Configure secrets and cron, but keep all users `server_reminders_enabled = false`.
4. Ship app preference sync and timezone update.
5. Enable server reminders for one internal test user.
6. Validate jobs and physical-device delivery.
7. Enable for a small cohort.
8. Suppress local reminders for server-enabled cohorts.
9. Roll out wider.
10. Ship separate environment-filter bugfix for existing push functions as a focused change.

## Claude Plan Differences

This plan intentionally differs from the earlier draft in these areas:

- Uses SQL RPC for atomic job claiming instead of unsupported Supabase JS field expressions.
- Uses shared Deno modules for testability instead of importing HTTP `index.ts` from tests.
- Requires a real IANA timezone provider instead of `DateTime.timeZoneName`.
- Schedules only near-due jobs and revalidates before send.
- Uses `completed_at` localized to the user's timezone for trained-today decisions.
- Clarifies that local reminders are fallback, not a permanent parallel channel.
- Treats the existing push environment filter as a separate priority bugfix.
