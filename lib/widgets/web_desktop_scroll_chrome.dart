import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

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
  static const _animationDuration = Duration(milliseconds: 220);

  // Always keep the chrome shown within this many pixels of the top so it
  // never vanishes on a tiny scroll, and accumulate scroll deltas so small
  // trackpad/momentum oscillations don't flicker the header.
  static const double _revealNearTop = 28;
  static const double _toggleThreshold = 18;

  bool _chromeVisible = true;
  double _accumulatedDelta = 0;

  void _setChromeVisible(bool visible) {
    if (_chromeVisible == visible) return;
    _accumulatedDelta = 0;
    setState(() => _chromeVisible = visible);
  }

  void _handleScrollDelta(double delta) {
    // Reset the accumulator whenever the scroll direction reverses.
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

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _handleScrollDelta(event.scrollDelta.dy);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.chrome,
          Expanded(child: widget.child),
        ],
      );
    }

    return WebDesktopScrollChromeVisibility(
      chromeVisible: _chromeVisible,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: _chromeVisible ? 1 : 0,
              duration: _animationDuration,
              curve: Curves.easeInOut,
              child: widget.chrome,
            ),
          ),
          Expanded(
            child: Listener(
              onPointerSignal: _handlePointerSignal,
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: widget.child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
