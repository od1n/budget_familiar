import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// ── Edge Function: verify-purchase ──────────────────────────────────────────
//
// Recibe el token de compra de Google Play, lo valida contra la API de
// Google Play Developer, y actualiza el plan del usuario en Supabase.
//
// En producción, debería validar el purchaseToken con la API de Google:
//   https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{packageName}/purchases/subscriptions/{subscriptionId}/tokens/{token}
//
// Para la fase actual (internal testing), confiamos en el token y actualizamos
// el perfil directamente. La validación completa se agrega cuando se publique.

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SUPABASE_SERVICE_ROLE_KEY =
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    const {
      user_id,
      product_id,
      purchase_token,
      plan_name,
      billing_cycle,
      source,
    } = await req.json();

    if (!user_id || !product_id || !purchase_token) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── TODO: Validar purchaseToken con Google Play Developer API ──────────
    //
    // Para validación real necesitas:
    // 1. Service account key de Google Cloud (JSON)
    // 2. Habilitar Google Play Android Developer API
    // 3. Vincular la service account en Play Console → API access
    //
    // const googleValidation = await fetch(
    //   `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/com.budgetfamiliar.app/purchases/subscriptionsv2/tokens/${purchase_token}`,
    //   { headers: { Authorization: `Bearer ${accessToken}` } }
    // );
    // const result = await googleValidation.json();
    // if (result.subscriptionState !== 'SUBSCRIPTION_STATE_ACTIVE') {
    //   return new Response(JSON.stringify({ error: 'Invalid purchase' }), { status: 403 });
    // }

    // ── Actualizar perfil en Supabase ─────────────────────────────────────

    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

    // Calcular expiración (1 mes o 1 año desde ahora)
    const now = new Date();
    const expiresAt =
      billing_cycle === "annual"
        ? new Date(now.setFullYear(now.getFullYear() + 1))
        : new Date(now.setMonth(now.getMonth() + 1));

    const { error } = await supabase
      .from("profiles")
      .update({
        plan_name: plan_name || "family",
        premium_plan: billing_cycle || "monthly",
        premium_expires_at: expiresAt.toISOString(),
        payment_source: source || "google_play",
        gplay_purchase_token: purchase_token,
        gplay_product_id: product_id,
      })
      .eq("id", user_id);

    if (error) {
      console.error("Error updating profile:", error);
      return new Response(
        JSON.stringify({ error: "Failed to update subscription" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(
      `Purchase verified: user=${user_id} plan=${plan_name} cycle=${billing_cycle} source=${source}`
    );

    return new Response(
      JSON.stringify({
        success: true,
        plan_name,
        billing_cycle,
        expires_at: expiresAt.toISOString(),
      }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (e) {
    console.error("verify-purchase error:", e);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { "Content-Type": "application/json" } }
    );
  }
});
