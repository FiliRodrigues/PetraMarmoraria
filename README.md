# Petra ERP — Marmoraria

ERP para a Petra Marmoraria. Flutter (web/desktop/mobile) + Supabase (Postgres, Auth, RLS).

```
.
├── petra_erp/         # App Flutter (lib/, web/, android/, ios/, windows/, ...)
├── supabase/
│   └── migrations/    # Schema do banco (5 migrations SQL)
├── docs/              # Documentação adicional
├── Dockerfile         # Build da imagem web (nginx + Flutter build)
├── docker-compose.yml
└── nginx.conf
```

## Pré-requisitos

- Flutter SDK `^3.11.4` ([docs.flutter.dev](https://docs.flutter.dev/get-started/install))
- Chrome (para rodar como web)
- Projeto Supabase ativo (a chave **publishable / anon** basta no client)

## Setup em outra máquina

### 1. Clonar e instalar dependências

```bash
git clone https://github.com/FiliRodrigues/PetraMarmoraria.git
cd PetraMarmoraria/petra_erp
flutter pub get
```

### 2. Configurar credenciais do Supabase

Na raiz do repositório, copie o template:

```bash
cp .env.example .env
```

Edite `.env` com a URL e a anon/publishable key do seu projeto Supabase
(painel: **Project Settings → API**).

> A `service_role` key **nunca** deve ir para o app cliente — só `anon` / `publishable`.

### 3. Aplicar o schema no Supabase

Abra o SQL Editor do dashboard
(`https://supabase.com/dashboard/project/<SEU_REF>/sql/new`) e rode, em ordem:

```
supabase/migrations/001_tables.sql
supabase/migrations/002_triggers.sql
supabase/migrations/003_rls.sql
supabase/migrations/004_fura_fila.sql
supabase/migrations/005_seed.sql   # opcional — dados de exemplo
```

Ou, com a Supabase CLI instalada e o projeto linkado:

```bash
supabase db push
```

### 4. Criar um usuário admin

No painel **Authentication → Users → Add user** crie o e-mail/senha e marque
`Auto Confirm User`. O trigger `on_auth_user_created` já cria o `profile`
com role `vendedor`; promova para `admin` rodando no SQL Editor:

```sql
UPDATE public.profiles
SET role = 'admin'
WHERE email = 'voce@exemplo.com';
```

### 5. Rodar o app

```bash
# carregue as variáveis do .env e injete via --dart-define
flutter run -d chrome \
  --dart-define=SUPABASE_URL=$SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

No PowerShell (Windows):

```powershell
$env:SUPABASE_URL = "https://xxx.supabase.co"
$env:SUPABASE_ANON_KEY = "sb_publishable_xxx"
flutter run -d chrome `
  --dart-define=SUPABASE_URL=$env:SUPABASE_URL `
  --dart-define=SUPABASE_ANON_KEY=$env:SUPABASE_ANON_KEY
```

## Build de produção (web)

```bash
cd petra_erp
flutter build web --release \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_xxx
```

O bundle vai para `petra_erp/build/web/`. Para servir via nginx use o
`Dockerfile` + `nginx.conf` na raiz:

```bash
docker compose up --build
```

## Stack

- **Flutter** + **Riverpod** (estado) + **go_router** (rotas)
- **Supabase Flutter** (auth + realtime + Postgres via PostgREST)
- **pdf** + **printing** (geração de OS em PDF)

## Módulos

- `auth` — login / recuperação de senha
- `customers` — CRUD de clientes
- `employees` — CRUD de funcionários (perfis com roles)
- `products` — catálogo de mármores, granitos, quartzos etc.
- `service_orders` — OS com kanban, transições de status validadas no banco,
  detecção de fura-fila e impressão PDF
- `profile` — perfil do usuário logado

## Roles e permissões (RLS)

- `admin` — acesso total
- `vendedor` — gerencia clientes, produtos, OS
- `cortador` / `montador` / `entregador` — atribuíveis às etapas de produção
  correspondentes (regra forçada pelo trigger `enforce_assignment_role`)
