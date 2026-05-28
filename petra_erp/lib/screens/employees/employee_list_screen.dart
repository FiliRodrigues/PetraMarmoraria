import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/widgets.dart';
import '../service_orders/os_list_screen.dart' show SearchField, NewButton;

/// Cor associada a cada cargo (papel) de funcionário.
Color _roleColor(String role) {
  switch (role.toLowerCase()) {
    case 'admin':
      return const Color(0xFF0A3D62);
    case 'vendedor':
      return const Color(0xFFC0802A);
    case 'cortador':
      return const Color(0xFF6058D0);
    case 'montador':
      return const Color(0xFF0D8B7E);
    case 'entregador':
      return const Color(0xFF1A7A5E);
    default:
      return AppColors.textMuted;
  }
}

const Map<String, String> _roleLabels = {
  'admin': 'Admin',
  'vendedor': 'Vendedor',
  'cortador': 'Cortador',
  'montador': 'Montador',
  'entregador': 'Entregador',
};

/// Lista de funcionários em grid de cards, com filtro por cargo.
class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() =>
      _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';
  String? _roleFilter; // null = Todos

  static const List<String> _roles = [
    'admin',
    'vendedor',
    'cortador',
    'montador',
    'entregador',
  ];

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
    final currentProfileAsync = ref.watch(currentProfileProvider);

    return currentProfileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) =>
          Scaffold(body: Center(child: Text('Erro ao validar acesso: $err'))),
      data: (profile) {
        if (profile == null || !profile.isAdmin) {
          return const Scaffold(
            body: EmptyState(
              title: 'Acesso Negado',
              message:
                  'Você não possui privilégios de Administrador para acessar esta área.',
              icon: Icons.lock_outline,
            ),
          );
        }

        final employeesAsync = ref.watch(employeeProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Funcionários'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Recarregar',
                onPressed: () =>
                    ref.read(employeeProvider.notifier).loadEmployees(),
              ),
            ],
          ),
          body: employeesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
                child: Text('Erro ao carregar funcionários: $err')),
            data: (employees) {
              final query = _searchText.trim().toLowerCase();
              final filtered = employees.where((e) {
                final matchesQuery = query.isEmpty ||
                    e.name.toLowerCase().contains(query) ||
                    e.email.toLowerCase().contains(query) ||
                    e.role.toLowerCase().contains(query);
                final matchesRole =
                    _roleFilter == null || e.hasRole(_roleFilter!);
                return matchesQuery && matchesRole;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _EmployeeHeader(
                    subtitle: '${employees.length} funcionários cadastrados',
                    searchController: _searchController,
                    onNew: () => context.push('/employees/new'),
                  ),
                  _RoleChips(
                    roles: _roles,
                    selected: _roleFilter,
                    onSelect: (r) => setState(() => _roleFilter = r),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: filtered.isEmpty
                        ? const EmptyState(
                            title: 'Nenhum funcionário encontrado',
                            message:
                                'Ajuste os filtros ou cadastre um novo funcionário.',
                            icon: Icons.people_alt_outlined,
                          )
                        : GridView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(20, 4, 20, 24),
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 320,
                              mainAxisExtent: 162,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) =>
                                _EmployeeCard(profile: filtered[i]),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _EmployeeCard extends StatefulWidget {
  final Profile profile;
  const _EmployeeCard({required this.profile});

  @override
  State<_EmployeeCard> createState() => _EmployeeCardState();
}

class _EmployeeCardState extends State<_EmployeeCard> {
  bool _hover = false;

  String get _initials {
    final parts = widget.profile.name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.profile;
    final role = e.role;
    final color = _roleColor(role);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: () => context.push('/employees/${e.id}/edit'),
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
                  _RoleAvatar(initials: _initials, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.jakarta(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        _RoleBadge(role: role, color: color),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_outlined,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
              const SizedBox(height: 14),
              _EmpInfoLine(icon: Icons.email_outlined, text: e.email),
              if (e.phone != null && e.phone!.isNotEmpty)
                _EmpInfoLine(
                  icon: Icons.phone,
                  text: Formatters.formatPhone(e.phone!),
                ),
              const Spacer(),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: e.active ? AppColors.success : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    e.active ? 'Ativo' : 'Inativo',
                    style: AppTheme.jakarta(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color:
                          e.active ? AppColors.success : AppColors.error,
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

class _RoleBadge extends StatelessWidget {
  final String role;
  final Color color;
  const _RoleBadge({required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    final label = (_roleLabels[role.toLowerCase()] ?? role).toUpperCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: AppTheme.jakarta(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _RoleAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  const _RoleAvatar({required this.initials, required this.color});

  @override
  Widget build(BuildContext context) {
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
            color.withValues(alpha: 0.20),
            AppColors.accent.withValues(alpha: 0.14),
          ],
        ),
      ),
      child: Text(
        initials,
        style: AppTheme.syne(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _EmpInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmpInfoLine({required this.icon, required this.text});

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

class _RoleChips extends StatelessWidget {
  final List<String> roles;
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _RoleChips({
    required this.roles,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _Chip(
            label: 'Todos',
            color: AppColors.primary,
            active: selected == null,
            onTap: () => onSelect(null),
          ),
          for (final r in roles)
            _Chip(
              label: _roleLabels[r] ?? r,
              color: _roleColor(r),
              active: selected == r,
              onTap: () => onSelect(r),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.12) : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: active ? color : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTheme.jakarta(
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              color: active ? color : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmployeeHeader extends StatelessWidget {
  final String subtitle;
  final TextEditingController searchController;
  final VoidCallback onNew;

  const _EmployeeHeader({
    required this.subtitle,
    required this.searchController,
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
                'Funcionários',
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
                        hint: 'Buscar por nome ou e-mail...',
                      ),
                    ),
                    const SizedBox(width: 10),
                    NewButton(label: 'Novo Funcionário', onPressed: onNew),
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
                      hint: 'Buscar por nome ou e-mail...',
                    ),
                  ),
                  const SizedBox(width: 10),
                  NewButton(label: 'Novo Funcionário', onPressed: onNew),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
