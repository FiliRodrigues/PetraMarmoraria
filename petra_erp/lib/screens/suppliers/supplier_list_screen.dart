import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/supplier_provider.dart';
import '../../widgets/widgets.dart';

class SupplierListScreen extends ConsumerStatefulWidget {
  const SupplierListScreen({super.key});

  @override
  ConsumerState<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends ConsumerState<SupplierListScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _searchText = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(supplierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Fornecedores'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.read(supplierProvider.notifier).loadSuppliers(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/suppliers/new'),
        child: const Icon(LucideIcons.plus, size: 20),
      ),
      body: suppliersAsync.when(
        data: (suppliers) {
          final filtered = suppliers.where((s) {
            final query = _searchText.toLowerCase();
            final nameMatch = s.name.toLowerCase().contains(query);
            final phoneMatch = s.phone.replaceAll(RegExp(r'\D'), '').contains(query);
            final docMatch = (s.cpfCnpj ?? '').replaceAll(RegExp(r'\D'), '').contains(query);
            return nameMatch || phoneMatch || docMatch;
          }).toList();

          return Column(
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
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        title: 'Nenhum fornecedor cadastrado',
                        message: 'Utilize o botão de adicionar para cadastrar o primeiro fornecedor.',
                        icon: LucideIcons.truck,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final supplier = filtered[index];
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
                              title: Text(supplier.name,
                                style: AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.phone, size: 13, color: AppColors.textMuted),
                                      const SizedBox(width: 6),
                                      Text(Formatters.formatPhone(supplier.phone),
                                        style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted)),
                                    ],
                                  ),
                                  if (supplier.cpfCnpj != null && supplier.cpfCnpj!.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.creditCard, size: 13, color: AppColors.textMuted),
                                        const SizedBox(width: 6),
                                        Text(supplier.cpfCnpj!,
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
                                    tooltip: 'Editar fornecedor',
                                    onPressed: () => context.push('/suppliers/${supplier.id}/edit'),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, size: 16, color: AppColors.error),
                                    tooltip: 'Excluir fornecedor',
                                    onPressed: () async {
                                      final confirm = await ConfirmDialog.show(
                                        context,
                                        title: 'Confirmar Exclusão',
                                        content: 'Deseja realmente excluir o fornecedor "${supplier.name}"? Todos os dados associados podem ser afetados.',
                                        confirmColor: AppColors.error,
                                      );
                                      if (confirm) {
                                        try {
                                          await ref.read(supplierProvider.notifier).deleteSupplier(supplier.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Fornecedor excluído com sucesso!')),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Erro ao excluir fornecedor: $e'),
                                                backgroundColor: AppColors.error),
                                            );
                                          }
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () => context.push('/suppliers/${supplier.id}'),
                            ),
                          );
                        },
                    ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Erro ao carregar fornecedores: $err',
            style: AppTheme.jakarta(color: AppColors.error))),
      ),
    );
  }
}
