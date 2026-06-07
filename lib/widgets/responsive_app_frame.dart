import 'package:flutter/material.dart';

import '../config/app_breakpoints.dart';

/// Centers the app on wide viewports so mobile layouts are not stretched edge-to-edge.
class ResponsiveAppFrame extends StatelessWidget {
  const ResponsiveAppFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  static const _letterbox = Color(0xFF2D2926);

  @override
  Widget build(BuildContext context) {
    final maxWidth = AppBreakpoints.contentMaxWidth(context);
    final isWide = AppBreakpoints.isTablet(context);

    if (!isWide) return child;

    return ColoredBox(
      color: _letterbox,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            minHeight: MediaQuery.sizeOf(context).height,
          ),
          child: child,
        ),
      ),
    );
  }
}
