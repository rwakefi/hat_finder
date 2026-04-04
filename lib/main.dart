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
      title: 'Hat Finder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2B1D14), // Rafter M Espresso Brown
          primary: const Color(0xFF2B1D14),
          onPrimary: Colors.white,
          secondary: const Color(0xFFCBB593), // Rafter M Tan
          onSecondary: const Color(0xFF2B1D14),
          surface: const Color(0xFF2B1D14),
          onSurface: const Color(0xFFF5F0E8),
          brightness: Brightness.dark, // Set to dark for white text by default
        ),
        scaffoldBackgroundColor: const Color(0xFF2B1D14),
        useMaterial3: true,
        textTheme: GoogleFonts.quattrocentoTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: const Color(0xFFF5F0E8),
          displayColor: const Color(0xFFF5F0E8),
        ).copyWith(
          displayLarge: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.displayLarge?.copyWith(color: const Color(0xFFF5F0E8))),
          displayMedium: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.displayMedium?.copyWith(color: const Color(0xFFF5F0E8))),
          displaySmall: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.displaySmall?.copyWith(color: const Color(0xFFF5F0E8))),
          headlineLarge: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(color: const Color(0xFFF5F0E8))),
          headlineMedium: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(color: const Color(0xFFF5F0E8))),
          headlineSmall: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFFF5F0E8))),
          titleLarge: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFFF5F0E8))),
          titleMedium: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(color: const Color(0xFFF5F0E8))),
          titleSmall: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(color: const Color(0xFFF5F0E8))),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2B1D14),
          primary: const Color(0xFFCBB593), // Flip primary to tan in dark mode
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.quattrocentoTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.white, displayColor: Colors.white)
            .copyWith(
              displayLarge: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.displayLarge?.copyWith(color: Colors.white)),
              displayMedium: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.displayMedium?.copyWith(color: Colors.white)),
              displaySmall: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white)),
              headlineLarge: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white)),
              headlineMedium: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.white)),
              headlineSmall: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
              titleLarge: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
              titleMedium: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white)),
              titleSmall: GoogleFonts.cinzel(textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
            ),
      ),
      home: const HomeScreen(),
    );
  }
}
