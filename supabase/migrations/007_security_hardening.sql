-- 007_security_hardening.sql
-- Hardening de segurança apontado pelo advisor do Supabase:
--   1. search_path imutável em todas as funções public.*
--   2. Revogar EXECUTE de anon (e authenticated quando não usado) nas SECURITY DEFINER
--   3. Endurecer RLS abertas (payments, stock_movements, status_history)

-- ============================================================
-- 1. search_path imutável
-- ============================================================
ALTER FUNCTION public.get_status_label(text)                                  SET search_path = public, pg_temp;
ALTER FUNCTION public.handle_new_user()                                       SET search_path = public, pg_temp;
ALTER FUNCTION public.update_updated_at_column()                              SET search_path = public, pg_temp;
ALTER FUNCTION public.handle_status_change()                                  SET search_path = public, pg_temp;
ALTER FUNCTION public.validate_os_status_transition()                         SET search_path = public, pg_temp;
ALTER FUNCTION public.is_admin()                                              SET search_path = public, pg_temp;
ALTER FUNCTION public.get_user_role()                                         SET search_path = public, pg_temp;
ALTER FUNCTION public.get_user_roles()                                        SET search_path = public, pg_temp;
ALTER FUNCTION public.validate_assignment_role()                              SET search_path = public, pg_temp;
ALTER FUNCTION public.check_queue_violation(uuid)                             SET search_path = public, pg_temp;
ALTER FUNCTION public.admin_create_employee(text, text[], text)               SET search_path = public, pg_temp;
ALTER FUNCTION public.admin_update_employee(uuid, text, text[], text, boolean) SET search_path = public, pg_temp;
ALTER FUNCTION public.admin_set_profile_active_status(uuid, boolean)          SET search_path = public, pg_temp;
ALTER FUNCTION public.get_profiles_by_role(text)                              SET search_path = public, pg_temp;
ALTER FUNCTION public.auto_create_receivable()                                SET search_path = public, pg_temp;
ALTER FUNCTION public.get_reports_summary(integer, integer)                   SET search_path = public, pg_temp;
ALTER FUNCTION public.update_own_profile(text, text)                          SET search_path = public, pg_temp;
ALTER FUNCTION public.rls_auto_enable()                                       SET search_path = pg_catalog, pg_temp;

-- ============================================================
-- 2. Revogar EXECUTE público (anon) das SECURITY DEFINER.
--    is_admin / get_user_role / get_user_roles são usadas em policies RLS,
--    então DEVEM permanecer executáveis por authenticated (revoga só anon/public).
--    admin_* / get_profiles_by_role / update_own_profile são chamadas pelo app
--    autenticado via RPC (revoga só anon/public).
--    Triggers e utilitário (handle_new_user / auto_create_receivable /
--    rls_auto_enable) não são chamados via API: revoga de anon E authenticated.
-- ============================================================
REVOKE EXECUTE ON FUNCTION public.is_admin()                                              FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_user_role()                                         FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_user_roles()                                        FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.admin_create_employee(text, text[], text)               FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.admin_update_employee(uuid, text, text[], text, boolean) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.admin_set_profile_active_status(uuid, boolean)          FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_profiles_by_role(text)                              FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.update_own_profile(text, text)                          FROM anon, public;

REVOKE EXECUTE ON FUNCTION public.handle_new_user()        FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.auto_create_receivable() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.rls_auto_enable()        FROM anon, authenticated, public;

-- Garante que o app autenticado mantém acesso ao que precisa.
GRANT EXECUTE ON FUNCTION public.is_admin()                                              TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_role()                                         TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_roles()                                        TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_create_employee(text, text[], text)               TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_update_employee(uuid, text, text[], text, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_set_profile_active_status(uuid, boolean)          TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_profiles_by_role(text)                              TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_own_profile(text, text)                          TO authenticated;

-- ============================================================
-- 3. Endurecer RLS abertas (substituir USING/WITH CHECK (true))
-- ============================================================
DROP POLICY IF EXISTS "All authenticated can manage payments" ON public.payments;
CREATE POLICY "Admin and Vendedor can manage payments" ON public.payments
  FOR ALL TO authenticated
  USING (is_admin() OR get_user_role() = 'vendedor')
  WITH CHECK (is_admin() OR get_user_role() = 'vendedor');

DROP POLICY IF EXISTS "All authenticated can manage stock movements" ON public.stock_movements;
CREATE POLICY "Admin and Vendedor can manage stock movements" ON public.stock_movements
  FOR ALL TO authenticated
  USING (is_admin() OR get_user_role() = 'vendedor')
  WITH CHECK (is_admin() OR get_user_role() = 'vendedor');

DROP POLICY IF EXISTS "All authenticated users can record status changes" ON public.status_history;
CREATE POLICY "Authenticated users can record own status changes" ON public.status_history
  FOR INSERT TO authenticated
  WITH CHECK (changed_by = auth.uid());
