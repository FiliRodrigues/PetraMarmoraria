import 'package:flutter/material.dart';
import '../../core/utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../core/constants/payment_constants.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/whatsapp.dart';
import '../../widgets/widgets.dart';
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
final osDetailDataProvider = FutureProvider.family<OSDetailData, String>((
  ref,
  id,
) async {
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
  } catch (e) {
    debugPrint('[OSDetail] Erro ao carregar assignments: $e');
  }

  // 4. Fetch Status History
  List<StatusHistory> history = [];
  try {
    history = await serviceOrderService.getStatusHistory(id);
  } catch (e) {
    debugPrint('[OSDetail] Erro ao carregar histórico: $e');
  }

  // 5. Fetch Profiles
  List<Profile> profiles = [];
  try {
    profiles = await profileService.getProfiles();
  } catch (e) {
    debugPrint('[OSDetail] Erro ao carregar profiles: $e');
  }

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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await ConfirmDialog.show(
      context,
      title: 'Excluir Ordem de Serviço',
      content:
          'Tem certeza que deseja excluir esta OS? Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmColor: AppColors.error,
    );
    if (!ok) return;
    try {
      await ref.read(serviceOrderServiceProvider).deleteServiceOrder(id);
      ref.invalidate(osProvider);
      if (context.mounted) {
        AppSnackbar.success(context, 'Ordem de serviço excluída.');
        context.pop();
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, friendlyError(e));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailDataAsync = ref.watch(osDetailDataProvider(id));

    // Pré-baixa APENAS o arquivo do desenho em background (só rede, não trava a
    // UI). A geração pesada do PDF só ocorre ao clicar em Visualizar, já partindo
    // do arquivo em cache.
    void warmDrawing(AsyncValue<OSDetailData> v) {
      final url = v.valueOrNull?.order.drawingUrl;
      if (url != null && url.trim().isNotEmpty) {
        ref.read(drawingBytesProvider(url).future).ignore();
      }
    }

    ref.listen(osDetailDataProvider(id), (prev, next) => warmDrawing(next));
    warmDrawing(detailDataAsync);

    final isAdmin = ref.watch(currentProfileProvider).value?.isAdmin ?? false;
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
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Excluir OS',
              onPressed: () => _confirmDelete(context, ref),
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
          if (measurements.containsKey('items') &&
              measurements['items'] is List) {
            final list = measurements['items'] as List;
            for (final item in list) {
              if (item is Map) {
                measurementRows.add({
                  'width': (item['width'] ?? item['largura'] ?? '-').toString(),
                  'height': (item['height'] ?? item['altura'] ?? '-')
                      .toString(),
                  'thickness': (item['thickness'] ?? item['espessura'] ?? '-')
                      .toString(),
                  'format': (item['format'] ?? item['formato'] ?? '-')
                      .toString(),
                  'details': (item['details'] ?? item['detalhes'] ?? '-')
                      .toString(),
                });
              }
            }
          } else {
            final hasKeys =
                measurements.containsKey('width') ||
                measurements.containsKey('largura') ||
                measurements.containsKey('height') ||
                measurements.containsKey('altura') ||
                measurements.containsKey('thickness') ||
                measurements.containsKey('espessura');
            if (hasKeys) {
              measurementRows.add({
                'width':
                    (measurements['width'] ?? measurements['largura'] ?? '-')
                        .toString(),
                'height':
                    (measurements['height'] ?? measurements['altura'] ?? '-')
                        .toString(),
                'thickness':
                    (measurements['thickness'] ??
                            measurements['espessura'] ??
                            '-')
                        .toString(),
                'format':
                    (measurements['format'] ?? measurements['formato'] ?? '-')
                        .toString(),
                'details':
                    (measurements['details'] ?? measurements['detalhes'] ?? '-')
                        .toString(),
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
              orElse: () => Profile(
                id: '',
                email: '',
                name: '',
                createdAt: DateTime(1970, 1, 1),
              ),
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
            if (creatorProfile.name.isNotEmpty &&
                creatorProfile.role.toLowerCase() == 'vendedor') {
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

          final phone2 = customer?.phone2?.trim() ?? '';
          final hasPhone2 = phone2.isNotEmpty;
          final city = customer?.city?.trim() ?? '';
          final uf = customer?.state.trim() ?? '';
          final cidadeUf = (city.isEmpty && uf.isEmpty)
              ? '-'
              : '${city.isEmpty ? "-" : city} / ${uf.isEmpty ? "-" : uf}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Header Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Container(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      border: Border(
                        left: BorderSide(color: AppColors.secondary, width: 4),
                      ),
                    ),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ordem de Serviço ${order.formattedNumber}',
                              style: AppTheme.syne(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusXl,
                                ),
                                border: Border.all(color: AppColors.secondary),
                              ),
                              child: Text(
                                order.statusLabel.toUpperCase(),
                                style: AppTheme.jakarta(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildDetailRow(
                                'Criada em',
                                dateFormat.format(order.createdAt),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'VALOR TOTAL',
                                    style: AppTheme.jakarta(
                                      color: AppColors.textMuted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ).copyWith(letterSpacing: 0.3),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    currencyFormat.format(order.totalValue),
                                    style: AppTheme.numeric(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Customer Details Card
                _buildSectionHeader('DADOS DO CLIENTE', Icons.person),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow(
                          'Nome',
                          customer?.name ??
                              order.customerName ??
                              'Não informado',
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildDetailRow(
                                'Telefone',
                                customer?.phone ?? 'Não informado',
                              ),
                            ),
                            if (hasPhone2)
                              Expanded(
                                child: _buildDetailRow('Telefone 2', phone2),
                              )
                            else
                              Expanded(
                                child: _buildDetailRow('Cidade/UF', cidadeUf),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          'Endereço',
                          customer?.address ?? 'Não informado',
                        ),
                        if (hasPhone2 && cidadeUf != '-') ...[
                          const SizedBox(height: 16),
                          _buildDetailRow('Cidade/UF', cidadeUf),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Service Specifications Card
                _buildSectionHeader('ESPECIFICAÇÕES DO SERVIÇO', Icons.build),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildDetailRow(
                                'Material',
                                order.material ?? 'Não informado',
                              ),
                            ),
                            Expanded(
                              child: _buildDetailRow(
                                'Acabamento',
                                order.edgeType ?? 'Não informado',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'DESCRIÇÃO / OBSERVAÇÕES',
                          style: AppTheme.jakarta(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                            fontSize: 10.5,
                          ).copyWith(letterSpacing: 0.3),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          order.description.isNotEmpty
                              ? order.description
                              : 'Nenhuma observação cadastrada.',
                          style:
                              AppTheme.jakarta(
                                fontSize: 14,
                                color: order.description.isNotEmpty
                                    ? AppColors.textPrimary
                                    : AppColors.textMuted,
                              ).copyWith(
                                height: 1.4,
                                fontStyle: order.description.isNotEmpty
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Measurements Card
                _buildSectionHeader('MEDIÇÕES', Icons.straighten),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: measurementRows.isEmpty
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Nenhuma medição cadastrada.',
                                style: AppTheme.jakarta(color: AppColors.grey),
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 20,
                              columns: [
                                DataColumn(
                                  label: Text(
                                    'Largura (m)',
                                    style: AppTheme.jakarta(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Altura (m)',
                                    style: AppTheme.jakarta(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Espessura (cm)',
                                    style: AppTheme.jakarta(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Formato',
                                    style: AppTheme.jakarta(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'Detalhes',
                                    style: AppTheme.jakarta(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                              rows: measurementRows.map((row) {
                                return DataRow(
                                  cells: [
                                    DataCell(Text(row['width'] ?? '-')),
                                    DataCell(Text(row['height'] ?? '-')),
                                    DataCell(Text(row['thickness'] ?? '-')),
                                    DataCell(Text(row['format'] ?? '-')),
                                    DataCell(Text(row['details'] ?? '-')),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Drawing/Sketch Card
                _buildSectionHeader('DESENHO / ESBOÇO', Icons.image),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child:
                        order.drawingUrl != null &&
                            order.drawingUrl!.trim().isNotEmpty
                        ? _buildAttachmentPreview(order.drawingUrl!)
                        : _buildEmptyAttachment(
                            Icons.architecture,
                            'Nenhum desenho ou esboço anexado',
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Budget Card
                _buildSectionHeader('ORÇAMENTO', Icons.attach_money),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child:
                        order.budgetUrl != null &&
                            order.budgetUrl!.trim().isNotEmpty
                        ? _buildAttachmentPreview(order.budgetUrl!)
                        : _buildEmptyAttachment(
                            Icons.description,
                            'Nenhum orçamento anexado',
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Team Assignments Card
                _buildSectionHeader('EQUIPE RESPONSÁVEL', Icons.people),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      children: [
                        _buildTeamRow('Vendedor', vendedor, Icons.badge),
                        const Divider(
                          height: 26,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                        _buildTeamRow('Cortador', cortador, Icons.content_cut),
                        const Divider(
                          height: 26,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                        _buildTeamRow('Montador', montador, Icons.construction),
                        const Divider(
                          height: 26,
                          thickness: 1,
                          color: AppColors.border,
                        ),
                        _buildTeamRow(
                          'Entregador',
                          entregador,
                          Icons.local_shipping,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Histórico de Movimentação
                _buildSectionHeader(
                  'HISTÓRICO DE MOVIMENTAÇÃO',
                  Icons.timeline,
                ),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: data.history.isEmpty
                        ? Text(
                            'Nenhuma movimentação registrada.',
                            style: AppTheme.jakarta(color: AppColors.textMuted),
                          )
                        : Column(
                            children: [
                              ...data.history.map((h) => _buildHistoryRow(h)),
                            ],
                          ),
                  ),
                ),
                if (data.history.isNotEmpty &&
                    (order.status == OSStatus.entrega ||
                        order.status == OSStatus.entregue)) ...[
                  const SizedBox(height: 8),
                  _buildDeliverySummary(data.history, order),
                ],
                const SizedBox(height: 20),

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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      ),
                    ),
                    icon: const Icon(Icons.print),
                    label: Text(
                      'Visualizar e Imprimir OS',
                      style: AppTheme.syne(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
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
                  friendlyError(err),
                  textAlign: TextAlign.center,
                  style: AppTheme.jakarta(fontSize: 16),
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

  Widget _buildAttachmentPreview(String url) {
    final isPdf = url.toLowerCase().endsWith('.pdf');
    if (isPdf) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf, size: 28, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                url.split('/').last,
                style: AppTheme.jakarta(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => launchUrl(Uri.parse(url)),
              child: const Text('Abrir'),
            ),
          ],
        ),
      );
    }
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, color: Colors.grey, size: 48),
                SizedBox(height: 8),
                Text(
                  'Erro ao carregar imagem',
                  style: AppTheme.jakarta(color: AppColors.grey),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyAttachment(IconData icon, String label) {
    return Container(
      height: 96,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 30),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTheme.jakarta(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(StatusHistory h) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final statusLabel = OSStatus.labels[h.toStatus] ?? h.toStatus;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: AppTheme.jakarta(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${dateFormat.format(h.changedAt)}${h.changedByName != null ? ' • ${h.changedByName}' : ''}',
                  style: AppTheme.jakarta(color: AppColors.grey, fontSize: 11),
                ),
                if (h.notes != null && h.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    h.notes!,
                    style: AppTheme.jakarta(
                      fontSize: 12,
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliverySummary(
    List<StatusHistory> history,
    ServiceOrder order,
  ) {
    if (history.isEmpty) return const SizedBox.shrink();
    final sorted = List<StatusHistory>.from(history)
      ..sort((a, b) => a.changedAt.compareTo(b.changedAt));
    final first = sorted.first;
    final last = sorted.last;
    final totalDays = last.changedAt.difference(first.changedAt).inDays;

    return Card(
      elevation: 1,
      color: AppColors.secondary.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(
              Icons.hourglass_bottom,
              color: AppColors.secondary,
              size: 28,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tempo total: $totalDays ${totalDays == 1 ? 'dia' : 'dias'}',
                  style: AppTheme.syne(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Orçamento → ${OSStatus.labels[last.toStatus] ?? last.toStatus}',
                  style: AppTheme.jakarta(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 2.0, bottom: 10.0, top: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, size: 15, color: AppColors.accent),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppTheme.syne(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ).copyWith(letterSpacing: 0.4),
          ),
        ],
      ),
    );
  }

  /// Campo label (muted) em cima e valor (primary) abaixo, alinhado à esquerda.
  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTheme.jakarta(
            color: AppColors.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ).copyWith(letterSpacing: 0.3),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: AppTheme.jakarta(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ).copyWith(height: 1.25),
        ),
      ],
    );
  }

  Widget _buildTeamRow(String role, String name, IconData icon) {
    final assigned = name != 'Não atribuído';
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, color: AppColors.accent, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                role.toUpperCase(),
                style: AppTheme.jakarta(
                  color: AppColors.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ).copyWith(letterSpacing: 0.3),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style:
                    AppTheme.jakarta(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: assigned
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ).copyWith(
                      fontStyle: assigned ? FontStyle.normal : FontStyle.italic,
                    ),
              ),
            ],
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          ),
        ),
        icon: const Icon(LucideIcons.messageCircle),
        label: Text(
          'Avisar cliente (WhatsApp)',
          style: AppTheme.syne(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        onPressed: hasPhone
            ? () async {
                final message = WhatsApp.messageForOrder(
                  order,
                  customerName: customer?.name,
                );
                final ok = await WhatsApp.open(phone: phone, message: message);
                if (!ok && context.mounted) {
                  AppSnackbar.warning(
                    context,
                    'Não foi possível abrir o WhatsApp.',
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: paymentsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Text(
            friendlyError(err),
            style: AppTheme.jakarta(color: AppColors.error),
          ),
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
                    _financeStat(
                      'Total',
                      currencyFormat.format(order.totalValue),
                      AppColors.primary,
                    ),
                    _financeStat(
                      'Pago',
                      currencyFormat.format(pago),
                      const Color(0xFF1A7A5E),
                    ),
                    _financeStat(
                      'Saldo',
                      currencyFormat.format(saldo),
                      saldo > 0
                          ? const Color(0xFFC0392B)
                          : const Color(0xFF1A7A5E),
                    ),
                  ],
                ),
                const Divider(height: 24),
                if (payments.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'Nenhum pagamento registrado.',
                      style: AppTheme.jakarta(color: AppColors.grey),
                    ),
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
        Text(
          label,
          style: AppTheme.jakarta(
            color: AppColors.grey,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTheme.numeric(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
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
            payment.isPaid
                ? LucideIcons.checkCircle
                : (overdue ? LucideIcons.alertTriangle : LucideIcons.clock),
            size: 16,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${PaymentConstants.methodLabel(payment.method)} · ${PaymentConstants.statusLabel(payment.status)}',
                  style: AppTheme.jakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  payment.notes ??
                      (payment.dueDate != null
                          ? 'Venc. ${AppDateUtils.formatDate(payment.dueDate)}'
                          : '—'),
                  style: AppTheme.jakarta(fontSize: 11, color: AppColors.grey),
                ),
              ],
            ),
          ),
          Text(
            currencyFormat.format(payment.amount),
            style: AppTheme.numeric(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          if (!payment.isPaid)
            TextButton(
              onPressed: () =>
                  ref.read(paymentProvider.notifier).markPaid(payment),
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
  ConsumerState<_RegisterPaymentDialog> createState() =>
      _RegisterPaymentDialogState();
}

class _RegisterPaymentDialogState
    extends ConsumerState<_RegisterPaymentDialog> {
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
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0;
    try {
      await ref
          .read(paymentProvider.notifier)
          .create(
            Payment(
              id: '',
              orderId: widget.order.id,
              amount: amount,
              method: _method,
              status: PaymentConstants.pendente,
              dueDate: _dueDate,
              notes: _notesController.text.trim().isEmpty
                  ? null
                  : _notesController.text.trim(),
              createdAt: DateTime.now(),
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
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
              Text(_error!, style: AppTheme.jakarta(color: AppColors.error)),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Valor'),
              validator: (v) {
                final parsed = double.tryParse((v ?? '').replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return 'Informe um valor maior que zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Método'),
              items: PaymentConstants.methods
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(PaymentConstants.methodLabel(m)),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _method = v ?? PaymentConstants.dinheiro),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dueDate == null
                        ? 'Sem vencimento'
                        : 'Vencimento: ${AppDateUtils.formatDate(_dueDate)}',
                  ),
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
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
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
  ConsumerState<_InstallmentsDialog> createState() =>
      _InstallmentsDialogState();
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
      await ref
          .read(paymentProvider.notifier)
          .createInstallments(
            orderId: widget.order.id,
            totalAmount: widget.order.totalValue,
            count: count,
            firstDueDate: _firstDueDate,
            method: _method,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = friendlyError(e));
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
              Text(_error!, style: AppTheme.jakarta(color: AppColors.error)),
              const SizedBox(height: 12),
            ],
            Text(
              'Total da OS: ${currencyFormat.format(widget.order.totalValue)}',
              style: AppTheme.jakarta(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _countController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Número de parcelas',
              ),
              validator: (v) {
                final parsed = int.tryParse(v ?? '');
                if (parsed == null || parsed < 1) {
                  return 'Informe ao menos 1 parcela';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'Método'),
              items: PaymentConstants.methods
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(PaymentConstants.methodLabel(m)),
                    ),
                  )
                  .toList(),
              onChanged: (v) =>
                  setState(() => _method = v ?? PaymentConstants.dinheiro),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '1º vencimento: ${AppDateUtils.formatDate(_firstDueDate)}',
                  ),
                ),
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
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Gerar'),
        ),
      ],
    );
  }
}
