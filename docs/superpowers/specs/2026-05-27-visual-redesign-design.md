# Redesign Visual Petra ERP

**Data:** 2026-05-27  
**Status:** Aprovado para implementação

---

## Contexto

O app atual parece "feito no fundo de quintal" — cores azuis médias sem personalidade, texto em tons cinza-azulados difíceis de ler, border radius pequenos que dão aspecto quadrado e básico. O objetivo é elevar a percepção visual para um ERP profissional e moderno, sem mudar funcionalidades.

---

## Decisões do Utilizador

| Ponto | Decisão |
|---|---|
| Azul primário | `#0A3D62` — petróleo escuro, premium |
| Sidebar | Sólida em `#0A3D62`, textos/ícones brancos |
| Border radius — cards | 20px (visual Notion/Linear) |
| Border radius — botões/inputs | 12px |
| Texto | Preto puro (`#111111`) ao invés de cinza azulado |
| Fontes | Manter Syne (headers) + Plus Jakarta Sans (body) |

---

## Nova Paleta de Cores

```dart
// app_colors.dart — completo
primary         = #0A3D62   // petróleo escuro (azul ação)
navyBlue        = #0A3D62   // sidebar/AppBar (= primary)
background      = #F9FAFB   // quase branco neutro
surface         = #FFFFFF   // branco puro (cards)
surfaceElevated = #F3F4F6   // cinza neutro muito claro
textPrimary     = #111111   // preto puro
textSecondary   = #374151   // cinza neutro médio
textMuted       = #6B7280   // cinza neutro suave
border          = #E5E7EB   // cinza neutro claro

// Sem mudança:
success = #198754 | warning = #D97706 | error = #DC3545 | info = #0EA5E9
```

---

## Border Radius — Mapa

| Contexto | Valor |
|---|---|
| Cards, colunas kanban, modais principais | 20px |
| Botões, inputs, dialogs internos, error containers | 12px |
| Search panel / filter containers | 16px |
| Small badges (pill) | 6px |
| Chart bars | 4px (não muda) |
| Status badges | 20px (não muda) |

---

## Arquivos e Estratégia

**Fase 1 — tokens globais (propaga ~80% automaticamente):**
- [lib/core/theme/app_colors.dart](petra_erp/lib/core/theme/app_colors.dart) — nova paleta completa
- [lib/core/theme/app_theme.dart](petra_erp/lib/core/theme/app_theme.dart) — radius global, AppBar foreground branco, drawerTheme

**Fase 2 — widgets com valores hardcoded:**
- [lib/widgets/common/app_drawer.dart](petra_erp/lib/widgets/common/app_drawer.dart) — textos/ícones brancos na sidebar
- [lib/widgets/kanban/kanban_column.dart](petra_erp/lib/widgets/kanban/kanban_column.dart) — radius 20px, corrige badge contador invisível (bug: fundo = texto)
- [lib/widgets/kanban/os_card.dart](petra_erp/lib/widgets/kanban/os_card.dart) — radius 12px no card e ClipRRect
- [lib/screens/home/home_screen.dart](petra_erp/lib/screens/home/home_screen.dart) — stat cards 20px, banners 12px, search panel 16px

**Fase 3 — screens restantes (padrão uniforme):**
- Auth: card principal 20px, error container 12px, botão inline 12px
- OS Detail, Order List, Form screens: substituir `circular(8)` → `circular(12)`, `circular(16)` → `circular(20)` nos RoundedRectangleBorder
- Profile screen: card principal 16→20px
- Loading overlay: 12→16px

---

## Nota: Bug Visual Corrigido no Caminho

`kanban_column.dart` — o badge contador (número de OS por coluna) usa a mesma cor para fundo e texto, tornando o número invisível. Corrigir para `Colors.white.withOpacity(0.2)` no fundo e `Colors.white` no texto.

---

## Verificação

1. `flutter analyze lib/` — zero erros
2. Hot reload: verificar AppBar com texto branco, sidebar sólida, cards arredondados
3. Checklist manual por tela: login, dashboard, kanban, forms, profile
4. `flutter build windows --release` — build limpo
