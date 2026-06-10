-- 019_hardening_select_financeiro.sql
-- Remove políticas SELECT=true das tabelas financeiras.
-- Trabalhadores de produção (montador, etc.) não devem ver dados financeiros.
-- Tabelas operacionais (customers, products, service_orders, order_assignments,
-- status_history, company_info) mantêm SELECT amplo — necessárias para o trabalho.

-- accounts_payable: restringir SELECT a admin+vendedor
DROP POLICY IF EXISTS "All authenticated can view payables" ON public.accounts_payable;
DROP POLICY IF EXISTS "Admin and Vendedor can manage payables" ON public.accounts_payable;
CREATE POLICY "Admin and Vendedor can manage payables" ON public.accounts_payable
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

-- accounts_receivable: restringir SELECT a admin+vendedor
DROP POLICY IF EXISTS "All authenticated can view receivables" ON public.accounts_receivable;
DROP POLICY IF EXISTS "Admin and Vendedor can manage receivables" ON public.accounts_receivable;
CREATE POLICY "Admin and Vendedor can manage receivables" ON public.accounts_receivable
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

-- cost_centers: restringir SELECT a admin+vendedor
DROP POLICY IF EXISTS "All authenticated users can view cost centers" ON public.cost_centers;
DROP POLICY IF EXISTS "Admin and Vendedor can manage cost centers" ON public.cost_centers;
CREATE POLICY "Admin and Vendedor can manage cost centers" ON public.cost_centers
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

-- financial_categories: restringir SELECT a admin+vendedor
DROP POLICY IF EXISTS "All authenticated users can view financial categories" ON public.financial_categories;
DROP POLICY IF EXISTS "Admin can manage financial categories" ON public.financial_categories;
CREATE POLICY "Admin can manage financial categories" ON public.financial_categories
  FOR ALL TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- suppliers: restringir SELECT a admin+vendedor
DROP POLICY IF EXISTS "All authenticated users can view suppliers" ON public.suppliers;
DROP POLICY IF EXISTS "Admin and Vendedor can manage suppliers" ON public.suppliers;
CREATE POLICY "Admin and Vendedor can manage suppliers" ON public.suppliers
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));
