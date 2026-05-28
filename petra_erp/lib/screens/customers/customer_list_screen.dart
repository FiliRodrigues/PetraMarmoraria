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
    final customersAsync = ref.watch(customerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Clientes'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.read(customerProvider.notifier).loadCustomers(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/customers/new'),
        child: const Icon(LucideIcons.plus, size: 20),
      ),
      body: customersAsync.when(
        data: (customers) {
          final filtered = customers.where((c) {
            final query = _searchText.toLowerCase();
            final nameMatch = c.name.toLowerCase().contains(query);
            final phoneMatch = c.phone.replaceAll(RegExp(r'\D'), '').contains(query);
            final docMatch = (c.cpfCnpj ?? '').replaceAll(RegExp(r'\D'), '').contains(query);
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
                        title: 'Nenhum cliente cadastrado',
                        message: 'Utilize o botão de adicionar para cadastrar o primeiro cliente.',
                        icon: LucideIcons.users,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(customer.name,
                                style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w700)),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Erro ao carregar clientes: $err',
            style: AppTheme.jakarta(color: AppColors.error))),
      ),
    );
  }
}
