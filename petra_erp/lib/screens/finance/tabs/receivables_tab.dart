import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../providers/providers.dart';
import '../../../../widgets/common/confirm_dialog.dart';
import '../../../../widgets/widgets.dart';

/// Tab de recebíveis — KPIs + filtro por status + lista de PaymentTile.
class ReceivablesTab extends ConsumerStatefulWidget {
  const ReceivablesTab({super.key});

  @override
  ConsumerState<ReceivablesTab> createState() => _ReceivablesTabState();
}

class _ReceivablesTabState extends ConsumerState<ReceivablesTab> {
  String _statusFilter = 'pendente'; // pendente | pago | todos

  // ── Handlers ──

  Future<void> _markPaid(payment) async {
    await ref.read(paymentProvider.notifier).markPaid(payment);
  }

  Future<void> _delete(payment) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Excluir pagamento',
      content: 'Tem certeza que deseja excluir este pagamento?',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (ok) {
      await ref.read(paymentProvider.notifier).delete(payment);
    }
  }

  void _showContextMenu(BuildContext context, payment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.checkCircle, size: 20, color: AppColors.staleOk),
                title: const Text('Marcar como Pago'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _markPaid(payment);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.trash2, size: 20, color: AppColors.error),
                title: const Text('Excluir'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _delete(payment);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final paymentsAsync = ref.watch(paymentProvider);

    return paymentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertTriangle, size: 40, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                'Erro ao carregar recebíveis',
                style: AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Tentar novamente',
                size: AppButtonSize.sm,
                onPressed: () => ref.read(paymentProvider.notifier).loadAll(),
              ),
            ],
          ),
        ),
      ),
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

        return RefreshIndicator(
          onRefresh: () => ref.read(paymentProvider.notifier).loadAll(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // KPIs
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: ResponsiveKpiGrid(
                  gap: 10,
                  children: [
                    _Kpi(
                      label: 'A receber',
                      value: Formatters.formatCurrency(aReceber),
                      color: AppColors.accent,
                      icon: LucideIcons.wallet,
                    ),
                    _Kpi(
                      label: 'Vencido',
                      value: Formatters.formatCurrency(vencidoTotal),
                      color: AppColors.staleCrit,
                      icon: LucideIcons.alertTriangle,
                    ),
                    _Kpi(
                      label: 'Recebido (mês)',
                      value: Formatters.formatCurrency(recebidoMes),
                      color: AppColors.staleOk,
                      icon: LucideIcons.checkCircle,
                    ),
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
                        itemBuilder: (context, i) {
                          final p = visible[i];
                          return PaymentTile(
                            payment: p,
                            onTap: () => context.go('/orders/${p.orderId}'),
                            onLongPress: () => _showContextMenu(context, p),
                            onMarkPaid: () => _markPaid(p),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
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
