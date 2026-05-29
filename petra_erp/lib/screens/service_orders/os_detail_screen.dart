import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../core/constants/payment_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/whatsapp.dart';
import 'os_print_screen.dart';

/// Container class to hold all data needed to render the Service Order Details.
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

/// Provider that loads all necessary details for the OS Details screen.
final osDetailDataProvider = FutureProvider.family<OSDetailData, String>((ref, id) async {
  final serviceOrderService = ref.watch(serviceOrderServiceProvider);
  final customerService = ref.watch(customerServiceProvider);
  final profileService = ref.watch(profileServiceProvider);

  // 1. Fetch OS details
  final order = await serviceOrderService.getServiceOrderById(id);

  // 2. Fetch Customer details (if customerId exists)
  Customer? customer;
  try {
    customer = await customerService.getCustomerById(order.customerId);
  } catch (_) {
    // Fail silently if customer details fail to load
  }

  // 3. Fetch Assignments
  List<OrderAssignment> assignments = [];
  try {
    assignments = await serviceOrderService.getAssignments(id);
  } catch (_) {}

  // 4. Fetch Status History
  List<StatusHistory> history = [];
  try {
    history = await serviceOrderService.getStatusHistory(id);
  } catch (_) {}

  // 5. Fetch Profiles
  List<Profile> profiles = [];
  try {
    profiles = await profileService.getProfiles();
  } catch (_) {}

  return OSDetailData(
    order: order,
    customer: customer,
    assignments: assignments,
    history: history,
    profiles: profiles,
  );
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
        title: detailDataAsync.maybeWhen(
          data: (data) => Text('OS ${data.order.formattedNumber}'),
          orElse: () => const Text('Detalhes da OS'),
        ),
        actions: [
          detailDataAsync.maybeWhen(
            data: (data) => IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Imprimir OS',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => OSPrintScreen(id: id),
                  ),
                );
              },
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      body: detailDataAsync.when(
        data: (data) {
          final order = data.order;
          final customer = data.customer;
          
          // Parse measurements
          final List<Map<String, String>> measurementRows = [];
          final measurements = order.measurements;
          if (measurements.containsKey('items') && measurements['items'] is List) {
            final list = measurements['items'] as List;
            for (final item in list) {
              if (item is Map) {
                measurementRows.add({
                  'width': (item['width'] ?? item['largura'] ?? '-').toString(),
                  'height': (item['height'] ?? item['altura'] ?? '-').toString(),
                  'thickness': (item['thickness'] ?? item['espessura'] ?? '-').toString(),
                  'format': (item['format'] ?? item['formato'] ?? '-').toString(),
                  'details': (item['details'] ?? item['detalhes'] ?? '-').toString(),
                });
              }
            }
          } else {
            final hasKeys = measurements.containsKey('width') ||
                measurements.containsKey('largura') ||
                measurements.containsKey('height') ||
                measurements.containsKey('altura') ||
                measurements.containsKey('thickness') ||
                measurements.containsKey('espessura');
            if (hasKeys) {
              measurementRows.add({
                'width': (measurements['width'] ?? measurements['largura'] ?? '-').toString(),
                'height': (measurements['height'] ?? measurements['altura'] ?? '-').toString(),
                'thickness': (measurements['thickness'] ?? measurements['espessura'] ?? '-').toString(),
                'format': (measurements['format'] ?? measurements['formato'] ?? '-').toString(),
                'details': (measurements['details'] ?? measurements['detalhes'] ?? '-').toString(),
              });
            }
          }

          // Resolve team members
          String vendedor = 'Não atribuído';
          String cortador = 'Não atribuído';
          String montador = 'Não atribuído';
          String entregador = 'Não atribuído';

          for (final assignment in data.assignments) {
            final name = assignment.employeeName ?? 'Atribuído';
            if (assignment.stage == 'corte') {
              cortador = name;
            } else if (assignment.stage == 'montagem') {
              montador = name;
            } else if (assignment.stage == 'entrega') {
              entregador = name;
            }
          }

          // Vendedor responsável: prioriza created_by (novo campo); cai na
          // heurística antiga (histórico/perfil) apenas para OS legadas.
          if (order.createdByName != null && order.createdByName!.isNotEmpty) {
            vendedor = order.createdByName!;
          } else if (order.createdBy != null) {
            final creator = data.profiles.firstWhere(
              (p) => p.id == order.createdBy,
              orElse: () => Profile(id: '', email: '', name: '', createdAt: DateTime(1970, 1, 1)),
            );
            if (creator.name.isNotEmpty) vendedor = creator.name;
          }

          if (vendedor == 'Não atribuído' && data.history.isNotEmpty) {
            final sortedHistory = List<StatusHistory>.from(data.history)
              ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
            final firstEntry = sortedHistory.first;
            final creatorProfile = data.profiles.firstWhere(
              (p) => p.id == firstEntry.changedBy,
              orElse: () => Profile(
                id: '',
                email: '',
                name: '',
                createdAt: DateTime(1970, 1, 1),
              ),
            );
            if (creatorProfile.name.isNotEmpty && creatorProfile.role.toLowerCase() == 'vendedor') {
              vendedor = creatorProfile.name;
            } else if (firstEntry.changedByName != null) {
              vendedor = firstEntry.changedByName!;
            }
          }

          if (vendedor == 'Não atribuído') {
            final sellerProfile = data.profiles.firstWhere(
              (p) => p.role.toLowerCase() == 'vendedor',
              orElse: () => Profile(
                id: '',
                email: '',
                name: '',
                createdAt: DateTime(1970, 1, 1),
              ),
            );
            if (sellerProfile.name.isNotEmpty) {
              vendedor = sellerProfile.name;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Header Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: AppColors.secondary, width: 4),
                      ),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Ordem de Serviço ${order.formattedNumber}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.secondary),
                              ),
                              child: Text(
                                order.statusLabel.toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Criada em', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(dateFormat.format(order.createdAt), style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Text('Valor Total', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  currencyFormat.format(order.totalValue),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Customer Details Card
                _buildSectionHeader('DADOS DO CLIENTE', Icons.person),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Nome', customer?.name ?? order.customerName ?? 'Não informado'),
                        const SizedBox(height: 12),
                        _buildDetailRow('Telefone', customer?.phone ?? 'Não informado'),
                        if (customer?.phone2 != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow('Telefone 2', customer!.phone2!),
                        ],
                        const SizedBox(height: 12),
                        _buildDetailRow('Endereço', customer?.address ?? 'Não informado'),
                        if (customer?.city != null || customer?.state != null) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow('Cidade/UF', '${customer?.city ?? "-"} / ${customer?.state ?? "-"}'),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Service Specifications Card
                _buildSectionHeader('ESPECIFICAÇÕES DO SERVIÇO', Icons.build),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildDetailRow('Material', order.material ?? 'Não informado')),
                            Expanded(child: _buildDetailRow('Acabamento', order.edgeType ?? 'Não informado')),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Descrição / Observações:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.description.isNotEmpty ? order.description : 'Nenhuma observação cadastrada.',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Measurements Card
                _buildSectionHeader('MEDIÇÕES', Icons.straighten),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: measurementRows.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Nenhuma medição cadastrada.', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 20,
                              columns: const [
                                DataColumn(label: Text('Largura (m)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Altura (m)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Espessura (cm)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Formato', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Detalhes', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: measurementRows.map((row) {
                                return DataRow(cells: [
                                  DataCell(Text(row['width'] ?? '-')),
                                  DataCell(Text(row['height'] ?? '-')),
                                  DataCell(Text(row['thickness'] ?? '-')),
                                  DataCell(Text(row['format'] ?? '-')),
                                  DataCell(Text(row['details'] ?? '-')),
                                ]);
                              }).toList(),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Drawing/Sketch Card
                _buildSectionHeader('DESENHO / ESBOÇO', Icons.image),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: order.drawingUrl != null && order.drawingUrl!.trim().isNotEmpty
                        ? Container(
                            height: 200,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Image.network(
                              order.drawingUrl!,
                              fit: BoxFit.contain,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image, color: Colors.grey, size: 48),
                                      SizedBox(height: 8),
                                      Text('Erro ao carregar imagem do desenho', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )
                        : Container(
                            height: 100,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!, style: BorderStyle.none),
                            ),
                            alignment: Alignment.center,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.architecture, color: Colors.grey, size: 36),
                                SizedBox(height: 8),
                                Text('Nenhum desenho ou esboço anexado', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Team Assignments Card
                _buildSectionHeader('EQUIPE RESPONSÁVEL', Icons.people),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildTeamRow('Vendedor', vendedor, Icons.badge),
                        const Divider(height: 24),
                        _buildTeamRow('Cortador', cortador, Icons.content_cut),
                        const Divider(height: 24),
                        _buildTeamRow('Montador', montador, Icons.construction),
                        const Divider(height: 24),
                        _buildTeamRow('Entregador', entregador, Icons.local_shipping),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Financeiro
                _buildSectionHeader('FINANCEIRO', Icons.payments),
                _FinanceSection(order: order),
                const SizedBox(height: 24),

                // Avisar cliente por WhatsApp
                _WhatsAppButton(order: order, customer: customer),
                const SizedBox(height: 12),

                // Direct Action Print Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.print),
                    label: const Text('Visualizar e Imprimir OS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => OSPrintScreen(id: id),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando detalhes da OS...'),
            ],
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar detalhes:\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(osDetailDataProvider(id)),
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamRow(String role, String name, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 20),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Botão "Avisar cliente (WhatsApp)". Desabilita quando não há telefone.
class _WhatsAppButton extends StatelessWidget {
  final ServiceOrder order;
  final Customer? customer;
  const _WhatsAppButton({required this.order, required this.customer});

  static const _whatsappGreen = Color(0xFF25D366);

  @override
  Widget build(BuildContext context) {
    final phone = customer?.phone ?? '';
    final hasPhone = phone.trim().isNotEmpty;

    final button = SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: hasPhone ? _whatsappGreen : Colors.grey.shade400,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: const Icon(LucideIcons.messageCircle),
        label: const Text('Avisar cliente (WhatsApp)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        onPressed: hasPhone
            ? () async {
                final message = WhatsApp.messageForOrder(order, customerName: customer?.name);
                final ok = await WhatsApp.open(phone: phone, message: message);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
                  );
                }
              }
            : null,
      ),
    );

    if (hasPhone) return button;
    return Tooltip(
      message: 'Cadastre o telefone do cliente para avisar pelo WhatsApp',
      child: button,
    );
  }
}

