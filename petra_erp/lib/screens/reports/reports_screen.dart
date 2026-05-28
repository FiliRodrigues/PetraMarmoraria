import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/months.dart';
import '../../core/utils/formatters.dart';
import '../../models/models.dart';
import '../../providers/finance_provider.dart';
import '../../providers/os_provider.dart';
import '../../providers/supabase_provider.dart';
import '../../widgets/common/empty_state.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _filterMonth = DateTime.now().month;
  int _filterYear = DateTime.now().year;

  final _months = const <int>[
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12,
  ];

  List<int> get _years {
    final y = DateTime.now().year;
    return List.generate(7, (i) => y - 3 + i);
  }

  String _formatMonth(int m) => formatMonth(m);

  DateTime get _fromDate {
    final firstDay = DateTime(_filterYear, _filterMonth, 1);
    return firstDay;
  }

  DateTime get _toDate {
    final nextMonth = _filterMonth == 12
        ? DateTime(_filterYear + 1, 1, 1)
        : DateTime(_filterYear, _filterMonth + 1, 1);
    return nextMonth.subtract(const Duration(microseconds: 1));
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(osProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Relatórios — ${_formatMonth(_filterMonth)} $_filterYear'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(osProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Erro: $err', style: AppTheme.jakarta(color: AppColors.textMuted)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(osProvider),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
        data: (orders) {
          final from = _fromDate;
          final to = _toDate;

          final monthOrders = orders.where((o) {
            return !o.createdAt.isBefore(from) && !o.createdAt.isAfter(to);
          }).toList();

          return _ReportsContent(
            orders: orders,
            monthOrders: monthOrders,
            filterMonth: _filterMonth,
            filterYear: _filterYear,
            fromDate: from,
            toDate: to,
            months: _months,
            years: _years,
            formatMonth: _formatMonth,
            onMonthChanged: (m) => setState(() => _filterMonth = m),
            onYearChanged: (y) => setState(() => _filterYear = y),
          );
        },
      ),
    );
  }
}

class _ReportsContent extends ConsumerWidget {
  final List<ServiceOrder> orders;
  final List<ServiceOrder> monthOrders;
  final int filterMonth;
  final int filterYear;
  final DateTime fromDate;
  final DateTime toDate;
  final List<int> months;
  final List<int> years;
  final String Function(int) formatMonth;
  final ValueChanged<int> onMonthChanged;
  final ValueChanged<int> onYearChanged;

