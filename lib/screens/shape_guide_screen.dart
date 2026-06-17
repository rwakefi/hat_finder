import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_breakpoints.dart';
import '../models/hat.dart';
import '../services/shopify_service.dart';
import '../theme/moon_ridge_logo_sizes.dart';
import '../theme/section_title_style.dart';
import '../theme/wizard_header_spacing.dart';
import '../widgets/web_content_scope.dart';

/// A visual glossary of hat shapes (brim or crown) carried in the catalog.
///
/// Names align with the Shopify validation choices for the given metafield.
/// Each entry pairs the curated definition with a representative product image
/// pulled from the live catalog (matched on the metafield value), falling back
/// to a styled monogram when no product photo is available.
class ShapeGuideScreen extends StatefulWidget {
  const ShapeGuideScreen({
    super.key,
    required this.isCrown,
    required this.appBarLabel,
    required this.eyebrow,
    required this.title,
    required this.intro,
    required this.metaField,
    this.footerNote,
  });

  /// Brim shapes guide.
  factory ShapeGuideScreen.brim() => const ShapeGuideScreen(
        isCrown: false,
        appBarLabel: 'BRIM SHAPE GUIDE',
        eyebrow: 'KNOW YOUR BRIM',
        title: 'A Field Guide to Brim Shapes',
        intro:
            'From the cleanest flat brim to the show-pen polish of a '
            'Showmanship, here is how each shape is built — and the look '
            'it carries.',
        metaField: 'brimShape',
        footerNote:
            'Brim shape is mostly about looks and tradition — any of these can '
            'be shaped to your taste. Use it as a starting point, then filter '
            'the catalog by the brim you love.',
      );

  /// Crown shapes guide.
  factory ShapeGuideScreen.crown() => const ShapeGuideScreen(
        isCrown: true,
        appBarLabel: 'CROWN SHAPE GUIDE',
        eyebrow: 'KNOW YOUR CROWN',
        title: 'A Field Guide to Crown Shapes',
        intro:
            'The crown is the heart of the hat. From the timeless Cattleman to '
            'the blank-canvas Open Crown, here is how each profile is creased '
            '— and the story it tells.',
        metaField: 'crownShape',
        footerNote:
            'Most felt hats can be re-creased into another crown by a hatter. '
            'Pick the profile you love here, then filter the catalog to match.',
      );

  final bool isCrown;
  final String appBarLabel;
  final String eyebrow;
  final String title;
  final String intro;
  final String metaField;
  final String? footerNote;

  @override
  State<ShapeGuideScreen> createState() => _ShapeGuideScreenState();
}

class _ShapeGuideScreenState extends State<ShapeGuideScreen> {
  static const Color _espresso = Color(0xFF2D2926);
  static const Color _surface = Color(0xFFFAF8F5);
  static const Color _accent = Color(0xFF559C99);
  static const Color _border = Color(0xFFE4DED1);

  late List<HatShapeInfo> _shapes;
  Map<String, String> _exampleImages = {};

  List<HatShapeInfo> get _fallbackShapes =>
      widget.isCrown ? crownShapes : brimShapes;

  @override
  void initState() {
    super.initState();
    _shapes = List<HatShapeInfo>.from(_fallbackShapes);
    _loadGuideData();
  }

  Future<void> _loadGuideData() async {
    await _loadValidationOrder();
    await _loadExampleImages();
  }

  Future<void> _loadValidationOrder() async {
    final key = widget.isCrown ? 'crown_shapes' : 'brim_shapes';
    final cached = ShopifyService.peekValidationChoices();
    if (cached != null) {
      final names = cached[key];
      if (names != null && names.isNotEmpty && mounted) {
        setState(() {
          _shapes = _orderedGuideShapes(
            widget.isCrown
                ? ShopifyService.filterCrownValidationChoices(names)
                : names,
          );
        });
      }
    }
    try {
      final choices = await ShopifyService.fetchValidationChoices(
        forceRefresh: cached == null,
      );
      final names = choices[key];
      if (names == null || names.isEmpty || !mounted) return;
      setState(() {
        _shapes = _orderedGuideShapes(
          widget.isCrown
              ? ShopifyService.filterCrownValidationChoices(names)
              : names,
        );
      });
    } catch (_) {
      // Fallback catalog order is fine offline.
    }
  }

