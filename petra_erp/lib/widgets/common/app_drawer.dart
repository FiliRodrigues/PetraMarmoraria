import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  final bool isSidebar;

  const AppDrawer({super.key, this.isSidebar = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final profile = profileAsync.value;
    final isAdmin = profile?.role == 'admin';

    String location = '/';
    try {
      location = GoRouterState.of(context).matchedLocation;
    } catch (_) {
    }

    final body = _buildBody(context, profile, isAdmin, location, ref);

    if (isSidebar) {
      return Container(
        color: AppColors.primary,
        child: SafeArea(child: body),
      );
    }

    return Drawer(child: body);
  }

  Widget _buildBody(BuildContext context, dynamic profile, bool isAdmin, String location, WidgetRef ref) {
    return Column(
      children: [
        DrawerHeader(
          decoration: const BoxDecoration(color: AppColors.primary),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.secondary,
                child: Text(
                  profile != null && profile.name.isNotEmpty
                      ? profile.name.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const Spacer(),
              Text(
                profile?.name ?? 'Carregando...',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.background, fontSize: 16),
              ),
              Text(
                profile?.email ?? '',
                style: TextStyle(color: AppColors.background.withValues(alpha: 0.8), fontSize: 12),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildItem(Icons.dashboard_outlined, Icons.dashboard, 'Painel Kanban', '/', location, context),
              _buildItem(Icons.people_outline, Icons.people, 'Clientes', '/customers', location, context),
              if (isAdmin)
                _buildItem(Icons.badge_outlined, Icons.badge, 'Funcionários', '/employees', location, context),
              _buildItem(Icons.shopping_bag_outlined, Icons.shopping_bag, 'Produtos', '/products', location, context),
              _buildItem(Icons.person_outline, Icons.person, 'Meu Perfil', '/profile', location, context),
            ],
          ),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: AppColors.error),
          title: const Text('Sair', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirmar Saída'),
                content: const Text('Deseja realmente sair do sistema?'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
                    child: const Text('Sair'),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await ref.read(authProvider.notifier).logout();
            }
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildItem(IconData icon, IconData activeIcon, String label, String route, String location, BuildContext context) {
    final isSelected = location == route || (route != '/' && location.startsWith(route));
    return ListTile(
      selected: isSelected,
      selectedTileColor: AppColors.secondary.withValues(alpha: 0.15),
      selectedColor: AppColors.background,
      iconColor: AppColors.background.withValues(alpha: 0.7),
      textColor: AppColors.background.withValues(alpha: 0.7),
      leading: Icon(isSelected ? activeIcon : icon, color: isSelected ? AppColors.secondary : null),
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      onTap: () {
        if (!isSidebar && context.mounted && Scaffold.of(context).isDrawerOpen) {
          Navigator.of(context).pop();
        }
        context.go(route);
      },
    );
  }
}
