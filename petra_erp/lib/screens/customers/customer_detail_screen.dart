import 'package:flutter/material.dart';
import '../../core/utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/customer_provider.dart';
import '../../providers/os_provider.dart';
import '../../widgets/widgets.dart';

/// Screen showing detailed profile information of a customer along with their Service Order history.
class CustomerDetailScreen extends ConsumerWidget {
  final String id;

  const CustomerDetailScreen({super.key, required this.id});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Excluir Cliente',
      content:
          'Tem certeza que deseja excluir este cliente? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (!ok) return;
    try {
      await ref.read(customerProvider.notifier).deleteCustomer(id);
      if (context.mounted) {
        AppSnackbar.success(context, 'Cliente excluído.');
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerProvider);
    final ordersAsync = ref.watch(osProvider);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Cliente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Editar Cliente',
            onPressed: () => context.push('/customers/$id/edit'),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Excluir Cliente',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: customersAsync.when(
        data: (customers) {
          final index = customers.indexWhere((c) => c.id == id);
          if (index == -1) {
            return const Center(child: Text('Cliente não encontrado.'));
          }
          final customer = customers[index];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Information Header Card
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.primary,
                              radius: 28.0,
                              child: Icon(Icons.person, size: 28.0),
                            ),
                            const SizedBox(width: 16.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.name,
                                    style: AppTheme.syne(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (customer.cpfCnpj != null) ...[
                                    const SizedBox(height: 4.0),
                                    Text(
                                      customer.cpfCnpj!,
                                      style: AppTheme.numeric(
                                        color: AppColors.grey,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 32.0),

                        // Formatted Fields Grid
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                Icons.phone,
                                'Telefone Principal',
                                Formatters.formatPhone(customer.phone),
                              ),
                            ),
                            if (customer.phone2 != null)
                              Expanded(
                                child: _buildInfoItem(
                                  Icons.phone_iphone,
                                  'Telefone Secundário',
                                  Formatters.formatPhone(customer.phone2!),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16.0),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (customer.email != null)
                              Expanded(
                                child: _buildInfoItem(
                                  Icons.email,
                                  'E-mail',
                                  customer.email!,
                                ),
                              ),
                            Expanded(
                              child: _buildInfoItem(
                                Icons.location_on,
                                'Endereço',
                                customer.address ?? 'Não informado',
                              ),
                            ),
                          ],
                        ),
                        if (customer.city != null) ...[
                          const SizedBox(height: 16.0),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  Icons.location_city,
                                  'Cidade / Estado',
                                  '${customer.city} / ${customer.state}',
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (customer.notes != null) ...[
                          const SizedBox(height: 16.0),
                          _buildInfoItem(
                            Icons.note,
                            'Observações Internas',
                            customer.notes!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24.0),

                // OS History Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Histórico de Ordens de Serviço',
                      style: AppTheme.syne(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Pass this customer ID as a query param so OS Form links it automatically
                        context.push('/orders/new?customerId=$id');
                      },
                      icon: const Icon(Icons.add, size: 16.0),
                      label: const Text('Nova OS'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),

                // OS List Loader
                ordersAsync.when(
                  data: (orders) {
                    final customerOrders = orders
                        .where((o) => o.customerId == id)
                        .toList();

                    if (customerOrders.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Text(
                            'Nenhuma ordem de serviço registrada para este cliente.',
                            textAlign: TextAlign.center,
                            style: AppTheme.jakarta(color: AppColors.grey),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: customerOrders.length,
                      itemBuilder: (context, index) {
                        final order = customerOrders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8.0),
                          child: ListTile(
                            leading: Container(
                              width: 6,
                              decoration: BoxDecoration(
                                color: order.daysStale <= 2
                                    ? AppColors.success
                                    : order.daysStale <= 5
                                    ? AppColors.warning
                                    : AppColors.error,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  order.formattedNumber,
                                  style: AppTheme.numeric(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                StatusBadge(status: order.status),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4.0),
                                Text(
                                  order.material ?? 'Sem material informado',
                                ),
                                Text(
                                  'Criada em ${dateFormat.format(order.createdAt)}',
                                  style: AppTheme.jakarta(
                                    fontSize: 11,
                                    color: AppColors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currencyFormat.format(order.totalValue),
                                  style: AppTheme.numeric(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 18.0),
                              ],
                            ),
                            onTap: () => context.push('/orders/${order.id}'),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text(friendlyError(err))),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(friendlyError(err))),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18.0, color: AppColors.secondary),
        const SizedBox(width: 8.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.jakarta(
                  fontSize: 11,
                  color: AppColors.grey,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: AppTheme.jakarta(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
