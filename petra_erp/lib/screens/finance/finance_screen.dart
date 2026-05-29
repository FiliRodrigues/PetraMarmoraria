import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/payment_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

/// Tela Financeira: recebíveis (pagamentos pendentes/pagos) com KPIs e lista
/// ordenada por vencimento. Toque numa linha abre a OS correspondente.
class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen> {
  String _statusFilter = 'pendente'; // pendente | pago | todos

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.read(paymentProvider.notifier).loadAll(),
          ),
        ],
      ),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro ao carregar financeiro: $err')),
        data: (payments) {
          final pendentes = payments.where((p) => !p.isPaid).toList();
          final vencidos = payments.where((p) => p.isOverdue).toList();
          final now = DateTime.now();
          final recebidoMes = payments
              .where((p) => p.isPaid && p.paidAt != null &&
                  p.paidAt!.year == now.year && p.paidAt!.month == now.month)
              .fold<double>(0, (s, p) => s + p.amount);
          final aReceber = pendentes.fold<double>(0, (s, p) => s + p.amount);
          final vencidoTotal = vencidos.fold<double>(0, (s, p) => s + p.amount);
          final osComSaldo = pendentes.map((p) => p.orderId).toSet().length;

          final visible = switch (_statusFilter) {
            'pago' => payments.where((p) => p.isPaid).toList(),
            'todos' => payments,
            _ => pendentes,
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // KPIs
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    _Kpi(
                      label: 'A receber',
                      value: Formatters.formatCurrency(aReceber),
                      color: AppColors.accent,
                      icon: LucideIcons.wallet,
                    ),
                    const SizedBox(width: 10),
                    _Kpi(
                      label: 'Vencido',
                      value: Formatters.formatCurrency(vencidoTotal),
                      color: AppColors.staleCrit,
                      icon: LucideIcons.alertTriangle,
                    ),
                    const SizedBox(width: 10),
                    _Kpi(
                      label: 'Recebido (mês)',
                      value: Formatters.formatCurrency(recebidoMes),
                      color: AppColors.staleOk,
                      icon: LucideIcons.checkCircle,
                    ),
                    const SizedBox(width: 10),
                    _Kpi(
                      label: 'OS com saldo',
                      value: '$osComSaldo',
                      color: AppColors.primary,
                      icon: LucideIcons.fileText,
                    ),
                  ],
                ),
              ),

              // Filtro de status
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Pendentes',
                      selected: _statusFilter == 'pendente',
                      onTap: () => setState(() => _statusFilter = 'pendente'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Pagos',
                      selected: _statusFilter == 'pago',
                      onTap: () => setState(() => _statusFilter = 'pago'),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Todos',
                      selected: _statusFilter == 'todos',
                      onTap: () => setState(() => _statusFilter = 'todos'),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: visible.isEmpty
                    ? const EmptyState(
                        title: 'Nenhum recebível',
                        message: 'Registre pagamentos no detalhe de uma Ordem de Serviço.',
                        icon: LucideIcons.wallet,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        itemCount: visible.length,
                        itemBuilder: (context, i) => _PaymentTile(payment: visible[i]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _Kpi({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.jakarta(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.numeric(fontSize: 16, fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTheme.jakarta(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final overdue = payment.isOverdue;
    final paid = payment.isPaid;
    final color = paid
        ? AppColors.staleOk
        : (overdue ? AppColors.staleCrit : AppColors.accent);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: overdue ? AppColors.staleCrit.withValues(alpha: 0.5) : AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            paid ? LucideIcons.checkCircle : (overdue ? LucideIcons.alertTriangle : LucideIcons.clock),
            size: 18, color: color,
          ),
        ),
        title: Text(
          payment.customerName ?? 'Cliente',
          style: AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${Formatters.formatOSNumber(payment.orderNumber)} · '
            '${PaymentConstants.methodLabel(payment.method)}'
            '${payment.dueDate != null ? ' · venc. ${AppDateUtils.formatDate(payment.dueDate)}' : ''}',
            style: AppTheme.jakarta(fontSize: 11.5, color: AppColors.textMuted),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Formatters.formatCurrency(payment.amount),
              style: AppTheme.numeric(fontSize: 15, fontWeight: FontWeight.w800, color: color),
            ),
            Text(
              paid ? 'Pago' : (overdue ? 'Vencido' : 'Pendente'),
              style: AppTheme.jakarta(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        onTap: () => context.go('/orders/${payment.orderId}'),
      ),
    );
  }
}
