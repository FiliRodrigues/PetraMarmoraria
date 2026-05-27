import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../core/theme/app_colors.dart';
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
        title: Text('OS $id'.substring(0, id.length > 8 ? 8 : id.length)),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
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
      backgroundColor: Colors.grey[100],
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

          if (data.history.isNotEmpty) {
            final sortedHistory = List<StatusHistory>.from(data.history)
              ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
            final firstEntry = sortedHistory.first;
            final creatorProfile = data.profiles.firstWhere(
              (p) => p.id == firstEntry.changedBy,
              orElse: () => Profile(
                id: '',
                email: '',
                name: '',
                role: '',
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
                role: '',
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                                color: AppColors.secondary.withOpacity(0.15),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                const SizedBox(height: 24),

                // Direct Action Print Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
