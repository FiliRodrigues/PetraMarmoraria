# Petra ERP - Plano de Execucao

**Data:** 2026-05-26
**Design Spec:** `docs/superpowers/specs/2026-05-26-erp-marmoraria-design.md`

---

## FASE 0 - Setup do Projeto

### 0.1 Criar projeto Flutter
```bash
flutter create petra_erp --org com.petra
```

### 0.2 Estrutura de pastas
```
petra_erp/lib/
  main.dart, app.dart
  core/theme/      app_theme.dart, app_colors.dart
  core/constants/  app_constants.dart, os_status.dart
  core/utils/      date_utils.dart, validators.dart, formatters.dart
  models/          profile.dart, customer.dart, product.dart,
                   service_order.dart, status_history.dart, order_assignment.dart
  services/        supabase_service.dart, auth_service.dart, customer_service.dart,
                   product_service.dart, service_order_service.dart, profile_service.dart
  providers/       auth_provider.dart, os_provider.dart, customer_provider.dart,
                   product_provider.dart, employee_provider.dart
  screens/auth/    login_screen.dart, forgot_password_screen.dart
  screens/home/    home_screen.dart (Dashboard Kanban)
  screens/customers/  customer_list_screen.dart, customer_form_screen.dart, customer_detail_screen.dart
  screens/service_orders/  os_detail_screen.dart, os_form_screen.dart, os_print_screen.dart
  screens/employees/  employee_list_screen.dart, employee_form_screen.dart
  screens/products/   product_list_screen.dart, product_form_screen.dart
  screens/profile/    profile_screen.dart
  widgets/kanban/  kanban_board.dart, kanban_column.dart, os_card.dart
  widgets/common/  app_scaffold.dart, app_drawer.dart, status_badge.dart,
                   delay_badge.dart, empty_state.dart, confirm_dialog.dart, loading_overlay.dart
  pdf/             os_pdf_generator.dart, os_pdf_template.dart
assets/  images/logo.png, fonts/Inter-*.ttf
supabase/migrations/  001_tables.sql, 002_triggers.sql, 003_rls.sql, 004_fura_fila.sql, 005_seed.sql
```

### 0.3 Dependencias (pubspec.yaml)
```yaml
dependencies:
  supabase_flutter: ^2.8.0
  go_router: ^14.0.0
  flutter_riverpod: ^2.5.0
  pdf: ^3.11.0
  printing: ^5.13.0
  intl: ^0.19.0
  image_picker: ^1.1.0
  google_fonts: ^6.2.0
  flutter_slidable: ^3.1.0
  uuid: ^4.4.0
```

### 0.4 Criar projeto Supabase
1. Criar projeto em https://supabase.com
2. Anotar SUPABASE_URL e SUPABASE_ANON_KEY

---

## FASE 1 - Tema e Autenticacao

### 1.1 Cores (app_colors.dart / app_theme.dart)

Paleta Petra Marmoraria:
- primary (preto): 0xFF1A1A1A
- surface (creme): 0xFFF5F0E8
- accent (dourado): 0xFFC4A747
- error (vermelho): 0xFFC62828
- warning (amarelo): 0xFFE6A817
- success (verde): 0xFF2E7D32

ThemeData com ColorScheme, TextTheme (fonte Inter), AppBar preto com texto creme, Drawer creme, botoes pretos, cards brancos com borda 12px, padding 16px.

### 1.2 Login Screen
- Web: card centralizado 400x500px, logo PETRA, campos email+senha, botao "Entrar" preto, link "Esqueci minha senha" dourado
- Mobile: mesmo card com 90% largura, ScrollView
- Validacao: email regex, senha min 6 chars
- Loading spinner no botao durante auth
- SnackBar para erros
- Supabase session persistente

### 1.3 Recuperar Senha
- Campo email, botao enviar link
- SnackBar confirmacao
- Supabase lida com magic link

### 1.4 Auth Provider
- StateNotifier com estados: loading, authenticated, unauthenticated
- Escuta onAuthStateChange do Supabase
- Redirect para login se sessao expirar

---

## FASE 2 - Banco de Dados (Migrations SQL)

Executar no SQL Editor do Supabase, na ordem:

