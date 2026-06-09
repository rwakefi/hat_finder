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

  Widget _buildBrandLockup({required bool isWide, required double logoHeight}) {
    final titleSize = isWide ? 15.0 : 12.0;
    final accentHeight = isWide ? 30.0 : 26.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          _logoAsset,
          height: logoHeight,
          fit: BoxFit.contain,
          color: Colors.white,
          colorBlendMode: BlendMode.srcIn,
        ),
        SizedBox(width: isWide ? 18 : 14),
        Container(
          width: 1,
          height: logoHeight * 0.62,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.04),
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.06),
              ],
            ),
          ),
        ),
        SizedBox(width: isWide ? 16 : 12),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 3,
              height: accentHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF7BB8B5),
                    _teal,
                    Color(0xFF3D7A77),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: _teal.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'HAT FINDER',
                  style: GoogleFonts.montserrat(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: isWide ? 2.4 : 2.0,
                    color: _gold,
                    height: 1.0,
                    shadows: const [
                      Shadow(
                        color: Color(0x40000000),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isWide ? 7 : 6),
                Container(
                  height: 2,
                  width: isWide ? 92 : 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: LinearGradient(
                      colors: [
                        _teal.withValues(alpha: 0.15),
                        _teal,
                        _gold.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
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
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.0),
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
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
                    isWide ? 10 : 8,
                    isWide ? 28 : 16,
                    isWide ? 12 : 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _openStore(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isWide ? 14 : 10,
                                vertical: isWide ? 8 : 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withValues(alpha: 0.035),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.07),
                                ),
                              ),
                              child: _buildBrandLockup(
                                isWide: isWide,
                                logoHeight: logoHeight,
                              ),
                            ),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _openStore(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                          padding: EdgeInsets.symmetric(
                            horizontal: isWide ? 14 : 10,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.1),
                            ),
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
