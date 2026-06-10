import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../models/supplier.dart';
import '../../../../providers/providers.dart';
import '../../../../widgets/finance/supplier_form_dialog.dart';
import '../../../../widgets/finance/register_expense_dialog.dart';
import '../../../../widgets/widgets.dart';

/// Tab de fornecedores — grid de cards com detalhes e integração com despesas.
class SuppliersTab extends ConsumerStatefulWidget {
  const SuppliersTab({super.key});

  @override
  ConsumerState<SuppliersTab> createState() => _SuppliersTabState();
}

class _SuppliersTabState extends ConsumerState<SuppliersTab> {
  void _openNew() {
    SupplierFormDialog.show(context);
  }

  void _openEdit(Supplier supplier) {
    SupplierFormDialog.show(context, existing: supplier);
  }

  Future<void> _delete(Supplier supplier) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Excluir fornecedor',
      content: 'Tem certeza que deseja excluir "${supplier.name}"?\n'
          'Despesas vinculadas não serão excluídas.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (ok) {
      await ref.read(supplierProvider.notifier).delete(supplier.id);
    }
  }

  void _openDetail(Supplier supplier) {
    final expensesAsync = ref.read(expenseProvider);
    final expenses = expensesAsync.maybeWhen(
      data: (list) => list
          .where((e) => e.supplierId == supplier.id)
          .toList(),
      orElse: () => <dynamic>[],
    );

    final totalPendente = expenses
        .where((e) => !e.isPaid)
        .fold<double>(0, (s, e) => s + e.amount);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        expand: false,
        builder: (ctx, scrollController) => _SupplierDetailSheet(
          supplier: supplier,
          expenses: expenses,
          totalPendente: totalPendente,
          onEdit: () {
            Navigator.of(ctx).pop();
            _openEdit(supplier);
          },
          onDelete: () {
            Navigator.of(ctx).pop();
            _delete(supplier);
          },
          onNewExpense: () {
            Navigator.of(ctx).pop();
            RegisterExpenseDialog.show(context, supplierId: supplier.id);
          },
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(supplierProvider);

    return suppliersAsync.when(
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
                'Erro ao carregar fornecedores',
                style: AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: 'Tentar novamente',
                size: AppButtonSize.sm,
                onPressed: () => ref.read(supplierProvider.notifier).loadAll(),
              ),
            ],
          ),
        ),
      ),
      data: (suppliers) {
        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () => ref.read(supplierProvider.notifier).loadAll(),
              child: suppliers.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        EmptyState(
                          title: 'Nenhum fornecedor',
                          message: 'Cadastre fornecedores para vincular às despesas.',
                          icon: LucideIcons.truck,
                        ),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.3,
                      ),
                      itemCount: suppliers.length,
                      itemBuilder: (context, i) {
                        final s = suppliers[i];
                        return _SupplierCard(
                          supplier: s,
                          onTap: () => _openDetail(s),
                        );
                      },
                    ),
            ),
            // FAB Novo Fornecedor
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'fab_novo_fornecedor',
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

/// Card de fornecedor no grid.
class _SupplierCard extends ConsumerWidget {
  final Supplier supplier;
  final VoidCallback onTap;

