import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

import {
  addDaysToLocalDate,
  localDateInTimezone,
  minuteOfDayInTimezone,
  minuteToTime,
  softReminderMinute,
} from '../_shared/reminder_time.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const CRON_SECRET = Deno.env.get('CRON_SECRET') ?? '';
const APP_ENVIRONMENT = Deno.env.get('APP_ENVIRONMENT') ?? 'production';

const LOOKBACK_MS = 2 * 60 * 1000;
const HORIZON_MS = 15 * 60 * 1000;
const STREAK_WARNING_MINUTE = 19 * 60;
const COMEBACK_MINUTE = 9 * 60;

function createServiceClient() {
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
}

// Derive from the concrete factory, preserving Supabase's default schema.
// The generic createClient return type loses those defaults on newer SDK typings.
type ServiceClient = ReturnType<typeof createServiceClient>;

interface ReminderPreferenceRow {
  user_id: string;
  timezone: string;
  quiet_start: string;
  quiet_end: string;
}

interface TrainingSessionRow {
  completed_at: string;
}

interface NotificationJobRow {
  type: 'training_soft' | 'comeback' | 'streak_warning';
  scheduled_for: string;
  status: string;
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
    const nowOverride = typeof body.now === 'string' ? body.now : null;
    const now = nowOverride && APP_ENVIRONMENT !== 'production'
      ? new Date(nowOverride)
      : new Date();
    if (Number.isNaN(now.getTime())) {
      return json({ error: 'invalid now override' }, 400);
    }

    const userIdFilter = typeof body.user_id === 'string' ? body.user_id : null;
    const supabase = createServiceClient();

    let preferenceQuery = supabase
      .from('user_reminder_preferences')
      .select('user_id, timezone, quiet_start, quiet_end')
      .eq('enabled', true)
      .eq('server_reminders_enabled', true);

    if (userIdFilter) {
      preferenceQuery = preferenceQuery.eq('user_id', userIdFilter);
    }

    const { data: preferences, error: preferencesError } = await preferenceQuery;
    if (preferencesError) throw preferencesError;

    const counts = {
      users_considered: 0,
      skipped_no_active_enrollment: 0,
      skipped_trained_today: 0,
      skipped_invalid_timezone: 0,
      skipped_outside_horizon: 0,
      skipped_comeback_limit: 0,
      jobs_inserted: 0,
      duplicate_jobs_ignored: 0,
    };

    for (const preference of (preferences ?? []) as ReminderPreferenceRow[]) {
      counts.users_considered += 1;
      const result = await scheduleForUser(supabase, preference, now);
      for (const [key, value] of Object.entries(result)) {
        counts[key as keyof typeof counts] += value;
      }
    }

    return json(counts);
  } catch (err) {
    console.error('schedule-training-reminders error:', err);
    return json({ error: formatError(err) }, 500);
  }
});

async function scheduleForUser(
  supabase: ServiceClient,
  preference: ReminderPreferenceRow,
  now: Date,
): Promise<Record<string, number>> {
  const counts: Record<string, number> = {
    skipped_no_active_enrollment: 0,
    skipped_trained_today: 0,
    skipped_invalid_timezone: 0,
    skipped_outside_horizon: 0,
    skipped_comeback_limit: 0,
    jobs_inserted: 0,
    duplicate_jobs_ignored: 0,
  };

  let localDate: string;
  try {
    localDate = localDateInTimezone(now.toISOString(), preference.timezone);
  } catch (_) {
    counts.skipped_invalid_timezone += 1;
    return counts;
  }

  const { data: enrollments, error: enrollmentError } = await supabase
    .from('enrollments')
    .select('id')
    .eq('user_id', preference.user_id)
    .eq('status', 'active');
  if (enrollmentError) throw enrollmentError;

  const enrollmentIds = (enrollments ?? []).map((row: { id: string }) => row.id);
  if (enrollmentIds.length === 0) {
    counts.skipped_no_active_enrollment += 1;
    return counts;
  }

  const yesterday = addDaysToLocalDate(localDate, -1);
  const historyStart = addDaysToLocalDate(localDate, -14);
  const historyQueryStart = addDaysToLocalDate(historyStart, -1);
  const sessions = await loadCompletedSessions(
    supabase,
    preference.user_id,
    enrollmentIds,
    historyQueryStart,
  );

  const trainedToday = sessions.some((session) =>
    localDateInTimezone(session.completed_at, preference.timezone) === localDate
  );
  if (trainedToday) {
    counts.skipped_trained_today += 1;
    return counts;
  }

  const trainedYesterday = sessions.some((session) =>
    localDateInTimezone(session.completed_at, preference.timezone) === yesterday
  );
  const historyMinutes = sessions.map((session) =>
    minuteOfDayInTimezone(session.completed_at, preference.timezone)
  );

  const quietStart = parseTimeToMinute(preference.quiet_start);
  const quietEnd = parseTimeToMinute(preference.quiet_end);
  const candidates: Array<{ type: 'training_soft' | 'comeback' | 'streak_warning'; minute: number }> = [];

  const comebackWouldApply = !trainedYesterday;
  if (comebackWouldApply) {
    const priorComebacks = await countPriorSentComebacks(
      supabase,
      preference.user_id,
      localDate,
    );
    if (priorComebacks < 3) {
      candidates.push({ type: 'comeback', minute: COMEBACK_MINUTE });
    } else {
      counts.skipped_comeback_limit += 1;
    }
  }

  if (!comebackWouldApply) {
    candidates.push({
      type: 'training_soft',
      minute: softReminderMinute(historyMinutes, quietStart, quietEnd),
    });
  }

  const latestEarlierPushMinute = await latestTrainingPushMinute(
    supabase,
    preference.user_id,
    localDate,
    preference.timezone,
    candidates,
  );
  if (
    latestEarlierPushMinute == null ||
    STREAK_WARNING_MINUTE - latestEarlierPushMinute >= 4 * 60
  ) {
    candidates.push({ type: 'streak_warning', minute: STREAK_WARNING_MINUTE });
  }

  for (const candidate of candidates) {
    const scheduledFor = await localToUtc(
      supabase,
      localDate,
      candidate.minute,
      preference.timezone,
    );
    if (!isInsideSchedulingHorizon(scheduledFor, now)) {
      counts.skipped_outside_horizon += 1;
      continue;
    }

    const inserted = await insertJob(supabase, {
      user_id: preference.user_id,
      type: candidate.type,
      scheduled_for: scheduledFor.toISOString(),
      local_date: localDate,
      timezone: preference.timezone,
      idempotency_key: `${preference.user_id}:${candidate.type}:${localDate}`,
    });
    if (inserted) {
      counts.jobs_inserted += 1;
    } else {
      counts.duplicate_jobs_ignored += 1;
    }
  }

  return counts;
}

