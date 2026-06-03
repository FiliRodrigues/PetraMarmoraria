-- 012_fix_profile_escalation_and_finance_roles.sql
-- Aplicada no banco em 2026-06-02.
-- C4 (CRÍTICO): a policy de UPDATE em profiles travava a antiga coluna `role`
--   (singular). Com a migração para `roles text[]`, essa trava se perdeu e
--   qualquer usuário podia se auto-promover a admin via UPDATE no próprio perfil.
-- A1 (resto): accounts_payable/accounts_receivable/suppliers ainda usavam
--   get_user_role() (= roles[1]); padronizar para 'vendedor' = ANY(get_user_roles()).

-- ============================================================
-- C4. Bloquear auto-escalação: usuário não pode alterar os próprios `roles`,
--     `active`, `blocked` nem `login_mode`. Admin mantém acesso total pela
--     policy "Admin has full access to profiles".
-- ============================================================
DROP POLICY IF EXISTS "Users can update own profile fields" ON public.profiles;
CREATE POLICY "Users can update own profile fields" ON public.profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND roles      = (SELECT roles      FROM public.profiles WHERE id = auth.uid())
    AND active     = (SELECT active     FROM public.profiles WHERE id = auth.uid())
    AND blocked    = (SELECT blocked    FROM public.profiles WHERE id = auth.uid())
    AND login_mode = (SELECT login_mode FROM public.profiles WHERE id = auth.uid())
  );

-- ============================================================
-- A1 (resto). Padronizar autorização multi-role nas tabelas financeiras.
-- ============================================================
DROP POLICY IF EXISTS "Admin and Vendedor can manage payables" ON public.accounts_payable;
CREATE POLICY "Admin and Vendedor can manage payables" ON public.accounts_payable
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

DROP POLICY IF EXISTS "Admin and Vendedor can manage receivables" ON public.accounts_receivable;
CREATE POLICY "Admin and Vendedor can manage receivables" ON public.accounts_receivable
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

DROP POLICY IF EXISTS "Admin and Vendedor can manage suppliers" ON public.suppliers;
CREATE POLICY "Admin and Vendedor can manage suppliers" ON public.suppliers
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));