  const _ReportsContent({
    required this.orders,
    required this.monthOrders,
    required this.filterMonth,
    required this.filterYear,
    required this.fromDate,
    required this.toDate,
    required this.months,
    required this.years,
    required this.formatMonth,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (orders.isEmpty) {
      return const Center(
        child: EmptyState(
          title: 'Nenhuma OS cadastrada',
          message: 'Crie a primeira ordem de serviço para ver os relatórios.',
          icon: LucideIcons.clipboardList,
        ),
      );
    }

    if (monthOrders.isEmpty) {
      return Center(
        child: EmptyState(
          title: 'Nenhuma OS em ${formatMonth(filterMonth)} $filterYear',
          message: 'Nenhuma ordem de serviço foi criada neste período.',
          icon: LucideIcons.calendar,
        ),
      );
    }

    final now = DateTime.now();
    final delivered = monthOrders.where((o) => o.status == OSStatus.entrega).toList();
    final totalValue = monthOrders.fold<double>(0, (s, o) => s + o.totalValue);
    final inProgress = monthOrders.where((o) => o.status != OSStatus.entrega).length;

    final todayD = DateTime(now.year, now.month, now.day);
    final entreguesNoPrazo = monthOrders.where((o) {
      if (o.status != OSStatus.entrega || o.scheduledDate == null) return false;
      final dl = DateTime(o.scheduledDate!.year, o.scheduledDate!.month, o.scheduledDate!.day);
      final up = DateTime(o.updatedAt.year, o.updatedAt.month, o.updatedAt.day);
      return !up.isAfter(dl);
    }).length;
    final vencidas = monthOrders.where((o) {
      if (o.status == OSStatus.entrega || o.scheduledDate == null) return false;
      return DateTime(o.scheduledDate!.year, o.scheduledDate!.month, o.scheduledDate!.day)
          .isBefore(todayD);
    }).length;
    final semPrazo = monthOrders.where((o) => o.scheduledDate == null).length;
    final pontual = delivered.isEmpty
        ? 0 : (entreguesNoPrazo / delivered.length * 100).round();

    final byStatus = {for (var s in OSStatus.ordered) s: monthOrders.where((o) => o.status == s).length};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _buildFilterRow(),
        const SizedBox(height: 20),

        _buildKpiRow(monthOrders.length, delivered.length, totalValue, pontual, entreguesNoPrazo),
        const SizedBox(height: 20),

        _buildProductionByEmployee(ref, monthOrders),
        const SizedBox(height: 20),

        _buildClientReport(monthOrders),
        const SizedBox(height: 20),

        _buildChartsRow(byStatus, orders),
        const SizedBox(height: 20),

        _buildDeadlineSection(entreguesNoPrazo, vencidas, semPrazo, inProgress, pontual),
        const SizedBox(height: 20),

        _buildFinanceSection(ref, filterMonth, filterYear),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _buildFinanceSection(WidgetRef ref, int month, int year) {
    final summaryAsync = ref.watch(financeSummaryProvider((month: month, year: year)));

    return summaryAsync.when(
      loading: () => const _SectionCard(
        title: 'Financeiro',
        icon: LucideIcons.wallet,
        child: SizedBox(height: 80, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      ),
      error: (err, _) => _SectionCard(
        title: 'Financeiro',
        icon: LucideIcons.wallet,
        child: Text('Erro ao carregar dados: $err',
          style: AppTheme.jakarta(fontSize: 12, color: AppColors.error)),
      ),
      data: (summary) {
        final totalReceived = summary['totalReceived'] ?? 0;
        final totalToPay = summary['totalToPay'] ?? 0;
        final balance = summary['balance'] ?? 0;

        return _SectionCard(
          title: 'Financeiro',
          icon: LucideIcons.wallet,
          child: Row(children: [
            _KPICard(label: 'Total Recebido no Mês', value: Formatters.formatCurrency(totalReceived),
              icon: LucideIcons.arrowDownFromLine, color: AppColors.success),
            const SizedBox(width: 12),
            _KPICard(label: 'Total a Pagar', value: Formatters.formatCurrency(totalToPay),
              icon: LucideIcons.arrowUpFromLine, color: AppColors.error),
            const SizedBox(width: 12),
            _KPICard(label: 'Saldo do Mês', value: Formatters.formatCurrency(balance),
              icon: LucideIcons.barChart3,
              color: balance >= 0 ? AppColors.success : AppColors.error),
          ]),
        );
      },
    );
  }

  Widget _buildFilterRow() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Período:', style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w600)),
            DropdownButton<int>(
              value: filterMonth,
              underline: const SizedBox(),
              items: months.map((m) => DropdownMenuItem(
                value: m,
                child: Text(formatMonth(m), style: AppTheme.jakarta(fontSize: 13)),
              )).toList(),
              onChanged: (v) { if (v != null) onMonthChanged(v); },
            ),
            DropdownButton<int>(
              value: filterYear,
              underline: const SizedBox(),
              items: years.map((y) => DropdownMenuItem(
                value: y,
                child: Text('$y', style: AppTheme.jakarta(fontSize: 13)),
              )).toList(),
              onChanged: (v) { if (v != null) onYearChanged(v); },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiRow(int created, int delivered, double value, int pontual, int noPrazo) {
    return Row(children: [
      _KPICard(label: 'OS Criadas', value: '$created', icon: LucideIcons.clipboardList, color: AppColors.accent),
      const SizedBox(width: 12),
      _KPICard(label: 'OS Entregues', value: '$delivered', icon: LucideIcons.checkCircle, color: AppColors.staleOk),
      const SizedBox(width: 12),
      _KPICard(label: 'Valor Orçado', value: Formatters.formatCurrency(value), icon: LucideIcons.dollarSign, color: AppColors.primary),
      const SizedBox(width: 12),
      _KPICard(label: 'Pontualidade', value: '$pontual%',
        sub: '$noPrazo no prazo',
        icon: LucideIcons.award,
        color: pontual >= 80 ? AppColors.staleOk : AppColors.staleWarn),
    ]);
  }

  Widget _buildProductionByEmployee(WidgetRef ref, List<ServiceOrder> monthOrders) {
    final orderIdsKey = monthOrders.map((o) => o.id).join(',');

    final assignmentsAsync = ref.watch(_assignmentsForOrdersProvider(orderIdsKey));

    return _SectionCard(
      title: 'Produção por Funcionário',
      icon: LucideIcons.users,
      child: assignmentsAsync.when(
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (err, _) => Text('Erro ao carregar dados: $err',
          style: AppTheme.jakarta(fontSize: 12, color: AppColors.error)),
        data: (assignments) {
          final Map<String, Map<String, int>> byEmployee = {};

          for (final a in assignments) {
            final name = a.employeeName ?? 'Desconhecido';
            byEmployee.putIfAbsent(name, () => <String, int>{});
            final stageKey = a.stage == 'corte' ? 'Corte' : a.stage == 'montagem' ? 'Montagem' : a.stage == 'entrega' ? 'Entrega' : a.stage;
            byEmployee[name]![stageKey] = (byEmployee[name]![stageKey] ?? 0) + 1;
          }

          for (final entry in byEmployee.entries) {
            entry.value['Corte'] ??= 0;
            entry.value['Montagem'] ??= 0;
            entry.value['Entrega'] ??= 0;
          }

          final sorted = byEmployee.entries.toList()
            ..sort((a, b) => (b.value.values.fold<int>(0, (s, v) => s + v))
                .compareTo(a.value.values.fold<int>(0, (s, v) => s + v)));

          if (sorted.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Nenhuma designação neste período.',
                style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted)),
            );
          }

          return Column(children: [
            _buildTableHeader(),
            ...sorted.map((e) => _buildTableRow(e.key, e.value)),
          ]);
        },
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(children: [
        Expanded(flex: 2, child: Text('Funcionário', style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
        Expanded(child: Text('Corte', style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted), textAlign: TextAlign.center)),
        Expanded(child: Text('Montagem', style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted), textAlign: TextAlign.center)),
        Expanded(child: Text('Entrega', style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted), textAlign: TextAlign.center)),
        Expanded(child: Text('Total', style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary), textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _buildTableRow(String name, Map<String, int> stages) {
    final total = stages.values.fold<int>(0, (s, v) => s + v);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(children: [
        Expanded(flex: 2, child: Text(name, style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(child: Text('${stages['Corte'] ?? 0}', style: AppTheme.numeric(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center)),
        Expanded(child: Text('${stages['Montagem'] ?? 0}', style: AppTheme.numeric(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center)),
        Expanded(child: Text('${stages['Entrega'] ?? 0}', style: AppTheme.numeric(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center)),
        Expanded(child: Text('$total', style: AppTheme.numeric(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary), textAlign: TextAlign.center)),
      ]),
    );
  }

  Widget _buildClientReport(List<ServiceOrder> monthOrders) {
    final Map<String, Map<String, dynamic>> byClient = {};
    for (final o in monthOrders) {
      final name = o.customerName ?? 'Cliente ${o.customerId.substring(0, 8)}';
      byClient.putIfAbsent(name, () => {'count': 0, 'total': 0.0});
      byClient[name]!['count'] = (byClient[name]!['count'] as int) + 1;
      byClient[name]!['total'] = (byClient[name]!['total'] as double) + o.totalValue;
    }

    final sorted = byClient.entries.toList()
      ..sort((a, b) => (b.value['total'] as double).compareTo(a.value['total'] as double));

    return _SectionCard(
      title: 'OS por Cliente',
      icon: LucideIcons.building2,
      child: sorted.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Nenhum pedido neste período.',
                style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted)),
            )
          : Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(children: [
                  Expanded(flex: 3, child: Text('Cliente', style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted))),
                  Expanded(child: Text('Qtd OS', style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted), textAlign: TextAlign.center)),
                  Expanded(child: Text('Valor Total', style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted), textAlign: TextAlign.right)),
                ]),
              ),
              ...sorted.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: Row(children: [
                  Expanded(flex: 3, child: Text(e.key, style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  Expanded(child: Text('${e.value['count']}', style: AppTheme.numeric(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center)),
                  Expanded(child: Text(Formatters.formatCurrency(e.value['total'] as double), style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary), textAlign: TextAlign.right)),
                ]),
              )),
            ]),
    );
  }

  Widget _buildChartsRow(Map<String, int> byStatus, List<ServiceOrder> allOrders) {
    final monthlyData = _computeMonthlyVolume(allOrders);

    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth > 700;
      if (wide) {
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 2, child: _VolumeChartCard(data: monthlyData)),
          const SizedBox(width: 16),
          Expanded(child: _OsByStatusCard(byStatus: byStatus, total: allOrders.length)),
        ]);
      }
      return Column(children: [
        _VolumeChartCard(data: monthlyData),
        const SizedBox(height: 16),
        _OsByStatusCard(byStatus: byStatus, total: allOrders.length),
      ]);
    });
  }

  List<_MonthData> _computeMonthlyVolume(List<ServiceOrder> orders) {
    final now = DateTime.now();
    final result = <_MonthData>[];
    for (int i = 5; i >= 0; i--) {
      final m = now.month - i;
      final y = now.year + (m <= 0 ? -1 : 0);
      final adjM = m <= 0 ? m + 12 : m;
      final firstDay = DateTime(y, adjM, 1);
      final lastDay = adjM == 12
          ? DateTime(y + 1, 1, 1).subtract(const Duration(days: 1))
          : DateTime(y, adjM + 1, 1).subtract(const Duration(days: 1));

      final created = orders.where((o) => !o.createdAt.isBefore(firstDay) && !o.createdAt.isAfter(lastDay)).length;
      final delivered = orders.where((o) =>
        o.status == OSStatus.entrega &&
        !o.updatedAt.isBefore(firstDay) &&
        !o.updatedAt.isAfter(lastDay),
      ).length;

      const names = ['', 'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
      result.add(_MonthData(names[adjM], created, delivered));
    }
    return result;
  }

  Widget _buildDeadlineSection(int entreguesNoPrazo, int vencidas, int semPrazo, int inProgress, int pontual) {
    return _SectionCard(
      title: 'Cumprimento de Prazo',
      icon: LucideIcons.calendarCheck,
      child: IntrinsicHeight(
        child: Row(children: [
          _StatBlock(value: '$entreguesNoPrazo', label: 'Entregues no prazo', color: AppColors.staleOk),
          const _VerticalDiv(),
          _StatBlock(value: '$vencidas', label: 'Com prazo vencido', color: AppColors.staleCrit),
          const _VerticalDiv(),
          _StatBlock(value: '$semPrazo', label: 'Sem prazo definido', color: AppColors.textMuted),
          const _VerticalDiv(),
          _StatBlock(value: '$inProgress', label: 'Em andamento', color: AppColors.primary),
        ]),
      ),
    );
  }
}

