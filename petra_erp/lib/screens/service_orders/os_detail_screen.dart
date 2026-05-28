import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/status_badge.dart';
import 'os_print_screen.dart';

class OSDetailData {
  final ServiceOrder order;
  final Customer? customer;
  final List<OrderAssignment> assignments;
  final List<StatusHistory> history;
  final List<Profile> profiles;

  OSDetailData({
    required this.order,
    this.customer,
    this.assignments = const [],
    this.history = const [],
    this.profiles = const [],
  });
}

final osDetailDataProvider = FutureProvider.family<OSDetailData, String>((ref, id) async {
  final serviceOrderService = ref.watch(serviceOrderServiceProvider);
  final customerService = ref.watch(customerServiceProvider);
  final profileService = ref.watch(profileServiceProvider);

  final order = await serviceOrderService.getServiceOrderById(id);

  Customer? customer;
  try { customer = await customerService.getCustomerById(order.customerId); } catch (_) {}

  List<OrderAssignment> assignments = [];
  try { assignments = await serviceOrderService.getAssignments(id); } catch (_) {}

  List<StatusHistory> history = [];
  try { history = await serviceOrderService.getStatusHistory(id); } catch (_) {}

  List<Profile> profiles = [];
  try { profiles = await profileService.getProfiles(); } catch (_) {}

  return OSDetailData(order: order, customer: customer, assignments: assignments, history: history, profiles: profiles);
});

