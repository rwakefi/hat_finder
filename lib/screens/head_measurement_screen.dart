import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/head_measurement_profile.dart';
import '../models/head_shape_profile.dart';

class HeadMeasurementScreen extends StatefulWidget {
  const HeadMeasurementScreen({
    super.key,
    required this.headShapeProfile,
    this.initialMeasurement,
  });

  final HeadShapeProfile headShapeProfile;
  final HeadMeasurementProfile? initialMeasurement;

  @override
  State<HeadMeasurementScreen> createState() => _HeadMeasurementScreenState();
}

class _HeadMeasurementScreenState extends State<HeadMeasurementScreen> {
  static const Color _espresso = Color(0xFF2D2926);
  static const Color _surface = Color(0xFFFAF8F5);
  static const Color _accent = Color(0xFF559C99);
  static const Color _bannerBg = Color(0xFFF4F1EA);
  static const Color _border = Color(0xFFE4DED1);

  final TextEditingController _centimetersController = TextEditingController();
  final TextEditingController _inchesController = TextEditingController();
  final TextEditingController _hatSizeController = TextEditingController();

  TextStyle get _stepTitleStyle => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: _espresso,
        height: 1.2,
      );

  @override
  void initState() {
    super.initState();
    final measurement = widget.initialMeasurement;
    if (measurement == null) return;

    final cm = measurement.circumferenceCm;
    final inches = measurement.circumferenceInches;
    if (cm != null) {
      _centimetersController.text = cm.toStringAsFixed(1);
    }
    if (inches != null) {
      _inchesController.text = inches.toStringAsFixed(1);
    }
    _hatSizeController.text = measurement.knownHatSize ?? '';
  }

  @override
  void dispose() {
    _centimetersController.dispose();
    _inchesController.dispose();
    _hatSizeController.dispose();
    super.dispose();
  }

  void _saveMeasurement() {
    final cm = double.tryParse(_centimetersController.text.trim());
    final inches = double.tryParse(_inchesController.text.trim());
    final knownSize = _hatSizeController.text.trim();
    final circumferenceCm = cm ?? (inches == null ? null : inches * 2.54);

    final measurement = HeadMeasurementProfile(
      circumferenceCm: circumferenceCm,
      knownHatSize: knownSize.isEmpty ? null : knownSize,
    );

    if (!measurement.hasMeasurement) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _espresso,
          content: Text(
            'Add a circumference or known hat size to save.',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          ),
        ),
      );
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(measurement);
    }
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: _espresso,
      toolbarHeight: 88,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _goBack,
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/Moon Ridge Header Logo.png',
            height: 48,
          ),
          const SizedBox(height: 4),
          Text(
            'LEARN YOUR HEAD SHAPE',
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: _espresso,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.of(context).canPop(),
      child: Scaffold(
        backgroundColor: _surface,
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Text(
              'OPTIONAL',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.6,
                color: _espresso.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 16),
            _buildGuidanceNote(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'What is your head size?',
                textAlign: TextAlign.center,
                style: _stepTitleStyle,
              ),
            ),
            _buildTextField(
              controller: _centimetersController,
              label: 'Circumference (cm)',
              hint: '58',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _inchesController,
              label: 'Circumference (inches)',
              hint: '22.8',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _hatSizeController,
              label: 'Known hat size',
              hint: '7 1/4',
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 32),
            _buildPrimaryButton('SAVE MEASUREMENT', _saveMeasurement),
            const SizedBox(height: 12),
            _buildSecondaryButton(
              'SKIP FOR NOW',
              _goBack,
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidanceNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _bannerBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.face_retouching_natural_outlined,
            color: _accent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.headShapeProfile.shortLabel} fit profile',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: _espresso,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Enter a known hat size, or measure with a flexible tape '
                  'where a hat normally sits.',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.5,
                    color: _espresso.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required TextInputType keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: _espresso.withValues(alpha: 0.72),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          cursorColor: _accent,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _espresso,
          ),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            hintStyle: GoogleFonts.montserrat(
              color: _espresso.withValues(alpha: 0.35),
              fontSize: 15,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _espresso.withValues(alpha: 0.22),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accent, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _espresso,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: _espresso,
          side: const BorderSide(color: _espresso, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
