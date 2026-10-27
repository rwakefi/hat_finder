import 'package:flutter/material.dart';

/// Horizontal row of pill-shaped segments used as a wizard/quiz progress
/// indicator.
///
/// Segments 1 … [currentStep] are filled with [filledColor]; segments
/// [currentStep]+1 … [totalSteps] are shown in [trackColor].
///
/// [currentStep] is 1-based and inclusive of the step the user is currently
/// on (e.g. step 1 fills only the first segment, step 3 fills three).
///
/// Wrap with horizontal [Padding] to control side margins; the widget itself
/// fills available width so it works both inside a body [Column] and as an
/// [AppBar] bottom [PreferredSize].
class SegmentedProgressBar extends StatelessWidget {
  const SegmentedProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.filledColor = const Color(0xFF2D2926),
    this.trackColor = const Color(0xFFE4DED1),
    this.height = 5.0,
    this.gap = 4.0,
    this.semanticLabel,
  });

  /// Which step the user is currently on (1-based, inclusive).
  final int currentStep;

  /// Total number of steps in the flow.
  final int totalSteps;

  /// Color for completed + current step segments (default: Moon Ridge espresso).
  final Color filledColor;

  /// Color for upcoming step segments (default: Moon Ridge border/warm gray).
  final Color trackColor;

  /// Pixel height of each pill segment.
  final double height;

  /// Pixel gap between adjacent segments.
  final double gap;

  /// Override the accessibility label; defaults to "Step N of M".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel ?? 'Step $currentStep of $totalSteps';
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (int i = 0; i < totalSteps; i++) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(
                child: _Pill(
                  filled: i < currentStep,
                  filledColor: filledColor,
                  trackColor: trackColor,
                  radius: height / 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.filled,
    required this.filledColor,
    required this.trackColor,
    required this.radius,
  });

  final bool filled;
  final Color filledColor;
  final Color trackColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? filledColor : trackColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const SizedBox.expand(),
    );
  }
}
