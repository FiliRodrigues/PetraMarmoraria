-- 008d_get_all_order_assignments_function.sql
-- RPC que lista todos os assignments num intervalo (agenda/relatórios).
-- Reconciliação: aplicada em produção mas ausente do repo. Capturada do banco em 2026-06-10.

CREATE OR REPLACE FUNCTION public.get_all_order_assignments(p_from timestamptz DEFAULT NULL, p_to timestamptz DEFAULT NULL)
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
  WHERE (p_from IS NULL OR oa.assigned_at >= p_from)
    AND (p_to IS NULL OR oa.assigned_at <= p_to)
  ORDER BY oa.assigned_at DESC;
END;
$$;
