import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Um destino de navegação consumido por sidebar (desktop), navigation rail
/// (tablet) e bottom navigation (mobile).
class NavDestinationItem {
  final IconData icon;
  final String label;
  final String route;
  final String? section;
  final bool adminOnly;

  /// Aparece na barra inferior do mobile / nos itens fixos do rail.
  final bool primary;

  /// Oculto no desktop (ex.: Quadro Kanban — no desktop a Home já é o Kanban).
  final bool hideOnDesktop;

  const NavDestinationItem({
    required this.icon,
    required this.label,
    required this.route,
    this.section,
    this.adminOnly = false,
    this.primary = false,
    this.hideOnDesktop = false,
  });
}

/// Fonte única dos itens de navegação. A ordem define a exibição na sidebar.
const List<NavDestinationItem> kNavDestinations = [
  NavDestinationItem(icon: LucideIcons.layoutDashboard, label: 'Painel',            route: '/',           section: 'PRINCIPAL',  primary: true),
  NavDestinationItem(icon: LucideIcons.trello,          label: 'Quadro Kanban',     route: '/kanban',     section: 'PRINCIPAL',  hideOnDesktop: true),
  NavDestinationItem(icon: LucideIcons.clipboardList,   label: 'Ordens de Serviço', route: '/orders',     section: 'PRINCIPAL',  primary: true),
  NavDestinationItem(icon: LucideIcons.users,           label: 'Clientes',          route: '/customers',  section: 'CADASTROS',  primary: true),
  NavDestinationItem(icon: LucideIcons.hardHat,         label: 'Funcionários',      route: '/employees',  section: 'CADASTROS',  adminOnly: true),
  NavDestinationItem(icon: LucideIcons.package,         label: 'Produtos',          route: '/products',   section: 'CADASTROS'),
  NavDestinationItem(icon: LucideIcons.boxes,           label: 'Estoque',           route: '/estoque',    section: 'ESTOQUE'),
  NavDestinationItem(icon: LucideIcons.wallet,          label: 'Financeiro',        route: '/financeiro', section: 'FINANCEIRO', primary: true, adminOnly: true),
  NavDestinationItem(icon: LucideIcons.barChart2,       label: 'Relatórios',        route: '/reports',    section: 'ANÁLISE'),
  NavDestinationItem(icon: LucideIcons.calendarDays,    label: 'Agenda',            route: '/agenda',     section: 'ANÁLISE'),
  NavDestinationItem(icon: LucideIcons.user,            label: 'Meu Perfil',        route: '/profile',    section: 'CONTA'),
  NavDestinationItem(icon: LucideIcons.settings,        label: 'Configurações',     route: '/configuracoes', section: 'CONTA', adminOnly: true),
];

/// Destinos visíveis para o perfil (filtra admin-only e, no desktop, os ocultos).
List<NavDestinationItem> navDestinationsFor({required bool isAdmin, bool isDesktop = false}) =>
    kNavDestinations
        .where((d) => (!d.adminOnly || isAdmin) && !(isDesktop && d.hideOnDesktop))
        .toList();

/// Os destinos que entram na barra inferior do mobile.
List<NavDestinationItem> primaryDestinationsFor({required bool isAdmin}) =>
    navDestinationsFor(isAdmin: isAdmin).where((d) => d.primary).toList();

/// Verdadeiro se a rota atual corresponde ao destino (mesma regra do drawer).
bool isRouteActive(String location, String route) =>
    location == route || (route != '/' && location.startsWith(route));
