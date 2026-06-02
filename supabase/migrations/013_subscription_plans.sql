-- ============================================================
-- Migración 013: Modelo de 4 planes de suscripción
-- beta | free | family ($2.99/mes) | premium ($9.99/mes)
-- ============================================================

-- ── 1. Agregar plan_name a profiles ──────────────────────────────────────────

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS plan_name TEXT NOT NULL DEFAULT 'free'
    CHECK (plan_name IN ('beta', 'free', 'family', 'premium'));

-- ── 2. Migrar usuarios premium existentes → plan 'premium' ───────────────────

UPDATE public.profiles
SET plan_name = 'premium'
WHERE is_premium = true
  AND plan_name = 'free';

-- ── 3. Función helper: max_members según plan ─────────────────────────────────

CREATE OR REPLACE FUNCTION public.max_members_for_plan(p_plan TEXT)
RETURNS INTEGER
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE p_plan
    WHEN 'premium' THEN 10
    WHEN 'beta'    THEN 10
    WHEN 'family'  THEN 5
    ELSE 2           -- 'free': 2 miembros (mantiene CHECK max_members >= 2)
  END;
$$;

-- ── 4. Actualizar max_members de grupos existentes según plan del owner ───────

UPDATE public.family_groups fg
SET max_members = public.max_members_for_plan(COALESCE(p.plan_name, 'free'))
FROM public.profiles p
WHERE fg.owner_id = p.id;

-- ── 5. Nueva RPC: set_user_plan ───────────────────────────────────────────────
-- Reemplaza set_user_premium para el modelo de 4 planes.
-- El webhook de LemonSqueezy llama esta función con service_role.
-- También actualiza is_premium por compatibilidad con código existente.

CREATE OR REPLACE FUNCTION public.set_user_plan(
  p_user_id   uuid,
  p_plan_name text,
  p_billing   text,          -- 'monthly' | 'annual' | null
  p_expires   timestamptz
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET
    plan_name          = p_plan_name,
    is_premium         = (p_plan_name NOT IN ('free')),
    premium_plan       = p_billing,
    premium_expires_at = p_expires,
    updated_at         = now()
  WHERE id = p_user_id;

  -- Actualizar max_members de todos los grupos del owner
  UPDATE public.family_groups
  SET max_members = public.max_members_for_plan(p_plan_name)
  WHERE owner_id = p_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.set_user_plan(uuid, text, text, timestamptz) FROM PUBLIC;
-- Solo service_role puede ejecutarla (no la otorgamos a 'authenticated')

-- ── 6. Actualizar revoke_user_premium para resetear plan_name ─────────────────

CREATE OR REPLACE FUNCTION public.revoke_user_premium(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET
    is_premium         = false,
    plan_name          = 'free',
    premium_plan       = NULL,
    premium_expires_at = NULL,
    updated_at         = now()
  WHERE id = p_user_id;

  -- Resetear max_members de los grupos del owner al mínimo (free = 2)
  UPDATE public.family_groups
  SET max_members = 2
  WHERE owner_id = p_user_id;
END;
$$;

-- ── 7. Actualizar create_family_group para respetar el plan del owner ─────────

CREATE OR REPLACE FUNCTION public.create_family_group(p_name text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group_id    uuid;
  v_group_row   json;
  v_plan_name   text;
  v_max_members integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No hay sesión activa';
  END IF;

  IF char_length(trim(p_name)) = 0 THEN
    RAISE EXCEPTION 'El nombre del grupo no puede estar vacío';
  END IF;

  -- Obtener plan del owner (default 'free' si no tiene perfil aún)
  SELECT COALESCE(plan_name, 'free') INTO v_plan_name
  FROM public.profiles
  WHERE id = auth.uid();

  v_max_members := public.max_members_for_plan(COALESCE(v_plan_name, 'free'));

  -- Insertar grupo (trigger genera invite_code y agrega al owner como miembro)
  INSERT INTO public.family_groups (name, owner_id, invite_code, max_members)
  VALUES (trim(p_name), auth.uid(), '', v_max_members)
  RETURNING id INTO v_group_id;

  SELECT row_to_json(fg) INTO v_group_row
  FROM public.family_groups fg
  WHERE fg.id = v_group_id;

  RETURN v_group_row;
END;
$$;

REVOKE ALL ON FUNCTION public.create_family_group(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_family_group(text) TO authenticated;

-- ── 8. Agregar RPC de lectura del plan (para el cliente Flutter) ──────────────

CREATE OR REPLACE FUNCTION public.get_my_plan()
RETURNS TABLE (
  plan_name   text,
  billing     text,
  expires_at  timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT plan_name, premium_plan, premium_expires_at
  FROM public.profiles
  WHERE id = auth.uid();
$$;

REVOKE ALL ON FUNCTION public.get_my_plan() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_my_plan() TO authenticated;
