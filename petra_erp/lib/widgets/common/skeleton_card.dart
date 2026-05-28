import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class SkeletonOSCard extends StatefulWidget {
  const SkeletonOSCard({super.key});

  @override
  State<SkeletonOSCard> createState() => _SkeletonOSCardState();
}

class _SkeletonOSCardState extends State<SkeletonOSCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = _ctrl.drive(CurveTween(curve: Curves.easeInOut));

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => Opacity(opacity: 0.4 + (opacity.value * 0.45), child: child),
      child: Container(
        height: 90,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(11),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 11,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 60,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
