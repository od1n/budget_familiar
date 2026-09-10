import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Límites mensuales por feature (plan Pro) ──────────────────────────────────
const LIMITS: Record<string, number> = {
  ocr: 150,
  investment_recommendation: 50,
  voice_parse: 150,
};

// Modelo por defecto. Se puede sobrescribir con el secreto GEMINI_MODEL sin
// tocar el codigo, y ademas callGemini() se autorepara si Google lo descontinua.
const DEFAULT_MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-3.6-flash";
const GEMINI_BASE  = "https://generativelanguage.googleapis.com/v1beta/models";

// Llama a Gemini con autorreparacion: si el modelo fue descontinuado (404 con
// "use models/<nuevo>"), reintenta una vez con el modelo que Google sugiere.
async function callGemini(
  apiKey: string,
  body: unknown,
): Promise<{ ok: boolean; status: number; data?: any; error?: string; model: string }> {
  let model = DEFAULT_MODEL;
  for (let attempt = 0; attempt < 2; attempt++) {
    const res = await fetch(
      `${GEMINI_BASE}/${model}:generateContent?key=${apiKey}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      },
    );
    if (res.ok) {
      return { ok: true, status: res.status, data: await res.json(), model };
    }
    const errText = await res.text();
    // Google incluye en el mensaje el modelo actual y el sugerido; tomamos el
    // primero distinto al que acabamos de usar.
    let next: string | null = null;
    if (res.status === 404) {
      const matches = errText.match(/models\/([a-zA-Z0-9.\-]+)/g) ?? [];
      for (const m of matches) {
        const name = m.replace("models/", "");
        if (name !== model) { next = name; break; }
      }
    }
    if (next && attempt === 0) {
      console.warn(`Modelo ${model} descontinuado; reintentando con ${next}`);
      model = next;
      continue;
    }
    console.error("Gemini error:", res.status, errText);
    return { ok: false, status: res.status, error: errText, model };
  }
  return { ok: false, status: 500, error: "unreachable", model };
}

// ── Prompts del sistema ───────────────────────────────────────────────────────
const OCR_PROMPT = `Analiza esta imagen de un recibo o comprobante de pago.
Extrae la información y responde ÚNICAMENTE con un JSON válido con este formato exacto:
{
  "amount": "123.45",
  "description": "descripción del gasto",
  "date": "YYYY-MM-DD",
  "category_hint": "food|transport|health|entertainment|services|clothing|home|other",
  "currency": "USD|VES|EUR"
}
Si no puedes determinar un campo con certeza, usa null. No incluyas texto fuera del JSON.`;

const VOICE_PROMPT = (text: string, today: string) => `Analiza esta frase en espanol donde una persona describe un ingreso o un gasto de dinero.
Fecha de hoy: ${today}.
Frase: "${text}"

Responde UNICAMENTE con un JSON valido con este formato exacto:
{
  "amount": "123.45",
  "description": "descripcion corta",
  "date": "YYYY-MM-DD",
  "category_hint": "food|transport|health|entertainment|services|clothing|home|other",
  "currency": "USD|VES|EUR|MXN|ARS",
  "type": "expense|income"
}
Reglas:
- "type" es "income" si la persona recibio, cobro o gano dinero; "expense" si gasto, pago o compro. Por defecto "expense".
- Moneda: si menciona bolivares o "Bs" usa "VES"; dolares "USD"; euros "EUR"; pesos mexicanos "MXN"; pesos argentinos "ARS". Por defecto "USD".
- Si no menciona fecha, usa la fecha de hoy indicada arriba.
- Si no puedes determinar un campo, usa null. No incluyas texto fuera del JSON.`;

const INVESTMENT_PROMPT_TEMPLATE = (ctx: InvestmentContext) => `
Eres un asesor financiero personal especializado en el contexto venezolano.
Analiza los datos financieros del mes y proporciona recomendaciones prácticas.

DATOS DEL MES (${ctx.month}):
- Ingresos: ${ctx.income.toFixed(2)} ${ctx.currency}
- Gastos: ${ctx.expense.toFixed(2)} ${ctx.currency}
- Balance: ${ctx.balance.toFixed(2)} ${ctx.currency}
- Tasa de ahorro: ${ctx.income > 0 ? ((ctx.balance / ctx.income) * 100).toFixed(1) : 0}%

TOP CATEGORÍAS DE GASTO:
${ctx.top_categories.map(c => `- ${c.name}: ${c.amount.toFixed(2)} ${ctx.currency}`).join('\n')}

METAS DE AHORRO:
${ctx.savings_goals.length > 0
  ? ctx.savings_goals.map(g => `- ${g.name}: ${g.current.toFixed(2)}/${g.target.toFixed(2)} ${ctx.currency}`).join('\n')
  : '- Sin metas configuradas'}

Considera:
- La inflación en Venezuela y la dolarización del mercado
- La volatilidad del VES respecto al USD
- La importancia de mantener ahorros en divisas estables

Responde ÚNICAMENTE con un JSON válido con este formato exacto:
{
  "recommendations": [
    {
      "title": "título corto",
      "description": "descripción práctica de 1-2 oraciones",
      "priority": "high|medium|low",
      "category": "ahorro|gasto|inversión|deuda|divisa"
    }
  ]
}
Máximo 5 recomendaciones. No incluyas texto fuera del JSON.`;

// ── Tipos ─────────────────────────────────────────────────────────────────────
interface InvestmentContext {
  income: number;
  expense: number;
  balance: number;
  month: string;
  currency: string;
  top_categories: Array<{ name: string; amount: number }>;
  savings_goals: Array<{ name: string; current: number; target: number }>;
}

// ── Handler principal ─────────────────────────────────────────────────────────
serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  // ── Autenticación del usuario ───────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization") ?? "";
  const token = authHeader.replace("Bearer ", "");
  if (!token) {
    return new Response("Unauthorized", { status: 401 });
  }

  // Cliente con scope del usuario (respeta RLS)
  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } }
  );

  // Cliente admin para escribir en ai_usage_log (bypasea RLS)
  const adminClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  const { data: { user }, error: authError } = await userClient.auth.getUser(token);
  if (authError || !user) {
    return new Response("Unauthorized", { status: 401 });
  }

  // ── Parsear body ────────────────────────────────────────────────────────────
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const feature = body.feature as string;
  if (!["ocr", "investment_recommendation", "voice_parse"].includes(feature)) {
    return new Response("Invalid feature", { status: 400 });
  }

  const byokKey = body.byok_key as string | undefined;

  // ── Selección de API key ────────────────────────────────────────────────────
  let apiKey: string;

  if (byokKey) {
    // Usuario provee su propia key — sin verificar cuota
    apiKey = byokKey;
  } else {
    // Verificar plan premium
    const { data: profile } = await userClient
      .from("profiles")
      .select("is_premium, premium_expires_at")
      .eq("id", user.id)
      .single();

    const isPremium = profile?.is_premium === true;
    const notExpired = !profile?.premium_expires_at ||
      new Date(profile.premium_expires_at) > new Date();

    if (!isPremium || !notExpired) {
      return new Response(
        JSON.stringify({ error: "pro_required", message: "Esta función requiere plan Pro." }),
        { status: 403, headers: { "Content-Type": "application/json" } }
      );
    }

    // Verificar cuota mensual
    const limit = LIMITS[feature] ?? 0;
    const { data: usageData } = await userClient
      .rpc("get_ai_usage_this_month", { p_feature: feature });
    const used = (usageData as number) ?? 0;

    if (used >= limit) {
      return new Response(
        JSON.stringify({
          error: "quota_exceeded",
          message: `Límite mensual alcanzado (${used}/${limit}). Agrega tu propia API key en Configuración para continuar.`,
          used,
          limit,
        }),
        { status: 429, headers: { "Content-Type": "application/json" } }
      );
    }

    // Usar developer key
    const devKey = Deno.env.get("GEMINI_API_KEY");
    if (!devKey) {
      return new Response("Service unavailable", { status: 503 });
    }
    apiKey = devKey;
  }

  // ── Llamar Gemini según feature ─────────────────────────────────────────────
  let geminiBody: unknown;

  if (feature === "ocr") {
    const imageBase64 = body.image_base64 as string;
    const mimeType   = (body.mime_type as string) ?? "image/jpeg";
    if (!imageBase64) {
      return new Response("Missing image_base64", { status: 400 });
    }
    geminiBody = {
      contents: [{
        parts: [
          { text: OCR_PROMPT },
          { inline_data: { mime_type: mimeType, data: imageBase64 } },
        ],
      }],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 1024,
        responseMimeType: "application/json",
      },
    };
  } else if (feature === "voice_parse") {
    const text = (body.text as string ?? "").trim();
    if (!text) {
      return new Response("Missing text", { status: 400 });
    }
    const today = new Date().toISOString().slice(0, 10);
    geminiBody = {
      contents: [{ parts: [{ text: VOICE_PROMPT(text, today) }] }],
      generationConfig: {
        temperature: 0.1,
        maxOutputTokens: 1024,
        responseMimeType: "application/json",
      },
    };
  } else {
    // investment_recommendation
    const ctx = body.context as InvestmentContext;
    if (!ctx) {
      return new Response("Missing context", { status: 400 });
    }
    geminiBody = {
      contents: [{ parts: [{ text: INVESTMENT_PROMPT_TEMPLATE(ctx) }] }],
      generationConfig: {
        temperature: 0.4,
        maxOutputTokens: 2048,
        responseMimeType: "application/json",
      },
    };
  }

  const gem = await callGemini(apiKey, geminiBody);
  if (!gem.ok) {
    return new Response(
      JSON.stringify({ error: "gemini_error", message: "Error al llamar la IA." }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }
  const geminiData = gem.data;
  // Los modelos nuevos pueden partir la respuesta en varios "parts"
  // (incluido un bloque de razonamiento): unimos el texto de todos.
  const parts = geminiData?.candidates?.[0]?.content?.parts;
  const rawText: string = Array.isArray(parts)
    ? parts.map((p: { text?: string }) => p?.text ?? "").join("")
    : "";

  // Extraer JSON de la respuesta (puede venir con markdown)
  const jsonMatch = rawText.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    console.error("No JSON en respuesta Gemini:", rawText);
    return new Response(
      JSON.stringify({
        error: "parse_error",
        message: `Sin JSON [${gem.model}]: ${(rawText || "(vacío)").slice(0, 300)}`,
      }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }

  // Registrar uso (solo si usamos developer key, no BYOK)
  if (!byokKey) {
    const tokensUsed = geminiData?.usageMetadata?.totalTokenCount ?? 1;
    await adminClient.from("ai_usage_log").insert({
      user_id: user.id,
      feature,
      tokens_used: tokensUsed,
    });
  }

  return new Response(
    JSON.stringify({ result: JSON.parse(jsonMatch[0]) }),
    { status: 200, headers: { "Content-Type": "application/json" } }
  );
});
