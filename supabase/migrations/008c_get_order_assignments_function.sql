-- 008c_get_order_assignments_function.sql
-- RPC que lista os assignments de uma OS com o nome do funcionário (join em profiles).
-- Reconciliação: aplicada em produção mas ausente do repo. Capturada do banco em 2026-06-10.

CREATE OR REPLACE FUNCTION public.get_order_assignments(p_order_id uuid)
RETURNS TABLE (
  id uuid,
  order_id uuid,
  stage text,
  employee_id uuid,
  assigned_at timestamptz,
  completed_at timestamptz,
  notes text,
  employee_name text
)
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY
  SELECT oa.id, oa.order_id, oa.stage, oa.employee_id, oa.assigned_at, oa.completed_at, oa.notes, p.name::text
  FROM public.order_assignments oa
  LEFT JOIN public.profiles p ON p.id = oa.employee_id
  WHERE oa.order_id = p_order_id
  ORDER BY oa.assigned_at ASC;
END;
$$;
