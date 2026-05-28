-- 010_fix_roles_and_schema.sql
-- Corrige CHECK constraint de service_orders removendo 'recebido'
-- Cria RPCs para gerenciamento de funcionários via admin
-- Nota: roles ARRAY e FK já estavam corretos no banco

-- 1. Corrigir CHECK constraint de service_orders removendo 'recebido'
ALTER TABLE public.service_orders
  DROP CONSTRAINT IF EXISTS service_orders_status_check;

ALTER TABLE public.service_orders
  ADD CONSTRAINT service_orders_status_check
  CHECK (status IN ('orcamento','aprovado','esperando_material','corte','montagem','entrega'));

-- 2. RPC admin_create_employee
CREATE OR REPLACE FUNCTION public.admin_create_employee(
  p_name TEXT,
  p_roles TEXT[],
  p_phone TEXT DEFAULT NULL
) RETURNS UUID AS $$
DECLARE
  v_id UUID;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Apenas administradores podem criar funcionários.';
  END IF;
  v_id := gen_random_uuid();
  INSERT INTO public.profiles (id, name, roles, phone, active, email)
  VALUES (v_id, p_name, p_roles, p_phone, true, NULL);
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. RPC admin_update_employee
CREATE OR REPLACE FUNCTION public.admin_update_employee(
  p_id UUID,
  p_name TEXT,
  p_roles TEXT[],
  p_phone TEXT DEFAULT NULL,
  p_active BOOLEAN DEFAULT true
) RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Apenas administradores podem atualizar funcionários.';
  END IF;
  UPDATE public.profiles
  SET name = p_name, roles = p_roles, phone = p_phone, active = p_active
  WHERE id = p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. RPC admin_set_profile_active_status
CREATE OR REPLACE FUNCTION public.admin_set_profile_active_status(
  p_id UUID,
  p_active BOOLEAN
) RETURNS VOID AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Apenas administradores podem alterar status de funcionários.';
  END IF;
  UPDATE public.profiles SET active = p_active WHERE id = p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. RPC get_profiles_by_role
CREATE OR REPLACE FUNCTION public.get_profiles_by_role(p_role TEXT)
RETURNS SETOF public.profiles AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM public.profiles
  WHERE active = true AND p_role = ANY(roles)
  ORDER BY name ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
