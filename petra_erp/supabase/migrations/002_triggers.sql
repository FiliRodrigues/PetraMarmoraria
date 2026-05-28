-- 002_triggers.sql
-- Database triggers and functions for business logic validation and updates

-- 1. Trigger function: Auto-create profile when a new user registers in Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  v_role TEXT;
BEGIN
  v_role := NEW.raw_user_meta_data->>'role';
  -- Safe fallback and validation for the role enum
  IF v_role IS NULL OR v_role NOT IN ('admin', 'vendedor', 'cortador', 'montador', 'entregador') THEN
    v_role := 'vendedor';
  END IF;

  INSERT INTO public.profiles (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    v_role
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- 2. Trigger function: Auto-update updated_at timestamp columns
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER update_customers_updated_at
  BEFORE UPDATE ON public.customers
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


-- 3. Trigger function: Auto-update status_changed_at when service order status changes
CREATE OR REPLACE FUNCTION public.handle_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    NEW.status_changed_at = now();
    NEW.updated_at = now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER on_os_status_change
  BEFORE UPDATE ON public.service_orders
  FOR EACH ROW EXECUTE FUNCTION public.handle_status_change();


-- 4. Trigger function: Enforce status transitions rules
-- OS only advances/recudes 1 step - never skips
CREATE OR REPLACE FUNCTION public.validate_os_status_transition()
RETURNS TRIGGER AS $$
DECLARE
  v_old_idx INT;
  v_new_idx INT;
  v_status_list TEXT[] := ARRAY['orcamento', 'aprovado', 'esperando_material', 'corte', 'montagem', 'entrega'];
BEGIN
  -- If status hasn't changed, allow it
  IF OLD.status IS NOT DISTINCT FROM NEW.status THEN
    RETURN NEW;
  END IF;

  -- Find indices (1-based in Postgres arrays)
  v_old_idx := array_position(v_status_list, OLD.status);
  v_new_idx := array_position(v_status_list, NEW.status);

  -- If old status or new status is not in the list, raise error
  IF v_old_idx IS NULL OR v_new_idx IS NULL THEN
    RAISE EXCEPTION 'Status inválido: % -> %', OLD.status, NEW.status;
  END IF;

  -- Rule: can only advance 1 step or retrocede 1 step
  IF abs(v_new_idx - v_old_idx) > 1 THEN
    RAISE EXCEPTION 'Transição de status inválida de % para %. É permitido apenas avançar ou recuar uma etapa por vez.', OLD.status, NEW.status;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER enforce_os_status_transition
  BEFORE UPDATE OF status ON public.service_orders
  FOR EACH ROW EXECUTE FUNCTION public.validate_os_status_transition();


-- 5. Trigger function: Enforce stage assignment employee role constraints
-- corte -> cortador, montagem -> montador, entrega -> entregador
CREATE OR REPLACE FUNCTION public.validate_assignment_role()
RETURNS TRIGGER AS $$
DECLARE
  v_employee_role TEXT;
  v_required_role TEXT;
BEGIN
  -- Get the employee's role
  SELECT role INTO v_employee_role
  FROM public.profiles
  WHERE id = NEW.employee_id;

  -- Determine the required role based on the stage
  v_required_role := CASE NEW.stage
    WHEN 'corte' THEN 'cortador'
    WHEN 'montagem' THEN 'montador'
    WHEN 'entrega' THEN 'entregador'
    ELSE NULL
  END;

  -- Verify role compatibility
  IF v_employee_role IS DISTINCT FROM v_required_role THEN
    RAISE EXCEPTION 'Funcionário com papel "%" não pode ser atribuído à etapa "%". Papel exigido: "%".',
      COALESCE(v_employee_role, 'Nenhum'), NEW.stage, COALESCE(v_required_role, 'Nenhum');
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER enforce_assignment_role
  BEFORE INSERT OR UPDATE ON public.order_assignments
  FOR EACH ROW EXECUTE FUNCTION public.validate_assignment_role();