async function loadCompletedSessions(
  supabase: ServiceClient,
  userId: string,
  enrollmentIds: string[],
  historyStartLocalDate: string,
): Promise<TrainingSessionRow[]> {
  const { data, error } = await supabase
    .from('training_sessions')
    .select('completed_at')
    .eq('user_id', userId)
    .in('enrollment_id', enrollmentIds)
    .eq('is_completed', true)
    .not('completed_at', 'is', null)
    .gte('completed_at', `${historyStartLocalDate}T00:00:00Z`);
  if (error) throw error;
  return (data ?? []) as TrainingSessionRow[];
}

async function countPriorSentComebacks(
  supabase: ServiceClient,
  userId: string,
  localDate: string,
): Promise<number> {
  const start = addDaysToLocalDate(localDate, -3);
  const end = addDaysToLocalDate(localDate, -1);
  const { count, error } = await supabase
    .from('notification_jobs')
    .select('id', { count: 'exact', head: true })
    .eq('user_id', userId)
    .eq('type', 'comeback')
    .eq('status', 'sent')
    .gte('local_date', start)
    .lte('local_date', end);
  if (error) throw error;
  return count ?? 0;
}

async function latestTrainingPushMinute(
  supabase: ServiceClient,
  userId: string,
  localDate: string,
  timezone: string,
  candidates: Array<{ type: string; minute: number }>,
): Promise<number | null> {
  const candidateMinutes = candidates
    .filter((candidate) => candidate.type === 'training_soft' || candidate.type === 'comeback')
    .map((candidate) => candidate.minute);

  const { data, error } = await supabase
    .from('notification_jobs')
    .select('type, scheduled_for, status')
    .eq('user_id', userId)
    .eq('local_date', localDate)
    .in('type', ['training_soft', 'comeback'])
    .in('status', ['pending', 'sending', 'sent']);
  if (error) throw error;

  const existingMinutes = ((data ?? []) as NotificationJobRow[]).map((job) =>
    minuteOfDayInTimezone(job.scheduled_for, timezone)
  );
  const all = [...candidateMinutes, ...existingMinutes].filter((minute) =>
    minute < STREAK_WARNING_MINUTE
  );
  if (all.length === 0) return null;
  return Math.max(...all);
}

async function localToUtc(
  supabase: ServiceClient,
  localDate: string,
  minute: number,
  timezone: string,
): Promise<Date> {
  const { data, error } = await supabase.rpc('training_reminder_local_to_utc', {
    p_local_date: localDate,
    p_local_time: minuteToTime(minute),
    p_timezone: timezone,
  });
  if (error) throw error;
  return new Date(data as string);
}

async function insertJob(
  supabase: ServiceClient,
  job: Record<string, string>,
): Promise<boolean> {
  const { error } = await supabase.from('notification_jobs').insert(job);
  if (!error) return true;
  if (error.code === '23505') return false;
  throw error;
}

function isInsideSchedulingHorizon(scheduledFor: Date, now: Date): boolean {
  const delta = scheduledFor.getTime() - now.getTime();
  return delta >= -LOOKBACK_MS && delta <= HORIZON_MS;
}

function parseTimeToMinute(value: string): number {
  const [hour, minute] = value.split(':').map(Number);
  return hour * 60 + minute;
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
