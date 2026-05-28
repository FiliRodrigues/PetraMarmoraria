# Spec: Correções de CRUD + Filtros e Relatórios

**Data:** 2026-05-28
**Status:** Design aprovado

---

## 1. Correções de CRUD

### 1.1 Edge Function `create-employee`

**Arquivo:** `supabase/functions/create-employee/index.ts`

**Contrato:**
```
POST /create-employee
Auth: JWT (validado internamente: só admin)
Body: { email: string, password: string, name: string, role: string, phone?: string }
Response 200: { id: string, email: string, name: string, role: string }
Response 403: { error: "Apenas administradores podem criar funcionários" }
```

**Lógica:**
1. Validar JWT do header Authorization
2. Query SQL: `SELECT public.is_admin()` — se false, retorna 403
3. Chamar `auth.admin.createUser({ email, password, user_metadata: { name, role, phone }, email_confirm: true })` com `service_role`
4. Retornar dados do usuário criado (sem session swap)

**Frontend:** `ProfileService.createProfile(email, password, name, role, phone)` → chama `_client.functions.invoke('create-employee', body: {...})`. `employee_form_screen.dart` remove o aviso de desconexão e chama `createProfile` + `loadEmployees()`.

### 1.2 Migration `010_fix_profile_phone.sql`

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE v_role TEXT;
BEGIN
  v_role := NEW.raw_user_meta_data->>'role';
  IF v_role IS NULL OR v_role NOT IN ('admin','vendedor','cortador','montador','entregador') THEN
    v_role := 'vendedor';
  END IF;
  INSERT INTO public.profiles (id, email, name, role, phone)
  VALUES (NEW.id, NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', NEW.email),
    v_role,
    NULLIF(NEW.raw_user_meta_data->>'phone', '')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE INDEX IF NOT EXISTS idx_service_orders_created_at
  ON public.service_orders(created_at);
```

### 1.3 Error handling nos serviços (5 arquivos)

Cada `catch (e) { rethrow; }` em `customer_service.dart`, `product_service.dart`, `service_order_service.dart`, `profile_service.dart` substituído por:
```dart
catch (e) {
  throw Exception('Falha ao [operacao]: ${e.toString()}');
}
```

---

## 2. Filtro mês/ano na listagem de OS

### 2.1 Service

`ServiceOrderService.getServiceOrders()` ganha parâmetros opcionais:
```dart
Future<List<ServiceOrder>> getServiceOrders({DateTime? fromDate, DateTime? toDate});
```

Query adiciona `.gte('created_at', fromDate)` e `.lte('created_at', toDate)` quando fornecidos.

### 2.2 Provider

Novo `StateProvider` no `os_provider.dart`:
```dart
final orderMonthFilterProvider = StateProvider<({int month, int year})?>((ref) => null);
```

### 2.3 Tela

`order_list_screen.dart`:
- Topo: Row com 2 `DropdownButtonFormField` (Mês [1-12, "Todos"] / Ano [2024-2030, "Todos"])
- Default: mês/ano corrente
- Label: "N OS encontradas em Mês/Ano"
- Ao trocar → provider atualiza → lista refiltra (client-side sobre dados já carregados)

---

## 3. Dashboard de Relatórios

### 3.1 Novos métodos no ServiceOrderService

```dart
Future<List<OrderAssignment>> getAssignmentsForOrders(List<String> orderIds);
```

Busca assignments em lote para os IDs de OS do período.

### 3.2 Estrutura da ReportsScreen

Seções (topo → baixo):

| Seção | Dados |
|-------|-------|
| **Filtro mês/ano** | Mesmo componente da listagem, compartilhado |
| **KPIs** | OS criadas no mês, entregues, valor orçado, pontualidade (já existente, alimentado com dados reais) |
| **Produção por Funcionário** | Tabela: nome | corte | montagem | entrega | total. Agregado de `order_assignments` filtrado pelas OS do mês |
| **OS por Cliente** | Tabela: cliente | qtd OS | valor total. Agregado das OS do mês por `customer_id` |
| **Gráfico de volume** | Line chart com dados reais (substitui mock `_kMonthly`) |
| **OS por Etapa** | Barras de progresso (já existe, alimentado com dados reais) |

### 3.3 Agregação

Toda feita client-side (volume pequeno). Fluxo:
1. Buscar OS do período → `getServiceOrders(fromDate, toDate)`
2. Extrair `orderIds` → `getAssignmentsForOrders(orderIds)`
3. Agrupar: `Map<String, Map<String, int>>` (employee → stage → count) para produção
4. Agrupar: `Map<String, {int count, double total}>` (customer → count + total) para clientes
5. Alimentar widgets

---

## 4. Arquivos Impactados

| Arquivo | Ação |
|---------|------|
| `supabase/functions/create-employee/index.ts` | **Novo** |
| `supabase/migrations/010_fix_profile_phone.sql` | **Novo** |
| `lib/services/customer_service.dart` | Modificar (error handling) |
| `lib/services/product_service.dart` | Modificar (error handling) |
| `lib/services/service_order_service.dart` | Modificar (error handling + novos métodos) |
| `lib/services/profile_service.dart` | Modificar (error handling + createProfile) |
| `lib/providers/os_provider.dart` | Modificar (novo provider de filtro) |
| `lib/screens/employees/employee_form_screen.dart` | Modificar (remover signUp + usar Edge Function) |
| `lib/screens/service_orders/order_list_screen.dart` | Modificar (adicionar filtro) |
| `lib/screens/reports/reports_screen.dart` | Reescrever (dados reais) |
