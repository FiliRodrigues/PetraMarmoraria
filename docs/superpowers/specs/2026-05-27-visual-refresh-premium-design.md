# Petra ERP — Visual Refresh Premium
**Data:** 2026-05-27  
**Modo:** Light Refinado (login dark glass + app light elevado)  
**Abordagem:** B — Por camadas (tema + 5 componentes + 3 pacotes)

---

## Contexto

O app Petra ERP tem UI funcional mas genérica — sem personalidade de marca, sem profundidade visual, sem micro-animações. O objetivo é transformar a estética sem alterar nenhuma lógica de negócio, providers ou serviços.

**Escopo fixo:** só estética e UX visual. Zero mudança em models, providers, services, routing.

---

## 1. Paleta de Cores — AppColors

### Alterações em `lib/core/theme/app_colors.dart`

```dart
// Backgrounds — levemente azulados (mais identidade)
static const background       = Color(0xFFF0F4F8);  // era #F9FAFB
static const surface          = Color(0xFFFFFFFF);  // mantido
static const surfaceElevated  = Color(0xFFEDF2F7);  // era #F3F4F6

// Primary — mantido + novo escuro para hover
static const primary          = Color(0xFF0A3D62);  // mantido
static const primaryDark      = Color(0xFF082D49);  // novo: hover/pressed

// Status — mais saturados e elegantes
static const success          = Color(0xFF1A8A6A);  // era #198754
static const warning          = Color(0xFFC0802A);  // era #D97706
static const error            = Color(0xFFC0392B);  // era #DC3545
static const info             = Color(0xFF0EA5E9);  // mantido

// Texto — mantidos
// Bordas
static const border           = Color(0xFFD1D9E0);  // era #E5E7EB (mais suave)
static const borderFocus      = Color(0xFF0A3D62);  // novo: borda focused

// Sombras (para uso manual em BoxDecoration)
static const shadowCard       = Color(0x14000000);  // rgba(0,0,0,0.08)
static const shadowElevated   = Color(0x1F000000);  // rgba(0,0,0,0.12)
```

---

## 2. Tema Global — AppTheme

### Alterações em `lib/core/theme/app_theme.dart`

**cardTheme:**
```dart
cardTheme: CardThemeData(
  color: AppColors.surface,
  elevation: 2,
  shadowColor: AppColors.shadowCard,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),  // era 20, agora 16
    side: const BorderSide(color: AppColors.border, width: 0.8),
  ),
  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
),
```

**appBarTheme** — gradiente via FlexibleSpaceBar não é possível no AppBarTheme, mas manter `elevation: 0` e adicionar `shadowColor` para sombra suave:
```dart
appBarTheme: const AppBarTheme(
  backgroundColor: AppColors.navyBlue,
  foregroundColor: Colors.white,
  elevation: 1,
  shadowColor: Color(0x33000000),
  centerTitle: false,  // era center — mais profissional à esquerda
  ...
),
```

**elevatedButtonTheme** — padding mais generoso:
```dart
padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
```

**inputDecorationTheme** — usar nova `borderFocus`:
```dart
focusedBorder: OutlineInputBorder(
  borderRadius: BorderRadius.circular(10),
  borderSide: const BorderSide(color: AppColors.borderFocus, width: 1.5),
),
```

---

## 3. LoginScreen — Glassmorphism Dark

**Arquivo:** `lib/screens/auth/login_screen.dart`

### Estrutura
```
Scaffold(backgroundColor: Color(0xFF0d1621))
  └─ Stack
       ├─ _BackgroundOrbs()          — 2 orbs radiais posicionados
       └─ Center
            └─ FadeTransition + SlideTransition (já existentes)
                 └─ ClipRRect(radius: 24)
                      └─ BackdropFilter(blur: 20)
                           └─ Container (glass card)
                                └─ Form [campos existentes adaptados]
```

### Glass Card
```dart
Container(
  decoration: BoxDecoration(
    color: Colors.white.withOpacity(0.05),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.10)),
    boxShadow: [BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 40,
      offset: Offset(0, 20),
    )],
  ),
)
```

