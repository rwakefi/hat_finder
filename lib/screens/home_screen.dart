import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hat_input_screen.dart';
import 'head_shape_screen.dart';
import 'shop_webview_screen.dart';
import '../services/shopify_service.dart';
import '../widgets/home_social_links.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _espresso = Color(0xFF2D2926);
  static const Color _surface = Color(0xFFFAF8F5);

  /// Test branch: tap a layout chip above the carousel to compare options.
  HomeCarouselLayout _carouselLayout = HomeCarouselLayout.clean;

  @override
  void initState() {
    super.initState();
    ShopifyService.preloadWizardCatalog(includeFullCatalog: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.paddingOf(context).bottom;
          final heroHeight = _carouselLayout.heightFor(
            constraints.maxHeight,
            bottomInset,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SafeArea(
                  bottom: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Image.asset(
                            'assets/images/Moon Ridge Header Logo.png',
                            height: 118,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'FIND YOUR PERFECT HAT',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _espresso,
                            letterSpacing: 2.5,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Discover luxury hats tailored to your unique style and shape.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: _espresso.withValues(alpha: 0.62),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 28),
                        _OptionBlock(
                          icon: Icons.style_outlined,
                          label: 'SEARCH BY HAT TYPE',
                          caption: 'For those who know what style they want',
                          emphasized: true,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HatInputScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _OptionBlock(
                          icon: Icons.face_outlined,
                          label: 'LEARN YOUR HEAD SHAPE',
                          caption: 'For those who want a personalized fit',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const HeadShapeScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _OptionBlock(
                          icon: Icons.shopping_bag_outlined,
                          label: 'JUST TAKE ME TO THE HATS!',
                          caption: 'Browse the full Moon Ridge collection',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ShopWebViewScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _CarouselLayoutPicker(
                selected: _carouselLayout,
                onSelected: (layout) => setState(() => _carouselLayout = layout),
              ),
              _HomeHeroCarousel(
                height: heroHeight,
                layout: _carouselLayout,
              ),
            ],
          );
        },
      ),
    );
  }
}

enum HomeCarouselLayout {
  clean,
  inset,
  cinematic,
  classic;

  String get label => switch (this) {
        HomeCarouselLayout.clean => 'Clean',
        HomeCarouselLayout.inset => 'Inset',
        HomeCarouselLayout.cinematic => 'Cinematic',
        HomeCarouselLayout.classic => 'Classic',
      };

  double heightFor(double screenHeight, double bottomInset) {
    final fraction = switch (this) {
      HomeCarouselLayout.clean => 0.30,
      HomeCarouselLayout.inset => 0.28,
      HomeCarouselLayout.cinematic => 0.34,
      HomeCarouselLayout.classic => 0.26,
    };
    final minHeight = switch (this) {
      HomeCarouselLayout.cinematic => 190.0,
      HomeCarouselLayout.classic => 150.0,
      _ => 168.0,
    };
    final maxHeight = switch (this) {
      HomeCarouselLayout.cinematic => 240.0,
      HomeCarouselLayout.classic => 200.0,
      _ => 220.0,
    };
    return (screenHeight * fraction).clamp(minHeight, maxHeight) + bottomInset;
  }
}

List<_HomeHeroSlide> _slidesForLayout(HomeCarouselLayout layout) {
  return switch (layout) {
    HomeCarouselLayout.classic => _homeHeroClassicSlides,
    _ => _homeHeroLifestyleSlides,
  };
}

class _CarouselLayoutPicker extends StatelessWidget {
  const _CarouselLayoutPicker({
    required this.selected,
    required this.onSelected,
  });

  final HomeCarouselLayout selected;
  final ValueChanged<HomeCarouselLayout> onSelected;

