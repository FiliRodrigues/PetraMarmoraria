# ERP Petra Marmoraria — Design Spec

**Data:** 2026-05-26
**Status:** Aprovado
**Stack:** Flutter (Web + Mobile) + Supabase (PostgreSQL + Auth)
**Instagram:** @petramarmoraria

---

## Branding

| Elemento | Valor |
|---|---|
| Nome | Petra Marmoraria |
| Cor primária | Creme `#F5F0E8` (backgrounds, superfícies) |
| Cor secundária | Preto `#1A1A1A` (textos, headers, navbar) |
| Cor de destaque | Dourado `#C4A747` (botões, badges, acentos) |
| Tipografia | Inter (clean, moderna, boa legibilidade) |
| Tom visual | Sofisticado, minimalista, industrial-limpo |
| Logo | "PETRA" em preto com ícone de pedra geométrica |

### Paleta do App Flutter (ThemeData)

```dart
ColorScheme(
  primary: Color(0xFF1A1A1A),       // preto
  onPrimary: Color(0xFFF5F0E8),     // creme sobre preto
  surface: Color(0xFFF5F0E8),       // creme fundo
  onSurface: Color(0xFF1A1A1A),     // preto texto
  secondary: Color(0xFFC4A747),     // dourado acentos
  error: Color(0xFFC62828),         // vermelho atrasos
  warning: Color(0xFFE6A817),       // amarelo atenção
  success: Color(0xFF2E7D32),       // verde concluído
)
```

---

## 1. Visão Geral

Sistema ERP para a Petra Marmoraria com controle de esteira de produção em 7 etapas fixas, gestão de clientes, funcionários e ordens de serviço. Nome do projeto: **Petra ERP**.

### Módulos

| Módulo | Descrição |
|---|---|
| Auth | Login, recuperação de senha, controle de sessão |
| Dashboard Kanban | Tela principal com todas as OS no fluxo da esteira |
| Clientes | CRUD de clientes (CPF/CNPJ, endereço, histórico) |
| Vendas | Orçamento inicial, aprovação, registro |
| Ordens de Serviço | Core — esteira de produção com 7 etapas |
| Funcionários | CRUD de usuários com roles específicos |
| Produtos | Catálogo de materiais (mármore, granito, quartzo...) |
| Impressão | Geração de PDF da OS com medidas, desenho e equipe |

---

## 2. Arquitetura

```
Flutter App (single codebase)
  ├── models/          Data classes (Customer, ServiceOrder, Profile...)
  ├── services/        Supabase client, auth, database queries
  ├── providers/       State management (ChangeNotifier + Riverpod)
  ├── screens/         One subfolder per module
  ├── widgets/         Reusable components (cards, modals, kanban)
  └── pdf/             PDF generation for OS printing

Supabase Backend
  ├── PostgreSQL       All data
  ├── Auth             Email/password authentication
  ├── Storage          Images/desenhos anexados às OS
  └── RLS              Row Level Security per auth.uid()
```

**Responsivo:** Layout único que se adapta automaticamente entre desktop (master-detail com sidebar) e mobile (navegação empilhada com Drawer).

---

## 3. Banco de Dados

### 3.1 `profiles`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | uuid PK | Vinculado ao auth.uid() do Supabase |
| `email` | text | Email de login |
| `name` | text | Nome completo |
| `role` | text | `admin`, `vendedor`, `cortador`, `montador`, `entregador` |
| `phone` | text | Telefone |
| `active` | bool | `true` / `false` |
| `created_at` | timestamptz | Data de criação |

- Criado via trigger Supabase `on_auth_user_created`
- RLS: admin vê todos, usuário comum vê próprio perfil

### 3.2 `customers`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | uuid PK | |
| `name` | text | Nome completo |
| `cpf_cnpj` | text | CPF ou CNPJ |
| `phone` | text | Telefone principal |
| `phone2` | text | Telefone secundário (opcional) |
| `email` | text | Email |
| `address` | text | Logradouro |
| `city` | text | Cidade |
| `state` | text | Estado (UF) |
| `notes` | text | Observações |
| `created_at` | timestamptz | |

