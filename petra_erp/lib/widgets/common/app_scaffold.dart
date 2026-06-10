import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
import 'app_drawer.dart';
import 'nav_destinations.dart';

/// Shell responsivo da aplicação:
/// - Desktop (>=900): sidebar permanente.
/// - Tablet (600–899): navigation rail + botão "Mais" (abre o drawer).
/// - Mobile (<600): app bar + drawer ("Mais") + bottom navigation.
class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) return _DesktopShell(child: child);
    if (context.isTablet) return _TabletShell(child: child);
    return _MobileShell(child: child);
  }
}

// ── Desktop ───────────────────────────────────────────────────────────────────
class _DesktopShell extends StatelessWidget {
  final Widget child;
  const _DesktopShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SizedBox(width: 280.0, child: AppDrawer(isSidebar: true)),
          const VerticalDivider(
            width: 1.0,
            thickness: 1.0,
            color: Colors.black12,
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

// ── Tablet: navigation rail ─────────────────────────────────────────────────────
class _TabletShell extends ConsumerStatefulWidget {
  final Widget child;
  const _TabletShell({required this.child});

  @override
  ConsumerState<_TabletShell> createState() => _TabletShellState();
}

class _TabletShellState extends ConsumerState<_TabletShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(currentProfileProvider).value?.isAdmin ?? false;
    final destinations = primaryDestinationsFor(isAdmin: isAdmin);

    String location = '/';
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) { /* GoRouterState.of pode falhar antes do primeiro build */ }

    final selected = destinations.indexWhere(
      (d) => isRouteActive(location, d.route),
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      body: Row(
        children: [
          NavigationRail(
            backgroundColor: AppColors.sidebarDark,
            selectedIndex: selected >= 0 ? selected : null,
            labelType: NavigationRailLabelType.all,
            groupAlignment: -0.9,
            indicatorColor: AppColors.accent.withValues(alpha: 0.17),
            selectedIconTheme: const IconThemeData(
              color: AppColors.accent,
              size: 22,
            ),
            unselectedIconTheme: IconThemeData(
              color: Colors.white.withValues(alpha: 0.7),
              size: 20,
            ),
            selectedLabelTextStyle: AppTheme.jakarta(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelTextStyle: AppTheme.jakarta(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            onDestinationSelected: (i) => context.go(destinations[i].route),
            leading: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: IconButton(
                icon: const Icon(
                  LucideIcons.menu,
                  color: Colors.white,
                  size: 22,
                ),
                tooltip: 'Mais',
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            ),
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label.split(' ').first),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1, color: Colors.black12),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

// ── Mobile: bottom navigation ───────────────────────────────────────────────────
class _MobileShell extends ConsumerStatefulWidget {
  final Widget child;
  const _MobileShell({required this.child});

  @override
  ConsumerState<_MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends ConsumerState<_MobileShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(currentProfileProvider).value?.isAdmin ?? false;
    final company = ref.watch(companyProvider).value;
    final destinations = primaryDestinationsFor(isAdmin: isAdmin);

    String location = '/';
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) { /* GoRouterState.of pode falhar antes do primeiro build */ }

    final activeIndex = destinations.indexWhere(
      (d) => isRouteActive(location, d.route),
    );
    // "Mais" é o último destino; quando a rota não é principal, ele fica selecionado.
    final moreIndex = destinations.length;
    final selectedIndex = activeIndex >= 0 ? activeIndex : moreIndex;

    final title = activeIndex >= 0
        ? destinations[activeIndex].label
        : ((company?.name.isNotEmpty ?? false) ? company!.name : 'Petra ERP');

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Text(title)),
      drawer: const AppDrawer(),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          if (i == moreIndex) {
            _scaffoldKey.currentState?.openDrawer();
          } else {
            context.go(destinations[i].route);
          }
        },
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              label: d.label.split(' ').first,
            ),
          const NavigationDestination(
            icon: Icon(LucideIcons.menu),
            label: 'Mais',
          ),
        ],
      ),
    );
  }
}
