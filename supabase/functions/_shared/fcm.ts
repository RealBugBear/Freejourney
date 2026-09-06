import { create, getNumericDate } from 'https://deno.land/x/djwt@v2.8/mod.ts';

export interface FcmSendRequest {
  projectId: string;
  accessToken: string;
  token: string;
  title: string;
  body: string;
  data: Record<string, string>;
  priority?: 'NORMAL' | 'HIGH';
}

export interface FcmSendResult {
  ok: boolean;
  messageId?: string;
  errorCode?: string;
  permanent: boolean;
  rawError?: string;
}

export async function getFirebaseAccessToken(
  serviceAccountJson: string,
): Promise<string> {
  if (!serviceAccountJson) {
    throw new Error('FIREBASE_SERVICE_ACCOUNT_JSON secret is missing');
  }

  const account = JSON.parse(serviceAccountJson);
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
    signal: AbortSignal.timeout(10000),
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

export async function sendFcmNotification(
  request: FcmSendRequest,
): Promise<FcmSendResult> {
  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${request.projectId}/messages:send`,
    {
      method: 'POST',
      signal: AbortSignal.timeout(10000),
      headers: {
        Authorization: `Bearer ${request.accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token: request.token,
          notification: {
            title: request.title,
            body: request.body,
          },
          data: request.data,
          android: {
            priority: request.priority ?? 'NORMAL',
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

  const text = await response.text();
  if (response.ok) {
    const body = text ? JSON.parse(text) : {};
    return {
      ok: true,
      messageId: typeof body.name === 'string' ? body.name : undefined,
      permanent: false,
    };
  }

  const errorCode = extractFcmErrorCode(text);
  return {
    ok: false,
    errorCode,
    permanent: isPermanentTokenError(errorCode, text),
    rawError: text,
  };
}

export function isPermanentTokenError(
  errorCode?: string,
  rawError = '',
): boolean {
  if (errorCode === 'UNREGISTERED') return true;
  if (errorCode !== 'INVALID_ARGUMENT') return false;

  // INVALID_ARGUMENT can mean a bad payload. Only classify as token-permanent
  // when FCM marks the token field itself as invalid.
  return rawError.includes('message.token') ||
    rawError.toLowerCase().includes('registration token');
}

export function extractFcmErrorCode(rawError: string): string | undefined {
  try {
    const parsed = JSON.parse(rawError);
    const details = parsed?.error?.details;
    if (Array.isArray(details)) {
      for (const detail of details) {
        const code = detail?.errorCode;
        if (typeof code === 'string' && code.length > 0) return code;
      }
    }
    const status = parsed?.error?.status;
    return typeof status === 'string' ? status : undefined;
  } catch (_) {
    return undefined;
  }
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
