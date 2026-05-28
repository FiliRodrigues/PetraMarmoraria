import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../providers/os_provider.dart';
import '../../widgets/widgets.dart';
import '../service_orders/os_list_screen.dart' show SearchField, NewButton;

/// Lista de clientes em grid de cards, replicando o protótipo "Clientes".
class CustomerListScreen extends ConsumerStatefulWidget {
  const CustomerListScreen({super.key});

  @override
  ConsumerState<CustomerListScreen> createState() =>
      _CustomerListScreenState();
}

class _CustomerListScreenState extends ConsumerState<CustomerListScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerProvider);
    final ordersAsync = ref.watch(osProvider);
    final orders = ordersAsync.asData?.value ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recarregar',
            onPressed: () =>
                ref.read(customerProvider.notifier).loadCustomers(),
          ),
        ],
      ),
      body: customersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) =>
            Center(child: Text('Erro ao carregar clientes: $err')),
        data: (customers) {
          final query = _searchText.trim().toLowerCase();
          final filtered = query.isEmpty
              ? customers
              : customers.where((c) {
                  return c.name.toLowerCase().contains(query) ||
                      (c.city ?? '').toLowerCase().contains(query);
                }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ListHeader(
                title: 'Clientes',
                subtitle: '${customers.length} clientes cadastrados',
                searchController: _searchController,
                searchHint: 'Buscar por nome ou cidade...',
                newLabel: 'Novo Cliente',
                onNew: () => context.push('/customers/new'),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                        title: 'Nenhum cliente encontrado',
                        message:
                            'Cadastre um novo cliente ou ajuste sua busca.',
                        icon: Icons.people_outline,
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 320,
                          mainAxisExtent: 168,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final c = filtered[i];
                          final custOrders = orders
                              .where((o) => o.customerId == c.id)
                              .toList();
                          final total = custOrders.fold<double>(
                              0, (s, o) => s + o.totalValue);
                          return _CustomerCard(
                            customer: c,
                            osCount: custOrders.length,
                            totalValue: total,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CustomerCard extends StatefulWidget {
  final Customer customer;
  final int osCount;
  final double totalValue;

  const _CustomerCard({
    required this.customer,
    required this.osCount,
    required this.totalValue,
  });

  @override
  State<_CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends State<_CustomerCard> {
  bool _hover = false;

  String get _initials {
    final parts = widget.customer.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.push('/customers/${c.id}'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hover ? AppColors.accent : AppColors.border,
            ),
            boxShadow: _hover
                ? const [
                    BoxShadow(
                      color: AppColors.shadowElevated,
                      blurRadius: 14,
                      offset: Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(initials: _initials),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.jakarta(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 10, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                [c.city, c.state]
                                    .where((e) =>
                                        e != null && e.toString().isNotEmpty)
                                    .join(' - '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.jakarta(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (c.email != null && c.email!.isNotEmpty)
                _InfoLine(icon: Icons.email_outlined, text: c.email!),
              if (c.phone.isNotEmpty)
                _InfoLine(
                  icon: Icons.phone,
                  text: Formatters.formatPhone(c.phone),
                ),
              const Spacer(),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${widget.osCount}',
                        style: AppTheme.numeric(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'OS',
                        style: AppTheme.jakarta(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    Formatters.formatCurrency(widget.totalValue),
                    style: AppTheme.numeric(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTheme.jakarta(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar quadrado com gradiente navy→âmbar e iniciais.
class _Avatar extends StatelessWidget {
  final String initials;
  final Color? color;
  const _Avatar({required this.initials, this.color});

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.primary;
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(11),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            base.withValues(alpha: 0.16),
            AppColors.accent.withValues(alpha: 0.16),
          ],
        ),
      ),
      child: Text(
        initials,
        style: AppTheme.syne(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: base,
        ),
      ),
    );
  }
}

// ── Cabeçalho de lista compartilhado (título + busca + botão) ────────────────

class _ListHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController searchController;
  final String searchHint;
  final String newLabel;
  final VoidCallback onNew;

  const _ListHeader({
    required this.title,
    required this.subtitle,
    required this.searchController,
    required this.searchHint,
    required this.newLabel,
    required this.onNew,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 560;
          final titleBlock = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTheme.syne(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTheme.jakarta(
                  fontSize: 11.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: SearchField(
                        controller: searchController,
                        hint: searchHint,
                      ),
                    ),
                    const SizedBox(width: 10),
                    NewButton(label: newLabel, onPressed: onNew),
                  ],
                ),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleBlock,
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 240,
                    child: SearchField(
                      controller: searchController,
                      hint: searchHint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  NewButton(label: newLabel, onPressed: onNew),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
