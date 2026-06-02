-- ============================================================
-- Migración 016: Tokens FCM para push notifications
-- ============================================================

CREATE TABLE IF NOT EXISTS public.fcm_tokens (
  id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  group_id    TEXT        NOT NULL,
  token       TEXT        NOT NULL,
  platform    TEXT        NOT NULL DEFAULT 'android'
                CHECK (platform IN ('android', 'ios')),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, token)
);

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_group
  ON public.fcm_tokens (group_id);

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user
  ON public.fcm_tokens (user_id);

ALTER TABLE public.fcm_tokens ENABLE ROW LEVEL SECURITY;

-- Cada usuario puede gestionar sus propios tokens
CREATE POLICY "fcm: user manages own tokens"
  ON public.fcm_tokens FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- RPC para upsert de token (evita duplicados y actualiza timestamp)
CREATE OR REPLACE FUNCTION public.upsert_fcm_token(
  p_group_id TEXT,
  p_token    TEXT,
  p_platform TEXT DEFAULT 'android'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.fcm_tokens (user_id, group_id, token, platform)
  VALUES (auth.uid(), p_group_id, p_token, p_platform)
  ON CONFLICT (user_id, token)
  DO UPDATE SET
    group_id   = EXCLUDED.group_id,
    platform   = EXCLUDED.platform,
    updated_at = now();
END;
$$;

REVOKE ALL ON FUNCTION public.upsert_fcm_token(text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.upsert_fcm_token(text, text, text) TO authenticated;

-- RPC para eliminar token al cerrar sesión
CREATE OR REPLACE FUNCTION public.delete_fcm_token(p_token TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  DELETE FROM public.fcm_tokens
  WHERE user_id = auth.uid() AND token = p_token;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_fcm_token(text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.delete_fcm_token(text) TO authenticated;
