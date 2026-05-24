import 'package:flutter/material.dart';

import '../screens/app_shell.dart';
import '../screens/hat_results_screen.dart';
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
      onSelected: (index) {
        if (index == 1) {
          // "Find Hat" in footer → go directly to results with all filters set to Any
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const HatResultsScreen(),
            ),
          );
        } else {
          AppShell.navigateToTab(index);
        }
      },
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
