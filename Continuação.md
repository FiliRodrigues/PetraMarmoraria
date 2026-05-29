# Petra ERP — Estado da Implementação

## Prompt original
Implementação de 8 features + 2 pré-requisitos para o petra_erp (Flutter + Supabase):
- §2.1 Capturar scheduledDate no formulário de OS
- §2.2 Campo created_by (vendedor responsável) na OS
- §3 Módulo Financeiro (contas a receber)
- §4 Estoque de materiais
- §5 Relatórios reais com abas
- §6 Agenda / Calendário de entregas
- §7 Notificar cliente por WhatsApp
- §8 Arquivamento automático de OS entregues (7 dias)
- SQL com todas as migrações

---

## O que foi FEITO

### §2.1 — scheduledDate no formulário de OS
- `os_form_screen.dart`: campo `_scheduledDate`, date picker com locale pt-BR, salvo no ServiceOrder

### §2.2 — created_by (vendedor) na OS
- `service_order.dart`: campos `createdBy` e `createdByName`, getter `isArchived`
- `service_order_service.dart`: join `creator:profiles(name)` no select, grava `created_by` no create
- `os_detail_screen.dart`: usa `createdByName` com fallback para heurística antiga
- `os_pdf_generator.dart`: mesma lógica de fallback

### §3 — Financeiro (BACKEND PRONTO, FALTA UI)
- `lib/models/payment.dart` — model completo
- `lib/services/payment_service.dart` — CRUD, parcelas, markPaid
- `lib/providers/payment_provider.dart` — notifier + orderPaymentsProvider
- `lib/core/constants/payment_constants.dart` — métodos e status

### §4 — Estoque (COMPLETO)
- `lib/models/product.dart`: campos `stockQuantity`, `minStock`, getter `isLowStock`
- `lib/models/stock_movement.dart` — model completo
- `lib/services/stock_service.dart` — registerMovement (RPC + fallback cliente)
- `lib/providers/stock_provider.dart` — notifier + lowStockProductsProvider
- `lib/core/constants/stock_constants.dart`
- `lib/screens/inventory/inventory_screen.dart` — tela com lista, alerta, movimentação, histórico
- `product_form_screen.dart`: campos estoque atual e mínimo
- `home_screen.dart`: banner de estoque baixo no Kanban
- Rotas, menu, exports registrados

### §5 — Relatórios reais com abas (COMPLETO)
- `reports_screen.dart` reescrito com 4 abas: Geral, Produção, Vendas, Orçamentos parados
- Dados reais do Supabase, sem mocks
- Gráficos com fl_chart (linha, barras)
- Filtro de período por aba
- `allAssignmentsProvider` adicionado ao `os_provider.dart`

### §6 — Agenda (COMPLETO)
- `lib/screens/agenda/agenda_screen.dart` com TableCalendar, locale pt-BR
- Marcadores de OS por scheduledDate, destaque de vencidas
- Rota `/agenda`, item de menu, export

### §7 — WhatsApp (COMPLETO)
- `lib/core/utils/whatsapp.dart` — sanitize, templates por status, open wa.me
- Botão "Avisar cliente (WhatsApp)" no detalhe da OS
- Trata ausência de telefone

### §8 — Arquivamento automático (COMPLETO)
- Getter `isArchived` no model (7 dias após entrega)
- `home_screen.dart`: filtra arquivadas do Kanban
- `os_list_screen.dart`: aba "Arquivadas", suporte a query param `?arquivadas=1`

### Infraestrutura
- `pubspec.yaml`: `url_launcher: ^6.3.0`, `table_calendar: ^3.1.2`, `flutter_localizations`
- `main.dart`: `initializeDateFormatting('pt_BR')`
- `app.dart`: localization delegates, rotas `/agenda` e `/estoque`
- Todos os barrel files atualizados (models, services, providers, screens)
- `test/widget_test.dart`: FakeServiceOrderService implementa getAllAssignments

---

## CONCLUÍDO (2026-05-29)

Tudo que faltava foi implementado nesta sessão:
- ✅ Migration `006_finance_stock.sql` criada e **aplicada no banco** via Supabase MCP
  (tabela `payments`, `stock_movements`, coluna `created_by` em service_orders,
  `stock_quantity`/`min_stock` em products, função `register_stock_movement` + RLS).
- ✅ Tela Financeira `lib/screens/finance/finance_screen.dart` (KPIs, filtro
  pendente/pago/todos, lista com destaque de vencidos, toque abre a OS).
