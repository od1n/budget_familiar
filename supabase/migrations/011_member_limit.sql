-- ============================================================
-- Migración 011: Límite de miembros por grupo familiar
-- ============================================================

-- ── 1. Agregar columna max_members ────────────────────────────────────────────
-- Default 5 → plan Pro. Grupos existentes quedan en 5.

ALTER TABLE public.family_groups
  ADD COLUMN IF NOT EXISTS max_members INTEGER NOT NULL DEFAULT 5
    CHECK (max_members BETWEEN 2 AND 20);

-- ── 2. Actualizar join_group_by_invite con validación de límite ───────────────

CREATE OR REPLACE FUNCTION public.join_group_by_invite(p_invite_code text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group_id   uuid;
  v_max        integer;
  v_current    integer;
BEGIN
  -- Buscar grupo por invite code
  SELECT id, max_members INTO v_group_id, v_max
  FROM public.family_groups
  WHERE invite_code = p_invite_code;

  IF v_group_id IS NULL THEN
    RAISE EXCEPTION 'Código de invitación inválido o expirado';
  END IF;

  -- Verificar si ya es miembro
  IF EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = v_group_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Ya eres miembro de este grupo';
  END IF;

  -- Verificar límite de miembros
  SELECT COUNT(*) INTO v_current
  FROM public.group_members
  WHERE group_id = v_group_id;

  IF v_current >= v_max THEN
    RAISE EXCEPTION 'El grupo ha alcanzado el límite de % miembros', v_max;
  END IF;

  -- Insertar como miembro
  INSERT INTO public.group_members (group_id, user_id, role)
  VALUES (v_group_id, auth.uid(), 'member')
  ON CONFLICT (group_id, user_id) DO NOTHING;
END;
$$;

REVOKE ALL ON FUNCTION public.join_group_by_invite(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.join_group_by_invite(text) TO authenticated;