class OSDetailScreen extends ConsumerWidget {
  final String id;
  const OSDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailDataAsync = ref.watch(osDetailDataProvider(id));
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhe da OS'),
        actions: [
          detailDataAsync.maybeWhen(
            data: (data) => IconButton(
              icon: const Icon(LucideIcons.printer, size: 18),
              tooltip: 'Imprimir OS',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => OSPrintScreen(id: id)),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detailDataAsync.when(
        data: (data) => _Body(data: data, currencyFormat: currencyFormat, dateFormat: dateFormat, osId: id),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Erro ao carregar OS', style: AppTheme.syne(fontSize: 15, color: AppColors.error)),
              const SizedBox(height: 8),
              Text('$err', style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => ref.invalidate(osDetailDataProvider(id)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final OSDetailData data;
  final NumberFormat currencyFormat;
  final DateFormat dateFormat;
  final String osId;

  const _Body({required this.data, required this.currencyFormat, required this.dateFormat, required this.osId});

  @override
  Widget build(BuildContext context) {
    final order    = data.order;
    final customer = data.customer;

    // Parse measurements
    final List<Map<String, String>> measurementRows = [];
    final measurements = order.measurements;
    if (measurements.containsKey('items') && measurements['items'] is List) {
      for (final item in measurements['items'] as List) {
        if (item is Map) {
          measurementRows.add({
            'width':     (item['width']     ?? item['largura']    ?? '-').toString(),
            'height':    (item['height']    ?? item['altura']     ?? '-').toString(),
            'thickness': (item['thickness'] ?? item['espessura']  ?? '-').toString(),
            'format':    (item['format']    ?? item['formato']    ?? '-').toString(),
            'details':   (item['details']   ?? item['detalhes']   ?? '-').toString(),
          });
        }
      }
    } else {
      final hasKeys = measurements.containsKey('width') || measurements.containsKey('largura') ||
          measurements.containsKey('height') || measurements.containsKey('altura') ||
          measurements.containsKey('thickness') || measurements.containsKey('espessura');
      if (hasKeys) {
        measurementRows.add({
          'width':     (measurements['width']     ?? measurements['largura']   ?? '-').toString(),
          'height':    (measurements['height']    ?? measurements['altura']    ?? '-').toString(),
          'thickness': (measurements['thickness'] ?? measurements['espessura'] ?? '-').toString(),
          'format':    (measurements['format']    ?? measurements['formato']   ?? '-').toString(),
          'details':   (measurements['details']   ?? measurements['detalhes']  ?? '-').toString(),
        });
      }
    }

    // Resolve team
    String vendedor = 'Não atribuído', cortador = 'Não atribuído',
           montador = 'Não atribuído', entregador = 'Não atribuído';
    for (final a in data.assignments) {
      final name = a.employeeName ?? 'Atribuído';
      if (a.stage == 'corte')    cortador  = name;
      if (a.stage == 'montagem') montador  = name;
      if (a.stage == 'entrega')  entregador = name;
    }
    if (data.history.isNotEmpty) {
      final sorted = List<StatusHistory>.from(data.history)..sort((a, b) => a.changedAt.compareTo(b.changedAt));
      final first = sorted.first;
      final creator = data.profiles.firstWhere((p) => p.id == first.changedBy,
          orElse: () => Profile(id: '', email: '', name: '', role: '', createdAt: DateTime(1970)));
      if (creator.name.isNotEmpty && creator.role.toLowerCase() == 'vendedor') {
        vendedor = creator.name;
      } else if (first.changedByName != null) {
        vendedor = first.changedByName!;
      }
    }
    if (vendedor == 'Não atribuído') {
      final seller = data.profiles.firstWhere((p) => p.role.toLowerCase() == 'vendedor',
          orElse: () => Profile(id: '', email: '', name: '', role: '', createdAt: DateTime(1970)));
      if (seller.name.isNotEmpty) vendedor = seller.name;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header card ──────────────────────────────────────────────────
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'OS ${order.formattedNumber}',
                        style: AppTheme.syne(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ),
                    StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _InfoBlock(label: 'Criada em', value: dateFormat.format(order.createdAt))),
                    Expanded(
                      child: _InfoBlock(
                        label: 'Valor Total',
                        value: currencyFormat.format(order.totalValue),
                        valueStyle: AppTheme.numeric(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.accent),
                        align: CrossAxisAlignment.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Cliente ──────────────────────────────────────────────────────
          _SectionLabel(icon: LucideIcons.user, label: 'DADOS DO CLIENTE'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow('Nome',      customer?.name ?? order.customerName ?? 'Não informado'),
                _DetailRow('Telefone',  customer?.phone ?? 'Não informado'),
                if (customer?.phone2 != null) _DetailRow('Telefone 2', customer!.phone2!),
                _DetailRow('Endereço',  customer?.address ?? 'Não informado'),
                if (customer?.city != null)
                  _DetailRow('Cidade/UF', '${customer?.city ?? "-"} / ${customer?.state ?? "-"}'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Especificações ───────────────────────────────────────────────
          _SectionLabel(icon: LucideIcons.settings, label: 'ESPECIFICAÇÕES DO SERVIÇO'),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _DetailRow('Material',    order.material   ?? 'Não informado')),
                    Expanded(child: _DetailRow('Acabamento',  order.edgeType   ?? 'Não informado')),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Descrição / Observações', style: AppTheme.jakarta(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w700).copyWith(letterSpacing: 0.3)),
                const SizedBox(height: 4),
                Text(
                  order.description.isNotEmpty ? order.description : 'Nenhuma observação cadastrada.',
                  style: AppTheme.jakarta(fontSize: 13.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Medições ─────────────────────────────────────────────────────
          _SectionLabel(icon: LucideIcons.ruler, label: 'MEDIÇÕES'),
          _Card(
            child: measurementRows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('Nenhuma medição cadastrada.', style: AppTheme.jakarta(color: AppColors.textMuted)),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      headingTextStyle: AppTheme.jakarta(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      dataTextStyle: AppTheme.jakarta(fontSize: 13),
                      columns: const [
                        DataColumn(label: Text('Largura (m)')),
                        DataColumn(label: Text('Altura (m)')),
                        DataColumn(label: Text('Espessura (cm)')),
                        DataColumn(label: Text('Formato')),
                        DataColumn(label: Text('Detalhes')),
                      ],
                      rows: measurementRows.map((row) => DataRow(cells: [
                        DataCell(Text(row['width']     ?? '-')),
                        DataCell(Text(row['height']    ?? '-')),
                        DataCell(Text(row['thickness'] ?? '-')),
                        DataCell(Text(row['format']    ?? '-')),
                        DataCell(Text(row['details']   ?? '-')),
                      ])).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 16),

          // ── Desenho ──────────────────────────────────────────────────────
          _SectionLabel(icon: LucideIcons.image, label: 'DESENHO / ESBOÇO'),
          _Card(
            child: order.drawingUrl != null && order.drawingUrl!.trim().isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    child: Image.network(
                      order.drawingUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (_, __, ___) => _EmptyDrawing(),
                    ),
                  )
                : _EmptyDrawing(),
          ),
          const SizedBox(height: 16),

          // ── Equipe ───────────────────────────────────────────────────────
          _SectionLabel(icon: LucideIcons.users, label: 'EQUIPE RESPONSÁVEL'),
          _Card(
            child: Column(
              children: [
                _TeamRow('Vendedor',   vendedor,   LucideIcons.badge),
                const Divider(color: AppColors.border, height: 20),
                _TeamRow('Cortador',   cortador,   LucideIcons.scissors),
                const Divider(color: AppColors.border, height: 20),
                _TeamRow('Montador',   montador,   LucideIcons.wrench),
                const Divider(color: AppColors.border, height: 20),
                _TeamRow('Entregador', entregador, LucideIcons.truck),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Botão imprimir ───────────────────────────────────────────────
          SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              icon: const Icon(LucideIcons.printer, size: 16),
              label: const Text('Visualizar e Imprimir OS'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => OSPrintScreen(id: osId)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Componentes internos ──────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      border: Border.all(color: AppColors.border),
    ),
    padding: const EdgeInsets.all(18),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, left: 2),
    child: Row(
      children: [
        Icon(icon, size: 13, color: AppColors.accent),
        const SizedBox(width: 7),
        Text(label, style: AppTheme.jakarta(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.textMuted).copyWith(letterSpacing: 1.2)),
      ],
    ),
  );
}

class _InfoBlock extends StatelessWidget {
  final String label, value;
  final TextStyle? valueStyle;
  final CrossAxisAlignment align;
  const _InfoBlock({required this.label, required this.value, this.valueStyle, this.align = CrossAxisAlignment.start});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: align,
    children: [
      Text(label, style: AppTheme.jakarta(fontSize: 11, color: AppColors.textMuted)),
      const SizedBox(height: 3),
      Text(value, style: valueStyle ?? AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w600)),
    ],
  );
}

class _DetailRow extends StatelessWidget {
  final String label, value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTheme.jakarta(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: AppTheme.jakarta(fontSize: 13.5, fontWeight: FontWeight.w500)),
      ],
    ),
  );
}

class _TeamRow extends StatelessWidget {
  final String role, name;
  final IconData icon;
  const _TeamRow(this.role, this.name, this.icon);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(icon, size: 15, color: AppColors.textMuted),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role, style: AppTheme.jakarta(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          Text(name, style: AppTheme.jakarta(fontSize: 13.5, fontWeight: FontWeight.w600)),
        ],
      ),
    ],
  );
}

class _EmptyDrawing extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 100,
    alignment: Alignment.center,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(LucideIcons.image, size: 32, color: AppColors.border),
        const SizedBox(height: 8),
        Text('Nenhum desenho anexado', style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted)),
      ],
    ),
  );
}
