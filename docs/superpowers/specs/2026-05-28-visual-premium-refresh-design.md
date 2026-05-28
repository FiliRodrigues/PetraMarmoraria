# Visual Premium Refresh — Petra ERP

**Data:** 2026-05-28  
**Scope:** Design system completo — cores, tipografia, arredondamentos, sidebar, home, componentes globais  
**Prioridade de entrega:** Sidebar + Home primeiro, depois restante  

---

## Contexto

O sistema Petra ERP tem uma identidade visual funcional mas percebida como simples e sem personalidade premium. O utilizador pretende elevar a qualidade visual para um nível SaaS moderno (referências: Linear, Vercel Dashboard, Supabase) mantendo a identidade de marmoraria (navy + ouro).

---

## Decisões de Design

| Dimensão | Decisão |
|---|---|
| Direção visual | Light refinado (fundo claro, qualidade elevada) |
| Paleta | Navy + ouro mantidos, mas mais profundos e ricos |
| Estilo de cards | Bordão colorido border-left por status (refinado) |
| Border radius | Médio (8–16px dependendo do componente) |
| Sidebar | Dark sólido + item ativo com pill dourado |
| Prioridade | Sidebar + Home primeiro |

---

## 1. Nova Paleta de Cores (`app_colors.dart`)

### Backgrounds
```
background:        #F8FAFC   (era #F9FAFB)
surface:           #FFFFFF
surfaceElevated:   #F1F5F9   (era #F4F8FC)
```

### Sidebar
```
sidebarDark:           #0A1628   (era #0A3D62 — mais profundo)
sidebarItemHover:      rgba(255,255,255,0.06)
sidebarItemActiveBg:   rgba(196,154,60,0.18)
sidebarItemActiveBorder: rgba(196,154,60,0.30)
```

### Primary (Navy)
```
primary:     #0D2B45   (era #0A3D62)
primaryDark: #071828   (era #071E30)
```

### Accent (Ouro)
```
accent:      #C49A3C   (era #C0802A — mais dourado, menos alaranjado)
accentWarm:  #B8882E   (hover state)
accentLight: #F5E9C8   (era #F5DFB0)
```

### Text
```
textPrimary:   #0F172A   (era #111111 — mais frio)
textSecondary: #334155   (era #374151)
textMuted:     #64748B   (igual)
```

### Borders
```
border:      #E2E8F0   (era #D8E3EC — mais subtil)
borderFocus: #0D2B45
```

### Sombras (novidade — adicionar ao AppTheme)
```
shadowSm: BoxShadow(color: Color(0x0F0F172A), blurRadius: 2, offset: Offset(0,1))
shadowMd: [
  BoxShadow(color: Color(0x140F172A), blurRadius: 12, offset: Offset(0,4)),
  BoxShadow(color: Color(0x0D0F172A), blurRadius: 3,  offset: Offset(0,1)),
]
shadowLg: [
  BoxShadow(color: Color(0x1A0F172A), blurRadius: 24, offset: Offset(0,8)),
  BoxShadow(color: Color(0x0F0F172A), blurRadius: 6,  offset: Offset(0,2)),
]
```

### Status (manter cores actuais — já são boas)
Sem alteração nos status de OS (orcamento, aprovado, corte, montagem, entrega, etc.)

---

## 2. Border Radius & Tipografia (`app_theme.dart`)

### Border Radius
```
radiusXs:   4    (era 6)
radiusSm:   8    (igual)
radiusMd:   12   (igual)
radiusLg:   16   (era 20)
radiusXl:   24   (era 16)
radiusFull: 999  (novo — para pills/badges)
```

### Tipografia (ajustes de hierarquia)
```
displayLarge:  30px Syne w800      (era 28)
displayMedium: 24px Syne w700      (era 22)
headlineLarge: 18px Syne w700      (era 17)
titleLarge:    16px Syne w600      (era w700)
bodyLarge:     15px Jakarta w400   (igual)
bodyMedium:    14px Jakarta w400   (novo)
labelLarge:    13px Jakarta w600   (era 13.5)
labelSmall:    11px Jakarta w500   (novo — badges/chips)
```

### Espaçamentos
```
Card padding:       16px (era ~12px)
Sidebar item pad:   10px vertical, 12px horizontal
Section header gap: 20px top margin
```

---

## 3. Sidebar (`app_drawer.dart`)

```
Container:
  background:    #0A1628
  width:         260px (era 240px)
  border-right:  1px solid rgba(255,255,255,0.06)

Logo/Header:
  padding:       24px 20px 16px
  "PETRA" — Syne w800 18px branco
  "ERP"   — Jakarta w400 11px rgba(255,255,255,0.4)

Nav item (normal):
  padding:       10px 12px
  margin:        2px 8px
  borderRadius:  radiusXl (24px) — pill
  icon:          20px rgba(255,255,255,0.5)
  label:         14px Jakarta w500 rgba(255,255,255,0.65)
  hover bg:      rgba(255,255,255,0.06)

Nav item (ativo):
  background:    rgba(196,154,60,0.18)
  border:        1px solid rgba(196,154,60,0.30)
  icon:          #C49A3C
  label:         #F5E9C8 w600
  indicator:     Container 3px×20px à direita, #C49A3C, radiusFull

Dividers:
  height: 1px, color: rgba(255,255,255,0.06), margin: 8px 16px

Section labels:
  10px Syne w700, rgba(255,255,255,0.25), uppercase, letterSpacing 0.8

User chip (bottom):
  avatar:    32px circular, border 1.5px #C49A3C
  nome:      13px Jakarta w600, branco
  cargo:     11px Jakarta w400, rgba(255,255,255,0.4)
  bg:        rgba(255,255,255,0.04)
  border:    1px rgba(255,255,255,0.08)
  padding:   10px 12px
  borderRadius: radiusMd (12px)
```

