import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../providers/os_provider.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/widgets.dart';

// Dados mensais — substitua por dados reais do Supabase quando disponível
class _MonthData {
  final String label;
  final int created;
  final int delivered;
  const _MonthData(this.label, this.created, this.delivered);
}

const _kMonthly = [
  _MonthData('Dez', 8,  6),
  _MonthData('Jan', 12, 10),
  _MonthData('Fev', 9,  11),
  _MonthData('Mar', 15, 13),
  _MonthData('Abr', 18, 14),
  _MonthData('Mai', 14, 12),
];

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(osProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            onPressed: () => ref.invalidate(osProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
        data: (orders) => _ReportsBody(orders: orders),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────
class _ReportsBody extends StatelessWidget {
  final List<ServiceOrder> orders;
  const _ReportsBody({required this.orders});

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
    final delivered30 = orders.where((o) => o.status == OSStatus.entrega && o.updatedAt.isAfter(thirtyAgo)).toList();
    final totalValue  = last30.fold<double>(0, (s, o) => s + o.totalValue);
    final inProgress  = orders.where((o) => o.status != OSStatus.entrega).length;

    final todayD = DateTime(now.year, now.month, now.day);
    final entreguesNoPrazo = orders.where((o) {
      if (o.status != OSStatus.entrega || o.scheduledDate == null) return false;
      final dl = DateTime(o.scheduledDate!.year, o.scheduledDate!.month, o.scheduledDate!.day);
      final up = DateTime(o.updatedAt.year, o.updatedAt.month, o.updatedAt.day);
      return !up.isAfter(dl);
    }).length;
    final vencidas   = orders.where((o) {
      if (o.status == OSStatus.entrega || o.scheduledDate == null) return false;
      return DateTime(o.scheduledDate!.year, o.scheduledDate!.month, o.scheduledDate!.day)
          .isBefore(todayD);
    }).length;
    final semPrazo   = orders.where((o) => o.scheduledDate == null).length;
    final pontual    = delivered30.isEmpty
        ? 0 : (entreguesNoPrazo / delivered30.length * 100).round();

    final byStatus   = {for (var s in OSStatus.ordered) s: orders.where((o) => o.status == s).length};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

        // ── KPI row ────────────────────────────────────────────────────────
        Row(children: [
          _KPICard(label: 'OS Criadas (30d)',    value: '${last30.length}',                   icon: LucideIcons.clipboardList, color: AppColors.accent),
          const SizedBox(width: 12),
          _KPICard(label: 'OS Entregues (30d)',  value: '${delivered30.length}',              icon: LucideIcons.checkCircle,   color: AppColors.staleOk),
          const SizedBox(width: 12),
          _KPICard(label: 'Valor Orçado (30d)',  value: Formatters.formatCurrency(totalValue),icon: LucideIcons.dollarSign,    color: AppColors.primary),
          const SizedBox(width: 12),
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
              Expanded(flex: 2, child: _lineChartCard()),
              const SizedBox(width: 16),
              Expanded(child: _statusBarsCard(byStatus, orders.length)),
            ]);
          }
          return Column(children: [
            _lineChartCard(),
            const SizedBox(height: 16),
            _statusBarsCard(byStatus, orders.length),
          ]);
        }),
        const SizedBox(height: 20),

        // ── Prazo section ─────────────────────────────────────────────────
        _SectionCard(
          title: 'Cumprimento de Prazo',
          icon: LucideIcons.calendarCheck,
          child: IntrinsicHeight(
            child: Row(children: [
              _StatBlock(value: '$entreguesNoPrazo', label: 'Entregues no prazo',           color: AppColors.staleOk),
              _Divider(),
              _StatBlock(value: '$vencidas',         label: 'Com prazo vencido (em aberto)',color: AppColors.staleCrit),
              _Divider(),
              _StatBlock(value: '$semPrazo',         label: 'Sem prazo definido',           color: AppColors.textMuted),
              _Divider(),
              _StatBlock(value: '$inProgress',       label: 'Total em andamento',           color: AppColors.primary),
            ]),
          ),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }

  // ── Line chart ─────────────────────────────────────────────────────────────
  Widget _lineChartCard() => _SectionCard(
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
                      if (i < 0 || i >= _kMonthly.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_kMonthly[i].label,
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
              minX: 0, maxX: (_kMonthly.length - 1).toDouble(),
              minY: 0,
              lineBarsData: [
                // Criadas
                LineChartBarData(
                  spots: _kMonthly.asMap().entries
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
                      colors: [AppColors.accent.withValues(alpha: 0.18), AppColors.accent.withValues(alpha: 0)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Entregues
                LineChartBarData(
                  spots: _kMonthly.asMap().entries
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
  final String value, label;
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