class _MonthData {
  final String label;
  final int created;
  final int delivered;
  const _MonthData(this.label, this.created, this.delivered);
}

final _assignmentsForOrdersProvider = FutureProvider.family<List<OrderAssignment>, String>((ref, orderIdsKey) async {
  if (orderIdsKey.isEmpty) return [];
  final orderIds = orderIdsKey.split(',').where((id) => id.isNotEmpty).toList();
  final service = ref.read(serviceOrderServiceProvider);
  return await service.getAssignmentsForOrders(orderIds);
});

class _VolumeChartCard extends StatelessWidget {
  final List<_MonthData> data;
  const _VolumeChartCard({required this.data});

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'Volume Mensal',
    icon: LucideIcons.trendingUp,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _LegendDot(color: AppColors.accent, label: 'OS Criadas'),
        const SizedBox(width: 16),
        _LegendDot(color: AppColors.primary, label: 'Entregues'),
      ]),
      const SizedBox(height: 16),
      SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: AppColors.border,
                strokeWidth: 1,
                dashArray: [4, 4],
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= data.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(data[i].label,
                        style: AppTheme.jakarta(fontSize: 11, color: AppColors.textMuted)),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: AppTheme.jakarta(fontSize: 10, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0, maxX: (data.length - 1).toDouble(),
            minY: 0,
            lineBarsData: [
              LineChartBarData(
                spots: data.asMap().entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.created.toDouble()))
                    .toList(),
                isCurved: true,
                color: AppColors.accent,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 4, color: Colors.white,
                    strokeWidth: 2, strokeColor: AppColors.accent,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [AppColors.accent.withOpacity(0.18), AppColors.accent.withOpacity(0)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
              ),
              LineChartBarData(
                spots: data.asMap().entries
                    .map((e) => FlSpot(e.key.toDouble(), e.value.delivered.toDouble()))
                    .toList(),
                isCurved: true,
                color: AppColors.primary,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 4, color: Colors.white,
                    strokeWidth: 2, strokeColor: AppColors.primary,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.12), AppColors.primary.withOpacity(0)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ]),
  );
}

