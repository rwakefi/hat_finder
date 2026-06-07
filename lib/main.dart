import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'widgets/responsive_app_frame.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HatFinderApp());
}

class HatFinderApp extends StatelessWidget {
  const HatFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moon Ridge Hat Finder',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return ResponsiveAppFrame(child: child);
      },
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light, // Shift to Premium Light Mode
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF559C99), // Turquoise Accent
          primary: const Color(0xFF2D2926), // Dark Espresso
          secondary: const Color(0xFF559C99), // Turquoise
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme:
            GoogleFonts.montserratTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: const Color(0xFF2D2926),
          displayColor: const Color(0xFF2D2926),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF2D2926),
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
