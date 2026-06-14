import 'package:flutter/material.dart';

/// When true, site chrome stays visible (e.g. home tab where wheel gestures
/// and nested panel scrolls should not collapse the header).
class ScrollChromeLock extends InheritedWidget {
  const ScrollChromeLock({
    super.key,
    required this.lockVisible,
    required super.child,
  });

  final bool lockVisible;

  static bool lockVisibleOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<ScrollChromeLock>()
            ?.lockVisible ??
        false;
  }

  @override
  bool updateShouldNotify(ScrollChromeLock oldWidget) {
    return lockVisible != oldWidget.lockVisible;
  }
}

/// Desktop web: hide site chrome while scrolling down; reveal on scroll up.
class WebDesktopScrollChrome extends StatefulWidget {
  const WebDesktopScrollChrome({
    super.key,
    required this.chrome,
    required this.child,
    required this.enabled,
  });

  final Widget chrome;
  final Widget child;
  final bool enabled;

  @override
  State<WebDesktopScrollChrome> createState() => _WebDesktopScrollChromeState();
}

class WebDesktopScrollChromeVisibility extends InheritedWidget {
  const WebDesktopScrollChromeVisibility({
    super.key,
    required this.chromeVisible,
    required super.child,
  });

  final bool chromeVisible;

  static bool chromeVisibleOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<WebDesktopScrollChromeVisibility>();
    return scope?.chromeVisible ?? true;
  }

  @override
  bool updateShouldNotify(WebDesktopScrollChromeVisibility oldWidget) {
    return chromeVisible != oldWidget.chromeVisible;
  }
}

class _WebDesktopScrollChromeState extends State<WebDesktopScrollChrome> {
  static const _animationDuration = Duration(milliseconds: 280);

  static const double _revealNearTop = 28;
  static const double _toggleThreshold = 24;

  bool _chromeVisible = true;
  double _accumulatedDelta = 0;

  bool get _lockVisible => ScrollChromeLock.lockVisibleOf(context);

  void _setChromeVisible(bool visible) {
    if (_chromeVisible == visible) return;
    _accumulatedDelta = 0;
    setState(() => _chromeVisible = visible);
  }

  void _handleScrollDelta(double delta) {
    if (delta.sign != _accumulatedDelta.sign) {
      _accumulatedDelta = 0;
    }
    _accumulatedDelta += delta;
    if (_accumulatedDelta > _toggleThreshold) {
      _setChromeVisible(false);
    } else if (_accumulatedDelta < -_toggleThreshold) {
      _setChromeVisible(true);
    }
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_lockVisible) return false;

    // Ignore nested scrollables (e.g. home actions panel) — only react to
    // page-level scroll so inner panels don't collapse the site header.
    if (notification.depth > 0) return false;

    // Only vertical page scrolling should toggle the chrome. Horizontal
    // scrollables (wizard PageView, crown/brim carousels) must not collapse it.
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.pixels <= _revealNearTop) {
        _setChromeVisible(true);
        return false;
      }
      final delta = notification.scrollDelta;
      if (delta != null) {
        _handleScrollDelta(delta);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final lockVisible = _lockVisible;
    final chromeVisible = lockVisible || !widget.enabled || _chromeVisible;

    if (!widget.enabled || lockVisible) {
      return WebDesktopScrollChromeVisibility(
        chromeVisible: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            widget.chrome,
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return WebDesktopScrollChromeVisibility(
      chromeVisible: chromeVisible,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: chromeVisible ? 1 : 0,
              duration: _animationDuration,
              curve: Curves.easeInOutCubic,
              child: widget.chrome,
            ),
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
