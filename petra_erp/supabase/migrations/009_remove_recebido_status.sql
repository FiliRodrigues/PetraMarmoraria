-- Remove status "recebido" do fluxo de Ordens de Serviço.
-- Etapas oficiais: orcamento, aprovado, esperando_material, corte, montagem, entrega.

-- 1. CHECK constraints da status_history sem 'recebido'
ALTER TABLE public.status_history DROP CONSTRAINT IF EXISTS status_history_from_status_check;
ALTER TABLE public.status_history DROP CONSTRAINT IF EXISTS status_history_to_status_check;

ALTER TABLE public.status_history
  ADD CONSTRAINT status_history_from_status_check
  CHECK (from_status IS NULL OR from_status IN ('orcamento','aprovado','esperando_material','corte','montagem','entrega'));

ALTER TABLE public.status_history
  ADD CONSTRAINT status_history_to_status_check
  CHECK (to_status IN ('orcamento','aprovado','esperando_material','corte','montagem','entrega'));

-- 2. get_status_label sem 'recebido'
CREATE OR REPLACE FUNCTION public.get_status_label(p_status TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN CASE p_status
    WHEN 'orcamento' THEN 'Orçamento'
    WHEN 'aprovado' THEN 'Aprovado'
    WHEN 'esperando_material' THEN 'Esperando Material'
    WHEN 'corte' THEN 'Corte'
    WHEN 'montagem' THEN 'Montagem'
    WHEN 'entrega' THEN 'Entrega'
    ELSE p_status
  END;
END;
$$ LANGUAGE plpgsql;

-- 3. check_queue_violation sem 'recebido'
CREATE OR REPLACE FUNCTION public.check_queue_violation(p_order_id UUID)
RETURNS TABLE (
  violated_by_id UUID,
  violated_by_number INT,
  violation_message TEXT
) AS $$
DECLARE
  v_status TEXT;
  v_queue INT;
  v_display_number INT;
BEGIN
  SELECT status, queue_position, display_number
  INTO v_status, v_queue, v_display_number
  FROM public.service_orders
  WHERE id = p_order_id;

  RETURN QUERY
  SELECT
    so.id AS violated_by_id,
    so.display_number AS violated_by_number,
    format('ATENÇÃO: OS #%s em %s antes da OS #%s (ainda em %s)',
      v_display_number,
      public.get_status_label(v_status),
      so.display_number,
      public.get_status_label(so.status)
    ) AS violation_message
  FROM public.service_orders so
  WHERE so.queue_position < v_queue
    AND so.status IS DISTINCT FROM 'entrega'
    AND so.id != p_order_id
    AND (
      CASE v_status
        WHEN 'aprovado' THEN so.status IN ('orcamento')
        WHEN 'esperando_material' THEN so.status IN ('orcamento', 'aprovado')
        WHEN 'corte' THEN so.status IN ('orcamento', 'aprovado', 'esperando_material')
        WHEN 'montagem' THEN so.status IN ('orcamento', 'aprovado', 'esperando_material', 'corte')
        WHEN 'entrega' THEN so.status IN ('orcamento', 'aprovado', 'esperando_material', 'corte', 'montagem')
        ELSE FALSE
      END
    );
END;
$$ LANGUAGE plpgsql;
