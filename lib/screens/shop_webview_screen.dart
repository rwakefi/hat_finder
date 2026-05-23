import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ShopWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const ShopWebViewScreen({
    super.key,
    this.url = 'https://moonridgecompany.com',
    this.title = 'Moon Ridge Shop',
  });

  @override
  State<ShopWebViewScreen> createState() => _ShopWebViewScreenState();
}

class _ShopWebViewScreenState extends State<ShopWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isClampingHorizontalScroll = false;

  static const String _verticalScrollLockScript = r'''
(() => {
  const styleId = 'hat-finder-vertical-scroll-lock';
  let style = document.getElementById(styleId);
  if (!style) {
    style = document.createElement('style');
    style.id = styleId;
    document.head.appendChild(style);
  }
  style.textContent = `
    html, body {
      overflow-x: hidden !important;
      max-width: 100vw !important;
      overscroll-behavior-x: none !important;
      touch-action: pan-y !important;
    }
  `;

  const viewport =
    document.querySelector('meta[name="viewport"]') ||
    document.head.appendChild(document.createElement('meta'));
  viewport.setAttribute('name', 'viewport');
  viewport.setAttribute('content', 'width=device-width, initial-scale=1');

  const clampHorizontalScroll = () => {
    document.documentElement.scrollLeft = 0;
    document.body.scrollLeft = 0;
    if (window.scrollX !== 0) {
      window.scrollTo(0, window.scrollY);
    }
  };

  if (!window.__hatFinderVerticalScrollLockInstalled) {
    window.__hatFinderVerticalScrollLockInstalled = true;
    let touchStartX = 0;
    let touchStartY = 0;

    window.addEventListener('touchstart', (event) => {
      const touch = event.touches && event.touches[0];
      if (!touch) return;
      touchStartX = touch.clientX;
      touchStartY = touch.clientY;
    }, { passive: true });

    window.addEventListener('touchmove', (event) => {
      const touch = event.touches && event.touches[0];
      if (!touch) return;
      const dx = Math.abs(touch.clientX - touchStartX);
      const dy = Math.abs(touch.clientY - touchStartY);
      if (dx > dy + 4) {
        event.preventDefault();
      }
      clampHorizontalScroll();
    }, { passive: false });

    window.addEventListener('scroll', clampHorizontalScroll, { passive: true });
    window.addEventListener('resize', clampHorizontalScroll, { passive: true });
    window.setInterval(clampHorizontalScroll, 250);
  }

  clampHorizontalScroll();
})();
''';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() => _isLoading = true);
            }
          },
          onPageFinished: (_) async {
            await _lockWebViewToVerticalScrolling();
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
    unawaited(_controller.setHorizontalScrollBarEnabled(false));
    unawaited(_controller.setOverScrollMode(WebViewOverScrollMode.never));
    unawaited(
      _controller.setOnScrollPositionChange((position) {
        if (_isClampingHorizontalScroll || position.x.abs() < 0.5) {
          return;
        }
        _isClampingHorizontalScroll = true;
        _controller
            .scrollTo(0, position.y.round())
            .whenComplete(() => _isClampingHorizontalScroll = false);
      }),
    );
  }

  Future<void> _lockWebViewToVerticalScrolling() async {
    try {
      await _controller.runJavaScript(_verticalScrollLockScript);
      final position = await _controller.getScrollPosition();
      if (position.dx.abs() >= 0.5) {
        await _controller.scrollTo(0, position.dy.round());
      }
    } catch (error) {
      debugPrint(
          'Unable to lock storefront web view to vertical scroll: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D2926)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D2926),
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF559C99)),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(
            controller: _controller,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
              Factory<VerticalDragGestureRecognizer>(
                () => VerticalDragGestureRecognizer(),
              ),
            },
          ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF559C99),
              ),
            ),
        ],
      ),
    );
  }
}
