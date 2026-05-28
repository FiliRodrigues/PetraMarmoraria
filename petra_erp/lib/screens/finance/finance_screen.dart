import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/account_payable.dart';
import '../../models/account_receivable.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/common/empty_state.dart';

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _filterMonth = DateTime.now().month;
  int _filterYear = DateTime.now().year;
  String? _payableFilter;
  String? _receivableFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Financeiro — ${_formatMonth(_filterMonth)} $_filterYear'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () {
              ref.invalidate(payablesProvider);
              ref.invalidate(receivablesProvider);
              ref.invalidate(financeSummaryProvider);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(LucideIcons.arrowUpFromLine, size: 16), text: 'Contas a Pagar'),
            Tab(icon: Icon(LucideIcons.arrowDownFromLine, size: 16), text: 'Contas a Receber'),
            Tab(icon: Icon(LucideIcons.barChart3, size: 16), text: 'Resumo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PayablesTab(
            filterMonth: _filterMonth,
            filterYear: _filterYear,
            statusFilter: _payableFilter,
            onStatusFilterChanged: (v) => setState(() => _payableFilter = v),
          ),
          _ReceivablesTab(
            filterMonth: _filterMonth,
            filterYear: _filterYear,
            statusFilter: _receivableFilter,
            onStatusFilterChanged: (v) => setState(() => _receivableFilter = v),
          ),
          _SummaryTab(filterMonth: _filterMonth, filterYear: _filterYear),
        ],
      ),
    );
  }

  String _formatMonth(int m) {
    const names = [
      '', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    return names[m];
  }
}

class _PayablesTab extends ConsumerWidget {
  final int filterMonth;
  final int filterYear;
  final String? statusFilter;
  final ValueChanged<String?> onStatusFilterChanged;

