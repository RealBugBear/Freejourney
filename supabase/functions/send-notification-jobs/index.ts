import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

import {
  buildTrainingReminderCopy,
} from '../_shared/reminder_copy.ts';
import type {
  ReminderType,
  WeeklyGoalSource,
} from '../_shared/reminder_copy.ts';
import {
  getFirebaseAccessToken,
  sendFcmNotification,
} from '../_shared/fcm.ts';
import {
  addDaysToLocalDate,
  localDateInTimezone,
  minuteOfDayInTimezone,
} from '../_shared/reminder_time.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const CRON_SECRET = Deno.env.get('CRON_SECRET') ?? '';
const APP_ENVIRONMENT = Deno.env.get('APP_ENVIRONMENT') ?? 'production';
const FIREBASE_SERVICE_ACCOUNT_JSON = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON') ?? '';
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID') ?? 'corejourney-prod';

const MAX_LIMIT = 100;

interface NotificationJob {
  id: string;
  user_id: string;
  type: ReminderType;
  scheduled_for: string;
  local_date: string;
  timezone: string;
  created_at: string;
}

interface ReminderPreference {
  enabled: boolean;
  weekly_goal: number | null;
  weekly_goal_source: WeeklyGoalSource;
}

interface DeviceToken {
  id: string;
  token: string;
}

interface TrainingSession {
  completed_at: string;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return cors();
  }

  // Fail closed: without a configured CRON_SECRET an empty header would match ''.
  if (!CRON_SECRET || req.headers.get('x-cron-secret') !== CRON_SECRET) {
    return json({ error: 'unauthorized' }, 401);
  }

  try {
    const body = await readJson(req);
    const limit = Math.min(
      Math.max(Number(body.limit ?? 50) || 50, 1),
      MAX_LIMIT,
    );
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const { data: jobs, error: claimError } = await supabase.rpc(
      'claim_due_notification_jobs',
      { p_limit: limit },
    );
    if (claimError) throw claimError;

    const claimed = (jobs ?? []) as NotificationJob[];
    const counts = {
      claimed: claimed.length,
      sent: 0,
      skipped: 0,
      failed: 0,
      tokens_disabled: 0,
    };

    if (claimed.length === 0) return json(counts);

    let accessToken: string;
    try {
      accessToken = await getFirebaseAccessToken(FIREBASE_SERVICE_ACCOUNT_JSON);
    } catch (tokenError) {
      for (const job of claimed) {
        await updateJob(supabase, job.id, {
          status: 'failed',
          last_error: formatError(tokenError),
        });
      }
      counts.failed = claimed.length;
      return json(counts);
    }

    for (const job of claimed) {
      try {
        const result = await processJob(supabase, job, accessToken);
        counts.sent += result.status === 'sent' ? 1 : 0;
        counts.skipped += result.status === 'skipped' ? 1 : 0;
        counts.failed += result.status === 'failed' ? 1 : 0;
        counts.tokens_disabled += result.tokensDisabled;
      } catch (jobError) {
        console.error('notification job failed:', job.id, jobError);
        await updateJob(supabase, job.id, {
          status: 'failed',
          last_error: formatError(jobError),
        });
        counts.failed += 1;
      }
    }

    return json(counts);
  } catch (err) {
    console.error('send-notification-jobs error:', err);
    return json({ error: formatError(err) }, 500);
  }
});

