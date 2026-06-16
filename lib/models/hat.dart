class Hat {
  final String crownShape;
  final double crownHeight; // Measured in inches (expected in 0.25 increments)
  final String brimShape;
  final double brimWidth; // Measured in inches (expected in 0.25 increments)

  Hat({
    required this.crownShape,
    required this.crownHeight,
    required this.brimShape,
    required this.brimWidth,
  });
}

class HatShapeInfo {
  final String name;
  final String imagePath;
  final String description;
  final String history;
  final List<Map<String, String>> famousWearers;
  final String physicalDescription;
  final List<String> galleryImages;

  const HatShapeInfo(
    this.name,
    this.imagePath,
    this.description, {
    this.history = '',
    this.famousWearers = const [],
    this.physicalDescription = '',
    this.galleryImages = const [],
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HatShapeInfo &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

/// Fallback catalog — names align with Shopify `custom.felt_straw_or_ballcap`.
const List<HatShapeInfo> hatTypes = [
  HatShapeInfo(
      'Felt', 'assets/images/red_rocks.webp', 'Classic fur or wool felt hats.'),
  HatShapeInfo('Straw', 'assets/images/straw_hat.jpg',
      'Woven straw hats for warmer weather.'),
  HatShapeInfo('Ballcap', 'assets/images/ballcap.png',
      'Casual structured and unstructured caps.'),
  HatShapeInfo(
    'Beanie/Flat Cap',
    'assets/images/crowns/flat_cap.png',
    'Beanies and flat caps for casual everyday wear.',
  ),
];

/// Fallback enrichment for wizard cards — images, copy, and history keyed by
/// Shopify `custom.crown_shape` validation labels. The live card list and order
/// come from Shopify admin via the Hat Finder backend.
const List<HatShapeInfo> crownShapes = [
  HatShapeInfo(
    'Cattleman\'s',
    'assets/images/crowns/cattleman.png',
    'The industry standard — a single center crease with two side dents.',
    famousWearers: [
      {
        'name': 'George Strait',
        'context':
            'The "King of Country" has made the Cattleman\'s his signature look for over four decades.'
      },
    ],
    physicalDescription:
        'The backbone of western hat making. A clean center crease runs straight from front to back, flanked by two long, parallel side dents. As classic and dependable as it gets.',
  ),
  HatShapeInfo(
    'Pinch Front/Teardrop/Diamond',
    'assets/images/crowns/pinch_front.png',
    'A V-shaped front pinch for a narrow, tapered, face-framing look.',
    physicalDescription:
        'Defined by a sharp V-shaped pinch at the front. The top can be finished soft and rounded like a teardrop or cut clean with geometric angles like a diamond — either way, it tapers in and frames the face closely.',
  ),
  HatShapeInfo(
    'Brick/Rounded Brick/Minnick/CHL',
    'assets/images/crowns/brick.png',
    'A flattened, widened Cattleman with a boxy, commanding presence.',
    physicalDescription:
        'A bolder take on the Cattleman. The top is flattened and broadened rather than creased, with deep side dents that push outward — giving the crown a wide, squared-off presence.',
  ),
  HatShapeInfo(
    'Gus/Tom Mix',
    'assets/images/crowns/gus.png',
    'A high back sloping forward to a pronounced front pinch — pure Old West.',
    famousWearers: [
      {
        'name': 'Robert Duvall',
        'context':
            'Immortalized the Gus crown as Augustus McCrae in "Lonesome Dove" (1989).'
      },
    ],
    physicalDescription:
        'Straight out of the Old West. The crown climbs high in the back and drops toward the front, with a pronounced front pinch and deep side indents that give it that unmistakable trail-worn silhouette.',
  ),
  HatShapeInfo(
    'Gambler/Telescope/Buckaroo',
    'assets/images/crowns/gambler.png',
    'A flat circular top with a continuous gutter around the crown.',
    physicalDescription:
        'Clean and unconventional. A flat, circular top with a continuous gutter running all the way around the outer edge — no pinch, no crease, just a bold, unbroken line. The Buckaroo shares this low, flat profile with a working-ranch attitude.',
  ),
  HatShapeInfo(
    'Texas Punch',
    'assets/images/crowns/texas_punch.png',
    'A deep, aggressive crease favored in working ranch country.',
    famousWearers: [
      {
        'name': 'West Texas Ranchers',
        'context':
            'A regional signature shape born in the Permian Basin, built for function in extreme heat.'
      },
    ],
    physicalDescription:
        'Built for the ranch. A deep, assertive crease with a taller crown and sharp, well-defined side dents. No frills — just a hard-working shape with serious character.',
  ),
  HatShapeInfo(
    'Cutter',
    'assets/images/crowns/square_top.png',
    'Popped-out side dents for a squarer, aggressive performance profile.',
    physicalDescription:
        'A performance-minded evolution of the Cattleman. The side dents are bumped out and popped, widening the crown from the front for a squarer, more aggressive stance.',
  ),
  HatShapeInfo(
    'The Walker',
    'assets/images/crowns/walker.png',
    'A smooth top, no center crease, and one small dent on each side of the front.',
    physicalDescription:
        'A modern favorite. No center crease — just a smooth top with a single subtle dent on each side of the front. Clean, understated, and highly wearable.',
  ),
  HatShapeInfo(
    'Mule Kick/Horseshoe',
    'assets/images/crowns/round_top.png',
    'A custom-shop favorite with a bumped-out "mule kick" on top.',
    physicalDescription:
        'A distinct bump pushes outward from the felt at the top of the crown, adding a one-of-a-kind profile that sets it apart from every other shape on the block.',
  ),
  HatShapeInfo(
    'Open Crown',
    'assets/images/crowns/open_crown.png',
    'A smooth, uncreased dome — your blank canvas for custom shaping.',
    famousWearers: [
      {
        'name': 'John B. Stetson',
        'context':
            'The original "Boss of the Plains" was sold as an open crown — the customer decided the crease.'
      },
    ],
    physicalDescription:
        'A blank slate. Round, smooth, and untouched — exactly as it comes off the block. The starting point for anyone who wants to put their own hands on the shape.',
  ),
];

/// Fallback enrichment for wizard cards — images and copy keyed by Shopify
/// `custom.brim_shape` validation labels. The live card list and order come
/// from Shopify admin via the Hat Finder backend.
const List<HatShapeInfo> brimShapes = [
  HatShapeInfo(
    'J (George Strait, Medium Curved)',
    'assets/images/placeholder.png',
    'Classic roper look — front matches the crown width.',
    famousWearers: [
      {
        'name': 'George Strait',
        'context':
            'The clean, medium-curved J brim is central to his signature western look.'
      },
    ],
    physicalDescription:
        'The front of the brim matches the width of the crown. Medium side height with soft corners — a classic roper look with old-school roots.',
  ),
  HatShapeInfo(
    'Flat/Pencil Curl',
    'assets/images/placeholder.png',
    'The most open brim — clean and straight all the way around.',
    physicalDescription:
        'No curves, no shape — just a clean, even brim that extends straight out all the way around. The most open brim in the lineup.',
  ),
  HatShapeInfo(
    'Snap Brim/Flanged Brim',
    'assets/images/placeholder.png',
    'Flexible brim, snapped down in front and up in back.',
    physicalDescription:
        'A flexible brim that can be snapped down in the front over the eyes and up in the back. Primarily associated with Fedora styles.',
  ),
  HatShapeInfo(
    'RD (Round)',
    'assets/images/placeholder.png',
    'Soft dip front to back with gentle curves throughout.',
    physicalDescription:
        'A step up from flat, with a soft dip that gradually drops from front to back. Gentle curves throughout with no sharp angles — unlike the aggressive 90-degree bend of a Taco or Quarter Horse brim.',
  ),
  HatShapeInfo(
    'JB (Bullrider)',
    'assets/images/placeholder.png',
    'A slightly bolder J — sits a finger past the crown.',
    physicalDescription:
        "Sits just about a finger's width beyond the crown. A straight, clean front with soft corners and medium sides — a slightly bolder take on the J.",
  ),
  HatShapeInfo(
    'CHL (Cool Hand Luke, Shovel, Reiner Low Sides)',
    'assets/images/placeholder.png',
    'Broadest, squared-off front with a low, sweeping side.',
    physicalDescription:
        'The broadest front of all the styles. Flat and squared-off up front with a low, sweeping profile on the sides.',
  ),
  HatShapeInfo(
    'U (Reiner High Sides)',
    'assets/images/placeholder.png',
    'Wide squared front with high, tight sides and a U back.',
    physicalDescription:
        'Shares the wide, squared front of the Cool Hand Luke, but the sides ride higher and pull in tighter toward the back — with a gentle "U" curve behind.',
  ),
  HatShapeInfo(
    'WTP (West Texas Punch, Rancher)',
    'assets/images/placeholder.png',
    'Straight front, tall sides, and a snug U-shape back.',
    physicalDescription:
        'About a finger\'s width wider than the crown up front. Straight across with soft corners, tall sides, and a snug "U" shape in the back.',
  ),
  HatShapeInfo(
    'SC (Showmanship)',
    'assets/images/placeholder.png',
    'The most structured brim — sharp, high, and tight.',
    physicalDescription:
        'The most structured brim in the lineup. The front tucks slightly inside the crown width, with sharp corners and sides that are high and tight — a precise, polished look built for the show pen.',
  ),
];

const List<String> brimWidths = [
  '4 Inches',
  '4 1/4 Inches',
  '4 1/2 Inches',
  '4 3/4 Inches',
  '5 Inches',
];

/// Standard crown heights in 1/4" steps (matches Shopify metafield increments).
List<double> defaultCrownHeightOptions() {
  const min = 3.75;
  const max = 5.5;
  final values = <double>[];
  for (var step = 0; step <= ((max - min) / 0.25).round(); step++) {
    values.add(min + step * 0.25);
  }
  return values;
}

String formatMeasurement(double val) {
  int whole = val.truncate();
  double fraction = val - whole;
  if ((fraction - 0.25).abs() < 0.01) return '$whole 1/4 In.';
  if ((fraction - 0.50).abs() < 0.01) return '$whole 1/2 In.';
  if ((fraction - 0.75).abs() < 0.01) return '$whole 3/4 In.';
  return '$whole In.';
}

String abbreviateInchesLabel(String label) {
  return label.replaceAll(' Inches', ' In.');
}

/// Parses numeric or fractional inch strings like `4.25`, `4 1/4 Inches`, `4 1/4 In.`
double? parseInchesFromText(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final direct = double.tryParse(trimmed);
  if (direct != null) return direct;

  final normalized = trimmed
      .toLowerCase()
      .replaceAll('inches', '')
      .replaceAll('inch', '')
      .replaceAll('in.', '')
      .trim();

  final parts = normalized.split(RegExp(r'\s+'));
  if (parts.isEmpty) return null;

  final whole = double.tryParse(parts.first);
  if (whole == null) return null;
  if (parts.length == 1) return whole;

  switch (parts[1]) {
    case '1/4':
      return whole + 0.25;
    case '1/2':
      return whole + 0.5;
    case '3/4':
      return whole + 0.75;
    default:
      return whole;
  }
}
