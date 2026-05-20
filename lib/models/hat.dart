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
  HatShapeInfo('Pinch Front', 'assets/images/crowns/pinch_front.png', 'Modern sharp crease with distinct front pinches.',
    history: 'The Pinch Front crown has long been a staple of both western wear and traditional dress hats. Its clean, sharp look became immensely popular as it creates a narrow, aerodynamic visual profile and provides excellent hand grip when donning or removing the hat.',
    famousWearers: [
      {'name': 'Vintage Fashion Icons', 'context': 'The pinch front was the signature crease of mid-century high-society travel hats.'},
      {'name': 'Modern Western Trailblazers', 'context': 'Professional style leaders frequently adopt the pinch front for its clean, photogenic profile.'},
    ],
    physicalDescription: 'Features a sharp crease down the center of the crown combined with two distinct, deep pinches at the front. Crown height is typically 4" to 4½". The front pinches draw the fabric or fur inward, creating a refined, tapering point. Fits heart-shaped and round faces beautifully, adding a sharp, angular focal point to soft facial structures.',
    galleryImages: ['assets/images/crowns/pinch_front.png']),
  HatShapeInfo('Gambler', 'assets/images/crowns/gambler.png', 'Classic flat-topped crown with circular indent.',
    history: 'The Gambler crown—historically associated with high-stakes players of the riverboat era and later popularized in classic films—originated from utility. Its low, flat circular top was designed to sit securely on the head during high winds on the open plains or on the decks of river steamers.',
    famousWearers: [
      {'name': 'Riverboat Players', 'context': 'The low circular top was highly practical and stayed securely placed during windy river crossings.'},
      {'name': 'Classic Western Actors', 'context': 'Spaghetti western movies popularized the gambler crease as a signature of cool, focused characters.'},
    ],
    physicalDescription: 'A low-profile crown (typically 3¾" to 4") characterized by a perfectly flat top with a subtle circular crease/indentation around the edge. The flat top keeps the center of gravity low and the overall look highly structured. Best suited for round and oval faces who want an elegant, distinctive silhouette that is less aggressive than a traditional Cattleman crease.',
    galleryImages: ['assets/images/crowns/gambler.png']),
  HatShapeInfo('Rounded Brick', 'assets/images/crowns/rounded_brick.png', 'Clean rectangular crease with soft rounded edges.',
    history: 'The Rounded Brick is a modern styling innovation that merges the commanding volume of a traditional Northern Plains brick crease with a softer, more approachable edge. It offers a contemporary, clean look for the modern rancher.',
    famousWearers: [
      {'name': 'Contemporary Ranchers', 'context': 'Introduced a softer edge to traditional northern plains brick shape for a premium everyday look.'},
    ],
    physicalDescription: 'A rectangular, squared-off box crease similar to the standard Brick, but with the top edge lines gently rounded rather than sharply creased. Crown height sits around 4" to 4¼". The softer corners provide a premium, smooth look while retaining the strong rectangular shape. Perfect for round and diamond face shapes by adding clean vertical lines without overly sharp angles.',
    galleryImages: ['assets/images/crowns/rounded_brick.png']),
  HatShapeInfo('Flat Cap', 'assets/images/crowns/flat_cap.png', 'Traditional rounded cap shape with small stiff brim.',
    history: 'Dating back to the 14th century in the British Isles, the Flat Cap represents the working class heritage of utility and durability. Originally made of wool, it became a standard of casual style worldwide, bridging traditional heritage with everyday outdoor life.',
    famousWearers: [
      {'name': 'British & Irish Artisans', 'context': 'The practical flat wool cap protected workers from weather for centuries.'},
      {'name': 'Peaky Blinders Cast', 'context': 'Popularized the vintage flat cap aesthetic for a new generation of style enthusiasts.'},
    ],
    physicalDescription: 'A rounded, low-profile cap crown with a small, stiff front brim. Fits snugly against the head. The top fabric or felt is pulled forward and sewn or snapped directly to the brim. A classic, timeless choice for casual styling and excellent protection in crisp weather. Highly versatile and works on every face shape.',
    galleryImages: ['assets/images/crowns/flat_cap.png']),
];

const List<HatShapeInfo> strawCrownShapes = [
  HatShapeInfo('Straw Cattleman', 'assets/images/crowns/cattleman.png', 'Popular straw pattern crease.'),
  HatShapeInfo('Straw Gus', 'assets/images/crowns/gus.png', 'Classic high front straw crease.'),
  HatShapeInfo('Straw Teardrop', 'assets/images/crowns/teardrop.png', 'Traditional fedora-style straw pinch.'),
];

