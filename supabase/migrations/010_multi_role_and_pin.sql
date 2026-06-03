-- 010_multi_role_and_pin.sql
-- Login por PIN para funcionários de produção (cortador/montador/entregador).
-- Os funcionários continuam sendo profiles/auth users (RLS, order_assignments e
-- triggers inalterados); só escondemos email/senha atrás de credenciais geradas + PIN.
-- A coluna `roles text[]` e os helpers (is_admin, validate_assignment_role) já leem array.

-- 1. Colunas de PIN em profiles (aditivo / idempotente)
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pin_hash text;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS pin_set boolean NOT NULL DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS failed_attempts int NOT NULL DEFAULT 0;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS blocked boolean NOT NULL DEFAULT false;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS login_mode text NOT NULL DEFAULT 'email';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'profiles_login_mode_check'
  ) THEN
    ALTER TABLE public.profiles
      ADD CONSTRAINT profiles_login_mode_check CHECK (login_mode IN ('email', 'pin'));
  END IF;
END $$;

-- 2. Corrige handle_new_user: respeitar o array `roles` e `login_mode` vindos do
--    user_metadata (o create-employee envia `roles`, mas o trigger só lia `role`
--    singular e caía sempre em ['vendedor']).
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_roles text[];
  v_login_mode text;
BEGIN
  IF NEW.raw_user_meta_data ? 'roles'
     AND jsonb_typeof(NEW.raw_user_meta_data->'roles') = 'array'
     AND jsonb_array_length(NEW.raw_user_meta_data->'roles') > 0 THEN
    SELECT array_agg(value) INTO v_roles
    FROM jsonb_array_elements_text(NEW.raw_user_meta_data->'roles') AS value;
  ELSIF NEW.raw_user_meta_data->>'role' IS NOT NULL THEN
    v_roles := ARRAY[NEW.raw_user_meta_data->>'role'];
  ELSE
    v_roles := ARRAY['vendedor'];
  END IF;

  -- Mantém só papéis válidos; se sobrar vazio, cai em vendedor.
  SELECT array_agg(r) INTO v_roles
  FROM unnest(v_roles) AS r
  WHERE r IN ('admin', 'vendedor', 'cortador', 'montador', 'entregador');
  IF v_roles IS NULL OR array_length(v_roles, 1) IS NULL THEN
    v_roles := ARRAY['vendedor'];
  END IF;

  v_login_mode := COALESCE(NULLIF(NEW.raw_user_meta_data->>'login_mode', ''), 'email');
  IF v_login_mode NOT IN ('email', 'pin') THEN
    v_login_mode := 'email';
  END IF;

  INSERT INTO public.profiles (id, email, name, roles, phone, login_mode)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    v_roles,
    NULLIF(NEW.raw_user_meta_data->>'phone', ''),
    v_login_mode
  );
  RETURN NEW;
END;
$function$;
