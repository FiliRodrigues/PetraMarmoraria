import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/widgets.dart';

class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  void _onSearchChanged() {
    ref.read(employeePagedProvider.notifier).refresh(
      search: _searchController.text.isEmpty ? null : _searchController.text,
    );
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(employeePagedProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _scrollController.removeListener(_onScroll);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentProfileAsync = ref.watch(currentProfileProvider);

    return currentProfileAsync.when(
      data: (profile) {
        if (profile == null || !profile.hasRole('admin')) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: EmptyState(
                  title: 'Acesso Negado',
                  message: 'Você não possui privilégios de Administrador para acessar esta área.',
                  icon: LucideIcons.lock,
                ),
              ),
            ),
          );
        }

        final paged = ref.watch(employeePagedProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Controle de Funcionários'),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                onPressed: () => ref.read(employeePagedProvider.notifier).refresh(
                  search: _searchController.text.isEmpty ? null : _searchController.text,
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/employees/new'),
            child: const Icon(LucideIcons.userPlus, size: 20),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar por nome, cargo ou e-mail...',
                    prefixIcon: Icon(LucideIcons.search, size: 16),
                  ),
                ),
              ),
              if (paged.error != null && paged.items.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
                        const SizedBox(height: 16),
                        Text('Erro ao carregar funcionários: ${paged.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: const Text('Tentar novamente'),
                          onPressed: () => ref.read(employeePagedProvider.notifier).refresh(),
                        ),
                      ],
                    ),
                  ),
                )
              else if (paged.items.isEmpty && paged.isLoadingMore)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (paged.items.isEmpty)
                const Expanded(
                  child: EmptyState(
                    title: 'Nenhum funcionário encontrado',
                    message: 'Utilize o botão de adicionar para cadastrar novos funcionários no sistema.',
                    icon: LucideIcons.users,
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: paged.items.length + (paged.isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == paged.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final emp = paged.items[index];
                      final isSelf = emp.id == profile.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              color: emp.active
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                            alignment: Alignment.center,
                            child: Text(emp.name.substring(0, 1).toUpperCase(),
                              style: AppTheme.syne(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ),
                          title: Row(
                            children: [
                              Text(emp.name,
                                style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w700)),
                              if (isSelf) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text('VOCÊ',
                                    style: AppTheme.jakarta(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white)),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            'Funções: ${emp.roles.map((r) => r.toUpperCase()).join(', ')} | ${emp.email ?? 'Sem email'}',
                            style: AppTheme.jakarta(fontSize: 12, color: AppColors.textMuted)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: emp.active,
                                activeColor: AppColors.accent,
                                onChanged: isSelf
                                    ? null
                                    : (val) async {
                                        try {
                                          await ref.read(employeeProvider.notifier).toggleActiveStatus(emp.id, val);
                                          if (context.mounted) {
                                            ref.read(employeePagedProvider.notifier).refresh();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Funcionário ${val ? "ativado" : "desativado"} com sucesso!')),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Erro ao alterar status: $e'), backgroundColor: AppColors.error),
                                            );
                                          }
                                        }
                                      },
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.edit, size: 16, color: AppColors.primary),
                                tooltip: 'Editar cargo/dados',
                                onPressed: () => context.push('/employees/${emp.id}/edit'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Erro ao validar acesso: $err'))),
    );
  }
}
