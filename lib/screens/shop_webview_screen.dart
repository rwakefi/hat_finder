import 'dart:async';

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

  static const String _storefrontViewportScript = r'''
(() => {
  const styleId = 'hat-finder-storefront-viewport';
  let style = document.getElementById(styleId);
  if (!style) {
    style = document.createElement('style');
    style.id = styleId;
    document.head.appendChild(style);
  }
  style.textContent = `
    html, body {
      width: 100% !important;
      overflow-x: hidden !important;
      overscroll-behavior-x: none;
    }

    body {
      max-width: 100vw !important;
      position: relative;
    }

    main,
    #MainContent,
    .shopify-section {
      max-width: 100vw !important;
      overflow-x: hidden !important;
    }

    img,
    video,
    canvas,
    svg,
    iframe {
      max-width: 100%;
    }
  `;

  const viewport =
    document.querySelector('meta[name="viewport"]') ||
    document.head.appendChild(document.createElement('meta'));
  viewport.setAttribute('name', 'viewport');
  viewport.setAttribute(
    'content',
    'width=device-width, initial-scale=1, maximum-scale=5'
  );

  document.documentElement.scrollLeft = 0;
  document.body.scrollLeft = 0;
  if (window.scrollX !== 0) {
    window.scrollTo(0, window.scrollY);
  }
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
  }

  Future<void> _lockWebViewToVerticalScrolling() async {
    try {
      await _controller.runJavaScript(_storefrontViewportScript);
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
