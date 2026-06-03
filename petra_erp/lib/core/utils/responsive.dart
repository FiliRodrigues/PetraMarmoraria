import 'package:flutter/widgets.dart';
import '../constants/app_constants.dart';

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isMobile => screenWidth < AppConstants.tabletBreakpoint;

  bool get isTablet =>
      screenWidth >= AppConstants.tabletBreakpoint &&
      screenWidth < AppConstants.desktopBreakpoint;

  bool get isDesktop => screenWidth >= AppConstants.desktopBreakpoint;
}
