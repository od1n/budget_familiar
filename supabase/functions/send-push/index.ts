import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ── Tipos ─────────────────────────────────────────────────────────────────────

interface ServiceAccount {
  client_email: string
  private_key: string
  project_id: string
}

// ── JWT / OAuth para FCM HTTP v1 API ──────────────────────────────────────────

function base64url(data: Uint8Array): string {
  return btoa(String.fromCharCode(...data))
    .replace(/\+/g, '-').replace(/\//g, '_').replace(/=/g, '')
}

function base64urlString(s: string): string {
  return base64url(new TextEncoder().encode(s))
}

function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, '').replace(/\s/g, '')
  const bin = atob(b64)
  const bytes = new Uint8Array(bin.length)
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i)
  return bytes.buffer
}

async function getFcmAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000)
  const header = base64urlString(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))
  const payload = base64urlString(JSON.stringify({
    iss: sa.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }))
  const sigInput = `${header}.${payload}`

  const key = await crypto.subtle.importKey(
    'pkcs8', pemToDer(sa.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false, ['sign'],
  )
  const sigBytes = new Uint8Array(
    await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key,
      new TextEncoder().encode(sigInput))
  )
  const jwt = `${sigInput}.${base64url(sigBytes)}`

  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  })
  const td = await tokenRes.json() as { access_token: string }
  return td.access_token
}

// ── Enviar notificación FCM v1 ────────────────────────────────────────────────

async function sendFcmMessage(
  accessToken: string,
  projectId: string,
  token: string,
  title: string,
  body: string,
  data?: Record<string, string>,
): Promise<boolean> {
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          android: { priority: 'high' },
          data: data ?? {},
        },
      }),
    },
  )
  if (!res.ok) {
    const err = await res.text()
    console.warn(`FCM send error for token ${token.slice(0, 20)}…: ${err}`)
    return false
  }
  return true
}

// ── Handler ───────────────────────────────────────────────────────────────────

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}
const json = (b: object, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...cors, 'Content-Type': 'application/json' } })

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    // Autenticación (JWT del usuario que dispara el push)
    const auth = req.headers.get('Authorization')
    if (!auth) return json({ error: 'no_auth' }, 401)

    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: auth } } },
    )
    const adminClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    )

    const { data: { user } } = await userClient.auth.getUser()
    if (!user) return json({ error: 'invalid_session' }, 401)

    const body = await req.json() as {
      group_id: string
      title: string
      body: string
      data?: Record<string, string>
      exclude_user_id?: string  // no enviar al remitente
    }

    if (!body.group_id || !body.title || !body.body) {
      return json({ error: 'missing_fields' }, 400)
    }

    // Leer credenciales FCM desde secrets
    const saJson = Deno.env.get('FCM_SERVICE_ACCOUNT_JSON')
    if (!saJson) {
      console.warn('FCM_SERVICE_ACCOUNT_JSON no configurado — omitiendo push')
      return json({ sent: 0, skipped: true })
    }
    const sa: ServiceAccount = JSON.parse(saJson)

    // Obtener tokens del grupo (excluir al remitente si se indica)
    let query = adminClient
      .from('fcm_tokens')
      .select('token, user_id, platform')
      .eq('group_id', body.group_id)

    if (body.exclude_user_id) {
      query = query.neq('user_id', body.exclude_user_id)
    }

    const { data: tokens } = await query
    if (!tokens || tokens.length === 0) {
      return json({ sent: 0, message: 'No hay tokens para este grupo' })
    }

    // Obtener access token de Google
    const accessToken = await getFcmAccessToken(sa)

    // Enviar a cada token
    let sent = 0
    const results = await Promise.allSettled(
      (tokens as Array<{ token: string; user_id: string; platform: string }>).map((t) =>
        sendFcmMessage(accessToken, sa.project_id, t.token,
          body.title, body.body, body.data)
      )
    )
    for (const r of results) {
      if (r.status === 'fulfilled' && r.value) sent++
    }

    console.log(`✓ send-push: ${sent}/${tokens.length} enviados para group=${body.group_id}`)
    return json({ sent, total: tokens.length })
  } catch (err) {
    console.error('send-push error:', err)
    return json({ error: 'server_error', message: String(err) }, 500)
  }
})
