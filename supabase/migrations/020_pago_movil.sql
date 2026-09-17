-- ============================================================
-- Migración 020: Reportes de pago por Pago Móvil (vía segura)
-- ------------------------------------------------------------
-- El cobro ocurre FUERA de Google Play (escritorio/web). El usuario
-- reporta su pago móvil; el administrador lo verifica en su banco y lo
-- aprueba desde Supabase con approve_payment_request(), que activa el
-- plan llamando a set_user_plan(). La app de Play NO contiene ningún
-- flujo de pago, por lo que no viola la política de pagos de Google.
-- ============================================================

-- ── 1. Tabla de reportes de pago ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.payment_requests (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plan_name    text NOT NULL CHECK (plan_name IN ('family', 'premium')),
  billing      text NOT NULL CHECK (billing IN ('monthly', 'annual')),
  amount_usd   numeric(10, 2),
  amount_ves   numeric(14, 2),
  reference    text NOT NULL,          -- número de confirmación del pago móvil
  payer_name   text,
  payer_phone  text,
  status       text NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending', 'approved', 'rejected')),
  note         text,                   -- nota del administrador / motivo de rechazo
  created_at   timestamptz NOT NULL DEFAULT now(),
  reviewed_at  timestamptz,
  reviewed_by  uuid
);

CREATE INDEX IF NOT EXISTS payment_requests_status_idx
  ON public.payment_requests (status, created_at DESC);

CREATE INDEX IF NOT EXISTS payment_requests_user_idx
  ON public.payment_requests (user_id, created_at DESC);

-- ── 2. Seguridad a nivel de fila (RLS) ────────────────────────────────────────
-- El usuario solo puede LEER sus propios reportes. La inserción se hace por la
-- función submit_payment_request() (SECURITY DEFINER), que fija user_id y estado
-- de forma segura, evitando que un usuario reporte a nombre de otro o se
-- autoapruebe. No hay políticas de UPDATE/DELETE: solo el administrador cambia
-- el estado, mediante las funciones de abajo.

ALTER TABLE public.payment_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "payment_requests_select_own" ON public.payment_requests;
CREATE POLICY "payment_requests_select_own"
  ON public.payment_requests
  FOR SELECT
  USING (user_id = auth.uid());

-- Lectura para usuarios autenticados (la política RLS de arriba la limita a los
-- reportes propios). No se otorga INSERT/UPDATE/DELETE: la inserción va por la
-- función submit_payment_request y no hay políticas de escritura, así que RLS
-- bloquea cualquier escritura directa.
GRANT SELECT ON public.payment_requests TO authenticated;

-- ── 3. Enviar un reporte de pago (desde la app, escritorio/web) ───────────────

