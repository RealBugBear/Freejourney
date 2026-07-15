import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { create, getNumericDate } from 'https://deno.land/x/djwt@v2.8/mod.ts';
import {
  buildCallRequestCopy,
  normalizeSupportedLocale,
} from '../_shared/notification_copy.ts';
import type { NotificationCopy } from '../_shared/notification_copy.ts';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const FIREBASE_SERVICE_ACCOUNT_JSON = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON') ?? '';
const FIREBASE_PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID') ?? 'corejourney-prod';

interface RequestPayload {
  channel_id: string;
}

interface DeviceTokenRow {
  user_id: string;
  token: string;
}

interface RecipientProfileRow {
  id: string;
  locale: string | null;
}

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
    if (!authHeader) {
      return json({ error: 'Missing Authorization header' }, 401);
    }

    const payload: RequestPayload = await req.json();
    if (!payload.channel_id) {
      return json({ error: 'Missing channel_id' }, 400);
    }

    const serviceClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const jwt = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await serviceClient.auth.getUser(jwt);
    if (userError || !user) {
      return json({ error: 'Unauthorized' }, 401);
    }

    const { data: callerMembership } = await serviceClient
      .from('chat_channel_members')
      .select('user_id')
      .eq('channel_id', payload.channel_id)
      .eq('user_id', user.id)
      .single();

    if (!callerMembership) {
      return json({ error: 'Not a channel member' }, 403);
    }

    const { data: recipients, error: recipientError } = await serviceClient
      .from('chat_channel_members')
      .select('user_id')
      .eq('channel_id', payload.channel_id)
      .neq('user_id', user.id);

    if (recipientError) throw recipientError;
    const recipientIds = (recipients ?? []).map((row: { user_id: string }) => row.user_id);
    if (recipientIds.length === 0) {
      return json({ sent: 0, skipped: 'no_recipients' });
    }

    const { data: recipientProfiles, error: profileError } = await serviceClient
      .from('profiles')
      .select('id, locale')
      .in('id', recipientIds);
    if (profileError) throw profileError;
    const localesByUserId = new Map(
      ((recipientProfiles ?? []) as RecipientProfileRow[]).map((profile) => [
        profile.id,
        normalizeSupportedLocale(profile.locale),
      ]),
    );

    const { data: tokens, error: tokenError } = await serviceClient
      .from('device_tokens')
      .select('user_id, token')
      .in('user_id', recipientIds)
      .eq('enabled', true)
      .is('revoked_at', null);

    if (tokenError) throw tokenError;
    if (!tokens || tokens.length === 0) {
      return json({ sent: 0, skipped: 'no_tokens' });
    }

    const accessToken = await getFirebaseAccessToken();
    let sent = 0;

    for (const row of tokens as DeviceTokenRow[]) {
      const copy = buildCallRequestCopy(
        localesByUserId.get(row.user_id) ?? 'de',
      );
      const ok = await sendFcmMessage(accessToken, row.token, {
        channel_id: payload.channel_id,
        requested_by: user.id,
      }, copy);
      if (ok) sent += 1;
    }

    return json({ sent });
  } catch (err) {
    console.error('notify-call-request error:', err);
    return json({ error: String(err) }, 500);
  }
});

async function getFirebaseAccessToken(): Promise<string> {
  if (!FIREBASE_SERVICE_ACCOUNT_JSON) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON secret is missing');
  }

  const account = JSON.parse(FIREBASE_SERVICE_ACCOUNT_JSON);
  const privateKey = await importPrivateKey(account.private_key);
  const now = getNumericDate(0);
  const assertion = await create(
    { alg: 'RS256', typ: 'JWT' },
    {
      iss: account.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging',
      aud: 'https://oauth2.googleapis.com/token',
      iat: now,
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

  if (!response.ok) {
    throw new Error(`Firebase token request failed: ${response.status}`);
  }

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
  for (let i = 0; i < binary.length; i += 1) {
    bytes[i] = binary.charCodeAt(i);
  }

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
          data: {
            type: 'call_request',
            ...data,
          },
          android: {
            priority: 'HIGH',
            notification: {
              sound: 'default',
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
              },
            },
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
