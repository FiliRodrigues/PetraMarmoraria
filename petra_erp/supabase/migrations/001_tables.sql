-- 001_tables.sql
-- Create database tables for Petra ERP Marmoraria

-- 1. profiles (linked to Supabase auth.users)
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  name TEXT NOT NULL,
  role TEXT DEFAULT 'vendedor' CHECK (role IN ('admin', 'vendedor', 'cortador', 'montador', 'entregador')),
  phone TEXT,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. customers
CREATE TABLE public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  cpf_cnpj TEXT UNIQUE,
  phone TEXT NOT NULL,
  phone2 TEXT,
  email TEXT,
  address TEXT,
  city TEXT,
  state TEXT DEFAULT 'SP',
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 3. products
CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type TEXT DEFAULT 'marmore' CHECK (type IN ('marmore', 'granito', 'quartzo', 'ardosia', 'outro')),
  unit_price DECIMAL(10,2) DEFAULT 0.00,
  unit TEXT DEFAULT 'm2' CHECK (unit IN ('m2', 'unidade', 'ml')),
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 4. service_orders (Main Service Order table)
CREATE TABLE public.service_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  display_number SERIAL UNIQUE,
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE RESTRICT,
  description TEXT NOT NULL,
  status TEXT DEFAULT 'orcamento' CHECK (status IN ('orcamento', 'aprovado', 'recebido', 'esperando_material', 'corte', 'montagem', 'entrega')),
  queue_position INT DEFAULT 0,
  material TEXT,
  edge_type TEXT,
  measurements JSONB DEFAULT '{}'::jsonb,
  drawing_url TEXT,
  total_value DECIMAL(10,2) DEFAULT 0.00,
  status_changed_at TIMESTAMPTZ DEFAULT now(),
  scheduled_date DATE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 5. status_history (Immutable audit trail for status transitions)
CREATE TABLE public.status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  from_status TEXT CHECK (from_status IS NULL OR from_status IN ('orcamento', 'aprovado', 'recebido', 'esperando_material', 'corte', 'montagem', 'entrega')),
  to_status TEXT NOT NULL CHECK (to_status IN ('orcamento', 'aprovado', 'recebido', 'esperando_material', 'corte', 'montagem', 'entrega')),
  changed_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  changed_at TIMESTAMPTZ DEFAULT now(),
  notes TEXT
);

-- 6. order_assignments (Employee stage assignments)
CREATE TABLE public.order_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  stage TEXT NOT NULL CHECK (stage IN ('corte', 'montagem', 'entrega')),
  employee_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  assigned_at TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  notes TEXT
);

-- Performance and Optimization Indexes
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_customers_name ON public.customers(name);
CREATE INDEX idx_products_active ON public.products(active);
CREATE INDEX idx_service_orders_customer_id ON public.service_orders(customer_id);
CREATE INDEX idx_service_orders_status ON public.service_orders(status);
CREATE INDEX idx_service_orders_queue_position ON public.service_orders(queue_position);
CREATE INDEX idx_status_history_order_id ON public.status_history(order_id);
CREATE INDEX idx_order_assignments_order_id ON public.order_assignments(order_id);
CREATE INDEX idx_order_assignments_employee_id ON public.order_assignments(employee_id);
