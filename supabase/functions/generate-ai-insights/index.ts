import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
}

const json = (body: object, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })

// ── Helpers de fecha ──────────────────────────────────────────────────────────

function monthStart(year: number, month: number): string {
  return new Date(year, month - 1, 1).toISOString()
}

function monthEnd(year: number, month: number): string {
  return new Date(year, month, 0, 23, 59, 59).toISOString()
}

function monthName(year: number, month: number): string {
  return new Date(year, month - 1, 1)
    .toLocaleDateString('es', { month: 'long', year: 'numeric' })
}

// ── Noticias GDELT (fuente gratuita, sin API key) ─────────────────────────────

async function fetchNews(): Promise<Array<{ title: string; url: string; source: string }>> {
  try {
    const url =
      'https://api.gdeltproject.org/api/v2/doc/doc' +
      '?query=Venezuela%20economia%20dolar%20inflacion' +
      '&mode=artlist&maxrecords=5&format=json&sort=DateDesc&sourcelang=Spanish'
    const res = await fetch(url, { signal: AbortSignal.timeout(4000) })
    if (!res.ok) return []
    const data = await res.json()
    return ((data as Record<string, unknown>).articles as Array<Record<string, string>> ?? [])
      .slice(0, 3)
      .map((a) => ({ title: a.title ?? '', url: a.url ?? '', source: a.domain ?? '' }))
  } catch {
    return [] // no bloquear si GDELT falla
  }
}

// ── Tasas VES (fuente directa, no depende de que la tabla esté poblada) ───────
async function fetchVesRates(): Promise<{ bcv: number | null; parallel: number | null }> {
  try {
    const res = await fetch('https://ve.dolarapi.com/v1/dolares', {
      signal: AbortSignal.timeout(4000),
    })
    if (!res.ok) return { bcv: null, parallel: null }
    const data = (await res.json()) as Array<{ fuente?: string; promedio?: number }>
    // Discriminar por `fuente` ('oficial' | 'paralelo'); el oficial trae nombre "Dólar".
    const bcv = data.find((d) => d.fuente === 'oficial')?.promedio ?? null
    const parallel = data.find((d) => d.fuente === 'paralelo')?.promedio ?? null
    return { bcv, parallel }
  } catch {
    return { bcv: null, parallel: null } // no bloquear si la API falla
  }
}

