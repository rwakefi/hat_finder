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
}

const List<HatShapeInfo> hatTypes = [
  HatShapeInfo('Felt', 'assets/images/red_rocks.webp', 'Classic fur or wool felt hats.'),
  HatShapeInfo('Straw', 'assets/images/straw_hat.jpg', 'Woven straw hats for warmer weather.'),
  HatShapeInfo('Ballcap', 'assets/images/ballcap.png', 'Casual structured and unstructured caps.'),
];

const List<HatShapeInfo> feltCrownShapes = [
  HatShapeInfo('Open Crown', 'assets/images/crowns/open_crown.png', 'Unshaped, ready to be customized.',
    history: 'The open crown is the original, unblocked hat body — a blank canvas. Before modern hat shaping, every cowboy hat started as an open crown that the owner would crease and shape by hand to suit their personality and needs on the trail.',
    famousWearers: [
      {'name': 'Every Working Cowboy', 'context': 'Before hat shops existed, every cowboy started with an open crown and shaped it themselves on the range.'},
      {'name': 'John B. Stetson', 'context': 'The original "Boss of the Plains" was sold as an open crown — the customer decided the crease.'},
    ],
    physicalDescription: 'An uncreased, round-topped crown with no shaping applied. The crown stands tall and symmetrical, typically 4½" to 5½" in height. This is the starting point for all custom hat shaping — a blank canvas that can be creased, pinched, and formed to any style. Best suited for customers who want a fully custom experience.',
    galleryImages: ['assets/images/crowns/open_crown.png', 'assets/images/crowns/cattleman.png', 'assets/images/crowns/gus.png']),
  HatShapeInfo('Cattleman\'s', 'assets/images/crowns/cattleman.png', 'Classic crease, most popular style.',
    history: 'The Cattleman\'s crease is the most iconic cowboy hat shape in American history. Originating in the late 1800s among Texas ranchers, its three-crease design channels rain away from the face. It became the gold standard for working cowboys and remains the best-selling western hat shape worldwide.',
    famousWearers: [
      {'name': 'George Strait', 'context': 'The "King of Country" has made the Cattleman\'s his signature look for over four decades.'},
      {'name': 'Lyndon B. Johnson', 'context': 'The 36th President was rarely seen on his Texas ranch without his Cattleman\'s Stetson.'},
      {'name': 'John Wayne', 'context': 'Wore variations of the Cattleman\'s crease throughout his legendary western film career.'},
      {'name': 'J.R. Ewing (Larry Hagman)', 'context': 'The iconic Dallas villain made the Cattleman\'s synonymous with Texas oil money.'},
    ],
    physicalDescription: 'Three distinct creases run the length of the crown — one center dent flanked by two side pinches. Crown height typically ranges from 4" to 4½". The symmetrical design creates a clean, balanced profile that complements nearly every face shape. The most versatile crown shape; works equally well for ranch work, rodeo, or a night out. Ideal for oval, square, and heart-shaped faces.',
    galleryImages: ['assets/images/crowns/cattleman.png', 'assets/images/crowns/brick.png', 'assets/images/crowns/minnick.png']),
  HatShapeInfo('Minnick', 'assets/images/crowns/minnick.png', 'A sharper, more defined cattleman crease.',
    history: 'The Minnick is a sharper evolution of the classic Cattleman\'s crease, favored by rodeo professionals and modern ranchers who want a more angular, defined look. Its clean geometric lines give it a contemporary edge while honoring traditional western form.',
    famousWearers: [
      {'name': 'Tuf Cooper', 'context': 'The world champion tie-down roper is known for his sharp Minnick crease in the arena.'},
      {'name': 'Modern Rodeo Cowboys', 'context': 'The Minnick has become the go-to shape for professional rodeo competitors who want a sharp, contemporary look.'},
    ],
    physicalDescription: 'A more angular variation of the Cattleman\'s with sharper, more defined crease lines. The center dent is narrower and deeper, and the side rails are more pronounced. Crown height is typically 4" to 4¼". The sharper angles create a more modern, aggressive silhouette. Best suited for angular and square face shapes. A favorite among younger cowboys and rodeo professionals.',
    galleryImages: ['assets/images/crowns/minnick.png', 'assets/images/crowns/cattleman.png']),
  HatShapeInfo('Brick', 'assets/images/crowns/brick.png', 'Squared-off crease, great for a wider profile.',
    history: 'The Brick crease gets its name from its distinctive squared-off, rectangular shape. Popular among ranchers in the Northern Plains and Rocky Mountain states, its flat top provides excellent sun coverage and gives the wearer a commanding, broad-shouldered silhouette.',
    famousWearers: [
      {'name': 'Wyoming & Montana Ranchers', 'context': 'The Brick is the signature crown of the Northern Plains, where its wide profile shields against harsh high-altitude sun.'},
      {'name': 'Yellowstone Cast', 'context': 'Several characters in the hit series sport Brick-style crowns, reflecting authentic Montana ranch culture.'},
    ],
    physicalDescription: 'A flat-topped, rectangular crown with squared-off edges and clean 90-degree crease lines. The crown appears wider and boxier than a Cattleman\'s. Typical height is 4" to 4½" with a notably wider profile. Creates a broad, commanding silhouette. Best for round and oval face shapes — the angular lines add structure. The flat top provides maximum sun coverage.',
    galleryImages: ['assets/images/crowns/brick.png', 'assets/images/crowns/square_top.png']),
  HatShapeInfo('Walker', 'assets/images/crowns/walker.png', 'Low profile, traditional box crease.',
    history: 'Named after the legendary Texas Rangers, the Walker is a low-profile box crease that sits close to the head. Its practical, no-nonsense design made it the preferred choice of lawmen and working cowboys who needed a hat that wouldn\'t catch the wind.',
    famousWearers: [
      {'name': 'Texas Rangers', 'context': 'The low-profile Walker was the preferred choice of the legendary lawmen — practical and wind-resistant.'},
      {'name': 'Walker, Texas Ranger (Chuck Norris)', 'context': 'While the show took creative liberties, the Walker crease pays homage to Ranger heritage.'},
    ],
    physicalDescription: 'A low-profile box crease that sits closer to the head than most western crowns. Height is typically 3¾" to 4¼". The compact shape is wind-resistant and practical for working conditions. The lower profile creates a more understated, workmanlike appearance. Best for taller individuals or those with longer face shapes who want to avoid adding too much height.',
    galleryImages: ['assets/images/crowns/walker.png']),
  HatShapeInfo('West Texas Punch', 'assets/images/crowns/texas_punch.png', 'Distinctive high pinched front.',
    history: 'Born in the vast open ranges of West Texas, this high pinched crown was designed to create airflow in extreme heat. The dramatic front pinch became a signature of the Permian Basin oil field workers and ranchers who needed breathability in 100°+ summers.',
    famousWearers: [
      {'name': 'Permian Basin Oil Workers', 'context': 'The high front pinch was designed for airflow in 100°+ West Texas heat — born from necessity.'},
      {'name': 'West Texas Ranchers', 'context': 'A regional signature shape that instantly identifies the wearer as hailing from the Permian Basin.'},
    ],
    physicalDescription: 'Features a dramatic high pinch at the front of the crown, creating a distinctive V-shaped profile from the front. Crown height is typically 4½" to 5". The elevated front pinch allows air circulation in extreme heat. The bold shape makes a strong statement. Best for oval and round face shapes — the height and pinch add vertical dimension and angular structure.',
    galleryImages: ['assets/images/crowns/texas_punch.png', 'assets/images/crowns/cattleman.png']),
  HatShapeInfo('Gus', 'assets/images/crowns/gus.png', 'High slanted back with three prominent dimples.',
    history: 'The Gus crown was made famous by Robert Duvall\'s character Augustus "Gus" McCrae in the 1989 miniseries "Lonesome Dove." Its distinctive high, sloping front and three-dimple crease has become one of the most requested shapes, blending Hollywood romance with authentic ranch heritage.',
    famousWearers: [
      {'name': 'Robert Duvall', 'context': 'His portrayal of Augustus "Gus" McCrae in "Lonesome Dove" (1989) immortalized this crown shape forever.'},
      {'name': 'Tommy Lee Jones', 'context': 'As Woodrow Call in the same miniseries, he helped make the Gus shape a cultural icon.'},
      {'name': 'Sam Elliott', 'context': 'The quintessential cowboy actor has been seen sporting Gus-style crowns throughout his career.'},
      {'name': 'Kevin Costner', 'context': 'Wore Gus-influenced shapes in "Open Range" and "Yellowstone."'},
    ],
    physicalDescription: 'A high crown (4½" to 5½") with a distinctive forward slope and three prominent dimples — one center and two side. The front of the crown sits higher than the back, creating a dramatic, sweeping profile. The asymmetric slope gives it more personality than a standard Cattleman\'s. Best for round and square face shapes — the height elongates the face. One of the most recognizable and requested shapes.',
    galleryImages: ['assets/images/crowns/gus.png', 'assets/images/crowns/teardrop.png']),
  HatShapeInfo('Cool Hand Luke', 'assets/images/crowns/cool_hand_luke.png', 'Iconic rounded, slightly sloping top.',
    history: 'Inspired by Paul Newman\'s unforgettable 1967 film, this rounded, slightly sloping crown embodies rebellious cool. Its understated shape became a counterculture symbol — the hat of a man who plays by his own rules.',
    famousWearers: [
      {'name': 'Paul Newman', 'context': 'Defined this shape in the 1967 film "Cool Hand Luke" — a symbol of effortless rebellion.'},
      {'name': 'Steve McQueen', 'context': 'The "King of Cool" was often seen in similar rounded, understated crown shapes.'},
      {'name': 'Matthew McConaughey', 'context': 'Has been spotted wearing Cool Hand Luke-style crowns, channeling that same Texas cool.'},
    ],
    physicalDescription: 'A smooth, rounded crown with a gentle forward slope and no sharp creases. Height is typically 4" to 4½". The soft, organic shape has no aggressive angles — it\'s all smooth curves. Creates an approachable, laid-back silhouette. Works well with virtually any face shape due to its rounded, neutral profile. The most "effortlessly cool" of all the crown shapes.',
    galleryImages: ['assets/images/crowns/cool_hand_luke.png']),
  HatShapeInfo('Teardrop', 'assets/images/crowns/teardrop.png', 'Classic fedora-style teardrop pinch.',
    history: 'The teardrop pinch traces its roots to European fedora styling of the early 20th century. When it crossed the Atlantic into the American West, it became the bridge between city sophistication and frontier grit — equally at home on Broadway or the back forty.',
    famousWearers: [
      {'name': 'Humphrey Bogart', 'context': 'The iconic leading man popularized the teardrop fedora pinch in classic Hollywood noir.'},
      {'name': 'Indiana Jones (Harrison Ford)', 'context': 'The adventurer\'s iconic hat features a teardrop-inspired crown pinch.'},
      {'name': 'Frank Sinatra', 'context': 'Made the teardrop fedora a symbol of smooth sophistication and style.'},
    ],
    physicalDescription: 'Features a teardrop-shaped pinch at the front of the crown, creating a soft, tapered point. Crown height is typically 4" to 4½". The rounded back narrows to a subtle point at the front, creating an elegant asymmetric profile. Bridges western and urban styling. Best for square and heart-shaped faces — the rounded curves soften angular features. The most versatile crossover shape.',
    galleryImages: ['assets/images/crowns/teardrop.png', 'assets/images/crowns/gus.png']),
  HatShapeInfo('Square Top', 'assets/images/crowns/square_top.png', 'Flat, sharp-edged classic look.',
    history: 'The Square Top is one of the oldest hat shapes in western tradition, dating back to the Spanish vaqueros. Its flat, uncreased crown was the standard before decorative creasing became popular. Today it represents a purist\'s approach to western heritage.',
    famousWearers: [
      {'name': 'Spanish Vaqueros', 'context': 'The original cowboys wore flat-topped hats centuries before the American West was settled.'},
      {'name': 'Amish & Mennonite Communities', 'context': 'The simple, uncreased flat top remains a staple of traditional Plain community dress.'},
    ],
    physicalDescription: 'A flat, uncreased crown with sharp, squared-off edges at the top. Height is typically 4" to 5". The perfectly flat top creates a clean, architectural silhouette with no curves or creases. The most minimalist of all crown shapes. Best for round and oval face shapes — the flat, angular top adds structure and definition. A purist\'s choice that honors the oldest traditions.',
    galleryImages: ['assets/images/crowns/square_top.png']),
  HatShapeInfo('Round Top', 'assets/images/crowns/round_top.png', 'Smooth, uncreased domed top.',
    history: 'The Round Top, or "Boss of the Plains," was the original silhouette created by John B. Stetson in 1865. It\'s the ancestor of every cowboy hat that followed. Its smooth, uncreased dome was designed for maximum durability and rain shedding on the open range.',
    famousWearers: [
      {'name': 'John B. Stetson', 'context': 'Created the original "Boss of the Plains" in 1865 — the hat that started it all.'},
      {'name': 'Buffalo Bill Cody', 'context': 'Wore a round-topped Stetson during his famous Wild West shows that toured the world.'},
      {'name': 'Teddy Roosevelt', 'context': 'Sported a round-topped hat during his Rough Riders campaign and ranching years in the Dakotas.'},
    ],
    physicalDescription: 'A smooth, uncreased dome with a perfectly rounded top. Height is typically 4½" to 5½". The dome shape sheds rain naturally in all directions. No creases, pinches, or flat surfaces — pure organic curve. The grandfather of all western hat shapes. Works well with angular and square face shapes — the rounded crown softens hard jaw lines.',
    galleryImages: ['assets/images/crowns/round_top.png']),
  HatShapeInfo('Telescope', 'assets/images/crowns/telescope.png', 'Flat "pork-pie" style circular crease.',
    history: 'The Telescope crown — also known as the "pork pie" — features a flat circular indent that creates a distinctive cylinder shape. Popularized by jazz musicians and later adopted by ranchers in the Southwest, it bridges musical culture with western utility.',
    famousWearers: [
      {'name': 'Lester Young', 'context': 'The legendary jazz saxophonist made the pork pie/telescope hat his iconic signature.'},
      {'name': 'Buster Keaton', 'context': 'The silent film star\'s flat-topped pork pie became one of the most recognizable hats in cinema history.'},
      {'name': 'Bryan Cranston (Walter White)', 'context': 'The Heisenberg hat in Breaking Bad was a modern telescope crown that became a cultural phenomenon.'},
    ],
    physicalDescription: 'Features a flat, circular indent on top of the crown, creating a telescope or cylinder shape. Height is typically 3¾" to 4½". The flat circular top with pinched sides creates a distinctive, compact profile unlike any other western shape. Best for oval and longer face shapes — the lower, flatter profile avoids adding too much height. A bold, artistic choice that stands out from traditional western shapes.',
    galleryImages: ['assets/images/crowns/telescope.png']),
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
