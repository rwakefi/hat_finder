import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_breakpoints.dart';
import '../utils/embed_mode.dart';
import 'website_chrome.dart';

/// Centers the app on wide viewports and adds website chrome on web.
class ResponsiveAppFrame extends StatelessWidget {
  const ResponsiveAppFrame({
    super.key,
    required this.child,
  });

  final Widget child;

  static const _surface = Color(0xFFFAF8F5);

  @override
  Widget build(BuildContext context) {
    if (EmbedMode.isActive) {
      return ColoredBox(color: _surface, child: child);
    }

    final isWide = AppBreakpoints.isTablet(context);
    if (!isWide) return child;

    // Native iPad should fill the App Store screenshot canvas.
    if (!kIsWeb) return child;

    // Web (tablet+): store header + full-bleed app - no side boards.
    final app = ColoredBox(color: _surface, child: child);
    if (WebsiteChrome.shouldShow(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WebsiteChrome(),
          Expanded(child: app),
        ],
      );
    }
    return app;
  }
}
