-- 015_fix_old_permissive_rls.sql
-- Remove policies permissivas da migration 003 que nunca foram droppadas.
-- As policies restritivas (Admin and Vendedor) foram criadas na 011 mas com
-- nomes diferentes, entrando em conflito com as antigas via OR do RLS.
-- Resultado: qualquer authenticated (incluindo workers de produção) podia
-- criar/alterar OS diretamente via API.

-- ============================================================
-- 1. service_orders: remover policies abertas da 003
-- ============================================================
DROP POLICY IF EXISTS "All authenticated users can update service orders"
  ON public.service_orders;

DROP POLICY IF EXISTS "All authenticated users can create service orders"
  ON public.service_orders;

-- ============================================================
-- 2. Reforço: garantir que só admin ou vendedor podem criar OS
--    (a policy "Admin and Vendedor can manage service orders"
--     da 011 já cobre INSERT, mas o nome é estranho — INSERT
--     com nome "manage". Dropar e recriar com nome claro.)
-- ============================================================
DROP POLICY IF EXISTS "Admin and Vendedor can manage service orders"
  ON public.service_orders;

CREATE POLICY "Admin and Vendedor can insert service orders"
  ON public.service_orders
  FOR INSERT TO authenticated
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

-- ============================================================
-- 3. Verificação: garantir que a policy restritiva de UPDATE
--    tem nome canônico e não tem duplicata.
-- ============================================================
DROP POLICY IF EXISTS "Admin and Vendedor can update service orders"
  ON public.service_orders;

CREATE POLICY "Admin and Vendedor can update service orders"
  ON public.service_orders
  FOR UPDATE TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

-- ============================================================
-- 4. Garantir que DELETE mantém só admin (reforço idempotente)
-- ============================================================
DROP POLICY IF EXISTS "Only admin can delete service orders"
  ON public.service_orders;

CREATE POLICY "Only admin can delete service orders"
  ON public.service_orders
  FOR DELETE TO authenticated
  USING (is_admin());
