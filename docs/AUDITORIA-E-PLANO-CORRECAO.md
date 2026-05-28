# Auditoria Completa + Plano de Correção — Petra ERP

## Contexto

Pedido: análise completa do projeto Petra ERP (Flutter + Supabase, single-tenant — uma marmoraria),
nota de 0 a 10, e relatório de bugs/erros para deixá-lo "o mais profissional possível".

Auditoria feita com: `flutter analyze` (fonte de verdade) + 3 auditorias paralelas
(dados/lógica, UI, segurança/backend). Os falsos positivos foram filtrados (ver final).

---

## NOTA ATUAL: **3,5 / 10**

Justificativa direta: **o projeto não compila.** `flutter analyze` retorna **144 issues, das quais ~45 são `error` (bloqueiam build)**. A arquitetura é boa (camadas screens → providers → services → Supabase, Riverpod, models limpos), o design é cuidado, mas no estado atual o app não roda. Nota sobe para ~7 assim que compilar + corrigidos os bugs de runtime, e ~8,5 com o RBAC e o financeiro fechados.

| Eixo | Nota | Comentário |
|------|------|------------|
| Compila / roda | 0 | ~45 erros de compilação |
| Arquitetura | 7,5 | Camadas claras, Riverpod bem usado |
| Correção (runtime) | 4 | setState após dispose, double pra dinheiro, TODOs vazios |
| Segurança | 5 | Single-tenant ok, mas RBAC de escrita aberto + seed com senha no histórico |
| UX / polish | 6,5 | Bom design, mas botões sem debounce e loadings presos |

---

## BLOCO 0 — ERROS DE COMPILAÇÃO (o app NÃO roda hoje) 🔴 CRÍTICO

### 0.1 `os_detail_screen.dart` está estruturalmente quebrado (~40 erros)
Causa-raiz: falta uma chave `}` fechando a classe `_Body` antes da linha 464.
Consequência: `_StatusTimeline`, `_Card`, `_SectionLabel`, `_DetailRow`, `_InfoBlock`,
`_TeamRow`, `_EmptyDrawing` ficam aninhados dentro de `_Body` (`class_in_class`), e o
`build` de `_Body` não enxerga nenhum desses componentes (`undefined_method` x ~30).
- Arquivo: [os_detail_screen.dart](petra_erp/lib/screens/service_orders/os_detail_screen.dart)
- Fix: fechar a classe `_Body` na linha ~462/463 (após o `;` do `build`), de modo que
  `_StatusTimeline` (linha 464) e os demais componentes fiquem no nível superior do arquivo.
- Verificar também `fontStyle` em `_DetailRow`/Text (linha 534) — `fontStyle` não é
  parâmetro válido onde está sendo passado; mover para dentro do `TextStyle`/`AppTheme.jakarta`.

### 0.2 Forms: `unchecked_use_of_nullable_value` (3 erros, mesmo padrão)
`customer_form_screen.dart:58`, `product_form_screen.dart:59`, `supplier_form_screen.dart:57`.
`widget.id` é `String?` e é usado em `indexWhere`/comparação sem garantir não-nulo dentro
do `maybeWhen`. Fix: capturar `final id = widget.id; if (id == null) return;` no início de
`_loadXxxData()` e usar a variável local.

### 0.3 Testes não compilam (4 erros)
[widget_test.dart](petra_erp/test/widget_test.dart): mocks de `CustomerService`,
`ProductService`, `ProfileService`, `ServiceOrderService` não implementam os novos métodos
`getXxxPaged` (adicionados na paginação infinite-scroll do último commit). Fix: adicionar
override desses métodos nos fakes (retornar `[]` / página vazia).

**Critério de saída do Bloco 0:** `flutter analyze` sem nenhum `error` e `flutter test` compila.

---

## BLOCO 1 — BUGS DE RUNTIME 🟠 ALTO

### 1.1 Dinheiro com `double` (erro de centavos)
Toda a camada financeira usa `double` para valores monetários — acumula erro de ponto
flutuante em somas (ex.: `0.1 + 0.2 != 0.3`).
- [account_payable.dart](petra_erp/lib/models/account_payable.dart), [account_receivable.dart](petra_erp/lib/models/account_receivable.dart), [product.dart](petra_erp/lib/models/product.dart), [service_order.dart](petra_erp/lib/models/service_order.dart)
- [finance_service.dart](petra_erp/lib/services/finance_service.dart) — loop de acumulação `totalToPay += amount`.
- Fix pragmático (sem refatorar tudo p/ `int` centavos): arredondar todo total exibido/salvo
  com helper único `roundMoney(double v) => (v * 100).round() / 100` aplicado nas somas de
  `getFinanceSummary` e ao gravar `amount`/`paid_amount`. Decisão de escopo com o usuário.

### 1.2 `setState` após `dispose` nos forms (crash potencial)
`_loadXxxData()` é `async`, chamado sem `await` no `initState`; em erro chama `setState`
sem checar `mounted`. Telas: customer/product/supplier/employee/os form.
- Fix: `if (!mounted) return;` antes de cada `setState` no `catch`.

### 1.3 Financeiro: ações sem implementação (botão morto)
[finance_screen.dart](petra_erp/lib/screens/finance/finance_screen.dart) — `_markAsPaid` (≈437) e
`_markAsReceived` (≈505) têm `// TODO` e fecham o dialog sem chamar o service. Usuário clica,
nada acontece. `finance_service.dart` já tem `markAsPaid`/`markAsReceived` prontos — só ligar.

