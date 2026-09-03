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

// ── Validación de compra contra Google Play (gated por secreto) ─────────────
// Si GOOGLE_PLAY_SA_JSON no está configurado, se OMITE la validación (como hoy).
// Configurado, valida el token real contra la Play Developer API.
const PACKAGE_NAME = "com.budgetfamiliar.app";

function b64url(bytes: Uint8Array): string {
  let s = "";
  for (const b of bytes) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function importPk(pem: string): Promise<CryptoKey> {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s+/g, "");
  const der = Uint8Array.from(atob(body), (c) => c.charCodeAt(0));
  return crypto.subtle.importKey(
    "pkcs8",
    der.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
}

async function googleAccessToken(saJson: string): Promise<string> {
  const sa = JSON.parse(saJson);
  const now = Math.floor(Date.now() / 1000);
  const enc = new TextEncoder();
  const header = b64url(
    enc.encode(JSON.stringify({ alg: "RS256", typ: "JWT" })),
  );
  const claim = b64url(
    enc.encode(JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/androidpublisher",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    })),
  );
  const unsigned = `${header}.${claim}`;
  const key = await importPk(sa.private_key);
  const sig = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    key,
    enc.encode(unsigned),
  );
  const jwt = `${unsigned}.${b64url(new Uint8Array(sig))}`;
  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const data = await res.json();
  if (!data.access_token) throw new Error("no_access_token");
  return data.access_token as string;
}

async function validatePlayPurchase(
  token: string,
): Promise<{ ok: boolean; reason?: string }> {
  const saJson = Deno.env.get("GOOGLE_PLAY_SA_JSON");
  if (!saJson) return { ok: true, reason: "skipped_no_sa" }; // gated
  try {
    const accessToken = await googleAccessToken(saJson);
    const res = await fetch(
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE_NAME}/purchases/subscriptionsv2/tokens/${token}`,
      { headers: { Authorization: `Bearer ${accessToken}` } },
    );
    if (!res.ok) return { ok: false, reason: `play_api_${res.status}` };
    const data = await res.json();
    const state = data.subscriptionState;
    const ok = state === "SUBSCRIPTION_STATE_ACTIVE" ||
      state === "SUBSCRIPTION_STATE_IN_GRACE_PERIOD";
    return ok ? { ok: true } : { ok: false, reason: state ?? "unknown" };
  } catch (e) {
    return { ok: false, reason: String(e) };
  }
}

serve(async (req) => {
  try {
    if (req.method !== "POST") {
      return new Response("Method not allowed", { status: 405 });
    }

    // ── Autenticación: el user_id sale del JWT, NUNCA del body ─────────────
    // Sin esto, cualquiera podía POSTear {user_id, plan_name:"premium"} y
    // regalarse un plan de pago. functions.invoke ya envía el JWT del usuario.
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "no_auth" }), {
        status: 401, headers: { "Content-Type": "application/json" },
      });
    }
    const userClient = createClient(
      SUPABASE_URL,
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );
    const { data: { user: authUser }, error: authErr } =
      await userClient.auth.getUser();
    if (authErr || !authUser) {
      return new Response(JSON.stringify({ error: "invalid_session" }), {
        status: 401, headers: { "Content-Type": "application/json" },
      });
    }
    const authUserId = authUser.id;

    const {
      product_id,
      purchase_token,
      plan_name,
      billing_cycle,
      source,
    } = await req.json();

    if (!product_id || !purchase_token) {
      return new Response(
        JSON.stringify({ error: "Missing required fields" }),
        { status: 400, headers: { "Content-Type": "application/json" } }
      );
    }

    // ── Validar la compra contra Google Play (si el secreto está configurado)
    const check = await validatePlayPurchase(purchase_token);
    if (!check.ok) {
      console.warn("Compra inválida:", check.reason);
      return new Response(
        JSON.stringify({ error: "invalid_purchase", reason: check.reason }),
        { status: 403, headers: { "Content-Type": "application/json" } },
      );
    }

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
      .eq("id", authUserId);

    if (error) {
      console.error("Error updating profile:", error);
      return new Response(
        JSON.stringify({ error: "Failed to update subscription" }),
        { status: 500, headers: { "Content-Type": "application/json" } }
      );
    }

    console.log(
      `Purchase verified: user=${authUserId} plan=${plan_name} cycle=${billing_cycle} source=${source}`
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
