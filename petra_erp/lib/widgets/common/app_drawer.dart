import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import 'confirm_dialog.dart';
import 'nav_destinations.dart';

class AppDrawer extends ConsumerWidget {
  final bool isSidebar;
  const AppDrawer({super.key, this.isSidebar = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile      = profileAsync.value;
    final isAdmin      = profile?.isAdmin ?? false;
    final company      = ref.watch(companyProvider).value;

    String location = '/';
    try { location = GoRouterState.of(context).matchedLocation; } catch (_) {}

    final body = _DrawerBody(
      profile: profile, isAdmin: isAdmin, isSidebar: isSidebar,
      location: location, ref: ref, context: context,
      companyName: (company?.name.isNotEmpty ?? false) ? company!.name : 'Petra',
      companyLogoUrl: company?.logoUrl,
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
  final String companyName;
  final String? companyLogoUrl;

  const _DrawerBody({
    required this.profile, required this.isAdmin, required this.isSidebar,
    required this.location, required this.ref, required this.context,
    required this.companyName, required this.companyLogoUrl,
  });

  @override
  Widget build(BuildContext ctx) {
    final destinations = navDestinationsFor(isAdmin: isAdmin, isDesktop: isSidebar);
    final items = <Widget>[];
    String? lastSection;
    for (final d in destinations) {
      if (d.section != null && d.section != lastSection) {
        items.add(_sectionLabel(d.section!));
        lastSection = d.section;
      }
      items.add(_item(ctx, d.icon, d.label, d.route, location));
    }

    return Column(
      children: [
        _Header(
          profile: profile, isAdmin: isAdmin,
          companyName: companyName, companyLogoUrl: companyLogoUrl,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            children: items,
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
    final isActive = isRouteActive(loc, route);
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
  final String companyName;
  final String? companyLogoUrl;
  const _Header({
    required this.profile, required this.isAdmin,
    required this.companyName, required this.companyLogoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final name   = profile?.name ?? 'Carregando...';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final hasLogo = companyLogoUrl != null && companyLogoUrl!.isNotEmpty;

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
                  gradient: hasLogo ? null : const LinearGradient(
                    colors: [Color(0xFF0F4C7A), Color(0xFF1464A8)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  color: hasLogo ? Colors.white : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasLogo
                    ? Image.network(companyLogoUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(LucideIcons.gem, color: Colors.white, size: 17))
                    : const Icon(LucideIcons.gem, color: Colors.white, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(companyName,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.syne(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                    Text('Sistema de Gestão',
                      style: AppTheme.jakarta(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.4))),
                  ],
                ),
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
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, Color(0xFFE0A040)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  alignment: Alignment.center,
                  child: Text(initials,
                    style: AppTheme.syne(fontSize: 12.5, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                        style: AppTheme.jakarta(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(isAdmin ? 'ADMIN' : 'MEMBRO',
                          style: AppTheme.jakarta(fontSize: 9, fontWeight: FontWeight.w800,
                            color: AppColors.accentLight)
                            .copyWith(letterSpacing: 0.5)),
                      ),
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
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Stack(
            children: [
              // Indicador lateral do item ativo
              if (widget.isActive)
                Positioned(
                  left: 0, top: 7, bottom: 7,
                  child: Container(
                    width: 3,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(4),
                        bottomRight: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                child: Row(
                  children: [
                    Icon(widget.icon, size: 16, color: color),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.label,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.jakarta(
                          fontSize: 13.5,
                          fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w400,
                          color: color,
                        )),
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
