import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

/// Screen displaying the active user's profile details and providing logout actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(
              child: Text('Nenhum dado de perfil encontrado.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 50.0,
                          backgroundColor: AppColors.secondary,
                          child: Text(
                            profile.name.isNotEmpty 
                                ? profile.name.substring(0, 1).toUpperCase() 
                                : 'U',
                            style: const TextStyle(
                              fontSize: 36.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        // Name
                        Text(
                          profile.name,
                          style: const TextStyle(
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0),

                        // Role Badge
                        Chip(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                          label: Text(
                            profile.role.toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                        const Divider(height: 40.0),

                        // Info Items
                        _buildProfileField(Icons.email, 'E-mail', profile.email),
                        const SizedBox(height: 16.0),
                        _buildProfileField(
                          Icons.phone,
                          'Telefone',
                          profile.phone ?? 'Não cadastrado',
                        ),
                        const SizedBox(height: 16.0),
                        _buildProfileField(
                          Icons.check_circle_outline,
                          'Status da Conta',
                          profile.active ? 'Ativo' : 'Inativo',
                        ),
                        const Divider(height: 40.0),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          height: 48.0,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            icon: const Icon(Icons.logout),
                            label: const Text(
                              'SAIR DO SISTEMA',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              final confirm = await ConfirmDialog.show(
                                context,
                                title: 'Sair do Sistema',
                                content: 'Deseja realmente encerrar sua sessão atual?',
                                confirmColor: AppColors.error,
                              );
                              if (confirm) {
                                await ref.read(authProvider.notifier).logout();
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Erro ao carregar dados do perfil: $err'),
        ),
      ),
    );
  }

  Widget _buildProfileField(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.secondary, size: 22.0),
        const SizedBox(width: 16.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12.0, color: AppColors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
