import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../providers/os_provider.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/status_badge.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';
  String? _filterStatus;
  String _sortCol = 'number';
  bool _sortAsc = false;
  int? _filterMonth;
  int? _filterYear;

  static const _cols = [
    ('number', 'OS#'),
    ('client', 'Cliente'),
    ('material', 'Material'),
    ('status', 'Etapa'),
    ('date', 'Prazo'),
    ('value', 'Valor'),
    ('stale', 'Tempo na etapa'),
  ];

  final _months = const <int?>[
    null,
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
  ];

  List<int> get _years {
    final y = DateTime.now().year;
    return List.generate(7, (i) => y - 3 + i);
  }

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    final now = DateTime.now();
    _filterMonth = now.month;
    _filterYear = now.year;
  }

  void _onSearchChanged() {
    setState(() => _searchText = _searchController.text);
    _applyServerFilters();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(osPagedProvider.notifier).loadMore();
    }
  }

  void _applyServerFilters() {
    ref.read(osPagedProvider.notifier).refreshWithFilters(
      search: _searchText.isEmpty ? null : _searchText,
      status: _filterStatus,
      month: _filterMonth,
      year: _filterYear,
    );
  }

  String _formatMonth(int? m) {
    const names = ['', 'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
    return m == null ? 'Todos os meses' : names[m];
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sort(String col) => setState(() {
    _sortCol == col ? _sortAsc = !_sortAsc : (_sortCol = col, _sortAsc = true);
  });

  List<ServiceOrder> _sorted(List<ServiceOrder> list) {
    final s = List<ServiceOrder>.from(list);
    s.sort((a, b) {
      final cmp = switch (_sortCol) {
        'number'   => a.displayNumber.compareTo(b.displayNumber),
        'client'   => (a.customerName ?? '').compareTo(b.customerName ?? ''),
        'status'   => OSStatus.indexOf(a.status).compareTo(OSStatus.indexOf(b.status)),
        'value'    => a.totalValue.compareTo(b.totalValue),
        'date'     => (a.scheduledDate ?? DateTime(9999)).compareTo(b.scheduledDate ?? DateTime(9999)),
        'stale'    => a.daysStale.compareTo(b.daysStale),
        _          => 0,
      };
      return _sortAsc ? cmp : -cmp;
    });
    return s;
  }

  Color _stalenessColor(int days) =>
    days <= 2 ? AppColors.success : days <= 5 ? AppColors.warning : AppColors.error;

  String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final paged = ref.watch(osPagedProvider);
    final rows = _sorted(paged.items);
    final total = rows.fold<double>(0, (s, o) => s + o.totalValue);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordens de Serviço'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, size: 18),
            tooltip: 'Nova OS',
            onPressed: () => context.push('/orders/new'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar OS#, cliente, material...',
                      prefixIcon: Icon(LucideIcons.search, size: 16),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                DropdownButton<String?>(
                  value: _filterStatus,
                  hint: Text('Todas etapas', style: AppTheme.jakarta(fontSize: 13)),
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(value: null, child: Text('Todas etapas', style: AppTheme.jakarta(fontSize: 13))),
                    ...OSStatus.ordered.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(OSStatus.labels[s] ?? s, style: AppTheme.jakarta(fontSize: 13)),
                    )),
                  ],
                  onChanged: (v) {
                    setState(() => _filterStatus = v);
                    _applyServerFilters();
                  },
                ),
                DropdownButton<int?>(
                  value: _filterMonth,
                  hint: const Text('Mês', style: TextStyle(fontSize: 13)),
                  underline: const SizedBox(),
                  items: _months.map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(_formatMonth(m), style: AppTheme.jakarta(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) {
                    setState(() => _filterMonth = v);
                    _applyServerFilters();
                  },
                ),
                DropdownButton<int?>(
                  value: _filterYear,
                  hint: const Text('Ano', style: TextStyle(fontSize: 13)),
                  underline: const SizedBox(),
                  items: _years.map((y) => DropdownMenuItem(
                    value: y,
                    child: Text('$y', style: AppTheme.jakarta(fontSize: 13)),
                  )).toList(),
                  onChanged: (v) {
                    setState(() => _filterYear = v);
                    _applyServerFilters();
                  },
                ),
                if (_filterStatus != null || _searchText.isNotEmpty)
                  TextButton.icon(
                    icon: const Icon(LucideIcons.x, size: 14),
                    label: const Text('Limpar'),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _filterStatus = null;
                        _searchText = '';
                      });
                      _applyServerFilters();
                    },
                  ),
                const Spacer(),
                if (paged.isLoadingMore)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                else
                  Text(
                    '${rows.length}${paged.hasMore ? '+' : ''} OS  •  ${Formatters.formatCurrency(total)}',
                    style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  ),
              ],
            ),
          ),

          if (paged.error != null && paged.items.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Erro: ${paged.error}', style: AppTheme.jakarta(color: AppColors.textMuted)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _applyServerFilters,
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            )
          else if (paged.items.isEmpty && paged.isLoadingMore)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (rows.isEmpty)
            const Expanded(
              child: EmptyState(
                title: 'Nenhuma OS encontrada',
                message: 'Crie uma nova ordem de serviço para começar.',
                icon: LucideIcons.clipboardList,
              ),
            )
          else
            Expanded(child: _buildTable(rows)),
        ],
      ),
    );
  }

  Widget _buildTable(List<ServiceOrder> rows) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: constraints.maxHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: rows.asMap().entries.map((e) => _buildRow(e.key, e.value)).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 2),
        ),
      ),
      child: Row(
        children: [
          ..._cols.map((c) => _headerCell(c.$1, c.$2)),
          const SizedBox(width: 80, child: SizedBox()),
        ],
      ),
    );
  }

  Widget _headerCell(String col, String label) {
    final isSorted = _sortCol == col;
    final sortable = col != 'material';
    return Expanded(
      child: InkWell(
        onTap: sortable ? () => _sort(col) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTheme.syne(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isSorted ? AppColors.primary : AppColors.textMuted,
                ).copyWith(letterSpacing: 0.5),
              ),
              if (isSorted) ...[
                const SizedBox(width: 4),
                Icon(
                  _sortAsc ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 12,
                  color: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(int index, ServiceOrder o) {
    final days = o.daysStale;
    final sc = _stalenessColor(days);
    final isOverdue = o.scheduledDate != null &&
        o.status != OSStatus.entrega &&
        o.scheduledDate!.isBefore(DateTime.now());

    return InkWell(
      onTap: () => context.push('/orders/${o.id}'),
      hoverColor: AppColors.primary.withOpacity(0.03),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            // OS#
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 3, height: 32,
                      decoration: BoxDecoration(color: sc, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 8),
                    Text(o.formattedNumber,
                      style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                  ],
                ),
              ),
            ),
            // Cliente
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(o.customerName ?? '—',
                  style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            // Material
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(o.material ?? '—',
                  style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ),
            // Etapa
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: StatusBadge(status: o.status),
              ),
            ),
            // Prazo
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: o.scheduledDate == null
                    ? Text('—', style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.calendar, size: 12,
                            color: isOverdue ? AppColors.error : AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(_fmtDate(o.scheduledDate!),
                            style: AppTheme.jakarta(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isOverdue ? AppColors.error : AppColors.primary,
                            )),
                        ],
                      ),
              ),
            ),
            // Valor
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(Formatters.formatCurrency(o.totalValue),
                  style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                  textAlign: TextAlign.right),
              ),
            ),
            // Tempo na etapa
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sc.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                      border: Border.all(color: sc.withOpacity(0.3)),
                    ),
                    child: Text(days == 0 ? 'Hoje' : '$days d',
                      style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: sc)),
                  ),
                ),
              ),
            ),
            // Ações
            SizedBox(
              width: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.eye, size: 15, color: AppColors.textMuted),
                    tooltip: 'Ver detalhes',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => context.push('/orders/${o.id}'),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.edit, size: 15, color: AppColors.textMuted),
                    tooltip: 'Editar',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    onPressed: () => context.push('/orders/${o.id}/edit'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
