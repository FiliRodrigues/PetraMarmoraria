import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../providers/providers.dart';
import '../../../../widgets/widgets.dart';

/// Tab de fluxo de caixa — seletor de mês/ano + KPIs de saldo.
class CashFlowTab extends ConsumerStatefulWidget {
  const CashFlowTab({super.key});

  @override
  ConsumerState<CashFlowTab> createState() => _CashFlowTabState();
}

class _CashFlowTabState extends ConsumerState<CashFlowTab> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  void _changeMonth(int months) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + months,
      );
    });
    ref.read(cashFlowProvider.notifier).load(_selectedMonth);
  }

  String _monthLabel() {
    const monthNames = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    return '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}';
  }

  @override
  Widget build(BuildContext context) {
    final cashFlowAsync = ref.watch(cashFlowProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Seletor de mês
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _changeMonth(-1),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(LucideIcons.chevronLeft, size: 18, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              Icon(LucideIcons.calendar, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                _monthLabel(),
                style: AppTheme.syne(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _changeMonth(1),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final now = DateTime.now();
                  setState(() {
                    _selectedMonth = DateTime(now.year, now.month);
                  });
                  ref.read(cashFlowProvider.notifier).load(_selectedMonth);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Hoje',
                    style: AppTheme.jakarta(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Conteúdo
        Expanded(
          child: cashFlowAsync.when(
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
                      'Erro ao carregar fluxo de caixa',
                      style: AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Tentar novamente',
                      size: AppButtonSize.sm,
                      onPressed: () => ref.read(cashFlowProvider.notifier).load(_selectedMonth),
                    ),
                  ],
                ),
              ),
            ),
            data: (cashFlow) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // KPIs de saldo
                    ResponsiveKpiGrid(
                      gap: 10,
                      children: [
                        _Kpi(
                          label: 'Entradas (recebido)',
                          value: Formatters.formatCurrency(cashFlow.received + cashFlow.totalIncome),
                          color: AppColors.staleOk,
                          icon: LucideIcons.trendingUp,
                        ),
                        _Kpi(
                          label: 'Saídas (pagas)',
                          value: Formatters.formatCurrency(cashFlow.paidExpenses),
                          color: AppColors.error,
                          icon: LucideIcons.trendingDown,
                        ),
                        _Kpi(
                          label: 'Saldo realizado',
                          value: Formatters.formatCurrency(cashFlow.balance),
                          color: cashFlow.balance >= 0 ? AppColors.staleOk : AppColors.staleCrit,
                          icon: LucideIcons.dollarSign,
                        ),
                        _Kpi(
                          label: 'Saldo projetado',
                          value: Formatters.formatCurrency(cashFlow.projectedBalance),
                          color: cashFlow.projectedBalance >= 0 ? AppColors.primary : AppColors.staleCrit,
                          icon: LucideIcons.target,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Resumo de recebíveis
                    _SectionHeader(
                      title: 'Recebíveis pendentes',
                      count: cashFlow.receivables.where((p) => !p.isPaid).length,
                      icon: LucideIcons.wallet,
                      color: AppColors.accent,
                    ),
                    if (cashFlow.receivables.where((p) => !p.isPaid).isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Nenhum recebível pendente neste mês.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      )
                    else
                      ...cashFlow.receivables.where((p) => !p.isPaid).map((p) => PaymentTile(
                            payment: p,
                            onTap: null,
                          )),

                    const SizedBox(height: 20),

                    // Resumo de despesas
                    _SectionHeader(
                      title: 'Despesas pendentes',
                      count: cashFlow.payables.where((e) => e.type == 'despesa' && !e.isPaid).length,
                      icon: LucideIcons.receipt,
                      color: AppColors.warning,
                    ),
                    if (cashFlow.payables.where((e) => e.type == 'despesa' && !e.isPaid).isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Nenhuma despesa pendente neste mês.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      )
                    else
                      ...cashFlow.payables
                          .where((e) => e.type == 'despesa' && !e.isPaid)
                          .map((e) => ExpenseTile(expense: e, onTap: null)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTheme.syne(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
            child: Text(
              '$count',
              style: AppTheme.numeric(fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
