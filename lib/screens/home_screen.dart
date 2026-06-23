import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../config/app_breakpoints.dart';
import '../config/app_config.dart';
import '../screens/shape_guide_screen.dart';
import '../services/shopify_service.dart';
import '../theme/moon_ridge_logo_sizes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onFindHat,
    required this.onFitGuide,
    required this.onShop,
  });

  final VoidCallback onFindHat;
  final VoidCallback onFitGuide;
  final VoidCallback onShop;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    ShopifyService.preloadWizardCatalog(includeFullCatalog: true);
  }

  Future<void> _openMoonRidgeStore() async {
    final uri = Uri.parse(AppConfig.publicStoreUrl);
    if (kIsWeb) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
      return;
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final mediaSize = MediaQuery.sizeOf(context);
    final screenHeight = mediaSize.height;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final isLargePhone = AppBreakpoints.isLargePhone(context);
    final tightViewport = screenHeight < 860 || mediaSize.width < 390;
    final largeText = textScale > 1.08;
    final compact = !isLargePhone && (tightViewport || largeText);
    final splitLayout = AppBreakpoints.useSplitHomeLayout(context);
    final isWideDesktop = AppBreakpoints.isWide(context);
    final nativeSplit = splitLayout && !kIsWeb;
    final isNativeTablet = AppBreakpoints.isNativeTablet(context);
    final nativeTabletStacked = isNativeTablet && !splitLayout;
    final heroHeight = splitLayout
        ? double.infinity
        : nativeTabletStacked
            ? (screenHeight * 0.44).clamp(340.0, 520.0)
            : (screenHeight * (compact ? 0.28 : 0.36))
                .clamp(compact ? 190.0 : 240.0, compact ? 246.0 : 320.0);
    final logoHeight = isLargePhone
        ? (screenHeight * 0.102).clamp(
            MoonRidgeLogoSizes.homeProMax,
            112.0,
          )
        : tightViewport
            ? MoonRidgeLogoSizes.homeCompactTight
            : (largeText
                ? MoonRidgeLogoSizes.homeCompact
                : (isWideDesktop
                    ? MoonRidgeLogoSizes.homeWide
                    : MoonRidgeLogoSizes.homeDefault));
    final buttonGap = compact ? 10.0 : (isWideDesktop ? 18.0 : 16.0);
    final footerLogoGap = isLargePhone
        ? 20.0
        : tightViewport
            ? 10.0
            : (largeText ? 18.0 : (splitLayout ? 24.0 : 16.0));
    final actionsBottomPadding = compact ? 28.0 : 12.0;
    final centerFooterLogo = !splitLayout && !nativeTabletStacked;
    final heroFlex = isWideDesktop ? 12 : (isNativeTablet ? 11 : 11);
    final actionsFlex = isWideDesktop ? 10 : (isNativeTablet ? 12 : 9);
    final webSplit = splitLayout && kIsWeb;

    Widget buildHeroClip(Widget child) {
      if (webSplit) return child;
      if (nativeSplit) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: child,
        );
      }
      if (nativeTabletStacked) {
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(28),
            bottomRight: Radius.circular(28),
          ),
          child: child,
        );
      }
      return ClipPath(
        clipper: _WaveBottomClipper(),
        child: child,
      );
    }

    Widget buildFooterLogo({double? maxHeight, bool tabletFooter = false}) {
      if (tabletFooter) {
        final height = maxHeight ?? MoonRidgeLogoSizes.homeTabletFooter;
        return _HomeFooterBrand(
          onTap: _openMoonRidgeStore,
          height: height,
        );
      }

      final base = maxHeight == null
          ? logoHeight
          : logoHeight.clamp(48.0, maxHeight * 0.75);
      final height = base * 1.1;
      return Semantics(
        button: true,
        label: 'Visit Moon Ridge website',
        child: GestureDetector(
          onTap: _openMoonRidgeStore,
          behavior: HitTestBehavior.opaque,
          child: Image.asset(
            'assets/images/Moon Ridge Header Logo.png',
            height: maxHeight == null ? height : height.clamp(48.0, maxHeight),
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    Widget buildHeroStack() {
      return Stack(
        fit: StackFit.expand,
        children: [
          const _RotatingPhotos(photos: _homePhotos),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _HomePalette.espresso.withValues(
                    alpha: nativeSplit || nativeTabletStacked ? 0.42 : 0.35,
                  ),
                  Colors.transparent,
                  _HomePalette.espresso.withValues(
                    alpha: nativeSplit || nativeTabletStacked ? 0.55 : 0.45,
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, compact ? 24 : 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HomeHeadline(
                    light: true,
                    heroTop: true,
                    compact: compact,
                    enlarged: nativeSplit || nativeTabletStacked,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final hero = SizedBox(
      height: splitLayout ? double.infinity : heroHeight,
      child: buildHeroClip(buildHeroStack()),
    );

    final List<Widget> mobileButtonChildren = [
      _OptionBlock(
        icon: Icons.style_outlined,
        label: 'SEARCH BY HAT TYPE',
        emphasized: true,
        onTap: widget.onFindHat,
        compact: compact,
      ),
      SizedBox(height: buttonGap),
      _OptionBlock(
        icon: Icons.face_outlined,
        label: 'LEARN YOUR HEAD SHAPE',
        onTap: widget.onFitGuide,
        compact: compact,
      ),
      SizedBox(height: buttonGap),
      _OptionBlock(
        icon: Icons.shopping_bag_outlined,
        label: 'JUST TAKE ME TO THE HATS!',
        onTap: widget.onShop,
        compact: compact,
      ),
      SizedBox(height: buttonGap),
      _HomeSecondaryActions(
        rowGap: buttonGap,
        columnGap: splitLayout ? (isWideDesktop ? 14 : 12) : 12,
        relaxed: splitLayout,
        onMeasure: () => _showVideoModal(context),
        onVirtualMeasure: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Coming soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        onCrownGuide: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ShapeGuideScreen.crown(),
            ),
          );
        },
        onBrimGuide: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ShapeGuideScreen.brim(),
            ),
          );
        },
      ),
    ];

    final nativeActionsPanel = (nativeSplit || nativeTabletStacked)
        ? _NativeSplitHomeActions(
            onFindHat: widget.onFindHat,
            onFitGuide: widget.onFitGuide,
            onShop: widget.onShop,
            onMeasure: () => _showVideoModal(context),
            onVirtualMeasure: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            onCrownGuide: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ShapeGuideScreen.crown(),
                ),
              );
            },
            onBrimGuide: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ShapeGuideScreen.brim(),
                ),
              );
            },
            footerLogo: buildFooterLogo(
              tabletFooter: nativeTabletStacked || nativeSplit,
            ),
            spacious: isNativeTablet || isWideDesktop,
          )
        : null;

    final actionChildren = <Widget>[
      ...mobileButtonChildren,
      if (!centerFooterLogo && nativeActionsPanel == null) ...[
        SizedBox(
            height: splitLayout ? (isWideDesktop ? 28 : 24) : footerLogoGap),
        Center(child: buildFooterLogo()),
      ],
    ];

    Widget buildMobileActions() {
      return CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: mobileButtonChildren,
              ),
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: buildFooterLogo(),
              ),
            ),
          ),
        ],
      );
    }

    final actions = centerFooterLogo
        ? buildMobileActions()
        : LayoutBuilder(
            builder: (context, constraints) {
              final pad = EdgeInsets.fromLTRB(
                nativeSplit || nativeTabletStacked
                    ? 28
                    : (isWideDesktop ? 32 : 24),
                splitLayout
                    ? (nativeSplit ? 32 : (isWideDesktop ? 40 : 28))
                    : (nativeTabletStacked ? 20 : 16),
                nativeSplit || nativeTabletStacked
                    ? 28
                    : (isWideDesktop ? 32 : 24),
                actionsBottomPadding,
              );
              return SingleChildScrollView(
                padding: pad,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - pad.vertical,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      nativeActionsPanel ??
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: actionChildren,
                          ),
                    ],
                  ),
                ),
              );
            },
          );

    if (nativeTabletStacked) {
      return ColoredBox(
        color: _HomePalette.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            hero,
            Expanded(child: actions),
          ],
        ),
      );
    }

    if (webSplit) {
      return _WebHomeSplit(
        hero: hero,
        heroFlex: heroFlex,
        actionsFlex: actionsFlex,
        isWideDesktop: isWideDesktop,
        actionChildren: actionChildren,
      );
    }

    return ColoredBox(
      color: _HomePalette.surface,
      child: splitLayout
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: heroFlex,
                        child: Padding(
                          padding: nativeSplit
                              ? const EdgeInsets.fromLTRB(12, 12, 0, 12)
                              : EdgeInsets.zero,
                          child: hero,
                        ),
                      ),
                      Expanded(flex: actionsFlex, child: actions),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                hero,
                Expanded(child: actions),
              ],
            ),
    );
  }
}

