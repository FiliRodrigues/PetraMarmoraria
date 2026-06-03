-- 009_storage_assets_bucket.sql
-- Bucket público (leitura) para logos da empresa e desenhos/croquis das OS.
-- Escrita restrita a admin/vendedor autenticado.

INSERT INTO storage.buckets (id, name, public)
VALUES ('assets', 'assets', true)
ON CONFLICT (id) DO UPDATE SET public = true;

DROP POLICY IF EXISTS "assets_public_read" ON storage.objects;
CREATE POLICY "assets_public_read" ON storage.objects
  FOR SELECT TO public
  USING (bucket_id = 'assets');

DROP POLICY IF EXISTS "assets_write_admin_vendedor" ON storage.objects;
CREATE POLICY "assets_write_admin_vendedor" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'assets' AND (public.is_admin() OR public.get_user_role() = 'vendedor'));

DROP POLICY IF EXISTS "assets_update_admin_vendedor" ON storage.objects;
CREATE POLICY "assets_update_admin_vendedor" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'assets' AND (public.is_admin() OR public.get_user_role() = 'vendedor'))
  WITH CHECK (bucket_id = 'assets' AND (public.is_admin() OR public.get_user_role() = 'vendedor'));

DROP POLICY IF EXISTS "assets_delete_admin_vendedor" ON storage.objects;
CREATE POLICY "assets_delete_admin_vendedor" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'assets' AND (public.is_admin() OR public.get_user_role() = 'vendedor'));
