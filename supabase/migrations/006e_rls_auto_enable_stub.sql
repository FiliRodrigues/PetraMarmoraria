-- 006e_rls_auto_enable_stub.sql
-- RECONCILIAÇÃO: A migration 007 referencia rls_auto_enable() com ALTER e REVOKE,
-- mas a função só é definida na 016. Sem este arquivo, um provisionamento limpo
-- quebraria em 007 ("function rls_auto_enable() does not exist").
-- Este stub existe para que 007 não falhe. A 016 recria com a implementação real.
-- Capturado fielmente do banco em 2026-06-02.

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
RETURNS event_trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
BEGIN
  NULL;
END;
$function$;
