-- ============================================================
-- Migración 014: Tabla de inversiones
-- ============================================================

CREATE TABLE IF NOT EXISTS public.investments (
  id             TEXT        PRIMARY KEY,
  group_id       TEXT        NOT NULL,
  user_id        UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name           TEXT        NOT NULL CHECK (char_length(name) BETWEEN 1 AND 100),
  type           TEXT        NOT NULL DEFAULT 'other'
                   CHECK (type IN ('fixed_term','fund','stock','crypto','real_estate','other')),
  initial_amount REAL        NOT NULL CHECK (initial_amount >= 0),
  current_value  REAL,
  currency_code  CHAR(3)     NOT NULL DEFAULT 'USD',
  start_date     TIMESTAMPTZ,
  maturity_date  TIMESTAMPTZ,
  institution    TEXT,
  notes          TEXT,
  is_active      BOOLEAN     NOT NULL DEFAULT true,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_investments_group_id
  ON public.investments (group_id);

CREATE INDEX IF NOT EXISTS idx_investments_active
  ON public.investments (group_id, is_active)
  WHERE is_active = true;

ALTER TABLE public.investments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "investments: group members can select"
  ON public.investments FOR SELECT TO authenticated
  USING (group_id IN (SELECT public.user_group_ids_text()));

CREATE POLICY "investments: group members can insert"
  ON public.investments FOR INSERT TO authenticated
  WITH CHECK (
    group_id IN (SELECT public.user_group_ids_text())
    AND user_id = auth.uid()
  );

CREATE POLICY "investments: owner or group member can update"
  ON public.investments FOR UPDATE TO authenticated
  USING (group_id IN (SELECT public.user_group_ids_text()));

CREATE POLICY "investments: owner or group member can delete"
  ON public.investments FOR DELETE TO authenticated
  USING (group_id IN (SELECT public.user_group_ids_text()));