### Logo
```dart
Container(
  width: 72, height: 72,
  decoration: BoxDecoration(
    gradient: LinearGradient(colors: [Color(0xFF0A3D62), Color(0xFF1565a8)]),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [BoxShadow(color: Color(0x660A3D62), blurRadius: 20)],
  ),
  child: Icon(LucideIcons.gem, color: Colors.white, size: 32),
)
```

### Campos
- `fillColor: Colors.white.withOpacity(0.07)`
- `labelStyle: TextStyle(color: Colors.white70)`
- `hintStyle: TextStyle(color: Colors.white38)`
- Ícones brancos

### Widget `_BackgroundOrbs` (novo, privado)
```dart
Positioned(top: -60, right: -60, child: _Orb(size: 220, color: Color(0xFF0A3D62))),
Positioned(bottom: -40, left: -40, child: _Orb(size: 180, color: Color(0xFF1A5276))),
```

### Animação (flutter_animate)
```dart
Form(...).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0)
```

---

## 4. AppDrawer — Sidebar Premium

**Arquivo:** `lib/widgets/common/app_drawer.dart`

### Header
- Logo: container `44×44`, `borderRadius: 12`, gradiente primary  
- Avatar: `40×40`, `borderRadius: 10` (quadrado arredondado, não círculo)  
- Badge de role: chip `ADMIN`/`MEMBRO` colorido (azul claro para admin, cinza para membro)  

### Seções categorizadas
Adicionar labels de seção entre grupos:
- **PRINCIPAL** → Painel Kanban, Ordens de Serviço  
- **CADASTROS** → Clientes, Funcionários (admin), Produtos  
- **ANÁLISE** → Relatórios  
- **CONTA** → Meu Perfil  

### Item ativo
```dart
// Sem border left hard — substituir por:
decoration: BoxDecoration(
  color: Colors.white.withOpacity(0.15),
  borderRadius: BorderRadius.circular(10),
)
```

### Hover
Envolver cada `_buildItem` em `StatefulBuilder` ou `_HoverableItem` com `AnimatedContainer`:
```dart
color: _isHovered ? Colors.white.withOpacity(0.08) : Colors.transparent
```

---

## 5. OSCard — Cards com Elevation

**Arquivo:** `lib/widgets/kanban/os_card.dart`

### Sombra real
```dart
Card(
  elevation: 0,
  shape: ...,
  shadowColor: AppColors.shadowCard,
)
// Adicionar BoxDecoration com boxShadow no Container interior:
boxShadow: [BoxShadow(
  color: AppColors.shadowCard,
  blurRadius: 8,
  offset: Offset(0, 2),
)]
```

### Badge de staleness
Substituir o texto `'$days d'` por chip colorido:
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  decoration: BoxDecoration(
    color: stalenessColor.withOpacity(0.12),
    borderRadius: BorderRadius.circular(6),
    border: Border.all(color: stalenessColor.withOpacity(0.3)),
  ),
  child: Text(
    days == 0 ? 'Hoje' : '$days d',
    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: stalenessColor),
  ),
)
```

### Hover com elevação
Modificar `_HoverableCardState` para adicionar `Transform.translate`:
```dart
Transform.translate(
  offset: Offset(0, _isHovered ? -2 : 0),
  child: AnimatedContainer(
    duration: Duration(milliseconds: 150),
    decoration: BoxDecoration(boxShadow: _isHovered ? [BoxShadow(blurRadius: 16, ...)] : []),
    child: widget.child,
  ),
)
```

### Animação de entrada (flutter_animate)
No `KanbanColumn.ListView.builder`:
```dart
OSCard(order: orders[index])
  .animate(delay: (index * 50).ms)
  .fadeIn(duration: 300.ms)
  .slideX(begin: 0.05, end: 0)
