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

/// Quadro Kanban operacional: header com busca/filtros, alertas e colunas por
/// etapa (abas no mobile). Antes vivia na Home; agora tem rota própria (/kanban).
class KanbanScreen extends ConsumerStatefulWidget {
  const KanbanScreen({super.key});

  @override
  ConsumerState<KanbanScreen> createState() => _KanbanScreenState();
}

class _KanbanScreenState extends ConsumerState<KanbanScreen> {
  final _search = TextEditingController();
  String _searchText = '';
  bool _onlyDelayed = false;
  bool _onlyHoje = false;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _searchText = _search.text));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clear() => setState(() {
    _search.clear();
    _onlyDelayed = false;
    _onlyHoje = false;
    _filterStatus = null;
  });

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(osProvider);
    final currentProfile = ref.watch(currentProfileProvider).value;
    final isAdmin = currentProfile?.isAdmin ?? false;
    final currentUserId = ref.watch(authProvider).value?.id;

    return Scaffold(
      body: ordersAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: 6,
          itemBuilder: (_, _) => const SkeletonOSCard(),
        ),
        error: (err, _) =>
            _ErrorView(err: err, onRetry: () => ref.invalidate(osProvider)),
        data: (orders) => _buildContent(
          context,
          orders,
          isAdmin: isAdmin,
          currentUserId: currentUserId,
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<ServiceOrder> allOrders, {
    required bool isAdmin,
    String? currentUserId,
  }) {
    var orders = allOrders.where((o) => !o.isArchived).toList();

    if (!isAdmin && currentUserId != null) {
      orders = orders.where((o) => o.createdBy == currentUserId).toList();
    }
    final today = DateTime.now();
    final todayD = DateTime(today.year, today.month, today.day);

    final statusFilters = OSStatus.ordered
        .where((s) => s != OSStatus.entregue)
        .toList();
    final statusCounts = <String, int>{
      for (final status in statusFilters)
        status: orders.where((o) => o.status == status).length,
    };
    final hojeCount = orders.where((o) {
      if (o.status == OSStatus.entrega || o.scheduledDate == null) return false;
      final d = o.scheduledDate!;
      return d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).length;
    final vencidasCount = orders.where((o) {
      if (o.status == OSStatus.entrega || o.scheduledDate == null) return false;
      return DateTime(
        o.scheduledDate!.year,
        o.scheduledDate!.month,
        o.scheduledDate!.day,
      ).isBefore(todayD);
    }).length;

    final lowStockCount = ref.watch(lowStockProductsProvider).length;

    // Fura-fila
    String? queueAlert;
    final sorted = List<ServiceOrder>.from(orders)
      ..sort((a, b) => a.queuePosition.compareTo(b.queuePosition));
    outer:
    for (var i = 0; i < sorted.length; i++) {
      final a = sorted[i];
      if (a.status == OSStatus.orcamento || a.status == OSStatus.entrega) {
        continue;
      }
      for (var j = i + 1; j < sorted.length; j++) {
        final b = sorted[j];
        if (b.status == OSStatus.orcamento || b.status == OSStatus.entrega) {
          continue;
        }
        if (OSStatus.indexOf(b.status) > OSStatus.indexOf(a.status)) {
          queueAlert = '${b.formattedNumber} furou a fila (${b.statusLabel})';
          break outer;
        }
      }
    }

    // Filtros
    var filtered = orders.where((o) {
      if (_searchText.isNotEmpty) {
        final q = _searchText.toLowerCase();
        if (!o.formattedNumber.toLowerCase().contains(q) &&
            !(o.customerName ?? '').toLowerCase().contains(q) &&
            !(o.material ?? '').toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_filterStatus != null && o.status != _filterStatus) return false;
      if (_onlyDelayed) {
        if (o.status == OSStatus.entrega || o.scheduledDate == null) {
          return false;
        }
        if (!DateTime(
          o.scheduledDate!.year,
          o.scheduledDate!.month,
          o.scheduledDate!.day,
        ).isBefore(todayD)) {
          return false;
        }
      }
      if (_onlyHoje) {
        if (o.status == OSStatus.entrega || o.scheduledDate == null) {
          return false;
        }
        final d = o.scheduledDate!;
        if (!(d.year == today.year &&
            d.month == today.month &&
            d.day == today.day)) {
          return false;
        }
      }
      return true;
    }).toList();

    final hasFilter =
        _onlyDelayed ||
        _onlyHoje ||
        _filterStatus != null ||
        _searchText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(18, 11, 18, 11),
          child: Row(
            children: [
              if (!context.isMobile) ...[
                Text(
                  'Painel Kanban',
                  style: AppTheme.syne(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 20),
              ],

              // Filtros por etapa (rolam horizontalmente em telas estreitas)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var i = 0; i < statusFilters.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        _Chip(
                          label: _statusLabelForChip(statusFilters[i]),
                          value: '${statusCounts[statusFilters[i]] ?? 0}',
                          color: AppColors.statusColors(statusFilters[i]).color,
                          active: _filterStatus == statusFilters[i],
                          onTap: () => setState(() {
                            _filterStatus = _filterStatus == statusFilters[i]
                                ? null
                                : statusFilters[i];
                            _onlyDelayed = false;
                            _onlyHoje = false;
                          }),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Busca (oculta no celular para não espremer; mobile usa só os chips)
              if (!context.isMobile)
                SizedBox(
                  width: 210,
                  height: 34,
                  child: TextField(
                    controller: _search,
                    style: AppTheme.jakarta(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Buscar OS, cliente...',
                      prefixIcon: const Icon(LucideIcons.search, size: 14),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                ),
              if (hasFilter) ...[
                const SizedBox(width: 6),
                _ActionBtn(
                  icon: LucideIcons.x,
                  color: AppColors.error,
                  onTap: _clear,
                ),
              ],
              const SizedBox(width: 6),
              _ActionBtn(
                icon: LucideIcons.refreshCw,
                onTap: () => ref.invalidate(osProvider),
              ),
              if (!context.isMobile) ...[
                const SizedBox(width: 6),
                _PrimaryBtn(
                  icon: LucideIcons.plus,
                  label: 'Nova OS',
                  onTap: () => context.push('/orders/new'),
                ),
              ],
            ],
          ),
        ),

        // ── Alertas ──────────────────────────────────────────────────────────
        if (vencidasCount > 0 ||
            hojeCount > 0 ||
            queueAlert != null ||
            lowStockCount > 0)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (vencidasCount > 0)
                  _AlertBanner(
                    icon: LucideIcons.alertTriangle,
                    text: '$vencidasCount OS com prazo vencido',
                    color: AppColors.staleCrit,
                    onTap: () => setState(() {
                      _onlyDelayed = true;
                      _onlyHoje = false;
                      _filterStatus = null;
                    }),
                  ),
                if (hojeCount > 0)
                  _AlertBanner(
                    icon: LucideIcons.calendarClock,
                    text: '$hojeCount para entrega hoje',
                    color: AppColors.staleWarn,
                    onTap: () => setState(() {
                      _onlyHoje = true;
                      _onlyDelayed = false;
                      _filterStatus = null;
                    }),
                  ),
                if (queueAlert != null)
                  _AlertBanner(
                    icon: LucideIcons.alertCircle,
                    text: queueAlert,
                    color: AppColors.corte,
                  ),
                if (lowStockCount > 0)
                  _AlertBanner(
                    icon: LucideIcons.packageX,
                    text: '$lowStockCount material(is) com estoque baixo',
                    color: AppColors.espMaterial,
                    onTap: () => context.push('/estoque'),
                  ),
              ],
            ),
          ),

        // ── Boards ────────────────────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  title: 'Nenhuma OS encontrada',
                  message: 'Altere os filtros ou crie uma nova OS.',
                  icon: LucideIcons.searchX,
                )
              : _buildBoards(context, filtered),
        ),
      ],
    );
  }

  Widget _buildBoards(BuildContext context, List<ServiceOrder> orders) {
    if (context.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _boardLabel('PEDIDOS'),
                Expanded(
                  child: KanbanBoard(
                    orders: orders,
                    statuses: OSStatus.pedidosStatuses,
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1, color: AppColors.border),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _boardLabel('PRODUÇÃO'),
                Expanded(
                  child: KanbanBoard(
                    orders: orders,
                    statuses: OSStatus.producaoStatuses,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return KanbanBoard(
      orders: orders,
      statuses: [...OSStatus.pedidosStatuses, ...OSStatus.producaoStatuses],
    );
  }

  Widget _boardLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 7, 16, 2),
    child: Text(
      label,
      style: AppTheme.jakarta(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        color: AppColors.textMuted,
      ).copyWith(letterSpacing: 2.2),
    ),
  );

  String _statusLabelForChip(String status) {
    if (status == OSStatus.esperandoMaterial) {
      return 'Esp. Material';
    }
    return OSStatus.labels[status] ?? status;
  }
}

// ── Chip de filtro ────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final String label, value;
  final Color color;
  final bool active;
  final VoidCallback? onTap;

  const _Chip({
    required this.label,
    required this.value,
    required this.color,
    this.active = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.12) : AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: active ? color : AppColors.border,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: AppTheme.numeric(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.jakarta(
              fontSize: 11,
              color: active ? color : AppColors.textSecondary,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
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

  const _AlertBanner({
    required this.icon,
    required this.text,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTheme.jakarta(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 31,
      height: 31,
      decoration: BoxDecoration(
        color: color != null
            ? color!.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(
          color: color != null
              ? color!.withValues(alpha: 0.3)
              : AppColors.border,
        ),
      ),
      child: Icon(icon, size: 14, color: color ?? AppColors.textSecondary),
    ),
  );
}

class _PrimaryBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTheme.jakarta(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
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
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
        const SizedBox(height: 16),
        Text(friendlyError(err), style: AppTheme.jakarta(fontSize: 13)),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text('Tentar novamente'),
        ),
      ],
    ),
  );
}
