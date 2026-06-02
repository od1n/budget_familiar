-- ============================================================
-- Migración 009 — Correcciones de seguridad (auditoría)
-- ============================================================

-- ── C-1: REVOCAR permisos de RPCs premium ─────────────────────────────────────
-- Las funciones set_user_premium y revoke_user_premium son SECURITY DEFINER
-- y deben ser invocables SOLO desde el backend (service_role / Edge Function).
-- Sin este REVOKE, cualquier usuario autenticado puede llamarlas vía .rpc().

REVOKE ALL ON FUNCTION public.set_user_premium(uuid, text, timestamptz) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.revoke_user_premium(uuid) FROM PUBLIC;
-- Solo service_role puede ejecutarlas; authenticated no tiene acceso.


-- ── A-3: Unirse a un grupo requiere invite code válido ────────────────────────
-- La política anterior permitía INSERT directo en group_members con solo
-- conocer el group_id. Ahora el join DEBE pasar por esta función que valida
-- el invite_code antes de insertar.

-- Revocar INSERT directo en group_members para usuarios autenticados
-- (el trigger add_owner_as_member usa SECURITY DEFINER y sigue funcionando)
DROP POLICY IF EXISTS "gm: users can join" ON public.group_members;

CREATE OR REPLACE FUNCTION public.join_group_by_invite(p_invite_code text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group_id uuid;
BEGIN
  -- Buscar grupo por invite code
  SELECT id INTO v_group_id
  FROM public.family_groups
  WHERE invite_code = p_invite_code;

  IF v_group_id IS NULL THEN
    RAISE EXCEPTION 'Código de invitación inválido o expirado';
  END IF;

  -- Insertar como miembro (ON CONFLICT para idempotencia)
  INSERT INTO public.group_members (group_id, user_id, role)
  VALUES (v_group_id, auth.uid(), 'member')
  ON CONFLICT (group_id, user_id) DO NOTHING;
END;
$$;

-- Solo authenticated puede invocarla (no PUBLIC anónimo)
REVOKE ALL ON FUNCTION public.join_group_by_invite(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.join_group_by_invite(text) TO authenticated;


-- ── M-1: SET search_path en todas las funciones SECURITY DEFINER ──────────────
-- Previene search_path hijacking si un atacante crea objetos en otro schema.

CREATE OR REPLACE FUNCTION public.user_group_ids_text()
RETURNS SETOF text
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT gm.group_id::text
  FROM   public.group_members gm
  WHERE  gm.user_id = auth.uid()
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_user_premium(
  p_user_id   uuid,
  p_plan      text,
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
    is_premium         = true,
    premium_plan       = p_plan,
    premium_expires_at = p_expires,
    updated_at         = now()
  WHERE id = p_user_id;
END;
$$;

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
    premium_plan       = NULL,
    premium_expires_at = NULL,
    updated_at         = now()
  WHERE id = p_user_id;
END;
$$;

-- Re-aplicar REVOKE después de recrear las funciones
REVOKE ALL ON FUNCTION public.set_user_premium(uuid, text, timestamptz) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.revoke_user_premium(uuid) FROM PUBLIC;


-- ── M-2: Política INSERT en profiles ─────────────────────────────────────────
-- Robustez: si el trigger falla, el usuario puede crear su propio perfil.

DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;
CREATE POLICY "profiles_insert_own" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);


-- ── M-4: Política RLS en group_members sin autoreferencia ────────────────────
-- La policy anterior hacía subconsulta sobre la misma tabla siendo evaluada.

DROP POLICY IF EXISTS "gm: members can select" ON public.group_members;
CREATE POLICY "gm: members can select" ON public.group_members
  FOR SELECT USING (
    group_id::text IN (SELECT public.user_group_ids_text())
  );


-- ── B-1: Ampliar invite_code a 12 caracteres ─────────────────────────────────
-- 32^8 ≈ 1.1B combinaciones → 32^12 ≈ 1.15T combinaciones.
-- Los códigos existentes de 8 chars siguen funcionando; solo los nuevos
-- grupos generarán códigos de 12 chars.

CREATE OR REPLACE FUNCTION public.generate_invite_code()
RETURNS text
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  code  text := '';
  i     int;
BEGIN
  FOR i IN 1..12 LOOP
    code := code || substr(chars, floor(random() * length(chars) + 1)::int, 1);
  END LOOP;
  RETURN code;
END;
$$;


-- ── B-2: Política DELETE en categories ───────────────────────────────────────
-- Solo categorías propias (no del sistema) pueden borrarse.

DROP POLICY IF EXISTS "cats: delete" ON public.categories;
CREATE POLICY "cats: delete"
  ON public.categories FOR DELETE TO authenticated
  USING (
    is_system = false
    AND group_id IN (SELECT public.user_group_ids_text())
  );