---

## 4. Home Screen (`home_screen.dart`)

### KPI Chips
```
Container:
  bg:           #FFFFFF
  border:       1px solid #E2E8F0
  borderRadius: radiusLg (16px)
  padding:      16px 20px
  shadow:       shadowMd
  min-width:    140px

Normal:
  icon bg:   rgba(13,43,69,0.08) — círculo 36px
  icon:      18px #0D2B45
  valor:     24px Syne w800 textPrimary
  label:     12px Jakarta w500 textMuted

Ativo/selecionado:
  border:    1.5px solid #C49A3C
  icon bg:   rgba(196,154,60,0.12)
  icon:      #C49A3C
```

### Kanban Columns
```
Coluna:
  bg:           rgba(241,245,249,0.6)
  border:       1px solid #E2E8F0
  borderRadius: radiusMd (12px)
  header pad:   14px 16px
  header label: 13px Syne w700 uppercase textSecondary
  count badge:  pill, bg cor-status 15% opacidade

OS Card:
  bg:           #FFFFFF
  border-left:  3px solid <cor do status>
  border:       1px solid #E2E8F0
  borderRadius: radiusMd (12px)
  padding:      14px 14px 14px 12px
  shadow:       shadowSm
  hover:        shadowMd + Transform.translate(y: -1)

  OS# label:  11px Jakarta w700 textMuted uppercase
  OS# valor:  14px Syne w700 textPrimary
  Cliente:    13px Jakarta w500 textSecondary
  Material:   12px Jakarta w400 textMuted
  Badges:     radiusFull, 10px labelSmall
```

### Page Header
```
  Título:       24px Syne w800 textPrimary
  Subtítulo:    14px Jakarta w400 textMuted (data atual)
  Botão +OS:    bg #C49A3C, branco, radiusSm, shadowSm
                hover: bg #B8882E
```

---

## 5. Componentes Globais

### Status Badge (`status_badge.dart`)
```
borderRadius:  radiusFull (999px)
padding:       3px 10px
fontSize:      11px Jakarta w600
sem dot        — fundo colorido direto
border:        1px solid <cor> 30% opacidade
bg:            <cor> 12% opacidade
text:          <cor> sólido
```

### Delay Badge (`delay_badge.dart`)
```
borderRadius:  radiusFull
padding:       2px 8px
fontSize:      11px Jakarta w500
ícone:         12px
cores mantidas (verde/âmbar/vermelho)
```

### Botões
```
Elevated (primário):
  bg:           #C49A3C
  hover bg:     #B8882E
  text:         #FFFFFF 14px Jakarta w600
  borderRadius: radiusSm (8px)
  padding:      10px 20px
  shadow:       shadowSm
  hover shadow: shadowMd

Outlined (secundário):
  border:       1.5px solid #E2E8F0
  hover border: #0D2B45
  text:         textSecondary → textPrimary on hover
  borderRadius: radiusSm (8px)
  padding:      10px 20px

Destructivo:
  border:       1px solid rgba(220,38,38,0.3)
  text:         #DC2626
  hover bg:     rgba(220,38,38,0.06)
```

### Inputs / TextFields
```
bg:           #FFFFFF
border:       1.5px solid #E2E8F0
borderRadius: radiusSm (8px)
focus border: 1.5px solid #0D2B45
focus shadow: 0 0 0 3px rgba(13,43,69,0.08)
label:        13px Jakarta w500 textSecondary
hint:         textMuted
padding:      12px 14px
```

### Tabelas (OrderListScreen)
```
Header row:
  bg:           #F8FAFC
  border-bottom: 2px solid #E2E8F0
  text:         12px Syne w700 textMuted uppercase
  padding:      12px 16px

Data row:
  border-bottom: 1px solid #F1F5F9
  hover bg:     rgba(13,43,69,0.03)
  padding:      12px 16px

Staleness bar: mantida (3px border-left por cor de dias)
```

---

## Ficheiros a Modificar

| Ficheiro | O que muda |
|---|---|
| `lib/core/theme/app_colors.dart` | Nova paleta + sombras |
| `lib/core/theme/app_theme.dart` | Radii, tipografia, ThemeData |
| `lib/widgets/common/app_drawer.dart` | Sidebar pill + user chip |
| `lib/screens/home/home_screen.dart` | KPI chips + header |
| `lib/widgets/kanban/os_card.dart` | Card refinado + hover |
| `lib/widgets/kanban/kanban_column.dart` | Header + badge count |
| `lib/widgets/common/status_badge.dart` | Pill sem dot |
| `lib/widgets/common/delay_badge.dart` | Pill ajustado |
| `lib/screens/service_orders/order_list_screen.dart` | Tabela refinada |
| `lib/screens/customers/customer_list_screen.dart` | Cards refinados |
| `lib/screens/*/.*_form_screen.dart` | Inputs + botões |

---

## Verificação

1. `flutter run -d windows` — verificar sidebar, home, kanban
2. Navegar para lista de OS — verificar tabela e badges
3. Abrir formulário de OS — verificar inputs e botões
4. Navegar para clientes — verificar cards
5. Verificar responsividade web (`flutter run -d chrome`)
