import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return json({ ok: true })
  }

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'Unauthorized' }, 401)

    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )
    const { data: { user }, error: authError } = await userClient.auth.getUser()
    if (authError || !user) return json({ error: 'Unauthorized' }, 401)

    const serviceClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    const { data: caller } = await serviceClient
      .from('profiles')
      .select('role')
      .eq('id', user.id)
      .single()
    if (caller?.role !== 'admin') return json({ error: 'Forbidden' }, 403)

    const body = await req.json() as { user_id?: string; email?: string }
    const userId = body.user_id
    if (!userId) return json({ error: 'user_id is required' }, 400)
    if (userId === user.id) {
      return json({ error: 'Admins cannot delete their own account' }, 400)
    }

    const { data: targetProfile } = await serviceClient
      .from('profiles')
      .select('role, display_name')
      .eq('id', userId)
      .single()
    if (targetProfile?.role === 'admin') {
      return json({ error: 'Deleting admin accounts is blocked here. Demote first if this is intentional.' }, 400)
    }

    const { error: auditError } = await serviceClient.from('admin_audit_events').insert({
      actor_id: user.id,
      action: 'user_deleted',
      target_type: 'auth_user',
      target_id: userId,
      metadata: {
        email: body.email ?? null,
        previous_role: targetProfile?.role ?? null,
        display_name: targetProfile?.display_name ?? null,
      },
    })
    if (auditError) return json({ error: auditError.message }, 500)

    const { error: deleteError } = await serviceClient.rpc('admin_delete_auth_user', {
      p_actor_id: user.id,
      p_user_id: userId,
    })
    if (deleteError) return json({ error: deleteError.message }, 500)

    return json({ success: true, user_id: userId })
  } catch (e) {
    return json({ error: String(e) }, 500)
  }
})

function json(body: Record<string, unknown>, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
