-- Migration 006: RPC functions and triggers

-- Trigger: auto-create profile on auth.users insert
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, roles, created_at)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'name', new.email),
    COALESCE(new.raw_user_meta_data->>'roles', '["vendedor"]')::jsonb::text[],
    new.created_at
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- RPC: get profiles by role
CREATE OR REPLACE FUNCTION public.get_profiles_by_role(p_role text)
RETURNS SETOF public.profiles AS $$
BEGIN
  RETURN QUERY SELECT * FROM public.profiles WHERE p_role = ANY(roles);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: admin create employee (insert into profiles only)
CREATE OR REPLACE FUNCTION public.admin_create_employee(
  p_name text,
  p_roles text[],
  p_phone text DEFAULT NULL
) RETURNS uuid AS $$
DECLARE
  v_id uuid;
BEGIN
  INSERT INTO public.profiles (name, roles, phone, active, created_at)
  VALUES (p_name, p_roles, p_phone, true, now())
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: admin update employee
CREATE OR REPLACE FUNCTION public.admin_update_employee(
  p_id uuid,
  p_name text,
  p_roles text[],
  p_phone text,
  p_active boolean
) RETURNS void AS $$
BEGIN
  UPDATE public.profiles SET name = p_name, roles = p_roles, phone = p_phone, active = p_active WHERE id = p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: admin set profile active status
CREATE OR REPLACE FUNCTION public.admin_set_profile_active_status(p_id uuid, p_active boolean)
RETURNS void AS $$
BEGIN
  UPDATE public.profiles SET active = p_active WHERE id = p_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: update own profile
CREATE OR REPLACE FUNCTION public.update_own_profile(p_name text, p_phone text)
RETURNS void AS $$
BEGIN
  UPDATE public.profiles SET name = p_name, phone = p_phone WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: check queue violation
CREATE OR REPLACE FUNCTION public.check_queue_violation(p_order_id uuid)
RETURNS TABLE(order_id uuid, display_number integer, bad_status text, expected_max_status text)
LANGUAGE sql SECURITY DEFINER AS $$
  WITH target AS (
    SELECT queue_position, status FROM public.service_orders WHERE id = p_order_id
  )
  SELECT o.id, o.display_number, o.status, t.status
  FROM public.service_orders o, target t
  WHERE o.id != p_order_id
    AND o.queue_position < t.queue_position
    AND o.status NOT IN ('orcamento', 'entrega')
    AND array_position(ARRAY['orcamento','aprovado','esperando_material','corte','montagem','entrega'], o.status) <
        array_position(ARRAY['orcamento','aprovado','esperando_material','corte','montagem','entrega'], t.status);
$$;

-- RPC: is admin helper
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND 'admin' = ANY(roles));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