### 001_tables.sql
```sql
-- profiles: vinculado ao auth.users
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL, name TEXT NOT NULL,
  role TEXT DEFAULT 'vendedor', phone TEXT, active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- customers
CREATE TABLE public.customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL, cpf_cnpj TEXT UNIQUE, phone TEXT NOT NULL,
  phone2 TEXT, email TEXT, address TEXT, city TEXT, state TEXT DEFAULT 'SP',
  notes TEXT, created_at TIMESTAMPTZ DEFAULT now(), updated_at TIMESTAMPTZ DEFAULT now()
);

-- products
CREATE TABLE public.products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL, type TEXT DEFAULT 'marmore',
  unit_price DECIMAL(10,2) DEFAULT 0, unit TEXT DEFAULT 'm2',
  active BOOLEAN DEFAULT true, created_at TIMESTAMPTZ DEFAULT now()
);

-- service_orders
CREATE TABLE public.service_orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  display_number SERIAL UNIQUE,
  customer_id UUID NOT NULL REFERENCES public.customers(id),
  description TEXT NOT NULL,
  status TEXT DEFAULT 'orcamento' CHECK (status IN ('orcamento','aprovado','recebido','esperando_material','corte','montagem','entrega')),
  queue_position INT DEFAULT 0, material TEXT, edge_type TEXT,
  measurements JSONB DEFAULT '{}', drawing_url TEXT,
  total_value DECIMAL(10,2) DEFAULT 0,
  status_changed_at TIMESTAMPTZ DEFAULT now(),
  scheduled_date DATE, created_at TIMESTAMPTZ DEFAULT now(), updated_at TIMESTAMPTZ DEFAULT now()
);

-- status_history
CREATE TABLE public.status_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  from_status TEXT, to_status TEXT NOT NULL,
  changed_by UUID NOT NULL REFERENCES public.profiles(id),
  changed_at TIMESTAMPTZ DEFAULT now(), notes TEXT
);

-- order_assignments
CREATE TABLE public.order_assignments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.service_orders(id) ON DELETE CASCADE,
  stage TEXT NOT NULL CHECK (stage IN ('corte','montagem','entrega')),
  employee_id UUID NOT NULL REFERENCES public.profiles(id),
  assigned_at TIMESTAMPTZ DEFAULT now(), completed_at TIMESTAMPTZ, notes TEXT
);
```

### 002_triggers.sql
```sql
-- Auto-criar profile ao criar auth.user
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, role)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'name', 'vendedor');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Atualizar status_changed_at automaticamente
CREATE OR REPLACE FUNCTION public.handle_status_change()
RETURNS TRIGGER AS $$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    NEW.status_changed_at = now();
    NEW.updated_at = now();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_os_status_change
  BEFORE UPDATE ON public.service_orders
  FOR EACH ROW EXECUTE FUNCTION public.handle_status_change();
```

### 003_rls.sql
- profiles: admin ve/edita todos, usuario ve proprio
- customers: autenticados veem, admin+vendedor criam/editam
- products: autenticados veem, admin+vendedor gerenciam
- service_orders: autenticados veem/criam/atualizam
- status_history: autenticados veem/inserem
- order_assignments: autenticados veem, admin+vendedor gerenciam

### 004_fura_fila.sql
```sql
CREATE OR REPLACE FUNCTION public.check_queue_violation(p_order_id UUID)
RETURNS TABLE(violated_by_id UUID, violated_by_number INT, violation_message TEXT) AS $$
DECLARE v_status TEXT; v_queue INT;
BEGIN
  SELECT status, queue_position INTO v_status, v_queue
  FROM public.service_orders WHERE id = p_order_id;

  RETURN QUERY
  SELECT so.id, so.display_number,
    format('ATENCAO: OS #%s (%s) em %s mas OS #%s ainda em etapa anterior',
      so.display_number, c.name, so.status,
      (SELECT display_number FROM public.service_orders WHERE id = p_order_id))
  FROM public.service_orders so
  JOIN public.customers c ON c.id = so.customer_id
  WHERE so.queue_position < v_queue
    AND so.status IS DISTINCT FROM 'entrega'
    AND so.id != p_order_id
    AND (
      CASE v_status
        WHEN 'corte' THEN so.status IN ('orcamento','aprovado','recebido','esperando_material')
        WHEN 'montagem' THEN so.status IN ('orcamento','aprovado','recebido','esperando_material','corte')
        WHEN 'entrega' THEN so.status NOT IN ('entrega')
        ELSE FALSE
      END
    );
END;
$$ LANGUAGE plpgsql;
```