async function processJob(
  supabase: ReturnType<typeof createClient>,
  job: NotificationJob,
  accessToken: string,
): Promise<{ status: 'sent' | 'failed' | 'skipped'; tokensDisabled: number }> {
  const skipReason = await revalidateJob(supabase, job);
  if (skipReason) {
    await updateJob(supabase, job.id, {
      status: 'skipped',
      last_error: skipReason,
      sent_at: new Date().toISOString(),
    });
    return { status: 'skipped', tokensDisabled: 0 };
  }

  const { data: preference, error: preferenceError } = await supabase
    .from('user_reminder_preferences')
    .select('enabled, weekly_goal, weekly_goal_source')
    .eq('user_id', job.user_id)
    .single();
  if (preferenceError) throw preferenceError;

  const { data: tokens, error: tokenError } = await supabase
    .from('device_tokens')
    .select('id, token')
    .eq('user_id', job.user_id)
    .eq('enabled', true)
    .is('revoked_at', null)
    .eq('environment', APP_ENVIRONMENT);
  if (tokenError) throw tokenError;

  const activeTokens = (tokens ?? []) as DeviceToken[];
  if (activeTokens.length === 0) {
    await updateJob(supabase, job.id, {
      status: 'skipped',
      last_error: 'no_tokens',
      sent_at: new Date().toISOString(),
    });
    return { status: 'skipped', tokensDisabled: 0 };
  }

  const streak = await calculateDailyStreak(supabase, job);
  const copy = buildTrainingReminderCopy(
    job.type,
    streak,
    (preference as ReminderPreference).weekly_goal,
    (preference as ReminderPreference).weekly_goal_source,
  );

  const messageIds: string[] = [];
  const errors: string[] = [];
  let sent = 0;
  let failed = 0;
  let tokensDisabled = 0;

  for (const row of activeTokens) {
    const result = await sendFcmNotification({
      projectId: FIREBASE_PROJECT_ID,
      accessToken,
      token: row.token,
      title: copy.title,
      body: copy.body,
      data: {
        type: 'training_reminder',
        reminder_type: job.type,
        job_id: job.id,
      },
      priority: 'NORMAL',
    });

    if (result.ok) {
      sent += 1;
      if (result.messageId) messageIds.push(result.messageId);
      continue;
    }

    failed += 1;
    errors.push(result.errorCode ?? result.rawError ?? 'unknown_fcm_error');
    if (result.permanent) {
      await disableToken(supabase, row.id);
      tokensDisabled += 1;
    }
  }

  const status = sent > 0 ? 'sent' : 'failed';
  await updateJob(supabase, job.id, {
    status,
    sent_token_count: sent,
    failed_token_count: failed,
    fcm_message_ids: messageIds,
    last_error: errors.length > 0 ? errors.slice(0, 5).join('; ') : null,
    sent_at: new Date().toISOString(),
  });

  return { status, tokensDisabled };
}

async function revalidateJob(
  supabase: ReturnType<typeof createClient>,
  job: NotificationJob,
): Promise<string | null> {
  const now = Date.now();
  const scheduled = new Date(job.scheduled_for).getTime();
  if (now - scheduled > 60 * 60 * 1000) return 'stale_job';

  const { data: preference, error: preferenceError } = await supabase
    .from('user_reminder_preferences')
    .select('enabled')
    .eq('user_id', job.user_id)
    .maybeSingle();
  if (preferenceError) throw preferenceError;
  if (!preference || !(preference as ReminderPreference).enabled) {
    return 'preferences_disabled';
  }

  const { data: enrollments, error: enrollmentError } = await supabase
    .from('enrollments')
    .select('id')
    .eq('user_id', job.user_id)
    .eq('status', 'active');
  if (enrollmentError) throw enrollmentError;
  const enrollmentIds = (enrollments ?? []).map((row: { id: string }) => row.id);
  if (enrollmentIds.length === 0) return 'no_active_enrollment';

  const sessions = await loadCompletedSessionsForDate(
    supabase,
    job.user_id,
    enrollmentIds,
    job.created_at,
    job.local_date,
    job.timezone,
  );
  if (sessions.length > 0) return 'trained_after_job_created';

  if (job.type === 'comeback') {
    const morningSessions = await loadCompletedSessionsForDate(
      supabase,
      job.user_id,
      enrollmentIds,
      `${addDaysToLocalDate(job.local_date, -1)}T00:00:00Z`,
      job.local_date,
      job.timezone,
    );
    const trainedBeforeNine = morningSessions.some((session) =>
      minuteOfDayInTimezone(session.completed_at, job.timezone) < 9 * 60
    );
    if (trainedBeforeNine) return 'trained_before_comeback';
  }

  if (job.type === 'streak_warning') {
    const { data: earlierJobs, error: jobsError } = await supabase
      .from('notification_jobs')
      .select('scheduled_for')
      .eq('user_id', job.user_id)
      .eq('local_date', job.local_date)
      .in('type', ['training_soft', 'comeback'])
      .eq('status', 'sent')
      .lte('scheduled_for', job.scheduled_for)
      .order('scheduled_for', { ascending: false })
      .limit(1);
    if (jobsError) throw jobsError;

    const earlier = earlierJobs?.[0]?.scheduled_for as string | undefined;
    if (earlier) {
      const gapMs = new Date(job.scheduled_for).getTime() - new Date(earlier).getTime();
      if (gapMs < 4 * 60 * 60 * 1000) return 'streak_warning_spacing';
    }
  }

  return null;
}

