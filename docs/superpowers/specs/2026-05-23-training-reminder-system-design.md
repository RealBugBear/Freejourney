# Training Reminder System Design

Date: 2026-05-23

## Goal

CoreJourney gets server-side training reminders via FCM with an idempotent job queue and a staged rollout. Existing local daily reminders remain as a rollout fallback at first and are disabled after the server path is stable. Existing video-call and appointment push functions are outside this V1 scope, except for a separate priority bugfix to filter device tokens by environment.

## V1 Scope

Included:

- Server-side reminder preferences.
- `notification_jobs` queue.
- Separate scheduler and sender Edge Functions.
- Adaptive training time.
- Default quiet hours `20:00-08:00`.
- `training_soft`, `streak_warning`, and `comeback` reminder types.
- Motivating streak copy.
- In-app positive reinforcement after training completion.
- Feature flag / server rollout switch.
- Local daily reminder fallback during rollout.

Not included:

- `notification_deliveries`.
- `privacy_mode`.
- `subject_profile_id`.
- OS push for positive reinforcement.
- Reminders without an active training package/enrollment.
- Rework of existing call/appointment push functions in this ticket.

## Data Model

### `user_reminder_preferences`

- `user_id uuid primary key`
- `enabled boolean default false`
- `timezone text not null`
- `quiet_start time default '20:00'`
- `quiet_end time default '08:00'`
- `weekly_goal int nullable`
- `weekly_goal_source text default 'default'`
  - `curriculum`
  - `user_setting`
  - `default`
- `server_reminders_enabled boolean default false`
- `created_at timestamptz default now()`
- `updated_at timestamptz default now()`

Optional only if there is no stable server-side locale source:

- `language_code text default 'de'`

The app must update `timezone` not only during first setup, but also whenever the device timezone changes or the app starts after a timezone/device restart change. The stored timezone is part of scheduling correctness and must not be treated as a one-time preference.

### `notification_jobs`

- `id uuid primary key`
- `user_id uuid not null`
- `type text not null`
  - `training_soft`
  - `streak_warning`
  - `comeback`
- `scheduled_for timestamptz not null`
- `local_date date not null`
- `timezone text not null`
- `status text default 'pending'`
  - `pending`
  - `sending`
  - `sent`
  - `failed`
  - `skipped`
- `attempt_count int default 0`
- `idempotency_key text unique not null`
- `sent_token_count int default 0`
- `failed_token_count int default 0`
- `last_error text nullable`
- `fcm_message_ids jsonb nullable`
- `created_at timestamptz default now()`
- `sent_at timestamptz nullable`

Constraints and indexes:

- Unique `idempotency_key`.
- Unique `(user_id, type, local_date)`.
- Index `(status, scheduled_for)`.
- Index `(user_id, local_date)`.
- Check constraints for `type`, `status`, and `weekly_goal_source`.

## Reminder Eligibility

A user is eligible for training reminders only when:

- `user_reminder_preferences.enabled = true`.
- `server_reminders_enabled = true`.
- A valid timezone is stored.
- At least one active training package/enrollment exists.
- At least one active FCM token exists in the matching app environment.

No active package/enrollment means:

- No `training_soft`.
- No `streak_warning`.
- No `comeback`.
- Later reactivation reminders are a separate feature.

## Reminder Types

### `training_soft`

- Default for new users: `10:00` local time.
- With enough history: typical training time minus 20 minutes.
- Send only if the user has not trained today.
- At most once per local day.

### `streak_warning`

- `19:00` local time.
- Send only if the user has not trained today.
- Send only if the last training push was at least 4 hours ago.
- Skip if `training_soft` or `comeback` happened too late in the day to satisfy the 4-hour spacing rule.

### `comeback`

- `09:00` local time.
- Send if the user missed training yesterday.
- Do not send if the user has already trained today before 09:00.
- Replaces the same-morning `training_soft`.
- At most 3 consecutive comeback days.
- After 3 consecutive comeback sends, pause until the user trains again or a separate reactivation flow exists.

The scheduler checks the consecutive comeback limit by counting prior `notification_jobs` with `type = 'comeback'` for the same user in the last 3 local dates. Only `sent` jobs count toward the limit; `skipped` and `failed` jobs do not.

Per local day:

- At most 2 training pushes total.
- At least 4 hours between training pushes.
- No further training reminders after a completed training session.

