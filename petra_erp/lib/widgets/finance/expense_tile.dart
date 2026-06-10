import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../models/expense.dart';

/// Tile de despesa — exibe descrição, categoria, valor, vencimento e badge de
/// status colorido. Similar ao [PaymentTile] mas voltado para despesas.
///
/// Exemplo:
/// ```dart
/// ExpenseTile(
///   expense: expense,
///   onTap: () => print('Despesa: \${expense.description}'),
/// )
/// ```
class ExpenseTile extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onPay;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.onTap,
    this.onLongPress,
    this.onPay,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = expense.isOverdue;
    final paid = expense.isPaid;
    final color = paid
        ? AppColors.staleOk
        : (overdue ? AppColors.staleCrit : AppColors.warning);

    final statusLabel = paid
        ? 'Pago'
        : (overdue ? 'Vencido' : 'Pendente');

    final statusIcon = paid
        ? LucideIcons.checkCircle
        : (overdue ? LucideIcons.alertTriangle : LucideIcons.clock);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: overdue ? AppColors.staleCrit.withValues(alpha: 0.5) : AppColors.border,
        ),
        boxShadow: AppTheme.shadowSoft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Ícone de status
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Icon(statusIcon, size: 18, color: color),
                ),
                const SizedBox(width: 12),
                // Conteúdo principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        expense.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.jakarta(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _buildSubtitle(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.jakarta(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Valor + status badge + botão pagar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Formatters.formatCurrency(expense.amount),
                      style: AppTheme.numeric(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusFull),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTheme.jakarta(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    if (!paid && onPay != null) ...[
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: onPay,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.staleOk.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                                AppTheme.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(LucideIcons.check,
                                  size: 12, color: AppColors.staleOk),
                              const SizedBox(width: 4),
                              Text(
                                'Pagar',
                                style: AppTheme.jakarta(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.staleOk,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    final catLabel = expense.categoryName ?? Expense.categoryLabel(expense.category);
    parts.add(catLabel);
    if (expense.dueDate != null) {
      parts.add('venc. ${AppDateUtils.formatDate(expense.dueDate)}');
    }
    return parts.join(' · ');
  }
}
