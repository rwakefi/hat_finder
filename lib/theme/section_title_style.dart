import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Large Playfair step headings (e.g. "Select a Hat Type:").
abstract final class SectionTitleStyle {
  static const Color espresso = Color(0xFF2D2926);
  static const double wizard = 23;
  static const double wizardCompactWeb = 20;
  static const double guide = 25;

  static TextStyle playfairBold({
    required double fontSize,
    double height = 1.2,
  }) =>
      GoogleFonts.playfairDisplay(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: espresso,
        height: height,
      );
}
