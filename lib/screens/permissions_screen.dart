import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A3525), // Softer, warmer brown
              Color(0xFF1E140E), // Deeper brown
            ],
          ),
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
                    'assets/images/logo.png',
                    height: 150,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.privacy_tip,
                      size: 80,
                      color: Color(0xFFCBB593),
                    ),
                  ),
                ),
                
                // Middle Section: Content
                Column(
                  children: [
                    Text(
                      'WELCOME TO HAT FINDER',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplaySc(
                        textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFCBB593), // Tan
                          letterSpacing: 3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'To give you the best experience, we need a couple of permissions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFFF5F0E8),
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
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: const Color(0xFFCBB593), // Tan
                      foregroundColor: const Color(0xFF2B1D14), // Espresso
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2), // Sharp corners
                      ),
                    ),
                    onPressed: _isLoading ? null : _requestPermissions,
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Color(0xFF2B1D14))
                        : const Text(
                            'CONTINUE',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
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
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFF5F0E8),
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
