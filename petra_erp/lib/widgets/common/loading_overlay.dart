import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Stack(
            children: [
              const ModalBarrier(dismissible: false, color: Colors.black38),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      if (message != null) ...[
                        const SizedBox(height: 14),
                        Text(message!,
                          style: AppTheme.jakarta(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
