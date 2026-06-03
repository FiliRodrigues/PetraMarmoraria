import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class RoleGateScreen extends ConsumerStatefulWidget {
  const RoleGateScreen({super.key});

  @override
  ConsumerState<RoleGateScreen> createState() => _RoleGateScreenState();
}

class _RoleGateScreenState extends ConsumerState<RoleGateScreen> {
  String? _selected;

  void _continue() {
    if (_selected == null) return;
    switch (_selected) {
      case 'admin':
        context.push('/login?perfil=admin');
        break;
      case 'vendedor':
        context.push('/login?perfil=vendedor');
        break;
      case 'funcionario':
        context.push('/funcionario');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                LucideIcons.gem,
                size: 56,
                color: AppColors.accent,
              ),
              const SizedBox(height: 16),
              Text(
                'PETRA MARMORARIA',
                style: AppTheme.syne(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ).copyWith(letterSpacing: 1.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecione seu perfil de acesso',
                style: AppTheme.jakarta(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              _RoleCard(
                icon: LucideIcons.shield,
                label: 'Administrador',
                subtitle: 'Acesso completo ao ERP',
                color: AppColors.primary,
                selected: _selected == 'admin',
                onTap: () => setState(() => _selected = 'admin'),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                icon: LucideIcons.briefcase,
                label: 'Vendedor',
                subtitle: 'Kanban, clientes e orçamentos',
                color: AppColors.accent,
                selected: _selected == 'vendedor',
                onTap: () => setState(() => _selected = 'vendedor'),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                icon: LucideIcons.hardHat,
                label: 'Funcionário',
                subtitle: 'Acesso rápido por PIN',
                color: AppColors.corte,
                selected: _selected == 'funcionario',
                onTap: () => setState(() => _selected = 'funcionario'),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: _selected != null ? _continue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: AppTheme.jakarta(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('CONTINUAR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 340,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: widget.selected
                  ? widget.color
                  : _hovered
                      ? AppColors.accent
                      : AppColors.border,
              width: widget.selected ? 2 : 1,
            ),
            boxShadow: widget.selected
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : AppTheme.shadowSoft,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
                child: Icon(widget.icon, color: widget.color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: AppTheme.syne(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: AppTheme.jakarta(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.selected)
                Icon(Icons.check_circle, color: widget.color, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
