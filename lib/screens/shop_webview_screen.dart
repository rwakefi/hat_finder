import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../widgets/shell_tab_bar_footer.dart';

/// In-app storefront browser on iOS/Android; opens a new browser tab on web.
class ShopWebViewScreen extends StatelessWidget {
  final String url;
  final String title;
  final VoidCallback? onBack;
  final bool hideHeaderFooter;
  final int selectedIndex;

  const ShopWebViewScreen({
    super.key,
    this.url = 'https://moonridgecompany.com',
    this.title = 'Moon Ridge Shop',
    this.onBack,
    this.hideHeaderFooter = false,
    this.selectedIndex = 3,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _WebStorefrontLauncher(
        url: url,
        title: title,
        onBack: onBack,
        selectedIndex: selectedIndex,
      );
    }
    return _MobileShopWebViewScreen(
      url: url,
      title: title,
      onBack: onBack,
      hideHeaderFooter: hideHeaderFooter,
      selectedIndex: selectedIndex,
    );
  }
}

class _MobileShopWebViewScreen extends StatefulWidget {
  const _MobileShopWebViewScreen({
    required this.url,
    required this.title,
    this.onBack,
    required this.hideHeaderFooter,
    required this.selectedIndex,
  });

  final String url;
  final String title;
  final VoidCallback? onBack;
  final bool hideHeaderFooter;
  final int selectedIndex;

  @override
  State<_MobileShopWebViewScreen> createState() =>
      _MobileShopWebViewScreenState();
}

class _MobileShopWebViewScreenState extends State<_MobileShopWebViewScreen> {
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

  static const String _hideHeaderFooterScript = r'''
(() => {
  const styleId = 'hat-finder-hide-header-footer';
  let style = document.getElementById(styleId);
  if (!style) {
    style = document.createElement('style');
    style.id = styleId;
    document.head.appendChild(style);
  }
  style.textContent = `
    .shopify-section-group-header-group,
    #shopify-section-announcement-bar,
    .announcement-bar,
    div[class*="announcement-bar"],
    header,
    .header-wrapper,
    #shopify-section-header,
    
    .rm-brand-promo-btn,
    .rm-brand-switcher,
    div[class*="brand-switcher"],
    div[class*="brand-promo"],
    .header__mobile-cta,
    
    .shopify-section-group-footer-group,
    footer,
    .footer,
    #shopify-section-footer,
    div[class*="footer"],
    
    #dummy-chat-button-iframe,
    iframe#dummy-chat-button-iframe,
    iframe[src*="shopify-chat"],
    .shopify-chat,
    #shopify-chat,
    #chat-button,
    #shopify-inbox {
      display: none !important;
    }
    
    body, #MainContent, main {
      padding-top: 0 !important;
      margin-top: 0 !important;
    }
    
    body, html, main, #MainContent, .events-directory, .shopify-section {
      background-color: #1C1917 !important;
    }
    
    .events-video-banner__bg video {
      filter: brightness(0.5) !important;
      -webkit-filter: brightness(0.5) !important;
    }
    .events-video-banner__overlay {
      z-index: 2 !important;
      transform: translateZ(0) !important;
      -webkit-transform: translate3d(0,0,0) !important;
    }
  `;
})();
''';

  @override
  void initState() {
    super.initState();

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
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
      if (widget.hideHeaderFooter) {
        await _controller.runJavaScript(_hideHeaderFooterScript);
      }
    } catch (error) {
      debugPrint(
          'Unable to lock storefront web view to vertical scroll: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final showShellNav = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D2926)),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
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
      bottomNavigationBar: showShellNav
          ? ShellTabBarFooter(selectedIndex: widget.selectedIndex)
          : null,
    );
  }
}

class _WebStorefrontLauncher extends StatefulWidget {
  const _WebStorefrontLauncher({
    required this.url,
    required this.title,
    this.onBack,
    required this.selectedIndex,
  });

  final String url;
  final String title;
  final VoidCallback? onBack;
  final int selectedIndex;

  @override
  State<_WebStorefrontLauncher> createState() => _WebStorefrontLauncherState();
}

class _WebStorefrontLauncherState extends State<_WebStorefrontLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    final launched = await launchUrl(
      Uri.parse(widget.url),
      webOnlyWindowName: '_blank',
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the shop page.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showShellNav = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D2926)),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
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
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.open_in_new, size: 48, color: Color(0xFF559C99)),
              const SizedBox(height: 20),
              Text(
                'Opening in your browser…',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D2926),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'If a new tab did not open, use the button below.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  height: 1.5,
                  color: const Color(0xFF2D2926).withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _open,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF559C99),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                child: Text(
                  'OPEN PRODUCT PAGE',
                  style: GoogleFonts.montserrat(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: showShellNav
          ? ShellTabBarFooter(selectedIndex: widget.selectedIndex)
          : null,
    );
  }
}
