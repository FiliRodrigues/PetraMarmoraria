import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/product_provider.dart';
import '../../widgets/widgets.dart';

/// Screen displaying the list of catalog materials/products with search and deletion capabilities.
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
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
        title: const Text('Catálogo de Materiais'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.read(productProvider.notifier).loadProducts(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/products/new'),
        child: const Icon(LucideIcons.plus, size: 20),
      ),
      body: productsAsync.when(
        data: (products) {
          final filtered = products.where((p) {
            final query = _searchText.toLowerCase();
            final nameMatch = p.name.toLowerCase().contains(query);
            final typeMatch = p.type.toLowerCase().contains(query);
            return nameMatch || typeMatch;
          }).toList();

          return Column(
            children: [
              // Search field
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nome ou tipo de material...',
                    prefixIcon: const Icon(LucideIcons.search, size: 16),
                  ),
                ),
              ),

              // Products list
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        title: 'Nenhum material cadastrado',
                        message: 'Utilize o botão de adicionar para cadastrar o primeiro material no catálogo.',
                        icon: LucideIcons.package,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final product = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(LucideIcons.layers, size: 18, color: AppColors.primary),
                              ),
                              title: Text(product.name,
                                style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w700)),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text('Tipo: ${product.type.toUpperCase()}',
                                  style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted)),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${Formatters.formatCurrency(product.unitPrice)}/${product.unit}',
                                    style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(LucideIcons.edit, size: 16, color: AppColors.primary),
                                    onPressed: () => context.push('/products/${product.id}/edit'),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                                    onPressed: () async {
                                      final confirm = await ConfirmDialog.show(
                                        context,
                                        title: 'Excluir Produto',
                                        content: 'Deseja realmente remover o material "${product.name}" do catálogo?',
                                        confirmColor: AppColors.error,
                                      );

                                      if (confirm) {
                                        try {
                                          await ref.read(productProvider.notifier).deleteProduct(product.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Produto excluído com sucesso!')),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Erro ao excluir produto: $e'), backgroundColor: AppColors.error),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro ao carregar catálogo: $err')),
      ),
    );
  }
}
