CREATE OR REPLACE FUNCTION public.update_own_profile(
  p_name TEXT,
  p_phone TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
  UPDATE public.profiles
  SET name = p_name,
      phone = p_phone
  WHERE id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
