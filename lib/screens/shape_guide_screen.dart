import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_breakpoints.dart';
import '../models/hat.dart';
import '../services/shopify_service.dart';
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
    required this.appBarLabel,
    required this.eyebrow,
    required this.title,
    required this.intro,
    required this.shapes,
    required this.metaField,
    this.footerNote,
  });

  /// Brim shapes guide.
  factory ShapeGuideScreen.brim() => const ShapeGuideScreen(
        appBarLabel: 'BRIM SHAPE GUIDE',
        eyebrow: 'KNOW YOUR BRIM',
        title: 'A Field Guide to Brim Shapes',
        intro:
            'From the cleanest flat brim to the show-pen polish of a '
            'Showmanship, here is how each shape is built — and the look '
            'it carries.',
        shapes: brimShapes,
        metaField: 'brimShape',
        footerNote:
            'Brim shape is mostly about looks and tradition — any of these can '
            'be shaped to your taste. Use it as a starting point, then filter '
            'the catalog by the brim you love.',
      );

  /// Crown shapes guide.
  factory ShapeGuideScreen.crown() => const ShapeGuideScreen(
        appBarLabel: 'CROWN SHAPE GUIDE',
        eyebrow: 'KNOW YOUR CROWN',
        title: 'A Field Guide to Crown Shapes',
        intro:
            'The crown is the heart of the hat. From the timeless Cattleman to '
            'the blank-canvas Open Crown, here is how each profile is creased '
            '— and the story it tells.',
        shapes: crownShapes,
        metaField: 'crownShape',
        footerNote:
            'Most felt hats can be re-creased into another crown by a hatter. '
            'Pick the profile you love here, then filter the catalog to match.',
      );

  final String appBarLabel;
  final String eyebrow;
  final String title;
  final String intro;
  final List<HatShapeInfo> shapes;
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

  Map<String, String> _exampleImages = {};

  @override
  void initState() {
    super.initState();
    _loadExampleImages();
  }

  Future<void> _loadExampleImages() async {
    final cached = ShopifyService.peekFullProducts();
    if (cached != null) {
      _exampleImages = _computeExampleImages(cached);
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
    final sorted = List<dynamic>.from(products)
      ..sort((a, b) => (a['title'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['title'] ?? '').toString().toLowerCase()));

    final used = <String>{};
    final result = <String, String>{};
    for (final shape in widget.shapes) {
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
      toolbarHeight: 88,
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
            height: 48,
          ),
          const SizedBox(height: 4),
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
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
              const SizedBox(height: 10),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _espresso,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 10),
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
                builder: (context, constraints) {
                  if (!twoUp) {
                    return Column(
                      children: [
                        for (final shape in widget.shapes) ...[
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
                      for (final shape in widget.shapes)
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
                },
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
            ],
          ),
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
          _buildThumb(),
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
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          imageUrl!,
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