const List<HatShapeInfo> brimShapes = [
  HatShapeInfo('Flat Brim', 'assets/images/placeholder.png', 'Classic medium flat brim, the most popular.',
    history: 'The Flat Brim is the workhorse of the western hat world — flat, wide enough to shade the neck, and neutral enough to work on every crown shape. It became the industry standard brim through the ranching era of the late 1800s and has never gone out of style.',
    famousWearers: [
      {'name': 'John Wayne', 'context': 'The Duke\'s signature look featured a classic flat brim throughout his career.'},
      {'name': 'Clint Eastwood', 'context': 'His spaghetti western characters wore flat brims that became iconic in cinema.'},
      {'name': 'Kevin Costner', 'context': 'His Yellowstone character John Dutton sports a crisp flat brim throughout the series.'},
    ],
    physicalDescription: 'A flat, level brim with no upward curl. Width typically 4\" to 4½\". The edges are finished with a simple binding or raw edge. The flatness provides maximum shade and a clean silhouette. Works with every crown shape. The most versatile and timeless brim in western tradition.',
    galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('J Curl', 'assets/images/placeholder.png', 'Subtle J-shaped upward curl on the sides.',
    history: 'The J Curl is a refined twist on the flat brim, with a slight upward sweep at the sides that gives the hat a more finished, dressy appearance. Popular in show circuits and dress western wear since the 1940s.',
    famousWearers: [
      {'name': 'Roy Rogers', 'context': 'The singing cowboy favored show-style brims with a subtle J curl for his performances.'},
      {'name': 'Gene Autry', 'context': 'Hollywood\'s original singing cowboy was known for his neatly curled brim presentation hats.'},
    ],
    physicalDescription: 'A brim with a slight J-shaped upward curl on both sides, keeping the front and back relatively flat. Width typically 4\" to 4½\". The curl adds elegance without going full rodeo. Best for dress western wear and special occasions. A subtle nod to showmanship.',
    galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('JB Curl', 'assets/images/placeholder.png', 'More pronounced J curl with sharper sweep.',
    history: 'The JB Curl takes the J Curl concept further with a more dramatic side sweep. Named for the shaping style popular in cutting horse and show competitions where a more pronounced brim curl signals a more formal presentation.',
    famousWearers: [
      {'name': 'Cutting horse competitors', 'context': 'Show circuits across Texas and Oklahoma have long favored the JB curl for its clean, formal appearance in the arena.'},
    ],
    physicalDescription: 'A more pronounced version of the J Curl with a sharper, higher sweep on both sides. Width typically 4\" to 4½\". The dramatic curl creates a distinctive profile that stands out in a crowd. Best for show, competition, and formal western events.',
    galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('West Texas Punch', 'assets/images/placeholder.png', 'Wide flat brim with a punched-down front.',
    history: 'Born from the hard-working ranches of West Texas where full sun protection was non-negotiable. The punched-down front keeps the brim out of sightlines while working cattle, while the wide flat body maximizes shade coverage.',
    famousWearers: [
      {'name': 'West Texas ranchers', 'context': 'The working cowboys of the Trans-Pecos region developed this brim style for maximum function in brutal summer heat.'},
      {'name': 'Sam Elliott', 'context': 'Has been seen in wide-brimmed, punched-down styles that evoke authentic ranch heritage.'},
    ],
    physicalDescription: 'A wide flat brim (typically 4½\" to 5\") with the front edge punched slightly downward for shade without obstructing vision. The sides remain flat. Maximum sun protection with a rugged, working aesthetic. Best for outdoor work and the authentic western rancher look.',
    galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('SC Curl', 'assets/images/placeholder.png', 'Full side curl from front to back.',
    history: 'The SC (Side Curl) traces its roots to rodeo performance culture where a more dramatic brim presentation set competitors apart in the arena. The full side curl from front to back creates an unmistakably "western show" silhouette.',
    famousWearers: [
      {'name': 'Professional rodeo competitors', 'context': 'The SC curl is a staple in barrel racing and roping circles where personal style is as important as performance.'},
    ],
    physicalDescription: 'A full curl that runs continuously from the front of the brim around both sides to the back. Width typically 4\" to 4½\". Creates a cohesive, elegant curved profile from every angle. One of the dressiest western brim shapes available. Best for rodeo, show, and formal western events.',
    galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('RD Curl', 'assets/images/placeholder.png', 'Rolled back front brim with curled sides.',
    history: 'The RD Curl originated in the Southwest where both practicality and style mattered equally. The rolled-back front keeps the brim elevated for better forward visibility, while the curled sides maintain a finished, presentable look.',
    famousWearers: [
      {'name': 'Southwest ranch hands', 'context': 'Cowboys working the brush country of South Texas developed this brim for clear sightlines while still looking put together in town.'},
    ],
    physicalDescription: 'Front of the brim rolls upward while both sides curl consistently. Width typically 4\" to 4½\". The upward front roll gives the hat an open, confident look. Highly versatile — works for both work and dress. One of the most personalized and expressive brim options.',
    galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('U Curl', 'assets/images/placeholder.png', 'Deep symmetrical U-shaped curl all around.',
    history: 'The U Curl is the most dramatic of all western brim shapes — both sides curl up uniformly to create a deep U profile from front to back. It became popular in trick riding and theatrical western performance where silhouette impact was everything.',
    famousWearers: [
      {'name': 'Trick riders & performers', 'context': 'The theatrical western performance circuit has long favored the dramatic U curl for its unmistakable stage presence.'},
      {'name': 'Tejano artists', 'context': 'Many Tejano and regional Mexican artists have embraced the deep U curl as part of their signature stage look.'},
    ],
    physicalDescription: 'Both sides curl up uniformly into a deep U shape from front to back. Width typically 4\" to 4½\". The dramatic symmetrical curl creates maximum visual impact. The most theatrical of all brim shapes. Best for performers, entertainers, and anyone who wants to make a bold statement.',
    galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Taco', 'assets/images/placeholder.png', 'Both sides folded up tightly, taco-style.',
    history: 'The Taco brim — where both sides fold up sharply — is one of the oldest brim traditions in vaquero culture. Spanish cowboys of the Southwest developed this style for riding through dense brush where a flat brim would catch on branches.',
    famousWearers: [
      {'name': 'Vaqueros', 'context': 'The original Mexican cowboys developed the taco fold for practical brush-country riding centuries ago.'},
      {'name': 'Freddie Fender', 'context': 'The legendary Tex-Mex artist was often photographed in a classic taco-brimmed hat that became part of his cultural identity.'},
    ],
    physicalDescription: 'Both sides of the brim fold sharply upward creating a taco or shell shape. Width typically 4\" to 4½\". The tight fold creates a very narrow visible profile from the front. Highly functional in brush and tight spaces. A deeply traditional vaquero style with centuries of heritage.',
    galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Extra Wide', 'assets/images/placeholder.png', 'Oversized brim for maximum shade and impact.',
    history: 'The extra wide brim (5\" and above) is the ultimate sun hat — developed by cowboys who worked in relentless heat and needed every inch of shade they could get. Today it also makes one of the most dramatic style statements in western fashion.',
    famousWearers: [
      {'name': 'Stevie Ray Vaughan', 'context': 'The blues legend was rarely seen without his oversized wide-brimmed hat, making it one of the most iconic looks in music history.'},
      {'name': 'Hat Trick cowboys', 'context': 'Competitors at major western shows often choose extra wide brims to maximize their visual presence in the arena.'},
    ],
    physicalDescription: 'A brim of 5\" or wider that extends significantly beyond the standard range. Can be flat or styled with any curl. Maximum shade coverage and maximum visual impact. Makes a strong, confident statement. Best for hot climates, large face shapes, and anyone who wants an unforgettable silhouette.',
    galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Medium Curved', 'assets/images/placeholder.png', 'Classic moderately curved western brim.',
    history: 'The Medium Curved brim is a highly popular option among everyday ranchers and cowboys, offering a perfect balance between standard flat brims and extreme rodeo curves.',
    famousWearers: [
      {'name': 'George Strait', 'context': 'Often prefers a clean, medium-curved brim setup for his signature western look.'},
    ],
    physicalDescription: 'Featuring a gentle, symmetrical upward curve on the sides, the front and back of the brim slope elegantly downward. Highly versatile and fits almost all face shapes.',
    galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Gus', 'assets/images/placeholder.png', 'Sloped old-west style brim.',
    history: 'Inspired by traditional old-west trail drivers, the Gus brim crease has a strong forward-dipping slope that keeps sun and weather out of the eyes while riding.',
    famousWearers: [
      {'name': 'Augustus McCrae', 'context': 'The legendary Lonesome Dove character\'s iconic signature look.'},
    ],
    physicalDescription: 'A distinct front dip combined with flat or slightly upturned sides. Pairs beautifully with a Gus crown for an authentic frontier profile.',
    galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('Shovel Front', 'assets/images/placeholder.png', 'Distinct flat front edge with curled sides.',
    history: 'The Shovel Front is a specialized performance crease designed to maximize forward sightlines and face shading while rodeo roping or working cattle.',
    famousWearers: [
      {'name': 'Professional Ropers', 'context': 'Highly favored by arena competitors for clean sightlines and unique appearance.'},
    ],
    physicalDescription: 'The front edge of the brim is flattened out straight like a shovel, while the sides are neatly curled up. Extremely functional and bold.',
    galleryImages: ['assets/images/placeholder.png']),
  HatShapeInfo('CHL', 'assets/images/placeholder.png', 'Rebellious, low-profile roll brim.',
    history: 'A vintage and counter-culture favorite, the Cool Hand Luke (CHL) style brim features a relaxed, rebellious curl with a classic old-school swagger.',
    famousWearers: [
      {'name': 'Paul Newman', 'context': 'Defined the effortlessly cool, non-conformist aesthetic.'},
    ],
    physicalDescription: 'A tight but low-profile side roll combined with a flat, direct front. Minimalist yet filled with vintage character.',
    galleryImages: ['assets/images/placeholder.png']),
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
