import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_screen.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  bool _isLoading = false;

  Future<void> _requestPermissions() async {
    setState(() => _isLoading = true);

    // Skip permissions on macOS as they are mobile-specific and can cause crashes if not configured.
    if (!kIsWeb && Platform.isMacOS) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_permissions', true);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
      return;
    }

    // Request App Tracking Transparency first (important for iOS)
    if (await AppTrackingTransparency.trackingAuthorizationStatus ==
        TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }

    // Request Location Permission
    if (await Permission.locationWhenInUse.isDenied) {
      await Permission.locationWhenInUse.request();
    }

    // Capture location if granted
    if (await Permission.locationWhenInUse.isGranted) {
      try {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble('user_lat', position.latitude);
        await prefs.setDouble('user_lng', position.longitude);
      } catch (e) {
        print("Error capturing location: $e");
      }
    }

    // Save that we have handled permissions onboarding
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_permissions', true);

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  Future<void> _launchShop() async {
    final Uri url = Uri.parse('https://moonridgecompany.com');
    if (!await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
      print("Could not launch $url");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Section: Logo
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Image.asset(
                    'assets/images/Moon Ridge Header Logo.png',
                    height: 150,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.privacy_tip,
                      size: 80,
                      color: Color(0xFF2D2926),
                    ),
                  ),
                ),
                
                // Middle Section: Content
                Column(
                  children: [
                    Text(
                      'WELCOME TO HAT FINDER',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D2926),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'To provide you with the best hat recommendations, '
                      'we need access to your camera to analyze your face shape.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: const Color(0xFF2D2926).withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),
                    _buildPermissionItem(
                      icon: Icons.location_on_outlined,
                      title: 'LOCATION ACCESS',
                      description: 'To help you find hat stores and products near you.',
                    ),
                    const SizedBox(height: 24),
                    _buildPermissionItem(
                      icon: Icons.track_changes_outlined,
                      title: 'APP TRACKING',
                      description: 'To deliver personalized recommendations and ads. You can ask the app not to track you on the next screen.',
                    ),
                  ],
                ),
                
                // Bottom Section: Button
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 60),
                          backgroundColor: const Color(0xFFCBB593),
                          foregroundColor: const Color(0xFF2B1D14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                        onPressed: _isLoading ? null : _requestPermissions,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Color(0xFF2B1D14))
                            : const Text(
                                'CONTINUE',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
                          side: BorderSide(color: const Color(0xFF2D2926).withOpacity(0.2)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _launchShop,
                        child: Text(
                          "Let's Just Shop...",
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: const Color(0xFF2D2926).withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, color: const Color(0xFF2D2926).withOpacity(0.7), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your photos are processed securely and never stored.',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF2D2926).withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFCBB593), size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.cinzel(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFCBB593),
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: const Color(0xFF2D2926).withOpacity(0.7),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
