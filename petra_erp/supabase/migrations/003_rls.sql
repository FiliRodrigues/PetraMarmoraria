-- 003_rls.sql
-- Row Level Security (RLS) policies for Petra ERP

-- 1. Helper Functions to check permissions securely
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin' AND active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION public.get_user_role()
RETURNS TEXT AS $$
BEGIN
  RETURN (
    SELECT role FROM public.profiles
    WHERE id = auth.uid() AND active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Enable Row Level Security (RLS) for all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_assignments ENABLE ROW LEVEL SECURITY;


-- 2. Policies for public.profiles
CREATE POLICY "Admin has full access to profiles" ON public.profiles
  FOR ALL TO authenticated
  USING (public.is_admin());

CREATE POLICY "Users can view own profile" ON public.profiles
  FOR SELECT TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile fields" ON public.profiles
  FOR UPDATE TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id 
    AND role = (SELECT role FROM public.profiles WHERE id = auth.uid()) -- block self role changes
    AND active = (SELECT active FROM public.profiles WHERE id = auth.uid()) -- block self status changes
  );


-- 3. Policies for public.customers
CREATE POLICY "All authenticated users can view customers" ON public.customers
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Admin and Vendedor can manage customers" ON public.customers
  FOR ALL TO authenticated
  USING (public.is_admin() OR public.get_user_role() = 'vendedor')
  WITH CHECK (public.is_admin() OR public.get_user_role() = 'vendedor');


-- 4. Policies for public.products
CREATE POLICY "All authenticated users can view products" ON public.products
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Admin and Vendedor can manage products" ON public.products
  FOR ALL TO authenticated
  USING (public.is_admin() OR public.get_user_role() = 'vendedor')
  WITH CHECK (public.is_admin() OR public.get_user_role() = 'vendedor');


-- 5. Policies for public.service_orders
CREATE POLICY "All authenticated users can view service orders" ON public.service_orders
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "All authenticated users can create service orders" ON public.service_orders
  FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "All authenticated users can update service orders" ON public.service_orders
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Only admin can delete service orders" ON public.service_orders
  FOR DELETE TO authenticated
  USING (public.is_admin());


-- 6. Policies for public.status_history
CREATE POLICY "All authenticated users can view status history" ON public.status_history
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "All authenticated users can record status changes" ON public.status_history
  FOR INSERT TO authenticated
  WITH CHECK (true);

-- No update/delete policies to keep status history immutable


-- 7. Policies for public.order_assignments
CREATE POLICY "All authenticated users can view order assignments" ON public.order_assignments
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Admin and Vendedor can manage order assignments" ON public.order_assignments
  FOR ALL TO authenticated
  USING (public.is_admin() OR public.get_user_role() = 'vendedor')
  WITH CHECK (public.is_admin() OR public.get_user_role() = 'vendedor');
