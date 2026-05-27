import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/widgets.dart';

/// Screen listing all customers with search and access to creation/editing.
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
    final customersAsync = ref.watch(customerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(customerProvider.notifier).loadCustomers(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/customers/new'),
        child: const Icon(Icons.add),
      ),
      body: customersAsync.when(
        data: (customers) {
          // Filter customers based on search text
          final filtered = customers.where((c) {
            final query = _searchText.toLowerCase();
            final nameMatch = c.name.toLowerCase().contains(query);
            final phoneMatch = c.phone.replaceAll(RegExp(r'\D'), '').contains(query);
            final docMatch = (c.cpfCnpj ?? '').replaceAll(RegExp(r'\D'), '').contains(query);
            return nameMatch || phoneMatch || docMatch;
          }).toList();

          return Column(
            children: [
              // Search input bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nome, telefone ou CPF/CNPJ...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),

              // Customer List
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        title: 'Nenhum cliente cadastrado',
                        message: 'Utilize o botão de adicionar para cadastrar o primeiro cliente.',
                        icon: Icons.people_outline,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final customer = filtered[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              title: Text(
                                customer.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4.0),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, size: 14.0, color: AppColors.grey),
                                      const SizedBox(width: 6.0),
                                      Text(Formatters.formatPhone(customer.phone)),
                                    ],
                                  ),
                                  if (customer.cpfCnpj != null && customer.cpfCnpj!.isNotEmpty) ...[
                                    const SizedBox(height: 2.0),
                                    Row(
                                      children: [
                                        const Icon(Icons.badge, size: 14.0, color: AppColors.grey),
                                        const SizedBox(width: 6.0),
                                        Text(customer.cpfCnpj!),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppColors.primary),
                                    tooltip: 'Editar cliente',
                                    onPressed: () => context.push('/customers/${customer.id}/edit'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: AppColors.error),
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
                                              SnackBar(content: Text('Erro ao excluir cliente: $e'), backgroundColor: AppColors.error),
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
        error: (err, _) => Center(child: Text('Erro ao carregar clientes: $err')),
      ),
    );
  }
}
