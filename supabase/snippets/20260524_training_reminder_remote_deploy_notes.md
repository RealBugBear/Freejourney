# Training Reminder Remote Deploy Notes

Use this because `supabase db push --dry-run --debug` currently hangs at
`Initialising login role...` against the linked pooler.

## 1. Apply Migration Manually

Open the Supabase SQL editor for project `sxvpiggednbftfqeokyd` and run the full
contents of:

```text
supabase/migrations/20260524_training_reminder_system.sql
```

Do not run `supabase db push` blindly from this checkout. Older local migration
files were renamed so local Supabase CLI can replay them from an empty Docker DB;
remote migration history must be inspected/repaired before normal CLI pushes.

## 2. Set CRON_SECRET

Set a high-entropy secret in Edge Function secrets:

```bash
supabase secrets set CRON_SECRET='<generated-secret>' --project-ref sxvpiggednbftfqeokyd
```

The same value must be sent as the `x-cron-secret` header by cron jobs.

## 3. Cron SQL Template

After the migration is applied, configure cron from the SQL editor. Replace
`<CRON_SECRET>` before running. This script enables the required extensions,
removes earlier jobs with the same names, and then creates the two production
jobs.

```sql
create extension if not exists pg_cron with schema extensions;
create extension if not exists pg_net with schema extensions;

do $$
declare
  reminder_job record;
begin
  for reminder_job in
    select jobid
    from cron.job
    where jobname in (
      'schedule-training-reminders',
      'send-notification-jobs'
    )
  loop
    perform cron.unschedule(reminder_job.jobid);
  end loop;
end;
$$;

select
  cron.schedule(
    'schedule-training-reminders',
    '*/15 * * * *',
    $$
    select
      net.http_post(
        url := 'https://sxvpiggednbftfqeokyd.supabase.co/functions/v1/schedule-training-reminders',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-cron-secret', '<CRON_SECRET>'
        ),
        body := '{}'::jsonb
      );
    $$
  );

select
  cron.schedule(
    'send-notification-jobs',
    '*/5 * * * *',
    $$
    select
      net.http_post(
        url := 'https://sxvpiggednbftfqeokyd.supabase.co/functions/v1/send-notification-jobs',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-cron-secret', '<CRON_SECRET>'
        ),
        body := '{"limit":50}'::jsonb
      );
    $$
  );
```

If cron jobs already exist, unschedule old entries first or update them in place.

Verify the jobs were created:

```sql
select jobid, jobname, schedule, active
from cron.job
where jobname in (
  'schedule-training-reminders',
  'send-notification-jobs'
)
order by jobname;
```

## 4. Internal Test User

Keep rollout off globally:

```sql
update public.user_reminder_preferences
set server_reminders_enabled = false;
```

Enable one internal user:

```sql
update public.user_reminder_preferences
set server_reminders_enabled = true
where user_id = '<test-user-id>';
```

## 5. Smoke Checks

- Remote function smoke after manual migration:
  - `schedule-training-reminders` returned counts with `users_considered = 0`.
  - `send-notification-jobs` returned counts with `claimed = 0`.
- App writes `user_reminder_preferences`.
- `timezone` is an IANA value such as `Europe/Berlin`, not `CET`.
- Scheduler creates a near-due `notification_jobs` row.
- A second scheduler call does not duplicate the row.
- Sender claims through `claim_due_notification_jobs`.
- Matching production device receives the FCM notification.
- Tapping the notification opens training.
- Local daily reminder is suppressed for the server-enabled user.
