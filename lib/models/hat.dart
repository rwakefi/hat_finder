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

/// Fallback catalog — names align with Shopify `custom.crown_shape` validation choices.
const List<HatShapeInfo> crownShapes = [
  HatShapeInfo('Cattleman\'s', 'assets/images/crowns/cattleman.png',
      'Classic crease, most popular style.',
      history:
          'The Cattleman\'s crease is the most iconic cowboy hat shape in American history. Originating in the late 1800s among Texas ranchers, its three-crease design channels rain away from the face. It became the gold standard for working cowboys and remains the best-selling western hat shape worldwide.',
      famousWearers: [
        {
          'name': 'George Strait',
          'context':
              'The "King of Country" has made the Cattleman\'s his signature look for over four decades.'
        },
        {
          'name': 'Lyndon B. Johnson',
          'context':
              'The 36th President was rarely seen on his Texas ranch without his Cattleman\'s Stetson.'
        },
        {
          'name': 'John Wayne',
          'context':
              'Wore variations of the Cattleman\'s crease throughout his legendary western film career.'
        },
      ],
      physicalDescription:
          'Three distinct creases run the length of the crown — one center dent flanked by two side pinches. Crown height typically ranges from 4" to 4½". The most versatile crown shape.',
      galleryImages: [
        'assets/images/crowns/cattleman.png',
        'assets/images/crowns/brick.png'
      ]),
  HatShapeInfo('Pinch Front', 'assets/images/crowns/pinch_front.png',
      'Modern sharp crease with distinct front pinches.',
      history:
          'The Pinch Front crown has long been a staple of both western wear and traditional dress hats. Its clean, sharp look became immensely popular as it creates a narrow, aerodynamic visual profile.',
      famousWearers: [
        {
          'name': 'Vintage Fashion Icons',
          'context':
              'The pinch front was the signature crease of mid-century high-society travel hats.'
        },
      ],
      physicalDescription:
          'A sharp center crease with two distinct, deep pinches at the front. Crown height is typically 4" to 4½".',
      galleryImages: ['assets/images/crowns/pinch_front.png']),
  HatShapeInfo('Gus', 'assets/images/crowns/gus.png',
      'High slanted back with three prominent dimples.',
      history:
          'Made famous by Augustus "Gus" McCrae in "Lonesome Dove," this crown blends Hollywood romance with authentic ranch heritage.',
      famousWearers: [
        {
          'name': 'Robert Duvall',
          'context':
              'Immortalized this crown shape as Gus McCrae in "Lonesome Dove" (1989).'
        },
        {
          'name': 'Sam Elliott',
          'context':
              'Has been seen sporting Gus-style crowns throughout his career.'
        },
      ],
      physicalDescription:
          'A high crown (4½" to 5½") with a distinctive forward slope and three prominent dimples.',
      galleryImages: [
        'assets/images/crowns/gus.png',
        'assets/images/crowns/teardrop.png'
      ]),
  HatShapeInfo('Teardrop', 'assets/images/crowns/teardrop.png',
      'Classic fedora-style teardrop pinch.',
      history:
          'Traces its roots to European fedora styling of the early 20th century — equally at home on Broadway or the back forty.',
      famousWearers: [
        {
          'name': 'Frank Sinatra',
          'context':
              'Made the teardrop fedora a symbol of smooth sophistication.'
        },
        {
          'name': 'Indiana Jones (Harrison Ford)',
          'context':
              'The adventurer\'s iconic hat features a teardrop-inspired crown pinch.'
        },
      ],
      physicalDescription:
          'A teardrop-shaped pinch at the front, tapering to a subtle point. Crown height is typically 4" to 4½".',
      galleryImages: ['assets/images/crowns/teardrop.png']),
  HatShapeInfo('Telescope', 'assets/images/crowns/telescope.png',
      'Flat "pork-pie" style circular crease.',
      history:
          'Features a flat circular indent that creates a distinctive cylinder shape — popularized by jazz musicians and adopted by southwestern ranchers.',
      famousWearers: [
        {
          'name': 'Lester Young',
          'context': 'Made the pork pie/telescope hat his iconic signature.'
        },
      ],
      physicalDescription:
          'A flat, circular indent on top creating a telescope or cylinder shape. Height is typically 3¾" to 4½".',
      galleryImages: ['assets/images/crowns/telescope.png']),
  HatShapeInfo('Gambler', 'assets/images/crowns/gambler.png',
      'Classic flat-topped crown with circular indent.',
      history:
          'Associated with riverboat players and classic western films — a low, flat circular top designed to sit securely in wind.',
      famousWearers: [
        {
          'name': 'Riverboat Players',
          'context':
              'The low circular top stayed secure during windy river crossings.'
        },
      ],
      physicalDescription:
          'A low-profile crown with a flat top and subtle circular crease around the edge. Typically 3¾" to 4".',
      galleryImages: ['assets/images/crowns/gambler.png']),
  HatShapeInfo('Brick', 'assets/images/crowns/brick.png',
      'Squared-off crease, great for a wider profile.',
      history:
          'Popular among ranchers in the Northern Plains and Rocky Mountain states for excellent sun coverage and a commanding silhouette.',
      famousWearers: [
        {
          'name': 'Wyoming & Montana Ranchers',
          'context': 'The Brick is the signature crown of the Northern Plains.'
        },
      ],
      physicalDescription:
          'A flat-topped, rectangular crown with squared-off edges. Typical height is 4" to 4½".',
      galleryImages: ['assets/images/crowns/brick.png']),
  HatShapeInfo('Open Crown', 'assets/images/crowns/open_crown.png',
      'Unshaped, ready to be customized.',
      history:
          'The open crown is the original, unblocked hat body — a blank canvas. Before modern hat shaping, every cowboy hat started as an open crown that the owner would crease and shape by hand to suit their personality and needs on the trail.',
      famousWearers: [
        {
          'name': 'Every Working Cowboy',
          'context':
              'Before hat shops existed, every cowboy started with an open crown and shaped it themselves on the range.'
        },
        {
          'name': 'John B. Stetson',
          'context':
              'The original "Boss of the Plains" was sold as an open crown — the customer decided the crease.'
        },
      ],
      physicalDescription:
          'An uncreased, round-topped crown with no shaping applied. The crown stands tall and symmetrical, typically 4½" to 5½" in height. This is the starting point for all custom hat shaping — a blank canvas that can be creased, pinched, and formed to any style. Best suited for customers who want a fully custom experience.',
      galleryImages: [
        'assets/images/crowns/open_crown.png',
        'assets/images/crowns/cattleman.png',
        'assets/images/crowns/gus.png'
      ]),
  HatShapeInfo('Minnick',
      'assets/images/crowns/minnick.png', 'A sharper, more defined cattleman crease.',
      history:
          'The Minnick is a sharper evolution of the classic Cattleman\'s crease, favored by rodeo professionals and modern ranchers who want a more angular, defined look. Its clean geometric lines give it a contemporary edge while honoring traditional western form.',
      famousWearers: [
        {
          'name': 'Tuf Cooper',
          'context':
              'The world champion tie-down roper is known for his sharp Minnick crease in the arena.'
        },
        {
          'name': 'Modern Rodeo Cowboys',
          'context':
              'The Minnick has become the go-to shape for professional rodeo competitors who want a sharp, contemporary look.'
        },
      ],
      physicalDescription:
          'A more angular variation of the Cattleman\'s with sharper, more defined crease lines. The center dent is narrower and deeper, and the side rails are more pronounced. Crown height is typically 4" to 4¼". The sharper angles create a more modern, aggressive silhouette. Best suited for angular and square face shapes. A favorite among younger cowboys and rodeo professionals.',
      galleryImages: [
        'assets/images/crowns/minnick.png',
        'assets/images/crowns/cattleman.png'
      ]),
  HatShapeInfo('Texas Punch', 'assets/images/crowns/texas_punch.png',
      'Distinctive high pinched front.',
      history:
          'Born in the vast open ranges of West Texas, this high pinched crown was designed to create airflow in extreme heat. The dramatic front pinch became a signature of the Permian Basin oil field workers and ranchers who needed breathability in 100°+ summers.',
      famousWearers: [
        {
          'name': 'Permian Basin Oil Workers',
          'context':
              'The high front pinch was designed for airflow in 100°+ West Texas heat — born from necessity.'
        },
        {
          'name': 'West Texas Ranchers',
          'context':
              'A regional signature shape that instantly identifies the wearer as hailing from the Permian Basin.'
        },
      ],
      physicalDescription:
          'Features a dramatic high pinch at the front of the crown, creating a distinctive V-shaped profile from the front. Crown height is typically 4½" to 5". The elevated front pinch allows air circulation in extreme heat. The bold shape makes a strong statement. Best for oval and round face shapes — the height and pinch add vertical dimension and angular structure.',
      galleryImages: [
        'assets/images/crowns/texas_punch.png',
        'assets/images/crowns/cattleman.png'
      ]),
  HatShapeInfo('Cool Hand Luke', 'assets/images/crowns/cool_hand_luke.png',
      'Iconic rounded, slightly sloping top.',
      history:
          'Inspired by Paul Newman\'s unforgettable 1967 film, this rounded, slightly sloping crown embodies rebellious cool. Its understated shape became a counterculture symbol — the hat of a man who plays by his own rules.',
      famousWearers: [
        {
          'name': 'Paul Newman',
          'context':
              'Defined this shape in the 1967 film "Cool Hand Luke" — a symbol of effortless rebellion.'
        },
        {
          'name': 'Steve McQueen',
          'context':
              'The "King of Cool" was often seen in similar rounded, understated crown shapes.'
        },
        {
          'name': 'Matthew McConaughey',
          'context':
              'Has been spotted wearing Cool Hand Luke-style crowns, channeling that same Texas cool.'
        },
      ],
      physicalDescription:
          'A smooth, rounded crown with a gentle forward slope and no sharp creases. Height is typically 4" to 4½". The soft, organic shape has no aggressive angles — it\'s all smooth curves. Creates an approachable, laid-back silhouette. Works well with virtually any face shape due to its rounded, neutral profile. The most "effortlessly cool" of all the crown shapes.',
      galleryImages: ['assets/images/crowns/cool_hand_luke.png']),
  HatShapeInfo('Rounded Brick', 'assets/images/crowns/rounded_brick.png',
      'Clean rectangular crease with soft rounded edges.',
      history:
          'The Rounded Brick is a modern styling innovation that merges the commanding volume of a traditional Northern Plains brick crease with a softer, more approachable edge. It offers a contemporary, clean look for the modern rancher.',
      famousWearers: [
        {
          'name': 'Contemporary Ranchers',
          'context':
              'Introduced a softer edge to traditional northern plains brick shape for a premium everyday look.'
        },
      ],
      physicalDescription:
          'A rectangular, squared-off box crease similar to the standard Brick, but with the top edge lines gently rounded rather than sharply creased. Crown height sits around 4" to 4¼". The softer corners provide a premium, smooth look while retaining the strong rectangular shape. Perfect for round and diamond face shapes by adding clean vertical lines without overly sharp angles.',
      galleryImages: ['assets/images/crowns/rounded_brick.png']),
  HatShapeInfo('Flat Cap', 'assets/images/crowns/flat_cap.png',
      'Traditional rounded cap shape with small stiff brim.',
      history:
          'Dating back to the 14th century in the British Isles, the Flat Cap represents the working class heritage of utility and durability. Originally made of wool, it became a standard of casual style worldwide, bridging traditional heritage with everyday outdoor life.',
      famousWearers: [
        {
          'name': 'British & Irish Artisans',
          'context':
              'The practical flat wool cap protected workers from weather for centuries.'
        },
        {
          'name': 'Peaky Blinders Cast',
          'context':
              'Popularized the vintage flat cap aesthetic for a new generation of style enthusiasts.'
        },
      ],
      physicalDescription:
          'A rounded, low-profile cap crown with a small, stiff front brim. Fits snugly against the head. The top fabric or felt is pulled forward and sewn or snapped directly to the brim. A classic, timeless choice for casual styling and excellent protection in crisp weather. Highly versatile and works on every face shape.',
      galleryImages: ['assets/images/crowns/flat_cap.png']),
];

