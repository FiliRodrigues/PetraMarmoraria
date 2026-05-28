import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/os_provider.dart';
import 'status_transition_dialog.dart';

class OSCard extends ConsumerStatefulWidget {
  final ServiceOrder order;
  final bool isFeedback;

  const OSCard({super.key, required this.order, this.isFeedback = false});

  @override
  ConsumerState<OSCard> createState() => _OSCardState();
}

class _OSCardState extends ConsumerState<OSCard> {
  bool _hovered = false;

  Color get _statusColor => AppColors.statusColors(widget.order.status).color;
  Color get _staleColor  => AppColors.stalenessColor(widget.order.daysStale);

  bool get _isDelayed => widget.order.isDelayed;

  bool get _isToday {
    final o = widget.order;
    if (o.status == OSStatus.entrega || o.scheduledDate == null) return false;
    final s = o.scheduledDate!, n = DateTime.now();
    return s.day == n.day && s.month == n.month && s.year == n.year;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final o    = widget.order;
    final days = o.daysStale;

    final card = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        transform: Matrix4.translationValues(0, _hovered ? -1 : 0, 0),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: _hovered ? AppColors.border : AppColors.border,
          ),
          boxShadow: _hovered ? AppColors.shadowMd : AppColors.shadowSm,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Stack(children: [
            // border-left colorido por status
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 3, color: _statusColor),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Row 1: OS# + badge ──────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'OS',
                        style: AppTheme.jakarta(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                        ).copyWith(letterSpacing: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        o.formattedNumber,
                        style: AppTheme.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_isDelayed)
                        _urgencyBadge('VENCIDA', AppColors.staleCrit)
                      else if (_isToday)
                        _urgencyBadge('HOJE', AppColors.staleWarn),
                      if (!widget.isFeedback) ...[
                        const SizedBox(width: 4),
                        _ContextMenu(order: o),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── Cliente ─────────────────────────────────────────────────
                  Text(
                    o.customerName ?? 'Sem cliente',
                    style: AppTheme.jakarta(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // ── Material ────────────────────────────────────────────────
                  if (o.material != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      o.material!,
                      style: AppTheme.jakarta(fontSize: 11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 10),

                  // ── Row final: prazo + staleness ────────────────────────────
                  Row(
                    children: [
                      if (o.scheduledDate != null && o.status != OSStatus.entrega) ...[
                        Icon(LucideIcons.calendarClock,
                          size: 11,
                          color: _isDelayed ? AppColors.staleCrit : AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(
                          _fmt(o.scheduledDate!),
                          style: AppTheme.numeric(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _isDelayed ? AppColors.staleCrit : AppColors.textMuted,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _staleColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(
                          days == 0 ? 'Hoje' : '${days}d',
                          style: AppTheme.numeric(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _staleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );

    if (widget.isFeedback) return card;

    return Draggable<ServiceOrder>(
      data: o,
      feedback: Material(
        type: MaterialType.transparency,
        child: SizedBox(width: 230, child: OSCard(order: o, isFeedback: true)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: GestureDetector(
        onTap: () => context.push('/orders/${o.id}'),
        child: card,
      ),
    );
  }

  Widget _urgencyBadge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      border: Border.all(color: color.withOpacity(0.25)),
    ),
    child: Text(label,
      style: AppTheme.jakarta(fontSize: 9, fontWeight: FontWeight.w800, color: color)
        .copyWith(letterSpacing: 0.4)),
  );
}

// ── Context menu (⋮) ──────────────────────────────────────────────────────────
class _ContextMenu extends ConsumerWidget {
  final ServiceOrder order;
  const _ContextMenu({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(LucideIcons.moreVertical, size: 15, color: AppColors.textMuted),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
      onSelected: (v) async {
        if (v == 'edit')   context.push('/orders/${order.id}/edit');
        if (v == 'detail') context.push('/orders/${order.id}');
        if (v == 'move') {
          showDialog(
            context: context,
            builder: (_) => StatusTransitionDialog(
              order: order,
              onTransitionCompleted: () => ref.invalidate(osProvider),
            ),
          );
        }
      },
      itemBuilder: (_) => [
        _menuItem('detail', LucideIcons.eye,            'Ver Detalhes'),
        _menuItem('edit',   LucideIcons.edit,           'Editar OS'),
        _menuItem('move',   LucideIcons.arrowLeftRight, 'Mover Etapa'),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String v, IconData icon, String label) =>
    PopupMenuItem(
      value: v,
      child: Row(children: [
        Icon(icon, size: 15),
        const SizedBox(width: 8),
        Text(label, style: AppTheme.jakarta(fontSize: 13)),
      ]),
    );
}
