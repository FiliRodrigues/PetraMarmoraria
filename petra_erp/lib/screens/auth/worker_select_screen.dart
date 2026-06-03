import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/constants/roles.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/supabase_provider.dart';
import '../../services/worker_auth_service.dart';
import '../../widgets/widgets.dart';

class WorkerSelectScreen extends ConsumerStatefulWidget {
  const WorkerSelectScreen({super.key});

  @override
  ConsumerState<WorkerSelectScreen> createState() => _WorkerSelectScreenState();
}

class _WorkerSelectScreenState extends ConsumerState<WorkerSelectScreen> {
  late final FutureProvider<List<PinWorker>> _workersProvider;

  @override
  void initState() {
    super.initState();
    final service = ref.read(workerAuthServiceProvider);
    _workersProvider = FutureProvider<List<PinWorker>>((ref) => service.listWorkers());
  }

  @override
  Widget build(BuildContext context) {
    final workersAsync = ref.watch(_workersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Funcionário'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/entrar'),
        ),
      ),
      body: workersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text('Erro ao carregar funcionários',
                style: AppTheme.jakarta(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(_workersProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (workers) {
          if (workers.isEmpty) {
            return const EmptyState(
              title: 'Nenhum funcionário',
              message: 'Nenhum funcionário de produção cadastrado no momento.',
              icon: LucideIcons.hardHat,
            );
          }

          final sorted = List<PinWorker>.from(workers)
            ..sort((a, b) => a.name.compareTo(b.name));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: Text(
                  'Quem é você?',
                  style: AppTheme.syne(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: sorted.length,
                  itemBuilder: (context, i) {
                    final worker = sorted[i];
                    final blocked = worker.blocked;

                    return Opacity(
                      opacity: blocked ? 0.45 : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _WorkerCard(
                          worker: worker,
                          onTap: blocked
                              ? null
                              : () => context.push('/funcionario/pin', extra: worker),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WorkerCard extends StatefulWidget {
  final PinWorker worker;
  final VoidCallback? onTap;

  const _WorkerCard({required this.worker, this.onTap});

  @override
  State<_WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<_WorkerCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.worker;
    final primaryRole = w.roles.isNotEmpty ? w.roles.first : '';
    final color = AppRoles.roleColor(primaryRole);

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: _hovered && widget.onTap != null ? AppColors.accent : AppColors.border,
            ),
            boxShadow: _hovered && widget.onTap != null
                ? AppTheme.shadowMedium
                : AppTheme.shadowSoft,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.20),
                      AppColors.accent.withValues(alpha: 0.14),
                    ],
                  ),
                ),
                child: Text(
                  AppRoles.initials(w.name),
                  style: AppTheme.syne(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w.name,
                      style: AppTheme.jakarta(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (w.blocked)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.lock, size: 13, color: AppColors.error),
                          const SizedBox(width: 4),
                          Text(
                            'Bloqueado',
                            style: AppTheme.jakarta(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: w.roles.map((role) {
                          final rc = AppRoles.roleColor(role);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: rc.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                            ),
                            child: Text(
                              AppRoles.roleLabel(role).toUpperCase(),
                              style: AppTheme.jakarta(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: rc,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              if (widget.onTap != null)
                Icon(Icons.chevron_right, color: AppColors.textMuted, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}
