import 'package:flutter/material.dart';
import '../../core/utils/error_messages.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/responsive.dart';
import '../../models/service_order.dart';
import '../../providers/os_provider.dart';
import '../../widgets/widgets.dart';

/// Lista de Ordens de Serviço em formato de tabela, com abas de status,
/// busca e ações de criação. Replica o protótipo da tela "Ordens de Serviço".
class OSListScreen extends ConsumerStatefulWidget {
  const OSListScreen({super.key});

  @override
  ConsumerState<OSListScreen> createState() => _OSListScreenState();
}

class _OSListScreenState extends ConsumerState<OSListScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';

  /// `null` representa a aba "Todas". [_kArchivedFilter] é a aba "Arquivadas".
  String? _statusFilter;

  /// Sentinel usado como filtro da aba "Arquivadas".
  static const String _kArchivedFilter = '__archived__';

  // Abas exibidas na barra de status (subconjunto/ordem do protótipo).
  static const List<String> _tabs = [
    OSStatus.orcamento,
    OSStatus.aprovado,
    OSStatus.esperandoMaterial,
    OSStatus.corte,
    OSStatus.montagem,
    OSStatus.entrega,
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text);
    });
    // Permite abrir direto na aba "Arquivadas" via /orders?arquivadas=1.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final arquivadas = GoRouterState.of(context).uri.queryParameters['arquivadas'];
      if (arquivadas == '1') {
        setState(() => _statusFilter = _kArchivedFilter);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(osProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: () => ref.read(osProvider.notifier).loadOrders(),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text(friendlyError(err))),
        data: (orders) {
          final all = [...orders]
            ..sort((a, b) => a.displayNumber.compareTo(b.displayNumber));

          final query = _searchText.trim().toLowerCase();
          final searched = query.isEmpty
              ? all
              : all.where((o) {
                  final num = o.formattedNumber.toLowerCase();
                  final client = (o.customerName ?? '').toLowerCase();
                  final material = (o.material ?? '').toLowerCase();
                  final desc = o.description.toLowerCase();
                  return num.contains(query) ||
                      client.contains(query) ||
                      material.contains(query) ||
                      desc.contains(query);
                }).toList();

          // OS arquivadas (entregues há 7+ dias) ficam fora das abas normais;
          // só aparecem na aba dedicada "Arquivadas".
          final active = searched.where((o) => !o.isArchived).toList();
          final archived = searched.where((o) => o.isArchived).toList();

          final List<ServiceOrder> visible;
          if (_statusFilter == _kArchivedFilter) {
            visible = archived;
          } else if (_statusFilter == null) {
            visible = active;
          } else {
            visible = active.where((o) => o.status == _statusFilter).toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                title: 'Ordens de Serviço',
                subtitle: '${all.length} ordens cadastradas',
                searchController: _searchController,
                searchHint: 'Buscar nº, cliente, material...',
                newLabel: 'Nova OS',
                onNew: () => context.push('/orders/new'),
              ),
              _StatusTabs(
                tabs: _tabs,
                all: active,
                archivedCount: archived.length,
                archivedFilter: _kArchivedFilter,
                selected: _statusFilter,
                onSelect: (s) => setState(() => _statusFilter = s),
              ),
              const Divider(height: 1),
              Expanded(
                child: visible.isEmpty
                    ? const EmptyState(
                        title: 'Nenhuma ordem encontrada',
                        message:
                            'Ajuste os filtros ou cadastre uma nova ordem de serviço.',
                        icon: Icons.assignment_outlined,
                      )
                    : _OrdersTable(orders: visible),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Tabela ──────────────────────────────────────────────────────────────────

class _OrdersTable extends StatelessWidget {
  final List<ServiceOrder> orders;
  const _OrdersTable({required this.orders});

  @override
  Widget build(BuildContext context) {
    // No celular a tabela de 7 colunas não cabe — usa cards (igual protótipo).
    if (context.isMobile) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
        itemCount: orders.length,
        itemBuilder: (_, i) => OrderCard(order: orders[i]),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppColors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              const _TableHeaderRow(),
              for (var i = 0; i < orders.length; i++)
                _OrderRow(order: orders[i], even: i.isEven),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    TextStyle h() => AppTheme.jakarta(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: AppColors.textMuted,
        ).copyWith(letterSpacing: 0.5);
    Widget cell(String label, int flex, {Alignment align = Alignment.centerLeft}) =>
        Expanded(
          flex: flex,
          child: Align(
            alignment: align,
            child: Text(label.toUpperCase(), style: h()),
          ),
        );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutral50,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          cell('OS #', 12),
          cell('Cliente', 22),
          cell('Descrição', 28),
          cell('Status', 18),
          cell('Prazo', 14),
          cell('Valor', 16, align: Alignment.centerRight),
          cell('Tempo', 10, align: Alignment.centerRight),
        ],
      ),
    );
  }
}

