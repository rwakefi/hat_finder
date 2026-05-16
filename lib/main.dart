import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/permissions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenPermissions = prefs.getBool('has_seen_permissions') ?? false;
  runApp(HatFinderApp(hasSeenPermissions: hasSeenPermissions));
}

class HatFinderApp extends StatelessWidget {
  final bool hasSeenPermissions;
  const HatFinderApp({super.key, required this.hasSeenPermissions});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moon Ridge Hat Finder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF312110), // Deep Artisan Brown
          secondary: const Color(0xFFA88467), // Heritage Gold
          surface: const Color(0xFF312110),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: const Color(0xFFE8D9C8), // Cream
        ),
        scaffoldBackgroundColor: const Color(0xFF2B1D14),
        textTheme: GoogleFonts.tenorSansTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: const Color(0xFFF5F0E8),
          displayColor: const Color(0xFFF5F0E8),
        ).copyWith(
          displayLarge: GoogleFonts.playfairDisplaySc(textStyle: Theme.of(context).textTheme.displayLarge?.copyWith(color: const Color(0xFFF5F0E8))),
          displayMedium: GoogleFonts.playfairDisplaySc(textStyle: Theme.of(context).textTheme.displayMedium?.copyWith(color: const Color(0xFFF5F0E8))),
          displaySmall: GoogleFonts.playfairDisplaySc(textStyle: Theme.of(context).textTheme.displaySmall?.copyWith(color: const Color(0xFFF5F0E8))),
          headlineLarge: GoogleFonts.playfairDisplaySc(textStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(color: const Color(0xFFF5F0E8))),
          headlineMedium: GoogleFonts.playfairDisplaySc(textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(color: const Color(0xFFF5F0E8))),
          headlineSmall: GoogleFonts.playfairDisplaySc(textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFFF5F0E8))),
          titleLarge: GoogleFonts.playfairDisplaySc(textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFFF5F0E8))),
          titleMedium: GoogleFonts.playfairDisplaySc(textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFFF5F0E8))),
          titleSmall: GoogleFonts.playfairDisplaySc(textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(color: const Color(0xFFF5F0E8))),
        ),
      ),
      home: hasSeenPermissions ? const HomeScreen() : const PermissionsScreen(),
    );
  }
}
