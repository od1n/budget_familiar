-- ============================================================
-- Migración 012: RPC para crear grupo familiar (evita RLS en cliente)
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_family_group(p_name text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_group_id   uuid;
  v_group_row  json;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No hay sesión activa';
  END IF;

  IF char_length(trim(p_name)) = 0 THEN
    RAISE EXCEPTION 'El nombre del grupo no puede estar vacío';
  END IF;

  -- Insertar grupo (trigger genera invite_code y agrega al owner como miembro)
  INSERT INTO public.family_groups (name, owner_id, invite_code)
  VALUES (trim(p_name), auth.uid(), '')
  RETURNING id INTO v_group_id;

  -- Devolver el grupo creado como JSON
  SELECT row_to_json(fg) INTO v_group_row
  FROM public.family_groups fg
  WHERE fg.id = v_group_id;

  RETURN v_group_row;
END;
$$;

REVOKE ALL ON FUNCTION public.create_family_group(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_family_group(text) TO authenticated;
