-- 011_security_audit_fixes.sql
-- Correções da auditoria pré-release (C1, C2, A1, A3, M1, M4).
-- Aplicada no banco em 2026-06-02. Pressupõe o estado multi-role já presente
-- (ver 010b_db_state_multi_role_finance.sql).

-- ============================================================
-- C1. order_assignments: remover policy de INSERT aberta que
--     sobrepunha (OR) a policy restrita "Admin and Vendedor".
-- ============================================================
DROP POLICY IF EXISTS "All authenticated users can insert assignments" ON public.order_assignments;

-- ============================================================
-- A1. Autorização multi-role: usar get_user_roles() (array) em vez de
--     get_user_role() (que retorna só roles[1]).
-- ============================================================
DROP POLICY IF EXISTS "Admin and Vendedor can update service orders" ON public.service_orders;
CREATE POLICY "Admin and Vendedor can update service orders" ON public.service_orders
  FOR UPDATE TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

DROP POLICY IF EXISTS "Admin and Vendedor can manage service orders" ON public.service_orders;
CREATE POLICY "Admin and Vendedor can manage service orders" ON public.service_orders
  FOR INSERT TO authenticated
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

DROP POLICY IF EXISTS "Admin and Vendedor can manage payments" ON public.payments;
CREATE POLICY "Admin and Vendedor can manage payments" ON public.payments
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

DROP POLICY IF EXISTS "Admin and Vendedor can manage stock movements" ON public.stock_movements;
CREATE POLICY "Admin and Vendedor can manage stock movements" ON public.stock_movements
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

DROP POLICY IF EXISTS "Admin and Vendedor can manage customers" ON public.customers;
CREATE POLICY "Admin and Vendedor can manage customers" ON public.customers
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

DROP POLICY IF EXISTS "Admin and Vendedor can manage products" ON public.products;
CREATE POLICY "Admin and Vendedor can manage products" ON public.products
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

-- ============================================================
-- C2 + M4. Revogar EXECUTE de anon/public nas funções SECURITY DEFINER de
--     assignments (fazem bypass de RLS) e fixar search_path.
-- ============================================================
REVOKE EXECUTE ON FUNCTION public.get_order_assignments(uuid)                                FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_all_order_assignments(timestamptz, timestamptz)        FROM anon, public;
GRANT  EXECUTE ON FUNCTION public.get_order_assignments(uuid)                                TO authenticated;
GRANT  EXECUTE ON FUNCTION public.get_all_order_assignments(timestamptz, timestamptz)        TO authenticated;

ALTER FUNCTION public.get_order_assignments(uuid)                         SET search_path = public, pg_temp;
ALTER FUNCTION public.get_all_order_assignments(timestamptz, timestamptz) SET search_path = public, pg_temp;
ALTER FUNCTION public.validate_os_status_transition()                     SET search_path = public, pg_temp;

-- ============================================================
-- A3. Bucket assets: remover policy de listagem ampla.
--     Objetos públicos seguem acessíveis por URL direta.
-- ============================================================
DROP POLICY IF EXISTS "assets_public_read" ON storage.objects;
CREATE POLICY "assets_public_object_read" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'assets' AND name IS NOT NULL);

-- ============================================================
-- M1. register_stock_movement: não mascarar saída maior que o saldo;
--     falhar explicitamente para manter histórico consistente com o saldo.
-- ============================================================
CREATE OR REPLACE FUNCTION public.register_stock_movement(
  p_product_id uuid, p_type text, p_quantity numeric,
  p_reason text DEFAULT NULL, p_order_id uuid DEFAULT NULL, p_created_by uuid DEFAULT NULL)
RETURNS void
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_current numeric; v_new numeric;
BEGIN
  SELECT stock_quantity INTO v_current FROM products WHERE id = p_product_id FOR UPDATE;
  IF p_quantity < 0 THEN
    RAISE EXCEPTION 'Quantidade não pode ser negativa';
  END IF;
  CASE p_type
    WHEN 'entrada' THEN v_new := v_current + p_quantity;
    WHEN 'saida'   THEN
      v_new := v_current - p_quantity;
      IF v_new < 0 THEN
        RAISE EXCEPTION 'Estoque insuficiente: saldo % menor que saída %', v_current, p_quantity;
      END IF;
    WHEN 'ajuste'  THEN
      v_new := p_quantity;
    ELSE
      RAISE EXCEPTION 'Tipo de movimento inválido: %', p_type;
  END CASE;
  INSERT INTO stock_movements (product_id, type, quantity, reason, order_id, created_by)
  VALUES (p_product_id, p_type, p_quantity, p_reason, p_order_id, p_created_by);
  UPDATE products SET stock_quantity = v_new WHERE id = p_product_id;
END;
$function$;