---

## FASE 3 - Models e Services

### 3.1 Models
Cada model: classe Dart imutavel, fromMap(), toMap(), copyWith(), ==, hashCode.

#### os_status.dart (constantes core)
```dart
class OSStatus {
  static const orcamento = 'orcamento';
  static const aprovado = 'aprovado';
  static const recebido = 'recebido';
  static const esperandoMaterial = 'esperando_material';
  static const corte = 'corte';
  static const montagem = 'montagem';
  static const entrega = 'entrega';

  static const ordered = [orcamento, aprovado, recebido, esperandoMaterial, corte, montagem, entrega];

  static const labels = {
    orcamento: 'Orcamento', aprovado: 'Aprovado', recebido: 'Recebido',
    esperandoMaterial: 'Esperando Material', corte: 'Corte',
    montagem: 'Montagem', entrega: 'Entrega',
  };

  static int indexOf(String status) => ordered.indexOf(status);
  static String? next(String status) { final i = indexOf(status); return i < ordered.length - 1 ? ordered[i + 1] : null; }
  static String? previous(String status) { final i = indexOf(status); return i > 0 ? ordered[i - 1] : null; }
  static bool canMoveTo(String from, String to) => to == next(from) || to == previous(from);
  static bool requiresAssignment(String s) => s == corte || s == montagem || s == entrega;
  static String? requiredRole(String stage) => {corte: 'cortador', montagem: 'montador', entrega: 'entregador'}[stage];
}
```

