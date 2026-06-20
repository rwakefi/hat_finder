import 'package:flutter/material.dart';

import '../config/app_breakpoints.dart';
import '../screens/app_shell.dart';
import 'moon_ridge_bottom_nav.dart';

/// Shell tab bar for pushed routes that cover [AppShell]'s persistent nav.
class ShellTabBarFooter extends StatelessWidget {
  const ShellTabBarFooter({
    super.key,
    required this.selectedIndex,
  });

  final int selectedIndex;

  static AppNavLayout layoutFor(BuildContext context) =>
      AppBreakpoints.useWebTopNavigation(context)
          ? AppNavLayout.top
          : AppNavLayout.bottom;

  static MoonRidgeBottomNav buildNav(
    BuildContext context, {
    required int selectedIndex,
  }) {
    return MoonRidgeBottomNav(
      selectedIndex: selectedIndex,
      layout: layoutFor(context),
      onSelected: (index) {
        AppShell.navigateToTab(index);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return buildNav(context, selectedIndex: selectedIndex);
  }
}

/// Wraps [child] with shell navigation at the top (desktop web) or bottom.
class ShellNavigationHost extends StatelessWidget {
  const ShellNavigationHost({
    super.key,
    required this.selectedIndex,
    required this.child,
    this.showNavigation = true,
  });

  final int selectedIndex;
  final Widget child;
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    if (!showNavigation) return child;

    final useTopNav = AppBreakpoints.useWebTopNavigation(context);
    final nav =
        ShellTabBarFooter.buildNav(context, selectedIndex: selectedIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (useTopNav) nav,
        Expanded(child: child),
        if (!useTopNav) nav,
      ],
    );
  }
}

/// Page-specific footer controls stacked above the shell tab bar.
class ShellTabBarWithFooter extends StatelessWidget {
  const ShellTabBarWithFooter({
    super.key,
    required this.selectedIndex,
    required this.footer,
  });

  final int selectedIndex;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final useTopNav = AppBreakpoints.useWebTopNavigation(context);

    // On desktop web the tab bar lives at the top of the AppShell — only
    // show the page-specific footer controls here to avoid a duplicate nav bar.
    if (useTopNav) {
      return footer;
    }

    final nav =
        ShellTabBarFooter.buildNav(context, selectedIndex: selectedIndex);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        footer,
        nav,
      ],
    );
  }
}
