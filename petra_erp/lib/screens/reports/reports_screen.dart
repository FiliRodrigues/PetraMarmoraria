import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../models/models.dart';
import '../../providers/os_provider.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/widgets.dart';

/// Janela de tempo usada pelos filtros de período dos relatórios.
enum ReportPeriod { all, d30, d90, m6 }

extension ReportPeriodX on ReportPeriod {
  String get label => switch (this) {
        ReportPeriod.all => 'Tudo',
        ReportPeriod.d30 => '30 dias',
        ReportPeriod.d90 => '90 dias',
        ReportPeriod.m6 => '6 meses',
      };

  /// Data de corte (início do período); null = sem limite.
  DateTime? get since {
    final now = DateTime.now();
    return switch (this) {
      ReportPeriod.all => null,
      ReportPeriod.d30 => now.subtract(const Duration(days: 30)),
      ReportPeriod.d90 => now.subtract(const Duration(days: 90)),
      ReportPeriod.m6 => DateTime(now.year, now.month - 6, now.day),
    };
  }
}

/// Volume mensal real (criadas x entregues) para os últimos 6 meses.
class MonthVolume {
  final String label;
  final int created;
  final int delivered;
  const MonthVolume(this.label, this.created, this.delivered);
}

const _kMonthAbbr = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
  'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
];

