-- 021_move_status_transactional.sql
-- RPC transacional para mover o status de uma OS.
-- Substitui as 3 escritas separadas (UPDATE status + INSERT history + INSERT assignment)
-- que podiam deixar o banco inconsistente se uma delas falhasse.

CREATE OR REPLACE FUNCTION public.move_service_order_status(
  p_order_id uuid,
  p_new_status text,
  p_changed_by uuid,
  p_notes text DEFAULT NULL,
  p_employee_id uuid DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_current_status text;
BEGIN
  SELECT status INTO v_current_status
  FROM public.service_orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Ordem de serviço não encontrada';
  END IF;

  UPDATE public.service_orders
  SET status = p_new_status,
      status_changed_at = now(),
      updated_at = now()
  WHERE id = p_order_id;

  INSERT INTO public.status_history (order_id, from_status, to_status, changed_by, notes)
  VALUES (p_order_id, v_current_status, p_new_status, p_changed_by, p_notes);

  IF p_employee_id IS NOT NULL THEN
    INSERT INTO public.order_assignments (order_id, stage, employee_id, notes)
    VALUES (p_order_id, p_new_status, p_employee_id, p_notes);
  END IF;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.move_service_order_status(uuid, text, uuid, text, uuid) FROM anon, public;
GRANT EXECUTE ON FUNCTION public.move_service_order_status(uuid, text, uuid, text, uuid) TO authenticated;
