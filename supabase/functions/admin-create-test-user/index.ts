import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

type CreateUserBody = {
  email?: string
  password?: string
  display_name?: string
  role?: string
  subscription_tier?: string
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

    const body = await req.json() as CreateUserBody
    const email = body.email?.trim().toLowerCase()
    const password = body.password ?? ''
    const displayName = body.display_name?.trim() || null
    const role = body.role ?? 'practitioner'
    const subscriptionTier = body.subscription_tier ?? 'free'

    if (!email || !email.includes('@')) {
      return json({ error: 'Valid email is required' }, 400)
    }
    if (password.length < 8) {
      return json({ error: 'Password must be at least 8 characters' }, 400)
    }
    if (!['practitioner', 'trainer', 'admin'].includes(role)) {
      return json({ error: 'role must be practitioner, trainer, or admin' }, 400)
    }
    if (!['free', 'premium'].includes(subscriptionTier)) {
      return json({ error: 'subscription_tier must be free or premium' }, 400)
    }

    const { data: created, error: createError } = await serviceClient.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        display_name: displayName,
        created_by_admin: true,
        test_user: true,
      },
    })
    if (createError || !created.user) {
      return json({ error: createError?.message ?? 'User creation failed' }, 500)
    }

    const { error: profileError } = await serviceClient
      .from('profiles')
      .update({
        display_name: displayName,
        role,
        subscription_tier: subscriptionTier,
      })
      .eq('id', created.user.id)
    if (profileError) {
      await serviceClient.auth.admin.deleteUser(created.user.id)
      return json({ error: profileError.message }, 500)
    }

    const { error: auditError } = await serviceClient.from('admin_audit_events').insert({
      actor_id: user.id,
      action: 'test_user_created',
      target_type: 'auth_user',
      target_id: created.user.id,
      metadata: {
        email,
        role,
        subscription_tier: subscriptionTier,
      },
    })
    if (auditError) {
      await serviceClient.auth.admin.deleteUser(created.user.id)
      return json({ error: auditError.message }, 500)
    }

    return json({
      success: true,
      user_id: created.user.id,
      email,
      role,
      subscription_tier: subscriptionTier,
    })
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
