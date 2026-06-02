-- ============================================================
-- Migración 008 — Tabla profiles + columnas premium
-- ============================================================

-- 1. Crear tabla profiles (si no existe).
--    Se sincroniza con auth.users via trigger.
CREATE TABLE IF NOT EXISTS public.profiles (
  id           uuid        PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name    text,
  avatar_url   text,
  -- ── Suscripción premium ──────────────────────────────────
  is_premium         boolean     NOT NULL DEFAULT false,
  premium_plan       text,          -- 'monthly' | 'annual' | 'lifetime'
  premium_expires_at timestamptz,   -- NULL = lifetime o no activo
  -- ────────────────────────────────────────────────────────
  updated_at   timestamptz NOT NULL DEFAULT now()
);

-- 2. Índice para consultas por estado premium
CREATE INDEX IF NOT EXISTS idx_profiles_is_premium
  ON public.profiles (is_premium)
  WHERE is_premium = true;

-- 3. Trigger: insertar fila en profiles automáticamente al registrar usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- 4. Insertar perfil para usuarios ya existentes (idempotente)
INSERT INTO public.profiles (id, full_name)
SELECT
  u.id,
  u.raw_user_meta_data->>'full_name'
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM public.profiles p WHERE p.id = u.id
);

-- 5. RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
CREATE POLICY "profiles_select_own" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
CREATE POLICY "profiles_update_own" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 6. RPCs para que el webhook del procesador de pagos actualice el estado
--    (llamar con service_role key desde el backend, nunca desde el cliente)

CREATE OR REPLACE FUNCTION public.set_user_premium(
  p_user_id   uuid,
  p_plan      text,
  p_expires   timestamptz
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
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