class _OrderRow extends StatefulWidget {
  final ServiceOrder order;
  final bool even;
  const _OrderRow({required this.order, required this.even});

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final baseBg = widget.even ? AppColors.surface : AppColors.neutral50;
    final bg = _hover ? AppColors.accent.withValues(alpha: 0.06) : baseBg;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.push('/orders/${o.id}'),
        child: Container(
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Expanded(
                flex: 12,
                child: Text(
                  o.formattedNumber,
                  style: AppTheme.numeric(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              Expanded(
                flex: 22,
                child: Text(
                  o.customerName ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.jakarta(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 28,
                child: Text(
                  o.description.isEmpty ? '—' : o.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.jakarta(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                flex: 18,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StatusBadge(status: o.status),
                ),
              ),
              Expanded(flex: 14, child: _DeadlineCell(order: o)),
              Expanded(
                flex: 16,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    Formatters.formatCurrency(o.totalValue),
                    style: AppTheme.numeric(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 10,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _StaleBadge(days: o.daysStale),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeadlineCell extends StatelessWidget {
  final ServiceOrder order;
  const _DeadlineCell({required this.order});

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
      return Text(
        '—',
        style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted),
      );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue = date.isBefore(today);
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');

    return Text(
      '$dd/$mm',
      style: AppTheme.jakarta(
        fontSize: 12,
        fontWeight: overdue ? FontWeight.w700 : FontWeight.w400,
        color: overdue ? AppColors.error : AppColors.textSecondary,
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
    final label = days <= 0 ? 'Hoje' : '${days}d';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: AppTheme.numeric(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ── Abas de status ────────────────────────────────────────────────────────────

class _StatusTabs extends StatelessWidget {
  final List<String> tabs;
  final List<ServiceOrder> all;
  final int archivedCount;
  final String archivedFilter;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _StatusTabs({
    required this.tabs,
    required this.all,
    required this.archivedCount,
    required this.archivedFilter,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Row(
          children: [
            _Tab(
              label: 'Todas',
              count: all.length,
              color: AppColors.accent,
              active: selected == null,
              onTap: () => onSelect(null),
            ),
            for (final s in tabs)
              _Tab(
                label: OSStatus.labels[s] ?? s,
                count: all.where((o) => o.status == s).length,
                color: AppColors.statusColors(s).color,
                active: selected == s,
                onTap: () => onSelect(s),
              ),
            if (archivedCount > 0)
              _Tab(
                label: 'Arquivadas',
                count: archivedCount,
                color: AppColors.textMuted,
                active: selected == archivedFilter,
                onTap: () => onSelect(archivedFilter),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.count,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          boxShadow: active ? AppTheme.shadowSoft : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTheme.jakarta(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: active ? color : AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
              decoration: BoxDecoration(
                color: active ? color : AppColors.neutral200,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '$count',
                style: AppTheme.numeric(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: active ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Cabeçalho compartilhado ─────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController searchController;
  final String searchHint;
  final String newLabel;
  final VoidCallback onNew;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.searchController,
    required this.searchHint,
    required this.newLabel,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 560;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTheme.syne(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.jakarta(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          );

          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: narrow ? 180 : 240,
                child: SearchField(
                  controller: searchController,
                  hint: searchHint,
                ),
              ),
              const SizedBox(width: 10),
              NewButton(label: newLabel, onPressed: onNew),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: SearchField(
                        controller: searchController,
                        hint: searchHint,
                      ),
                    ),
                    const SizedBox(width: 10),
                    NewButton(label: newLabel, onPressed: onNew),
                  ],
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [titleBlock, actions],
          );
        },
      ),
    );
  }
}

/// Campo de busca arredondado reutilizável.
class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const SearchField({super.key, required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        style: AppTheme.jakarta(fontSize: 13),
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          filled: true,
          fillColor: AppColors.surface,
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
          suffixIcon: Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppTheme.radiusXs),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('/',
              style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.textMuted)),
          ),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
      ),
    );
  }
}

/// Botão "Novo X" em âmbar com ícone +.
class NewButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const NewButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.white,
          elevation: 1,
          shadowColor: AppColors.shadowMedium,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          textStyle: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
