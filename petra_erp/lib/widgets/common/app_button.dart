import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, navy, outline, soft, ghost, danger, dangerSoft, link }

enum AppButtonSize { sm, md, lg }

/// Botão reutilizável no estilo reui (forma) com a marca Petra.
/// Variantes: primary (âmbar), navy, outline, soft, ghost, danger, dangerSoft, link.
class AppButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool loading;
  final bool expanded;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.loading = false,
    this.expanded = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;
  bool _focused = false;

  bool get _disabled => widget.onPressed == null || widget.loading;

  EdgeInsets get _padding => switch (widget.size) {
        AppButtonSize.sm => const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        AppButtonSize.md => const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        AppButtonSize.lg => const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
      };

  double get _fontSize => switch (widget.size) {
        AppButtonSize.sm => 12.5,
        AppButtonSize.md => 13.5,
        AppButtonSize.lg => 15.0,
      };

  double get _iconSize => switch (widget.size) {
        AppButtonSize.sm => 15,
        AppButtonSize.md => 16,
        AppButtonSize.lg => 18,
      };

  ({Color bg, Color fg, Color? border}) get _colors {
    final accentHover = const Color(0xFFA96E22);
    return switch (widget.variant) {
      AppButtonVariant.primary =>
        (bg: _hovered ? accentHover : AppColors.accent, fg: Colors.white, border: null),
      AppButtonVariant.navy =>
        (bg: _hovered ? const Color(0xFF0C4A78) : AppColors.primary, fg: Colors.white, border: null),
      AppButtonVariant.outline =>
        (bg: _hovered ? AppColors.neutral100 : AppColors.surface, fg: AppColors.primary, border: AppColors.border),
      AppButtonVariant.soft =>
        (bg: _hovered ? const Color(0xFFEFD49A) : AppColors.accentLight, fg: const Color(0xFF7A521B), border: null),
      AppButtonVariant.ghost =>
        (bg: _hovered ? AppColors.neutral100 : Colors.transparent, fg: AppColors.primary, border: null),
      AppButtonVariant.danger =>
        (bg: _hovered ? const Color(0xFFA32F23) : AppColors.error, fg: Colors.white, border: null),
      AppButtonVariant.dangerSoft =>
        (bg: _hovered ? const Color(0xFFF6D6D1) : const Color(0xFFFBE9E7), fg: const Color(0xFFA32F23), border: null),
      AppButtonVariant.link =>
        (bg: Colors.transparent, fg: AppColors.primary, border: null),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    final isLink = widget.variant == AppButtonVariant.link;
    final showElevation = !_disabled &&
        (widget.variant == AppButtonVariant.primary ||
            widget.variant == AppButtonVariant.navy ||
            widget.variant == AppButtonVariant.danger);

    Widget content = Row(
      mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: _iconSize, height: _iconSize,
            child: CircularProgressIndicator(strokeWidth: 2, color: c.fg),
          )
        else if (widget.icon != null) ...[
          Icon(widget.icon, size: _iconSize, color: c.fg),
        ],
        if ((widget.icon != null || widget.loading)) const SizedBox(width: 8),
        Text(
          widget.label,
          style: AppTheme.jakarta(
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
            color: c.fg,
          ).copyWith(
            decoration: isLink ? TextDecoration.underline : null,
            decorationColor: c.fg,
          ),
        ),
      ],
    );

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      transform: Matrix4.translationValues(0, (_hovered && showElevation) ? -1 : 0, 0),
      padding: isLink ? const EdgeInsets.symmetric(horizontal: 4, vertical: 8) : _padding,
      decoration: BoxDecoration(
        color: _disabled ? c.bg.withValues(alpha: 0.5) : c.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: c.border != null ? Border.all(color: c.border!) : null,
        boxShadow: _focused
            ? AppTheme.focusRing(widget.variant == AppButtonVariant.navy
                ? AppColors.primary
                : AppColors.accent)
            : (showElevation ? (_hovered ? AppTheme.shadowMedium : AppTheme.shadowSoft) : null),
      ),
      child: content,
    );

    return MouseRegion(
      cursor: _disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: GestureDetector(
          onTap: _disabled ? null : widget.onPressed,
          child: child,
        ),
      ),
    );
  }
}