  List<HatShapeInfo> _orderedGuideShapes(List<String> names) {
    final shapes = <HatShapeInfo>[];
    for (final name in names) {
      for (final part in _expandGuideShapeName(name)) {
        shapes.add(_enrichGuideShape(part));
      }
    }
    return shapes;
  }

  /// Crown guide expands combined Shopify labels; the wizard keeps one card.
  List<String> _expandGuideShapeName(String name) {
    if (!widget.isCrown) return [name];
    final normalized = name.toLowerCase().replaceAll("'s", '').trim();
    if (normalized.contains('walker') && normalized.contains('west texas punch')) {
      return const ['Walker', 'West Texas Punch'];
    }
    return [name];
  }

  HatShapeInfo _enrichGuideShape(String name) {
    if (widget.isCrown) {
      final guideOnly = _crownGuideOnlyShapes[name];
      if (guideOnly != null) return guideOnly;
    }
    return _enrichShapeName(name);
  }

  static const Map<String, HatShapeInfo> _crownGuideOnlyShapes = {
    'Walker': HatShapeInfo(
      'Walker',
      'assets/images/crowns/walker.png',
      'Two small side dents, no center crease.',
      famousWearers: [
        {
          'name': 'Ryan Bingham',
          'context': 'Yellowstone',
        },
      ],
      physicalDescription: 'Two small side dents, no center crease.',
    ),
    'West Texas Punch': HatShapeInfo(
      'West Texas Punch',
      'assets/images/crowns/texas_punch.png',
      'Two deep sweeping side dents.',
      physicalDescription: 'Two deep sweeping side dents.',
    ),
  };

  HatShapeInfo _enrichShapeName(String name) {
    for (final shape in _fallbackShapes) {
      if (shape.name == name) return shape;
      if (ShopifyService.matchShape(shape.name, name)) {
        return HatShapeInfo(
          name,
          shape.imagePath,
          shape.description,
          history: shape.history,
          famousWearers: shape.famousWearers,
          physicalDescription: shape.physicalDescription,
          galleryImages: shape.galleryImages,
        );
      }
    }
    return HatShapeInfo(
      name,
      'assets/images/placeholder.png',
      widget.isCrown ? 'Custom shaped crown.' : 'Custom shaped brim.',
      physicalDescription: widget.isCrown
          ? 'Individually creased custom crown.'
          : 'Individually shaped custom brim.',
    );
  }

  Future<void> _loadExampleImages() async {
    final cached = ShopifyService.peekFullProducts();
    if (cached != null) {
      final images = _computeExampleImages(cached);
      if (!mounted) return;
      setState(() => _exampleImages = images);
      return;
    }
    try {
      final products = await ShopifyService.fetchFullProducts();
      if (!mounted) return;
      setState(() {
        _exampleImages = _computeExampleImages(products);
      });
    } catch (_) {
      // Definitions still render fine without product photos.
    }
  }

  /// Deterministically map each shape to a representative catalog image.
  Map<String, String> _computeExampleImages(List<dynamic> products) {
    final sorted = ShopifyService.sortPickerExampleProducts(products);

    final used = <String>{};
    final result = <String, String>{};
    for (final shape in _shapes) {
      for (final product in sorted) {
        if (ShopifyService.isExcludedFromHatFinderExamples(product)) continue;
        if (!ShopifyService.isHatFinderCatalogProduct(product)) continue;
        final imageUrl = product['featuredImage']?['url'];
        if (imageUrl == null || imageUrl.toString().isEmpty) continue;
        final url = imageUrl.toString();
        if (used.contains(url)) continue;
        final prodValue =
            ShopifyService.parseMetafieldValue(product[widget.metaField]);
        if (prodValue.isEmpty) continue;
        if (ShopifyService.matchShape(prodValue, shape.name)) {
          result[shape.name] = url;
          used.add(url);
          break;
        }
      }

      if (result.containsKey(shape.name)) continue;

      final preferred = ShopifyService.pickPreferredShapeExample(
        shapeName: shape.name,
        products: sorted,
        shapeMetaKey: widget.metaField,
      );
      if (preferred != null) {
        final url = preferred['url']!;
        if (!used.contains(url)) {
          result[shape.name] = url;
          used.add(url);
        }
      }
    }
    return result;
  }

  /// Short monogram for the fallback tile (e.g. `J`, `WTP`, `OPEN`).
  /// Combined Shopify labels split or omitted from the main guide grid.
  static const List<String> _guideExcludedCrownLabels = [
    'Mule Kick/Horseshoe',
  ];

