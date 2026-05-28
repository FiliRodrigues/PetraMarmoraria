CREATE TABLE IF NOT EXISTS public.suppliers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  cnpj TEXT UNIQUE,
  phone TEXT NOT NULL,
  phone2 TEXT,
  email TEXT,
  contact_person TEXT,
  address TEXT,
  city TEXT,
  state TEXT DEFAULT 'SP',
  notes TEXT,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_suppliers_name ON public.suppliers(name);

ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated users can view suppliers" ON public.suppliers
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Admin and Vendedor can manage suppliers" ON public.suppliers
  FOR ALL TO authenticated
  USING (public.is_admin() OR public.get_user_role() = 'vendedor')
  WITH CHECK (public.is_admin() OR public.get_user_role() = 'vendedor');
