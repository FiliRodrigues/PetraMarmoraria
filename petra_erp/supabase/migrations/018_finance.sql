CREATE TABLE IF NOT EXISTS public.accounts_payable (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id UUID NOT NULL REFERENCES public.suppliers(id) ON DELETE RESTRICT,
  description TEXT NOT NULL,
  amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  due_date DATE NOT NULL,
  paid_at TIMESTAMPTZ,
  paid_amount DECIMAL(12,2),
  category TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.accounts_receivable (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,
  service_order_id UUID REFERENCES public.service_orders(id) ON DELETE SET NULL,
  description TEXT NOT NULL,
  amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  due_date DATE NOT NULL,
  received_at TIMESTAMPTZ,
  received_amount DECIMAL(12,2),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_accounts_payable_due_date ON public.accounts_payable(due_date);
CREATE INDEX IF NOT EXISTS idx_accounts_receivable_due_date ON public.accounts_receivable(due_date);
CREATE INDEX IF NOT EXISTS idx_accounts_receivable_order_id ON public.accounts_receivable(service_order_id);

ALTER TABLE public.accounts_payable ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts_receivable ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated can view payables" ON public.accounts_payable
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admin and Vendedor can manage payables" ON public.accounts_payable
  FOR ALL TO authenticated
  USING (public.is_admin() OR public.get_user_role() = 'vendedor')
  WITH CHECK (public.is_admin() OR public.get_user_role() = 'vendedor');

CREATE POLICY "All authenticated can view receivables" ON public.accounts_receivable
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admin and Vendedor can manage receivables" ON public.accounts_receivable
  FOR ALL TO authenticated
  USING (public.is_admin() OR public.get_user_role() = 'vendedor')
  WITH CHECK (public.is_admin() OR public.get_user_role() = 'vendedor');

CREATE OR REPLACE FUNCTION public.auto_create_receivable()
RETURNS TRIGGER AS $$
DECLARE
  v_terms INT;
BEGIN
  IF NEW.status = 'entrega' AND (OLD.status IS DISTINCT FROM 'entrega') THEN
    SELECT COALESCE(default_payment_terms_days, 30) INTO v_terms
    FROM public.company_info WHERE id = 1;

    INSERT INTO public.accounts_receivable (
      customer_id, service_order_id, description, amount, due_date
    )
    VALUES (
      NEW.customer_id,
      NEW.id,
      'OS #' || NEW.display_number || ' - ' || COALESCE(NEW.description, ''),
      NEW.total_value,
      CURRENT_DATE + v_terms
    )
    ON CONFLICT DO NOTHING;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_auto_create_receivable ON public.service_orders;
CREATE TRIGGER trg_auto_create_receivable
  AFTER UPDATE OF status ON public.service_orders
  FOR EACH ROW EXECUTE FUNCTION public.auto_create_receivable();
