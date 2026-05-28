-- Migration 004: Suppliers table (mirrors customers structure)

CREATE TABLE IF NOT EXISTS public.suppliers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  cnpj text UNIQUE,
  phone text NOT NULL,
  phone2 text,
  email text,
  contact_person text,
  address text,
  city text,
  state text DEFAULT 'SP',
  notes text,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Suppliers readable by authenticated" ON public.suppliers FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin/vendedor can insert suppliers" ON public.suppliers FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND ('admin' = ANY(p.roles) OR 'vendedor' = ANY(p.roles))));
CREATE POLICY "Admin/vendedor can update suppliers" ON public.suppliers FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND ('admin' = ANY(p.roles) OR 'vendedor' = ANY(p.roles))));
CREATE POLICY "Admin/vendedor can delete suppliers" ON public.suppliers FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND ('admin' = ANY(p.roles) OR 'vendedor' = ANY(p.roles))));

CREATE INDEX IF NOT EXISTS idx_suppliers_name ON public.suppliers(name);
