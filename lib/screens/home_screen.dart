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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 44),
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
                      label: 'SEARCH BY HAT SHAPE',
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
                      label: 'SEARCH BY HEAD SHAPE',
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
                      label: 'BALLCAPS! Or Just Go Shopping',
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
            );
          },
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
