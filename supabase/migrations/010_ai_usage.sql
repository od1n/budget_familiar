-- ============================================================
-- Migración 010 — Cuotas de uso de IA por usuario
-- ============================================================

-- 1. Tabla de registro de uso
CREATE TABLE IF NOT EXISTS public.ai_usage_log (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  feature     text        NOT NULL CHECK (feature IN ('ocr', 'investment_recommendation')),
  tokens_used integer     NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_user_feature_month
  ON public.ai_usage_log (user_id, feature, created_at);

-- 2. RLS — el usuario solo puede leer su propio uso (no escribir: solo el proxy escribe)
ALTER TABLE public.ai_usage_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_usage_select_own" ON public.ai_usage_log
  FOR SELECT USING (auth.uid() = user_id);
-- INSERT solo permitido via service_role (Edge Function con SUPABASE_SERVICE_ROLE_KEY)

-- 3. Función RPC para leer cuota del mes actual (segura para el cliente)
CREATE OR REPLACE FUNCTION public.get_ai_usage_this_month(p_feature text)
RETURNS integer
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(COUNT(*)::integer, 0)
  FROM public.ai_usage_log
  WHERE user_id  = auth.uid()
    AND feature  = p_feature
    AND created_at >= date_trunc('month', now());
$$;

REVOKE ALL ON FUNCTION public.get_ai_usage_this_month(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_ai_usage_this_month(text) TO authenticated;

-- 4. Límites por plan (referencia — se aplican en la Edge Function)
-- Plan gratuito : 0 llamadas proxy (deben usar BYOK)
-- Plan Pro      : ocr = 150/mes, investment_recommendation = 50/mes
