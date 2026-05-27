-- 004_fura_fila.sql
-- Function to detect queue violations (fura-fila) in the production pipeline

-- 1. Helper function to translate internal status keys into user-friendly labels
CREATE OR REPLACE FUNCTION public.get_status_label(p_status TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN CASE p_status
    WHEN 'orcamento' THEN 'Orçamento'
    WHEN 'aprovado' THEN 'Aprovado'
    WHEN 'recebido' THEN 'Recebido'
    WHEN 'esperando_material' THEN 'Esperando Material'
    WHEN 'corte' THEN 'Corte'
    WHEN 'montagem' THEN 'Montagem'
    WHEN 'entrega' THEN 'Entrega'
    ELSE p_status
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- 2. Main function: check_queue_violation
-- Checks if a specific service order has skipped ahead of older active service orders.
-- Returns all older orders that are currently in an earlier production stage than the target order.
CREATE OR REPLACE FUNCTION public.check_queue_violation(p_order_id UUID)
RETURNS TABLE(violated_by_id UUID, violated_by_number INT, violation_message TEXT) AS $$
DECLARE
  v_status TEXT;
  v_queue INT;
  v_display_number INT;
BEGIN
  -- Retrieve status and queue position of the order to check
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
  WHERE so.queue_position < v_queue            -- Older in queue sequence
    AND so.status IS DISTINCT FROM 'entrega'    -- Skip completed orders
    AND so.id != p_order_id                     -- Don't compare against itself
    AND (
      -- Check if the older order is lagging behind in a prior stage
      CASE v_status
        WHEN 'aprovado' THEN so.status IN ('orcamento')
        WHEN 'recebido' THEN so.status IN ('orcamento', 'aprovado')
        WHEN 'esperando_material' THEN so.status IN ('orcamento', 'aprovado', 'recebido')
        WHEN 'corte' THEN so.status IN ('orcamento', 'aprovado', 'recebido', 'esperando_material')
        WHEN 'montagem' THEN so.status IN ('orcamento', 'aprovado', 'recebido', 'esperando_material', 'corte')
        WHEN 'entrega' THEN so.status IN ('orcamento', 'aprovado', 'recebido', 'esperando_material', 'corte', 'montagem')
        ELSE FALSE
      END
    );
END;
$$ LANGUAGE plpgsql;