async function loadCompletedSessionsForDate(
  supabase: ReturnType<typeof createClient>,
  userId: string,
  enrollmentIds: string[],
  completedAfterIso: string,
  localDate: string,
  timezone: string,
): Promise<TrainingSession[]> {
  const { data, error } = await supabase
    .from('training_sessions')
    .select('completed_at')
    .eq('user_id', userId)
    .in('enrollment_id', enrollmentIds)
    .eq('is_completed', true)
    .not('completed_at', 'is', null)
    .gte('completed_at', completedAfterIso);
  if (error) throw error;

  return ((data ?? []) as TrainingSession[]).filter((session) =>
    localDateInTimezone(session.completed_at, timezone) === localDate
  );
}

async function calculateDailyStreak(
  supabase: ReturnType<typeof createClient>,
  job: NotificationJob,
): Promise<number | null> {
  const { data, error } = await supabase
    .from('training_sessions')
    .select('completed_at')
    .eq('user_id', job.user_id)
    .eq('is_completed', true)
    .not('completed_at', 'is', null)
    .order('completed_at', { ascending: false })
    .limit(60);
  if (error) throw error;

  const completedDates = new Set(
    ((data ?? []) as TrainingSession[]).map((session) =>
      localDateInTimezone(session.completed_at, job.timezone)
    ),
  );
  if (completedDates.size === 0) return null;

  let streak = 0;
  let cursor = new Date(`${job.local_date}T00:00:00Z`);
  cursor.setUTCDate(cursor.getUTCDate() - 1);
  while (streak < 60) {
    const date = cursor.toISOString().slice(0, 10);
    if (!completedDates.has(date)) break;
    streak += 1;
    cursor.setUTCDate(cursor.getUTCDate() - 1);
  }

  return streak > 0 ? streak : null;
}

async function disableToken(
  supabase: ReturnType<typeof createClient>,
  tokenId: string,
): Promise<void> {
  const { error } = await supabase
    .from('device_tokens')
    .update({
      enabled: false,
      revoked_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('id', tokenId);
  if (error) throw error;
}

async function updateJob(
  supabase: ReturnType<typeof createClient>,
  jobId: string,
  values: Record<string, unknown>,
): Promise<void> {
  const { error } = await supabase
    .from('notification_jobs')
    .update(values)
    .eq('id', jobId);
  if (error) throw error;
}

async function readJson(req: Request): Promise<Record<string, unknown>> {
  if (req.method !== 'POST') return {};
  const text = await req.text();
  if (!text.trim()) return {};
  return JSON.parse(text);
}

function cors(): Response {
  return new Response(null, {
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'authorization, content-type, x-cron-secret',
    },
  });
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    },
  });
}

function formatError(error: unknown): string {
  if (error instanceof Error) return error.message;
  if (typeof error === 'string') return error;
  if (error && typeof error === 'object') {
    const record = error as Record<string, unknown>;
    const fields = ['message', 'code', 'details', 'hint']
      .map((key) => [key, record[key]])
      .filter((entry): entry is [string, unknown] => entry[1] != null);
    if (fields.length > 0) {
      return fields.map(([key, value]) => `${key}: ${String(value)}`).join('; ');
    }
  }
  try {
    return JSON.stringify(error, Object.getOwnPropertyNames(error));
  } catch (_) {
    return String(error);
  }
}
