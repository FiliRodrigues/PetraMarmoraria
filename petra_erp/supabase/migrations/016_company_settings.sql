CREATE TABLE IF NOT EXISTS public.company_info (
  id INT PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  name TEXT NOT NULL DEFAULT '',
  cnpj TEXT,
  address TEXT,
  phone TEXT,
  email TEXT,
  logo_url TEXT,
  default_deadline_days INT DEFAULT 15,
  default_payment_terms_days INT DEFAULT 30,
  updated_at TIMESTAMPTZ DEFAULT now()
);

INSERT INTO public.company_info (id, name) VALUES (1, 'Petra Marmoraria')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.company_info ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated users can view company info" ON public.company_info
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Only admin can update company info" ON public.company_info
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());
