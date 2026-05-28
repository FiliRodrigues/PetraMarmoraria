-- Migration 003: Company settings singleton table

CREATE TABLE IF NOT EXISTS public.company_info (
  id integer PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  name text NOT NULL DEFAULT '',
  cnpj text,
  address text,
  phone text,
  email text,
  logo_url text,
  default_deadline_days integer DEFAULT 15,
  default_payment_terms_days integer DEFAULT 30,
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE public.company_info ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Company info readable by authenticated" ON public.company_info FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin can update company info" ON public.company_info FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND 'admin' = ANY(p.roles)));
CREATE POLICY "Admin can insert company info" ON public.company_info FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND 'admin' = ANY(p.roles)));
