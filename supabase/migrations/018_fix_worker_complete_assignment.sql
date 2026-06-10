-- 018_fix_worker_complete_assignment.sql
-- Permite que o funcionário marque seu próprio assignment como concluído (completed_at).
-- O worker precisa atualizar APENAS completed_at do registro onde ele é o employee_id.
-- Isso fecha o bug crítico #1 onde montadores viam "Etapa concluída!" mas nada gravava.

DROP POLICY IF EXISTS "Worker can complete own assignment" ON public.order_assignments;
CREATE POLICY "Worker can complete own assignment" ON public.order_assignments
  FOR UPDATE TO authenticated
  USING (employee_id = auth.uid())
  WITH CHECK (employee_id = auth.uid());
