import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hat_input_screen.dart';
import 'chat_screen.dart';
import 'head_shape_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final logoHeight = (constraints.maxHeight * 0.22).clamp(100.0, 180.0);
          
          return Container(
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
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 50.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Section: Logo
                        Padding(
                          padding: const EdgeInsets.only(top: 30.0),
                          child: Image.asset(
                            'assets/images/logo.png',
                            height: logoHeight,
                            color: const Color(0xFFCBB593), // Tan color for a lighter, golden look
                          ),
                        ),
                        
                        // Middle Section: Content
                        Column(
                          children: [
                            Text(
                              'FIND YOUR PERFECT HAT',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplaySc(
                                textStyle: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFCBB593), // Tan
                                  letterSpacing: 4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Discover luxury hats tailored to your unique style and shape.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFFF5F0E8), // Off-white
                                height: 1.6,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        
                        // Bottom Section: Actions
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const HatInputScreen()),
                                  );
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFCBB593), // Tan
                                  foregroundColor: const Color(0xFF2B1D14), // Espresso
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2), // Sharp corners
                                  ),
                                ),
                                child: const Text(
                                  'SEARCH BY HAT SHAPE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'For those who know what style they are looking for',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFFF5F0E8).withOpacity(0.7),
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32), // More space between sections
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const HeadShapeScreen()),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFCBB593), // Tan
                                  side: const BorderSide(color: Color(0xFFCBB593), width: 1),
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                child: const Text(
                                  'SEARCH BY HEAD SHAPE',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'For those who have no idea what hat might look good on them',
                              style: TextStyle(
                                fontSize: 13,
                                color: const Color(0xFFF5F0E8).withOpacity(0.7),
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
