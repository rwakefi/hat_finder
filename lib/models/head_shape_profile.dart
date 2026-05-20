enum HeadShapeProfileType {
  longOval,
  roundOval,
  regularOval,
}

class HeadShapeProfile {
  const HeadShapeProfile({
    required this.type,
    required this.label,
    required this.shortLabel,
    required this.summary,
    required this.fitGuidance,
    required this.defaultMaterial,
    required this.crownPriorities,
    required this.brimPriorities,
  });

  final HeadShapeProfileType type;
  final String label;
  final String shortLabel;
  final String summary;
  final String fitGuidance;
  final String defaultMaterial;
  final List<String> crownPriorities;
  final List<String> brimPriorities;

  static const longOval = HeadShapeProfile(
    type: HeadShapeProfileType.longOval,
    label: 'LONG OVAL',
    shortLabel: 'Long Oval',
    summary:
        'Likely pressure at the forehead and back, or a hat that rocks side-to-side.',
    fitGuidance:
        'Start with felt styles that can be shaped and fitted carefully. Avoid solving comfort only by sizing up; the right oval fit matters more than a loose hat.',
    defaultMaterial: 'Felt',
    crownPriorities: [
      'gambler',
      'telescope',
      'teardrop',
      'pinch front',
      'open crown',
    ],
    brimPriorities: [
      'medium curved',
      'flanged',
      'pulled down',
    ],
  );

  static const roundOval = HeadShapeProfile(
    type: HeadShapeProfileType.roundOval,
    label: 'ROUND OVAL',
    shortLabel: 'Round Oval',
    summary: 'Likely side pressure from hats shaped for a narrower oval.',
    fitGuidance:
        'Look for forgiving shapes and plan on in-store shaping when possible. A clean crown and balanced brim help keep the fit comfortable without feeling oversized.',
    defaultMaterial: 'Felt',
    crownPriorities: [
      'cattleman',
      'brick',
      'rounded brick',
      'gus',
    ],
    brimPriorities: [
      'medium curved',
      'slightly curved',
      'shovel',
    ],
  );

  static const regularOval = HeadShapeProfile(
    type: HeadShapeProfileType.regularOval,
    label: 'REGULAR OVAL',
    shortLabel: 'Regular Oval',
    summary:
        'Most factory hats should be close, with style preference doing more of the work.',
    fitGuidance:
        'You can shop broadly. Use crown and brim choices to tune the look first, then confirm comfort in the exact size.',
    defaultMaterial: 'Felt',
    crownPriorities: [
      'cattleman',
      'pinch front',
      'teardrop',
    ],
    brimPriorities: [
      'medium curved',
      'flat',
      'pencil curl',
    ],
  );
}
