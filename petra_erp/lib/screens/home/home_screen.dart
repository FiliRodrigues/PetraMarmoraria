import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/os_provider.dart';
import '../../widgets/widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _search = TextEditingController();
  String _searchText = '';
  bool _onlyDelayed = false;
  bool _onlyHoje    = false;
  String? _filterStatus;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() => _searchText = _search.text));
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  void _clear() => setState(() {
    _search.clear(); _onlyDelayed = false; _onlyHoje = false; _filterStatus = null;
  });

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(osProvider);
    return Scaffold(
      body: ordersAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: 6,
          itemBuilder: (_, __) => const SkeletonOSCard(),
        ),
        error: (err, _) => _ErrorView(err: err, onRetry: () => ref.invalidate(osProvider)),
        data: (orders) => _buildContent(context, orders),
      ),
    );
  }

  Widget _buildContent(BuildContext context, List<ServiceOrder> orders) {
    final today    = DateTime.now();
    final todayD   = DateTime(today.year, today.month, today.day);

    final total    = orders.length;
    final orcCount = orders.where((o) => o.status == OSStatus.orcamento).length;
    final hojeCount = orders.where((o) {
      if (o.status == OSStatus.entrega || o.scheduledDate == null) return false;
      final d = o.scheduledDate!;
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }).length;
    final vencidasCount = orders.where((o) {
      if (o.status == OSStatus.entrega || o.scheduledDate == null) return false;
      return DateTime(o.scheduledDate!.year, o.scheduledDate!.month, o.scheduledDate!.day)
          .isBefore(todayD);
    }).length;

    // Fura-fila
    String? queueAlert;
    final sorted = List<ServiceOrder>.from(orders)
      ..sort((a, b) => a.queuePosition.compareTo(b.queuePosition));
    outer:
    for (var i = 0; i < sorted.length; i++) {
      final a = sorted[i];
      if (a.status == OSStatus.orcamento || a.status == OSStatus.entrega) continue;
      for (var j = i + 1; j < sorted.length; j++) {
        final b = sorted[j];
        if (b.status == OSStatus.orcamento || b.status == OSStatus.entrega) continue;
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
            !(o.material ?? '').toLowerCase().contains(q)) return false;
      }
      if (_filterStatus != null && o.status != _filterStatus) return false;
      if (_onlyDelayed) {
        if (o.status == OSStatus.entrega || o.scheduledDate == null) return false;
        if (!DateTime(o.scheduledDate!.year, o.scheduledDate!.month, o.scheduledDate!.day)
            .isBefore(todayD)) return false;
      }
      if (_onlyHoje) {
        if (o.status == OSStatus.entrega || o.scheduledDate == null) return false;
        final d = o.scheduledDate!;
        if (!(d.year == today.year && d.month == today.month && d.day == today.day)) return false;
      }
      return true;
    }).toList();

    final hasFilter = _onlyDelayed || _onlyHoje || _filterStatus != null || _searchText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(18, 11, 18, 11),
          child: Row(children: [
            Text('Painel Kanban',
              style: AppTheme.syne(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const SizedBox(width: 20),

            // KPI chips (rolam horizontalmente em telas estreitas)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _Chip(icon: LucideIcons.clipboardList, label: 'Total',        value: '$total',        color: AppColors.primary),
                  const SizedBox(width: 6),
                  _Chip(icon: LucideIcons.fileText,      label: 'Orçamentos',   value: '$orcCount',     color: AppColors.orcamento,
                    active: _filterStatus == OSStatus.orcamento,
                    onTap: () => setState(() {
                      _filterStatus = _filterStatus == OSStatus.orcamento ? null : OSStatus.orcamento;
                      _onlyDelayed = _onlyHoje = false; _search.clear();
                    })),
                  const SizedBox(width: 6),
                  _Chip(icon: LucideIcons.calendarCheck, label: 'Entrega hoje', value: '$hojeCount',    color: AppColors.staleOk,
                    active: _onlyHoje,
                    onTap: () => setState(() { _onlyHoje = !_onlyHoje; _onlyDelayed = false; _filterStatus = null; })),
                  const SizedBox(width: 6),
                  _Chip(icon: LucideIcons.calendarX,     label: 'Vencidas',     value: '$vencidasCount',color: AppColors.staleCrit,
                    active: _onlyDelayed,
                    onTap: () => setState(() { _onlyDelayed = !_onlyDelayed; _onlyHoje = false; _filterStatus = null; })),
                ]),
              ),
            ),
            const SizedBox(width: 10),

            // Busca
            SizedBox(
              width: 210, height: 34,
              child: TextField(
                controller: _search,
                style: AppTheme.jakarta(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Buscar OS, cliente...',
                  prefixIcon: const Icon(LucideIcons.search, size: 14),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border)),
                  filled: true,
                  fillColor: AppColors.background,
                ),
              ),
            ),
            if (hasFilter) ...[
              const SizedBox(width: 6),
              _ActionBtn(icon: LucideIcons.x, color: AppColors.error, onTap: _clear),
            ],
            const SizedBox(width: 6),
            _ActionBtn(icon: LucideIcons.refreshCw, onTap: () => ref.invalidate(osProvider)),
            const SizedBox(width: 6),
            _PrimaryBtn(
              icon: LucideIcons.plus,
              label: 'Nova OS',
              onTap: () => context.push('/orders/new'),
            ),
          ]),
        ),

        // ── Alertas ──────────────────────────────────────────────────────────
        if (vencidasCount > 0 || hojeCount > 0 || queueAlert != null)
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Wrap(spacing: 8, runSpacing: 4, children: [
              if (vencidasCount > 0)
                _AlertBanner(
                  icon: LucideIcons.alertTriangle,
                  text: '$vencidasCount OS com prazo vencido',
                  color: AppColors.staleCrit,
                  onTap: () => setState(() { _onlyDelayed = true; _onlyHoje = false; _filterStatus = null; }),
                ),
              if (hojeCount > 0)
                _AlertBanner(
                  icon: LucideIcons.calendarClock,
                  text: '$hojeCount para entrega hoje',
                  color: AppColors.staleWarn,
                  onTap: () => setState(() { _onlyHoje = true; _onlyDelayed = false; _filterStatus = null; }),
                ),
              if (queueAlert != null)
                _AlertBanner(icon: LucideIcons.alertCircle, text: queueAlert!, color: AppColors.corte),
            ]),
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
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _boardLabel('PEDIDOS'),
            Expanded(child: KanbanBoard(orders: orders, statuses: OSStatus.pedidosStatuses)),
          ])),
          VerticalDivider(width: 1, color: AppColors.border),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _boardLabel('PRODUÇÃO'),
            Expanded(child: KanbanBoard(orders: orders, statuses: OSStatus.producaoStatuses)),
          ])),
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
    child: Text(label,
      style: AppTheme.jakarta(fontSize: 9, fontWeight: FontWeight.w800,
        color: AppColors.textMuted).copyWith(letterSpacing: 2.2)),
  );
}

