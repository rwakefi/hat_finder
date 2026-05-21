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
  final TextEditingController _centimetersController = TextEditingController();
  final TextEditingController _inchesController = TextEditingController();
  final TextEditingController _hatSizeController = TextEditingController();

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
        const SnackBar(
          content: Text('Add a circumference or known hat size to save.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(measurement);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SIZE MEASUREMENT',
          style: GoogleFonts.playfairDisplaySc(),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2B1D14),
        foregroundColor: const Color(0xFFCBB593),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A3525),
              Color(0xFF1E140E),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildGuidanceCard(),
                const SizedBox(height: 26),
                _buildTextField(
                  controller: _centimetersController,
                  label: 'Circumference in centimeters',
                  hint: 'Example: 58',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _inchesController,
                  label: 'Circumference in inches',
                  hint: 'Example: 22.8',
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _hatSizeController,
                  label: 'Known hat size',
                  hint: 'Example: 7 1/4',
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _saveMeasurement,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFCBB593),
                    foregroundColor: const Color(0xFF2B1D14),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text(
                    'SAVE MEASUREMENT',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFCBB593),
                    side: const BorderSide(color: Color(0xFFCBB593), width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  child: const Text(
                    'SKIP FOR NOW',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
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

  Widget _buildGuidanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8).withValues(alpha: 0.08),
        border: Border.all(
          color: const Color(0xFFCBB593).withValues(alpha: 0.5),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.headShapeProfile.shortLabel} fit profile',
            style: GoogleFonts.tenorSans(
              textStyle: const TextStyle(
                color: Color(0xFFCBB593),
                fontSize: 13,
                letterSpacing: 1.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Optional for this version: enter a known hat size or use a flexible tape around the spot where a hat normally sits.',
            style: GoogleFonts.tenorSans(
              textStyle: const TextStyle(
                color: Color(0xFFF5F0E8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Camera measurement and image analysis are parked for now.',
            style: GoogleFonts.tenorSans(
              textStyle: TextStyle(
                color: const Color(0xFFF5F0E8).withValues(alpha: 0.72),
                fontSize: 13,
                height: 1.45,
                fontStyle: FontStyle.italic,
              ),
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
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      cursorColor: const Color(0xFFCBB593),
      style: const TextStyle(color: Color(0xFFF5F0E8)),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Color(0xFFCBB593)),
        hintStyle: TextStyle(
          color: const Color(0xFFF5F0E8).withValues(alpha: 0.42),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFCBB593)),
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFF5F0E8), width: 1.4),
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),
    );
  }
}
