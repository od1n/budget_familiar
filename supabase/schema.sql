-- =============================================================================
-- Budget Familiar — Schema Supabase
-- Ejecutar en: Supabase Dashboard → SQL Editor → New query
-- =============================================================================

-- ── Tablas ────────────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.categories (
  id          TEXT PRIMARY KEY,
  group_id    TEXT,
  name        TEXT        NOT NULL CHECK (length(name) BETWEEN 1 AND 100),
  icon_code   TEXT        NOT NULL,
  color_hex   TEXT        NOT NULL CHECK (length(color_hex) = 7),
  type        TEXT        NOT NULL CHECK (type IN ('expense','income','both')),
  is_system   BOOLEAN     NOT NULL DEFAULT false,
  sort_order  INTEGER     NOT NULL DEFAULT 0,
  is_active   BOOLEAN     NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.transactions (
  id                    TEXT        PRIMARY KEY,
  group_id              TEXT        NOT NULL,
  user_id               UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id           TEXT        REFERENCES public.categories(id),
  amount                REAL        NOT NULL,
  currency_code         CHAR(3)     NOT NULL,
  amount_usd_equivalent REAL,
  exchange_rate_id      TEXT,
  type                  TEXT        NOT NULL CHECK (type IN ('income','expense')),
  date                  TIMESTAMPTZ NOT NULL,
  description           TEXT,
  payment_method        TEXT,
  notes                 TEXT,
  receipt_url           TEXT,
  is_synced             BOOLEAN     NOT NULL DEFAULT true,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.exchange_rates (
  id            TEXT        PRIMARY KEY,
  from_currency CHAR(3)     NOT NULL,
  to_currency   CHAR(3)     NOT NULL,
  rate          REAL        NOT NULL,
  rate_type     TEXT        NOT NULL,
  source        TEXT,
  valid_at      TIMESTAMPTZ NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.budgets (
  id            TEXT        PRIMARY KEY,
  group_id      TEXT        NOT NULL,
  category_id   TEXT        NOT NULL REFERENCES public.categories(id),
  monthly_limit REAL        NOT NULL,
  currency_code CHAR(3)     NOT NULL DEFAULT 'USD',
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (group_id, category_id)
);

CREATE TABLE IF NOT EXISTS public.savings_goals (
  id             TEXT        PRIMARY KEY,
  group_id       TEXT        NOT NULL,
  name           TEXT        NOT NULL,
  target_amount  REAL        NOT NULL,
  current_amount REAL        NOT NULL DEFAULT 0,
  currency_code  CHAR(3)     NOT NULL DEFAULT 'USD',
  target_date    TIMESTAMPTZ,
  icon_code      TEXT        NOT NULL DEFAULT 'savings',
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Índices ───────────────────────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_transactions_group_date
  ON public.transactions (group_id, date DESC);

CREATE INDEX IF NOT EXISTS idx_transactions_unsynced
  ON public.transactions (is_synced) WHERE is_synced = false;

CREATE INDEX IF NOT EXISTS idx_budgets_group
  ON public.budgets (group_id);

CREATE INDEX IF NOT EXISTS idx_savings_goals_group
  ON public.savings_goals (group_id);

-- ── Row Level Security ────────────────────────────────────────────────────────

ALTER TABLE public.categories    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exchange_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.budgets        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.savings_goals  ENABLE ROW LEVEL SECURITY;

-- categories: sistema visible para todos, propias solo para su dueño
CREATE POLICY "Categorías sistema: lectura pública autenticada"
  ON public.categories FOR SELECT TO authenticated
  USING (is_system = true OR group_id = auth.uid()::text);

CREATE POLICY "Categorías propias: inserción"
  ON public.categories FOR INSERT TO authenticated
  WITH CHECK (group_id = auth.uid()::text);

CREATE POLICY "Categorías propias: actualización"
  ON public.categories FOR UPDATE TO authenticated
  USING (group_id = auth.uid()::text);

-- transactions
CREATE POLICY "Transacciones: lectura del grupo propio"
  ON public.transactions FOR SELECT TO authenticated
  USING (group_id = auth.uid()::text);

CREATE POLICY "Transacciones: inserción en grupo propio"
  ON public.transactions FOR INSERT TO authenticated
  WITH CHECK (group_id = auth.uid()::text AND user_id = auth.uid());

CREATE POLICY "Transacciones: actualización en grupo propio"
  ON public.transactions FOR UPDATE TO authenticated
  USING (group_id = auth.uid()::text);

CREATE POLICY "Transacciones: eliminación en grupo propio"
  ON public.transactions FOR DELETE TO authenticated
  USING (group_id = auth.uid()::text);

-- exchange_rates: solo lectura para todos los autenticados
CREATE POLICY "Tasas de cambio: solo lectura"
  ON public.exchange_rates FOR SELECT TO authenticated
  USING (true);

-- budgets
CREATE POLICY "Presupuestos: CRUD del grupo propio"
  ON public.budgets FOR ALL TO authenticated
  USING (group_id = auth.uid()::text)
  WITH CHECK (group_id = auth.uid()::text);

-- savings_goals
CREATE POLICY "Metas de ahorro: CRUD del grupo propio"
  ON public.savings_goals FOR ALL TO authenticated
  USING (group_id = auth.uid()::text)
  WITH CHECK (group_id = auth.uid()::text);

-- ── Seed: categorías del sistema ──────────────────────────────────────────────

INSERT INTO public.categories
  (id, group_id, name, icon_code, color_hex, type, is_system, sort_order)
VALUES
  ('sys_food',          NULL, 'Alimentación',    'restaurant',          '#E74C3C', 'expense', true,  1),
  ('sys_transport',     NULL, 'Transporte',       'directions_car',      '#E67E22', 'expense', true,  2),
  ('sys_services',      NULL, 'Servicios',        'bolt',                '#3498DB', 'expense', true,  3),
  ('sys_health',        NULL, 'Salud',            'local_hospital',      '#2ECC71', 'expense', true,  4),
  ('sys_education',     NULL, 'Educación',        'school',              '#9B59B6', 'expense', true,  5),
  ('sys_entertainment', NULL, 'Entretenimiento',  'movie',               '#F39C12', 'expense', true,  6),
  ('sys_clothing',      NULL, 'Ropa',             'checkroom',           '#1ABC9C', 'expense', true,  7),
  ('sys_home',          NULL, 'Hogar',            'home',                '#34495E', 'expense', true,  8),
  ('sys_debt',          NULL, 'Deudas',           'credit_card',         '#C0392B', 'expense', true,  9),
  ('sys_other_exp',     NULL, 'Otros gastos',     'more_horiz',          '#95A5A6', 'expense', true, 10),
  ('sys_salary',        NULL, 'Salario',          'work',                '#27AE60', 'income',  true,  1),
  ('sys_freelance',     NULL, 'Freelance',        'laptop',              '#2980B9', 'income',  true,  2),
  ('sys_investments',   NULL, 'Inversiones',      'trending_up',         '#8E44AD', 'income',  true,  3),
  ('sys_other_inc',     NULL, 'Otros ingresos',   'attach_money',        '#16A085', 'income',  true,  4)
ON CONFLICT (id) DO NOTHING;
