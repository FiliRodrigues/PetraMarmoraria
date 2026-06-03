-- 006d_admin_rpcs.sql
-- RECONCILIAÇÃO (A4): RPCs administrativas que existiam no banco mas não no repo.
-- A migration 007 faz ALTER/REVOKE nestas funções; sem este arquivo, um
-- provisionamento limpo quebraria em 007 ("função não existe").
-- Capturado fielmente do banco em 2026-06-02.
-- NOTA: o app cria funcionários via Edge Function create-employee (cria o auth
-- user). Estas RPCs são um caminho alternativo no banco; versionadas como estão.

-- Cria profile (sem auth user). Só admin.
CREATE OR REPLACE FUNCTION public.admin_create_employee(p_name text, p_roles text[], p_phone text DEFAULT NULL)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE v_id UUID;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Apenas administradores podem criar funcionários.';
  END IF;
  v_id := gen_random_uuid();
  INSERT INTO public.profiles (id, name, roles, phone, active, email)
  VALUES (v_id, p_name, p_roles, p_phone, true, NULL);
  RETURN v_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_update_employee(p_id uuid, p_name text, p_roles text[], p_phone text DEFAULT NULL, p_active boolean DEFAULT true)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Apenas administradores podem atualizar funcionários.';
  END IF;
  UPDATE public.profiles
  SET name = p_name, roles = p_roles, phone = p_phone, active = p_active
  WHERE id = p_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_set_profile_active_status(p_id uuid, p_active boolean)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Apenas administradores podem alterar status de funcionários.';
  END IF;
  UPDATE public.profiles SET active = p_active WHERE id = p_id;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_profiles_by_role(p_role text)
RETURNS SETOF public.profiles LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  RETURN QUERY
  SELECT * FROM public.profiles
  WHERE active = true AND p_role = ANY(roles)
  ORDER BY name ASC;
END;
$function$;

-- Usuário atualiza o próprio nome/telefone (não toca roles/active).
CREATE OR REPLACE FUNCTION public.update_own_profile(p_name text, p_phone text DEFAULT NULL)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  UPDATE public.profiles
  SET name = p_name, phone = p_phone
  WHERE id = auth.uid();
END;
$function$;

-- Permissões: só authenticated (revoga anon/public). 007/008 reforçam isso.
REVOKE EXECUTE ON FUNCTION public.admin_create_employee(text, text[], text)               FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.admin_update_employee(uuid, text, text[], text, boolean) FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.admin_set_profile_active_status(uuid, boolean)          FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_profiles_by_role(text)                              FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.update_own_profile(text, text)                          FROM anon, public;
GRANT  EXECUTE ON FUNCTION public.admin_create_employee(text, text[], text)               TO authenticated;
GRANT  EXECUTE ON FUNCTION public.admin_update_employee(uuid, text, text[], text, boolean) TO authenticated;
GRANT  EXECUTE ON FUNCTION public.admin_set_profile_active_status(uuid, boolean)          TO authenticated;
GRANT  EXECUTE ON FUNCTION public.get_profiles_by_role(text)                              TO authenticated;
GRANT  EXECUTE ON FUNCTION public.update_own_profile(text, text)                          TO authenticated;
