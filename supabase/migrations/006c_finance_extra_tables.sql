-- 006c_finance_extra_tables.sql
-- RECONCILIAÇÃO (A4): tabelas, funções e triggers que existiam no banco de
-- produção (Petra / prxkfifwuygtlynozdqx) mas nunca foram versionadas no repo.
-- Sem este arquivo, um provisionamento limpo a partir das migrations não teria
-- company_info / suppliers / accounts_payable / accounts_receivable, e as
-- migrations 007+ falhariam ao referenciar funções inexistentes.
-- Capturado fielmente do banco em 2026-06-02. Idempotente.

-- ============================================================
-- 1. company_info (singleton id=1)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.company_info (
  id                          integer PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  name                        text NOT NULL DEFAULT '',
  cnpj                        text,
  address                     text,
  phone                       text,
  email                       text,
  logo_url                    text,
  default_deadline_days       integer DEFAULT 15,
  default_payment_terms_days  integer DEFAULT 30,
  updated_at                  timestamptz DEFAULT now()
);
INSERT INTO public.company_info (id, name) VALUES (1, '') ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 2. suppliers
-- ============================================================
CREATE TABLE IF NOT EXISTS public.suppliers (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  cnpj            text UNIQUE,
  phone           text NOT NULL,
  phone2          text,
  email           text,
  contact_person  text,
  address         text,
  city            text,
  state           text DEFAULT 'SP',
  notes           text,
  active          boolean DEFAULT true,
  created_at      timestamptz DEFAULT now(),
  updated_at      timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_suppliers_name ON public.suppliers USING btree (name);

-- ============================================================
-- 3. accounts_payable
-- ============================================================
CREATE TABLE IF NOT EXISTS public.accounts_payable (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id  uuid NOT NULL REFERENCES public.suppliers(id),
  description  text NOT NULL,
  amount       numeric NOT NULL DEFAULT 0.00,
  due_date     date NOT NULL,
  paid_at      timestamptz,
  paid_amount  numeric,
  category     text,
  notes        text,
  created_at   timestamptz DEFAULT now(),
  updated_at   timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_accounts_payable_due_date ON public.accounts_payable USING btree (due_date);

-- ============================================================
-- 4. accounts_receivable
-- ============================================================
CREATE TABLE IF NOT EXISTS public.accounts_receivable (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id       uuid NOT NULL REFERENCES public.customers(id),
  service_order_id  uuid REFERENCES public.service_orders(id),
  description       text NOT NULL,
  amount            numeric NOT NULL DEFAULT 0.00,
  due_date          date NOT NULL,
  received_at       timestamptz,
  received_amount   numeric,
  notes             text,
  created_at        timestamptz DEFAULT now(),
  updated_at        timestamptz DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_accounts_receivable_due_date ON public.accounts_receivable USING btree (due_date);
CREATE INDEX IF NOT EXISTS idx_accounts_receivable_order_id ON public.accounts_receivable USING btree (service_order_id);

-- ============================================================
-- 5. RLS — leitura para todos autenticados; escrita admin/vendedor.
--    company_info: só admin escreve. (Já no formato multi-role corrigido.)
-- ============================================================
ALTER TABLE public.company_info        ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts_payable    ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts_receivable ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "All authenticated users can view company info" ON public.company_info;
CREATE POLICY "All authenticated users can view company info" ON public.company_info
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Only admin can update company info" ON public.company_info;
CREATE POLICY "Only admin can update company info" ON public.company_info
  FOR UPDATE TO authenticated USING (is_admin()) WITH CHECK (is_admin());

DROP POLICY IF EXISTS "All authenticated users can view suppliers" ON public.suppliers;
CREATE POLICY "All authenticated users can view suppliers" ON public.suppliers
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Admin and Vendedor can manage suppliers" ON public.suppliers;
CREATE POLICY "Admin and Vendedor can manage suppliers" ON public.suppliers
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

DROP POLICY IF EXISTS "All authenticated can view payables" ON public.accounts_payable;
CREATE POLICY "All authenticated can view payables" ON public.accounts_payable
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Admin and Vendedor can manage payables" ON public.accounts_payable;
CREATE POLICY "Admin and Vendedor can manage payables" ON public.accounts_payable
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

DROP POLICY IF EXISTS "All authenticated can view receivables" ON public.accounts_receivable;
CREATE POLICY "All authenticated can view receivables" ON public.accounts_receivable
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "Admin and Vendedor can manage receivables" ON public.accounts_receivable;
CREATE POLICY "Admin and Vendedor can manage receivables" ON public.accounts_receivable
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

-- ============================================================
-- 6. Funções de relatório / assignments / receivable automático.
--    (get_status_label já é criada em 004_fura_fila.sql.)
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_order_assignments(p_order_id uuid)
RETURNS TABLE(id uuid, order_id uuid, stage text, employee_id uuid, assigned_at timestamptz, completed_at timestamptz, notes text, employee_name text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  RETURN QUERY
  SELECT oa.id, oa.order_id, oa.stage, oa.employee_id, oa.assigned_at, oa.completed_at, oa.notes, p.name::text
  FROM public.order_assignments oa
  LEFT JOIN public.profiles p ON p.id = oa.employee_id
  WHERE oa.order_id = p_order_id
  ORDER BY oa.assigned_at ASC;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_all_order_assignments(p_from timestamptz DEFAULT NULL, p_to timestamptz DEFAULT NULL)
RETURNS TABLE(id uuid, order_id uuid, stage text, employee_id uuid, assigned_at timestamptz, completed_at timestamptz, notes text, employee_name text)
LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  RETURN QUERY
  SELECT oa.id, oa.order_id, oa.stage, oa.employee_id, oa.assigned_at, oa.completed_at, oa.notes, p.name::text
  FROM public.order_assignments oa
  LEFT JOIN public.profiles p ON p.id = oa.employee_id
  WHERE (p_from IS NULL OR oa.assigned_at >= p_from)
    AND (p_to IS NULL OR oa.assigned_at <= p_to)
  ORDER BY oa.assigned_at DESC;
END;
$function$;

CREATE OR REPLACE FUNCTION public.get_reports_summary(p_month integer, p_year integer)
RETURNS TABLE(total_created integer, total_delivered integer, total_quoted numeric, on_time integer, overdue integer, in_progress integer)
LANGUAGE plpgsql STABLE SET search_path TO 'public', 'pg_temp'
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    COUNT(*) FILTER (WHERE EXTRACT(MONTH FROM created_at) = p_month AND EXTRACT(YEAR FROM created_at) = p_year)::INT,
    COUNT(*) FILTER (WHERE status = 'entrega' AND EXTRACT(MONTH FROM updated_at) = p_month AND EXTRACT(YEAR FROM updated_at) = p_year)::INT,
    COALESCE(SUM(total_value) FILTER (WHERE EXTRACT(MONTH FROM created_at) = p_month AND EXTRACT(YEAR FROM created_at) = p_year), 0),
    COUNT(*) FILTER (WHERE status = 'entrega' AND scheduled_date IS NOT NULL AND scheduled_date >= updated_at::date)::INT,
    COUNT(*) FILTER (WHERE status != 'entrega' AND scheduled_date IS NOT NULL AND scheduled_date < CURRENT_DATE)::INT,
    COUNT(*) FILTER (WHERE status != 'entrega')::INT
  FROM public.service_orders;
END;
$function$;

-- Gera um recebível ao mover a OS para 'entrega'.
CREATE OR REPLACE FUNCTION public.auto_create_receivable()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_terms INT;
BEGIN
  IF NEW.status = 'entrega' AND (OLD.status IS DISTINCT FROM 'entrega') THEN
    SELECT COALESCE(default_payment_terms_days, 30) INTO v_terms
    FROM public.company_info WHERE id = 1;
    INSERT INTO public.accounts_receivable (customer_id, service_order_id, description, amount, due_date)
    VALUES (
      NEW.customer_id, NEW.id,
      'OS #' || NEW.display_number || ' - ' || COALESCE(NEW.description, ''),
      NEW.total_value, CURRENT_DATE + v_terms
    )
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.get_order_assignments(uuid)                         FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.get_all_order_assignments(timestamptz, timestamptz)  FROM anon, public;
REVOKE EXECUTE ON FUNCTION public.auto_create_receivable()                             FROM anon, authenticated, public;
GRANT  EXECUTE ON FUNCTION public.get_order_assignments(uuid)                          TO authenticated;
GRANT  EXECUTE ON FUNCTION public.get_all_order_assignments(timestamptz, timestamptz)  TO authenticated;
GRANT  EXECUTE ON FUNCTION public.get_reports_summary(integer, integer)                TO authenticated;

-- ============================================================
-- 7. Trigger que cria o recebível na entrega.
-- ============================================================
DROP TRIGGER IF EXISTS trg_auto_create_receivable ON public.service_orders;
CREATE TRIGGER trg_auto_create_receivable
  AFTER UPDATE ON public.service_orders
  FOR EACH ROW EXECUTE FUNCTION public.auto_create_receivable();
