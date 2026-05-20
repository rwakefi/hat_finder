import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hat_input_screen.dart';
import 'head_shape_screen.dart';
import 'shop_webview_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final logoHeight = (constraints.maxHeight * 0.20).clamp(90.0, 160.0);

          return Container(
            color: Colors.white,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ── Logo ──
                    const Spacer(flex: 2),
                    Image.asset(
                      'assets/images/Moon Ridge Header Logo.png',
                      height: logoHeight,
                    ),

                    // ── Headline ──
                    const Spacer(flex: 1),
                    Text(
                      'FIND YOUR\nPERFECT HAT',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D2926),
                        letterSpacing: 4,
                        height: 1.3,
                      ),
                    ),

                    // ── Tagline ──
                    const Spacer(flex: 1),
                    Text(
                      'Discover luxury hats tailored to your unique style and shape.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: const Color(0xFF2D2926).withOpacity(0.65),
                        height: 1.6,
                        letterSpacing: 0.3,
                      ),
                    ),

                    // ── Option Cards ──
                    const Spacer(flex: 2),
                    _buildOptionCard(
                      context: context,
                      icon: Icons.style_outlined,
                      label: 'SEARCH BY HAT SHAPE',
                      caption: 'For those who know what style they want',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const HatInputScreen()),
                      ),
                    ),
                    const Spacer(flex: 2),
                    _buildOptionCard(
                      context: context,
                      icon: Icons.face_outlined,
                      label: 'SEARCH BY HEAD SHAPE',
                      caption: 'For those who want a personalized fit',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const HeadShapeScreen()),
                      ),
                    ),
                    const Spacer(flex: 2),
                    _buildOptionCard(
                      context: context,
                      icon: Icons.shopping_bag_outlined,
                      label: 'BALLCAPS! Or Just Go Shopping',
                      caption: 'Browse the full Moon Ridge collection',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ShopWebViewScreen()),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String caption,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: const Color(0xFF2D2926).withOpacity(0.06),
            highlightColor: const Color(0xFF2D2926).withOpacity(0.03),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E4DA), // Richer warm beige
                border: Border.all(
                  color: const Color(0xFF2D2926)
                      .withOpacity(0.48), // Even more defined border
                  width: 1.2,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D2926)
                        .withOpacity(0.06), // Slightly deeper shadow
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 29, // Increased from 25
                    color: const Color(0xFF2D2926).withOpacity(0.65),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.montserrat(
                        fontSize: 17, // Increased from 15 (~15%)
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.8,
                        color: const Color(0xFF2D2926),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16, // Slightly bumped
                    color: const Color(0xFF2D2926).withOpacity(0.35),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.5, // Increased from 14.5 (~15%)
            color: const Color(0xFF2D2926).withOpacity(0.48),
            letterSpacing: 0.2,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
