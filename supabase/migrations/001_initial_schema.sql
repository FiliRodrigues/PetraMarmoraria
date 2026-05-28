-- Migration 001: Initial schema — core tables for Petra ERP

-- Profiles (employees/users) — managed by auth.users trigger
CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY,
  email text,
  name text NOT NULL,
  phone text,
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  roles text[] DEFAULT '{vendedor}'::text[],
  avatar_url text
);

-- Customers
CREATE TABLE IF NOT EXISTS public.customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  cpf_cnpj text UNIQUE,
  phone text NOT NULL,
  phone2 text,
  email text,
  address text,
  city text,
  state text DEFAULT 'SP',
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Products / Materials
CREATE TABLE IF NOT EXISTS public.products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  type text DEFAULT 'marmore' CHECK (type IN ('marmore', 'granito', 'quartzo', 'ardosia', 'outro')),
  unit_price numeric DEFAULT 0.00,
  unit text DEFAULT 'm2' CHECK (unit IN ('m2', 'unidade', 'ml')),
  active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Service Orders
CREATE SEQUENCE IF NOT EXISTS public.service_orders_display_number_seq;

CREATE TABLE IF NOT EXISTS public.service_orders (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  display_number integer UNIQUE DEFAULT nextval('service_orders_display_number_seq'),
  customer_id uuid NOT NULL REFERENCES public.customers(id),
  description text NOT NULL,
  status text DEFAULT 'orcamento' CHECK (status IN ('orcamento', 'aprovado', 'esperando_material', 'corte', 'montagem', 'entrega')),
  queue_position integer DEFAULT 0,
  material text,
  edge_type text,
  measurements jsonb DEFAULT '{}'::jsonb,
  drawing_url text,
  total_value numeric DEFAULT 0.00,
  status_changed_at timestamptz DEFAULT now(),
  scheduled_date date,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Status History
CREATE TABLE IF NOT EXISTS public.status_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.service_orders(id),
  from_status text CHECK (from_status IS NULL OR from_status IN ('orcamento', 'aprovado', 'esperando_material', 'corte', 'montagem', 'entrega')),
  to_status text NOT NULL CHECK (to_status IN ('orcamento', 'aprovado', 'esperando_material', 'corte', 'montagem', 'entrega')),
  changed_by uuid NOT NULL REFERENCES public.profiles(id),
  changed_at timestamptz DEFAULT now(),
  notes text
);

-- Order Assignments (who works on what stage)
CREATE TABLE IF NOT EXISTS public.order_assignments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES public.service_orders(id),
  stage text NOT NULL CHECK (stage IN ('corte', 'montagem', 'entrega')),
  employee_id uuid NOT NULL REFERENCES public.profiles(id),
  assigned_at timestamptz DEFAULT now(),
  completed_at timestamptz,
  notes text
);
