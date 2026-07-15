import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

function mapRedeemError(message: string): { status: number; code: string } {
  switch (message) {
    case 'invalid_code':
      return { status: 400, code: 'invalid_code' };
    case 'already_redeemed':
      return { status: 400, code: 'already_redeemed' };
    case 'expired_code':
      return { status: 400, code: 'expired_code' };
    case 'unsupported_code_type':
      return { status: 400, code: 'unsupported_code_type' };
    case 'unauthorized':
      return { status: 401, code: 'unauthorized' };
    default:
      return { status: 500, code: 'unknown_error' };
  }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'unauthorized' }, 401);
    }

    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const {
      data: { user },
      error: authError,
    } = await userClient.auth.getUser();
    if (authError || !user) {
      return jsonResponse({ error: 'unauthorized' }, 401);
    }

    const payload = (await req.json()) as { code?: string };
    const rawCode = payload.code ?? '';
    const code = rawCode.trim().toUpperCase();
    if (!code) {
      return jsonResponse({ error: 'invalid_code' }, 400);
    }

    const serviceClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    );

    const { data, error } = await serviceClient.rpc('redeem_access_code', {
      p_code: code,
      p_user_id: user.id,
    });
    if (error) {
      const mapped = mapRedeemError(error.message);
      return jsonResponse({ error: mapped.code }, mapped.status);
    }

    return jsonResponse({ success: true, data });
  } catch {
    return jsonResponse({ error: 'unknown_error' }, 500);
  }
});
