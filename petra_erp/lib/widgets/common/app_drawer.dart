import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    final isAdmin      = profile?.hasRole('admin') ?? false;

    String location = '/';
    try { location = GoRouterState.of(context).matchedLocation; } catch (_) {}

    final body = _DrawerBody(
      profile: profile, isAdmin: isAdmin,
      location: location, ref: ref, context: context,
      isSidebar: isSidebar,
    );

    if (isSidebar) {
      return Container(
        width: 260,
        decoration: const BoxDecoration(
          color: AppColors.sidebarDark,
          border: Border(
            right: BorderSide(color: Color(0x0FFFFFFF), width: 1),
          ),
        ),
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
  final String location;
  final WidgetRef ref;
  final BuildContext context;
  final bool isSidebar;

  const _DrawerBody({
    required this.profile, required this.isAdmin,
    required this.location, required this.ref, required this.context,
    this.isSidebar = false,
  });

  @override
  Widget build(BuildContext ctx) {
    return Column(
      children: [
        _Header(profile: profile, isAdmin: isAdmin),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            children: [
              _sectionLabel('PRINCIPAL'),
              _item(ctx, LucideIcons.layoutDashboard, 'Painel Kanban',     '/',          location),
              _item(ctx, LucideIcons.clipboardList,   'Ordens de Serviço', '/orders',    location),
              _sectionLabel('CADASTROS'),
              _item(ctx, LucideIcons.users,           'Clientes',          '/customers', location),
              _item(ctx, LucideIcons.truck,           'Fornecedores',      '/suppliers', location),
              if (isAdmin)
              _item(ctx, LucideIcons.hardHat,         'Funcionários',      '/employees', location),
              _item(ctx, LucideIcons.package,         'Produtos',          '/products',  location),
              _sectionLabel('FINANCEIRO'),
              _item(ctx, LucideIcons.wallet,          'Financeiro',        '/finance',   location),
              _sectionLabel('ANÁLISE'),
              _item(ctx, LucideIcons.barChart2,       'Relatórios',        '/reports',   location),
              _sectionLabel('CONTA'),
              _item(ctx, LucideIcons.user,            'Meu Perfil',        '/profile',   location),
              _sectionLabel('SISTEMA'),
              _item(ctx, LucideIcons.settings,       'Configurações',     '/settings',  location),
            ],
          ),
        ),
        _Footer(ref: ref, context: context),
      ],
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 0, 4),
    child: Text(
      label,
      style: AppTheme.syne(
        fontSize: 10, fontWeight: FontWeight.w700,
        color: Colors.white.withOpacity(0.25),
      ).copyWith(letterSpacing: 0.8),
    ),
  );

  Widget _item(BuildContext ctx, IconData icon, String label, String route, String loc) {
    final isActive = loc == route || (route != '/' && loc.startsWith(route));
    return _NavItem(
      icon: icon, label: label, isActive: isActive,
      onTap: () {
        if (!isSidebar && Scaffold.of(ctx).isDrawerOpen) Navigator.of(ctx).pop();
        ctx.push(route);
      },
    );
  }
}

// ── Header com logo ───────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final dynamic profile;
  final bool isAdmin;
  const _Header({required this.profile, required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A3A5C), Color(0xFF0D2B45)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1),
            ),
            child: const Icon(LucideIcons.gem, color: AppColors.accent, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PETRA',
                style: AppTheme.syne(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              Text('ERP',
                style: AppTheme.jakarta(fontSize: 11, color: Colors.white.withOpacity(0.4))),
            ],
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
        ? AppColors.sidebarItemActiveBg
        : _hovered ? AppColors.sidebarItemHoverBg : Colors.transparent;
    final iconColor = widget.isActive
        ? AppColors.accent
        : Colors.white.withOpacity(0.5);
    final labelColor = widget.isActive
        ? const Color(0xFFF5E9C8)
        : Colors.white.withOpacity(0.65);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusXl),
            border: widget.isActive
                ? Border.all(color: AppColors.sidebarItemActiveBorder, width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(widget.icon, size: 18, color: iconColor),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.label,
                  style: AppTheme.jakarta(
                    fontSize: 14,
                    fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                    color: labelColor,
                  )),
              ),
              if (widget.isActive)
                Container(
                  width: 3, height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionText extends StatefulWidget {
  @override
  State<_VersionText> createState() => _VersionTextState();
}

class _VersionTextState extends State<_VersionText> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = 'v${info.version}');
    } catch (_) {
      if (mounted) setState(() => _version = 'v1.0.0');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _version,
      style: AppTheme.jakarta(fontSize: 10.5, color: Colors.white.withOpacity(0.22)),
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
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0x0FFFFFFF))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _VersionText(),
          GestureDetector(
            onTap: () async {
              final confirm = await ConfirmDialog.show(context,
                title: 'Confirmar saída',
                content: 'Deseja realmente sair do sistema?',
              );
              if (confirm) await ref.read(authProvider.notifier).logout();
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