  /// Guide-only entries for the Non-Traditional Crowns section.
  static const List<HatShapeInfo> _nonTraditionalGuideShapes = [
    HatShapeInfo(
      'Horseshoe',
      'assets/images/crowns/round_top.png',
      'A low-profile crown pressed into the curved silhouette of a horseshoe.',
      physicalDescription:
          'A specialty crown shape where the top of the hat is pressed into the '
          'curved silhouette of a horseshoe — a low-profile, round-backed style '
          'typically around 4¼" in height, often paired with a mule kick in the '
          'front. More custom conversation piece than everyday crease.',
    ),
    HatShapeInfo(
      'Coffin',
      'assets/images/crowns/square_top.png',
      'A tapered crown wider at the shoulders, narrowing toward the top.',
      physicalDescription:
          'A specialty crown shaped to mirror the tapered silhouette of a coffin '
          '— wider at the shoulders, narrowing toward the top. Not for everyone.',
    ),
  ];

  bool _isGuideExcludedCrownShape(String name) {
    for (final label in _guideExcludedCrownLabels) {
      if (ShopifyService.matchShape(name, label)) return true;
    }
    return false;
  }

  List<HatShapeInfo> get _primaryGuideShapes {
    if (!widget.isCrown) return _shapes;
    return _shapes
        .where((shape) => !_isGuideExcludedCrownShape(shape.name))
        .toList();
  }