#### ServiceOrder (model)
campos: id, displayNumber, customerId, customerName (join), description, status, queuePosition, material, edgeType, measurements (json), drawingUrl, totalValue, statusChangedAt, scheduledDate, createdAt, updatedAt.
helpers: isDelayed (>5d), isWarning (>3d), daysStale, statusLabel, formattedNumber (#0000).

### 3.2 Services
Cada service recebe SupabaseClient, metodos CRUD, try/catch com mensagens amigaveis.

#### service_order_service.dart (core logic)
- getAll(filters), getById, create, update, delete
- streamAll() - Supabase Realtime
- moveStatus(orderId, newStatus, changedBy, notes?, employeeId?) - valida transicao, atualiza OS, insere history, cria assignment se necessario
- getDelayed(), checkQueueViolations(), countDelayed()
- getHistory(orderId), getAssignments(orderId)

---

## FASE 4 - Providers (State Management - Riverpod)

### 4.1 auth_provider.dart
- State: AsyncValue<User?>
- login(email, password), logout(), resetPassword(email)
- Escuta onAuthStateChange

### 4.2 os_provider.dart (principal)
- State: AsyncValue<List<ServiceOrder>>
- build() carrega todas OS do Supabase
- Agrupamentos: getByStatus(status), getDelayed(), countByStatus(), countDelayed()
- Acoes: moveOrder(orderId, newStatus, ...), createOrder(data), updateOrder(id, data)
- checkQueueViolations(): para cada OS, chama funcao SQL e retorna violacoes
- StreamBuilder para realtime updates

### 4.3 Outros providers
- customerProvider, productProvider, employeeProvider (lista + CRUD)
- profileProvider (perfil do usuario logado)

---

## FASE 5 - Dashboard Kanban (Tela Principal)

### 5.1 kanban_board.dart
- Recebe List<ServiceOrder> agrupadas por status
- Desktop: Row horizontal com 7 KanbanColumn em SingleChildScrollView horizontal
- Mobile: TabBar com 7 abas (uma por etapa), TabBarView com KanbanColumn vertical
- Realtime via Consumer do os_provider
- Banner de fura-fila no topo (MaterialBanner) se detectado
- AppBar com: titulo "Petra ERP", icone busca, Badge com contador de atrasos

### 5.2 kanban_column.dart
- Cabecalho: nome da etapa + icone + contador "(N)"
- Fundo cor suave (10% da cor do status)
- Scroll vertical independente
- DragTarget que aceita apenas transicoes permitidas via OSStatus.canMoveTo
- Cards ordenados por queue_position ASC

### 5.3 os_card.dart
- Card branco 12px borderRadius, sombra sutil
- Borda esquerda colorida: verde <=2d, amarelo 3-5d, vermelho >5d
- Conteudo: numero OS + badge tempo, nome cliente, descricao (1 linha), funcionario atribuido + icone, valor
- DragHandle no topo
- LongPressDraggable (data: ServiceOrder, feedback: card reduzido)
- OnTap: navega para os_detail_screen

### 5.4 Contadores no topo
Row com 3 chips: "N pendentes", "N em producao", "N atrasados" (vermelho)

---

## FASE 6 - Modal de Transicao de Status

Dialog exibido ao arrastar card ou clicar "Mover etapa":
- Titulo: Mover OS #NNNN
- Cliente e transicao: "De: Orcamento -> Para: Aprovado"
- Campo observacoes (opcional)
- Se etapa = corte/montagem/entrega: Dropdown de funcionarios (filtrado por role) mostrando nome + OS ativas
- Botoes Cancelar / Confirmar
- Confirmar disabled se precisa funcionario e nenhum selecionado
- Ao confirmar: loading no botao, fecha dialog, chama os_provider.moveOrder(), SnackBar sucesso

---

## FASE 7 - Telas de CRUD

### 7.1 Clientes
- customer_list_screen: ListView cards, AppBar com busca, FAB Novo
- customer_form_screen: nome* (required), CPF/CNPJ (mascara), telefone*, endereco, cidade, estado, obs
- customer_detail_screen: header dados + Tab historico de OS do cliente + botao Nova OS

### 7.2 Funcionarios (admin only)
- employee_list_screen: lista nome + role (chip colorido) + status, FAB, toggle ativo/inativo
- employee_form_screen: nome, email, role dropdown, telefone
- Botao Convidar: envia magic link via Supabase Auth admin API

### 7.3 Produtos
- product_list_screen: grid/lista nome + tipo + preco, FAB, toggle ativo

### 7.4 OS Form (criar/editar)
- Selecionar cliente (dropdown com busca)
- Descricao (multiline)
- Material (dropdown), tipo borda
- Medidas: largura, altura, espessura (numericos lado a lado)
- Formato (dropdown: reto, L, U, curvo)
- Upload desenho/croqui (botao camera/galeria -> Supabase Storage)
- Valor total (mascara R$)
- Data prevista entrega (DatePicker)
- Status inicial sempre "orcamento"
- queue_position = max_atual + 1

---

## FASE 8 - Detalhe da OS

### os_detail_screen.dart
- AppBar: "<- OS #0014" com botao imprimir
- Card Status: chip colorido + tempo parado (delay_badge)
- Card Cliente: nome, telefone
- Card Descricao: material, borda
- Card Medidas: largura x altura x espessura, formato
- Card Desenho: imagem do Storage (se existir)
- Card Equipe: cortador, montador, entregador (com nome ou "---")
- Card Historico: timeline vertical com cada mudanca (data, de->para, quem, notas)
- Card Valores: total, previsao
- FAB ou botao "Mover para proxima etapa" -> chama modal de transicao

---

## FASE 9 - Impressao PDF da OS

### os_pdf_generator.dart
Usa pacotes pdf + printing. Pagina A4, margens 40px.

Secoes do PDF:
1. Cabecalho: "PETRA MARMORARIA", OS #NNNN, data
2. Dados cliente: nome, telefone, endereco
3. Descricao: material, borda
4. Medidas: tabela com largura, altura, espessura, formato
5. Desenho: imagem se disponivel
6. Equipe: tabela vendedor/cortador/montador/entregador
7. Rodape: valor total, status

Estilo: borda superior dourada grossa, textos pretos, fundo branco, fonte Helvetica.

Integracao: botao na AppBar -> generateOSPDF -> Printing.layoutPdf (preview antes de imprimir)

---

## FASE 10 - Navegacao

### GoRouter
- /login, /forgot-password
- ShellRoute com AppScaffold:
  - / (Home/Dashboard)
  - /customers, /customers/new, /customers/:id, /customers/:id/edit
  - /orders/new, /orders/:id, /orders/:id/edit
  - /employees, /employees/new
  - /products
  - /profile
- Redirect: nao logado -> /login; logado em auth -> /

### AppScaffold (responsivo)
- Desktop (>900px): Row com Sidebar 240px + divider + body
- Mobile (<900px): Scaffold com Drawer + body

### AppDrawer
Menu lateral:
- Logo "PETRA MARMORARIA"
- Dashboard, Clientes, Produtos, Funcionarios (admin only)
- Separador
- Meu Perfil, Sair

---

## FASE 11 - Notificacoes e Alertas

### delay_badge.dart
- >5 dias: chip vermelho "Atrasado (X dias)"
- 3-5 dias: chip amarelo "Parado ha X dias"
- <=2 dias: sem badge

### AppBar Badge
- Icone sino com Badge numerico = countDelayed()
- Ao clicar: filtra apenas OS atrasadas no Dashboard

### Banner fura-fila
- Exibido no topo do Dashboard se checkQueueViolations() retornar resultados
- Texto: "ATENCAO: N ordens com fila desordenada"
- Botoes: Ver (filtra violacoes) / Ignorar (fecha)

---

## FASE 12 - Polimento

### Animações
- FadeTransition 300ms entre telas
- StaggeredAnimation para entrada dos cards kanban
- ScaleTransition no modal de mover etapa
- Shimmer loading nos cards enquanto carrega

### Feedback
- SnackBar verde (sucesso) / vermelho (erro) com icone
- Dialog confirmacao para deletar
- Loading overlay durante operacoes

### Estados Vazios
- EmptyState widget: icone, titulo, subtitulo, botao acao opcional
- Ex: "Nenhuma OS encontrada", "Cadastre seu primeiro cliente"

### Responsividade
- <600px mobile: TabBar kanban, Drawer hamburguer, FAB
- 600-900px tablet: 2-3 colunas kanban visiveis, scroll
- >900px desktop: sidebar fixa, 7 colunas, drag-drop

### Tratamento de Erro
- Offline: banner "Sem conexao. Tentando reconectar..."
- Retry automatico a cada 5s
- Dados em cache da ultima requisicao
- Erro 401: redirect login

### Exports (barrel files)
- models/models.dart, services/services.dart, providers/providers.dart
- widgets/widgets.dart, screens/screens.dart

---

## Ordem de Execucao

| # | Fase | Prioridade | Depende de |
|---|---|---|---|
| 0 | Setup Flutter + Supabase | Alta | - |
| 1 | Tema + Auth (login funcional) | Alta | 0 |
| 2 | Migrations SQL (banco completo) | Alta | 0 |
| 3 | Models + Services (camada dados) | Alta | 2 |
| 4 | Providers (state management) | Alta | 3 |
| 5 | Dashboard Kanban (tela principal) | Alta | 4 |
| 6 | Modal transicao status | Alta | 5 |
| 7 | CRUD Clientes + Funcionarios + Produtos | Media | 4 |
| 8 | Detalhe OS + Historico | Media | 4 |
| 9 | Impressao PDF | Media | 8 |
| 10 | Navegacao GoRouter | Alta | 1 |
| 11 | Notificacoes e Alertas | Media | 5 |
| 12 | Polimento e testes | Baixa | todas |

---

## Resumo das Regras de Negocio

1. OS avanca/recua apenas 1 etapa por vez - nunca pula
2. corte/montagem/entrega exigem selecionar funcionario (role compativel)
3. Alerta >5 dias parado = vermelho, >3 dias = amarelo
4. Fura-fila: OS#N em etapa avancada quando OS#N-1 ainda atras
5. PDF inclui cliente, medidas, desenho, equipe
6. Responsivo: mesmo codigo web + mobile
7. Cores: creme #F5F0E8, preto #1A1A1A, dourado #C4A747
8. Nome: Petra Marmoraria
