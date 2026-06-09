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

  static const _logoAsset = 'assets/images/moon_ridge_logo.png';
  static const _espresso = Color(0xFF2D2926);
  static const _champagne = Color(0xFFC9BBA8);
  static const _gold = Color(0xFFD4A843);
  static const _teal = Color(0xFF559C99);

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
    final logoHeight = isWide ? 50.0 : 42.0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3D322C),
            _espresso,
            Color(0xFF241F1C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppBreakpoints.webAppMaxWidth(context),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 28 : 16,
                    isWide ? 12 : 10,
                    isWide ? 28 : 16,
                    isWide ? 14 : 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openStore(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    _logoAsset,
                                    height: logoHeight,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(width: isWide ? 16 : 12),
                                  Container(
                                    width: 1,
                                    height: logoHeight * 0.72,
                                    color: Colors.white.withValues(alpha: 0.18),
                                  ),
                                  SizedBox(width: isWide ? 16 : 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'HAT FINDER',
                                        style: GoogleFonts.montserrat(
                                          fontSize: isWide ? 13 : 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: isWide ? 2.0 : 1.6,
                                          color: _gold,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Container(
                                        width: isWide ? 36 : 28,
                                        height: 2,
                                        decoration: BoxDecoration(
                                          color: _teal,
                                          borderRadius:
                                              BorderRadius.circular(1),
                                        ),
                                      ),
                                      if (isWide) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          'Curated western & specialty hats',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            letterSpacing: 0.2,
                                            color: _champagne
                                                .withValues(alpha: 0.82),
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openStore(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 12 : 8,
                            vertical: 8,
                          ),
                        ),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: isWide ? 18 : 16,
                          color: _champagne.withValues(alpha: 0.95),
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
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed: () => _openHatsCollection(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: _teal.withValues(alpha: 0.18),
                            side: BorderSide(
                              color: _teal.withValues(alpha: 0.75),
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 11,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Text(
                            'Browse Hats',
                            style: GoogleFonts.montserrat(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 2,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0x00559C99),
                  _teal,
                  Color(0x00559C99),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
