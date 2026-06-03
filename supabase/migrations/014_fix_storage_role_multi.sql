-- 014_fix_storage_role_multi.sql
-- Storage (bucket assets): as policies de escrita da 009 ainda usavam
-- get_user_role() = 'vendedor' (singular, lê só roles[1]). Com o schema
-- multi-role (profiles.roles text[]), vendedor fora da 1ª posição falha o
-- WITH CHECK e não consegue subir logo/desenho. Padronizar para ANY(get_user_roles())
-- como nas 011/012.

DROP POLICY IF EXISTS "assets_write_admin_vendedor" ON storage.objects;
CREATE POLICY "assets_write_admin_vendedor" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'assets' AND (is_admin() OR 'vendedor' = ANY(get_user_roles())));

DROP POLICY IF EXISTS "assets_update_admin_vendedor" ON storage.objects;
CREATE POLICY "assets_update_admin_vendedor" ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id = 'assets' AND (is_admin() OR 'vendedor' = ANY(get_user_roles())))
  WITH CHECK (bucket_id = 'assets' AND (is_admin() OR 'vendedor' = ANY(get_user_roles())));

DROP POLICY IF EXISTS "assets_delete_admin_vendedor" ON storage.objects;
CREATE POLICY "assets_delete_admin_vendedor" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'assets' AND (is_admin() OR 'vendedor' = ANY(get_user_roles())));
