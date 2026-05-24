import 'package:flutter/material.dart';

import '../widgets/moon_ridge_bottom_nav.dart';
import 'connect_screen.dart';
import 'hat_input_screen.dart';
import 'hat_results_screen.dart';
import 'head_shape_screen.dart';
import 'home_screen.dart';
import 'shop_webview_screen.dart';

/// Root shell with persistent bottom navigation (Hero Top home + tab sections).
class AppShell extends StatefulWidget {
  AppShell({Key? key}) : super(key: key ?? _navKey);

  static final GlobalKey _navKey = GlobalKey();

  /// Pops overlay routes and switches the shell tab (e.g. from results).
  static void navigateToTab(int index) {
    final state = _navKey.currentState;
    if (state is _AppShellState) {
      state.selectTab(index);
    }
  }

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  final Set<int> _visitedTabs = {0};

  void selectTab(int index) => _selectTab(index);

  void _selectTab(int index) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
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
      1 => HatInputScreen(onExit: () => _selectTab(0)),
      2 => const HeadShapeScreen(),
      3 => ShopWebViewScreen(onBack: () => _selectTab(0)),
      4 => ShopWebViewScreen(
          url: 'https://moonridgecompany.com/pages/book-moonridge',
          title: 'Events / Connect',
          onBack: () => _selectTab(0),
          hideHeaderFooter: true,
          selectedIndex: 4,
        ),
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
            onSelected: (index) {
              if (index == 1) {
                // "Find Hat" footer → go straight to results (all filters = Any)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HatResultsScreen(),
                  ),
                );
              } else {
                _selectTab(index);
              }
            },
          ),
        ],
      ),
    );
  }
}