class _OsByStatusCard extends StatelessWidget {
  final Map<String, int> byStatus;
  final int total;
  const _OsByStatusCard({required this.byStatus, required this.total});

  @override
  Widget build(BuildContext context) => _SectionCard(
    title: 'OS por Etapa',
    icon: LucideIcons.barChart2,
    child: Column(children: OSStatus.ordered.map((s) {
      final (:color, :bg) = AppColors.statusColors(s);
      final count = byStatus[s] ?? 0;
      final pct = total > 0 ? count / total : 0.0;
      final label = OSStatus.labels[s] ?? s;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: AppTheme.jakarta(fontSize: 12, color: AppColors.textSecondary)),
            Text('$count', style: AppTheme.numeric(fontSize: 12, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 5),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ]),
      );
    }).toList()),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      border: Border.all(color: AppColors.border),
    ),
    padding: const EdgeInsets.all(22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(title, style: AppTheme.syne(fontSize: 13.5, fontWeight: FontWeight.w700)),
      ]),
      const SizedBox(height: 4),
      const Divider(color: AppColors.border),
      const SizedBox(height: 8),
      child,
    ]),
  );
}

class _KPICard extends StatelessWidget {
  final String label;
  final String value;
  final String? sub;
  final IconData icon;
  final Color color;
  const _KPICard({required this.label, required this.value, required this.icon, required this.color, this.sub});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: AppTheme.jakarta(fontSize: 11, color: AppColors.textMuted)),
          Icon(icon, size: 14, color: AppColors.textMuted),
        ]),
        const SizedBox(height: 6),
        Text(value,
          style: AppTheme.numeric(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        if (sub != null) ...[
          const SizedBox(height: 3),
          Text(sub!, style: AppTheme.jakarta(fontSize: 11, color: AppColors.textMuted)),
        ],
      ]),
    ),
  );
}

class _StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBlock({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
          style: AppTheme.numeric(fontSize: 32, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 6),
        Text(label, style: AppTheme.jakarta(fontSize: 11.5, color: AppColors.textSecondary)),
      ]),
    ),
  );
}

class _VerticalDiv extends StatelessWidget {
  const _VerticalDiv();

  @override
  Widget build(BuildContext context) =>
    const VerticalDivider(color: AppColors.border, width: 1, indent: 4, endIndent: 4);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 20, height: 3, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 6),
    Text(label, style: AppTheme.jakarta(fontSize: 12, color: AppColors.textSecondary)),
  ]);
}