### 1.4 `DateTime(year, month + 1, 1)` — quebra em dezembro
[service_order_service.dart](petra_erp/lib/services/service_order_service.dart) — paginação por mês.
`month + 1 = 13` é tolerado pelo Dart (vira jan do ano seguinte) — confirmar; se houver
uso de `DateTime.utc` com mês 13 em outro ponto, normalizar. Médio.

### 1.5 Double fetch / stream listeners sem debounce
Providers (customer/product/employee) refazem `loadXxx()` a cada emissão do stream e
`os_provider.moveOrder` chama `loadOrders()` manualmente além do stream → fetch duplicado.
- Fix: remover o `loadOrders()` manual em `moveOrder` (o stream já recarrega) OU desativar o
  reload do stream. Escolher 1 caminho.

### 1.6 `BuildContext` após await sem `mounted` (2 ocorrências reais)
[os_form_screen.dart:590,595](petra_erp/lib/screens/service_orders/os_form_screen.dart) —
`use_build_context_synchronously` confirmado pelo analyzer (anexar desenho). Add `mounted` check.

---

## BLOCO 2 — SEGURANÇA 🟠 ALTO

### 2.1 Seed com senha real no histórico do Git 🔴
`petra_erp/supabase/migrations/005_seed.sql` foi deletado no working tree, mas continua no
histórico com usuários (`admin@petra.com`) e senha `password123`. Qualquer um com acesso ao
repo loga como admin. **Ação:** trocar senhas no Supabase + limpar histórico (`git filter-repo`).
Decisão do usuário (reescrever histórico é destrutivo).

### 2.2 RBAC de escrita aberto (não é multi-tenant — é RBAC)
As policies de `service_orders`, `status_history`, `order_assignments` usam `WITH CHECK (true)`
→ qualquer autenticado (cortador, entregador) cria/edita OS e forja histórico de auditoria.
- Migrations: `petra_erp/supabase/migrations/003_rls.sql` + `014_tighten...`. Aplicar policies
  por role (admin/vendedor para escrita), como já existe em `customers`/`products`.

### 2.3 Validação de força/entrada na Edge Function `create-employee`
Sem validação de senha forte nem rate-limit. Médio. (Single-tenant reduz superfície.)

### 2.4 Buckets de storage públicos + upload sem validação de MIME/tamanho real
[storage_service.dart](petra_erp/lib/services/storage_service.dart) + `015_storage_buckets.sql`.
Avaliar `public:false` + signed URLs, ou aceitar como risco baixo (desenhos não sensíveis).

---

## BLOCO 3 — DUAS PASTAS DE MIGRATIONS DIVERGENTES 🟠

Existem `supabase/migrations/` (raiz, 6 arquivos — criados agora, untracked) **e**
`petra_erp/supabase/migrations/` (21 arquivos — histórico real). Isso é uma armadilha:
risco de aplicar o conjunto errado. **Decidir qual é canônico** e remover/arquivar o outro.
A do `petra_erp/` parece ser a real (sequência completa 001→021). Decisão do usuário.

---

## BLOCO 4 — LIMPEZA / PROFISSIONALISMO 🟡 (os outros ~95 "info/warning")

- **`withOpacity` deprecated (~55 ocorrências)**: trocar por `.withValues(alpha:)`. Mecânico.
- **Imports desnecessários** (customer_form, product_form, os_form, home): remover.
- **Dead code / null-aware morto**: customer_detail_screen.dart:119; home_screen.dart:217 (`!` inútil).
- **`activeColor` deprecated**: employee_form/list → `activeThumbColor`.
- **`onWillAccept`/`onAccept` deprecated** (kanban_column): migrar p/ `*WithDetails`.
- **`prefer_final_fields`**, `unnecessary_underscores`, `curly_braces` etc.: cosmético.
- Botões de submit sem disable durante `_isLoading` em todos os forms → permite duplo-submit.

---

## DECISÃO DO USUÁRIO
- **Escopo:** apenas o relatório/diagnóstico. O usuário fará as correções por conta própria.
  Nenhuma alteração de código será feita por mim agora.
- **Dinheiro (quando o usuário for corrigir):** arredondamento pontual via helper
  `roundMoney()` nas somas e na gravação — não refatorar para `int` centavos.

## ORDEM DE EXECUÇÃO RECOMENDADA (para quando você for corrigir)

1. **Bloco 0** (compilar) — sem isso nada mais importa.
2. **Bloco 1** (runtime: financeiro morto, setState, dinheiro).
3. **Bloco 2** (segurança: senha no histórico, RBAC).
4. **Bloco 3** (migrations canônicas).
5. **Bloco 4** (limpeza dos warnings → analyze 100% limpo).

## Verificação (fim de cada bloco)
- `cd petra_erp && flutter analyze` → 0 errors (meta final: 0 issues).
- `flutter test` → passa.
- `flutter build web --dart-define SUPABASE_URL=... --dart-define SUPABASE_ANON_KEY=...`
  (ver memória [[petra-build-command]]) → build conclui.
- Smoke manual: login → criar OS → mover status no kanban → abrir detalhe da OS (era a tela
  quebrada) → marcar conta como paga em Finanças.

---

## Falsos positivos descartados na auditoria
- **"Multi-tenant sem filtro tenant_id"**: Petra é **single-tenant** (0 refs a tenant/company_id no schema).
  A regra de `tenant_id` no CLAUDE.md global pertence ao projeto **ATR**, não a este. As policies
  `USING(true)` para *leitura* são aceitáveis aqui; o problema real é o RBAC de *escrita* (2.2).
- **Anon key "vazando" no .env**: a anon key é pública por design; `.env` está no `.gitignore`.
  Não é crítico (a senha do seed em 2.1 é o problema real).
- Vários "memory leaks" reportados pela auditoria de UI já estão corretamente dispostos (verificado).
