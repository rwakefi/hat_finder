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

  // Palette aligned with moonridgecompany.com (Shopify theme).
  static const _brandBrown = Color(0xFF312110);
  static const _announcementTeal = Color(0xFF4A9E9A);
  static const _headerBorder = Color(0xFFE0E0E0);

  static bool shouldShow(BuildContext context) {
    if (!kIsWeb || EmbedMode.isActive) return false;
    return AppBreakpoints.isTablet(context);
  }

  Future<void> _openStore(BuildContext context) async {
    final uri = Uri.parse(AppConfig.publicStoreUrl);
    await launchUrl(uri, webOnlyWindowName: '_top');
  }

  Widget _buildBrandTitle({required bool isDesktop}) {
    final titleSize = isDesktop ? 14.0 : 12.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'HAT FINDER',
          style: GoogleFonts.montserrat(
            fontSize: titleSize,
            fontWeight: FontWeight.w600,
            letterSpacing: isDesktop ? 2.4 : 2.0,
            color: _brandBrown,
            height: 1.0,
          ),
        ),
        SizedBox(height: isDesktop ? 6 : 5),
        Container(
          height: 2,
          width: isDesktop ? 72 : 60,
          decoration: BoxDecoration(
            color: _announcementTeal,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);

    return ColoredBox(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ColoredBox(
            color: _announcementTeal,
            child: SizedBox(height: 3, width: double.infinity),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: _headerBorder),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: AppBreakpoints.webAppMaxWidth(context),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? 32 : 16,
                      isDesktop ? 16 : 12,
                      isDesktop ? 32 : 16,
                      isDesktop ? 18 : 14,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openStore(context),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                    vertical: 2,
                                  ),
                                  child: _buildBrandTitle(isDesktop: isDesktop),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Image.asset(
                          'assets/images/Moon Ridge Header Logo.png',
                          height: 72,
                          fit: BoxFit.contain,
                        ),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _openStore(context),
                              style: TextButton.styleFrom(
                                foregroundColor: _brandBrown,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isDesktop ? 12 : 8,
                                  vertical: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                size: isDesktop ? 18 : 16,
                                color: _brandBrown.withValues(alpha: 0.85),
                              ),
                              label: Text(
                                isDesktop ? 'Back to Moon Ridge' : 'Store',
                                style: GoogleFonts.montserrat(
                                  fontSize: isDesktop ? 13 : 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                  color: _brandBrown,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
