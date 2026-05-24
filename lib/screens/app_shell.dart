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

  void _selectTab(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                HomeScreen(
                  onFindHat: () => _selectTab(1),
                  onFitGuide: () => _selectTab(2),
                  onShop: () => _selectTab(3),
                ),
                const HatInputScreen(),
                const HeadShapeScreen(),
                ShopWebViewScreen(onBack: () => _selectTab(0)),
                const ConnectScreen(),
              ],
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
