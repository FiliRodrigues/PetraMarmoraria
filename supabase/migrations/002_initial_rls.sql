-- Migration 002: Row Level Security policies for core tables

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.service_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_assignments ENABLE ROW LEVEL SECURITY;

-- Profiles: everyone can read, self can update, admin can update all
CREATE POLICY "Profiles visible to authenticated" ON public.profiles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE TO authenticated USING (auth.uid() = id);
CREATE POLICY "Admin can update any profile" ON public.profiles FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND 'admin' = ANY(p.roles)));

-- Customers: authenticated can read, admin/vendedor can insert/update/delete
CREATE POLICY "Customers readable by authenticated" ON public.customers FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin/vendedor can insert customers" ON public.customers FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND ('admin' = ANY(p.roles) OR 'vendedor' = ANY(p.roles))));
CREATE POLICY "Admin/vendedor can update customers" ON public.customers FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND ('admin' = ANY(p.roles) OR 'vendedor' = ANY(p.roles))));
CREATE POLICY "Admin/vendedor can delete customers" ON public.customers FOR DELETE TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND ('admin' = ANY(p.roles) OR 'vendedor' = ANY(p.roles))));

-- Products: authenticated can read, admin/vendedor can insert/update
CREATE POLICY "Products readable by authenticated" ON public.products FOR SELECT TO authenticated USING (true);
CREATE POLICY "Admin/vendedor can insert products" ON public.products FOR INSERT TO authenticated WITH CHECK (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND ('admin' = ANY(p.roles) OR 'vendedor' = ANY(p.roles))));
CREATE POLICY "Admin/vendedor can update products" ON public.products FOR UPDATE TO authenticated USING (EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = auth.uid() AND ('admin' = ANY(p.roles) OR 'vendedor' = ANY(p.roles))));

-- Service Orders: authenticated can read all, admin/vendedor can insert/update all
CREATE POLICY "Orders readable by authenticated" ON public.service_orders FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated can insert orders" ON public.service_orders FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated can update orders" ON public.service_orders FOR UPDATE TO authenticated USING (true);

-- Status History: readable by authenticated, insert on move
CREATE POLICY "History readable by authenticated" ON public.status_history FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated can insert history" ON public.status_history FOR INSERT TO authenticated WITH CHECK (true);

-- Order Assignments: readable by authenticated, insert/update on assignment
CREATE POLICY "Assignments readable by authenticated" ON public.order_assignments FOR SELECT TO authenticated USING (true);
CREATE POLICY "Authenticated can insert assignments" ON public.order_assignments FOR INSERT TO authenticated WITH CHECK (true);
CREATE POLICY "Authenticated can update assignments" ON public.order_assignments FOR UPDATE TO authenticated USING (true);
