import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { create, getNumericDate } from 'https://deno.land/x/djwt@v2.8/mod.ts';
import {
  buildAppointmentConfirmedCopy,
  buildDefaultAppointmentTitle,
  buildDefaultClientLabel,
  normalizeSupportedLocale,
} from '../_shared/notification_copy.ts';
import type { NotificationCopy } from '../_shared/notification_copy.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FIREBASE_SERVICE_ACCOUNT_JSON = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON') ?? '';
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID') ?? 'corejourney-prod';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, content-type',
      },
    });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) return json({ error: 'Missing Authorization header' }, 401);

    const { appointment_id } = await req.json();
    if (!appointment_id) return json({ error: 'Missing appointment_id' }, 400);

    const serviceClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const jwt = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await serviceClient.auth.getUser(jwt);
    if (userError || !user) return json({ error: 'Unauthorized' }, 401);

    const { data: appointment, error: apptError } = await serviceClient
      .from('appointments')
      .select('id, trainer_id, trainee_id, title, scheduled_for, duration_minutes, location, notes, profiles!trainee_id(display_name)')
      .eq('id', appointment_id)
      .single();

    if (apptError || !appointment) return json({ error: 'Appointment not found' }, 404);
    if (appointment.trainee_id !== user.id) return json({ error: 'Forbidden' }, 403);
    if (!appointment.scheduled_for) return json({ error: 'Appointment has no scheduled time' }, 400);

    const { data: tokens, error: tokenError } = await serviceClient
      .from('device_tokens')
      .select('token')
      .eq('user_id', appointment.trainer_id)
      .eq('enabled', true)
      .is('revoked_at', null);

    if (tokenError) throw tokenError;
    if (!tokens || tokens.length === 0) return json({ sent: 0, skipped: 'no_tokens' });

    const { data: recipientProfile, error: profileError } = await serviceClient
      .from('profiles')
      .select('locale')
      .eq('id', appointment.trainer_id)
      .maybeSingle();
    if (profileError) throw profileError;
    const locale = normalizeSupportedLocale(recipientProfile?.locale);
    const relatedProfile = (Array.isArray(appointment.profiles)
      ? appointment.profiles[0]
      : appointment.profiles) as { display_name?: string | null } | null;
    const traineeName = relatedProfile?.display_name ??
      buildDefaultClientLabel(locale);
    const copy = buildAppointmentConfirmedCopy({
      locale,
      traineeName,
      scheduledFor: appointment.scheduled_for,
    });

    const accessToken = await getFirebaseAccessToken();
    let sent = 0;
    for (const { token } of tokens as Array<{ token: string }>) {
      const ok = await sendFcmMessage(accessToken, token, {
        type: 'appointment_confirmed',
        appointment_id: appointment.id,
        title: appointment.title ?? buildDefaultAppointmentTitle(locale),
        scheduled_for: appointment.scheduled_for,
        duration_minutes: String(appointment.duration_minutes ?? 60),
        location: appointment.location ?? '',
        notes: appointment.notes ?? '',
        trainee_name: traineeName,
      }, copy);
      if (ok) sent += 1;
    }

    return json({ sent });
  } catch (err) {
    console.error('notify-appointment-confirmed error:', err);
    return json({ error: String(err) }, 500);
  }
});

async function getFirebaseAccessToken(): Promise<string> {
  if (!FIREBASE_SERVICE_ACCOUNT_JSON) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON secret is missing');
  }
  const account = JSON.parse(FIREBASE_SERVICE_ACCOUNT_JSON);
  const privateKey = await importPrivateKey(account.private_key);
  const assertion = await create(
    { alg: 'RS256', typ: 'JWT' },
    {
      iss: account.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: getNumericDate(0),
      exp: getNumericDate(3600),
    },
    privateKey,
  );
  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });
  if (!response.ok) throw new Error(`Firebase token request failed: ${response.status}`);
  const data = await response.json();
  return data.access_token as string;
}

async function importPrivateKey(pem: string): Promise<CryptoKey> {
  const body = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replaceAll('\\n', '')
    .replaceAll('\n', '')
    .trim();
  const binary = atob(body);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i += 1) bytes[i] = binary.charCodeAt(i);
  return await crypto.subtle.importKey(
    'pkcs8',
    bytes.buffer,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
}

async function sendFcmMessage(
  accessToken: string,
  token: string,
  data: Record<string, string>,
  copy: NotificationCopy,
): Promise<boolean> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: {
            title: copy.title,
            body: copy.body,
          },
          data,
          android: {
            priority: 'HIGH',
            notification: { sound: 'default' },
          },
          apns: {
            payload: { aps: { sound: 'default' } },
          },
        },
      }),
    },
  );
  if (!response.ok) {
    console.error('FCM send failed:', response.status, await response.text());
    return false;
  }
  return true;
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
