import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../providers/customer_provider.dart';
import '../../providers/os_provider.dart';
import '../../widgets/widgets.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String id;
  const CustomerDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customerProvider);
    final ordersAsync    = ref.watch(osProvider);
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat     = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Cliente'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit, size: 18),
            tooltip: 'Editar Cliente',
            onPressed: () => context.push('/customers/$id/edit'),
          ),
        ],
      ),
      body: customersAsync.when(
        data: (customers) {
          final index = customers.indexWhere((c) => c.id == id);
          if (index == -1) {
            return Center(child: Text('Cliente não encontrado.', style: AppTheme.jakarta(color: AppColors.textMuted)));
          }
          final customer = customers[index];
          final initials = customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header card ──────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            ),
                            alignment: Alignment.center,
                            child: Text(initials,
                              style: AppTheme.syne(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(customer.name,
                                  style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w800)),
                                if (customer.cpfCnpj != null) ...[
                                  const SizedBox(height: 3),
                                  Text(customer.cpfCnpj!,
                                    style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted)),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _InfoItem(LucideIcons.phone, 'Telefone Principal',
                              Formatters.formatPhone(customer.phone))),
                          if (customer.phone2 != null)
                            Expanded(child: _InfoItem(LucideIcons.smartphone, 'Telefone 2',
                                Formatters.formatPhone(customer.phone2!))),
                        ],
                      ),
                      if (customer.email != null || customer.address != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (customer.email != null)
                              Expanded(child: _InfoItem(LucideIcons.mail, 'E-mail', customer.email!)),
                            if (customer.address != null)
                              Expanded(child: _InfoItem(LucideIcons.mapPin, 'Endereço', customer.address!)),
                          ],
                        ),
                      ],
                      if (customer.city != null) ...[
                        const SizedBox(height: 14),
                        _InfoItem(LucideIcons.building2, 'Cidade / Estado',
                            '${customer.city} / ${customer.state ?? "-"}'),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (customer.phone.isNotEmpty)
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(LucideIcons.phone, size: 14),
                                label: Text('Ligar', style: TextStyle(fontSize: 12)),
                                onPressed: () => launchUrl(Uri.parse('tel:${customer.phone.replaceAll(RegExp(r'\D'), '')}')),
                              ),
                            ),
                          if (customer.phone.isNotEmpty) SizedBox(width: 8),
                          if (customer.phone.isNotEmpty)
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: Icon(LucideIcons.messageCircle, size: 14),
                                label: Text('WhatsApp', style: TextStyle(fontSize: 12)),
                                onPressed: () => launchUrl(Uri.parse('https://wa.me/55${customer.phone.replaceAll(RegExp(r'\D'), '')}')),
                              ),
                            ),
                          if (customer.phone.isNotEmpty) SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(LucideIcons.copy, size: 14),
                              label: Text('Copiar', style: TextStyle(fontSize: 12)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: customer.phone));
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Telefone copiado!')));
                              },
                            ),
                          ),
                        ],
                      ),
                      if (customer.notes != null) ...[
                        const SizedBox(height: 14),
                        _InfoItem(LucideIcons.fileText, 'Observações', customer.notes!),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── OS History ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Histórico de OS',
                      style: AppTheme.syne(fontSize: 14, fontWeight: FontWeight.w700)),
                    GestureDetector(
                      onTap: () => context.push('/orders/new?customerId=$id'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(LucideIcons.plus, size: 13, color: Colors.white),
                          const SizedBox(width: 5),
                          Text('Nova OS', style: AppTheme.jakarta(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ordersAsync.when(
                  data: (orders) {
                    final customerOrders = orders.where((o) => o.customerId == id).toList();
                    if (customerOrders.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Center(child: Text('Nenhuma OS para este cliente.',
                          style: AppTheme.jakarta(color: AppColors.textMuted))),
                      );
                    }
                    return Column(
                      children: customerOrders.map((order) {
                        final staleColor = AppColors.stalenessColor(order.daysStale);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                            border: Border(
                              left:   BorderSide(color: staleColor, width: 3),
                              top:    BorderSide(color: AppColors.border),
                              right:  BorderSide(color: AppColors.border),
                              bottom: BorderSide(color: AppColors.border),
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            title: Row(
                              children: [
                                Text(order.formattedNumber,
                                  style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                const SizedBox(width: 8),
                                StatusBadge(status: order.status, small: true),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(order.material ?? 'Sem material', style: AppTheme.jakarta(fontSize: 12)),
                                Text('Criada ${dateFormat.format(order.createdAt)}',
                                  style: AppTheme.jakarta(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(currencyFormat.format(order.totalValue),
                                  style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
                              ],
                            ),
                            onTap: () => context.push('/orders/${order.id}'),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Erro: $err', style: AppTheme.jakarta(color: AppColors.error))),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err', style: AppTheme.jakarta(color: AppColors.error))),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoItem(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 14, color: AppColors.accent),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTheme.jakarta(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(value, style: AppTheme.jakarta(fontSize: 13.5, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ],
  );
}
