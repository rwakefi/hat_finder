enum HeadMeasurementSource {
  manual,
}

class HeadMeasurementProfile {
  const HeadMeasurementProfile({
    this.circumferenceCm,
    this.knownHatSize,
    this.source = HeadMeasurementSource.manual,
  });

  final double? circumferenceCm;
  final String? knownHatSize;
  final HeadMeasurementSource source;

  double? get circumferenceInches {
    final cm = circumferenceCm;
    if (cm == null) return null;
    return cm / 2.54;
  }

  bool get hasMeasurement =>
      circumferenceCm != null || (knownHatSize?.trim().isNotEmpty ?? false);

  String get shortLabel {
    final size = knownHatSize?.trim();
    if (size != null && size.isNotEmpty) {
      return 'Known size $size';
    }

    final cm = circumferenceCm;
    final inches = circumferenceInches;
    if (cm != null && inches != null) {
      return '${cm.toStringAsFixed(1)} cm / ${inches.toStringAsFixed(1)} in';
    }

    return 'Manual measurement added';
  }

  String get guidance {
    final size = knownHatSize?.trim();
    final cm = circumferenceCm;

    if (size != null && size.isNotEmpty && cm != null) {
      return 'Use this known hat size and circumference as a starting point, then confirm comfort in the exact style.';
    }

    if (size != null && size.isNotEmpty) {
      return 'Use this known hat size as a starting point, then confirm comfort in the exact style.';
    }

    return 'Use this circumference as a starting point, then confirm comfort in the exact style.';
  }
}
