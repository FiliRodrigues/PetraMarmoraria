import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_drawer.dart';

/// A responsive app scaffold that acts as the shell of the application.
/// It renders a permanent sidebar on desktop (> 900px) and a standard drawer on mobile.
class AppScaffold extends StatelessWidget {
  final Widget child;

  const AppScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            SizedBox(
              width: 280.0,
              child: AppDrawer(isSidebar: true),
            ),
            const VerticalDivider(width: 1.0, thickness: 1.0, color: AppColors.border),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Petra ERP'),
      ),
      drawer: const AppDrawer(),
      body: child,
    );
  }
}