  String _monogram(String name) {
    final head = name.split('(').first.trim();
    final firstToken = head.split(RegExp(r'[\s/]')).first.trim();
    if (firstToken.isEmpty) return '?';
    if (firstToken.length <= 3) return firstToken.toUpperCase();
    return firstToken.substring(0, 4).toUpperCase();
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: _espresso,
      toolbarHeight: MoonRidgeLogoSizes.secondaryAppBar +
          WizardHeaderSpacing.gap +
          18,
      centerTitle: true,
      leading: Navigator.of(context).canPop()
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _goBack,
            )
          : null,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/images/Moon Ridge Header Logo.png',
            height: MoonRidgeLogoSizes.secondaryAppBar,
          ),
          const SizedBox(height: WizardHeaderSpacing.gap),
          Text(
            widget.appBarLabel,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: _espresso,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final twoUp = AppBreakpoints.isTablet(context);

    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: WebContentScope(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, WizardHeaderSpacing.gap, 20, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.eyebrow,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: _accent,
                ),
              ),
              const SizedBox(height: WizardHeaderSpacing.gap),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: SectionTitleStyle.playfairBold(
                  fontSize: SectionTitleStyle.guide,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: WizardHeaderSpacing.gap),
              Text(
                widget.intro,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  height: 1.5,
                  color: _espresso.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) =>
                    _buildShapeCardGrid(_primaryGuideShapes, constraints, twoUp),
              ),
              if (widget.footerNote != null) ...[
                const SizedBox(height: 8),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F1EA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Text(
                    widget.footerNote!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      height: 1.5,
                      color: _espresso.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
              if (widget.isCrown) ...[
                const SizedBox(height: 32),
                _buildCrownVariationsSection(),
                if (_nonTraditionalGuideShapes.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  _buildCrownNonTraditionalSection(twoUp),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShapeCardGrid(
    List<HatShapeInfo> shapes,
    BoxConstraints constraints,
    bool twoUp,
  ) {
    if (!twoUp) {
      return Column(
        children: [
          for (final shape in shapes) ...[
            _ShapeCard(
              shape: shape,
              imageUrl: _exampleImages[shape.name],
              monogram: _monogram(shape.name),
            ),
            const SizedBox(height: 14),
          ],
        ],
      );
    }
    const spacing = 16.0;
    final cardWidth = (constraints.maxWidth - spacing) / 2;
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (final shape in shapes)
          SizedBox(
            width: cardWidth,
            child: _ShapeCard(
              shape: shape,
              imageUrl: _exampleImages[shape.name],
              monogram: _monogram(shape.name),
            ),
          ),
      ],
    );
  }

  Widget _buildGuideSectionHeader({
    required String eyebrow,
    required String title,
    required String intro,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          eyebrow,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: _accent,
          ),
        ),
        const SizedBox(height: WizardHeaderSpacing.gap),
        Text(
          title,
          textAlign: TextAlign.center,
          style: SectionTitleStyle.playfairBold(
            fontSize: SectionTitleStyle.guide * 0.72,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          intro,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            height: 1.5,
            color: _espresso.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  static const List<_GuideVariation> _crownVariations = [
    _GuideVariation(
      title: 'Mule Kick',
      monogram: 'MK',
      body:
          'A mule kick is a sharp inward dent pressed into the front of the crown '
          '— a subtle but distinctive modification that adds character and a slightly '
          'more aggressive, worn-in look to almost any crease style. It\'s a custom '
          'add-on a skilled hat shaper can steam and press in on request, and like '
          'its namesake, it leaves an impression.',
    ),
    _GuideVariation(
      title: 'Cutter Bumps',
      monogram: 'CB',
      body:
          "A modified Cattleman's feature where the side dents of the crown are "
          'bumped outward. Originally favored by cutting horse competitors to keep '
          'their hat secure at speed — and considered an optional add-on that a hat '
          'shaper can press in on request.',
    ),
  ];

  Widget _buildCrownVariationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGuideSectionHeader(
          eyebrow: 'VARIATIONS',
          title: 'Variations',
          intro:
              'Optional custom details a hat shaper can steam and press in on request.',
        ),
        const SizedBox(height: 20),
        for (final variation in _crownVariations) ...[
          _VariationCard(variation: variation),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildCrownNonTraditionalSection(bool twoUp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildGuideSectionHeader(
          eyebrow: 'NON-TRADITIONAL CROWNS',
          title: 'Non-Traditional Crowns',
          intro:
              'Profiles that step outside the classic center-crease tradition — '
              'flat tops, open domes, and shapes built for a different kind of statement.',
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) => _buildShapeCardGrid(
            _nonTraditionalGuideShapes,
            constraints,
            twoUp,
          ),
        ),
      ],
    );
  }
}

class _GuideVariation {
  const _GuideVariation({
    required this.title,
    required this.monogram,
    required this.body,
    this.imagePath,
  });

  final String title;
  final String monogram;
  final String body;
  final String? imagePath;
}

class _VariationCard extends StatelessWidget {
  const _VariationCard({required this.variation});

  final _GuideVariation variation;

  static const Color _espresso = Color(0xFF2D2926);
  static const Color _accent = Color(0xFF559C99);
  static const Color _border = Color(0xFFE4DED1);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumb(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variation.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _espresso,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  variation.body,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    height: 1.5,
                    color: _espresso.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb() {
    const double size = 84;
    final radius = BorderRadius.circular(12);
    final imagePath = variation.imagePath;
    if (imagePath != null) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          imagePath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildMonogram(size, radius),
        ),
      );
    }
    return _buildMonogram(size, radius);
  }

  Widget _buildMonogram(double size, BorderRadius radius) {
    final monogram = variation.monogram;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6FB3B0), _accent],
        ),
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: Text(
        monogram,
        style: GoogleFonts.playfairDisplay(
          fontSize: monogram.length > 2 ? 18 : 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _ShapeCard extends StatelessWidget {
  const _ShapeCard({
    required this.shape,
    required this.monogram,
    this.imageUrl,
  });

  final HatShapeInfo shape;
  final String monogram;
  final String? imageUrl;

  static const Color _espresso = Color(0xFF2D2926);
  static const Color _accent = Color(0xFF559C99);
  static const Color _border = Color(0xFFE4DED1);

  @override
  Widget build(BuildContext context) {
    final definition = shape.physicalDescription.isNotEmpty
        ? shape.physicalDescription
        : shape.description;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildThumb(context),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shape.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: _espresso,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  definition,
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    height: 1.5,
                    color: _espresso.withValues(alpha: 0.78),
                  ),
                ),
                if (shape.famousWearers.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    shape.famousWearers
                        .map((w) => '${w['name']} — ${w['context']}')
                        .join(' · '),
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                      color: _accent.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumb(BuildContext context) {
    const double size = 84;
    final radius = BorderRadius.circular(12);
    final cacheWidth =
        (size * MediaQuery.devicePixelRatioOf(context)).round();
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: cacheWidth,
          errorBuilder: (_, __, ___) => _buildMonogram(size, radius),
        ),
      );
    }
    return _buildMonogram(size, radius);
  }

  Widget _buildMonogram(double size, BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6FB3B0), _accent],
        ),
        borderRadius: radius,
      ),
      alignment: Alignment.center,
      child: Text(
        monogram,
        style: GoogleFonts.playfairDisplay(
          fontSize: monogram.length > 2 ? 18 : 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