/// Calcula o volume mensal real dos últimos 6 meses a partir das OS.
List<MonthVolume> computeMonthlyVolume(List<ServiceOrder> orders) {
  final now = DateTime.now();
  final buckets = <DateTime>[];
  for (var i = 5; i >= 0; i--) {
    buckets.add(DateTime(now.year, now.month - i, 1));
  }

  final created = {for (final b in buckets) b: 0};
  final delivered = {for (final b in buckets) b: 0};

  for (final o in orders) {
    final cKey = DateTime(o.createdAt.year, o.createdAt.month, 1);
    if (created.containsKey(cKey)) created[cKey] = created[cKey]! + 1;

    if (o.status == OSStatus.entregue) {
      final dKey = DateTime(o.statusChangedAt.year, o.statusChangedAt.month, 1);
      if (delivered.containsKey(dKey)) delivered[dKey] = delivered[dKey]! + 1;
    }
  }

  return buckets
      .map((b) => MonthVolume(_kMonthAbbr[b.month - 1], created[b]!, delivered[b]!))
      .toList();
}

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(osProvider);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Relatórios'),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              onPressed: () {
                ref.invalidate(osProvider);
                ref.invalidate(allAssignmentsProvider);
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.accent,
            tabs: [
              Tab(text: 'Geral'),
              Tab(text: 'Produção'),
              Tab(text: 'Vendas'),
              Tab(text: 'Orçamentos parados'),
            ],
          ),
        ),
        body: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text(friendlyError(err))),
          data: (orders) => TabBarView(
            children: [
              _ReportsGeral(orders: orders),
              _ReportsProducao(orders: orders),
              _ReportsVendas(orders: orders),
              _ReportsOrcamentosParados(orders: orders),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Aba: Geral ──────────────────────────────────────────────────────────────
class _ReportsGeral extends StatelessWidget {
  final List<ServiceOrder> orders;
  const _ReportsGeral({required this.orders});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Center(child: EmptyState(
        title: 'Nenhuma OS cadastrada',
        message: 'Crie a primeira ordem de serviço para ver os relatórios.',
        icon: LucideIcons.clipboardList,
      ));
    }

    final now         = DateTime.now();
    final thirtyAgo   = now.subtract(const Duration(days: 30));
    final last30      = orders.where((o) => o.createdAt.isAfter(thirtyAgo)).toList();
    final delivered30 = orders.where((o) => o.status == OSStatus.entregue && o.statusChangedAt.isAfter(thirtyAgo)).toList();
    final totalValue  = last30.fold<double>(0, (s, o) => s + o.totalValue);
    final inProgress  = orders.where((o) => o.status != OSStatus.entregue).length;

    final todayD = DateTime(now.year, now.month, now.day);
    final entreguesNoPrazo = orders.where((o) {
      if (o.status != OSStatus.entregue || o.scheduledDate == null) return false;
      final dl = DateTime(o.scheduledDate!.year, o.scheduledDate!.month, o.scheduledDate!.day);
      final up = DateTime(o.statusChangedAt.year, o.statusChangedAt.month, o.statusChangedAt.day);
      return !up.isAfter(dl);
    }).length;
    final vencidas   = orders.where((o) {
      if (o.status == OSStatus.entregue || o.scheduledDate == null) return false;
      return DateTime(o.scheduledDate!.year, o.scheduledDate!.month, o.scheduledDate!.day)
          .isBefore(todayD);
    }).length;
    final semPrazo   = orders.where((o) => o.scheduledDate == null).length;
    final pontual    = delivered30.isEmpty
        ? 0 : (entreguesNoPrazo / delivered30.length * 100).round();

    final byStatus   = {for (var s in OSStatus.ordered) s: orders.where((o) => o.status == s).length};
    final monthly    = computeMonthlyVolume(orders);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        // ── KPI row ────────────────────────────────────────────────────────
        ResponsiveKpiGrid(children: [
          _KPICard(label: 'OS Criadas (30d)',    value: '${last30.length}',                   icon: LucideIcons.clipboardList, color: AppColors.accent),
          _KPICard(label: 'OS Entregues (30d)',  value: '${delivered30.length}',              icon: LucideIcons.checkCircle,   color: AppColors.staleOk),
          _KPICard(label: 'Valor Orçado (30d)',  value: Formatters.formatCurrency(totalValue),icon: LucideIcons.dollarSign,    color: AppColors.primary),
          _KPICard(label: 'Pontualidade',        value: '$pontual%',
            sub: '$entreguesNoPrazo no prazo',
            icon: LucideIcons.award,
            color: pontual >= 80 ? AppColors.staleOk : AppColors.staleWarn),
        ]),
        const SizedBox(height: 20),

        // ── Charts row ─────────────────────────────────────────────────────
        LayoutBuilder(builder: (context, constraints) {
          final wide = constraints.maxWidth > 700;
          if (wide) {
            return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(flex: 2, child: _lineChartCard(monthly)),
              const SizedBox(width: 16),
              Expanded(child: _statusBarsCard(byStatus, orders.length)),
            ]);
          }
          return Column(children: [
            _lineChartCard(monthly),
            const SizedBox(height: 16),
            _statusBarsCard(byStatus, orders.length),
          ]);
        }),
        const SizedBox(height: 20),

        // ── Prazo section ─────────────────────────────────────────────────
        _SectionCard(
          title: 'Cumprimento de Prazo',
          icon: LucideIcons.calendarCheck,
          child: _PrazoBlocks(
            entreguesNoPrazo: entreguesNoPrazo,
            vencidas: vencidas,
            semPrazo: semPrazo,
            inProgress: inProgress,
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ── Line chart (volume mensal real) ─────────────────────────────────────────
  Widget _lineChartCard(List<MonthVolume> monthly) => _SectionCard(
    title: 'Volume Mensal',
    icon: LucideIcons.trendingUp,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(children: [
          _LegendDot(color: AppColors.accent,   label: 'OS Criadas'),
          const SizedBox(width: 16),
          _LegendDot(color: AppColors.primary,  label: 'Entregues'),
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
                topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= monthly.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(monthly[i].label,
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
              minX: 0, maxX: (monthly.length - 1).toDouble(),
              minY: 0,
              lineBarsData: [
                // Criadas
                LineChartBarData(
                  spots: monthly.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.created.toDouble()))
                      .toList(),
                  isCurved: true,
                  color: AppColors.accent,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 4, color: Colors.white,
                      strokeWidth: 2, strokeColor: AppColors.accent,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [AppColors.accent.withValues(alpha: 0.18), AppColors.accent.withValues(alpha: 0)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Entregues
                LineChartBarData(
                  spots: monthly.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.delivered.toDouble()))
                      .toList(),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 2.5,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 4, color: Colors.white,
                      strokeWidth: 2, strokeColor: AppColors.primary,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.12), AppColors.primary.withValues(alpha: 0)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  // ── Status bars ────────────────────────────────────────────────────────────
  Widget _statusBarsCard(Map<String, int> byStatus, int total) => _SectionCard(
    title: 'OS por Etapa',
    icon: LucideIcons.barChart2,
    child: Column(children: OSStatus.ordered.map((s) {
      final (:color, :bg) = AppColors.statusColors(s);
      final count = byStatus[s] ?? 0;
      final pct   = total > 0 ? count / total : 0.0;
      final label = OSStatus.labels[s] ?? s;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTheme.jakarta(fontSize: 12, color: AppColors.textSecondary)),
              Text('$count', style: AppTheme.numeric(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
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

// ── Aba: Produção por Funcionário ────────────────────────────────────────────
class _ReportsProducao extends ConsumerStatefulWidget {
  final List<ServiceOrder> orders;
  const _ReportsProducao({required this.orders});

  @override
  ConsumerState<_ReportsProducao> createState() => _ReportsProducaoState();
}

class _ProductionRow {
  final String name;
  int corte = 0, montagem = 0, entrega = 0; // concluídas
  int atribuidas = 0;
  _ProductionRow(this.name);
  int get total => corte + montagem + entrega;
}

class _ReportsProducaoState extends ConsumerState<_ReportsProducao> {
  ReportPeriod _period = ReportPeriod.all;

  @override
  Widget build(BuildContext context) {
    final assignmentsAsync = ref.watch(allAssignmentsProvider);

    return assignmentsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(friendlyError(err))),
      data: (assignments) {
        final since = _period.since;
        final filtered = since == null
            ? assignments
            : assignments.where((a) {
                final ref = a.completedAt ?? a.assignedAt;
                return ref.isAfter(since);
              }).toList();

        // Agrupa por funcionário × etapa.
        final byEmployee = <String, _ProductionRow>{};
        for (final a in filtered) {
          final row = byEmployee.putIfAbsent(
            a.employeeId,
            () => _ProductionRow(a.employeeName ?? 'Funcionário'),
          );
          row.atribuidas++;
          final concluida = a.completedAt != null;
          if (!concluida) continue;
          switch (a.stage) {
            case OSStatus.corte:
              row.corte++;
            case OSStatus.montagem:
              row.montagem++;
            case OSStatus.entrega:
              row.entrega++;
          }
        }

        final rows = byEmployee.values.toList()
          ..sort((a, b) => b.total.compareTo(a.total));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _PeriodSelector(value: _period, onChanged: (p) => setState(() => _period = p)),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EmptyState(
                  title: 'Sem dados de produção',
                  message: 'Nenhuma atribuição de etapa no período selecionado.',
                  icon: LucideIcons.hardHat,
                ),
              )
            else ...[
              _SectionCard(
                title: 'Produção por Funcionário',
                icon: LucideIcons.users,
                child: _ProductionTable(rows: rows),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Total de etapas concluídas',
                icon: LucideIcons.barChart2,
                child: _ProductionChart(rows: rows),
              ),
            ],
            const SizedBox(height: 24),
          ]),
        );
      },
    );
  }
}

class _ProductionTable extends StatelessWidget {
  final List<_ProductionRow> rows;
  const _ProductionTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final mobile = context.isMobile;
    final nameFlex = mobile ? 3 : 4;
    final numFlex = mobile ? 2 : 1;
    TextStyle h() => AppTheme.jakarta(fontSize: mobile ? 10 : 11, fontWeight: FontWeight.w700, color: AppColors.textMuted);
    Widget num(int v) => Text('$v',
        textAlign: TextAlign.right,
        style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w700));
    Widget head(String t) => Text(t, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: h());

    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          Expanded(flex: nameFlex, child: Text('FUNCIONÁRIO', maxLines: 1, overflow: TextOverflow.ellipsis, style: h())),
          Expanded(flex: numFlex, child: head('CORTE')),
          Expanded(flex: numFlex, child: head('MONT.')),
          Expanded(flex: numFlex, child: head('ENTR.')),
          Expanded(flex: numFlex, child: head('TOTAL')),
        ]),
      ),
      const Divider(color: AppColors.border),
      ...rows.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(children: [
              Expanded(
                flex: nameFlex,
                child: Text(r.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Expanded(flex: numFlex, child: num(r.corte)),
              Expanded(flex: numFlex, child: num(r.montagem)),
              Expanded(flex: numFlex, child: num(r.entrega)),
              Expanded(
                flex: numFlex,
                child: Text('${r.total}',
                    textAlign: TextAlign.right,
                    style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
            ]),
          )),
    ]);
  }
}