// ── KPI Chip ──────────────────────────────────────────────────────────────────
class _Chip extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  final bool active;
  final VoidCallback? onTap;

  const _Chip({
    required this.icon, required this.label, required this.value,
    required this.color, this.active = false, this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: active ? color.withValues(alpha: 0.12) : AppColors.background,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: active ? color : AppColors.border, width: active ? 1.5 : 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 5),
        Text(value,
          style: AppTheme.numeric(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(width: 4),
        Text(label,
          style: AppTheme.jakarta(fontSize: 11,
            color: active ? color : AppColors.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
      ]),
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
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 6),
        Text(text,
          style: AppTheme.jakarta(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
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
      width: 31, height: 31,
      decoration: BoxDecoration(
        color: color != null ? color!.withValues(alpha: 0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color != null ? color!.withValues(alpha: 0.3) : AppColors.border),
      ),
      child: Icon(icon, size: 14, color: color ?? AppColors.textSecondary),
    ),
  );
}

class _PrimaryBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _PrimaryBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 31,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 5),
        Text(label,
          style: AppTheme.jakarta(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
      ]),
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
      Text('Erro: $err', style: AppTheme.jakarta(fontSize: 13)),
      const SizedBox(height: 16),
      ElevatedButton(onPressed: onRetry, child: const Text('Tentar novamente')),
    ]),
  );
}
