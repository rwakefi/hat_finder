import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/head_measurement_profile.dart';
import '../models/head_shape_profile.dart';
import 'head_measurement_screen.dart';
import 'hat_input_screen.dart';

class HeadShapeScreen extends StatefulWidget {
  const HeadShapeScreen({super.key});

  @override
  State<HeadShapeScreen> createState() => _HeadShapeScreenState();
}

class _HeadShapeScreenState extends State<HeadShapeScreen> {
  static const Color _espresso = Color(0xFF2D2926);
  static const Color _surface = Color(0xFFFAF8F5);
  static const Color _accent = Color(0xFF559C99);
  static const Color _bannerBg = Color(0xFFF4F1EA);
  static const Color _border = Color(0xFFE4DED1);

  int _currentQuestion = 0;
  String? _pressureLocation;
  bool? _rocks;
  bool? _sizesUp;
  String? _result;
  HeadShapeProfile? _profile;
  HeadMeasurementProfile? _measurementProfile;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Where do you usually feel pressure?',
      'options': [
        {'text': 'FOREHEAD & BACK', 'value': 'long_oval'},
        {'text': 'ON THE SIDES', 'value': 'round_oval'},
        {'text': 'EVEN ALL AROUND', 'value': 'regular_oval'},
        {'text': 'NOWHERE / FEELS LOOSE', 'value': 'loose'},
      ]
    },
    {
      'question': 'Does the hat rock side-to-side?',
      'options': [
        {'text': 'YES, IT ROCKS', 'value': true},
        {'text': 'NO, IT FEELS STABLE', 'value': false},
      ]
    },
    {
      'question': 'Do you often need to size up?',
      'options': [
        {'text': 'YES, I SIZE UP FOR COMFORT', 'value': true},
        {'text': 'NO, MY SIZE USUALLY WORKS', 'value': false},
      ]
    }
  ];

  TextStyle get _stepTitleStyle => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: _espresso,
        height: 1.2,
      );

  TextStyle get _buttonLabelStyle => GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
        color: _espresso,
      );

  void _answerQuestion(dynamic value) {
    setState(() {
      if (_currentQuestion == 0) _pressureLocation = value;
      if (_currentQuestion == 1) _rocks = value;
      if (_currentQuestion == 2) _sizesUp = value;

      if (_currentQuestion < _questions.length - 1) {
        _currentQuestion++;
      } else {
        _calculateResult();
      }
    });
  }

  void _calculateResult() {
    if (_pressureLocation == 'long_oval' ||
        _rocks == true ||
        _sizesUp == true) {
      _result = 'LONG OVAL';
      _profile = HeadShapeProfile.longOval;
    } else if (_pressureLocation == 'round_oval') {
      _result = 'ROUND OVAL';
      _profile = HeadShapeProfile.roundOval;
    } else {
      _result = 'REGULAR OVAL';
      _profile = HeadShapeProfile.regularOval;
    }
  }

  void _reset() {
    setState(() {
      _currentQuestion = 0;
      _pressureLocation = null;
      _rocks = null;
      _sizesUp = null;
      _result = null;
      _profile = null;
      _measurementProfile = null;
    });
  }

  void _continueToStyles() {
    final profile = _profile;
    if (profile == null) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HatInputScreen(
          headShapeProfile: profile,
          headMeasurementProfile: _measurementProfile,
        ),
      ),
    );
  }

  Future<void> _addMeasurement() async {
    final profile = _profile;
    if (profile == null) return;

    final measurement =
        await Navigator.of(context).push<HeadMeasurementProfile>(
      MaterialPageRoute(
        builder: (_) => HeadMeasurementScreen(
          headShapeProfile: profile,
          initialMeasurement: _measurementProfile,
        ),
      ),
    );

    if (!mounted || measurement == null) return;

    setState(() {
      _measurementProfile = measurement;
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: _espresso,
      toolbarHeight: 88,
      centerTitle: true,
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
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_result == null) _buildProgressBar(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                      child: _result == null
                          ? _buildQuestionnaire()
                          : _buildResult(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (_currentQuestion + 1) / _questions.length,
      backgroundColor: Colors.grey[200],
      valueColor: const AlwaysStoppedAnimation<Color>(_accent),
      minHeight: 3,
    );
  }

  Widget _buildQuestionnaire() {
    final currentQ = _questions[_currentQuestion];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'QUESTION ${_currentQuestion + 1} OF ${_questions.length}',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
            color: _espresso.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 16),
        _buildFitGuidanceNote(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            currentQ['question'] as String,
            textAlign: TextAlign.center,
            style: _stepTitleStyle,
          ),
        ),
        Column(
          children: (currentQ['options'] as List).map((option) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildOptionCard(
                label: option['text'] as String,
                onTap: () => _answerQuestion(option['value']),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFitGuidanceNote() {
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
            Icons.info_outline_rounded,
            color: _accent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This is about how hats feel on your head, not your face shape. '
              'Think about pressure points when wearing a real hat.',
              style: GoogleFonts.inter(
                fontSize: 15,
                height: 1.5,
                color: _espresso.withValues(alpha: 0.82),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const double _optionButtonHeight = 58;

  Widget _buildOptionCard({
    required String label,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: label,
      child: SizedBox(
        width: double.infinity,
        height: _optionButtonHeight,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: _espresso,
            backgroundColor: Colors.transparent,
            side: BorderSide(
              color: _espresso.withValues(alpha: 0.35),
              width: 1,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _buttonLabelStyle,
          ),
        ),
      ),
    );
  }

  Widget _buildResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'YOUR PROBABLE SHAPE',
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.8,
            color: _espresso.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _result!,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: _espresso,
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _getRecommendation(),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              height: 1.55,
              color: _espresso.withValues(alpha: 0.82),
            ),
          ),
        ),
        if (_measurementProfile != null) ...[
          const SizedBox(height: 24),
          _buildMeasurementSummary(),
        ],
        const SizedBox(height: 32),
        _buildPrimaryButton('CONTINUE TO STYLES', _continueToStyles),
        const SizedBox(height: 12),
        _buildSecondaryButton(
          _measurementProfile == null
              ? 'ADD SIZE MEASUREMENT'
              : 'EDIT SIZE MEASUREMENT',
          _addMeasurement,
        ),
        const SizedBox(height: 12),
        _buildSecondaryButton('START OVER', _reset),
      ],
    );
  }

  Widget _buildMeasurementSummary() {
    final measurement = _measurementProfile;
    if (measurement == null) return const SizedBox.shrink();

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
            Icons.straighten_outlined,
            color: _accent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SIZE STARTING POINT',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: _espresso,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  measurement.shortLabel,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    height: 1.45,
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

  String _getRecommendation() {
    final profile = _profile;
    if (profile == null) return '';
    return '${profile.summary}\n\n${profile.fitGuidance}';
  }
}
