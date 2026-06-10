-- 006b_stock_fn_search_path.sql
-- Fixa o search_path da função de movimentação de estoque (hardening de SECURITY DEFINER).
-- Reconciliação: aplicada em produção mas ausente do repo. Capturada do banco em 2026-06-10.

ALTER FUNCTION public.register_stock_movement(uuid, text, numeric, text, uuid, uuid)
  SET search_path = public, pg_temp;
