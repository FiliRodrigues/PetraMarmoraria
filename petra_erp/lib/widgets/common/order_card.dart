import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/service_order.dart';
import 'status_badge.dart';

/// Card de OS para celular — faixa de etapa colorida, número + status,
/// cliente, descrição, e rodapé com prazo/valor. Espelha o `.oscard` do
/// protótipo. Usado na lista de Ordens e no dashboard inicial.
class OrderCard extends StatelessWidget {
  final ServiceOrder order;
  const OrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final o = order;
    final (:color, :bg) = AppColors.statusColors(o.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/orders/${o.id}'),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 5, color: color),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                o.formattedNumber,
                                style: AppTheme.numeric(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(status: o.status, small: true),
                              const Spacer(),
                              if (o.daysStale > 2) _StaleBadge(days: o.daysStale),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Text(
                            o.customerName ?? '—',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.jakarta(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            o.description.isEmpty ? '—' : o.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.jakarta(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 11),
                          Row(
                            children: [
                              _FooterItem(label: 'Prazo', child: _DeadlineText(order: o)),
                              const SizedBox(width: 20),
                              _FooterItem(
                                label: 'Valor',
                                child: Text(
                                  Formatters.formatCurrency(o.totalValue),
                                  style: AppTheme.numeric(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.chevron_right,
                                  color: AppColors.textMuted, size: 22),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterItem extends StatelessWidget {
  final String label;
  final Widget child;
  const _FooterItem({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: AppTheme.jakarta(fontSize: 11.5, color: AppColors.textMuted),
        ),
        child,
      ],
    );
  }
}

class _DeadlineText extends StatelessWidget {
  final ServiceOrder order;
  const _DeadlineText({required this.order});

  @override
  Widget build(BuildContext context) {
    if (order.status == OSStatus.entregue) {
      return Text(
        '✓ Entregue',
        style: AppTheme.jakarta(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.success,
        ),
      );
    }

    if (order.status == OSStatus.entrega) {
      return Text(
        'Em entrega',
        style: AppTheme.jakarta(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.secondary,
        ),
      );
    }

    final date = order.scheduledDate;
    if (date == null) {
      return Text('—', style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted));
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue = date.isBefore(today);
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');

    return Text(
      '$dd/$mm',
      style: AppTheme.numeric(
        fontSize: 13,
        fontWeight: overdue ? FontWeight.w800 : FontWeight.w700,
        color: overdue ? AppColors.error : AppColors.textPrimary,
      ),
    );
  }
}

class _StaleBadge extends StatelessWidget {
  final int days;
  const _StaleBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.stalenessColor(days);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        '${days}d parado',
        style: AppTheme.numeric(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
