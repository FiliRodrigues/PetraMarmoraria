import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/os_status.dart';
import '../../core/theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/os_provider.dart';
import '../../widgets/widgets.dart';

/// The main Dashboard screen displaying the Kanban board for production stages,
/// filters, statistics, and queue integrity checks.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';
  bool _onlyDelayed = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
      });
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
        title: const Text('Painel Kanban de Produção'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar OS',
            onPressed: () => ref.invalidate(osProvider),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Nova Ordem de Serviço',
            onPressed: () => context.push('/orders/new'),
          ),
        ],
      ),
      body: ordersAsync.when(
        data: (orders) {
          // 1. Calculate general stats
          final totalCount = orders.length;
          final orcamentoCount = orders.where((o) => o.status == OSStatus.orcamento).length;
          final producaoCount = orders.where((o) => o.status == OSStatus.corte || o.status == OSStatus.montagem).length;
          final delayedCount = orders.where((o) => o.isDelayed).length;

          // 2. Count staleness levels
          int greenCount = 0;
          int yellowCount = 0;
          int redCount = 0;
          for (var o in orders) {
            if (o.status == OSStatus.entrega) continue; // ignore completed for staleness warning
            if (o.daysStale <= 2) {
              greenCount++;
            } else if (o.daysStale <= 5) {
              yellowCount++;
            } else {
              redCount++;
            }
          }

          // 3. Queue violation check (client-side bypass check)
          final sortedByQueue = List<ServiceOrder>.from(orders)
            ..sort((a, b) => a.queuePosition.compareTo(b.queuePosition));
          
          String? queueViolationMessage;
          for (int i = 0; i < sortedByQueue.length; i++) {
            final orderA = sortedByQueue[i];
            final indexA = OSStatus.indexOf(orderA.status);

            // Ignore orders in initial draft stage or completed
            if (orderA.status == OSStatus.orcamento || orderA.status == OSStatus.entrega) continue;

            for (int j = i + 1; j < sortedByQueue.length; j++) {
              final orderB = sortedByQueue[j];
              final indexB = OSStatus.indexOf(orderB.status);

              if (orderB.status == OSStatus.orcamento || orderB.status == OSStatus.entrega) continue;

              // Violation occurs when orderB (with higher/worse queue position) is in a further stage than orderA
              if (indexB > indexA) {
                queueViolationMessage = 
                    'Alerta de Fila: A OS ${orderB.formattedNumber} furou a fila de prioridades e está na etapa "${orderB.statusLabel}" antes da OS ${orderA.formattedNumber} (que está na etapa "${orderA.statusLabel}").';
                break;
              }
            }
            if (queueViolationMessage != null) break;
          }

          // 4. Apply Filters
          var filteredOrders = orders;
          if (_searchText.isNotEmpty) {
            final query = _searchText.toLowerCase();
            filteredOrders = filteredOrders.where((o) {
              final numMatch = o.formattedNumber.toLowerCase().contains(query) || 
                               o.displayNumber.toString().contains(query);
              final clientMatch = (o.customerName ?? '').toLowerCase().contains(query);
              final materialMatch = (o.material ?? '').toLowerCase().contains(query);
              return numMatch || clientMatch || materialMatch;
            }).toList();
          }

          if (_onlyDelayed) {
            filteredOrders = filteredOrders.where((o) => o.isDelayed).toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Stats Headers Row
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0.0),
                child: Row(
                  children: [
                    _buildStatCard('Total OS', '$totalCount', Icons.list_alt, Colors.blue),
                    _buildStatCard('Orçamentos', '$orcamentoCount', Icons.article_outlined, Colors.amber),
                    _buildStatCard('Em Produção', '$producaoCount', Icons.handyman, Colors.purple),
                    _buildStatCard('Atrasadas (>5d)', '$delayedCount', Icons.warning_amber, AppColors.error),
                  ],
                ),
              ),

              // 2. Queue Violation Banner if exists
              if (queueViolationMessage != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: AppColors.error.withOpacity(0.3), width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Text(
                          queueViolationMessage,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 3. Search and Filters Panel
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Search bar input
                        Expanded(
                          child: TextFormField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Buscar por OS#, cliente ou material...',
                              prefixIcon: Icon(Icons.search),
                              contentPadding: EdgeInsets.symmetric(vertical: 0.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16.0),

                        // Delay count summary & Filter switch
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                _buildColorIndicator(AppColors.success, '<=2 dias', greenCount),
                                const SizedBox(width: 12.0),
                                _buildColorIndicator(AppColors.warning, '3-5 dias', yellowCount),
                                const SizedBox(width: 12.0),
                                _buildColorIndicator(AppColors.error, '>5 dias', redCount),
                              ],
                            ),
                            Row(
                              children: [
                                const Text(
                                  'Apenas Atrasadas (>5 dias):',
                                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                                ),
                                Switch(
                                  value: _onlyDelayed,
                                  activeColor: AppColors.secondary,
                                  onChanged: (val) {
                                    setState(() {
                                      _onlyDelayed = val;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. Kanban Board Area
              Expanded(
                child: filteredOrders.isEmpty
                    ? const EmptyState(
                        title: 'Nenhuma OS encontrada',
                        message: 'Tente alterar os filtros ou crie uma nova OS para começar.',
                        icon: Icons.search_off,
                      )
                    : KanbanBoard(orders: filteredOrders),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Erro ao carregar ordens de serviço: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(osProvider),
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                radius: 20.0,
                child: Icon(icon, color: color, size: 20.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11.0, color: AppColors.grey, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      value,
                      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorIndicator(Color color, String label, int count) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4.0),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 11.0, color: AppColors.grey),
        ),
        Text(
          '$count',
          style: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ],
    );
  }
}