  static const Color _espresso = Color(0xFF2D2926);
  static const Color _surface = Color(0xFFFAF8F5);
  static const Color _turquoise = Color(0xFF559C99);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'CAROUSEL TEST — tap a layout',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: _espresso.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: HomeCarouselLayout.values.map((layout) {
                final active = layout == selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(layout.label),
                    selected: active,
                    onSelected: (_) => onSelected(layout),
                    labelStyle: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: active ? Colors.white : _espresso,
                    ),
                    selectedColor: _turquoise,
                    backgroundColor: _surface,
                    side: BorderSide(
                      color: active
                          ? _turquoise
                          : _espresso.withValues(alpha: 0.18),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeroSlide {
  const _HomeHeroSlide(
    this.assetPath, {
    this.label,
    this.imageScale = 1.0,
    this.alignment = Alignment.center,
  });

  final String assetPath;
  final String? label;
  final double imageScale;
  final Alignment alignment;
}

const _homeHeroLifestyleSlides = [
  _HomeHeroSlide(
    'assets/images/home_carousel_western.jpg',
    label: 'Western',
  ),
  _HomeHeroSlide(
    'assets/images/home_carousel_outdoor.jpg',
    label: 'Outdoor',
    imageScale: 0.86,
    alignment: Alignment(0.0, -0.05),
  ),
  _HomeHeroSlide(
    'assets/images/home_carousel_city.jpg',
    label: 'City',
  ),
];

const _homeHeroClassicSlides = [
  _HomeHeroSlide('assets/images/home_carousel_western.jpg'),
  _HomeHeroSlide(
    'assets/images/home_carousel_outdoor.jpg',
    imageScale: 0.86,
    alignment: Alignment(0.0, -0.05),
  ),
  _HomeHeroSlide('assets/images/home_carousel_city.jpg'),
  _HomeHeroSlide(
    'assets/images/outdoor.png',
    imageScale: 0.86,
    alignment: Alignment(0.0, -0.05),
  ),
  _HomeHeroSlide(
    'assets/images/city.png',
    imageScale: 0.92,
    alignment: Alignment(0.0, -0.02),
  ),
];

class _HomeHeroCarousel extends StatefulWidget {
  const _HomeHeroCarousel({
    required this.height,
    required this.layout,
  });

  final double height;
  final HomeCarouselLayout layout;

  List<_HomeHeroSlide> get slides => _slidesForLayout(layout);

  @override
  State<_HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<_HomeHeroCarousel> {
  static const Color _espresso = Color(0xFF2D2926);
  static const Color _turquoise = Color(0xFF559C99);
  static const Color _surface = Color(0xFFFAF8F5);

  final PageController _pageController = PageController();
  Timer? _autoAdvance;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _autoAdvance = Timer.periodic(const Duration(seconds: 5), (_) => _advance());
  }

  @override
  void didUpdateWidget(covariant _HomeHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout != widget.layout) {
      _index = 0;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(0);
      }
    }
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _advance() {
    if (!mounted || !_pageController.hasClients) return;
    final count = widget.slides.length;
    if (count == 0) return;
    final next = (_index + 1) % count;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildSlideImage(_HomeHeroSlide slide, BoxConstraints constraints) {
    if (slide.imageScale >= 1.0) {
      return Image.asset(
        slide.assetPath,
        fit: BoxFit.cover,
        alignment: slide.alignment,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final overscale = 1 / slide.imageScale;
    return ClipRect(
      child: Align(
        alignment: slide.alignment,
        child: Image.asset(
          slide.assetPath,
          fit: BoxFit.cover,
          width: constraints.maxWidth * overscale,
          height: constraints.maxHeight * overscale,
        ),
      ),
    );
  }

  Widget? _buildSlideScrim() {
    return switch (widget.layout) {
      HomeCarouselLayout.clean => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.transparent,
                _espresso.withValues(alpha: 0.28),
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
      HomeCarouselLayout.inset => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                _espresso.withValues(alpha: 0.12),
                _espresso.withValues(alpha: 0.38),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      HomeCarouselLayout.cinematic => null,
      HomeCarouselLayout.classic => DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _espresso.withValues(alpha: 0.18),
                Colors.transparent,
                _espresso.withValues(alpha: 0.55),
              ],
              stops: const [0.0, 0.2, 1.0],
            ),
          ),
        ),
    };
  }

  Widget _buildCarouselBody({required double bottomInset}) {
    final scrim = _buildSlideScrim();
    final showSideGradient = widget.layout == HomeCarouselLayout.classic;
    final showBottomGradient = widget.layout != HomeCarouselLayout.cinematic;
    final bottomGradientHeight = switch (widget.layout) {
      HomeCarouselLayout.clean => 56.0,
      HomeCarouselLayout.inset => 64.0,
      HomeCarouselLayout.classic => 88.0,
      HomeCarouselLayout.cinematic => 0.0,
    };
    final bottomScrimStrength = switch (widget.layout) {
      HomeCarouselLayout.clean => (0.16, 0.32),
      HomeCarouselLayout.inset => (0.22, 0.42),
      HomeCarouselLayout.classic => (0.35, 0.62),
      HomeCarouselLayout.cinematic => (0.0, 0.0),
    };

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _index = i),
          itemCount: widget.slides.length,
          itemBuilder: (context, index) {
            final slide = widget.slides[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return _buildSlideImage(slide, constraints);
                  },
                ),
                if (scrim != null) scrim,
                if (slide.label != null)
                  Positioned(
                    left: 16,
                    bottom: 18 + bottomInset,
                    child: Text(
                      slide.label!.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: Colors.white.withValues(alpha: 0.92),
                        shadows: [
                          Shadow(
                            color: _espresso.withValues(alpha: 0.45),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        if (widget.layout != HomeCarouselLayout.inset)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: widget.layout == HomeCarouselLayout.cinematic ? 52 : 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _surface,
                    _surface.withValues(alpha: 0.75),
                    _surface.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        if (showBottomGradient)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bottomGradientHeight + bottomInset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    _espresso.withValues(alpha: bottomScrimStrength.$1),
                    _espresso.withValues(alpha: bottomScrimStrength.$2),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        if (showSideGradient)
          Positioned(
            right: 0,
            top: 0,
            bottom: bottomInset + 36,
            width: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    _espresso.withValues(alpha: 0.28),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: 6,
          top: 0,
          bottom: bottomInset + 36,
          child: const Center(
            child: HomeSocialLinks(
              layout: HomeSocialLinksLayout.carouselColumn,
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: bottomInset + 14,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.slides.length, (i) {
              final active = i == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? _turquoise
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final body = _buildCarouselBody(bottomInset: bottomInset);

    if (widget.layout == HomeCarouselLayout.inset) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: _espresso.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: SizedBox(height: widget.height, child: body),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: body,
    );
  }
}

class _OptionBlock extends StatelessWidget {
  const _OptionBlock({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;
  final bool emphasized;

  static const Color _espresso = Color(0xFF2D2926);
  static const Color _beige = Color(0xFFE8E4DA);
  static const Color _accent = Color(0xFF559C99);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: emphasized ? _beige : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: emphasized
                      ? _accent.withValues(alpha: 0.45)
                      : _espresso.withValues(alpha: 0.22),
                  width: emphasized ? 1.5 : 1,
                ),
                boxShadow: [
                  if (emphasized)
                    BoxShadow(
                      color: _espresso.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                child: Row(
                  children: [
                    Icon(
                      icon,
                      size: 24,
                      color: _espresso.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.montserrat(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: _espresso,
                          height: 1.25,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _espresso.withValues(alpha: 0.35),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  color: _espresso.withValues(alpha: 0.5),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
