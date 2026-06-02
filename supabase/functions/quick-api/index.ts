import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Límites mensuales por feature (plan Pro) ──────────────────────────────────
const LIMITS: Record<string, number> = {
  ocr: 150,
  investment_recommendation: 50,
};

const GEMINI_MODEL = "gemini-1.5-flash";
const GEMINI_BASE  = "https://generativelanguage.googleapis.com/v1beta/models";

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
  if (!["ocr", "investment_recommendation"].includes(feature)) {
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
      generationConfig: { temperature: 0.1, maxOutputTokens: 256 },
    };
  } else {
    // investment_recommendation
    const ctx = body.context as InvestmentContext;
    if (!ctx) {
      return new Response("Missing context", { status: 400 });
    }
    geminiBody = {
      contents: [{ parts: [{ text: INVESTMENT_PROMPT_TEMPLATE(ctx) }] }],
      generationConfig: { temperature: 0.4, maxOutputTokens: 1024 },
    };
  }

  const geminiRes = await fetch(
    `${GEMINI_BASE}/${GEMINI_MODEL}:generateContent?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(geminiBody),
    }
  );

  if (!geminiRes.ok) {
    const errText = await geminiRes.text();
    console.error("Gemini error:", errText);
    return new Response(
      JSON.stringify({ error: "gemini_error", message: "Error al llamar la IA." }),
      { status: 502, headers: { "Content-Type": "application/json" } }
    );
  }

  const geminiData = await geminiRes.json();
  const rawText: string =
    geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

  // Extraer JSON de la respuesta (puede venir con markdown)
  const jsonMatch = rawText.match(/\{[\s\S]*\}/);
  if (!jsonMatch) {
    console.error("No JSON en respuesta Gemini:", rawText);
    return new Response(
      JSON.stringify({ error: "parse_error", message: "Respuesta IA inválida." }),
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