/// Seção "Financeiro" do detalhe: total/pago/saldo + lista de pagamentos da OS,
/// com ações de registrar pagamento, gerar parcelas e marcar como pago.
class _FinanceSection extends ConsumerWidget {
  final ServiceOrder order;
  const _FinanceSection({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(orderPaymentsProvider(order.id));
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: paymentsAsync.when(
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
          ),
          error: (err, _) => Text('Erro ao carregar pagamentos: $err',
              style: const TextStyle(color: Colors.red)),
          data: (payments) {
            final pago = payments
                .where((p) => p.isPaid)
                .fold<double>(0, (s, p) => s + p.amount);
            final saldo = order.totalValue - pago;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _financeStat('Total', currencyFormat.format(order.totalValue), AppColors.primary),
                    _financeStat('Pago', currencyFormat.format(pago), const Color(0xFF1A7A5E)),
                    _financeStat('Saldo', currencyFormat.format(saldo),
                        saldo > 0 ? const Color(0xFFC0392B) : const Color(0xFF1A7A5E)),
                  ],
                ),
                const Divider(height: 24),
                if (payments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nenhum pagamento registrado.',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...payments.map((p) => _PaymentRow(payment: p)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: const Text('Registrar pagamento'),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _RegisterPaymentDialog(order: order),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(LucideIcons.layers, size: 16),
                        label: const Text('Gerar parcelas'),
                        onPressed: () => showDialog<void>(
                          context: context,
                          builder: (_) => _InstallmentsDialog(order: order),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _financeStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class _PaymentRow extends ConsumerWidget {
  final Payment payment;
  const _PaymentRow({required this.payment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final overdue = payment.isOverdue;
    final color = payment.isPaid
        ? const Color(0xFF1A7A5E)
        : (overdue ? const Color(0xFFC0392B) : AppColors.primary);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            payment.isPaid ? LucideIcons.checkCircle : (overdue ? LucideIcons.alertTriangle : LucideIcons.clock),
            size: 16, color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${PaymentConstants.methodLabel(payment.method)} · ${PaymentConstants.statusLabel(payment.status)}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  payment.notes ??
                      (payment.dueDate != null ? 'Venc. ${AppDateUtils.formatDate(payment.dueDate)}' : '—'),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(currencyFormat.format(payment.amount),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          if (!payment.isPaid)
            TextButton(
              onPressed: () => ref.read(paymentProvider.notifier).markPaid(payment),
              child: const Text('Marcar pago'),
            ),
        ],
      ),
    );
  }
}

class _RegisterPaymentDialog extends ConsumerStatefulWidget {
  final ServiceOrder order;
  const _RegisterPaymentDialog({required this.order});

  @override
  ConsumerState<_RegisterPaymentDialog> createState() => _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState extends ConsumerState<_RegisterPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String _method = PaymentConstants.dinheiro;
  DateTime? _dueDate;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    try {
      await ref.read(paymentProvider.notifier).create(
            Payment(
              id: '',
              orderId: widget.order.id,
              amount: amount,
              method: _method,
              status: PaymentConstants.pendente,
              dueDate: _dueDate,
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              createdAt: DateTime.now(),
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erro ao registrar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Registrar pagamento'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor'),
              validator: (v) {
                final parsed = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) return 'Informe um valor maior que zero';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Método'),
              items: PaymentConstants.methods
                  .map((m) => DropdownMenuItem(value: m, child: Text(PaymentConstants.methodLabel(m))))
                  .toList(),
              onChanged: (v) => setState(() => _method = v ?? PaymentConstants.dinheiro),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(_dueDate == null
                      ? 'Sem vencimento'
                      : 'Vencimento: ${AppDateUtils.formatDate(_dueDate)}'),
                ),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _dueDate = picked);
                  },
                  child: const Text('Definir data'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notas (opcional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Registrar'),
        ),
      ],
    );
  }
}