/// Centered, bounded hero+actions card for laptop/desktop web.
class _WebHomeSplit extends StatelessWidget {
  const _WebHomeSplit({
    required this.hero,
    required this.heroFlex,
    required this.actionsFlex,
    required this.isWideDesktop,
    required this.actionChildren,
  });

  final Widget hero;
  final int heroFlex;
  final int actionsFlex;
  final bool isWideDesktop;
  final List<Widget> actionChildren;

  @override
  Widget build(BuildContext context) {
    final outerPadding = isWideDesktop ? 48.0 : 28.0;

    return ColoredBox(
      color: _HomePalette.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight;
          // Keep the card from getting so tall the hero crops the headline.
          final cardHeight =
              (availableHeight - outerPadding * 2).clamp(420.0, 760.0);

          final card = ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWideDesktop ? 1180 : 1000,
              maxHeight: cardHeight,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _HomePalette.espresso.withValues(alpha: 0.10),
                    blurRadius: 44,
                    spreadRadius: -8,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: heroFlex, child: hero),
                    Expanded(
                      flex: actionsFlex,
                      child: _WebActionsPanel(
                        isWideDesktop: isWideDesktop,
                        children: actionChildren,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          return Center(
            child: Padding(
              padding: EdgeInsets.all(outerPadding),
              child: card,
            ),
          );
        },
      ),
    );
  }
}

