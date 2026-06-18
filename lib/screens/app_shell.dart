import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_breakpoints.dart';
import '../widgets/moon_ridge_bottom_nav.dart';
import '../widgets/web_content_scope.dart';
import 'hat_input_screen.dart';
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
  int _hatInputSession = 0;
  final Set<int> _visitedTabs = {0};
  final Set<int> _deferredTabs = {};

  static const Set<int> _webViewTabs = {3, 4};
  static const _darkSurfaceOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );
  static const _lightSurfaceOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  void selectTab(int index) => _selectTab(index);

  void _selectTab(int index) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }

    final shouldDeferTabBuild =
        !_visitedTabs.contains(index) && _webViewTabs.contains(index);
    setState(() {
      if (index == 0) {
        // Home abandons the in-progress wizard — fresh session next visit.
        _hatInputSession++;
      }
      _selectedIndex = index;
      if (shouldDeferTabBuild) {
        _deferredTabs.add(index);
      } else {
        _visitedTabs.add(index);
      }
    });

    if (shouldDeferTabBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _deferredTabs.remove(index);
          _visitedTabs.add(index);
        });
      });
    }
  }

  Widget _buildTab(int index) {
    if (!_visitedTabs.contains(index)) {
      return _deferredTabs.contains(index)
          ? const _DeferredTabLoadingView()
          : const SizedBox.shrink();
    }

    return switch (index) {
      0 => HomeScreen(
          onFindHat: () => _selectTab(1),
          onFitGuide: () => _selectTab(2),
          onShop: () => _selectTab(3),
        ),
      1 => HatInputScreen(
          key: ValueKey('hat-input-$_hatInputSession'),
          onExit: () => _selectTab(0),
        ),
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
    final useTopNav = AppBreakpoints.useWebTopNavigation(context);
    final nav = MoonRidgeBottomNav(
      selectedIndex: _selectedIndex,
      layout: useTopNav ? AppNavLayout.top : AppNavLayout.bottom,
      onSelected: (index) {
        _selectTab(index);
      },
    );

    final content = WebContentScope(
      child: IndexedStack(
        index: _selectedIndex,
        children: List.generate(5, _buildTab),
      ),
    );
    final safeContent = !kIsWeb && _selectedIndex != 0
        ? SafeArea(
            bottom: false,
            child: content,
          )
        : content;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _selectedIndex == 0
          ? _darkSurfaceOverlayStyle
          : _lightSurfaceOverlayStyle,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF8F5),
        body: Column(
          children: [
            if (useTopNav) nav,
            Expanded(child: safeContent),
            if (!useTopNav) nav,
          ],
        ),
      ),
    );
  }
}

class _DeferredTabLoadingView extends StatelessWidget {
  const _DeferredTabLoadingView();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFFAF8F5),
      child: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF559C99),
        ),
      ),
    );
  }
}
