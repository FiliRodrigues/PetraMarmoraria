import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/os_status.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../models/order_assignment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supabase_provider.dart';
import '../../widgets/widgets.dart';
import 'drawing_viewer_screen.dart';

class _TaskItem {
  final OrderAssignment assignment;
  final int? displayNumber;
  final String? customerName;
  final String? material;
  final String? edgeType;
  final String? description;
  final Map<String, dynamic> measurements;
  final String orderStatus;
  final String? drawingUrl;

  const _TaskItem({
    required this.assignment,
    this.displayNumber,
    this.customerName,
    this.material,
    this.edgeType,
    this.description,
    this.measurements = const {},
    required this.orderStatus,
    this.drawingUrl,
  });

  String get formattedNumber => displayNumber != null
      ? '#${displayNumber.toString().padLeft(4, '0')}'
      : 'OS #...';
}

class WorkerHomeScreen extends ConsumerStatefulWidget {
  const WorkerHomeScreen({super.key});

  @override
  ConsumerState<WorkerHomeScreen> createState() => _WorkerHomeScreenState();
}

class _WorkerHomeScreenState extends ConsumerState<WorkerHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(currentProfileProvider);
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Meu Painel'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.users),
            tooltip: 'Trocar funcionário',
            onPressed: () => _switchWorker(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.key),
            tooltip: 'Trocar PIN',
            onPressed: () => context.push('/meu-painel/trocar-pin'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.logOut),
            tooltip: 'Sair',
            onPressed: () => _logout(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Erro ao carregar perfil')),
        data: (profile) {
          if (profile == null) return const SizedBox.shrink();

          final productionRoles = profile.roles
              .where((r) => AppRoles.productionRoles.contains(r))
              .toList();
          final userId = userAsync.value?.id;

          if (userId == null) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          if (productionRoles.isEmpty) {
            return const EmptyState(
              title: 'Nenhuma função de produção',
              message: 'Você não possui funções de produção atribuídas.',
              icon: LucideIcons.hardHat,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(profile: profile),
                const SizedBox(height: 24),
                for (final role in productionRoles) ...[
                  _StageSection(role: role, userId: userId),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Sair',
      content: 'Deseja realmente sair do sistema?',
    );
    if (confirm && mounted) {
      ref.read(authProvider.notifier).logout();
    }
  }

  Future<void> _switchWorker() async {
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/funcionario');
  }
}

class _Header extends StatelessWidget {
  final dynamic profile;
  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    final primaryRole = profile.roles.isNotEmpty ? profile.roles.first : '';
    final color = AppRoles.roleColor(primaryRole);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.20),
                    AppColors.accent.withValues(alpha: 0.14),
                  ],
                ),
              ),
              child: Text(
                AppRoles.initials(profile.name),
                style: AppTheme.syne(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Olá, ${profile.name.split(' ').first}',
                    style: AppTheme.syne(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: (profile.roles as List<String>).map((role) {
                      final rc = AppRoles.roleColor(role);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: rc.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusFull,
                          ),
                        ),
                        child: Text(
                          AppRoles.roleLabel(role).toUpperCase(),
                          style: AppTheme.jakarta(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: rc,
                          ),
                        ),
                      );
                    }).toList(),
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

class _StageSection extends ConsumerWidget {
  final String role;
  final String userId;
  const _StageSection({required this.role, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stage = AppRoles.roleStage(role);
    if (stage == null) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(role: role),
            const SizedBox(height: 12),
            _StageTasks(stage: stage, userId: userId),
          ],
        ),
      ),
    );
  }
}

