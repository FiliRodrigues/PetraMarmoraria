import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'confirm_dialog.dart';

class AppDrawer extends ConsumerWidget {
  final bool isSidebar;
  const AppDrawer({super.key, this.isSidebar = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile      = profileAsync.value;
    final isAdmin      = profile?.isAdmin ?? false;

    String location = '/';
    try { location = GoRouterState.of(context).matchedLocation; } catch (_) {}

    final body = _DrawerBody(
      profile: profile, isAdmin: isAdmin, isSidebar: isSidebar,
      location: location, ref: ref, context: context,
    );

    if (isSidebar) {
      return Container(
        width: 240,
        color: AppColors.sidebarDark,
        child: SafeArea(child: body),
      );
    }
    return Drawer(
      backgroundColor: AppColors.sidebarDark,
      child: body,
    );
  }
}

class _DrawerBody extends StatelessWidget {
  final dynamic profile;
  final bool isAdmin;
  final bool isSidebar;
  final String location;
  final WidgetRef ref;
  final BuildContext context;

  const _DrawerBody({
    required this.profile, required this.isAdmin, required this.isSidebar,
    required this.location, required this.ref, required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    return Column(
      children: [
        _Header(profile: profile, isAdmin: isAdmin),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            children: [
              _sectionLabel('PRINCIPAL'),
              _item(ctx, LucideIcons.layoutDashboard, 'Painel Kanban',     '/',          location),
              _item(ctx, LucideIcons.clipboardList,   'Ordens de Serviço', '/orders',    location),
              _sectionLabel('CADASTROS'),
              _item(ctx, LucideIcons.users,           'Clientes',          '/customers', location),
              if (isAdmin)
              _item(ctx, LucideIcons.hardHat,         'Funcionários',      '/employees', location),
              _item(ctx, LucideIcons.package,         'Produtos',          '/products',  location),
              _sectionLabel('ANÁLISE'),
              _item(ctx, LucideIcons.barChart2,       'Relatórios',        '/reports',   location),
              _sectionLabel('CONTA'),
              _item(ctx, LucideIcons.user,            'Meu Perfil',        '/profile',   location),
            ],
          ),
        ),
        _Footer(ref: ref, context: context),
      ],
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 14, 0, 4),
    child: Text(
      label,
      style: AppTheme.jakarta(
        fontSize: 9.5, fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.28),
      ).copyWith(letterSpacing: 1.5),
    ),
  );

  Widget _item(BuildContext ctx, IconData icon, String label, String route, String loc) {
    final isActive = loc == route || (route != '/' && loc.startsWith(route));
    return _NavItem(
      icon: icon, label: label, isActive: isActive,
      onTap: () {
        if (!isSidebar && Scaffold.of(ctx).isDrawerOpen) Navigator.of(ctx).pop();
        ctx.go(route);
      },
    );
  }
}

// ── Header com logo + user ────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final dynamic profile;
  final bool isAdmin;
  const _Header({required this.profile, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final name   = profile?.name ?? 'Carregando...';
    final email  = profile?.email ?? '';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F4C7A), Color(0xFF1464A8)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.gem, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Petra', style: AppTheme.syne(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Sistema de Gestão',
                    style: AppTheme.jakarta(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.4))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          // User chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  alignment: Alignment.center,
                  child: Text(initials,
                    style: AppTheme.syne(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                        style: AppTheme.jakarta(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                      Text(isAdmin ? 'ADMIN' : 'MEMBRO',
                        style: AppTheme.jakarta(fontSize: 9, fontWeight: FontWeight.w800,
                          color: isAdmin ? const Color(0xFF7DD3FC) : AppColors.accent)
                          .copyWith(letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav Item ──────────────────────────────────────────────────────────────────
class _NavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon, required this.label,
    required this.isActive, required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isActive
        ? AppColors.accent.withValues(alpha: 0.17)
        : _hovered ? Colors.white.withValues(alpha: 0.06) : Colors.transparent;
    final color = widget.isActive
        ? AppColors.accent
        : Colors.white.withValues(alpha: 0.7);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 16, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.jakarta(
                    fontSize: 13.5,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w400,
                    color: color,
                  )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  final WidgetRef ref;
  final BuildContext context;
  const _Footer({required this.ref, required this.context});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('v1.0.0',
            style: AppTheme.jakarta(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.22))),
          GestureDetector(
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => const ConfirmDialog(
                  title: 'Confirmar saída',
                  content: 'Deseja realmente sair do sistema?',
                ),
              );
              if (confirm == true) await ref.read(authProvider.notifier).logout();
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.logOut, size: 14, color: AppColors.error),
                const SizedBox(width: 5),
                Text('Sair',
                  style: AppTheme.jakarta(fontSize: 12, fontWeight: FontWeight.w700,
                    color: AppColors.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
