import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { timingSafeEqual } from "https://deno.land/std@0.168.0/crypto/timing_safe_equal.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SIGNING_SECRET = Deno.env.get("LEMON_SIGNING_SECRET") ?? "";

// ── Verificar firma HMAC-SHA256 de LemonSqueezy ───────────────────────────────

async function verifySignature(
  body: string,
  signature: string
): Promise<boolean> {
  if (!SIGNING_SECRET || !signature) return false;
  try {
    const key = await crypto.subtle.importKey(
      "raw",
      new TextEncoder().encode(SIGNING_SECRET),
      { name: "HMAC", hash: "SHA-256" },
      false,
      ["sign"]
    );
    const signed = await crypto.subtle.sign(
      "HMAC",
      key,
      new TextEncoder().encode(body)
    );
    const expected = Array.from(new Uint8Array(signed))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    const expectedBytes = new TextEncoder().encode(expected);
    const actualBytes = new TextEncoder().encode(signature);
    if (expectedBytes.length !== actualBytes.length) return false;
    return timingSafeEqual(expectedBytes, actualBytes);
  } catch {
    return false;
  }
}

// ── Detectar plan a partir del nombre de variante ─────────────────────────────
// El nombre de la variante en LemonSqueezy debe contener 'premium' para el plan
// Premium. Cualquier otra variante se asigna al plan 'family'.
// Ejemplo: "Premium Mensual", "Premium Monthly" → plan 'premium'
//          "Familiar Mensual", "Monthly", "Family" → plan 'family'

function detectPlan(variantName: string): "family" | "premium" {
  const lower = variantName.toLowerCase();
  if (lower.includes("premium")) return "premium";
  return "family";
}

function detectBillingCycle(variantName: string): "monthly" | "annual" {
  const lower = variantName.toLowerCase();
  if (
    lower.includes("anual") ||
    lower.includes("annual") ||
    lower.includes("year")
  ) {
    return "annual";
  }
  return "monthly";
}

// ── Handler principal ─────────────────────────────────────────────────────────

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const body = await req.text();
  const signature = req.headers.get("x-signature") ?? "";

  const valid = await verifySignature(body, signature);
  if (!valid) {
    console.error("Firma inválida");
    return new Response("Unauthorized", { status: 401 });
  }

  let event: Record<string, unknown>;
  try {
    event = JSON.parse(body);
  } catch {
    return new Response("Invalid JSON", { status: 400 });
  }

  const eventName = (event.meta as Record<string, unknown>)
    ?.event_name as string;

  console.log("Evento recibido:", eventName);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // ── Idempotencia ──────────────────────────────────────────────────────────
  const eventId = (event.meta as Record<string, unknown>)?.event_id as string;
  if (eventId) {
    const { error: idempErr } = await supabase
      .from("processed_webhook_events")
      .insert({ event_id: eventId });
    if (idempErr?.code === "23505") {
      console.log("Evento ya procesado:", eventId);
      return new Response("Already processed", { status: 200 });
    }
  }

  // ── Activar plan ──────────────────────────────────────────────────────────
  if (
    eventName === "order_created" ||
    eventName === "subscription_created" ||
    eventName === "subscription_resumed" ||
    eventName === "subscription_unpaused"
  ) {
    const userId = (
      (event.meta as Record<string, unknown>)
        ?.custom_data as Record<string, unknown>
    )?.user_id as string;

    if (!userId) {
      console.error("user_id ausente en custom_data");
      return new Response("Missing user_id", { status: 400 });
    }

    const attrs = (event.data as Record<string, unknown>)
      ?.attributes as Record<string, unknown>;

    const variantName =
      (
        (attrs?.first_order_item as Record<string, unknown>)
          ?.variant_name as string
      ) ??
      (attrs?.variant_name as string) ??
      "";

    const planName  = detectPlan(variantName);
    const billing   = detectBillingCycle(variantName);
    const months    = billing === "annual" ? 12 : 1;
    const expiresAt = new Date();
    expiresAt.setMonth(expiresAt.getMonth() + months);

    // Usar la nueva RPC set_user_plan (actualiza plan_name + is_premium + max_members)
    const { error } = await supabase.rpc("set_user_plan", {
      p_user_id:   userId,
      p_plan_name: planName,
      p_billing:   billing,
      p_expires:   expiresAt.toISOString(),
    });

    if (error) {
      console.error("Error activando plan:", error);
      return new Response("DB error", { status: 500 });
    }

    console.log(
      `✓ Plan activado: ${userId} → ${planName} (${billing}) hasta ${expiresAt.toISOString()}`
    );
    return new Response("OK", { status: 200 });
  }

  // ── Revocar plan ──────────────────────────────────────────────────────────
  if (
    eventName === "subscription_cancelled" ||
    eventName === "subscription_expired" ||
    eventName === "subscription_paused"
  ) {
    const userId = (
      (event.meta as Record<string, unknown>)
        ?.custom_data as Record<string, unknown>
    )?.user_id as string;

    if (!userId) {
      return new Response("Missing user_id", { status: 400 });
    }

    const { error } = await supabase.rpc("revoke_user_premium", {
      p_user_id: userId,
    });

    if (error) {
      console.error("Error revocando plan:", error);
      return new Response("DB error", { status: 500 });
    }

    console.log(`✓ Plan revocado: ${userId}`);
    return new Response("OK", { status: 200 });
  }

  return new Response("Ignored", { status: 200 });
});
