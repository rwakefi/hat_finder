import 'package:flutter/material.dart';

/// Uniform vertical rhythm below the Moon Ridge logo lockup.
abstract final class WizardHeaderSpacing {
  static const double gap = 12;

  static const EdgeInsets stepTitle =
      EdgeInsets.fromLTRB(16, gap, 16, 0);

  static const EdgeInsets stepTitleWeb =
      EdgeInsets.fromLTRB(16, gap, 16, 0);

  static const EdgeInsets actionRow =
      EdgeInsets.fromLTRB(16, gap, 16, 0);

  static const EdgeInsets guideLink =
      EdgeInsets.fromLTRB(0, gap, 0, 16);

  static const EdgeInsets webLogo =
      EdgeInsets.fromLTRB(16, gap, 16, 0);

  static const EdgeInsets screenBody =
      EdgeInsets.fromLTRB(24, gap, 24, 28);
}