class _ProductionChart extends StatelessWidget {
  final List<_ProductionRow> rows;
  const _ProductionChart({required this.rows});

  @override
  Widget build(BuildContext context) {
    final shown = rows.take(8).toList();
    final maxVal = shown.fold<int>(1, (m, r) => r.total > m ? r.total : m);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (maxVal * 1.2).ceilToDouble(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [4, 4]),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: AppTheme.jakarta(fontSize: 10, color: AppColors.textMuted)),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= shown.length) return const SizedBox.shrink();
                  final first = shown[i].name.split(' ').first;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(first,
                        style: AppTheme.jakarta(fontSize: 10, color: AppColors.textMuted)),
                  );
                },
              ),
            ),
          ),
          barGroups: shown.asMap().entries.map((e) {
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: e.value.total.toDouble(),
                color: AppColors.accent,
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ── Aba: Vendas por Vendedor ──────────────────────────────────────────────────
class _ReportsVendas extends StatefulWidget {
  final List<ServiceOrder> orders;
  const _ReportsVendas({required this.orders});

  @override
  State<_ReportsVendas> createState() => _ReportsVendasState();
}

class _SellerRow {
  final String name;
  int count = 0;
  double total = 0;
  _SellerRow(this.name);
}

class _ReportsVendasState extends State<_ReportsVendas> {
  ReportPeriod _period = ReportPeriod.all;
  bool _onlyApproved = false;

  @override
  Widget build(BuildContext context) {
    final since = _period.since;
    final filtered = widget.orders.where((o) {
      if (since != null && !o.createdAt.isAfter(since)) return false;
      if (_onlyApproved && OSStatus.indexOf(o.status) < OSStatus.indexOf(OSStatus.aprovado)) return false;
      return true;
    }).toList();

    final bySeller = <String, _SellerRow>{};
    for (final o in filtered) {
      final key = o.createdBy ?? '__none__';
      final name = o.createdByName ?? 'Sem vendedor';
      final row = bySeller.putIfAbsent(key, () => _SellerRow(name));
      row.count++;
      row.total += o.totalValue;
    }

    final rows = bySeller.values.toList()..sort((a, b) => b.total.compareTo(a.total));
    final grandTotal = rows.fold<double>(0, (s, r) => s + r.total);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _PeriodSelector(value: _period, onChanged: (p) => setState(() => _period = p)),
        const SizedBox(height: 10),
        Row(children: [
          Checkbox(
            value: _onlyApproved,
            onChanged: (v) => setState(() => _onlyApproved = v ?? false),
          ),
          Expanded(
            child: Text('Somente OS aprovadas ou em etapa posterior',
                style: AppTheme.jakarta(fontSize: 12.5, color: AppColors.textSecondary)),
          ),
        ]),
        const SizedBox(height: 8),
        if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EmptyState(
              title: 'Sem vendas no período',
              message: 'Nenhuma OS encontrada para os filtros selecionados.',
              icon: LucideIcons.dollarSign,
            ),
          )
        else ...[
          ResponsiveKpiGrid(children: [
            _KPICard(label: 'Total vendido', value: Formatters.formatCurrency(grandTotal), icon: LucideIcons.dollarSign, color: AppColors.primary),
            _KPICard(label: 'OS no período', value: '${filtered.length}', icon: LucideIcons.clipboardList, color: AppColors.accent),
            _KPICard(
              label: 'Top vendedor',
              value: rows.first.name.split(' ').first,
              sub: Formatters.formatCurrency(rows.first.total),
              icon: LucideIcons.award,
              color: AppColors.staleOk,
            ),
          ]),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Ranking de Vendas',
            icon: LucideIcons.trophy,
            child: _SellerTable(rows: rows),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Valor vendido por vendedor',
            icon: LucideIcons.barChart2,
            child: _SellerChart(rows: rows),
          ),
        ],
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _SellerTable extends StatelessWidget {
  final List<_SellerRow> rows;
  const _SellerTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    TextStyle h() => AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          SizedBox(width: 28, child: Text('#', style: h())),
          Expanded(flex: 4, child: Text('VENDEDOR', style: h())),
          Expanded(child: Text('OS', textAlign: TextAlign.right, style: h())),
          Expanded(flex: 3, child: Text('TOTAL', textAlign: TextAlign.right, style: h())),
        ]),
      ),
      const Divider(color: AppColors.border),
      ...rows.asMap().entries.map((e) {
        final i = e.key;
        final r = e.value;
        final isTop = i == 0;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: isTop
              ? BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                )
              : null,
          child: Row(children: [
            SizedBox(
              width: 28,
              child: Text('${i + 1}',
                  style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w800,
                      color: isTop ? AppColors.accent : AppColors.textMuted)),
            ),
            Expanded(
              flex: 4,
              child: Row(children: [
                if (isTop) ...[
                  const Icon(LucideIcons.award, size: 14, color: AppColors.accent),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.jakarta(fontSize: 13,
                          fontWeight: isTop ? FontWeight.w800 : FontWeight.w600)),
                ),
              ]),
            ),
            Expanded(
              child: Text('${r.count}',
                  textAlign: TextAlign.right,
                  style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w700)),
            ),
            Expanded(
              flex: 3,
              child: Text(Formatters.formatCurrency(r.total),
                  textAlign: TextAlign.right,
                  style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
          ]),
        );
      }),
    ]);
  }
}