```

---

## 6. Stat Cards — Semânticos e Clicáveis

**Arquivo:** `lib/screens/home/home_screen.dart` — método `_buildStatCard`

### Nova assinatura
```dart
Widget _buildStatCard(
  String label, 
  String value, 
  IconData icon, 
  Color color, {
  String? subLabel,      // ex: "ação imediata"
  VoidCallback? onTap,   // filtro ao clicar
})
```

### Estrutura
```dart
InkWell(
  onTap: onTap,
  borderRadius: BorderRadius.circular(16),
  child: Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: AppColors.shadowCard, blurRadius: 8, offset: Offset(0,2))],
    ),
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(  // ícone colorido
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        SizedBox(height: 12),
        Text(value, style: TextStyle(fontFamily: 'Syne', fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.primary)),
        SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (subLabel != null) ...[
          SizedBox(height: 4),
          Text(subLabel, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
        ],
      ],
    ),
  ),
).animate().fadeIn(duration: 400.ms).scale(begin: Offset(0.96, 0.96))
```

### Chamadas atualizadas
```dart
_buildStatCard('Total OS', '$totalCount', LucideIcons.clipboardList, Colors.blue,
  subLabel: 'em produção'),
_buildStatCard('Orçamentos', '$orcamentoCount', LucideIcons.fileText, Colors.amber,
  subLabel: orcamentoCount > 0 ? 'aguardando aprovação' : null,
  onTap: () => /* filtrar */),
_buildStatCard('Entrega Hoje', '$entregaHojeCount', LucideIcons.calendarCheck, AppColors.success,
  subLabel: entregaHojeCount > 0 ? 'atenção hoje' : 'nenhuma',
  onTap: () => setState(() => _onlyEntregaHoje = true)),
_buildStatCard('Vencidas', '$vencidasCount', LucideIcons.calendarX, AppColors.error,
  subLabel: vencidasCount > 0 ? 'ação imediata' : 'em dia',
  onTap: () => setState(() => _onlyDelayed = true)),
```

---

## 7. Skeleton Loading — Shimmer

**Novos widgets em** `lib/widgets/common/skeleton_card.dart`  
Substituir o loader `CircularProgressIndicator` no `osProvider.when(loading:)` por:

```dart
loading: () => ListView.builder(
  padding: EdgeInsets.symmetric(vertical: 8),
  itemCount: 6,
  itemBuilder: (_, __) => const _SkeletonOSCard(),
),
```

`_SkeletonOSCard` usa o pacote `shimmer` para simular a forma de um `OSCard`.

---

## 8. Toastification — Feedback Premium

**Substituir** todos os `ScaffoldMessenger.of(context).showSnackBar(...)` por:

```dart
toastification.show(
  context: context,
  type: ToastificationType.success,
  style: ToastificationStyle.flatColored,
  title: Text('OS Salva'),
  description: Text('OS-XXXX foi criada com sucesso.'),
  autoCloseDuration: const Duration(seconds: 4),
  alignment: Alignment.topRight,
)
```

Pontos de integração:
- `os_form_screen.dart` — save/update
- `os_detail_screen.dart` — transições de status
- `customer_form_screen.dart` — save/update
- `product_form_screen.dart` — save/update

---

## 9. Pacotes a Adicionar em pubspec.yaml

```yaml
flutter_animate: ^4.5.0
shimmer: ^3.0.0
toastification: ^2.1.0
```

---

## Arquivos a Modificar

| Arquivo | Tipo de mudança |
|---------|----------------|
| `lib/core/theme/app_colors.dart` | Refinar paleta |
| `lib/core/theme/app_theme.dart` | Elevation, borders, button |
| `lib/screens/auth/login_screen.dart` | Glass dark + orbs |
| `lib/widgets/common/app_drawer.dart` | Seções + hover + avatar |
| `lib/widgets/kanban/os_card.dart` | Shadow + badge chip + hover |
| `lib/widgets/kanban/kanban_column.dart` | Animação stagger nos cards |
| `lib/screens/home/home_screen.dart` | Stat cards semânticos |
| `lib/widgets/common/skeleton_card.dart` | **NOVO** — shimmer loading |
| `petra_erp/pubspec.yaml` | 3 novos pacotes |

**Arquivos NÃO tocados:** providers, services, models, routing, PDF, validators.

---

## Critérios de Sucesso

- [ ] App compila sem erros após mudanças  
- [ ] Login screen tem fundo dark e card glass  
- [ ] Sidebar tem seções categorizadas e role badge  
- [ ] OSCards têm shadow, badge chip e hover elevado  
- [ ] Stat cards são clicáveis e aplicam filtro  
- [ ] Loading exibe skeleton em vez de spinner  
- [ ] Toasts substituem SnackBar nos formulários  
- [ ] Nenhuma lógica de negócio alterada  