// ── Handler ───────────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    // ── Autenticación ──────────────────────────────────────────────────────────
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

    const { data: { user }, error: authErr } = await userClient.auth.getUser()
    if (authErr || !user) return json({ error: 'invalid_session' }, 401)

    // ── Verificar plan premium ─────────────────────────────────────────────────
    const { data: profile } = await adminClient
      .from('profiles')
      .select('plan_name')
      .eq('id', user.id)
      .single()

    if (!['premium', 'beta'].includes(profile?.plan_name ?? '')) {
      return json({ error: 'premium_required' }, 403)
    }

    // ── Obtener group_id del cuerpo ────────────────────────────────────────────
    const body = await req.json().catch(() => ({}))
    const groupId = (body as Record<string, string>).group_id
    if (!groupId) return json({ error: 'missing_group_id' }, 400)

    // Verificar membresía
    const { data: member } = await adminClient
      .from('group_members')
      .select('user_id')
      .eq('group_id', groupId)
      .eq('user_id', user.id)
      .maybeSingle()
    if (!member) return json({ error: 'not_a_member' }, 403)

    // ── Verificar caché (TTL 7 días) ───────────────────────────────────────────
    const { data: cached } = await adminClient
      .from('ai_insights')
      .select('*')
      .eq('group_id', groupId)
      .gt('expires_at', new Date().toISOString())
      .order('generated_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (cached) {
      console.log(`Insight cacheado para group=${groupId}`)
      return json({ insight: cached, cached: true })
    }

    // ── Recopilar contexto financiero ──────────────────────────────────────────
    const now = new Date()
    const cy = now.getFullYear()
    const cm = now.getMonth() + 1

    // Meses a analizar: mes actual + 2 anteriores
    const months: Array<{ year: number; month: number }> = []
    for (let i = 0; i < 3; i++) {
      const d = new Date(cy, cm - 1 - i, 1)
      months.push({ year: d.getFullYear(), month: d.getMonth() + 1 })
    }

    // Transacciones de los últimos 3 meses
    const { data: txRaw } = await adminClient
      .from('transactions')
      .select('amount, currency_code, type, date, category_id')
      .eq('group_id', groupId)
      .gte('date', monthStart(months[2].year, months[2].month))
      .lte('date', monthEnd(cy, cm))

    const transactions = (txRaw ?? []) as Array<{
      amount: number; currency_code: string; type: string
      date: string; category_id: string | null
    }>

    // Agrupar por mes
    function summarizeMonth(y: number, m: number) {
      const start = monthStart(y, m); const end = monthEnd(y, m)
      const monthTx = transactions.filter((t) => t.date >= start && t.date <= end)
      const income  = monthTx.filter((t) => t.type === 'income')
        .reduce((s, t) => s + t.amount, 0)
      const expense = monthTx.filter((t) => t.type === 'expense')
        .reduce((s, t) => s + t.amount, 0)
      const byCat: Record<string, number> = {}
      for (const t of monthTx.filter((t) => t.type === 'expense')) {
        const k = t.category_id ?? 'other'
        byCat[k] = (byCat[k] ?? 0) + t.amount
      }
      return { year: y, month: m, label: monthName(y, m), income, expense, balance: income - expense, byCat }
    }

    const [curr, prev1, prev2] = months.map((m) => summarizeMonth(m.year, m.month))
    const avgIncome  = (prev1.income  + prev2.income)  / 2
    const avgExpense = (prev1.expense + prev2.expense) / 2

    // Categorías
    const { data: catsRaw } = await adminClient
      .from('categories')
      .select('id, name')
      .or(`group_id.eq.${groupId},is_system.eq.true`)
    const catMap: Record<string, string> = {}
    for (const c of catsRaw ?? []) catMap[(c as { id: string; name: string }).id] = (c as { id: string; name: string }).name

    const topExpCategories = Object.entries(curr.byCat)
      .map(([id, amount]) => ({ name: catMap[id] ?? 'Otros', amount,
        avg: ((prev1.byCat[id] ?? 0) + (prev2.byCat[id] ?? 0)) / 2 }))
      .sort((a, b) => b.amount - a.amount)
      .slice(0, 5)

    // Presupuestos del mes actual
    const { data: budgetsRaw } = await adminClient
      .from('budgets')
      .select('category_id, monthly_limit, currency_code')
      .eq('group_id', groupId)
    const budgets = (budgetsRaw ?? []) as Array<{ category_id: string; monthly_limit: number; currency_code: string }>

    // Metas de ahorro
    const { data: goalsRaw } = await adminClient
      .from('savings_goals')
      .select('name, target_amount, current_amount, currency_code, target_date')
      .eq('group_id', groupId)
    const goals = (goalsRaw ?? []) as Array<{ name: string; target_amount: number; current_amount: number; currency_code: string; target_date: string | null }>

    // Inversiones activas
    const { data: invRaw } = await adminClient
      .from('investments')
      .select('name, type, initial_amount, current_value, currency_code')
      .eq('group_id', groupId)
      .eq('is_active', true)
    const investments = (invRaw ?? []) as Array<{ name: string; type: string; initial_amount: number; current_value: number | null; currency_code: string }>

    // Tasas de cambio: en vivo desde la API pública; la tabla exchange_rates
    // queda solo como respaldo (hoy no la puebla nada).
    const live = await fetchVesRates()
    let bcvRate = live.bcv
    let parallelRate = live.parallel
    if (bcvRate === null || parallelRate === null) {
      const { data: ratesRaw } = await adminClient
        .from('exchange_rates')
        .select('from_currency, to_currency, rate, rate_type, valid_at')
        .order('valid_at', { ascending: false })
        .limit(10)
      const rates = (ratesRaw ?? []) as Array<{ from_currency: string; to_currency: string; rate: number; rate_type: string; valid_at: string }>
      bcvRate ??= rates.find((r) => r.from_currency === 'USD' && r.to_currency === 'VES' && r.rate_type === 'official')?.rate ?? null
      parallelRate ??= rates.find((r) => r.from_currency === 'USD' && r.to_currency === 'VES' && r.rate_type === 'parallel')?.rate ?? null
    }

    // Noticias (GDELT, opcional)
    const news = await fetchNews()

    // ── Construir prompt ───────────────────────────────────────────────────────
    const savingsRate = curr.income > 0
      ? ((curr.balance / curr.income) * 100).toFixed(1)
      : '0.0'
    const incomeChange = avgIncome > 0
      ? (((curr.income - avgIncome) / avgIncome) * 100).toFixed(1)
      : null
    const expenseChange = avgExpense > 0
      ? (((curr.expense - avgExpense) / avgExpense) * 100).toFixed(1)
      : null

    const catLines = topExpCategories.map((c) => {
      const delta = c.avg > 0 ? (((c.amount - c.avg) / c.avg) * 100).toFixed(0) : null
      const budget = budgets.find((b) => catMap[b.category_id] === c.name)
      const budgetLine = budget
        ? `  Presupuesto: ${budget.monthly_limit} ${budget.currency_code} — Consumido: ${budget.monthly_limit > 0 ? ((c.amount / budget.monthly_limit) * 100).toFixed(0) : '?'}%`
        : ''
      return `- ${c.name}: ${c.amount.toFixed(2)} USD${delta ? ` (${Number(delta) >= 0 ? '+' : ''}${delta}% vs promedio)` : ''}${budgetLine}`
    }).join('\n')

    const goalLines = goals.map((g) => {
      const pct = g.target_amount > 0
        ? ((g.current_amount / g.target_amount) * 100).toFixed(0)
        : '0'
      return `- "${g.name}": ${g.current_amount.toFixed(2)}/${g.target_amount.toFixed(2)} ${g.currency_code} (${pct}%)${g.target_date ? ` — vence ${new Date(g.target_date).toLocaleDateString('es')}` : ''}`
    }).join('\n')

    const invLines = investments.length > 0
      ? investments.map((i) => {
          const val = i.current_value ?? i.initial_amount
          const pnl = ((val - i.initial_amount) / i.initial_amount * 100).toFixed(1)
          return `- ${i.name} (${i.type}): ${i.initial_amount.toFixed(2)} → ${val.toFixed(2)} ${i.currency_code} (${Number(pnl) >= 0 ? '+' : ''}${pnl}%)`
        }).join('\n')
      : '(sin inversiones registradas)'

    const newsLines = news.length > 0
      ? news.map((n) => `  - [${n.source}] ${n.title}`).join('\n')
      : '  (sin noticias disponibles)'

    const prompt = `Eres un asistente de presupuesto personal para familias en economías latinoamericanas, particularmente Venezuela. Ayudas a organizar gastos, ingresos y metas de ahorro. Analiza los datos y genera recomendaciones concretas, empáticas y accionables en español neutro sobre el manejo del presupuesto. No brindas asesoría de inversión ni recomiendas comprar, vender o mantener activos financieros.

CONTEXTO MACROECONÓMICO (Venezuela, ${new Date().toLocaleDateString('es')}):
${bcvRate ? `- Tasa oficial (BCV): 1 USD = ${bcvRate.toFixed(2)} VES` : '- Tasa oficial: no disponible'}
${parallelRate ? `- Tasa paralela: 1 USD = ${parallelRate.toFixed(2)} VES` : '- Tasa paralela: no disponible'}
- Noticias recientes:
${newsLines}

ESTADO FINANCIERO — ${curr.label}:
- Ingreso: ${curr.income.toFixed(2)} USD${incomeChange ? ` (${Number(incomeChange) >= 0 ? '+' : ''}${incomeChange}% vs promedio)` : ''}
- Gasto: ${curr.expense.toFixed(2)} USD${expenseChange ? ` (${Number(expenseChange) >= 0 ? '+' : ''}${expenseChange}% vs promedio)` : ''}
- Balance: ${curr.balance.toFixed(2)} USD
- Ratio ahorro/ingreso: ${savingsRate}%

DESGLOSE POR CATEGORÍA:
${catLines || '(sin datos de categorías)'}

METAS DE AHORRO:
${goalLines || '(sin metas activas)'}

Genera máximo 4 recomendaciones priorizadas. Devuelve SOLO JSON válido con esta estructura exacta, sin texto adicional:
{
  "recommendations": [
    {
      "type": "spending_alert|savings_tip|budget_tip|macro_context",
      "priority": "high|medium|low",
      "category": "string",
      "title": "string corto",
      "message": "explicación clara en 1-2 oraciones",
      "action": "acción concreta en 1 oración"
    }
  ],
  "macro_context_summary": "1 párrafo sobre el contexto económico y cómo afecta a esta familia",
  "overall_health_score": 0-100
}`

    // ── Llamar a Gemini ────────────────────────────────────────────────────────
    const geminiKey = Deno.env.get('GEMINI_API_KEY')
    if (!geminiKey) return json({ error: 'gemini_not_configured' }, 500)

    // Modelo por defecto (sobrescribible con el secreto GEMINI_MODEL) con
    // autorreparacion: si Google lo descontinua, reintenta con el sugerido.
    const DEFAULT_MODEL = Deno.env.get('GEMINI_MODEL') ?? 'gemini-3.6-flash'
    const geminiBase = 'https://generativelanguage.googleapis.com/v1beta/models'
    const genBody = {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: {
        temperature: 0.3,
        maxOutputTokens: 2048,
        responseMimeType: 'application/json',
      },
    }

    let usedModel = DEFAULT_MODEL
    // deno-lint-ignore no-explicit-any
    let geminiData: any = null
    for (let attempt = 0; attempt < 2; attempt++) {
      const geminiRes = await fetch(
        `${geminiBase}/${usedModel}:generateContent?key=${geminiKey}`,
        {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(genBody),
        },
      )
      if (geminiRes.ok) {
        geminiData = await geminiRes.json()
        break
      }
      const err = await geminiRes.text()
      let next: string | null = null
      if (geminiRes.status === 404) {
        const matches = err.match(/models\/([a-zA-Z0-9.\-]+)/g) ?? []
        for (const m of matches) {
          const name = m.replace('models/', '')
          if (name !== usedModel) { next = name; break }
        }
      }
      if (next && attempt === 0) {
        console.warn(`Modelo ${usedModel} descontinuado; reintentando con ${next}`)
        usedModel = next
        continue
      }
      console.error('Gemini error:', geminiRes.status, err)
      return json({ error: 'ai_error', detail: err }, 500)
    }
    if (!geminiData) return json({ error: 'ai_error' }, 500)

    const parts = geminiData?.candidates?.[0]?.content?.parts
    const rawText: string = Array.isArray(parts)
      ? parts.map((p: { text?: string }) => p?.text ?? '').join('')
      : ''
    const tokensUsed: number =
      (geminiData?.usageMetadata?.promptTokenCount ?? 0) +
      (geminiData?.usageMetadata?.candidatesTokenCount ?? 0)

    // Limpiar y parsear JSON
    const cleanedText = rawText
      .replace(/```json\s*/g, '')
      .replace(/```\s*/g, '')
      .trim()

    let parsed: { recommendations: unknown[]; macro_context_summary: string; overall_health_score: number }
    try {
      parsed = JSON.parse(cleanedText)
    } catch {
      console.error('JSON parse error, raw:', cleanedText.slice(0, 200))
      return json({ error: 'invalid_ai_response' }, 500)
    }

    // ── Guardar en ai_insights ─────────────────────────────────────────────────
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString()
    const insightRow = {
      group_id: groupId,
      expires_at: expiresAt,
      recommendations: parsed.recommendations ?? [],
      macro_context: parsed.macro_context_summary ?? null,
      overall_health_score: parsed.overall_health_score ?? null,
      news_sources: news.length > 0 ? news : null,
      model_used: usedModel,
      tokens_used: tokensUsed,
      context_snapshot: {
        current_month: curr,
        prev_months: [prev1, prev2],
        bcv_rate: bcvRate,
        parallel_rate: parallelRate,
      },
    }

    const { data: savedInsight, error: saveErr } = await adminClient
      .from('ai_insights')
      .insert(insightRow)
      .select()
      .single()

    if (saveErr) {
      console.error('Error guardando insight:', saveErr)
      // Aun así retornar el resultado aunque no se haya persistido
      return json({ insight: { ...insightRow, id: null }, cached: false })
    }

    console.log(`✓ Insight generado para group=${groupId}, score=${parsed.overall_health_score}`)
    return json({ insight: savedInsight, cached: false })
  } catch (err) {
    console.error('generate-ai-insights error:', err)
    return json({ error: 'server_error', message: String(err) }, 500)
  }
})
