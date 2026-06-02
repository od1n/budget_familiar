import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req) => {
  // Preflight CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const json = (body: object, status = 200) =>
    new Response(JSON.stringify(body), {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  try {
    // ── 1. Verificar JWT ────────────────────────────────────────────────────
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return json({ error: 'no_auth' }, 401)

    // Cliente con permisos del usuario (respeta RLS)
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )

    // Cliente admin (service_role) para operaciones privilegiadas
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    )

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser()

    if (userError || !user) return json({ error: 'invalid_session' }, 401)

    const userId = user.id

    // ── 2. Verificar grupos propios con otros miembros ──────────────────────
    // Si el usuario es owner de un grupo que tiene OTROS miembros, no puede
    // eliminar su cuenta sin antes transferir la administración.
    const { data: ownedGroups, error: groupsError } = await adminClient
      .from('family_groups')
      .select('id, name')
      .eq('owner_id', userId)

    if (groupsError) throw groupsError

    for (const group of ownedGroups ?? []) {
      const { count, error: countError } = await adminClient
        .from('group_members')
        .select('*', { count: 'exact', head: true })
        .eq('group_id', group.id)
        .neq('user_id', userId)

      if (countError) throw countError

      if ((count ?? 0) > 0) {
        return json(
          {
            error: 'owner_with_members',
            group_name: group.name,
            message:
              `Eres administrador del grupo "${group.name}" con otros miembros. ` +
              'Transfiere la administración antes de eliminar tu cuenta.',
          },
          400,
        )
      }
    }

    // ── 3. Eliminar el usuario ──────────────────────────────────────────────
    // auth.users → ON DELETE CASCADE cubre:
    //   profiles, family_groups (owner_id), group_members (user_id),
    //   transactions (user_id), ai_usage_log (user_id)
    const { error: deleteError } =
      await adminClient.auth.admin.deleteUser(userId)

    if (deleteError) throw deleteError

    return json({ success: true })
  } catch (err) {
    console.error('delete-account error:', err)
    return json({ error: 'server_error', message: String(err) }, 500)
  }
})
