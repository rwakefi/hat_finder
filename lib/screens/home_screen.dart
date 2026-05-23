import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hat_input_screen.dart';
import 'head_shape_screen.dart';
import 'shop_webview_screen.dart';
import '../services/shopify_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _espresso = Color(0xFF2D2926);
  static const Color _surface = Color(0xFFFAF8F5);

  @override
  void initState() {
    super.initState();
    ShopifyService.preloadWizardCatalog();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.paddingOf(context).bottom;
          final heroHeight =
              (constraints.maxHeight * 0.26).clamp(150.0, 200.0) + bottomInset;

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
              _HomeHeroCarousel(height: heroHeight),
            ],
          );
        },
      ),
    );
  }
}

class _HomeHeroSlide {
  const _HomeHeroSlide(this.assetPath, this.label);

  final String assetPath;
  final String label;
}

class _HomeHeroCarousel extends StatefulWidget {
  const _HomeHeroCarousel({required this.height});

  final double height;

  static const List<_HomeHeroSlide> _slides = [
    _HomeHeroSlide('assets/images/home_carousel_western.jpg', 'Western'),
    _HomeHeroSlide('assets/images/outdoor.png', 'Outdoor'),
    _HomeHeroSlide('assets/images/city.png', 'City'),
    _HomeHeroSlide('assets/images/red_rocks.webp', 'Red rocks'),
    _HomeHeroSlide('assets/images/straw_hat.jpg', 'Straw'),
  ];

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
  void dispose() {
    _autoAdvance?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _advance() {
    if (!mounted || !_pageController.hasClients) return;
    final next = (_index + 1) % _HomeHeroCarousel._slides.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _surface,
        border: Border(
          top: BorderSide(
            color: _espresso.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: _espresso.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: _HomeHeroCarousel._slides.length,
            itemBuilder: (context, index) {
              final slide = _HomeHeroCarousel._slides[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    slide.assetPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _espresso.withValues(alpha: 0.18),
                          Colors.transparent,
                          _espresso.withValues(alpha: 0.42),
                        ],
                        stops: const [0.0, 0.22, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: bottomInset + 28,
                    child: Text(
                      slide.label.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_HomeHeroCarousel._slides.length, (i) {
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
        ),
      ),
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
