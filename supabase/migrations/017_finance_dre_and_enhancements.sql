-- 017_finance_dre_and_enhancements.sql
-- Expansão financeira: novas colunas em accounts_payable/accounts_receivable,
-- novas tabelas (bank_accounts, cost_centers, financial_categories),
-- seed de categorias financeiras e função DRE mensal.
-- Idempotente: usa IF NOT EXISTS, ADD COLUMN IF NOT EXISTS, DO blocks para constraints.

-- ============================================================
-- 1. MELHORIAS em accounts_payable
-- ============================================================

-- 1a. Novas colunas
ALTER TABLE public.accounts_payable ADD COLUMN IF NOT EXISTS cost_center_id      uuid REFERENCES public.service_orders(id);
ALTER TABLE public.accounts_payable ADD COLUMN IF NOT EXISTS payment_method      text NOT NULL DEFAULT 'pix';
ALTER TABLE public.accounts_payable ADD COLUMN IF NOT EXISTS recurring           boolean NOT NULL DEFAULT false;
ALTER TABLE public.accounts_payable ADD COLUMN IF NOT EXISTS recurring_interval  text;
ALTER TABLE public.accounts_payable ADD COLUMN IF NOT EXISTS paid_method         text;
ALTER TABLE public.accounts_payable ADD COLUMN IF NOT EXISTS status              text NOT NULL DEFAULT 'pendente';

-- 1b. CHECK constraint em recurring_interval (idempotente via DO block)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ck_accounts_payable_recurring_interval'
      AND conrelid = 'public.accounts_payable'::regclass
  ) THEN
    ALTER TABLE public.accounts_payable
      ADD CONSTRAINT ck_accounts_payable_recurring_interval
      CHECK (recurring_interval IS NULL OR recurring_interval IN ('mensal','semanal','quinzenal'));
  END IF;
END $$;

-- 1c. CHECK constraint em status
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ck_accounts_payable_status'
      AND conrelid = 'public.accounts_payable'::regclass
  ) THEN
    ALTER TABLE public.accounts_payable
      ADD CONSTRAINT ck_accounts_payable_status
      CHECK (status IN ('pendente','pago','vencido','cancelado'));
  END IF;
END $$;

-- 1d. CHECK constraint em category (valores padronizados)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ck_accounts_payable_category'
      AND conrelid = 'public.accounts_payable'::regclass
  ) THEN
    ALTER TABLE public.accounts_payable
      ADD CONSTRAINT ck_accounts_payable_category
      CHECK (category IS NULL OR category IN (
        'matéria-prima','ferramentas','frete','manutenção','mão de obra',
        'aluguel','energia','impostos','marketing','outros'
      ))
      NOT VALID;
  END IF;
END $$;

-- 1e. Índices
CREATE INDEX IF NOT EXISTS idx_accounts_payable_supplier_id    ON public.accounts_payable USING btree (supplier_id);
CREATE INDEX IF NOT EXISTS idx_accounts_payable_status          ON public.accounts_payable USING btree (status);
CREATE INDEX IF NOT EXISTS idx_accounts_payable_cost_center_id  ON public.accounts_payable USING btree (cost_center_id);
-- idx_accounts_payable_due_date já existe (006c)

-- ============================================================
-- 2. MELHORIAS em accounts_receivable
-- ============================================================

-- 2a. Novas colunas
ALTER TABLE public.accounts_receivable ADD COLUMN IF NOT EXISTS payment_method     text;
ALTER TABLE public.accounts_receivable ADD COLUMN IF NOT EXISTS installments_count integer NOT NULL DEFAULT 1;
ALTER TABLE public.accounts_receivable ADD COLUMN IF NOT EXISTS installment_number integer NOT NULL DEFAULT 1;
ALTER TABLE public.accounts_receivable ADD COLUMN IF NOT EXISTS status             text NOT NULL DEFAULT 'pendente';
ALTER TABLE public.accounts_receivable ADD COLUMN IF NOT EXISTS billing_reference   text;

-- 2b. CHECK constraint em status
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'ck_accounts_receivable_status'
      AND conrelid = 'public.accounts_receivable'::regclass
  ) THEN
    ALTER TABLE public.accounts_receivable
      ADD CONSTRAINT ck_accounts_receivable_status
      CHECK (status IN ('pendente','pago','vencido','cancelado'));
  END IF;
END $$;