class _SellerChart extends StatelessWidget {
  final List<_SellerRow> rows;
  const _SellerChart({required this.rows});

  @override
  Widget build(BuildContext context) {
    final shown = rows.take(8).toList();
    final maxVal = shown.fold<double>(1, (m, r) => r.total > m ? r.total : m);

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [4, 4]),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= shown.length) return const SizedBox.shrink();
                  final first = shown[i].name.split(' ').first;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(first,
                        style: AppTheme.jakarta(fontSize: 10, color: AppColors.textMuted)),
                  );
                },
              ),
            ),
          ),
          barGroups: shown.asMap().entries.map((e) {
            final isTop = e.key == 0;
            return BarChartGroupData(x: e.key, barRods: [
              BarChartRodData(
                toY: e.value.total,
                color: isTop ? AppColors.accent : AppColors.primary,
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}

// ── Aba: Orçamentos parados ───────────────────────────────────────────────────
class _ReportsOrcamentosParados extends StatelessWidget {
  final List<ServiceOrder> orders;
  const _ReportsOrcamentosParados({required this.orders});

  @override
  Widget build(BuildContext context) {
    final stalled = orders.where((o) => o.status == OSStatus.orcamento).toList()
      ..sort((a, b) => b.daysStale.compareTo(a.daysStale));

    if (stalled.isEmpty) {
      return const Center(child: EmptyState(
        title: 'Nenhum orçamento parado',
        message: 'Todas as OS em orçamento foram aprovadas ou avançaram.',
        icon: LucideIcons.checkCircle,
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _SectionCard(
        title: '${stalled.length} orçamento(s) aguardando aprovação',
        icon: LucideIcons.fileClock,
        child: Column(children: [
          for (final o in stalled) _StalledRow(order: o),
        ]),
      ),
    );
  }
}

class _StalledRow extends StatelessWidget {
  final ServiceOrder order;
  const _StalledRow({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.stalenessColor(order.daysStale);

    Widget badge() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXs),
      ),
      child: Text(order.daysStale <= 0 ? 'Hoje' : '${order.daysStale}d parado',
          style: AppTheme.numeric(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
    );

    Widget content;
    if (context.isMobile) {
      content = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(order.formattedNumber,
              style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(order.customerName ?? '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(Formatters.formatCurrency(order.totalValue),
              maxLines: 1,
              style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w700)),
          badge(),
        ]),
      ]);
    } else {
      content = Row(children: [
        Expanded(
          flex: 3,
          child: Text(order.formattedNumber,
              style: AppTheme.numeric(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
        ),
        Expanded(
          flex: 6,
          child: Text(order.customerName ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        Expanded(
          flex: 4,
          child: Text(Formatters.formatCurrency(order.totalValue),
              maxLines: 1,
              textAlign: TextAlign.right,
              style: AppTheme.numeric(fontSize: 12.5, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        badge(),
      ]);
    }

    return InkWell(
      onTap: () => context.push('/orders/${order.id}'),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: content,
      ),
    );
  }
}

// ── Seletor de período ────────────────────────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  final ReportPeriod value;
  final ValueChanged<ReportPeriod> onChanged;
  const _PeriodSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, children: ReportPeriod.values.map((p) {
      final active = p == value;
      return ChoiceChip(
        label: Text(p.label),
        selected: active,
        onSelected: (_) => onChanged(p),
        labelStyle: AppTheme.jakarta(
          fontSize: 12,
          fontWeight: active ? FontWeight.w700 : FontWeight.w400,
          color: active ? Colors.white : AppColors.textSecondary,
        ),
        selectedColor: AppColors.accent,
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          side: BorderSide(color: active ? AppColors.accent : AppColors.border),
        ),
      );
    }).toList());
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────
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
        Expanded(child: Text(title, style: AppTheme.syne(fontSize: 13.5, fontWeight: FontWeight.w700))),
      ]),
      const SizedBox(height: 4),
      const Divider(color: AppColors.border),
      const SizedBox(height: 8),
      child,
    ]),
  );
}

