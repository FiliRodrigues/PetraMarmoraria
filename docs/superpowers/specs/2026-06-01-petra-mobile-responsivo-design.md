# Petra ERP — Responsividade Mobile/Tablet + Build Android

> Spec de design. Regras globais em `~/.claude/CLAUDE.md`. Projeto: `c:\Users\filip\Desktop\Petra\petra_erp`.
> Branch de trabalho: `fix/auditoria-correcoes`.

## Contexto

O Petra ERP (Flutter — Windows Desktop + Web) foi desenhado para tela grande e densa.
O usuário quer rodar bem em **celular e tablet**, começando por **instalar um APK no próprio
Android** para testar (sem loja, sem Mac — iOS fica para fase futura).

Um protótipo HTML navegável (`%TEMP%\petra_mockups\app.html`) foi aprovado como direção visual:
bottom nav no celular, listas em cards, KPIs 2×2, formulários empilhados, navigation rail no tablet.

**Diagnóstico do estado atual (auditado no código):**
- `AppScaffold` (`lib/widgets/common/app_scaffold.dart`) já comuta sidebar↔drawer em `width > 900`
  (hardcoded). É o único ponto estrutural de responsividade.
- `AppConstants` (`lib/core/constants/app_constants.dart:12-13`) define `desktopBreakpoint = 900` e
  `tabletBreakpoint = 600`, **mas não são usados** — há `> 900` hardcoded em `app_scaffold`,
  `kanban_board`, `kanban_column`.
- **Sem bottom navigation** no mobile: tudo atrás do drawer hamburguer.
- Telas com problema real no mobile (ver fatia 2): lista de OS é tabela `Row`+flex de 7 colunas
  sem scroll horizontal; KPIs do Financeiro são 4 colunas fixas; formulários (OS, Cliente, Produto)
  têm campos em `Row` lado a lado que não empilham.
- Kanban já tem fallback mobile (TabBar por etapa) + drag-and-drop nativo que funciona no touch.
- Grids de Clientes/Produtos já são responsivos (`MaxCrossAxisExtent: 320`).
- `profile`/`settings` já usam `ConstrainedBox(maxWidth)` — padrão a replicar.
- Toolchain Android OK (`flutter doctor` limpo, SDK 35, `android/` configurado).
- **Atenção build:** o app exige `--dart-define SUPABASE_URL` e `SUPABASE_ANON_KEY` ou quebra no boot
  (registrado em memória `petra-build-command`).

## Objetivo desta entrega (Fatia 1)

Fundação responsiva + navegação adaptativa + um APK release instalável no Android do usuário.
NÃO inclui cards/KPIs/formulários (fatia 2) nem iOS/lojas (futuro).

## Princípio de design

Decisões de layout por **largura disponível** (não por "é phone/tablet"), via `LayoutBuilder`/
`MediaQuery.sizeOf`, seguindo Material 3 (bottom nav → rail → drawer conforme a largura cresce).
Desktop permanece **idêntico** ao atual.

## Componentes

### 1. Helper de breakpoints (`lib/core/utils/responsive.dart` — novo)
Extension em `BuildContext` lendo `AppConstants`:
- `context.isMobile` → `width < tabletBreakpoint` (600)
- `context.isTablet` → `600 <= width < 900`
- `context.isDesktop` → `width >= 900`
- `context.screenWidth`
Substituir os `> 900` hardcoded em `app_scaffold.dart`, `kanban_board.dart`, `kanban_column.dart`
por essas chamadas (mantém o mesmo comportamento, só centraliza).

### 2. Navegação adaptativa (`lib/widgets/common/app_scaffold.dart` — modificar)
O `ShellRoute` em `lib/app.dart` continua envolvendo tudo com `AppScaffold`. O scaffold passa a ter 3 modos:
- **Desktop (`isDesktop`):** sidebar permanente atual (`AppDrawer(isSidebar:true)`) — inalterado.
- **Tablet (`isTablet`):** `NavigationRail` à esquerda com os destinos principais; itens extras
  acessíveis por um botão "Mais"/drawer. Reusar os mesmos itens/ícones do `AppDrawer`.
- **Mobile (`isMobile`):** `Scaffold` com `AppBar` + `bottomNavigationBar` (`NavigationBar` M3) com 5
  destinos: Painel (`/`), Ordens (`/orders`), Clientes (`/customers`), Financeiro (`/financeiro`),
  Mais. "Mais" abre o `AppDrawer` existente (já tem todos os links: produtos, estoque, relatórios,
  agenda, funcionários, perfil, config, sair). Item ativo derivado de `GoRouterState.matchedLocation`,
  como o `AppDrawer` já faz.

Restrições:
- Não duplicar a lista de navegação: extrair os destinos para uma fonte única (lista de
  `({icon, label, route, adminOnly})`) consumida por sidebar, rail e bottom nav.
- Bottom nav só mostra 4 rotas principais + "Mais"; o resto vive no drawer.
- Respeitar `isAdmin` (alguns itens são admin-only, como hoje no `AppDrawer`).

### 3. Empacotamento Android
- Conferir `applicationId`, `versionName`/`versionCode`, label e ícone em `android/app/build.gradle.kts`
  e `AndroidManifest.xml` (ajustar label para "Petra ERP" se preciso).
- Build: `flutter build apk --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
- Entregar caminho do `.apk` (`build/app/outputs/flutter-apk/app-release.apk`) e instruções de instalação
  (transferir + permitir "fontes desconhecidas").

## Fluxo de dados
Sem mudança. Navegação é UI pura sobre o `go_router`/`ShellRoute` existentes. Nenhuma alteração em
providers, repositórios, Supabase ou RLS.

## Tratamento de erros / riscos
- **Trocar de rota deve preservar o destino ativo** ao alternar mobile↔desktop (rotação/resize): item
  ativo vem sempre de `matchedLocation`, nunca de estado local.
- **APK sem `--dart-define`** → boot quebrado. Mitigação: documentar o comando completo e validar no
  primeiro boot do APK.
- **Fontes Google via rede:** no celular offline cai no fallback. Fora do escopo da fatia 1; anotar
  para futura inclusão de fontes como asset no `pubspec`.
- Não quebrar desktop: o caminho `isDesktop` deve renderizar exatamente o scaffold atual.

## Testes / verificação (end-to-end)
1. `flutter analyze` sem erros novos.
2. Rodar no Chrome/Windows e **redimensionar a janela** cruzando 600 e 900px:
   - <600 → bottom nav aparece, sidebar some; navegar pelos 5 destinos + "Mais" (drawer) funciona.
   - 600–900 → navigation rail; navegação funciona.
   - >900 → sidebar idêntica à atual.
3. Item ativo acompanha a rota em todas as larguras.
4. `flutter build apk --release` com os dart-defines → instalar no Android do usuário → app abre,
   loga no Supabase, navega pelo bottom nav.

## Fora de escopo (fatias futuras — mapeadas, não agendadas)
- **Fatia 2 (visual das telas):** lista de OS e tabelas de relatório → cards no mobile; KPIs 4→2×2;
  formulários (OS/Cliente/Produto) empilhando campos < 600px; `maxWidth` nas telas de form; alvos de
  toque ≥44px e ajuste de densidade/fontes no mobile.
- **Fatia 3 (polish):** fontes embutidas como asset (offline), ícone/splash do app, revisão de Kanban
  mobile (manter abas vs. lista vertical — decisão adiada pelo usuário).
- **iOS / publicação em lojas:** requer Mac (físico ou nuvem) e contas de desenvolvedor.
