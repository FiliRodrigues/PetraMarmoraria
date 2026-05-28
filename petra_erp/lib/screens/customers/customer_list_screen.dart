import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/widgets.dart';

class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    ref.read(customerPagedProvider.notifier).refresh(
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(customerPagedProvider.notifier).loadMore();
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
    final paged = ref.watch(customerPagedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Clientes'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.read(customerPagedProvider.notifier).refresh(
              search: _searchController.text.isEmpty ? null : _searchController.text,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/customers/new'),
        child: const Icon(LucideIcons.plus, size: 20),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar por nome, telefone ou CPF/CNPJ...',
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
                    Text('Erro ao carregar clientes: ${paged.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(LucideIcons.refreshCw, size: 16),
                      label: const Text('Tentar novamente'),
                      onPressed: () => ref.read(customerPagedProvider.notifier).refresh(),
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
                title: 'Nenhum cliente cadastrado',
                message: 'Utilize o botão de adicionar para cadastrar o primeiro cliente.',
                icon: LucideIcons.users,
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: paged.items.length + (paged.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == paged.items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final customer = paged.items[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.shadowSm,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(customer.name,
                        style: AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(LucideIcons.phone, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Text(Formatters.formatPhone(customer.phone),
                                style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                          if (customer.cpfCnpj != null && customer.cpfCnpj!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(LucideIcons.creditCard, size: 13, color: AppColors.textMuted),
                                const SizedBox(width: 6),
                                Text(customer.cpfCnpj!,
                                  style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(LucideIcons.edit, size: 16, color: AppColors.primary),
                            tooltip: 'Editar cliente',
                            onPressed: () => context.push('/customers/${customer.id}/edit'),
                          ),
                          IconButton(
                            icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                            tooltip: 'Excluir cliente',
                            onPressed: () async {
                              final confirm = await ConfirmDialog.show(
                                context,
                                title: 'Confirmar Exclusão',
                                content: 'Deseja realmente excluir o cliente "${customer.name}"? Todos os históricos associados podem ser afetados.',
                                confirmColor: AppColors.error,
                              );
                              if (confirm) {
                                try {
                                  await ref.read(customerProvider.notifier).deleteCustomer(customer.id);
                                  if (context.mounted) {
                                    ref.read(customerPagedProvider.notifier).refresh();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Cliente excluído com sucesso!')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Erro ao excluir cliente: $e'),
                                        backgroundColor: AppColors.error),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ],
                      ),
                      onTap: () => context.push('/customers/${customer.id}'),
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
