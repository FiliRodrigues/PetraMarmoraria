-- 016_fix_rls_auto_enable_reference.sql
-- A migration 007 (security_hardening.sql) referencia a função rls_auto_enable()
-- com ALTER e REVOKE, mas ela NUNCA foi definida em nenhuma migration anterior.
-- Isso quebra provisionamentos limpos (supabase db push de 001 a 015).
-- Esta migration cria a função fantasma para que ALTER/REVOKE não falhem.

-- Cria a função (espelho fiel do que existe no banco de produção,
-- capturado em 2026-06-02 do projeto prxkfifwuygtlynozdqx).
CREATE OR REPLACE FUNCTION public.rls_auto_enable()
RETURNS event_trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'pg_catalog', 'pg_temp'
AS $function$
DECLARE
  r record;
BEGIN
  FOR r IN
    SELECT objid::regclass::text AS tbl
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS')
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', r.tbl);
  END LOOP;
END;
$function$;