CREATE OR REPLACE FUNCTION public.submit_payment_request(
  p_plan_name   text,
  p_billing     text,
  p_amount_usd  numeric,
  p_amount_ves  numeric,
  p_reference   text,
  p_payer_name  text,
  p_payer_phone text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'No hay sesión activa';
  END IF;

  IF p_plan_name NOT IN ('family', 'premium') THEN
    RAISE EXCEPTION 'Plan inválido: %', p_plan_name;
  END IF;

  IF p_billing NOT IN ('monthly', 'annual') THEN
    RAISE EXCEPTION 'Ciclo de facturación inválido: %', p_billing;
  END IF;

  IF char_length(trim(coalesce(p_reference, ''))) = 0 THEN
    RAISE EXCEPTION 'La referencia del pago no puede estar vacía';
  END IF;

  INSERT INTO public.payment_requests (
    user_id, plan_name, billing, amount_usd, amount_ves,
    reference, payer_name, payer_phone, status
  )
  VALUES (
    auth.uid(), p_plan_name, p_billing, p_amount_usd, p_amount_ves,
    trim(p_reference), nullif(trim(coalesce(p_payer_name, '')), ''),
    nullif(trim(coalesce(p_payer_phone, '')), ''), 'pending'
  )
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.submit_payment_request(text, text, numeric, numeric, text, text, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_payment_request(text, text, numeric, numeric, text, text, text) TO authenticated;

-- ── 4. Aprobar un reporte (solo administrador, desde Supabase) ────────────────
-- Verifica el pago en el banco ANTES de llamar esta función. Activa el plan
-- extendiendo cualquier vencimiento vigente y marca el reporte como aprobado.
--
-- Uso (SQL de Supabase):
--   select public.approve_payment_request('id-del-reporte');
--   -- opcional: forzar meses o cambiar de plan
--   select public.approve_payment_request('id-del-reporte', 3);
--   select public.approve_payment_request('id-del-reporte', null, 'premium');

CREATE OR REPLACE FUNCTION public.approve_payment_request(
  p_request_id uuid,
  p_months     integer DEFAULT NULL,   -- null = 1 mes (mensual) o 12 (anual)
  p_plan       text    DEFAULT NULL    -- null = usar el plan del reporte
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_req      public.payment_requests%ROWTYPE;
  v_plan     text;
  v_months   integer;
  v_current  timestamptz;
  v_base     timestamptz;
  v_expires  timestamptz;
BEGIN
  SELECT * INTO v_req
  FROM public.payment_requests
  WHERE id = p_request_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reporte de pago no encontrado: %', p_request_id;
  END IF;

  IF v_req.status = 'approved' THEN
    RAISE EXCEPTION 'El reporte ya fue aprobado';
  END IF;

  v_plan   := coalesce(p_plan, v_req.plan_name);
  v_months := coalesce(
    p_months,
    CASE v_req.billing WHEN 'annual' THEN 12 ELSE 1 END
  );

  -- Extiende sobre el vencimiento vigente si el plan sigue activo.
  SELECT premium_expires_at INTO v_current
  FROM public.profiles
  WHERE id = v_req.user_id;

  v_base := greatest(now(), coalesce(v_current, now()));
  v_expires := v_base + make_interval(months => v_months);

  -- Activa el plan (reutiliza la función existente).
  PERFORM public.set_user_plan(v_req.user_id, v_plan, v_req.billing, v_expires);

  UPDATE public.payment_requests
  SET status = 'approved', reviewed_at = now(), reviewed_by = auth.uid()
  WHERE id = p_request_id;

  RETURN json_build_object(
    'request_id', p_request_id,
    'user_id',    v_req.user_id,
    'plan_name',  v_plan,
    'billing',    v_req.billing,
    'months',     v_months,
    'expires_at', v_expires
  );
END;
$$;

-- Solo service_role / postgres (editor SQL de Supabase). NO se otorga a usuarios.
REVOKE ALL ON FUNCTION public.approve_payment_request(uuid, integer, text) FROM PUBLIC;

-- ── 5. Rechazar un reporte (solo administrador, desde Supabase) ───────────────
--   select public.reject_payment_request('id-del-reporte', 'No se ubicó el pago');

CREATE OR REPLACE FUNCTION public.reject_payment_request(
  p_request_id uuid,
  p_note       text DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.payment_requests
  SET status = 'rejected', note = p_note, reviewed_at = now(), reviewed_by = auth.uid()
  WHERE id = p_request_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Reporte de pago no encontrado: %', p_request_id;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.reject_payment_request(uuid, text) FROM PUBLIC;

-- ── 6. Listado de pendientes (comodidad para el administrador) ────────────────
--   select * from public.pending_payment_requests;

CREATE OR REPLACE VIEW public.pending_payment_requests AS
  SELECT
    pr.id,
    pr.created_at,
    pr.user_id,
    u.email,
    pr.plan_name,
    pr.billing,
    pr.amount_usd,
    pr.amount_ves,
    pr.reference,
    pr.payer_name,
    pr.payer_phone
  FROM public.payment_requests pr
  LEFT JOIN auth.users u ON u.id = pr.user_id
  WHERE pr.status = 'pending'
  ORDER BY pr.created_at ASC;
