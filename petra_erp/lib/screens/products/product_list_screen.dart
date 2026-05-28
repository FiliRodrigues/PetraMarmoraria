import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/product_provider.dart';
import '../../widgets/widgets.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    ref.read(productPagedProvider.notifier).refresh(
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(productPagedProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paged = ref.watch(productPagedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Materiais'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.read(productPagedProvider.notifier).refresh(
              search: _searchController.text.isEmpty ? null : _searchController.text,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/products/new'),
        child: const Icon(LucideIcons.plus, size: 20),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome ou tipo de material...',
                prefixIcon: Icon(LucideIcons.search, size: 16),
              ),
            ),
          ),
          if (paged.error != null && paged.items.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Erro ao carregar catálogo: ${paged.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: const Text('Tentar novamente'),
                      onPressed: () => ref.read(productPagedProvider.notifier).refresh(),
                    ),
                  ],
                ),
              ),
            )
          else if (paged.items.isEmpty && paged.isLoadingMore)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (paged.items.isEmpty)
            const Expanded(
              child: EmptyState(
                title: 'Nenhum material cadastrado',
                message: 'Utilize o botão de adicionar para cadastrar o primeiro material no catálogo.',
                icon: LucideIcons.package,
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: paged.items.length + (paged.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == paged.items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final product = paged.items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
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
                                    ref.read(productPagedProvider.notifier).refresh();
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
      ),
    );
  }
}
