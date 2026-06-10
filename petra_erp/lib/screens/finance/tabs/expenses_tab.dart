import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../providers/providers.dart';
import '../../../../widgets/finance/register_expense_dialog.dart';
import '../../../../widgets/widgets.dart';

/// Tab de despesas — KPIs de despesas + lista de ExpenseTile com filtro por status.
class ExpensesTab extends ConsumerStatefulWidget {
  const ExpensesTab({super.key});

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  String _statusFilter = 'pendente'; // pendente | pago | todos

  // ── Handlers ──

  void _openEdit(expense) {
    RegisterExpenseDialog.show(context, existing: expense);
  }

  void _openNew() {
    RegisterExpenseDialog.show(context);
  }

  Future<void> _duplicate(expense) async {
    await ref.read(expenseProvider.notifier).create(
          expense.copyWith(id: ''),
        );
  }

  Future<void> _delete(expense) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Excluir despesa',
      content: 'Tem certeza que deseja excluir "${expense.description}"?',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (ok) {
      await ref.read(expenseProvider.notifier).delete(expense.id);
    }
  }

  Future<void> _markPaid(id) async {
    await ref.read(expenseProvider.notifier).markPaid(id);
  }

  void _showContextMenu(BuildContext context, expense) {
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
                leading: const Icon(LucideIcons.pencil, size: 20, color: AppColors.textSecondary),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openEdit(expense);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.copy, size: 20, color: AppColors.textSecondary),
                title: const Text('Duplicar'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _duplicate(expense);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.trash2, size: 20, color: AppColors.error),
                title: const Text('Excluir'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _delete(expense);
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
    final expensesAsync = ref.watch(expenseProvider);

    return expensesAsync.when(
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
                'Erro ao carregar despesas',
                style: AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Tentar novamente',
                size: AppButtonSize.sm,
                onPressed: () => ref.read(expenseProvider.notifier).loadAll(),
              ),
            ],
          ),
        ),
      ),
      data: (expenses) {
        final despesas = expenses.where((e) => e.type == 'despesa').toList();
        final pendentes = despesas.where((e) => !e.isPaid).toList();
        final vencidas = despesas.where((e) => e.isOverdue).toList();
        final now = DateTime.now();
        final pagasMes = despesas
            .where((e) => e.isPaid && e.paidAt != null &&
                e.paidAt!.year == now.year && e.paidAt!.month == now.month)
            .fold<double>(0, (s, e) => s + e.amount);
        final aPagar = pendentes.fold<double>(0, (s, e) => s + e.amount);
        final vencidoTotal = vencidas.fold<double>(0, (s, e) => s + e.amount);

        final visible = switch (_statusFilter) {
          'pago' => despesas.where((e) => e.isPaid).toList(),
          'todos' => despesas,
          _ => pendentes,
        };

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.read(expenseProvider.notifier).loadAll(),
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
                          label: 'Total despesas',
                          value: Formatters.formatCurrency(despesas.fold<double>(0, (s, e) => s + e.amount)),
                          color: AppColors.error,
                          icon: LucideIcons.trendingDown,
                        ),
                        _Kpi(
                          label: 'A pagar',
                          value: Formatters.formatCurrency(aPagar),
                          color: AppColors.warning,
                          icon: LucideIcons.clock,
                        ),
                        _Kpi(
                          label: 'Vencidas',
                          value: Formatters.formatCurrency(vencidoTotal),
                          color: AppColors.staleCrit,
                          icon: LucideIcons.alertTriangle,
                        ),
                        _Kpi(
                          label: 'Pagas (mês)',
                          value: Formatters.formatCurrency(pagasMes),
                          color: AppColors.staleOk,
                          icon: LucideIcons.checkCircle,
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
                          label: 'Pagas',
                          selected: _statusFilter == 'pago',
                          onTap: () => setState(() => _statusFilter = 'pago'),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Todas',
                          selected: _statusFilter == 'todos',
                          onTap: () => setState(() => _statusFilter = 'todos'),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: visible.isEmpty
                        ? const EmptyState(
                            title: 'Nenhuma despesa',
                            message: 'Registre despesas para controlar seu financeiro.',
                            icon: LucideIcons.receipt,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            itemCount: visible.length,
                            itemBuilder: (context, i) {
                              final e = visible[i];
                              return ExpenseTile(
                                expense: e,
                                onTap: () => _openEdit(e),
                                onLongPress: () => _showContextMenu(context, e),
                                onPay: () => _markPaid(e.id),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            // FAB Nova Despesa
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'fab_nova_despesa',
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                onPressed: _openNew,
                child: const Icon(LucideIcons.plus, size: 22),
              ),
            ),
          ],
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