-- 2c. Índices
CREATE INDEX IF NOT EXISTS idx_accounts_receivable_status ON public.accounts_receivable USING btree (status);
CREATE INDEX IF NOT EXISTS idx_accounts_receivable_customer_id ON public.accounts_receivable USING btree (customer_id);

-- ============================================================
-- 3. NOVAS TABELAS
-- ============================================================

-- 3a. bank_accounts
CREATE TABLE IF NOT EXISTS public.bank_accounts (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  bank_name      text NOT NULL,
  agency         text,
  account_number text,
  balance        decimal(12,2) NOT NULL DEFAULT 0.00,
  active         boolean NOT NULL DEFAULT true,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_bank_accounts_active ON public.bank_accounts USING btree (active);

-- 3b. cost_centers
CREATE TABLE IF NOT EXISTS public.cost_centers (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name         text NOT NULL,
  type         text NOT NULL DEFAULT 'department' CHECK (type IN ('os','department','overhead')),
  reference_id uuid REFERENCES public.service_orders(id) ON DELETE SET NULL,
  active       boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now(),
  updated_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_cost_centers_type      ON public.cost_centers USING btree (type);
CREATE INDEX IF NOT EXISTS idx_cost_centers_active     ON public.cost_centers USING btree (active);
CREATE INDEX IF NOT EXISTS idx_cost_centers_reference  ON public.cost_centers USING btree (reference_id);

-- 3c. financial_categories
CREATE TABLE IF NOT EXISTS public.financial_categories (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name       text NOT NULL,
  type       text NOT NULL DEFAULT 'expense' CHECK (type IN ('expense','income')),
  parent_id  uuid REFERENCES public.financial_categories(id) ON DELETE SET NULL,
  active     boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_financial_categories_type     ON public.financial_categories USING btree (type);
CREATE INDEX IF NOT EXISTS idx_financial_categories_parent    ON public.financial_categories USING btree (parent_id);
CREATE INDEX IF NOT EXISTS idx_financial_categories_active    ON public.financial_categories USING btree (active);

-- ============================================================
-- 4. RLS — habilita e cria políticas para as tabelas novas
--    (suppliers, accounts_payable, accounts_receivable já têm
--     RLS ativa desde 006c; policies ajustadas em 012.)
-- ============================================================

ALTER TABLE public.bank_accounts          ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cost_centers           ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.financial_categories   ENABLE ROW LEVEL SECURITY;

-- 4a. bank_accounts: admin manage, vendedor select
DROP POLICY IF EXISTS "Admin can manage bank accounts" ON public.bank_accounts;
CREATE POLICY "Admin can manage bank accounts" ON public.bank_accounts
  FOR ALL TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

DROP POLICY IF EXISTS "Vendedor can view bank accounts" ON public.bank_accounts;
CREATE POLICY "Vendedor can view bank accounts" ON public.bank_accounts
  FOR SELECT TO authenticated
  USING ('vendedor' = ANY(get_user_roles()));

-- 4b. cost_centers: todos select, admin+vendedor manage
DROP POLICY IF EXISTS "All authenticated users can view cost centers" ON public.cost_centers;
CREATE POLICY "All authenticated users can view cost centers" ON public.cost_centers
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Admin and Vendedor can manage cost centers" ON public.cost_centers;
CREATE POLICY "Admin and Vendedor can manage cost centers" ON public.cost_centers
  FOR ALL TO authenticated
  USING (is_admin() OR 'vendedor' = ANY(get_user_roles()))
  WITH CHECK (is_admin() OR 'vendedor' = ANY(get_user_roles()));

-- 4c. financial_categories: todos select, admin manage
DROP POLICY IF EXISTS "All authenticated users can view financial categories" ON public.financial_categories;
CREATE POLICY "All authenticated users can view financial categories" ON public.financial_categories
  FOR SELECT TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Admin can manage financial categories" ON public.financial_categories;
CREATE POLICY "Admin can manage financial categories" ON public.financial_categories
  FOR ALL TO authenticated
  USING (is_admin())
  WITH CHECK (is_admin());

-- ============================================================
-- 5. SEED de categorias financeiras (idempotente)
-- ============================================================

-- 5a. Despesas (expense)
INSERT INTO public.financial_categories (id, name, type, parent_id, active) VALUES
  ('e0000001-0000-0000-0000-000000000001', 'Matéria-prima',         'expense', NULL, true),
  ('e0000001-0000-0000-0000-000000000002', 'Ferramentas/Insumos',   'expense', NULL, true),
  ('e0000001-0000-0000-0000-000000000003', 'Frete/Logística',       'expense', NULL, true),
  ('e0000001-0000-0000-0000-000000000004', 'Manutenção',            'expense', NULL, true),
  ('e0000001-0000-0000-0000-000000000005', 'Mão de obra',           'expense', NULL, true),
  ('e0000001-0000-0000-0000-000000000006', 'Aluguel',               'expense', NULL, true),
  ('e0000001-0000-0000-0000-000000000007', 'Energia/Água',          'expense', NULL, true),
  ('e0000001-0000-0000-0000-000000000008', 'Impostos/Taxas',        'expense', NULL, true),
  ('e0000001-0000-0000-0000-000000000009', 'Marketing/Vendas',      'expense', NULL, true),
  ('e0000001-0000-0000-0000-00000000000a', 'Contabilidade',         'expense', NULL, true),
  ('e0000001-0000-0000-0000-00000000000b', 'Salários/Encargos',     'expense', NULL, true),
  ('e0000001-0000-0000-0000-00000000000c', 'Outros',                'expense', NULL, true)
ON CONFLICT (id) DO NOTHING;

-- 5b. Receitas (income)
INSERT INTO public.financial_categories (id, name, type, parent_id, active) VALUES
  ('e0000001-0000-0000-0000-00000000000d', 'Vendas de Produtos',    'income', NULL, true),
  ('e0000001-0000-0000-0000-00000000000e', 'Serviços',              'income', NULL, true),
  ('e0000001-0000-0000-0000-00000000000f', 'Outras Receitas',       'income', NULL, true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 6. FUNÇÃO DRE mensal — get_monthly_dre
--    Retorna receitas, custos diretos, lucro bruto,
--    despesas operacionais e lucro líquido do mês.
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_monthly_dre(
  p_month integer,
  p_year  integer
)
RETURNS TABLE (
  total_revenue   numeric,
  total_costs     numeric,
  gross_profit    numeric,
  total_expenses  numeric,
  net_profit      numeric
)
LANGUAGE plpgsql
STABLE
SET search_path TO 'public', 'pg_temp'
AS $function$
DECLARE
  v_revenue  numeric;
  v_costs    numeric;
  v_expenses numeric;
BEGIN
  -- Receita total: contas a receber efetivamente recebidas no mês/ano
  SELECT COALESCE(SUM(COALESCE(received_amount, amount)), 0.00)
    INTO v_revenue
    FROM public.accounts_receivable
    WHERE received_at IS NOT NULL
      AND EXTRACT(MONTH FROM received_at) = p_month
      AND EXTRACT(YEAR  FROM received_at) = p_year;

  -- Custos diretos: contas a pagar pagas no mês, categorias de custo
  -- (matéria-prima, ferramentas, frete, mão de obra)
  SELECT COALESCE(SUM(COALESCE(paid_amount, amount)), 0.00)
    INTO v_costs
    FROM public.accounts_payable
    WHERE paid_at IS NOT NULL
      AND category IN ('matéria-prima','ferramentas','frete','mão de obra')
      AND EXTRACT(MONTH FROM paid_at) = p_month
      AND EXTRACT(YEAR  FROM paid_at) = p_year;

  -- Despesas operacionais: contas a pagar pagas no mês, outras categorias
  SELECT COALESCE(SUM(COALESCE(paid_amount, amount)), 0.00)
    INTO v_expenses
    FROM public.accounts_payable
    WHERE paid_at IS NOT NULL
      AND category IN ('manutenção','aluguel','energia','impostos','marketing','outros')
      AND EXTRACT(MONTH FROM paid_at) = p_month
      AND EXTRACT(YEAR  FROM paid_at) = p_year;

  RETURN QUERY
  SELECT
    v_revenue                                AS total_revenue,
    v_costs                                  AS total_costs,
    v_revenue - v_costs                      AS gross_profit,
    v_expenses                               AS total_expenses,
    v_revenue - v_costs - v_expenses         AS net_profit;
END;
$function$;

-- Permissões da função DRE
REVOKE EXECUTE ON FUNCTION public.get_monthly_dre(integer, integer) FROM anon, public;
GRANT  EXECUTE ON FUNCTION public.get_monthly_dre(integer, integer) TO authenticated;
