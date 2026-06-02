-- ============================================================
-- Migración 003: Grupos familiares
-- Ejecutar en: Supabase Dashboard → SQL Editor
--
-- IMPORTANTE: todas las tablas originales (transactions, budgets,
-- savings_goals, categories) usan group_id TEXT, no uuid.
-- Las funciones auxiliares convierten uuid → text donde hace falta.
-- ============================================================

-- ── 1. Tabla family_groups ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.family_groups (
  id           uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text        NOT NULL CHECK (char_length(name) BETWEEN 1 AND 60),
  owner_id     uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  invite_code  text        NOT NULL UNIQUE,
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_family_groups_invite_code
  ON public.family_groups (invite_code);

CREATE INDEX IF NOT EXISTS idx_family_groups_owner_id
  ON public.family_groups (owner_id);

-- ── 2. Tabla group_members ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.group_members (
  id            uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id      uuid        NOT NULL REFERENCES public.family_groups(id) ON DELETE CASCADE,
  user_id       uuid        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  role          text        NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  display_name  text,
  email         text,
  joined_at     timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT uq_group_members_group_user UNIQUE (group_id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_group_members_group_id
  ON public.group_members (group_id);

CREATE INDEX IF NOT EXISTS idx_group_members_user_id
  ON public.group_members (user_id);

-- ── 3. Función helper: grupos del usuario actual como TEXT ────────────────────
-- Retorna los group_id del usuario como TEXT para comparar con las columnas
-- TEXT de transactions, budgets, savings_goals y categories.
-- Se llama desde las políticas RLS — SECURITY DEFINER para evitar recursión.

CREATE OR REPLACE FUNCTION public.user_group_ids_text()
RETURNS SETOF text
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT gm.group_id::text
  FROM   public.group_members gm
  WHERE  gm.user_id = auth.uid()
$$;

-- ── 4. Función para generar invite_code único ─────────────────────────────────
-- Caracteres sin O, 0, I, 1 para evitar confusión visual.

CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  code  text := '';
  i     int;
BEGIN
  FOR i IN 1..8 LOOP
    code := code || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN code;
END;
$$;

-- ── 5. Trigger: auto-generar invite_code al insertar ─────────────────────────

CREATE OR REPLACE FUNCTION public.set_invite_code()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  candidate text;
  attempts  int := 0;
BEGIN
  IF NEW.invite_code IS NULL OR NEW.invite_code = '' THEN
    LOOP
      candidate := public.generate_invite_code();
      EXIT WHEN NOT EXISTS (
        SELECT 1 FROM public.family_groups WHERE invite_code = candidate
      );
      attempts := attempts + 1;
      IF attempts > 20 THEN
        RAISE EXCEPTION 'No se pudo generar un invite_code único tras 20 intentos';
      END IF;
    END LOOP;
    NEW.invite_code := candidate;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_invite_code ON public.family_groups;
CREATE TRIGGER trg_set_invite_code
  BEFORE INSERT ON public.family_groups
  FOR EACH ROW EXECUTE FUNCTION public.set_invite_code();

-- ── 6. Trigger: insertar al creador como miembro 'owner' ─────────────────────

CREATE OR REPLACE FUNCTION public.add_owner_as_member()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.group_members (group_id, user_id, role, email)
  VALUES (
    NEW.id,
    NEW.owner_id,
    'owner',
    (SELECT email FROM auth.users WHERE id = NEW.owner_id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_add_owner_as_member ON public.family_groups;
CREATE TRIGGER trg_add_owner_as_member
  AFTER INSERT ON public.family_groups
  FOR EACH ROW EXECUTE FUNCTION public.add_owner_as_member();

-- ── 7. RLS en family_groups y group_members ───────────────────────────────────

ALTER TABLE public.family_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- family_groups: visible para sus miembros
CREATE POLICY "fg: members can select"
  ON public.family_groups FOR SELECT
  USING (
    id IN (
      SELECT group_id FROM public.group_members
      WHERE user_id = auth.uid()
    )
  );

-- family_groups: cualquier usuario autenticado puede crear
CREATE POLICY "fg: authenticated can insert"
  ON public.family_groups FOR INSERT
  WITH CHECK (owner_id = auth.uid());

-- family_groups: solo el owner actualiza
CREATE POLICY "fg: owner can update"
  ON public.family_groups FOR UPDATE
  USING (owner_id = auth.uid());

-- family_groups: solo el owner elimina
CREATE POLICY "fg: owner can delete"
  ON public.family_groups FOR DELETE
  USING (owner_id = auth.uid());

-- group_members: visible para todos los miembros del mismo grupo
-- Usamos la función helper para evitar recursión en la política
CREATE POLICY "gm: members can select"
  ON public.group_members FOR SELECT
  USING (
    group_id IN (
      SELECT group_id FROM public.group_members gm2
      WHERE gm2.user_id = auth.uid()
    )
  );

-- group_members: un usuario puede insertarse a sí mismo
CREATE POLICY "gm: users can join"
  ON public.group_members FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- group_members: un miembro puede salir (eliminar su propia fila)
CREATE POLICY "gm: members can leave"
  ON public.group_members FOR DELETE
  USING (user_id = auth.uid());

-- ── 8. Actualizar RLS en tablas existentes ────────────────────────────────────
-- Las tablas originales usan group_id TEXT.
-- En Fase 1: group_id = auth.uid()::text (userId del usuario).
-- En Fase 2: group_id = family_groups.id::text (UUID del grupo como string).
-- La nueva política permite ambos casos via user_group_ids_text().

-- ── transactions ──────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Transacciones: lectura del grupo propio"         ON public.transactions;
DROP POLICY IF EXISTS "Transacciones: inserción en grupo propio"        ON public.transactions;
DROP POLICY IF EXISTS "Transacciones: actualización en grupo propio"    ON public.transactions;
DROP POLICY IF EXISTS "Transacciones: eliminación en grupo propio"      ON public.transactions;
DROP POLICY IF EXISTS "group members can manage transactions"            ON public.transactions;

CREATE POLICY "tx: group members can select"
  ON public.transactions FOR SELECT TO authenticated
  USING (group_id IN (SELECT public.user_group_ids_text()));

CREATE POLICY "tx: group members can insert"
  ON public.transactions FOR INSERT TO authenticated
  WITH CHECK (
    group_id IN (SELECT public.user_group_ids_text())
    AND user_id = auth.uid()
  );

CREATE POLICY "tx: group members can update"
  ON public.transactions FOR UPDATE TO authenticated
  USING (group_id IN (SELECT public.user_group_ids_text()));

CREATE POLICY "tx: group members can delete"
  ON public.transactions FOR DELETE TO authenticated
  USING (group_id IN (SELECT public.user_group_ids_text()));

-- ── budgets ───────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Presupuestos: CRUD del grupo propio" ON public.budgets;
DROP POLICY IF EXISTS "budgets: group members" ON public.budgets;

CREATE POLICY "budgets: group members"
  ON public.budgets FOR ALL TO authenticated
  USING     (group_id IN (SELECT public.user_group_ids_text()))
  WITH CHECK (group_id IN (SELECT public.user_group_ids_text()));

-- ── savings_goals ─────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Metas de ahorro: CRUD del grupo propio" ON public.savings_goals;
DROP POLICY IF EXISTS "savings: group members" ON public.savings_goals;

CREATE POLICY "savings: group members"
  ON public.savings_goals FOR ALL TO authenticated
  USING     (group_id IN (SELECT public.user_group_ids_text()))
  WITH CHECK (group_id IN (SELECT public.user_group_ids_text()));

-- ── categories ────────────────────────────────────────────────────────────────

DROP POLICY IF EXISTS "Categorías sistema: lectura pública autenticada" ON public.categories;
DROP POLICY IF EXISTS "Categorías propias: inserción"                   ON public.categories;
DROP POLICY IF EXISTS "Categorías propias: actualización"               ON public.categories;
DROP POLICY IF EXISTS "cats: select"  ON public.categories;
DROP POLICY IF EXISTS "cats: insert"  ON public.categories;
DROP POLICY IF EXISTS "cats: update"  ON public.categories;

-- Lectura: categorías del sistema (group_id IS NULL) + las del grupo del usuario
CREATE POLICY "cats: select"
  ON public.categories FOR SELECT TO authenticated
  USING (
    is_system = true
    OR group_id IN (SELECT public.user_group_ids_text())
  );

-- Inserción: solo para el grupo del usuario
CREATE POLICY "cats: insert"
  ON public.categories FOR INSERT TO authenticated
  WITH CHECK (group_id IN (SELECT public.user_group_ids_text()));

-- Actualización: solo las del grupo del usuario (no las del sistema)
CREATE POLICY "cats: update"
  ON public.categories FOR UPDATE TO authenticated
  USING (
    is_system = false
    AND group_id IN (SELECT public.user_group_ids_text())
  );
