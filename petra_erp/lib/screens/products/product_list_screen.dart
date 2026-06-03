import 'package:flutter/material.dart';
import '../../core/utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../widgets/widgets.dart';
import '../service_orders/os_list_screen.dart' show SearchField, NewButton;

/// Cor associada a cada categoria de material.
Color _categoryColor(String type) {
  switch (type.toLowerCase()) {
    case 'marmore':
      return const Color(0xFF9A6B2A);
    case 'granito':
      return const Color(0xFF374151);
    case 'quartzo':
      return const Color(0xFF6058D0);
    case 'outro':
      return const Color(0xFF0D8B7E);
    default:
      return AppColors.textMuted;
  }
}

const Map<String, String> _categoryLabels = {
  'marmore': 'Mármore',
  'granito': 'Granito',
  'quartzo': 'Quartzo',
  'outro': 'Outro',
};

String _capitalize(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

/// Lista de produtos/materiais em grid de cards, com filtro por categoria.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() =>
      _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';
  String? _categoryFilter; // null = Todos

  static const List<String> _categories = [
    'marmore',
    'granito',
    'quartzo',
    'outro',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Produtos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: () => ref.read(productProvider.notifier).loadProducts(),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(friendlyError(err))),
        data: (products) {
          final query = _searchText.trim().toLowerCase();
          final filtered = products.where((p) {
            final matchesQuery =
                query.isEmpty || p.name.toLowerCase().contains(query);
            final matchesCat =
                _categoryFilter == null || p.type == _categoryFilter;
            return matchesQuery && matchesCat;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProductHeader(
                subtitle: '${products.length} materiais no catálogo',
                searchController: _searchController,
                onNew: () => context.push('/products/new'),
              ),
              _CategoryChips(
                categories: _categories,
                selected: _categoryFilter,
                onSelect: (c) => setState(() => _categoryFilter = c),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        title: 'Nenhum material encontrado',
                        message:
                            'Ajuste os filtros ou cadastre um novo material.',
                        icon: Icons.category_outlined,
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 320,
                          mainAxisExtent: 168,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) =>
                            _ProductCard(product: filtered[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final Product product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final color = _categoryColor(p.type);
    final catLabel = _categoryLabels[p.type.toLowerCase()] ?? _capitalize(p.type);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.push('/products/${p.id}/edit'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: _hover ? AppColors.accent : AppColors.border,
            ),
            boxShadow: _hover ? AppTheme.shadowMedium : AppTheme.shadowSoft,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Faixa de cor da categoria
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.55)],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.jakarta(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _Tag(
                            label: catLabel,
                            color: color,
                          ),
                          const SizedBox(width: 8),
                          _Tag(
                            label: p.active ? 'Ativo' : 'Inativo',
                            color: p.active
                                ? AppColors.success
                                : AppColors.error,
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            Formatters.formatCurrency(p.unitPrice),
                            style: AppTheme.numeric(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'por ${p.unit}',
                            style: AppTheme.jakarta(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: AppTheme.jakarta(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _CatChip(
            label: 'Todos',
            color: AppColors.primary,
            active: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final c in categories)
            _CatChip(
              label: _categoryLabels[c] ?? _capitalize(c),
              color: _categoryColor(c),
              active: selected == c,
              onTap: () => onSelect(c),
            ),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            border: Border.all(color: active ? color : AppColors.border),
          ),
          child: Text(
            label,
            style: AppTheme.jakarta(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductHeader extends StatelessWidget {
  final String subtitle;
  final TextEditingController searchController;
  final VoidCallback onNew;

  const _ProductHeader({
    required this.subtitle,
    required this.searchController,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 560;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Produtos',
                style: AppTheme.syne(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.jakarta(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        controller: searchController,
                        hint: 'Buscar por nome...',
                      ),
                    ),
                    const SizedBox(width: 10),
                    NewButton(label: 'Novo Produto', onPressed: onNew),
                  ],
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleBlock,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 240,
                    child: SearchField(
                      controller: searchController,
                      hint: 'Buscar por nome...',
                    ),
                  ),
                  const SizedBox(width: 10),
                  NewButton(label: 'Novo Produto', onPressed: onNew),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
