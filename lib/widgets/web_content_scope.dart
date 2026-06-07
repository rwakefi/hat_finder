import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/app_breakpoints.dart';
import '../utils/embed_mode.dart';

/// Keeps primary app content at a readable width on large web viewports.
class WebContentScope extends StatelessWidget {
  const WebContentScope({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || EmbedMode.isActive || !AppBreakpoints.isDesktop(context)) {
      return child;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppBreakpoints.webAppMaxWidth(context),
        ),
        child: child,
      ),
    );
  }
}
