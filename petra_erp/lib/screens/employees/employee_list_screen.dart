import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_provider.dart';
import '../../widgets/widgets.dart';

/// Screen listing all employees. Restricted to Admin profiles.
/// Admins can toggle active/inactive status and navigate to creation/editing.
class EmployeeListScreen extends ConsumerStatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  ConsumerState<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends ConsumerState<EmployeeListScreen> {
  final _searchController = TextEditingController();
  String _searchText = '';

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
    // 1. Verify if user is admin
    final currentProfileAsync = ref.watch(currentProfileProvider);

    return currentProfileAsync.when(
      data: (profile) {
        if (profile == null || profile.role.toLowerCase() != 'admin') {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: EmptyState(
                  title: 'Acesso Negado',
                  message: 'Você não possui privilégios de Administrador para acessar esta área.',
                  icon: Icons.lock_outline,
                ),
              ),
            ),
          );
        }

        // Render main screen for Admins
        final employeesAsync = ref.watch(employeeProvider);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Controle de Funcionários'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(employeeProvider.notifier).loadEmployees(),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => context.push('/employees/new'),
            child: const Icon(Icons.person_add),
          ),
          body: employeesAsync.when(
            data: (employees) {
              final filtered = employees.where((emp) {
                final query = _searchText.toLowerCase();
                final nameMatch = emp.name.toLowerCase().contains(query);
                final roleMatch = emp.role.toLowerCase().contains(query);
                final emailMatch = emp.email.toLowerCase().contains(query);
                return nameMatch || roleMatch || emailMatch;
              }).toList();

              return Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Buscar por nome, cargo ou e-mail...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                  ),

                  // Employees List
                  Expanded(
                    child: filtered.isEmpty
                        ? const EmptyState(
                            title: 'Nenhum funcionário encontrado',
                            message: 'Utilize o botão de adicionar para cadastrar novos funcionários no sistema.',
                            icon: Icons.people_alt_outlined,
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final emp = filtered[index];
                              final isSelf = emp.id == profile.id;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: emp.active 
                                        ? AppColors.secondary.withOpacity(0.2) 
                                        : AppColors.lightGrey,
                                    foregroundColor: AppColors.primary,
                                    child: Text(emp.name.substring(0, 1).toUpperCase()),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        emp.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      if (isSelf) ...[
                                        const SizedBox(width: 8.0),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'VOCÊ',
                                            style: TextStyle(color: Colors.white, fontSize: 8.0, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    'Cargo: ${emp.role.toUpperCase()} | ${emp.email}',
                                    style: const TextStyle(fontSize: 12.0),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Active Status Switch
                                      Switch(
                                        value: emp.active,
                                        activeColor: AppColors.secondary,
                                        onChanged: isSelf 
                                            ? null // prevent self-deactivation
                                            : (val) async {
                                                try {
                                                  await ref
                                                      .read(employeeProvider.notifier)
                                                      .toggleActiveStatus(emp.id, val);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'Funcionário ${val ? "ativado" : "desativado"} com sucesso!',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Erro ao alterar status: $e'),
                                                        backgroundColor: AppColors.error,
                                                      ),
                                                    );
                                                  }
                                                }
                                              },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: AppColors.primary),
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
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Erro ao carregar lista de funcionários: $err')),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Erro ao validar acesso: $err'))),
    );
  }
}