  const _SupplierCard({required this.supplier, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expenseProvider);
    final totalPendente = expensesAsync.maybeWhen(
      data: (list) => list
          .where((e) => e.supplierId == supplier.id && !e.isPaid)
          .fold<double>(0, (s, e) => s + e.amount),
      orElse: () => 0.0,
    );

    final hasDebt = totalPendente > 0;
    final statusColor = hasDebt ? AppColors.error : AppColors.success;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome + indicador
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: const Icon(LucideIcons.truck, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        supplier.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.jakarta(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (supplier.cnpj != null && supplier.cnpj!.isNotEmpty)
                        Text(
                          supplier.cnpj!,
                          style: AppTheme.jakarta(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Telefone
            if (supplier.phone.isNotEmpty)
              Row(
                children: [
                  const Icon(LucideIcons.phone, size: 12, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      supplier.phone,
                      style: AppTheme.jakarta(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 6),
            // Total pendente
            Row(
              children: [
                Icon(
                  hasDebt ? LucideIcons.alertCircle : LucideIcons.checkCircle,
                  size: 12,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  hasDebt
                      ? 'Pendente: ${Formatters.formatCurrency(totalPendente)}'
                      : 'Em dia',
                  style: AppTheme.jakarta(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet de detalhes do fornecedor.
class _SupplierDetailSheet extends StatelessWidget {
  final Supplier supplier;
  final List<dynamic> expenses;
  final double totalPendente;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onNewExpense;
  final ScrollController scrollController;

  const _SupplierDetailSheet({
    required this.supplier,
    required this.expenses,
    required this.totalPendente,
    required this.onEdit,
    required this.onDelete,
    required this.onNewExpense,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Content
        Expanded(
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: const Icon(LucideIcons.truck, size: 22, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supplier.name,
                          style: AppTheme.syne(fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        if (supplier.cnpj != null && supplier.cnpj!.isNotEmpty)
                          Text(
                            supplier.cnpj!,
                            style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted),
                          ),
                      ],
                    ),
                  ),
                  // Botões de ação
                  IconButton(
                    icon: const Icon(LucideIcons.pencil, size: 18),
                    color: AppColors.textSecondary,
                    tooltip: 'Editar',
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, size: 18),
                    color: AppColors.error,
                    tooltip: 'Excluir',
                    onPressed: onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Total pendente
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: totalPendente > 0
                      ? AppColors.error.withValues(alpha: 0.05)
                      : AppColors.success.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: totalPendente > 0
                        ? AppColors.error.withValues(alpha: 0.15)
                        : AppColors.success.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      totalPendente > 0 ? LucideIcons.alertCircle : LucideIcons.checkCircle,
                      color: totalPendente > 0 ? AppColors.error : AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      totalPendente > 0
                          ? 'Total pendente: ${Formatters.formatCurrency(totalPendente)}'
                          : 'Nenhum valor pendente',
                      style: AppTheme.jakarta(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: totalPendente > 0 ? AppColors.error : AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Dados do fornecedor
              _InfoRow(icon: LucideIcons.phone, label: 'Telefone', value: supplier.phone),
              if (supplier.phone2 != null && supplier.phone2!.isNotEmpty)
                _InfoRow(icon: LucideIcons.phone, label: 'Telefone 2', value: supplier.phone2!),
              if (supplier.email != null && supplier.email!.isNotEmpty)
                _InfoRow(icon: LucideIcons.mail, label: 'Email', value: supplier.email!),
              if (supplier.contactPerson != null && supplier.contactPerson!.isNotEmpty)
                _InfoRow(icon: LucideIcons.user, label: 'Contato', value: supplier.contactPerson!),
              if (supplier.address != null && supplier.address!.isNotEmpty)
                _InfoRow(icon: LucideIcons.mapPin, label: 'Endereço', value: supplier.address!),
              if (supplier.city != null && supplier.city!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _InfoRow(
                  icon: LucideIcons.mapPin,
                  label: 'Cidade/UF',
                  value: '${supplier.city}${supplier.state != null ? '/${supplier.state}' : ''}',
                ),
              ],
              if (supplier.notes != null && supplier.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Observações',
                  style: AppTheme.jakarta(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  supplier.notes!,
                  style: AppTheme.jakarta(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],

              const SizedBox(height: 20),
              // Botão Nova Compra
              AppButton(
                label: 'Nova Compra',
                icon: LucideIcons.plus,
                expanded: true,
                onPressed: onNewExpense,
              ),

              const SizedBox(height: 20),
              // Lista de despesas vinculadas
              Row(
                children: [
                  const Icon(LucideIcons.receipt, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    'Compras/Despesas (${expenses.length})',
                    style: AppTheme.syne(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (expenses.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Nenhuma despesa vinculada',
                      style: AppTheme.jakarta(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                ...expenses.map((e) => ExpenseTile(
                      expense: e,
                      onTap: () {
                        Navigator.of(context).pop();
                        RegisterExpenseDialog.show(context, existing: e);
                      },
                    )),
            ],
          ),
        ),
      ],
    );
  }
}

/// Linha de informação no bottom sheet.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: AppTheme.jakarta(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.jakarta(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
