import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/shopify_service.dart';

/// Warm palette that complements the bronze logo lockup.
const Color kSplashBackground = Color(0xFF0F0C0A);
const Color kSplashGlow = Color(0xFF3A2D22);
const Color kSplashChampagne = Color(0xFFC9BBA8);
const Color kSplashCream = Color(0xFFF2EDE6);
const Color kSplashAccent = Color(0xFF7BA8A5);
const Color _dealerEmbossHighlight = Color(0xFFE4D8C8);
const Color _dealerEmbossShadow = Color(0xFF070504);

const String _logoAsset = 'assets/images/moon_ridge_logo.png';
const String _stetsonDealerLogo =
    'assets/images/dealers/stetson_authorized.png';
const String _resistolDealerLogo =
    'assets/images/dealers/resistol_authorized.png';
const double _stetsonDealerOpacity = 0.76;
const double _resistolDealerOpacity = 0.54;
const double _dealerLogoWidthFactor = 0.60;
const double _resistolDealerWidthFactor = 0.90;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const _prefsLaunchKey = 'has_launched_before';
  static const _returningDelayMs = 2800;
  static const _firstLaunchDelayMs = 4600;

  late final AnimationController _introController;
  late final AnimationController _exitController;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoLift;
  late final Animation<double> _headlineFade;
  late final Animation<Offset> _headlineSlide;
  late final Animation<double> _headlineScale;
  late final Animation<double> _dealerFade;
  late final Animation<Offset> _dealerSlide;
  late final Animation<double> _vignetteFade;
  late final Animation<double> _exitFade;

  @override
  void initState() {
    super.initState();
    ShopifyService.preloadWizardCatalog(includeFullCatalog: true);
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    final logoMotion = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.05, 0.78, curve: Curves.easeOutCubic),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.05, 0.45, curve: Curves.easeOut),
      ),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.68, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 72,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 28,
      ),
    ]).animate(logoMotion);

    _logoLift = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.05, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _vignetteFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _headlineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.48, 1.0, curve: Curves.easeOut),
      ),
    );

    _headlineSlide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.48, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _headlineScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.48, 1.0, curve: Curves.easeOutBack),
      ),
    );

    _dealerFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.62, 1.0, curve: Curves.easeOut),
      ),
    );

    _dealerSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.62, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeIn),
    );

    _introController.forward();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    final prefs = await SharedPreferences.getInstance();
    final isReturning = prefs.getBool(_prefsLaunchKey) ?? false;
    if (!isReturning) {
      await prefs.setBool(_prefsLaunchKey, true);
    }

    await Future.delayed(
      Duration(
        milliseconds: isReturning ? _returningDelayMs : _firstLaunchDelayMs,
      ),
    );

    if (!mounted) return;

    await _exitController.forward();
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AppShell(),
        transitionDuration: const Duration(milliseconds: 700),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoWidth = (size.width * 0.76).clamp(260.0, 340.0);
    final contentOpacity = _exitFade.value;

    return Scaffold(
      backgroundColor: kSplashBackground,
      body: AnimatedBuilder(
        animation: Listenable.merge([_introController, _exitController]),
        builder: (context, child) {
          return Opacity(
            opacity: contentOpacity,
            child: Transform.scale(
              scale: 1.0 + (1.0 - contentOpacity) * 0.04,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FadeTransition(
                    opacity: _vignetteFade,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.12),
                          radius: 1.05,
                          colors: [
                            kSplashGlow.withValues(alpha: 0.55),
                            const Color(0xFF1E1612),
                            kSplashBackground,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const Spacer(flex: 18),
                      FadeTransition(
                        opacity: _logoFade,
                        child: Transform.translate(
                          offset: Offset(0, _logoLift.value),
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: Image.asset(
                              _logoAsset,
                              width: logoWidth,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 12),
                      FadeTransition(
                        opacity: _headlineFade,
                        child: SlideTransition(
                          position: _headlineSlide,
                          child: Transform.scale(
                            scale: _headlineScale.value,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: Column(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 1,
                                    margin: const EdgeInsets.only(bottom: 18),
                                    color:
                                        kSplashAccent.withValues(alpha: 0.55),
                                  ),
                                  Text(
                                    'FIND YOUR',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: kSplashChampagne,
                                      letterSpacing: 5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'PERFECT HAT',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w700,
                                      color: kSplashCream,
                                      letterSpacing: 5.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 14),
                      FadeTransition(
                        opacity: _dealerFade,
                        child: SlideTransition(
                          position: _dealerSlide,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              28,
                              0,
                              28,
                              MediaQuery.paddingOf(context).bottom + 92,
                            ),
                            child: _buildAuthorizedDealerSection(logoWidth),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthorizedDealerSection(double referenceWidth) {
    final dealerLogoWidth =
        (referenceWidth * _dealerLogoWidthFactor).clamp(190.0, 250.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'AUTHORIZED DEALER:',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: kSplashChampagne.withValues(alpha: 0.8),
            letterSpacing: 2.4,
          ),
        ),
        const SizedBox(height: 16),
        _buildDealerLogo(
          assetPath: _stetsonDealerLogo,
          label: 'Stetson',
          width: dealerLogoWidth,
          opacity: _stetsonDealerOpacity,
        ),
        const SizedBox(height: 32),
        _buildDealerLogo(
          assetPath: _resistolDealerLogo,
          label: 'Resistol',
          width: dealerLogoWidth * _resistolDealerWidthFactor,
          opacity: _resistolDealerOpacity,
        ),
      ],
    );
  }

  Widget _buildDealerLogo({
    required String assetPath,
    required String label,
    required double width,
    double opacity = 1.0,
  }) {
    return Semantics(
      label: '$label authorized dealer',
      child: SizedBox(
        width: width,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Transform.translate(
              offset: const Offset(1.2, 1.4),
              child: _buildTintedDealerLogo(
                assetPath: assetPath,
                width: width,
                color: _dealerEmbossShadow,
                opacity: opacity * 0.34,
              ),
            ),
            Transform.translate(
              offset: const Offset(-0.9, -0.9),
              child: _buildTintedDealerLogo(
                assetPath: assetPath,
                width: width,
                color: _dealerEmbossHighlight,
                opacity: opacity * 0.30,
              ),
            ),
            Opacity(
              opacity: opacity,
              child: Image.asset(
                assetPath,
                width: width,
                fit: BoxFit.contain,
                alignment: Alignment.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTintedDealerLogo({
    required String assetPath,
    required double width,
    required Color color,
    required double opacity,
  }) {
    return Opacity(
      opacity: opacity,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: Image.asset(
          assetPath,
          width: width,
          fit: BoxFit.contain,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}