final _stageTasksProvider = FutureProvider.family<List<_TaskItem>, (String, String)>((
  ref,
  params,
) async {
  final (stage, userId) = params;
  final client = ref.watch(supabaseClientProvider);

  final assignResponse = await client
      .from('order_assignments')
      .select()
      .eq('employee_id', userId)
      .eq('stage', stage)
      .filter('completed_at', 'is', null)
      .order('assigned_at', ascending: false);

  final rawAssignments = assignResponse as List;
  if (rawAssignments.isEmpty) return [];

  // Deduplica por OS mantendo a atribuição mais recente (assigned_at desc já
  // ordenado acima). Defesa em profundidade junto com o índice único do banco.
  final seenOrders = <String>{};
  final assignments = <OrderAssignment>[];
  for (final e in rawAssignments) {
    final a = OrderAssignment.fromMap(e as Map<String, dynamic>);
    if (seenOrders.add(a.orderId)) assignments.add(a);
  }

  final orderIds = assignments.map((a) => a.orderId).toList();

  final ordersResponse = await client
      .from('service_orders')
      .select(
        'id, customer_id, display_number, status, material, edge_type, description, measurements, drawing_url',
      )
      .inFilter('id', orderIds);

  final ordersMap = <String, Map<String, dynamic>>{};
  for (final o in (ordersResponse as List)) {
    ordersMap[o['id'] as String] = o as Map<String, dynamic>;
  }

  final customerIds = ordersMap.values
      .map((o) => o['customer_id'] as String?)
      .whereType<String>()
      .toSet()
      .toList();

  final customersMap = <String, String>{};
  if (customerIds.isNotEmpty) {
    final custResponse = await client
        .from('customers')
        .select('id, name')
        .inFilter('id', customerIds);
    for (final c in (custResponse as List)) {
      customersMap[c['id'] as String] = c['name'] as String? ?? '';
    }
  }

  return assignments.map((a) {
    final order = ordersMap[a.orderId];
    final customerId = order?['customer_id'] as String?;
    return _TaskItem(
      assignment: a,
      displayNumber: (order?['display_number'] as num?)?.toInt(),
      customerName: customerId != null ? customersMap[customerId] : null,
      material: order?['material'] as String?,
      edgeType: order?['edge_type'] as String?,
      description: order?['description'] as String?,
      measurements:
          (order?['measurements'] as Map?)?.cast<String, dynamic>() ?? const {},
      orderStatus: order?['status'] as String? ?? '',
      drawingUrl: order?['drawing_url'] as String?,
    );
  }).toList();
});

