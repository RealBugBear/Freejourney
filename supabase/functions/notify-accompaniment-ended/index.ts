import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';
import { create, getNumericDate } from 'https://deno.land/x/djwt@v2.8/mod.ts';
import {
  buildAccompanimentEndedCopy,
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

    const { relationship_id } = await req.json();
    if (!relationship_id) return json({ error: 'Missing relationship_id' }, 400);

    const serviceClient = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);
    const jwt = authHeader.replace('Bearer ', '');
    const { data: { user }, error: userError } = await serviceClient.auth.getUser(jwt);
    if (userError || !user) return json({ error: 'Unauthorized' }, 401);

    // Atomic claim. Authorization alone is not enough: the RPC has already
    // committed, so the caller stays a valid client of the ended relationship
    // indefinitely and could otherwise loop this endpoint to spam the trainer.
    // Zero rows updated means somebody already claimed it.
    const { data: claimed, error: claimError } = await serviceClient
      .from('trainer_client_relationships')
      .update({ end_notification_sent_at: new Date().toISOString() })
      .eq('id', relationship_id)
      .eq('client_id', user.id)
      .not('ended_by_client_at', 'is', null)
      .is('end_notification_sent_at', null)
      .select('trainer_id, client_id')
      .maybeSingle();

    if (claimError) throw claimError;
    if (!claimed) return json({ sent: 0, skipped: 'already_sent' });

    const { data: tokens, error: tokenError } = await serviceClient
      .from('device_tokens')
      .select('token')
      .eq('user_id', claimed.trainer_id)
      .eq('enabled', true)
      .is('revoked_at', null);

    if (tokenError) throw tokenError;
    if (!tokens || tokens.length === 0) return json({ sent: 0, skipped: 'no_tokens' });

    const { data: trainerProfile } = await serviceClient
      .from('profiles')
      .select('locale')
      .eq('id', claimed.trainer_id)
      .maybeSingle();

    const { data: clientProfile } = await serviceClient
      .from('profiles')
      .select('display_name')
      .eq('id', claimed.client_id)
      .maybeSingle();

    const locale = normalizeSupportedLocale(trainerProfile?.locale);
    const clientLabel =
      (clientProfile?.display_name as string | null)?.trim() ||
      buildDefaultClientLabel(locale);
    const copy = buildAccompanimentEndedCopy(locale, clientLabel);

    const accessToken = await getFirebaseAccessToken();
    let sent = 0;
    for (const { token } of tokens as Array<{ token: string }>) {
      const ok = await sendFcmMessage(accessToken, token, {
        type: 'accompaniment_ended',
        relationship_id: relationship_id,
        client_name: clientLabel,
      }, copy);
      if (ok) sent += 1;
    }

    return json({ sent });
  } catch (err) {
    console.error('notify-accompaniment-ended error:', err);
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
