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
  final List<String> galleryImages;

  const HatShapeInfo(
    this.name,
    this.imagePath,
    this.description, {
    this.galleryImages = const [],
  });
}

const List<HatShapeInfo> hatTypes = [
  HatShapeInfo('Felt', 'assets/images/red_rocks.webp', 'Classic fur or wool felt hats.'),
  HatShapeInfo('Straw', 'assets/images/straw_hat.jpg', 'Woven straw hats for warmer weather.'),
  HatShapeInfo('Ballcap', 'assets/images/ballcap.png', 'Casual structured and unstructured caps.'),
  HatShapeInfo('Any Type', 'assets/images/placeholder.png', 'Search across all hat styles.'),
];

const List<HatShapeInfo> feltCrownShapes = [
  HatShapeInfo('Open Crown', 'assets/images/crowns/open_crown.png', 'Unshaped, ready to be customized.', galleryImages: ['assets/images/crowns/open_crown.png', 'assets/images/crowns/cattleman.png', 'assets/images/crowns/gus.png']),
  HatShapeInfo('Cattleman\'s', 'assets/images/crowns/cattleman.png', 'Classic crease, most popular style.', galleryImages: ['assets/images/crowns/cattleman.png', 'assets/images/crowns/brick.png', 'assets/images/crowns/minnick.png']),
  HatShapeInfo('Minnick', 'assets/images/crowns/minnick.png', 'A sharper, more defined cattleman crease.', galleryImages: ['assets/images/crowns/minnick.png', 'assets/images/crowns/cattleman.png']),
  HatShapeInfo('Brick', 'assets/images/crowns/brick.png', 'Squared-off crease, great for a wider profile.', galleryImages: ['assets/images/crowns/brick.png', 'assets/images/crowns/square_top.png']),
  HatShapeInfo('Walker', 'assets/images/crowns/walker.png', 'Low profile, traditional box crease.', galleryImages: ['assets/images/crowns/walker.png']),
  HatShapeInfo('Texas Punch', 'assets/images/crowns/texas_punch.png', 'Distinctive high pinched front.', galleryImages: ['assets/images/crowns/texas_punch.png', 'assets/images/crowns/cattleman.png']),
  HatShapeInfo('Gus', 'assets/images/crowns/gus.png', 'High slanted back with three prominent dimples.', galleryImages: ['assets/images/crowns/gus.png', 'assets/images/crowns/teardrop.png']),
  HatShapeInfo('Cool Hand Luke', 'assets/images/crowns/cool_hand_luke.png', 'Iconic rounded, slightly sloping top.', galleryImages: ['assets/images/crowns/cool_hand_luke.png']),
  HatShapeInfo('Teardrop', 'assets/images/crowns/teardrop.png', 'Classic fedora-style teardrop pinch.', galleryImages: ['assets/images/crowns/teardrop.png', 'assets/images/crowns/gus.png']),
  HatShapeInfo('Square Top', 'assets/images/crowns/square_top.png', 'Flat, sharp-edged classic look.', galleryImages: ['assets/images/crowns/square_top.png']),
  HatShapeInfo('Round Top', 'assets/images/crowns/round_top.png', 'Smooth, uncreased domed top.', galleryImages: ['assets/images/crowns/round_top.png']),
  HatShapeInfo('Telescope', 'assets/images/crowns/telescope.png', 'Flat "pork-pie" style circular crease.', galleryImages: ['assets/images/crowns/telescope.png']),
];

const List<HatShapeInfo> strawCrownShapes = [
  HatShapeInfo('Straw Cattleman', 'assets/images/crowns/cattleman.png', 'Popular straw pattern crease.'),
  HatShapeInfo('Straw Gus', 'assets/images/crowns/gus.png', 'Classic high front straw crease.'),
  HatShapeInfo('Straw Teardrop', 'assets/images/crowns/teardrop.png', 'Traditional fedora-style straw pinch.'),
];

const List<HatShapeInfo> brimShapes = [
  HatShapeInfo('Cool Hand Luke', 'assets/images/placeholder.png', 'A description of this shape.'),
  HatShapeInfo('J', 'assets/images/placeholder.png', 'A description of this shape.'),
  HatShapeInfo('JB', 'assets/images/placeholder.png', 'A description of this shape.'),
  HatShapeInfo('West Texas Punch', 'assets/images/placeholder.png', 'A description of this shape.'),
  HatShapeInfo('SC', 'assets/images/placeholder.png', 'A description of this shape.'),
  HatShapeInfo('RD', 'assets/images/placeholder.png', 'A description of this shape.'),
  HatShapeInfo('U', 'assets/images/placeholder.png', 'A description of this shape.'),
  HatShapeInfo('Taco', 'assets/images/placeholder.png', 'A description of this shape.'),
  HatShapeInfo('Extra Wide', 'assets/images/placeholder.png', 'A description of this shape.'),
];

const List<String> brimWidths = [
  '4 Inches',
  '4 1/4 Inches',
  '4 1/2 Inches',
  '4 3/4 Inches',
  '5 Inches',
];

String formatMeasurement(double val) {
  int whole = val.truncate();
  double fraction = val - whole;
  if ((fraction - 0.25).abs() < 0.01) return '$whole 1/4 Inches';
  if ((fraction - 0.50).abs() < 0.01) return '$whole 1/2 Inches';
  if ((fraction - 0.75).abs() < 0.01) return '$whole 3/4 Inches';
  return '$whole Inches';
}
