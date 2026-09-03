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

    // ── 2.5 Borrar datos de grupos propios sin cascada ──────────────────────
    // Estas tablas usan group_id como TEXT SIN llave foránea a family_groups,
    // así que el CASCADE de auth.users NO las alcanza. Se borran explícitamente
    // para no dejar datos personales huérfanos (derecho de supresión GDPR/Play).
    const ownedGroupIds = (ownedGroups ?? []).map((g) => g.id as string)
    if (ownedGroupIds.length > 0) {
      const groupScopedTables = [
        'accounts',
        'ai_insights',
        'budgets',
        'categories',
        'savings_goals',
        'virtual_envelopes',
      ]
      for (const table of groupScopedTables) {
        const { error: delErr } = await adminClient
          .from(table)
          .delete()
          .in('group_id', ownedGroupIds)
        if (delErr) throw delErr
      }
    }

    // ── 3. Eliminar el usuario ──────────────────────────────────────────────
    // auth.users → ON DELETE CASCADE cubre el resto:
    //   profiles, family_groups (owner_id), group_members (user_id),
    //   transactions (user_id), recurring_transactions, investments,
    //   ai_usage_log, fcm_tokens (todas con user_id ON DELETE CASCADE).
    const { error: deleteError } =
      await adminClient.auth.admin.deleteUser(userId)

    if (deleteError) throw deleteError

    return json({ success: true })
  } catch (err) {
    console.error('delete-account error:', err)
    return json({ error: 'server_error', message: String(err) }, 500)
  }
})
