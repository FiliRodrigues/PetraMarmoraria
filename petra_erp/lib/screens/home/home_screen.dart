import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/error_messages.dart';
import '../../core/utils/responsive.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/os_provider.dart';
import '../../providers/stock_provider.dart';
import '../../widgets/widgets.dart';
import '../kanban/kanban_screen.dart';

/// Tela inicial. No celular/tablet mostra um dashboard de resumo; no desktop
/// (tela larga) mostra o quadro Kanban, que aproveita melhor a largura.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _checkedPending = false;

  void _maybeShowPendingActions() {
    if (_checkedPending) return;
    final isAdmin = ref.read(currentProfileProvider).value?.isAdmin ?? false;
    if (!isAdmin) return;
    _checkedPending = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final actions = await ref.read(pendingAdminActionsProvider.future);
      if (!mounted || actions.isEmpty) return;
      await showPendingAdminActionsDialog(context, ref, actions);
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeShowPendingActions();

    if (context.isDesktop) return const KanbanScreen();

    final ordersAsync = ref.watch(osProvider);
    final currentProfile = ref.watch(currentProfileProvider).value;
    final isAdmin = currentProfile?.isAdmin ?? false;
    final currentUserId = ref.watch(authProvider).value?.id;

    return Scaffold(
      body: ordersAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: 5,
          itemBuilder: (_, _) => const SkeletonOSCard(),
        ),
        error: (err, _) => _ErrorView(err: err, onRetry: () => ref.invalidate(osProvider)),
        data: (orders) => _Dashboard(
          allOrders: orders,
          isAdmin: isAdmin,
          currentUserId: currentUserId,
          lowStockCount: ref.watch(lowStockProductsProvider).length,
          onRefresh: () => ref.invalidate(osProvider),
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  final List<ServiceOrder> allOrders;
  final bool isAdmin;
  final String? currentUserId;
  final int lowStockCount;
  final VoidCallback onRefresh;

  const _Dashboard({
    required this.allOrders,
    required this.isAdmin,
    required this.currentUserId,
    required this.lowStockCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    var orders = allOrders.where((o) => !o.isArchived).toList();
    if (!isAdmin && currentUserId != null) {
      orders = orders.where((o) => o.createdBy == currentUserId).toList();
    }

    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);

    bool isToday(ServiceOrder o) {
      if (o.status == OSStatus.entrega || o.scheduledDate == null) return false;
      final d = o.scheduledDate!;
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }

    bool isOverdue(ServiceOrder o) {
      if (o.status == OSStatus.entrega || o.scheduledDate == null) return false;
      return DateTime(o.scheduledDate!.year, o.scheduledDate!.month, o.scheduledDate!.day)
          .isBefore(todayD);
    }

    final total = orders.length;
    final orcCount = orders.where((o) => o.status == OSStatus.orcamento).length;
    final hojeCount = orders.where(isToday).length;
    final vencidasCount = orders.where(isOverdue).length;

    // "Precisam de atenção": vencidas primeiro, depois mais paradas, depois hoje.
    final attention = orders.where((o) => isOverdue(o) || isToday(o) || o.daysStale > 2).toList()
      ..sort((a, b) {
        int score(ServiceOrder o) =>
            (isOverdue(o) ? 1000 : 0) + (isToday(o) ? 500 : 0) + o.daysStale;
        return score(b).compareTo(score(a));
      });
    final attentionTop = attention.take(6).toList();

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 90),
        children: [
          // ── KPIs ──────────────────────────────────────────────────────────
          ResponsiveKpiGrid(
            gap: 10,
            children: [
              _DashKpi(
                label: 'Total de OS',
                value: '$total',
                icon: LucideIcons.clipboardList,
                color: AppColors.primary,
                onTap: () => context.push('/orders'),
              ),
              _DashKpi(
                label: 'Orçamentos',
                value: '$orcCount',
                icon: LucideIcons.fileText,
                color: AppColors.orcamento,
                onTap: () => context.push('/orders'),
              ),
              _DashKpi(
                label: 'Entrega hoje',
                value: '$hojeCount',
                icon: LucideIcons.calendarCheck,
                color: AppColors.staleOk,
              ),
              _DashKpi(
                label: 'Vencidas',
                value: '$vencidasCount',
                icon: LucideIcons.calendarX,
                color: AppColors.staleCrit,
                onTap: () => context.push('/orders'),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // ── Alertas ───────────────────────────────────────────────────────
          if (vencidasCount > 0)
            _AlertBanner(
              icon: LucideIcons.alertTriangle,
              text: '$vencidasCount OS com prazo vencido',
              color: AppColors.staleCrit,
              onTap: () => context.push('/orders'),
            ),
          if (lowStockCount > 0)
            _AlertBanner(
              icon: LucideIcons.packageX,
              text: '$lowStockCount material(is) com estoque baixo',
              color: AppColors.espMaterial,
              onTap: () => context.push('/estoque'),
            ),

          // ── Ver Kanban ──────────────────────────────────────────────────────
          const SizedBox(height: 6),
          _KanbanButton(onTap: () => context.go('/kanban')),

          // ── Precisam de atenção ─────────────────────────────────────────────
          const SizedBox(height: 18),
          Row(
            children: [
              Text('Precisam de atenção',
                  style: AppTheme.syne(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const Spacer(),
              if (attention.length > attentionTop.length)
                GestureDetector(
                  onTap: () => context.push('/orders'),
                  child: Text('Ver todas',
                      style: AppTheme.jakarta(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (attentionTop.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              alignment: Alignment.center,
              child: Column(children: [
                Icon(LucideIcons.checkCircle, size: 36, color: AppColors.success.withValues(alpha: 0.6)),
                const SizedBox(height: 10),
                Text('Tudo em dia!',
                    style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
              ]),
            )
          else
            ...attentionTop.map((o) => OrderCard(order: o)),
        ],
      ),
    );
  }
}

// ── KPI do dashboard (espelha o card do protótipo) ──────────────────────────────
class _DashKpi extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DashKpi({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.jakarta(
                              fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                    ),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, size: 15, color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(value,
                    style: AppTheme.numeric(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              ],
            ),
          ),
        ),
      );
}

// ── Botão "Ver Kanban" ──────────────────────────────────────────────────────────
class _KanbanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _KanbanButton({required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              const Icon(LucideIcons.layoutDashboard, size: 18, color: Colors.white),
              const SizedBox(width: 10),
              Text('Ver Quadro Kanban',
                  style: AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              const Icon(LucideIcons.chevronRight, size: 18, color: Colors.white),
            ]),
          ),
        ),
      );
}

// ── Alert Banner ──────────────────────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final VoidCallback? onTap;

  const _AlertBanner({required this.icon, required this.text, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Row(children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(text,
                    style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
              ),
              Icon(LucideIcons.chevronRight, size: 16, color: color.withValues(alpha: 0.7)),
            ]),
          ),
        ),
      );
}

// ── Error view ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final Object err;
  final VoidCallback onRetry;
  const _ErrorView({required this.err, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
          const SizedBox(height: 16),
          Text(friendlyError(err), style: AppTheme.jakarta(fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
        ]),
      );
}

// ── Popup de etapas concluídas aguardando o ADM ─────────────────────────────────
Future<void> showPendingAdminActionsDialog(
  BuildContext context,
  WidgetRef ref,
  List<PendingAdminAction> initial,
) {
  return showDialog(
    context: context,
    builder: (ctx) {
      final pending = List<PendingAdminAction>.from(initial);
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Row(children: [
              const Icon(LucideIcons.bellRing, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              const Text('Etapas concluídas'),
            ]),
            content: SizedBox(
              width: 380,
              child: pending.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Tudo liberado.'),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: pending.map((a) {
                        final stageLabel = OSStatus.labels[a.stage] ?? a.stage;
                        final next = OSStatus.next(a.stage);
                        final nextLabel = next != null ? (OSStatus.labels[next] ?? next) : null;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'OS ${a.order.formattedNumber} — ${a.employeeName}',
                                  style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Terminou $stageLabel'
                                  '${nextLabel != null ? ' → mover para $nextLabel?' : ''}',
                                  style: AppTheme.jakarta(fontSize: 12, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => setState(() => pending.remove(a)),
                                      child: const Text('Depois'),
                                    ),
                                    const SizedBox(width: 4),
                                    if (next != null)
                                      ElevatedButton(
                                        onPressed: () async {
                                          final moved = await showDialog<bool>(
                                            context: ctx,
                                            builder: (_) => StatusTransitionDialog(
                                              order: a.order,
                                              targetStatus: next,
                                            ),
                                          );
                                          if (moved == true) {
                                            ref.invalidate(pendingAdminActionsProvider);
                                            setState(() => pending.remove(a));
                                          }
                                        },
                                        child: Text('Mover'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Fechar'),
              ),
            ],
          );
        },
      );
    },
  );
}
