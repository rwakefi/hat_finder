import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/home_social_links.dart';
import 'package:url_launcher/url_launcher.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

  static const Color _espresso = Color(0xFF2D2926);
  static const Color _surface = Color(0xFFFAF8F5);

  Future<void> _openSite() async {
    final uri = Uri.parse('https://moonridgecompany.com');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/Moon Ridge Header Logo.png',
                  height: 96,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Stay Connected',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: _espresso,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Follow Moon Ridge for new drops, styling tips, and western heritage.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  height: 1.5,
                  color: _espresso.withValues(alpha: 0.58),
                ),
              ),
              const Spacer(),
              const Center(child: HomeSocialLinks()),
              const SizedBox(height: 28),
              Semantics(
                button: true,
                label: 'Visit moonridgecompany.com',
                child: OutlinedButton(
                  onPressed: _openSite,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _espresso,
                    side: BorderSide(
                      color: _espresso.withValues(alpha: 0.25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'VISIT MOONRIDGECOMPANY.COM',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
