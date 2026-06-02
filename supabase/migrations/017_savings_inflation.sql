-- ============================================================
-- Migración 017: Ajuste por inflación en metas de ahorro
-- ============================================================

-- Una tasa mensual nula = ajuste desactivado para esa meta.
ALTER TABLE public.savings_goals
  ADD COLUMN IF NOT EXISTS inflation_rate_monthly REAL;

COMMENT ON COLUMN public.savings_goals.inflation_rate_monthly IS
  'Tasa de inflación mensual en % (ej. 4.5 = 4.5%). NULL = ajuste desactivado.';
