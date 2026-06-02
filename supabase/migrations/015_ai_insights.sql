-- ============================================================
-- Migración 015: Tabla ai_insights (insights IA persistentes)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.ai_insights (
  id                   UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id             TEXT        NOT NULL,
  generated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at           TIMESTAMPTZ NOT NULL,
  recommendations      JSONB       NOT NULL DEFAULT '[]',
  macro_context        TEXT,
  overall_health_score INTEGER     CHECK (overall_health_score BETWEEN 0 AND 100),
  context_snapshot     JSONB,
  news_sources         JSONB,
  model_used           TEXT,
  tokens_used          INTEGER,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_insights_group_expires
  ON public.ai_insights (group_id, expires_at DESC);

ALTER TABLE public.ai_insights ENABLE ROW LEVEL SECURITY;

-- Solo los miembros del grupo pueden leer sus insights
CREATE POLICY "insights: group members can select"
  ON public.ai_insights FOR SELECT TO authenticated
  USING (group_id IN (SELECT public.user_group_ids_text()));

-- Solo service_role puede insertar (la Edge Function)
