-- ============================================================
-- Migración 004: Transacciones recurrentes + parches pendientes
-- ============================================================
-- Ejecutar en Supabase SQL Editor en el orden en que aparecen.
-- ============================================================

-- ── 1. PARCHES DE LA MIGRACIÓN 003 (PENDIENTES) ─────────────────────────────

-- 1a. Policy UPDATE en group_members — necesaria para transferOwnership.
--     El owner actual puede actualizar los roles de miembros de su grupo.
CREATE POLICY "gm: owner puede actualizar roles"
  ON public.group_members
  FOR UPDATE
  TO authenticated
  USING (
    group_id IN (
      SELECT id FROM public.family_groups WHERE owner_id = auth.uid()
    )
  );

-- 1b. Habilitar Realtime en la tabla transactions
--     (sin esto RealtimeService no recibe eventos).
ALTER PUBLICATION supabase_realtime ADD TABLE public.transactions;

-- ── 2. TABLA recurring_transactions ─────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.recurring_transactions (
  id              TEXT        PRIMARY KEY,
  group_id        TEXT        NOT NULL,
  user_id         UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  category_id     TEXT,
  amount          NUMERIC     NOT NULL CHECK (amount > 0),
  currency_code   TEXT        NOT NULL DEFAULT 'USD',
  type            TEXT        NOT NULL CHECK (type IN ('income', 'expense')),
  description     TEXT,
  -- 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'yearly'
  frequency       TEXT        NOT NULL
                    CHECK (frequency IN ('daily','weekly','biweekly','monthly','yearly')),
  -- Día del mes (1-28) para frecuencias mensuales; NULL = usar nextDueDate.day
  day_of_month    SMALLINT    CHECK (day_of_month BETWEEN 1 AND 28),
  next_due_date   TIMESTAMPTZ NOT NULL,
  is_active       BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Índices de uso frecuente
CREATE INDEX IF NOT EXISTS idx_rt_group_active
  ON public.recurring_transactions (group_id, is_active, next_due_date);

CREATE INDEX IF NOT EXISTS idx_rt_user
  ON public.recurring_transactions (user_id);

-- ── 3. RLS ───────────────────────────────────────────────────────────────────

ALTER TABLE public.recurring_transactions ENABLE ROW LEVEL SECURITY;

-- SELECT: miembros del grupo pueden leer las plantillas del grupo.
CREATE POLICY "rt: miembros del grupo pueden leer"
  ON public.recurring_transactions
  FOR SELECT
  TO authenticated
  USING (group_id IN (SELECT public.user_group_ids_text()));

-- INSERT: solo el usuario autenticado puede insertar sus propias plantillas
--         en un grupo al que pertenece.
CREATE POLICY "rt: miembro puede insertar"
  ON public.recurring_transactions
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid()::text = user_id::text
    AND group_id IN (SELECT public.user_group_ids_text())
  );

-- UPDATE: el creador (user_id) puede editar sus propias plantillas.
CREATE POLICY "rt: creador puede actualizar"
  ON public.recurring_transactions
  FOR UPDATE
  TO authenticated
  USING (auth.uid()::text = user_id::text)
  WITH CHECK (auth.uid()::text = user_id::text);

-- DELETE: el creador puede eliminar sus propias plantillas.
CREATE POLICY "rt: creador puede eliminar"
  ON public.recurring_transactions
  FOR DELETE
  TO authenticated
  USING (auth.uid()::text = user_id::text);

-- ── 4. REALTIME (opcional — Fase 2) ─────────────────────────────────────────
-- Descomentar si se necesita sincronización en tiempo real de plantillas.
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.recurring_transactions;

-- ── FIN ──────────────────────────────────────────────────────────────────────
-- Verificar con:
--   SELECT tablename, policyname FROM pg_policies
--   WHERE tablename = 'recurring_transactions';
