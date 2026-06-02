-- ─────────────────────────────────────────────────────────────────────────────
-- 007_accounts.sql
-- Tabla de cuentas bancarias/efectivo por grupo familiar
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Tabla accounts
CREATE TABLE IF NOT EXISTS public.accounts (
  id               TEXT        PRIMARY KEY,
  -- group_id es TEXT para coincidir con el resto del schema (transactions, budgets, etc.).
  -- family_groups.id es uuid: no se puede definir FK directa entre tipos distintos en PG.
  -- La integridad referencial queda garantizada por las políticas RLS (group_members).
  group_id         TEXT        NOT NULL,
  type             TEXT        NOT NULL DEFAULT 'cash'
                               CHECK (type IN ('cash','bank','digital','credit','investment')),
  name             TEXT        NOT NULL,
  currency_code    CHAR(3)     NOT NULL DEFAULT 'USD',
  initial_balance  DOUBLE PRECISION NOT NULL DEFAULT 0,
  color_hex        TEXT        NOT NULL DEFAULT '#607D8B',
  icon_code        TEXT        NOT NULL DEFAULT 'account_balance_wallet',
  is_archived      BOOLEAN     NOT NULL DEFAULT FALSE,
  is_synced        BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Columna account_id en transactions (nullable, sin FK estricta para evitar
--    problemas de orden de sincronización)
ALTER TABLE public.transactions
  ADD COLUMN IF NOT EXISTS account_id TEXT REFERENCES public.accounts(id) ON DELETE SET NULL;

-- 3. Índices
CREATE INDEX IF NOT EXISTS accounts_group_idx ON public.accounts (group_id);
CREATE INDEX IF NOT EXISTS transactions_account_idx ON public.transactions (account_id);

-- 4. RLS
ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

-- Las políticas usan user_group_ids_text() (definida en 003_family_groups.sql)
-- que devuelve los group_id como TEXT, compatible con accounts.group_id TEXT.

CREATE POLICY "accounts_select" ON public.accounts
  FOR SELECT USING (
    accounts.group_id IN (SELECT public.user_group_ids_text())
  );

CREATE POLICY "accounts_insert" ON public.accounts
  FOR INSERT WITH CHECK (
    accounts.group_id IN (SELECT public.user_group_ids_text())
  );

CREATE POLICY "accounts_update" ON public.accounts
  FOR UPDATE USING (
    accounts.group_id IN (SELECT public.user_group_ids_text())
  );

CREATE POLICY "accounts_delete" ON public.accounts
  FOR DELETE USING (
    accounts.group_id IN (SELECT public.user_group_ids_text())
  );
