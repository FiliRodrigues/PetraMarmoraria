-- 011_multi_role_profiles.sql
-- Formaliza a migração de role (singular) para roles (array)
-- Necessário para que o schema seja reproduzível em ambiente local

-- 1. Adiciona coluna roles como array (se ainda não existir)
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS roles TEXT[] DEFAULT '{vendedor}'::text[];

-- 2. Migra dados existentes da coluna role para roles
UPDATE public.profiles
  SET roles = ARRAY[role]
  WHERE roles IS NULL AND role IS NOT NULL;

-- 3. Remove coluna role (singular) se existir
ALTER TABLE public.profiles
  DROP COLUMN IF EXISTS role;

-- 4. Atualiza funções que usavam role (singular)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND 'admin' = ANY(roles) AND active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN (SELECT roles[1] FROM public.profiles WHERE id = auth.uid() AND active = true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Índice GIN para busca eficiente por role
CREATE INDEX IF NOT EXISTS idx_profiles_roles ON public.profiles USING GIN(roles);

-- 6. Atualiza trigger handle_new_user para usar array
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role TEXT;
BEGIN
  v_role := NEW.raw_user_meta_data->>'role';
  IF v_role IS NULL OR v_role NOT IN ('admin','vendedor','cortador','montador','entregador') THEN
    v_role := 'vendedor';
  END IF;
  INSERT INTO public.profiles (id, email, name, roles, phone)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email), ARRAY[v_role], NULLIF(NEW.raw_user_meta_data->>'phone', ''));
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Atualiza trigger validate_assignment_role para usar array
CREATE OR REPLACE FUNCTION public.validate_assignment_role()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;
