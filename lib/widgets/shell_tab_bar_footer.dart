import 'package:flutter/material.dart';

import '../screens/app_shell.dart';
import 'moon_ridge_bottom_nav.dart';

/// Shell tab bar for pushed routes that cover [AppShell]'s persistent nav.
class ShellTabBarFooter extends StatelessWidget {
  const ShellTabBarFooter({
    super.key,
    required this.selectedIndex,
  });

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return MoonRidgeBottomNav(
      selectedIndex: selectedIndex,
      onSelected: AppShell.navigateToTab,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        footer,
        ShellTabBarFooter(selectedIndex: selectedIndex),
      ],
    );
  }
}