class _WebActionsPanel extends StatelessWidget {
  const _WebActionsPanel({
    required this.isWideDesktop,
    required this.children,
  });

  final bool isWideDesktop;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _HomePalette.surface,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isWideDesktop ? 44 : 32,
            vertical: 32,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWideDesktop ? 420 : 380),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

void _showVideoModal(BuildContext context) {
  const videoId = 'URwlW5-5CV8';
  final youtubeUri = Uri.parse('https://www.youtube.com/watch?v=$videoId');

  if (kIsWeb) {
    unawaited(
      launchUrl(
        youtubeUri,
        webOnlyWindowName: '_blank',
        mode: LaunchMode.externalApplication,
      ),
    );
    return;
  }

  const htmlString = '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <style>
        body { margin: 0; padding: 0; background-color: #1C1917; display: flex; justify-content: center; align-items: center; height: 100vh; width: 100vw; overflow: hidden; }
        #player { width: 100%; height: 56.25vw; max-height: 100vh; }
      </style>
    </head>
    <body>
      <div id="player"></div>
      <script>
        var tag = document.createElement('script');
        tag.src = "https://www.youtube.com/iframe_api";
        var firstScriptTag = document.getElementsByTagName('script')[0];
        firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

        var player;
        function onYouTubeIframeAPIReady() {
          player = new YT.Player('player', {
            videoId: '$videoId',
            playerVars: {
              'playsinline': 1,
              'rel': 0,
              'enablejsapi': 1,
              'origin': 'https://moonridgecompany.com'
            }
          });
        }
      </script>
    </body>
    </html>
  ''';

  late final PlatformWebViewControllerCreationParams params;
  if (WebViewPlatform.instance is WebKitWebViewPlatform) {
    params = WebKitWebViewControllerCreationParams(
      allowsInlineMediaPlayback: true,
      mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
    );
  } else {
    params = const PlatformWebViewControllerCreationParams();
  }

  final controller = WebViewController.fromPlatformCreationParams(params)
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..loadHtmlString(htmlString, baseUrl: 'https://moonridgecompany.com');

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      height: MediaQuery.sizeOf(context).height * 0.55,
      decoration: const BoxDecoration(
        color: Color(0xFF1C1917),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'HOW TO MEASURE FOR HAT SIZE',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white60),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: WebViewWidget(controller: controller),
            ),
          ),
        ],
      ),
    ),
  );
}

abstract final class _HomePalette {
  static const espresso = Color(0xFF2D2926);
  static const surface = Color(0xFFFAF8F5);
  static const beige = Color(0xFFE8E4DA);
  static const turquoise = Color(0xFF559C99);
}

class _HomePhoto {
  const _HomePhoto(
    this.assetPath, {
    this.imageScale = 1.0,
    this.alignment = Alignment.center,
  });

  final String assetPath;
  final double imageScale;
  final Alignment alignment;
}

const _homePhotos = [
  _HomePhoto('assets/images/home_carousel_western.jpg'),
  _HomePhoto(
    'assets/images/home_carousel_outdoor.jpg',
    imageScale: 0.86,
    alignment: Alignment(0.0, -0.05),
  ),
  _HomePhoto('assets/images/home_carousel_city.jpg'),
];

class _HomeHeadline extends StatelessWidget {
  const _HomeHeadline({
    this.light = false,
    this.heroTop = false,
    this.compact = false,
    this.enlarged = false,
  });

  final bool light;
  final bool heroTop;
  final bool compact;
  final bool enlarged;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : _HomePalette.espresso;
    final subColor = light
        ? Colors.white.withValues(alpha: 0.82)
        : _HomePalette.espresso.withValues(alpha: 0.62);
    final titleSize = heroTop
        ? (enlarged ? 32.0 : (compact ? 24.0 : 28.0))
        : 22.0;
    final subSize = heroTop
        ? (enlarged ? 16.0 : (compact ? 13.0 : 15.0))
        : 14.0;

    return Column(
      children: [
        Text(
          'FIND YOUR PERFECT HAT',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: heroTop ? 2.0 : 2.5,
            height: 1.2,
          ),
        ),
        SizedBox(height: heroTop ? (compact ? 8 : 10) : 12),
        Text(
          'Discover luxury hats tailored to your unique style and shape.',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: subSize,
            fontWeight: FontWeight.w400,
            color: subColor,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _RotatingPhotos extends StatefulWidget {
  const _RotatingPhotos({required this.photos});

  final List<_HomePhoto> photos;

  @override
  State<_RotatingPhotos> createState() => _RotatingPhotosState();
}

class _RotatingPhotosState extends State<_RotatingPhotos> {
  Timer? _autoAdvance;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _autoAdvance =
        Timer.periodic(const Duration(seconds: 7), (_) => _advance());
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    super.dispose();
  }

  void _advance() {
    if (!mounted || widget.photos.isEmpty) return;
    setState(() => _index = (_index + 1) % widget.photos.length);
  }

  Widget _photoImage(_HomePhoto photo, BoxConstraints constraints) {
    if (photo.imageScale >= 1.0) {
      return Image.asset(
        photo.assetPath,
        fit: BoxFit.cover,
        alignment: photo.alignment,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final overscale = 1 / photo.imageScale;
    return ClipRect(
      child: Align(
        alignment: photo.alignment,
        child: Image.asset(
          photo.assetPath,
          fit: BoxFit.cover,
          width: constraints.maxWidth * overscale,
          height: constraints.maxHeight * overscale,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    return Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 1400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              fit: StackFit.expand,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: LayoutBuilder(
            key: ValueKey(_index),
            builder: (context, constraints) {
              return _photoImage(photo, constraints);
            },
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.photos.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? _HomePalette.turquoise
                      : Colors.white.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _WaveBottomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 28)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + 12,
        size.width,
        size.height - 28,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _HomeFooterBrand extends StatelessWidget {
  const _HomeFooterBrand({
    required this.onTap,
    required this.height,
  });

  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: _HomePalette.espresso.withValues(alpha: 0.1),
        ),
        const SizedBox(height: 14),
        Semantics(
          button: true,
          label: 'Visit Moon Ridge website',
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Image.asset(
                'assets/images/moon_ridge_logo_home.png',
                height: height,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NativeSplitHomeActions extends StatelessWidget {
  const _NativeSplitHomeActions({
    required this.onFindHat,
    required this.onFitGuide,
    required this.onShop,
    required this.onMeasure,
    required this.onVirtualMeasure,
    required this.onCrownGuide,
    required this.onBrimGuide,
    required this.footerLogo,
    required this.spacious,
  });

  final VoidCallback onFindHat;
  final VoidCallback onFitGuide;
  final VoidCallback onShop;
  final VoidCallback onMeasure;
  final VoidCallback onVirtualMeasure;
  final VoidCallback onCrownGuide;
  final VoidCallback onBrimGuide;
  final Widget footerLogo;
  final bool spacious;

  @override
  Widget build(BuildContext context) {
    final gap = spacious ? 13.0 : 12.0;
    final tileGap = spacious ? 10.0 : 10.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'START HERE',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
            color: _HomePalette.espresso.withValues(alpha: 0.45),
          ),
        ),
        SizedBox(height: gap - 4),
        _FeaturedHomeAction(
          title: 'Search by Hat Type',
          subtitle: 'Felt, straw, style, crown, brim & size',
          icon: Icons.style_outlined,
          onTap: onFindHat,
          spacious: spacious,
        ),
        SizedBox(height: gap),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CompactHomeAction(
                title: 'Learn Your\nHead Shape',
                icon: Icons.face_outlined,
                onTap: onFitGuide,
                spacious: spacious,
              ),
            ),
            SizedBox(width: tileGap),
            Expanded(
              child: _CompactHomeAction(
                title: 'Browse\nAll Hats',
                icon: Icons.shopping_bag_outlined,
                onTap: onShop,
                spacious: spacious,
                accent: true,
              ),
            ),
          ],
        ),
        SizedBox(height: gap + 2),
        Text(
          'GUIDES & TOOLS',
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.4,
            color: _HomePalette.espresso.withValues(alpha: 0.45),
          ),
        ),
        SizedBox(height: gap - 2),
        Row(
          children: [
            Expanded(
              child: _GuideTile(
                icon: Icons.play_circle_outline_rounded,
                label: 'How to Measure',
                onTap: onMeasure,
                spacious: spacious,
              ),
            ),
            SizedBox(width: tileGap),
            Expanded(
              child: _GuideTile(
                icon: Icons.straighten_outlined,
                label: 'Virtual Measure',
                onTap: onVirtualMeasure,
                spacious: spacious,
              ),
            ),
          ],
        ),
        SizedBox(height: tileGap),
        Row(
          children: [
            Expanded(
              child: _GuideTile(
                icon: Icons.layers_outlined,
                label: 'Crown Shapes',
                onTap: onCrownGuide,
                spacious: spacious,
              ),
            ),
            SizedBox(width: tileGap),
            Expanded(
              child: _GuideTile(
                icon: Icons.border_horizontal,
                label: 'Brim Shapes',
                onTap: onBrimGuide,
                spacious: spacious,
              ),
            ),
          ],
        ),
        SizedBox(height: spacious ? 18 : 14),
        footerLogo,
      ],
    );
  }
}

class _FeaturedHomeAction extends StatelessWidget {
  const _FeaturedHomeAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.spacious,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool spacious;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _HomePalette.beige,
                  _HomePalette.beige.withValues(alpha: 0.72),
                ],
              ),
              border: Border.all(
                color: _HomePalette.turquoise.withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _HomePalette.espresso.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacious ? 18 : 18,
                vertical: spacious ? 17 : 18,
              ),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(spacious ? 11 : 14),
                      child: Icon(
                        icon,
                        size: spacious ? 25 : 24,
                        color: _HomePalette.turquoise,
                      ),
                    ),
                  ),
                  SizedBox(width: spacious ? 14 : 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: spacious ? 15 : 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: _HomePalette.espresso,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: spacious ? 4 : 6),
                        Text(
                          subtitle,
                          style: GoogleFonts.montserrat(
                            fontSize: spacious ? 12 : 12,
                            fontWeight: FontWeight.w500,
                            color: _HomePalette.espresso.withValues(alpha: 0.62),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: _HomePalette.espresso.withValues(alpha: 0.35),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactHomeAction extends StatelessWidget {
  const _CompactHomeAction({
    required this.title,
    required this.icon,
    required this.onTap,
    required this.spacious,
    this.accent = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool spacious;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title.replaceAll('\n', ' '),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: spacious ? 14 : 14,
              vertical: spacious ? 15 : 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: accent
                    ? _HomePalette.turquoise.withValues(alpha: 0.35)
                    : _HomePalette.espresso.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: spacious ? 23 : 22,
                  color: accent
                      ? _HomePalette.turquoise
                      : _HomePalette.espresso.withValues(alpha: 0.65),
                ),
                SizedBox(height: spacious ? 10 : 10),
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.montserrat(
                    fontSize: spacious ? 11.5 : 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _HomePalette.espresso,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GuideTile extends StatelessWidget {
  const _GuideTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.spacious,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool spacious;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: _HomePalette.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              vertical: spacious ? 13 : 14,
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _HomePalette.espresso.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: spacious ? 22 : 22,
                  color: _HomePalette.turquoise,
                ),
                SizedBox(height: spacious ? 7 : 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: spacious ? 12 : 11,
                    fontWeight: FontWeight.w600,
                    color: _HomePalette.espresso.withValues(alpha: 0.78),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionBlock extends StatelessWidget {
  const _OptionBlock({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: emphasized ? _HomePalette.beige : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: emphasized
                  ? _HomePalette.turquoise.withValues(alpha: 0.45)
                  : _HomePalette.espresso.withValues(alpha: 0.22),
              width: emphasized ? 1.5 : 1,
            ),
            boxShadow: [
              if (emphasized)
                BoxShadow(
                  color: _HomePalette.espresso.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: compact ? 14 : 16,
              horizontal: 18,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: compact ? 22 : 24,
                  color: _HomePalette.espresso.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: compact ? 14 : 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: _HomePalette.espresso,
                      height: 1.25,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: _HomePalette.espresso.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSecondaryActions extends StatelessWidget {
  const _HomeSecondaryActions({
    required this.rowGap,
    required this.columnGap,
    required this.relaxed,
    required this.onMeasure,
    required this.onVirtualMeasure,
    required this.onCrownGuide,
    required this.onBrimGuide,
  });

  final double rowGap;
  final double columnGap;
  final bool relaxed;
  final VoidCallback onMeasure;
  final VoidCallback onVirtualMeasure;
  final VoidCallback onCrownGuide;
  final VoidCallback onBrimGuide;

  @override
  Widget build(BuildContext context) {
    Widget row(List<Widget> children) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: children[0]),
            SizedBox(width: columnGap),
            Expanded(child: children[1]),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row([
          _SmallBubble(
            icon: Icons.play_circle_outline_rounded,
            label: 'How to Measure\nfor Hat Size',
            onTap: onMeasure,
            relaxed: relaxed,
          ),
          _SmallBubble(
            icon: Icons.straighten_outlined,
            label: 'Virtual Head\nMeasurement',
            onTap: onVirtualMeasure,
            relaxed: relaxed,
          ),
        ]),
        SizedBox(height: rowGap),
        row([
          _SmallBubble(
            icon: Icons.layers_outlined,
            label: 'Learn About\nCrown Shape',
            onTap: onCrownGuide,
            relaxed: relaxed,
          ),
          _SmallBubble(
            icon: Icons.border_horizontal,
            label: 'Learn About\nBrim Shape',
            onTap: onBrimGuide,
            relaxed: relaxed,
          ),
        ]),
      ],
    );
  }
}

class _SmallBubble extends StatelessWidget {
  const _SmallBubble({
    required this.icon,
    required this.label,
    required this.onTap,
    this.relaxed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool relaxed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _HomePalette.espresso.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: relaxed ? 16 : 14,
              horizontal: relaxed ? 16 : 14,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: relaxed ? 22 : 20,
                  color: _HomePalette.turquoise,
                ),
                SizedBox(width: relaxed ? 12 : 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.montserrat(
                      fontSize: relaxed ? 13 : 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: relaxed ? 0.35 : 0.5,
                      color: _HomePalette.espresso,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