### 3.3 `products`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | uuid PK | |
| `name` | text | Nome do material |
| `type` | text | `marmore`, `granito`, `quartzo`, `ardosia`, `outro` |
| `unit_price` | decimal | Preço por m² ou unidade |
| `unit` | text | `m2`, `unidade`, `ml` |
| `active` | bool | |
| `created_at` | timestamptz | |

### 3.4 `service_orders` (Tabela Principal)

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | uuid PK | Número da OS (exibe como OS #0014) |
| `customer_id` | uuid FK | Referência `customers.id` |
| `description` | text | Descrição do pedido (ex: "Bancada cozinha 3,20m") |
| `status` | text | `orcamento`, `aprovado`, `recebido`, `esperando_material`, `corte`, `montagem`, `entrega` |
| `queue_position` | int | Ordem cronológica na esteira |
| `material` | text | Tipo de pedra |
| `edge_type` | text | Tipo de borda |
| `measurements` | jsonb | `{largura, altura, espessura, formato, detalhes}` |
| `drawing_url` | text | URL do desenho/croqui no Storage |
| `total_value` | decimal | Valor total da OS |
| `status_changed_at` | timestamptz | Momento da última mudança de status |
| `scheduled_date` | date | Data prevista de entrega |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

### 3.5 `status_history`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | uuid PK | |
| `order_id` | uuid FK | Referência OS |
| `from_status` | text | Status anterior |
| `to_status` | text | Novo status |
| `changed_by` | uuid FK | `profiles.id` |
| `changed_at` | timestamptz | |
| `notes` | text | Observação da transição |

### 3.6 `order_assignments`

| Campo | Tipo | Descrição |
|---|---|---|
| `id` | uuid PK | |
| `order_id` | uuid FK | Referência OS |
| `stage` | text | `corte`, `montagem` ou `entrega` |
| `employee_id` | uuid FK | `profiles.id` (role compatível com o stage) |
| `assigned_at` | timestamptz | |
| `completed_at` | timestamptz | |
| `notes` | text | |

---

## 4. Esteira de Produção (Core Logic)

### 4.1 Estados (ordem fixa e imutável)

```
1. orcamento
2. aprovado
3. recebido
4. esperando_material
5. corte
6. montagem
7. entrega
```

### 4.2 Regras de Transição

| De | Para | Condição |
|---|---|---|
| Qualquer status atual | Próximo na sequência (index+1) | Permitido |
| Qualquer status atual | Anterior na sequência (index-1) | Permitido (retroceder) |
| Qualquer status atual | Pular etapas (index+2+) | **Bloqueado — nunca permitido** |

### 4.3 Alertas Críticos

| Alerta | Gatilho | Visual |
|---|---|---|
| **Atraso** | `now() - status_changed_at > 5 dias` e status != `entrega` | Badge vermelho "Atrasado (X dias)", card vermelho |
| **Atenção** | `now() - status_changed_at > 3 dias` | Badge amarelo "Parado há X dias" |
| **Fura-fila** | OS#N avança e OS#(N-1) ou anterior está em etapa anterior | Banner "ATENÇÃO: OS#4 em Corte antes da OS#2" |

### 4.4 Atribuição de Funcionário por Etapa

Ao mover uma OS para `corte`, `montagem` ou `entrega`, o sistema **exige** selecionar um funcionário com `role` compatível:

| Etapa | Role exigido |
|---|---|
| `corte` | `cortador` |
| `montagem` | `montador` |
| `entrega` | `entregador` |

A tela de atribuição mostra: nome do funcionário, quantidade de OS ativas já atribuídas a ele, dropdown/modal de seleção.

---

## 5. Dashboard Kanban (Tela Principal)

### 5.1 Layout

Kanban horizontal com 7 colunas (uma por etapa). Cada OS é um card com:

- Nome do cliente
- Descrição do pedido
- Badge de tempo (verde/amarelo/vermelho)
- Funcionário atribuído (se houver)
- Número da OS

Ordenação por `queue_position` ASC dentro de cada coluna.

### 5.2 Funcionalidades

- **Drag and drop:** arrastar card para coluna seguinte → modal de confirmação
- **Modal de transição:** ao mover, exibe campo de notas + seleciona funcionário (se etapa exige)
- **Filtros:** por status, cliente, funcionário, apenas atrasadas
- **Busca:** por nome cliente, nº da OS, descrição
- **Contadores no topo:** "X pendentes | Y em produção | Z atrasados"
- **Atualização em tempo real:** via Supabase Realtime (WebSocket)

### 5.3 Cores por Status de Tempo

| Condição | Cor do Card |
|---|---|
| <= 2 dias parado | Verde (normal) |
| 3-5 dias parado | Amarelo (atenção) |
| > 5 dias parado | Vermelho (atraso crítico) |

---

## 6. Impressão de OS

### 6.1 Geração de PDF

Usando os pacotes Flutter `pdf` e `printing`.

### 6.2 Conteúdo do PDF

1. Cabeçalho: nome da marmoraria, nº OS, data
2. Dados do cliente: nome, telefone, endereço
3. Descrição do pedido: material, tipo de borda
4. Medidas: largura, altura, espessura, formato
5. Desenho/croqui (imagem do Storage)
6. Equipe atribuída: vendedor, cortador, montador, entregador
7. Valor total
8. Status atual

### 6.3 Ação

Botão "Imprimir OS" na tela de detalhe da OS. Gera PDF → preview → compartilhar/imprimir/salvar.

---

## 7. Estrutura de Telas

```
LoginScreen
RecuperarSenhaScreen

HomeScreen (Dashboard Kanban)
  ├── Card de OS
  │     └── Modal MoverEtapa (seleciona funcionário + notas)
  └── AppBar: filtros, busca, contadores

CustomerListScreen
  ├── CustomerFormScreen (criar/editar)
  └── CustomerDetailScreen (histórico de OS do cliente)

ServiceOrderDetailScreen
  ├── StatusTimeline (histórico de mudanças)
  ├── AssignmentsList (funcionários atribuídos)
  └── PrintButton → Gera PDF

EmployeeListScreen (admin)
  └── EmployeeFormScreen

ProductListScreen
  └── ProductFormScreen

ProfileScreen (meu perfil)
```

---

## 8. Notificações e Alertas

| Mecanismo | Descrição |
|---|---|
| Badge no AppBar | Contador de OS atrasadas (>5 dias) |
| Cor no card | Verde/amarelo/vermelho por tempo parado |
| Banner no Dashboard | Alerta de fura-fila detectado |
| Ordenação forçada | Cards atrasados aparecem no topo da coluna |

---

## 9. Stack Tecnológica

| Camada | Tecnologia |
|---|---|
| Frontend | Flutter 3.x (Dart) |
| Backend | Supabase |
| Database | PostgreSQL 15 |
| Auth | Supabase Auth (email + senha) |
| Storage | Supabase Storage (desenhos/anexos) |
| State | Riverpod + Streams Supabase Realtime |
| PDF | `pdf` + `printing` packages |
| Routing | go_router |
| Responsivo | LayoutBuilder + Breakpoints adaptive |

---

## 10. Regras de Negócio Consolidadas

1. OS só avança para próxima etapa — nunca pula
2. Permitido retroceder apenas uma etapa (ex: `corte` → `esperando_material`)
3. Ao entrar em `corte`, `montagem` ou `entrega`, selecionar funcionário é obrigatório
4. Funcionário só pode ser atribuído se `role` compatível com a etapa
5. Alerta visual se OS ficar >5 dias sem mudar de status
6. Alerta visual se houver fura-fila (OS posterior passou OS anterior)
7. Dashboard atualiza em tempo real via WebSocket do Supabase
8. PDF de OS inclui todas as informações: cliente, medidas, desenho, equipe
9. Todo acesso a dados passa por RLS do Supabase vinculado ao `auth.uid()`
