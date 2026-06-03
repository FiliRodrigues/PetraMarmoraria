-- 013: dedup de order_assignments + índice único parcial
-- Problema: order_assignments não tinha unicidade; OS apareciam duplicadas no
-- painel do funcionário (até 3x a mesma atribuição aberta).

-- 1. Remove atribuições abertas duplicadas, mantendo a mais recente por (order_id, stage).
DELETE FROM public.order_assignments a
USING public.order_assignments b
WHERE a.completed_at IS NULL
  AND b.completed_at IS NULL
  AND a.order_id = b.order_id
  AND a.stage = b.stage
  AND (a.assigned_at, a.id) < (b.assigned_at, b.id);

-- 2. Impede novas duplicatas: uma OS só tem um responsável ativo por etapa.
CREATE UNIQUE INDEX IF NOT EXISTS uq_assignment_open
  ON public.order_assignments (order_id, stage)
  WHERE completed_at IS NULL;