  const _PayablesTab({
    required this.filterMonth,
    required this.filterYear,
    required this.statusFilter,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payablesAsync = ref.watch(payablesProvider(statusFilter));

    return Column(
      children: [
        _FilterBar(
          statusFilter: statusFilter,
          onChanged: onStatusFilterChanged,
          pendingLabel: 'Pendentes',
          paidLabel: 'Pagos',
        ),
        Expanded(
          child: payablesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Erro: $err', style: AppTheme.jakarta(color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(payablesProvider),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
            data: (payables) {
              if (payables.isEmpty) {
                return const EmptyState(
                  title: 'Nenhuma conta a pagar',
                  message: 'Nenhum registro encontrado para este período.',
                  icon: LucideIcons.arrowUpFromLine,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: payables.length,
                itemBuilder: (context, index) => _PayableCard(payables[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ReceivablesTab extends ConsumerWidget {
  final int filterMonth;
  final int filterYear;
  final String? statusFilter;
  final ValueChanged<String?> onStatusFilterChanged;

  const _ReceivablesTab({
    required this.filterMonth,
    required this.filterYear,
    required this.statusFilter,
    required this.onStatusFilterChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receivablesAsync = ref.watch(receivablesProvider(statusFilter));

    return Column(
      children: [
        _FilterBar(
          statusFilter: statusFilter,
          onChanged: onStatusFilterChanged,
          pendingLabel: 'Pendentes',
          paidLabel: 'Recebidos',
        ),
        Expanded(
          child: receivablesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('Erro: $err', style: AppTheme.jakarta(color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(receivablesProvider),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
            data: (receivables) {
              if (receivables.isEmpty) {
                return const EmptyState(
                  title: 'Nenhuma conta a receber',
                  message: 'Nenhum registro encontrado para este período.',
                  icon: LucideIcons.arrowDownFromLine,
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: receivables.length,
                itemBuilder: (context, index) => _ReceivableCard(receivables[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryTab extends ConsumerWidget {
  final int filterMonth;
  final int filterYear;

  const _SummaryTab({required this.filterMonth, required this.filterYear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(financeSummaryProvider((month: filterMonth, year: filterYear)));

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Erro: $err', style: AppTheme.jakarta(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(financeSummaryProvider),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      ),
      data: (summary) {
        final totalToPay = summary['totalToPay'] ?? 0;
        final totalPaid = summary['totalPaid'] ?? 0;
        final totalToReceive = summary['totalToReceive'] ?? 0;
        final totalReceived = summary['totalReceived'] ?? 0;
        final balance = summary['balance'] ?? 0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KpiCard(
                label: 'Total a Pagar',
                value: Formatters.formatCurrency(totalToPay),
                icon: LucideIcons.arrowUpFromLine,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              _KpiCard(
                label: 'Total Pago',
                value: Formatters.formatCurrency(totalPaid),
                icon: LucideIcons.checkCircle,
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              _KpiCard(
                label: 'Total a Receber',
                value: Formatters.formatCurrency(totalToReceive),
                icon: LucideIcons.arrowDownFromLine,
                color: AppColors.warning,
              ),
              const SizedBox(height: 12),
              _KpiCard(
                label: 'Total Recebido',
                value: Formatters.formatCurrency(totalReceived),
                icon: LucideIcons.dollarSign,
                color: AppColors.success,
              ),
              const SizedBox(height: 12),
              _KpiCard(
                label: 'Saldo do Mês',
                value: Formatters.formatCurrency(balance),
                icon: LucideIcons.barChart3,
                color: balance >= 0 ? AppColors.success : AppColors.error,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? statusFilter;
  final ValueChanged<String?> onChanged;
  final String pendingLabel;
  final String paidLabel;

  const _FilterBar({
    required this.statusFilter,
    required this.onChanged,
    required this.pendingLabel,
    required this.paidLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todas',
            selected: statusFilter == null,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: pendingLabel,
            selected: statusFilter == 'pending',
            onTap: () => onChanged('pending'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: paidLabel,
            selected: statusFilter == 'paid',
            onTap: () => onChanged('paid'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.jakarta(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PayableCard extends StatelessWidget {
  final AccountPayable payable;
  const _PayableCard(this.payable);

  @override
  Widget build(BuildContext context) {
    final isOverdue = !payable.isPaid && payable.dueDate.isBefore(DateTime.now());

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(payable.description,
                    style: AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Vencimento: ${Formatters.formatCurrency(payable.amount)} em ${payable.dueDate.day.toString().padLeft(2, '0')}/${payable.dueDate.month.toString().padLeft(2, '0')}/${payable.dueDate.year}',
                    style: AppTheme.jakarta(fontSize: 12, color: AppColors.textSecondary)),
                  if (payable.paidAt != null) ...[
                    const SizedBox(height: 2),
                    Text('Pago: ${Formatters.formatCurrency(payable.paidAmount ?? payable.amount)}',
                      style: AppTheme.jakarta(fontSize: 12, color: AppColors.success)),
                  ],
                  if (isOverdue)
                    Text('VENCIDA',
                      style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error)),
                ],
              ),
            ),
            if (!payable.isPaid)
              TextButton(
                onPressed: () => _markAsPaid(context),
                child: const Text('Pagar', style: TextStyle(fontSize: 12)),
              )
            else
              Icon(LucideIcons.checkCircle, size: 20, color: AppColors.success),
          ],
        ),
      ),
    );
  }

  void _markAsPaid(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como Pago'),
        content: Text('Confirmar pagamento de ${Formatters.formatCurrency(payable.amount)} para "${payable.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: call service to mark as paid
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _ReceivableCard extends StatelessWidget {
  final AccountReceivable receivable;
  const _ReceivableCard(this.receivable);

  @override
  Widget build(BuildContext context) {
    final isOverdue = !receivable.isReceived && receivable.dueDate.isBefore(DateTime.now());

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(receivable.description,
                    style: AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Valor: ${Formatters.formatCurrency(receivable.amount)} — Vencimento: ${receivable.dueDate.day.toString().padLeft(2, '0')}/${receivable.dueDate.month.toString().padLeft(2, '0')}/${receivable.dueDate.year}',
                    style: AppTheme.jakarta(fontSize: 12, color: AppColors.textSecondary)),
                  if (receivable.receivedAt != null) ...[
                    const SizedBox(height: 2),
                    Text('Recebido: ${Formatters.formatCurrency(receivable.receivedAmount ?? receivable.amount)}',
                      style: AppTheme.jakarta(fontSize: 12, color: AppColors.success)),
                  ],
                  if (isOverdue)
                    Text('VENCIDA',
                      style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error)),
                ],
              ),
            ),
            if (!receivable.isReceived)
              TextButton(
                onPressed: () => _markAsReceived(context),
                child: const Text('Receber', style: TextStyle(fontSize: 12)),
              )
            else
              Icon(LucideIcons.checkCircle, size: 20, color: AppColors.success),
          ],
        ),
      ),
    );
  }

  void _markAsReceived(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Marcar como Recebido'),
        content: Text('Confirmar recebimento de ${Formatters.formatCurrency(receivable.amount)} para "${receivable.description}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // TODO: call service to mark as received
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                  style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text(value,
                  style: AppTheme.numeric(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
