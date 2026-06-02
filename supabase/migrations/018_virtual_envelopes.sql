-- ============================================================
-- Migración 018: Sobres virtuales (Virtual Envelopes)
-- Método de presupuesto donde cada "sobre" tiene un monto asignado
-- y se descuenta automáticamente al registrar gastos de esa categoría.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.virtual_envelopes (
  id               TEXT        PRIMARY KEY,
  group_id         TEXT        NOT NULL,
  category_id      TEXT        REFERENCES public.categories(id),
  name             TEXT        NOT NULL CHECK (char_length(name) BETWEEN 1 AND 100),
  allocated_amount REAL        NOT NULL CHECK (allocated_amount >= 0),
  spent_amount     REAL        NOT NULL DEFAULT 0,
  currency_code    CHAR(3)     NOT NULL DEFAULT 'USD',
  period_start     TIMESTAMPTZ NOT NULL,
  period_end       TIMESTAMPTZ NOT NULL,
  is_active        BOOLEAN     NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_envelopes_group_active
  ON public.virtual_envelopes (group_id, is_active)
  WHERE is_active = true;

ALTER TABLE public.virtual_envelopes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "envelopes: group members can select"
  ON public.virtual_envelopes FOR SELECT TO authenticated
  USING (group_id IN (SELECT public.user_group_ids_text()));

CREATE POLICY "envelopes: group members can insert"
  ON public.virtual_envelopes FOR INSERT TO authenticated
  WITH CHECK (group_id IN (SELECT public.user_group_ids_text()));

CREATE POLICY "envelopes: group members can update"
  ON public.virtual_envelopes FOR UPDATE TO authenticated
  USING (group_id IN (SELECT public.user_group_ids_text()));

CREATE POLICY "envelopes: group members can delete"
  ON public.virtual_envelopes FOR DELETE TO authenticated
  USING (group_id IN (SELECT public.user_group_ids_text()));
