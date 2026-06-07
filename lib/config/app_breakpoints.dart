import 'package:flutter/material.dart';

/// Shared layout breakpoints for web and large screens.
class AppBreakpoints {
  AppBreakpoints._();

  static const double tablet = 600;
  static const double desktop = 1024;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isTablet(BuildContext context) => widthOf(context) >= tablet;

  static bool isDesktop(BuildContext context) => widthOf(context) >= desktop;

  /// Max width for the centered app column (phone / tablet / desktop).
  static double contentMaxWidth(BuildContext context) {
    final width = widthOf(context);
    if (width >= desktop) return 960;
    if (width >= tablet) return 480;
    return width;
  }

  static int gridCrossAxisCount(
    BuildContext context, {
    int mobile = 2,
    int tablet = 2,
    int desktop = 3,
  }) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
