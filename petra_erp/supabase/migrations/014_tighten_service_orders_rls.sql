-- Substitui políticas permissivas de service_orders por regras por role
-- Antes: INSERT/UPDATE com USING(true) para qualquer autenticado
-- Depois: admin/vendedor podem tudo, outros roles só SELECT

DROP POLICY IF EXISTS "All authenticated users can create service orders" ON public.service_orders;
DROP POLICY IF EXISTS "All authenticated users can update service orders" ON public.service_orders;

CREATE POLICY "Admin and Vendedor can manage service orders" ON public.service_orders
  FOR INSERT TO authenticated
  WITH CHECK (public.is_admin() OR public.get_user_role() = 'vendedor');

CREATE POLICY "Admin and Vendedor can update service orders" ON public.service_orders
  FOR UPDATE TO authenticated
  USING (public.is_admin() OR public.get_user_role() = 'vendedor')
  WITH CHECK (public.is_admin() OR public.get_user_role() = 'vendedor');
