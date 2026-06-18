import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/embed_mode.dart';

/// Shared layout breakpoints for web and large screens.
class AppBreakpoints {
  AppBreakpoints._();

  static const double tablet = 600;
  static const double laptop = 900;
  static const double desktop = 1024;
  static const double wide = 1280;
  static const double webAppMax = 1280;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isTablet(BuildContext context) => widthOf(context) >= tablet;

  static bool isLaptop(BuildContext context) => widthOf(context) >= laptop;

  static bool isDesktop(BuildContext context) => widthOf(context) >= desktop;

  static bool isWide(BuildContext context) => widthOf(context) >= wide;

  /// Pro Max class (~932pt+ logical height). Native phones only.
  static bool isLargePhone(BuildContext context) {
    if (kIsWeb) return false;
    return MediaQuery.sizeOf(context).height >= 920;
  }

  /// Desktop web uses a top tab bar instead of the mobile-style bottom nav.
  static bool useWebTopNavigation(BuildContext context) =>
      kIsWeb && !EmbedMode.isActive && isDesktop(context);

  /// Side-by-side home hero + actions (laptop and up).
  static bool useSplitHomeLayout(BuildContext context) => isLaptop(context);

  /// Max readable width for app content on large web screens.
  static double webAppMaxWidth(BuildContext context) {
    if (!isDesktop(context)) return widthOf(context);
    return math.min(widthOf(context), webAppMax);
  }

  /// Max width for the centered app column.
  static double contentMaxWidth(BuildContext context) {
    final width = widthOf(context);
    if (width >= wide) return 1200;
    if (width >= desktop) return math.min(width - 64, 1120);
    if (width >= laptop) return math.min(width - 48, 1040);
    if (width >= tablet) return math.min(width - 32, 720);
    return width;
  }

  static int gridCrossAxisCount(
    BuildContext context, {
    int mobile = 2,
    int tablet = 2,
    int laptop = 3,
    int desktop = 3,
  }) {
    if (isDesktop(context)) return desktop;
    if (isLaptop(context)) return laptop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}
