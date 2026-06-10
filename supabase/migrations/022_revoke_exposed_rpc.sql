-- 022_revoke_exposed_rpc.sql
-- admin_reset_password é um SECURITY DEFINER exposto a authenticated via RPC.
-- A Edge Function admin-reset-password já cobre este caso usando service_role.
-- Remover a superfície redundante do RPC público.

REVOKE EXECUTE ON FUNCTION public.admin_reset_password(uuid, text) FROM authenticated;
