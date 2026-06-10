import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/payment_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/formatters.dart';
import '../../models/payment.dart';

/// Tile de pagamento — exibe OS #, cliente, valor, vencimento e badge de
/// status colorido. Extraído da tela de financeiro como widget público.
///
/// Exemplo:
/// ```dart
/// PaymentTile(
///   payment: payment,
///   onTap: () => context.go('/orders/\${payment.orderId}'),
/// )
/// ```
class PaymentTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMarkPaid;

  const PaymentTile({
    super.key,
    required this.payment,
    this.onTap,
    this.onLongPress,
    this.onMarkPaid,
  });

  @override
  Widget build(BuildContext context) {
    final overdue = payment.isOverdue;
    final paid = payment.isPaid;
    final color = paid
        ? AppColors.staleOk
        : (overdue ? AppColors.staleCrit : AppColors.accent);

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
                GestureDetector(
                  onTap: !paid ? onMarkPaid : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Icon(
                      !paid ? LucideIcons.check : statusIcon,
                      size: 18,
                      color: !paid ? AppColors.staleOk : color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Conteúdo principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        payment.customerName ?? 'Cliente',
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
                // Valor + status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      Formatters.formatCurrency(payment.amount),
                      style: AppTheme.numeric(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
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
    parts.add(Formatters.formatOSNumber(payment.orderNumber));
    parts.add(PaymentConstants.methodLabel(payment.method));
    if (payment.dueDate != null) {
      parts.add('venc. ${AppDateUtils.formatDate(payment.dueDate)}');
    }
    return parts.join(' · ');
  }
}
