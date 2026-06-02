import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ── Fuentes de datos ──────────────────────────────────────────────────────────
//
// BCV (oficial): dolarapi.com — retorna tasa oficial BCV y paralela
//   GET https://ve.dolarapi.com/v1/dolares
//
// Fallback paralela: monitordolarvenezuela.com
//   GET https://monitordolarvenezuela.com/api/v1/dollar
//
// La tabla exchange_rates guarda ambas tasas para que el cliente
// elija cuál usar.

const cors = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface RateRow {
  id: string
  from_currency: string
  to_currency: string
  rate: number
  rate_type: string   // 'official' | 'parallel'
  source: string
  valid_at: string
  created_at: string
}

function rateId(type: string): string {
  // ID determinista por tipo + hora truncada a la hora
  // Evita duplicados si la función corre varias veces en la misma hora
  const hour = new Date().toISOString().slice(0, 13)
  return `${type}_VES_${hour}`
}

// ── Fetch dolarapi.com ────────────────────────────────────────────────────────

async function fetchDolarApi(): Promise<{ official: number | null; parallel: number | null }> {
  try {
    const res = await fetch('https://ve.dolarapi.com/v1/dolares', {
      signal: AbortSignal.timeout(8000),
    })
    if (!res.ok) return { official: null, parallel: null }

    const data = await res.json() as Array<{
      nombre: string; promedio: number; promedioBcv?: number
    }>

    // El array tiene objetos con nombre: 'Oficial', 'Paralelo', etc.
    const oficial  = data.find((d) => d.nombre?.toLowerCase().includes('oficial'))
    const paralelo = data.find((d) => d.nombre?.toLowerCase().includes('paralelo') ||
                                      d.nombre?.toLowerCase().includes('paralela'))

    return {
      official: oficial?.promedio ?? oficial?.promedioBcv ?? null,
      parallel: paralelo?.promedio ?? null,
    }
  } catch (e) {
    console.warn('dolarapi.com error:', e)
    return { official: null, parallel: null }
  }
}

// ── Fallback: monitordolarvenezuela.com ───────────────────────────────────────

async function fetchMonitorDolar(): Promise<number | null> {
  try {
    const res = await fetch(
      'https://monitordolarvenezuela.com/api/v1/dollar',
      { signal: AbortSignal.timeout(6000) },
    )
    if (!res.ok) return null
    const data = await res.json() as { price?: number; precio?: number }
    return data.price ?? data.precio ?? null
  } catch {
    return null
  }
}

// ── Handler ───────────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    const admin = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
      { auth: { autoRefreshToken: false, persistSession: false } },
    )

    const now = new Date().toISOString()
    const rows: Partial<RateRow>[] = []

    // ── Obtener tasas ────────────────────────────────────────────────────────
    const { official, parallel } = await fetchDolarApi()

    if (official !== null && official > 0) {
      rows.push({
        id: rateId('official'),
        from_currency: 'USD',
        to_currency: 'VES',
        rate: official,
        rate_type: 'official',
        source: 'dolarapi.com/bcv',
        valid_at: now,
        created_at: now,
      })
      console.log(`BCV oficial: 1 USD = ${official} VES`)
    }

    let parallelRate = parallel
    if (!parallelRate || parallelRate <= 0) {
      // Intentar con fallback
      parallelRate = await fetchMonitorDolar()
    }

    if (parallelRate !== null && parallelRate > 0) {
      rows.push({
        id: rateId('parallel'),
        from_currency: 'USD',
        to_currency: 'VES',
        rate: parallelRate,
        rate_type: 'parallel',
        source: parallel ? 'dolarapi.com' : 'monitordolarvenezuela.com',
        valid_at: now,
        created_at: now,
      })
      console.log(`Paralela: 1 USD = ${parallelRate} VES`)
    }

    if (rows.length === 0) {
      console.warn('No se pudo obtener ninguna tasa — abortando')
      return new Response(
        JSON.stringify({ error: 'no_rates_available' }),
        { status: 503, headers: { ...cors, 'Content-Type': 'application/json' } },
      )
    }

    // ── Guardar en Supabase ──────────────────────────────────────────────────
    const { error } = await admin
      .from('exchange_rates')
      .upsert(rows, { onConflict: 'id' })

    if (error) {
      console.error('Error guardando tasas:', error)
      return new Response(
        JSON.stringify({ error: error.message }),
        { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } },
      )
    }

    const result = {
      updated: rows.length,
      official: official ?? null,
      parallel: parallelRate ?? null,
      timestamp: now,
    }

    console.log(`✓ Tasas actualizadas:`, result)
    return new Response(JSON.stringify(result), {
      status: 200,
      headers: { ...cors, 'Content-Type': 'application/json' },
    })
  } catch (err) {
    console.error('update-exchange-rates error:', err)
    return new Response(
      JSON.stringify({ error: String(err) }),
      { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } },
    )
  }
})