class _KPICard extends StatelessWidget {
  final String label, value;
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
          Expanded(child: Text(label, style: AppTheme.jakarta(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
          Icon(icon, size: 14, color: AppColors.textMuted),
        ]),
        const SizedBox(height: 6),
        Text(value,
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: AppTheme.numeric(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        if (sub != null) ...[
          const SizedBox(height: 3),
          Text(sub!, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppTheme.jakarta(fontSize: 11, color: AppColors.textMuted)),
        ],
      ]),
    ),
  );
}

class _StatBlock extends StatelessWidget {
  final String value, label;
  final Color color;
  final bool center;
  const _StatBlock({required this.value, required this.label, required this.color, this.center = false});

  @override
  Widget build(BuildContext context) {
    final fontSize = center ? 26.0 : 32.0;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
            Text(value,
              style: AppTheme.numeric(fontSize: fontSize, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 6),
            Text(label,
              textAlign: center ? TextAlign.center : TextAlign.start,
              style: AppTheme.jakarta(fontSize: 11.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

/// Cumprimento de Prazo: linha única no desktop, grade 2×2 no celular.
class _PrazoBlocks extends StatelessWidget {
  final int entreguesNoPrazo, vencidas, semPrazo, inProgress;
  const _PrazoBlocks({
    required this.entreguesNoPrazo,
    required this.vencidas,
    required this.semPrazo,
    required this.inProgress,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Column(children: [
        IntrinsicHeight(child: Row(children: [
          _StatBlock(value: '$entreguesNoPrazo', label: 'Entregues no prazo',            color: AppColors.staleOk,   center: true),
          _Divider(),
          _StatBlock(value: '$vencidas',          label: 'Com prazo vencido (em aberto)', color: AppColors.staleCrit, center: true),
        ])),
        const SizedBox(height: 16),
        IntrinsicHeight(child: Row(children: [
          _StatBlock(value: '$semPrazo',   label: 'Sem prazo definido',  color: AppColors.textMuted, center: true),
          _Divider(),
          _StatBlock(value: '$inProgress', label: 'Total em andamento',  color: AppColors.primary,   center: true),
        ])),
      ]);
    }

    return IntrinsicHeight(
      child: Row(children: [
        _StatBlock(value: '$entreguesNoPrazo', label: 'Entregues no prazo',            color: AppColors.staleOk),
        _Divider(),
        _StatBlock(value: '$vencidas',          label: 'Com prazo vencido (em aberto)', color: AppColors.staleCrit),
        _Divider(),
        _StatBlock(value: '$semPrazo',          label: 'Sem prazo definido',            color: AppColors.textMuted),
        _Divider(),
        _StatBlock(value: '$inProgress',        label: 'Total em andamento',            color: AppColors.primary),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
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
