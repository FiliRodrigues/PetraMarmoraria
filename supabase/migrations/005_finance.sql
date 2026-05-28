-- Migration 005: Finance tables (accounts payable / receivable)

CREATE TABLE IF NOT EXISTS public.accounts_payable (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  supplier_id uuid NOT NULL REFERENCES public.suppliers(id),
  description text NOT NULL,
  amount numeric NOT NULL DEFAULT 0.00,
  due_date date NOT NULL,
  paid_at timestamptz,
  paid_amount numeric,
  category text,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.accounts_receivable (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  customer_id uuid NOT NULL REFERENCES public.customers(id),
  service_order_id uuid REFERENCES public.service_orders(id),
  description text NOT NULL,
  amount numeric NOT NULL DEFAULT 0.00,
  due_date date NOT NULL,
  received_at timestamptz,
  received_amount numeric,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.accounts_payable ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.accounts_receivable ENABLE ROW LEVEL SECURITY;

CREATE POLICY "AP readable by authenticated" ON public.accounts_payable FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin/vendedor can insert AP" ON public.accounts_payable FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND ('admin' = ANY(p.roles) OR 'vendedor' = ANY(p.roles))));
CREATE POLICY "Admin/vendedor can update AP" ON public.accounts_payable FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND ('admin' = ANY(p.roles) OR 'vendedor' = ANY(p.roles))));

CREATE POLICY "AR readable by authenticated" ON public.accounts_receivable FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin/vendedor can insert AR" ON public.accounts_receivable FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND ('admin' = ANY(p.roles) OR 'vendedor' = ANY(p.roles))));
CREATE POLICY "Admin/vendedor can update AR" ON public.accounts_receivable FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND ('admin' = ANY(p.roles) OR 'vendedor' = ANY(p.roles))));

CREATE INDEX IF NOT EXISTS idx_ap_due_date ON public.accounts_payable(due_date);
CREATE INDEX IF NOT EXISTS idx_ar_due_date ON public.accounts_receivable(due_date);