## Adaptive Timing

Data source:

- `training_sessions`

Filters:

- `is_completed = true`
- `completed_at is not null`
- Sessions in the last 14 local days.
- Only sessions from the active training context where this can be derived cleanly.

Calculation:

- Convert `completed_at` to the user's stored timezone.
- Calculate minute-of-day.
- With at least 3 sessions: use the median minute-of-day.
- With fewer than 3 sessions: use default `10:00`.
- `training_soft` time = median minus 20 minutes.
- If the calculated time falls into quiet hours, move it to the end of quiet hours.
- If the soft reminder is too close to `19:00`, skip the `streak_warning` that day rather than violating the 4-hour spacing rule.

Documented latency:

- Scheduler runs every 15 minutes.
- Sender runs every 5-10 minutes.
- Expected maximum delivery delay is about 25 minutes, acceptable for reminders.

## Weekly Goal And Streak Copy

The streak count itself is always available from `training_sessions`. It can be used independently of `weekly_goal`.

`weekly_goal` is only required for `X von Y` copy such as `3 von 5 Einheiten diese Woche`.

Rules:

- `weekly_goal_source = 'curriculum'`: `X von Y` copy may be used.
- `weekly_goal_source = 'user_setting'`: `X von Y` copy may be used.
- `weekly_goal_source = 'default'`: do not use `X von Y` copy; use neutral streak/progress copy instead.
- Package changes do not break the streak.
- Multiple completed trainings on the same local day count once.
- Streaks are based on durable `training_sessions`.
- Training history remains until account deletion.

Examples:

- Reliable weekly goal: `Du bist bei 3 von 5 Einheiten diese Woche.`
- No reliable weekly goal: `Heute ist noch Zeit fuer deine Einheit.`
- Comeback: `Heute ist ein guter Moment, wieder einzusteigen.`
- Streak warning: `Heute ist noch Zeit fuer eine kurze Einheit.`

## Positive Reinforcement

V1 uses only in-app reinforcement:

- In-app celebration/outro after completed training.
- No OS push.
- No local notification.

Content:

- Weekly progress when `weekly_goal` is reliable.
- Streak/progress copy that remains supportive and non-pressuring.
- Next sensible step.

## Edge Functions

### `schedule-training-reminders`

- Cron every 15 minutes.
- Load reminder-eligible users.
- Check active enrollment.
- Calculate local time.
- Check today's and yesterday's training status.
- Calculate adaptive soft time.
- Check consecutive comeback count from prior `notification_jobs`.
- Create due `notification_jobs`.
- Use idempotency.
- Do not send FCM directly.

### `send-notification-jobs`

- Cron every 5-10 minutes.
- Fetch due `pending` jobs.
- Atomically mark jobs as `sending`.
- Skip jobs older than 60 minutes past `scheduled_for`.
- Load active `device_tokens`.
- Filter by current app environment.
- Send FCM notification messages.
- Store aggregate send results on the job.
- Set status to `sent`, `failed`, or `skipped`.
- Disable tokens on permanent FCM errors.

## App Changes

- Read/write reminder settings from `user_reminder_preferences`.
- Migrate existing local settings once when the user is signed in.
- Ask push permission only when the user enables reminders.
- Keep local daily reminders as initial fallback.
- Enable server reminders via rollout switch.
- Update stored timezone on app start and on detected timezone changes.
- Training reminder tap opens dashboard or training start.
- Positive reinforcement appears in the training outro.

## Rollout

1. Deploy DB migration.
2. Deploy Edge Functions.
3. Let app read/write server preferences.
4. Keep feature flag off and local reminders active.
5. Enable `server_reminders_enabled = true` internally/test users.
6. Observe jobs and send results.
7. Enable for user cohorts.
8. Disable local daily reminders after stability.
9. Add cleanup job for old `notification_jobs` later.

## Separate Priority Ticket

Existing push functions must filter by `device_tokens.environment`:

- `notify-video-call`
- `notify-call-request`
- `notify-appointment-proposal`
- `notify-appointment-confirmed`

Reason:

- `device_tokens.environment` already exists.
- Current functions likely send to mixed dev and production tokens.
- Mixed environment sends can explain missing push notifications when the app is closed.
- This ticket is important, but separate from Reminder V1.