class _StageTasks extends ConsumerWidget {
  final String stage;
  final String userId;
  const _StageTasks({required this.stage, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(_stageTasksProvider((stage, userId)));

    return asyncItems.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (err, _) => Text(
        'Erro ao carregar',
        style: AppTheme.jakarta(fontSize: 12, color: AppColors.error),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'Nenhuma OS pendente',
                style: AppTheme.jakarta(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          );
        }
        return Column(
          children: items.map((item) => _TaskCard(item: item)).toList(),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String role;
  const _SectionHeader({required this.role});

  @override
  Widget build(BuildContext context) {
    final color = AppRoles.roleColor(role);
    final stage = AppRoles.roleStage(role);
    final sectionLabel = stage != null
        ? (OSStatus.labels[stage] ?? stage)
        : role;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          'Para $sectionLabel',
          style: AppTheme.syne(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final _TaskItem item;
  const _TaskCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppRoles.roleColor(
      AppRoles.stageRole(item.assignment.stage) ?? '',
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.formattedNumber,
                        style: AppTheme.numeric(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.customerName ?? 'Cliente não informado',
                        style: AppTheme.jakarta(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showDetail(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      'Detalhes',
                      style: AppTheme.jakarta(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (item.material != null && item.material!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                item.material!,
                style: AppTheme.jakarta(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _markComplete(context, ref),
                icon: const Icon(LucideIcons.checkCheck, size: 16),
                label: const Text('Marcar como concluído'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  textStyle: AppTheme.jakarta(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final measurementLines = _measurementLines(item.measurements);
    final hasMeasurements = measurementLines.isNotEmpty;
    final hasInfo =
        item.customerName != null ||
        (item.material != null && item.material!.isNotEmpty) ||
        (item.edgeType != null && item.edgeType!.isNotEmpty) ||
        (item.description != null && item.description!.isNotEmpty) ||
        hasMeasurements ||
        (item.drawingUrl != null && item.drawingUrl!.isNotEmpty);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('OS ${item.formattedNumber}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.customerName != null)
                _infoRow('Cliente', item.customerName!, bold: true),
              if (item.material != null && item.material!.isNotEmpty)
                _infoRow('Material', item.material!),
              if (item.edgeType != null && item.edgeType!.isNotEmpty)
                _infoRow('Acabamento', item.edgeType!),
              if (item.description != null && item.description!.isNotEmpty)
                _infoRow('Descrição', item.description!),
              if (hasMeasurements) ...[
                const SizedBox(height: 8),
                Text(
                  'Medidas:',
                  style: AppTheme.jakarta(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                ...measurementLines.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text(line, style: AppTheme.jakarta(fontSize: 13)),
                  ),
                ),
              ],
              if (item.drawingUrl != null && item.drawingUrl!.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DrawingViewerScreen(
                            url: item.drawingUrl!,
                            title: 'Desenho — OS ${item.formattedNumber}',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.image, size: 16),
                    label: const Text('Ver desenho'),
                  ),
                ),
              ],
              if (!hasInfo)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nenhuma informação adicional.',
                    style: AppTheme.jakarta(
                      color: AppColors.grey,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: AppTheme.jakarta(fontSize: 13, color: AppColors.textPrimary),
          children: [
            TextSpan(
              text: '$label: ',
              style: AppTheme.jakarta(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: value,
              style: AppTheme.jakarta(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Converte o JSON de medidas (`{ items: [...] }` ou formato plano) em linhas
  /// legíveis por peça. Espelha o parsing de os_detail_screen.dart.
  List<String> _measurementLines(Map<String, dynamic> measurements) {
    final pieces = <Map<String, dynamic>>[];
    if (measurements['items'] is List) {
      for (final it in measurements['items'] as List) {
        if (it is Map) pieces.add(it.cast<String, dynamic>());
      }
    } else if (measurements.isNotEmpty) {
      pieces.add(measurements);
    }

    String? val(Map<String, dynamic> p, String en, String pt) {
      final v = (p[en] ?? p[pt])?.toString().trim();
      return (v == null || v.isEmpty || v == '-') ? null : v;
    }

    final lines = <String>[];
    for (var i = 0; i < pieces.length; i++) {
      final p = pieces[i];
      final width = val(p, 'width', 'largura');
      final height = val(p, 'height', 'altura');
      final thickness = val(p, 'thickness', 'espessura');
      final format = val(p, 'format', 'formato');
      final details = val(p, 'details', 'detalhes');

      final parts = <String>[];
      if (width != null && height != null) {
        parts.add('$width×$height cm');
      } else if (width != null) {
        parts.add('$width cm');
      } else if (height != null) {
        parts.add('$height cm');
      }
      if (thickness != null) parts.add('${thickness}cm esp.');
      if (format != null) parts.add(format);

      final label = 'Peça ${i + 1}';
      lines.add(
        parts.isEmpty
            ? '$label: medidas não informadas'
            : '$label: ${parts.join(' · ')}',
      );
      if (details != null) lines.add('  $details');
    }
    return lines;
  }

  Future<void> _markComplete(BuildContext context, WidgetRef ref) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Concluir etapa',
      content:
          'Confirmar conclusão da etapa "${OSStatus.labels[item.orderStatus] ?? item.orderStatus}" para a ${item.formattedNumber}?',
      confirmLabel: 'Concluir',
      confirmColor: AppColors.success,
    );
    if (!confirm) return;

    final currentUser = ref.read(authProvider).value;
    if (currentUser == null) return;

    final client = ref.read(supabaseClientProvider);

    try {
      // Funcionário apenas conclui sua parte. Quem avança a OS para a próxima
      // etapa (e atribui o próximo responsável) é o escritório/ADM via popup.
      await client
          .from('order_assignments')
          .update({'completed_at': DateTime.now().toIso8601String()})
          .eq('id', item.assignment.id);

      ref.invalidate(_stageTasksProvider);
      if (context.mounted) {
        AppSnackbar.success(
          context,
          'Etapa concluída! Aguardando liberação do escritório.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, e.toString().replaceAll('Exception: ', ''));
      }
    }
  }
}
