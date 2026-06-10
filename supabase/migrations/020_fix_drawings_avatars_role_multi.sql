-- 020_fix_drawings_avatars_role_multi.sql
-- A policy "Admin and Vendedor can upload drawings" (buckets service-order-drawings
-- e avatars) ainda usava get_user_role() = 'vendedor' (singular, lê só roles[1]).
-- Um vendedor multi-role (ex.: ['montador','vendedor']) era barrado no upload.
-- Corrige para ANY(get_user_roles()), mesma correção da 014 para o bucket assets.

DROP POLICY IF EXISTS "Admin and Vendedor can upload drawings" ON storage.objects;
CREATE POLICY "Admin and Vendedor can upload drawings" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = ANY (ARRAY['service-order-drawings'::text, 'avatars'::text])
    AND (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  );

DROP POLICY IF EXISTS "Admin and Vendedor can update drawings" ON storage.objects;
CREATE POLICY "Admin and Vendedor can update drawings" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = ANY (ARRAY['service-order-drawings'::text, 'avatars'::text])
    AND (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  )
  WITH CHECK (
    bucket_id = ANY (ARRAY['service-order-drawings'::text, 'avatars'::text])
    AND (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  );

DROP POLICY IF EXISTS "Admin and Vendedor can delete drawings" ON storage.objects;
CREATE POLICY "Admin and Vendedor can delete drawings" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = ANY (ARRAY['service-order-drawings'::text, 'avatars'::text])
    AND (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  );
