import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/shopify_service.dart';

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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final compact = screenHeight < 860;
    final heroHeight = (screenHeight * (compact ? 0.30 : 0.36))
        .clamp(compact ? 200.0 : 240.0, compact ? 270.0 : 320.0);
    final logoHeight = compact ? 88.0 : 118.0;
    final buttonGap = compact ? 12.0 : 16.0;

    return ColoredBox(
      color: _HomePalette.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: heroHeight,
            child: ClipPath(
              clipper: _WaveBottomClipper(),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const _RotatingPhotos(photos: _homePhotos),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          _HomePalette.espresso.withValues(alpha: 0.35),
                          Colors.transparent,
                          _HomePalette.espresso.withValues(alpha: 0.45),
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
                          _HomeHeadline(light: true, heroTop: true, compact: compact),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OptionBlock(
                    icon: Icons.style_outlined,
                    label: 'SEARCH BY HAT TYPE',
                    caption: 'For those who know what style they want',
                    emphasized: true,
                    onTap: widget.onFindHat,
                    compact: compact,
                  ),
                  SizedBox(height: buttonGap),
                  _OptionBlock(
                    icon: Icons.face_outlined,
                    label: 'LEARN YOUR HEAD SHAPE',
                    caption: 'For those who want a personalized fit',
                    onTap: widget.onFitGuide,
                    compact: compact,
                  ),
                  SizedBox(height: buttonGap),
                  _OptionBlock(
                    icon: Icons.shopping_bag_outlined,
                    label: 'JUST TAKE ME TO THE HATS!',
                    caption: 'Browse the full Moon Ridge collection',
                    onTap: widget.onShop,
                    compact: compact,
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: compact ? 20 : 28),
                    child: Center(
                      child: Image.asset(
                        'assets/images/Moon Ridge Header Logo.png',
                        height: logoHeight,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
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
  });

  final bool light;
  final bool heroTop;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = light ? Colors.white : _HomePalette.espresso;
    final subColor = light
        ? Colors.white.withValues(alpha: 0.82)
        : _HomePalette.espresso.withValues(alpha: 0.62);
    final titleSize = heroTop ? (compact ? 24.0 : 28.0) : 22.0;
    final subSize = heroTop ? (compact ? 13.0 : 15.0) : 14.0;

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
    if (!mounted || !_pageController.hasClients || widget.photos.isEmpty) {
      return;
    }
    final next = (_index + 1) % widget.photos.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOut,
    );
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
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (i) => setState(() => _index = i),
          itemCount: widget.photos.length,
          itemBuilder: (context, index) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return _photoImage(widget.photos[index], constraints);
              },
            );
          },
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
                duration: const Duration(milliseconds: 220),
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

class _OptionBlock extends StatelessWidget {
  const _OptionBlock({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
    this.emphasized = false,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final String caption;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
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
            SizedBox(height: compact ? 6 : 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                caption,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: compact ? 12 : 13,
                  color: _HomePalette.espresso.withValues(alpha: 0.5),
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
