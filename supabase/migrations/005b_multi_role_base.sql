-- 005b_multi_role_base.sql
-- RECONCILIAÇÃO (A4): estabelece o modelo multi-role que estava no banco de
-- produção (Petra / prxkfifwuygtlynozdqx) mas não no repo. DEVE rodar antes de
-- qualquer migration que use get_user_roles()/is_admin() no formato array
-- (006c, 006d, 007, 011, 012). Capturado do banco real em 2026-06-02. Idempotente.

-- ============================================================
-- 1. profiles.roles (array) substitui a antiga `role` (singular).
-- ============================================================
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS roles text[] NOT NULL DEFAULT '{vendedor}'::text[];
-- Migra dados de role -> roles e remove a coluna antiga + dependências dela
-- (índice idx_profiles_role do 001 e a policy de update do 003 que referenciava
-- `role`). A policy de profiles é recriada no 012 já no formato multi-role.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns
             WHERE table_schema='public' AND table_name='profiles' AND column_name='role') THEN
    UPDATE public.profiles SET roles = ARRAY[role]
      WHERE role IS NOT NULL AND (roles IS NULL OR roles = '{vendedor}'::text[]);
    DROP POLICY IF EXISTS "Users can update own profile fields" ON public.profiles;
    DROP INDEX IF EXISTS public.idx_profiles_role;
    ALTER TABLE public.profiles DROP COLUMN role CASCADE;
  END IF;
END $$;

-- ============================================================
-- 2. Helpers de autorização lendo o array `roles`.
-- ============================================================
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND 'admin' = ANY(roles) AND active = true
  );
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  RETURN (SELECT roles[1] FROM public.profiles WHERE id = auth.uid() AND active = true);
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_user_roles()
RETURNS text[]
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  RETURN (SELECT roles FROM public.profiles WHERE id = auth.uid() AND active = true);
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.is_admin()        FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_user_role()   FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_user_roles()  FROM anon, public;
GRANT  EXECUTE ON FUNCTION public.is_admin()        TO authenticated;
GRANT  EXECUTE ON FUNCTION public.get_user_role()   TO authenticated;
GRANT  EXECUTE ON FUNCTION public.get_user_roles()  TO authenticated;

-- ============================================================
-- 3. validate_assignment_role lê o array `roles` do funcionário.
-- ============================================================
CREATE OR REPLACE FUNCTION public.validate_assignment_role()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_employee_roles TEXT[];
  v_required_role TEXT;
BEGIN
  SELECT roles INTO v_employee_roles FROM public.profiles WHERE id = NEW.employee_id;
  v_required_role := CASE NEW.stage
    WHEN 'corte' THEN 'cortador'
    WHEN 'montagem' THEN 'montador'
    WHEN 'entrega' THEN 'entregador'
    ELSE NULL
  END;
  IF v_employee_roles IS NULL OR NOT (v_required_role = ANY(v_employee_roles)) THEN
    RAISE EXCEPTION 'Funcionário não possui o papel "%" exigido para a etapa "%".',
      COALESCE(v_required_role, 'Nenhum'), NEW.stage;
  END IF;
  RETURN NEW;
END;
$function$;
