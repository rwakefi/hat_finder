import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/head_shape_profile.dart';
import 'hat_input_screen.dart';

class HeadShapeScreen extends StatefulWidget {
  const HeadShapeScreen({super.key});

  @override
  State<HeadShapeScreen> createState() => _HeadShapeScreenState();
}

class _HeadShapeScreenState extends State<HeadShapeScreen> {
  // State variables
  int _currentQuestion = 0;
  String? _pressureLocation;
  bool? _rocks;
  bool? _sizesUp;
  String? _result;
  HeadShapeProfile? _profile;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'WHERE DO YOU USUALLY FEEL PRESSURE?',
      'options': [
        {'text': 'FOREHEAD & BACK', 'value': 'long_oval'},
        {'text': 'ON THE SIDES', 'value': 'round_oval'},
        {'text': 'EVEN ALL AROUND', 'value': 'regular_oval'},
        {'text': 'NOWHERE / FEELS LOOSE', 'value': 'loose'},
      ]
    },
    {
      'question': 'DOES THE HAT ROCK SIDE-TO-SIDE?',
      'options': [
        {'text': 'YES, IT ROCKS', 'value': true},
        {'text': 'NO, IT FEELS STABLE', 'value': false},
      ]
    },
    {
      'question': 'DO YOU OFTEN NEED TO SIZE UP?',
      'options': [
        {'text': 'YES, I SIZE UP FOR COMFORT', 'value': true},
        {'text': 'NO, MY SIZE USUALLY WORKS', 'value': false},
      ]
    }
  ];

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
    // Simple logic based on KB
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('HEAD SHAPE DIAGNOSTIC',
            style: GoogleFonts.playfairDisplaySc()),
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
              Color(0xFF4A3525), // Softer, warmer brown
              Color(0xFF1E140E), // Deeper brown
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
            child: _result == null ? _buildQuestionnaire() : _buildResult(),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionnaire() {
    final currentQ = _questions[_currentQuestion];
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Progress
        Text(
          'QUESTION ${_currentQuestion + 1} OF ${_questions.length}',
          style: GoogleFonts.tenorSans(
            textStyle: const TextStyle(
              color: Color(0xFFCBB593),
              fontSize: 12,
              letterSpacing: 2,
            ),
          ),
        ),

        // Question
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Text(
            currentQ['question'],
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplaySc(
              textStyle: const TextStyle(
                color: Color(0xFFF5F0E8),
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        // Options
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: (currentQ['options'] as List).map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _answerQuestion(option['value']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFCBB593),
                      side:
                          const BorderSide(color: Color(0xFFCBB593), width: 1),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    child: Text(
                      option['text'],
                      style: GoogleFonts.tenorSans(
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(height: 20),
        Text(
          'YOUR PROBABLE SHAPE',
          style: GoogleFonts.tenorSans(
            textStyle: const TextStyle(
              color: Color(0xFFCBB593),
              fontSize: 14,
              letterSpacing: 2,
            ),
          ),
        ),

        // Result
        Text(
          _result!,
          style: GoogleFonts.playfairDisplaySc(
            textStyle: const TextStyle(
              color: Color(0xFFF5F0E8),
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
        ),

        // Description based on result
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            _getRecommendation(),
            textAlign: TextAlign.center,
            style: GoogleFonts.tenorSans(
              textStyle: const TextStyle(
                color: Color(0xFFF5F0E8),
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Action Buttons
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final profile = _profile;
                  if (profile == null) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => HatInputScreen(
                        headShapeProfile: profile,
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFCBB593),
                  foregroundColor: const Color(0xFF2B1D14),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Text(
                  'CONTINUE TO STYLES',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFCBB593),
                  side: const BorderSide(color: Color(0xFFCBB593), width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: const Text(
                  'START OVER',
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
      ],
    );
  }

  String _getRecommendation() {
    final profile = _profile;
    if (profile == null) return '';
    return '${profile.summary}\n\n${profile.fitGuidance}';
  }
}
