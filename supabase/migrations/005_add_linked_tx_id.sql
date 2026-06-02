-- ============================================================
-- Migración 005: columna linked_tx_id para transferencias internas
-- ============================================================
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- ============================================================

ALTER TABLE transactions
  ADD COLUMN IF NOT EXISTS linked_tx_id TEXT REFERENCES transactions(id) ON DELETE SET NULL;

-- Índice para búsquedas por par vinculado
CREATE INDEX IF NOT EXISTS idx_transactions_linked_tx_id
  ON transactions (linked_tx_id)
  WHERE linked_tx_id IS NOT NULL;

-- Política RLS: los miembros del grupo pueden ver/crear transferencias de su grupo
-- (ya cubierto por las políticas existentes que filtran por group_id;
--  se agrega sólo como recordatorio explícito de que 'transfer' es un tipo válido)

-- Verificar que la columna existe
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'transactions'
  AND column_name = 'linked_tx_id';
