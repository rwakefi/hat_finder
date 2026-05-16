import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const HatFinderApp());
}

class HatFinderApp extends StatelessWidget {
  const HatFinderApp({super.key});

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
        scaffoldBackgroundColor: const Color(0xFF312110),
        textTheme: GoogleFonts.loraTextTheme().apply(
          bodyColor: const Color(0xFFE8D9C8),
          displayColor: const Color(0xFFE8D9C8),
        ).copyWith(
          displayLarge: GoogleFonts.tenorSans(letterSpacing: 4.0),
          displayMedium: GoogleFonts.tenorSans(letterSpacing: 4.0),
          displaySmall: GoogleFonts.tenorSans(letterSpacing: 3.0),
          headlineLarge: GoogleFonts.tenorSans(letterSpacing: 2.5),
          headlineMedium: GoogleFonts.tenorSans(letterSpacing: 2.0),
          headlineSmall: GoogleFonts.tenorSans(letterSpacing: 1.5),
          titleLarge: GoogleFonts.tenorSans(letterSpacing: 1.5),
          titleMedium: GoogleFonts.tenorSans(letterSpacing: 1.2),
          titleSmall: GoogleFonts.tenorSans(letterSpacing: 1.0),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
