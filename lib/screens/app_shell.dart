import 'package:flutter/material.dart';

import '../widgets/moon_ridge_bottom_nav.dart';
import 'connect_screen.dart';
import 'hat_input_screen.dart';
import 'head_shape_screen.dart';
import 'home_screen.dart';
import 'shop_webview_screen.dart';

/// Root shell with persistent bottom navigation (Hero Top home + tab sections).
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final Set<int> _visitedTabs = {0};

  void _selectTab(int index) {
    setState(() {
      _selectedIndex = index;
      _visitedTabs.add(index);
    });
  }

  Widget _buildTab(int index) {
    if (!_visitedTabs.contains(index)) {
      return const SizedBox.shrink();
    }

    return switch (index) {
      0 => HomeScreen(
          onFindHat: () => _selectTab(1),
          onFitGuide: () => _selectTab(2),
          onShop: () => _selectTab(3),
        ),
      1 => const HatInputScreen(),
      2 => const HeadShapeScreen(),
      3 => ShopWebViewScreen(onBack: () => _selectTab(0)),
      4 => const ConnectScreen(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: List.generate(5, _buildTab),
            ),
          ),
          MoonRidgeBottomNav(
            selectedIndex: _selectedIndex,
            onSelected: _selectTab,
          ),
        ],
      ),
    );
  }
}
