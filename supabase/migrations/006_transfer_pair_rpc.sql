-- ============================================================
-- Migración 006: RPC para crear par de transferencias internamente
-- ============================================================
-- La política INSERT de transactions exige user_id = auth.uid(), lo que
-- impide que el emisor inserte la fila del receptor.
-- Esta función SECURITY DEFINER se ejecuta con permisos elevados y puede
-- insertar ambas filas validando que el llamador sea miembro del grupo.
-- ============================================================

CREATE OR REPLACE FUNCTION public.create_transfer_pair(
  p_out_id          text,
  p_in_id           text,
  p_group_id        text,
  p_sender_id       text,
  p_receiver_id     text,
  p_amount          numeric,
  p_currency_code   text,
  p_amount_usd      numeric,   -- puede ser NULL
  p_date            timestamptz,
  p_description     text,      -- puede ser NULL
  p_out_notes       text,
  p_in_notes        text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Validar que el llamador sea miembro del grupo
  IF NOT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id::text = p_group_id
      AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'El usuario no pertenece al grupo';
  END IF;

  -- Validar que el receptor también sea miembro del grupo
  IF NOT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id::text = p_group_id
      AND user_id = p_receiver_id::uuid
  ) THEN
    RAISE EXCEPTION 'El receptor no pertenece al grupo';
  END IF;

  -- Insertar la fila de salida (sender)
  INSERT INTO public.transactions (
    id, group_id, user_id, amount, currency_code,
    amount_usd_equivalent, type, date, description,
    notes, linked_tx_id, is_synced, created_at, updated_at
  ) VALUES (
    p_out_id, p_group_id, p_sender_id, p_amount, p_currency_code,
    p_amount_usd, 'transfer', p_date, p_description,
    p_out_notes, p_in_id, true, now(), now()
  )
  ON CONFLICT (id) DO NOTHING;

  -- Insertar la fila de entrada (receiver)
  INSERT INTO public.transactions (
    id, group_id, user_id, amount, currency_code,
    amount_usd_equivalent, type, date, description,
    notes, linked_tx_id, is_synced, created_at, updated_at
  ) VALUES (
    p_in_id, p_group_id, p_receiver_id, p_amount, p_currency_code,
    p_amount_usd, 'transfer', p_date, p_description,
    p_in_notes, p_out_id, true, now(), now()
  )
  ON CONFLICT (id) DO NOTHING;
END;
$$;

-- Revocar acceso público y conceder solo a usuarios autenticados
REVOKE ALL ON FUNCTION public.create_transfer_pair FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_transfer_pair TO authenticated;
