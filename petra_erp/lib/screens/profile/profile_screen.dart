import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/widgets.dart';

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
            return Center(
              child: Text('Nenhum dado de perfil encontrado.',
                style: AppTheme.jakarta(color: AppColors.textMuted)),
            );
          }

          final initials = profile.name.isNotEmpty
              ? profile.name[0].toUpperCase()
              : 'U';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Avatar
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        alignment: Alignment.center,
                        child: Text(initials,
                          style: AppTheme.syne(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ),
                      const SizedBox(height: 20),

                      // Name
                      Text(profile.name,
                        style: AppTheme.syne(fontSize: 20, fontWeight: FontWeight.w800),
                        textAlign: TextAlign.center),
                      const SizedBox(height: 8),

                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Text(profile.roles.map((r) => r.toUpperCase()).join(', '),
                          style: AppTheme.jakarta(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 20),

                      _ProfileField(LucideIcons.mail, 'E-mail', profile.email ?? '—'),
                      const SizedBox(height: 16),
                      _ProfileField(LucideIcons.phone, 'Telefone',
                          profile.phone ?? 'Não cadastrado'),
                      const SizedBox(height: 16),
                      _ProfileField(LucideIcons.checkCircle, 'Status da Conta',
                          profile.active ? 'Ativo' : 'Inativo'),

                      const SizedBox(height: 24),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 20),

                      // Edit profile button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          icon: const Icon(LucideIcons.pencil, size: 16),
                          label: const Text('EDITAR PERFIL'),
                          onPressed: () => context.push('/profile/edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Logout button
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                            ),
                          ),
                          icon: const Icon(LucideIcons.logOut, size: 16),
                          label: Text('SAIR DO SISTEMA',
                            style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Erro ao carregar dados do perfil: $err',
            style: AppTheme.jakarta(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ProfileField(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.accent),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
              style: AppTheme.jakarta(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
            const SizedBox(height: 2),
            Text(value,
              style: AppTheme.jakarta(fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ],
  );
}
