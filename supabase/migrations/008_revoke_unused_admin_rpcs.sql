-- 008_revoke_unused_admin_rpcs.sql
-- As RPCs admin_* / get_profiles_by_role / update_own_profile NÃO são chamadas
-- pelo app (verificado: nenhum .rpc() para elas; criação de funcionário usa a
-- Edge Function create-employee, edição/desativação vão direto na tabela como admin).
-- Revogar EXECUTE de authenticated elimina os avisos do advisor sem quebrar nada.
--
-- is_admin / get_user_role / get_user_roles NÃO podem ser revogadas: são usadas
-- nas policies RLS e o Postgres exige EXECUTE do role autenticado para elas —
-- comprovado empiricamente: revogar causa "permission denied for function is_admin"
-- em qualquer query protegida. Os 3 avisos restantes do advisor para essas são
-- falso-positivo aceitável (funções de leitura do próprio auth.uid(), seguras).

REVOKE EXECUTE ON FUNCTION public.admin_create_employee(text, text[], text)               FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_update_employee(uuid, text, text[], text, boolean) FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.admin_set_profile_active_status(uuid, boolean)          FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.get_profiles_by_role(text)                              FROM authenticated;
REVOKE EXECUTE ON FUNCTION public.update_own_profile(text, text)                          FROM authenticated;
