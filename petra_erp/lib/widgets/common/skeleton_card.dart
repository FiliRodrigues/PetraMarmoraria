import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Placeholder animado (shimmer) exibido enquanto as OS carregam no Kanban.
class SkeletonOSCard extends StatefulWidget {
  const SkeletonOSCard({super.key});

  @override
  State<SkeletonOSCard> createState() => _SkeletonOSCardState();
}

class _SkeletonOSCardState extends State<SkeletonOSCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: const Border(
          left: BorderSide(color: AppColors.border, width: 3),
          top: BorderSide(color: AppColors.border),
          right: BorderSide(color: AppColors.border),
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _bar(60, 12),
          const SizedBox(height: 8),
          _bar(140, 13),
          const SizedBox(height: 6),
          _bar(90, 11),
        ],
      ),
    );
  }

  Widget _bar(double w, double h) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            gradient: LinearGradient(
              colors: const [
                AppColors.neutral200,
                AppColors.neutral100,
                AppColors.neutral200,
              ],
              stops: const [0.25, 0.5, 0.75],
              begin: Alignment(-1.0 - 3 * _c.value, 0),
              end: Alignment(1.0 - 3 * _c.value, 0),
            ),
          ),
        ),
      );
}
