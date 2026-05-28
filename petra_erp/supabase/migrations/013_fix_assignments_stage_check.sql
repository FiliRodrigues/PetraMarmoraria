-- Remove 'aprovado' do CHECK de order_assignments.stage
-- O código Dart só utiliza corte, montagem, entrega
-- Primeiro limpa dados existentes com stage inválido

DELETE FROM public.order_assignments WHERE stage = 'aprovado';

ALTER TABLE public.order_assignments
  DROP CONSTRAINT IF EXISTS order_assignments_stage_check;

ALTER TABLE public.order_assignments
  ADD CONSTRAINT order_assignments_stage_check
  CHECK (stage IN ('corte', 'montagem', 'entrega'));
