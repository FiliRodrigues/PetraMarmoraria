import 'package:flutter/material.dart';
import '../../core/utils/error_messages.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

/// Screen displaying the active user's profile details and providing logout actions.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meu Perfil')),
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
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    side: const BorderSide(color: AppColors.border),
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
                            style: AppTheme.syne(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24.0),

                        // Name
                        Text(
                          profile.name,
                          style: AppTheme.syne(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0),

                        // Role Badge
                        Chip(
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.08,
                          ),
                          label: Text(
                            profile.role.toUpperCase(),
                            style: AppTheme.jakarta(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Divider(height: 40.0),

                        // Info Items
                        _buildProfileField(
                          Icons.email,
                          'E-mail',
                          profile.email,
                        ),
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
                            label: Text(
                              'SAIR DO SISTEMA',
                              style: AppTheme.jakarta(
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            onPressed: () async {
                              final confirm = await ConfirmDialog.show(
                                context,
                                title: 'Sair do Sistema',
                                content:
                                    'Deseja realmente encerrar sua sessão atual?',
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
        error: (err, _) => Center(child: Text(friendlyError(err))),
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
                style: AppTheme.jakarta(
                  fontSize: 12,
                  color: AppColors.grey,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                value,
                style: AppTheme.jakarta(
                  fontSize: 15,
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
