-- 008b_rls_assignments_insert.sql
-- Permite que qualquer usuário autenticado insira assignments (atribuição de etapas).
-- Reconciliação: aplicada em produção mas ausente do repo. Capturada do banco em 2026-06-10.

CREATE POLICY "All authenticated users can insert assignments" ON public.order_assignments
  FOR INSERT TO authenticated
  WITH CHECK (true);