- ✅ Registrada: export em `screens.dart`, rota `/financeiro` em `app.dart`, seção
  FINANCEIRO no `app_drawer.dart`.
- ✅ Seção Financeiro no `os_detail_screen.dart` (total/pago/saldo, lista de pagamentos,
  dialogs de registrar pagamento, gerar parcelas e marcar pago).
- ✅ `flutter analyze` limpo nos arquivos tocados; build Windows debug OK.

> O detalhamento abaixo era o pendente original — mantido como referência histórica.

---

## ~~O que FALTA fazer~~ (referência — já feito)

### 1. Tela Financeira (`lib/screens/finance/finance_screen.dart`)
Criar a tela com:
- KPIs: A receber (saldo total pendente), Recebido no mês, Vencido, Nº de OS com saldo
- Lista de recebíveis ordenada por vencimento, destaque para vencidos
- Toque na linha abre a OS
- Filtro por método (dinheiro/pix/cartão/etc) e por período
- Usar `paymentProvider` e `orderPaymentsProvider` (já existem)

Depois registrar:
- `lib/screens/screens.dart`: adicionar `export 'finance/finance_screen.dart';`
- `lib/app.dart`: adicionar rota `GoRoute(path: '/financeiro', builder: ...)`
- `lib/widgets/common/app_drawer.dart`: adicionar item "Financeiro" na seção FINANCEIRO

### 2. Seção Financeira no detalhe da OS (`os_detail_screen.dart`)
Adicionar seção "Financeiro" mostrando:
- Total da OS, Valor Pago (soma dos pagamentos com status=pago), Saldo a receber
- Lista de pagamentos da OS (usar `orderPaymentsProvider(order.id)`)
- Botão "Registrar pagamento" → dialog com valor, método, data, notas
- Botão "Gerar parcelas" → dialog: nº de parcelas + 1ª data + método → cria N rows
- Opção "Marcar como pago" em cada parcela pendente
- Destaque visual para parcelas vencidas (`payment.isOverdue`)

### 3. Arquivo SQL de migrações
Criar arquivo (ex: `migrations.sql`) com todos os comandos para rodar no Supabase SQL Editor:

```sql
-- §2.2 Vendedor/criador
ALTER TABLE service_orders ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES profiles(id);

-- §3 Financeiro
CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id uuid NOT NULL REFERENCES service_orders(id) ON DELETE CASCADE,
  amount numeric NOT NULL,
  method text NOT NULL,
  status text NOT NULL DEFAULT 'pendente',
  due_date date,
  paid_at timestamptz,
  notes text,
  created_by uuid REFERENCES profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_payments_order ON payments(order_id);

-- §4 Estoque
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

-- §4 Função atômica para movimentação de estoque (opcional, recomendada)
CREATE OR REPLACE FUNCTION register_stock_movement(
  p_product_id uuid,
  p_type text,
  p_quantity numeric,
  p_reason text DEFAULT NULL,
  p_order_id uuid DEFAULT NULL,
  p_created_by uuid DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_current numeric;
  v_new numeric;
BEGIN
  SELECT stock_quantity INTO v_current FROM products WHERE id = p_product_id;

  CASE p_type
    WHEN 'entrada' THEN v_new := v_current + p_quantity;
    WHEN 'saida' THEN v_new := v_current - p_quantity;
    WHEN 'ajuste' THEN v_new := p_quantity;
    ELSE v_new := v_current;
  END CASE;

  IF v_new < 0 THEN v_new := 0; END IF;

  INSERT INTO stock_movements (product_id, type, quantity, reason, order_id, created_by)
  VALUES (p_product_id, p_type, p_quantity, p_reason, p_order_id, p_created_by);

  UPDATE products SET stock_quantity = v_new WHERE id = p_product_id;
END;
$$ LANGUAGE plpgsql;
```

### 4. (Opcional) Políticas RLS para as tabelas novas
Adicionar políticas RLS para `payments` e `stock_movements` (espelhar tabelas existentes — authenticated pode tudo).

---

## Ordem para continuar amanhã

1. Criar o arquivo SQL de migrações e rodar no Supabase
2. Criar `lib/screens/finance/finance_screen.dart`
3. Registrar rota, menu e export da tela financeira
4. Integrar seção financeira no `os_detail_screen.dart`
5. Rodar `flutter analyze` para garantir que não há erros
