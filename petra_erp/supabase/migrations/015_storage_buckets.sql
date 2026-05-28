INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('service-order-drawings', 'service-order-drawings', true, 5242880, ARRAY['image/png', 'image/jpeg', 'image/webp']::text[]),
  ('avatars', 'avatars', true, 1048576, ARRAY['image/png', 'image/jpeg', 'image/webp']::text[])
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Authenticated users can view drawings" ON storage.objects;
CREATE POLICY "Authenticated users can view drawings" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id IN ('service-order-drawings', 'avatars'));

DROP POLICY IF EXISTS "Admin and Vendedor can upload drawings" ON storage.objects;
CREATE POLICY "Admin and Vendedor can upload drawings" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id IN ('service-order-drawings', 'avatars')
    AND (public.is_admin() OR public.get_user_role() = 'vendedor')
  );

DROP POLICY IF EXISTS "Users can update own files" ON storage.objects;
CREATE POLICY "Users can update own files" ON storage.objects
  FOR UPDATE TO authenticated
  USING (auth.uid() = owner)
  WITH CHECK (auth.uid() = owner);