class _InstallmentsDialog extends ConsumerStatefulWidget {
  final ServiceOrder order;
  const _InstallmentsDialog({required this.order});

  @override
  ConsumerState<_InstallmentsDialog> createState() => _InstallmentsDialogState();
}

class _InstallmentsDialogState extends ConsumerState<_InstallmentsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _countController = TextEditingController(text: '2');
  String _method = PaymentConstants.dinheiro;
  DateTime _firstDueDate = DateTime.now();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _countController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final count = int.tryParse(_countController.text) ?? 0;
    try {
      await ref.read(paymentProvider.notifier).createInstallments(
            orderId: widget.order.id,
            totalAmount: widget.order.totalValue,
            count: count,
            firstDueDate: _firstDueDate,
            method: _method,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Erro ao gerar parcelas: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.simpleCurrency(locale: 'pt_BR');
    return AlertDialog(
      title: const Text('Gerar parcelas'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 12),
            ],
            Text('Total da OS: ${currencyFormat.format(widget.order.totalValue)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Número de parcelas'),
              validator: (v) {
                final parsed = int.tryParse(v ?? '');
                if (parsed == null || parsed < 1) return 'Informe ao menos 1 parcela';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Método'),
              items: PaymentConstants.methods
                  .map((m) => DropdownMenuItem(value: m, child: Text(PaymentConstants.methodLabel(m))))
                  .toList(),
              onChanged: (v) => setState(() => _method = v ?? PaymentConstants.dinheiro),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: Text('1º vencimento: ${AppDateUtils.formatDate(_firstDueDate)}')),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _firstDueDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => _firstDueDate = picked);
                  },
                  child: const Text('Definir data'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Gerar'),
        ),
      ],
    );
  }
}
