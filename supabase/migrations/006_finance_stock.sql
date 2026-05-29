-- 006_finance_stock.sql
-- Compatibiliza o schema com o codigo Dart: financeiro (payments), estoque e created_by na OS.

-- §2.2 created_by na OS
ALTER TABLE service_orders ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES profiles(id);

-- §3 payments
CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
  amount numeric NOT NULL,
  method text NOT NULL DEFAULT 'dinheiro',
  status text NOT NULL DEFAULT 'pendente',
  due_date date,
  paid_at timestamptz,
  notes text,
  created_by uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_payments_order ON payments(order_id);

-- §4 estoque
ALTER TABLE products ADD COLUMN IF NOT EXISTS stock_quantity numeric NOT NULL DEFAULT 0;
ALTER TABLE products ADD COLUMN IF NOT EXISTS min_stock numeric NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS stock_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id uuid NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  type text NOT NULL,
  quantity numeric NOT NULL,
  reason text,
  order_id uuid REFERENCES service_orders(id),
  created_by uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_stock_mov_product ON stock_movements(product_id);

-- §4 funcao atomica de movimentacao (saida nunca abaixo de 0)
CREATE OR REPLACE FUNCTION register_stock_movement(
  p_product_id uuid, p_type text, p_quantity numeric,
  p_reason text DEFAULT NULL, p_order_id uuid DEFAULT NULL, p_created_by uuid DEFAULT NULL
) RETURNS void AS $$
DECLARE v_current numeric; v_new numeric;
BEGIN
  SELECT stock_quantity INTO v_current FROM products WHERE id = p_product_id;
  CASE p_type
    WHEN 'entrada' THEN v_new := v_current + p_quantity;
    WHEN 'saida'   THEN v_new := v_current - p_quantity;
    WHEN 'ajuste'  THEN v_new := p_quantity;
    ELSE v_new := v_current;
  END CASE;
  IF v_new < 0 THEN v_new := 0; END IF;
  INSERT INTO stock_movements (product_id, type, quantity, reason, order_id, created_by)
  VALUES (p_product_id, p_type, p_quantity, p_reason, p_order_id, p_created_by);
  UPDATE products SET stock_quantity = v_new WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql SET search_path = public, pg_temp;

-- RLS: authenticated faz tudo (espelha o acesso liberado das tabelas operacionais)
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements ENABLE ROW LEVEL SECURITY;

CREATE POLICY "All authenticated can manage payments" ON payments
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "All authenticated can manage stock movements" ON stock_movements
  FOR ALL TO authenticated USING (true) WITH CHECK (true);
