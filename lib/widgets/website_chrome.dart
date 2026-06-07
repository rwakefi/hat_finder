import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../config/app_breakpoints.dart';
import '../utils/embed_mode.dart';

/// Full-width web header so Hat Finder feels like part of moonridgecompany.com.
class WebsiteChrome extends StatelessWidget {
  const WebsiteChrome({super.key});

  static bool shouldShow(BuildContext context) {
    if (!kIsWeb || EmbedMode.isActive) return false;
    return AppBreakpoints.isTablet(context);
  }

  Future<void> _openStore(BuildContext context) async {
    final uri = Uri.parse(AppConfig.publicStoreUrl);
    await launchUrl(uri, webOnlyWindowName: '_top');
  }

  Future<void> _openHatsCollection(BuildContext context) async {
    final uri = Uri.parse('${AppConfig.publicStoreUrl}/collections/hats');
    await launchUrl(uri, webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isDesktop(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF3A2E28),
            Color(0xFF2D2926),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: Color(0x33FFFFFF)),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 28 : 16, 10, isWide ? 28 : 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MOON RIDGE',
                      style: GoogleFonts.montserrat(
                        fontSize: isWide ? 15 : 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.4,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'Hat Finder',
                      style: GoogleFonts.montserrat(
                        fontSize: isWide ? 12 : 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _openStore(context),
                icon: Icon(
                  Icons.arrow_back_rounded,
                  size: isWide ? 18 : 16,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
                label: Text(
                  isWide ? 'Back to Moon Ridge' : 'Store',
                  style: GoogleFonts.montserrat(
                    fontSize: isWide ? 13 : 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
              if (isWide) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _openHatsCollection(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    'Browse Hats',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