/// Fallback catalog — names align with Shopify `custom.brim_shape` validation choices.
const List<HatShapeInfo> brimShapes = [
  HatShapeInfo('Slightly Curved', 'assets/images/placeholder.png',
      'Gentle, subtle curve along the brim edge.',
      history:
          'A refined everyday brim with just enough curve to soften the silhouette without going full dress or rodeo.',
      famousWearers: [],
      physicalDescription:
          'A light, even curve around the brim — dressy but understated. Works well with city and fedora crowns.',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Medium Curved', 'assets/images/placeholder.png',
      'Classic moderately curved western brim.',
      history:
          'The Medium Curved brim is a highly popular option among everyday ranchers and cowboys, offering a perfect balance between standard flat brims and extreme rodeo curves.',
      famousWearers: [
        {
          'name': 'George Strait',
          'context':
              'Often prefers a clean, medium-curved brim setup for his signature western look.'
        },
      ],
      physicalDescription:
          'Featuring a gentle, symmetrical upward curve on the sides, the front and back of the brim slope elegantly downward. Highly versatile and fits almost all face shapes.',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('CHL (Cool Hand Luke)', 'assets/images/placeholder.png',
      'Rebellious, low-profile roll brim.',
      history:
          'A vintage and counter-culture favorite, the Cool Hand Luke (CHL) style brim features a relaxed, rebellious curl with a classic old-school swagger.',
      famousWearers: [
        {
          'name': 'Paul Newman',
          'context': 'Defined the effortlessly cool, non-conformist aesthetic.'
        },
      ],
      physicalDescription:
          'A tight but low-profile side roll combined with a flat, direct front. Minimalist yet filled with vintage character.',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('J (George Strait)', 'assets/images/placeholder.png',
      'Subtle J-shaped upward curl on the sides.',
      history:
          'The J curl is a refined twist on the flat brim, with a slight upward sweep at the sides that gives the hat a more finished, dressy appearance.',
      famousWearers: [
        {
          'name': 'George Strait',
          'context':
              'Helped popularize the clean J-curl brim in modern western dress wear.'
        },
      ],
      physicalDescription:
          'A slight J-shaped upward curl on both sides, keeping the front and back relatively flat. Width typically 4" to 4½".',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('WTP (West Texas Punch)', 'assets/images/placeholder.png',
      'Wide flat brim with a punched-down front.',
      history:
          'Born from the hard-working ranches of West Texas where full sun protection was non-negotiable.',
      famousWearers: [
        {
          'name': 'West Texas ranchers',
          'context':
              'Developed this brim style for maximum function in brutal summer heat.'
        },
      ],
      physicalDescription:
          'A wide flat brim with the front edge punched slightly downward for shade without obstructing vision.',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('JB', 'assets/images/placeholder.png',
      'More pronounced J curl with sharper sweep.',
      history:
          'The JB curl takes the J curl further with a more dramatic side sweep, popular in show and cutting circuits.',
      famousWearers: [],
      physicalDescription:
          'A sharper, higher J-shaped sweep on both sides. Width typically 4" to 4½".',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Shovel Width', 'assets/images/placeholder.png',
      'Distinct flat front edge with curled sides.',
      history:
          'Designed to maximize forward sightlines and face shading while roping or working cattle.',
      famousWearers: [
        {
          'name': 'Professional ropers',
          'context': 'Favored for clean sightlines and a bold front profile.'
        },
      ],
      physicalDescription:
          'The front edge is flattened straight like a shovel, while the sides are neatly curled up.',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Taco', 'assets/images/placeholder.png',
      'Both sides folded up tightly, taco-style.',
      history:
          'One of the oldest brim traditions in vaquero culture — both sides fold up sharply for brush country riding.',
      famousWearers: [
        {
          'name': 'Vaqueros',
          'context':
              'Developed the taco fold for practical brush-country riding centuries ago.'
        },
      ],
      physicalDescription:
          'Both sides of the brim fold sharply upward creating a taco or shell shape.',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Half Taco/Minnick', 'assets/images/placeholder.png',
      'A partial taco fold with a Minnick-style profile.',
      history:
          'Blends the vaquero taco tradition with the specialized Minnick crease for a distinctive asymmetric look.',
      famousWearers: [],
      physicalDescription:
          'A tighter, partial side fold — less extreme than a full taco, with Minnick character.',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Flip up or Down', 'assets/images/placeholder.png',
      'Versatile brim that can be worn flipped up or down.',
      history:
          'A flexible dress brim style that adapts to sun, wind, and formal presentation.',
      famousWearers: [],
      physicalDescription:
          'Can be shaped with the brim edge turned up or left down depending on look and function.',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Pulled Down', 'assets/images/placeholder.png',
      'Brim pulled down for shade and a low profile.',
      history:
          'Favored when maximum brow shade and a grounded, understated silhouette are desired.',
      famousWearers: [],
      physicalDescription:
          'The brim is shaped downward around the crown for extra shade and a composed look.',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Flanged Brim', 'assets/images/placeholder.png',
      'Brim with a defined flanged edge.',
      history:
          'The flanged edge adds structure and a crisp finished line — common on dress and heritage felts.',
      famousWearers: [],
      physicalDescription:
          'Features a distinct turned or flanged outer edge for a sharp, tailored outline.',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Pencil Curl', 'assets/images/placeholder.png',
      'Tight, fine curl along the brim edge.',
      history:
          'A precise dress brim finish — the curl is narrow and crisp like a pencil line.',
      famousWearers: [],
      physicalDescription:
          'A very tight, narrow curl around the brim perimeter. Elegant and formal.',
      galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Flat/RD (Round)', 'assets/images/placeholder.png',
      'Flat brim or rolled round (RD) profile.',
      history:
          'Combines the classic flat brim with the rolled round curl popular in southwest dress wear.',
      famousWearers: [
        {
          'name': 'Southwest ranch hands',
          'context':
              'The rolled round profile balances sightlines with a finished town look.'
        },
      ],
      physicalDescription:
          'Either a level flat brim or sides curled in a continuous round profile.',
      galleryImages: ['assets/images/placeholder.png']),
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
