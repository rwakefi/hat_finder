import 'package:flutter/material.dart';
import 'shop_webview_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/shopify_service.dart';
import '../services/database_service.dart';
import '../models/hat.dart';
import '../models/head_measurement_profile.dart';
import '../models/head_shape_profile.dart';
import '../widgets/fine_tuning_tray.dart';

class HatResultsScreen extends StatefulWidget {
  final HeadShapeProfile? headShapeProfile;
  final HeadMeasurementProfile? headMeasurementProfile;
  final String? hatType;
  final String? westernStyle;
  final String? crownShape;
  final List<double>? crownHeights;
  final String? brimShape;
  final List<String>? brimWidths;

  /// Instant results from the wizard cache (full catalog loaded in background).
  final List<dynamic>? preloadedHats;
  final List<HatShapeInfo>? crownShapeOptions;
  final List<HatShapeInfo>? brimShapeOptions;

  const HatResultsScreen({
    super.key,
    this.headShapeProfile,
    this.headMeasurementProfile,
    this.hatType,
    this.westernStyle,
    this.crownShape,
    this.crownHeights,
    this.brimShape,
    this.brimWidths,
    this.preloadedHats,
    this.crownShapeOptions,
    this.brimShapeOptions,
  });

  @override
  State<HatResultsScreen> createState() => _HatResultsScreenState();
}

class _HatResultsScreenState extends State<HatResultsScreen> {
  late Future<List<dynamic>> _hatsFuture;
  String? _selectedColor;
  Map<String, List<({String color, String variantGid})>> _swatchCache = {};
  List<dynamic>? _fullCatalog;
  bool _fineTuningExpanded = false;
  late String? _filterHatType;
  late String? _filterCrownShape;
  late String? _filterBrimShape;
  late List<double> _filterCrownHeights;
  late List<String> _filterBrimWidths;

  // Brand colors — consistent with the rest of the app & moonridgecompany.com
  static const Color _espresso = Color(0xFF2D2926);
  static const Color _turquoise = Color(0xFF559C99);
  static const Color _white = Colors.white;
  static const Color _offWhite = Color(0xFFF8F7F5);
  static const Color _borderGrey = Color(0xFFE8E5E1);

  @override
  void initState() {
    super.initState();
    _filterHatType = widget.hatType;
    _filterCrownShape = widget.crownShape;
    _filterBrimShape = widget.brimShape;
    _filterCrownHeights = List<double>.from(widget.crownHeights ?? []);
    _filterBrimWidths = List<String>.from(widget.brimWidths ?? []);

    if (widget.preloadedHats != null) {
      _rebuildSwatchCache(widget.preloadedHats!);
      _hatsFuture = Future.value(widget.preloadedHats);
    } else {
      _hatsFuture = _fetchFilteredHats();
    }
    _loadFullCatalog();
  }

  bool get _showsFineTuningTray {
    final type = (_filterHatType ?? widget.hatType ?? '').toLowerCase();
    return !type.contains('ballcap') &&
        !type.contains('beanie') &&
        !type.contains('flat cap');
  }

  Future<List<dynamic>> _fetchFilteredHats() async {
    final all = await ShopifyService.fetchFullProducts();
    _fullCatalog = all;
    return _filterCatalog(all);
  }

  Future<void> _loadFullCatalog() async {
    if (_fullCatalog != null) {
      _applyFilters();
      return;
    }
    try {
      final all = await ShopifyService.fetchFullProducts();
      if (!mounted) return;
      _fullCatalog = all;
      _applyFilters();
    } catch (_) {
      // Keep showing current results if catalog load fails.
    }
  }

  List<dynamic> _filterCatalog(List<dynamic> catalog) {
    return ShopifyService.filterProducts(
      catalog,
      hatType: _filterHatType,
      westernStyle: widget.westernStyle,
      crownShape: _filterCrownShape,
      crownHeights:
          _filterCrownHeights.isEmpty ? null : _filterCrownHeights,
      brimShape: _filterBrimShape,
      brimWidths: _filterBrimWidths.isEmpty ? null : _filterBrimWidths,
    );
  }

  void _applyFilters() {
    final source = _fullCatalog;
    if (source == null) return;
    final filtered = _filterCatalog(source);
    setState(() {
      _selectedColor = null;
      _rebuildSwatchCache(filtered);
      _hatsFuture = Future.value(filtered);
    });
  }

  void _onFineTuningChanged(FineTuningValues values) {
    setState(() {
      _filterHatType = values.hatType;
      _filterCrownShape = values.crownShape;
      _filterBrimShape = values.brimShape;
      _filterCrownHeights = List<double>.from(values.crownHeights);
      _filterBrimWidths = List<String>.from(values.brimWidths);
    });
    _applyFilters();
  }

  String _crownSummaryLabel() {
    final shape = _filterCrownShape ?? 'Any';
    final heights = _filterCrownHeights.isEmpty
        ? 'Any'
        : _filterCrownHeights.map(formatMeasurement).join(', ');
    return '$shape ($heights)';
  }

  String _brimSummaryLabel() {
    final shape = _filterBrimShape ?? 'Any';
    final widths = _filterBrimWidths.isEmpty
        ? 'Any'
        : _filterBrimWidths.join(', ');
    return '$shape ($widths)';
  }

  String _metaValue(dynamic entry) {
    final value = ShopifyService.parseMetafieldValue(entry);
    return value.isEmpty ? '—' : value;
  }

  void _rebuildSwatchCache(List<dynamic> hats) {
    _swatchCache = {
      for (final hat in hats) (hat['id'] as String): _computeSwatchColors(hat),
    };
  }

  List<({String color, String variantGid})> _swatchColorsFor(dynamic hat) {
    final id = hat['id'] as String?;
    if (id != null && _swatchCache.containsKey(id)) {
      return _swatchCache[id]!;
    }
    return _computeSwatchColors(hat);
  }

  bool _isFeltHat(dynamic hat) {
    final material = _metaValue(hat['feltStrawOrBallcap']).toLowerCase();
    return material.contains('felt');
  }

  bool _isStrawHat(dynamic hat) {
    final material = _metaValue(hat['feltStrawOrBallcap']).toLowerCase();
    return material.contains('straw');
  }

  /// Felt hats only; straw and ballcaps never show color swatches.
  bool _shouldShowColorSwatches(dynamic hat) =>
      _isFeltHat(hat) && !_isStrawHat(hat);

  bool _variantIsAvailable(dynamic node) {
    if (node['availableForSale'] == true) return true;
    final qty = (node['inventoryQuantity'] as num?)?.toInt();
    if (qty == null) return false;
    return qty > 0 || qty == -1;
  }

  /// In-stock felt colors with a variant id for deep-linking (includes single-color felt).
  List<({String color, String variantGid})> _computeSwatchColors(dynamic hat) {
    if (!_shouldShowColorSwatches(hat)) return [];

    final variants = hat['variants']?['edges'] as List<dynamic>? ?? [];
    final availableByColor = <String, bool>{};
    final variantByColor = <String, String>{};

    for (final edge in variants) {
      final node = edge['node'];
      if (node == null) continue;
      String? colorName;
      for (final opt in (node['selectedOptions'] as List<dynamic>? ?? [])) {
        if (opt['name'].toString().toLowerCase() == 'color') {
          colorName = opt['value'].toString();
          break;
        }
      }
      if (colorName == null || colorName.isEmpty) continue;
      if (_variantIsAvailable(node)) {
        availableByColor[colorName] = true;
        variantByColor.putIfAbsent(colorName, () => node['id'] as String);
      }
    }

    var colors = availableByColor.keys
        .map((c) => (color: c, variantGid: variantByColor[c]!))
        .toList()
      ..sort((a, b) => a.color.compareTo(b.color));

    if (colors.isNotEmpty) return colors;

    // Metafield color when there is no Color option (uncommon on felt).
    final colorMeta = _metaValue(hat['color']);
    if (colorMeta != '—' && colorMeta.isNotEmpty) {
      for (final edge in variants) {
        final node = edge['node'];
        if (node != null && _variantIsAvailable(node) && node['id'] != null) {
          return [(color: colorMeta, variantGid: node['id'] as String)];
        }
      }
    }

    return [];
  }

  String _productUrlForVariant(String baseUrl, String variantGid) {
    final variantId = variantGid.split('/').last;
    final uri = Uri.parse(baseUrl);
    return uri.replace(
      queryParameters: {...uri.queryParameters, 'variant': variantId},
    ).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 90,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new, color: _espresso, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Moon Ridge Header Logo.png',
              height: 45.0,
            ),
            const SizedBox(height: 2),
            Text(
              'RESULTS',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                color: _espresso,
                letterSpacing: 3.0,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Turquoise progress accent line
          Container(height: 3, color: _turquoise),
          _buildSearchSummary(),
          const Divider(height: 1, color: _borderGrey),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _hatsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: _turquoise),
                        const SizedBox(height: 24),
                        Text(
                          'Finding Your Perfect Hat...',
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            color: _espresso.withValues(alpha: 0.5),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}',
                        style: const TextStyle(color: Colors.red)),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 56,
                              color: _espresso.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'No Matches Found',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: _espresso,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your shape or size filters.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: _espresso.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final hats = snapshot.data!;
                if (_swatchCache.isEmpty ||
                    _swatchCache.length != hats.length) {
                  _rebuildSwatchCache(hats);
                }

                // Extract unique in-stock colors from returned products
                final Set<String> availableColors = {};
                for (final hat in hats) {
                  for (final entry in _swatchColorsFor(hat)) {
                    availableColors.add(entry.color);
                  }
                }
                final sortedColors = availableColors.toList()..sort();

                // Filter by selected color
                final filteredHats = _selectedColor == null
                    ? hats
                    : hats.where((hat) {
                        return _swatchColorsFor(hat).any(
                          (entry) =>
                              entry.color.toLowerCase() ==
                              _selectedColor!.toLowerCase(),
                        );
                      }).toList();

                return Column(
                  children: [
                    // Color filter bar
                    if (sortedColors.isNotEmpty)
                      Container(
                        color: _white,
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Row(
                          children: [
                            Icon(Icons.palette_outlined,
                                size: 16,
                                color: _espresso.withValues(alpha: 0.4)),
                            const SizedBox(width: 8),
                            Text(
                              'COLOR',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: _turquoise,
                                letterSpacing: 2.0,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: [
                                    // "All" chip
                                    Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _selectedColor = null),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _selectedColor == null
                                                ? _turquoise
                                                : _white,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: _selectedColor == null
                                                  ? _turquoise
                                                  : _borderGrey,
                                            ),
                                          ),
                                          child: Text(
                                            'All',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _selectedColor == null
                                                  ? _white
                                                  : _espresso,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Color chips
                                    ...sortedColors.map((color) {
                                      final isSelected =
                                          _selectedColor == color;
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(right: 6),
                                        child: GestureDetector(
                                          onTap: () => setState(
                                              () => _selectedColor = color),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? _turquoise
                                                  : _white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected
                                                    ? _turquoise
                                                    : _borderGrey,
                                              ),
                                            ),
                                            child: Text(
                                              color,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isSelected
                                                    ? _white
                                                    : _espresso,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (sortedColors.isNotEmpty)
                      const Divider(height: 1, color: _borderGrey),
                    // Grid
                    Expanded(
                      child: filteredHats.isEmpty
                          ? Center(
                              child: Text(
                                'No hats in this color.',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  color: _espresso.withValues(alpha: 0.4),
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(12, 12, 12, 32),
                              addAutomaticKeepAlives: false,
                              addRepaintBoundaries: true,
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                                childAspectRatio: 0.45,
                              ),
                              itemCount: filteredHats.length,
                              itemBuilder: (context, index) {
                                return RepaintBoundary(
                                  child: _buildHatCard(filteredHats[index]),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHatCard(dynamic hat) {
    final title = hat['title'] ?? 'Unknown Hat';
    final imageUrl = hat['featuredImage']?['url'];

    // Metafield values
    final crownShape = _metaValue(hat['crownShape']);
    final material = _metaValue(hat['material']);
    final brimShape = _metaValue(hat['brimShape']);
    final hatTypeLower = (widget.hatType ?? '').toLowerCase();
    final isBallcap = hatTypeLower.contains('ballcap') ||
        hatTypeLower.contains('beanie') ||
        hatTypeLower.contains('flat cap');

    final swatchColors = _swatchColorsFor(hat);
    final imageCacheWidth = (MediaQuery.sizeOf(context).width *
            0.5 *
            MediaQuery.devicePixelRatioOf(context))
        .round();

    String priceStr = '';
    try {
      final variant = hat['variants']?['edges']?[0]?['node'];
      if (variant != null) {
        final priceData = variant['price'];
        if (priceData is String) {
          priceStr = '\$${double.parse(priceData).toStringAsFixed(2)}';
        } else if (priceData != null && priceData['amount'] != null) {
          final amount = priceData['amount'];
          priceStr = '\$${double.parse(amount.toString()).toStringAsFixed(2)}';
        }
      }
    } catch (e) {
      debugPrint('Price parse error for "$title": $e');
    }

    final String? productUrl = hat['onlineStoreUrl'];

    void openProduct({String? variantGid}) {
      if (productUrl == null || productUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product link is unavailable.')),
        );
        return;
      }
      final url = variantGid != null
          ? _productUrlForVariant(productUrl, variantGid)
          : productUrl;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShopWebViewScreen(
            url: url,
            title: title,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderGrey, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: openProduct,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero image
            Expanded(
              flex: 5,
              child: Container(
                color: _offWhite,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: imageUrl != null
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              alignment: const Alignment(0.0, -0.1),
                              cacheWidth: imageCacheWidth,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.image_outlined,
                                    color: _espresso.withValues(alpha: 0.15),
                                    size: 36),
                              ),
                            )
                          : Center(
                              child: Icon(Icons.image_outlined,
                                  color: _espresso.withValues(alpha: 0.15),
                                  size: 36),
                            ),
                    ),
                    if (swatchColors.isNotEmpty)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: swatchColors.map((entry) {
                            final swatchColor =
                                _mapColorNameToColor(entry.color);
                            return Tooltip(
                              message: entry.color,
                              preferBelow: false,
                              verticalOffset: 12,
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              textStyle: GoogleFonts.montserrat(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _white,
                              ),
                              decoration: BoxDecoration(
                                color: _espresso.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Semantics(
                                label: '${entry.color} color',
                                button: true,
                                child: GestureDetector(
                                  onTap: () =>
                                      openProduct(variantGid: entry.variantGid),
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 5),
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: swatchColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: swatchColor
                                                      .computeLuminance() >
                                                  0.8
                                              ? _espresso.withValues(alpha: 0.2)
                                              : Colors.white30,
                                          width: 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withValues(alpha: 0.12),
                                            blurRadius: 2,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Title + Price + CTA
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _espresso,
                        letterSpacing: 1.0,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Price
                    if (priceStr.isNotEmpty)
                      Text(
                        priceStr,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _turquoise,
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Compact attributes
                    if (!isBallcap) ...[
                      _buildAttribute('Crown', crownShape),
                      _buildAttribute('Brim', brimShape),
                    ] else ...[
                      _buildAttribute('Material', material),
                    ],
                    const Spacer(),
                    // CTA row
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final success = await DatabaseService.saveHat(
                              name: title,
                              price: priceStr,
                              url: productUrl,
                              brand: widget.westernStyle,
                            );
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? 'Saved to Bookmarks'
                                      : 'Failed to save bookmark.',
                                ),
                                backgroundColor:
                                    success ? _turquoise : Colors.red,
                              ),
                            );
                          },
                          child: Icon(Icons.bookmark_border_rounded,
                              color: _espresso.withValues(alpha: 0.4),
                              size: 20),
                        ),
                        const Spacer(),
                        Text(
                          'VIEW →',
                          style: GoogleFonts.montserrat(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _turquoise,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttribute(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: _espresso.withValues(alpha: 0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _espresso,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary() {
    return Container(
      color: _offWhite,
      constraints: const BoxConstraints(maxHeight: 340),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          children: [
            if (widget.headShapeProfile != null) ...[
              _buildFitProfileSummary(widget.headShapeProfile!),
              const SizedBox(height: 12),
            ],
            if (widget.headMeasurementProfile != null) ...[
              _buildMeasurementSummary(widget.headMeasurementProfile!),
              const SizedBox(height: 12),
            ],
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 20,
              runSpacing: 10,
              children: [
                _buildSummaryChip('Type', _filterHatType ?? widget.hatType ?? 'Any'),
                if (widget.westernStyle != null)
                  _buildSummaryChip('Style', widget.westernStyle!),
                if (_showsFineTuningTray) ...[
                  _buildSummaryChip('Crown', _crownSummaryLabel()),
                  _buildSummaryChip('Brim', _brimSummaryLabel()),
                ],
              ],
            ),
            if (_showsFineTuningTray) ...[
              const SizedBox(height: 14),
              FineTuningTray(
                expanded: _fineTuningExpanded,
                onExpandedChanged: (open) =>
                    setState(() => _fineTuningExpanded = open),
                hatType: _filterHatType,
                crownShape: _filterCrownShape,
                brimShape: _filterBrimShape,
                crownHeights: _filterCrownHeights,
                brimWidths: _filterBrimWidths,
                crownShapeOptions:
                    widget.crownShapeOptions ?? crownShapes,
                brimShapeOptions: widget.brimShapeOptions ?? brimShapes,
                onChanged: _onFineTuningChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFitProfileSummary(HeadShapeProfile profile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.face_retouching_natural_outlined,
          size: 18,
          color: _turquoise,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${profile.shortLabel}: ${profile.fitGuidance}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.35,
              color: _espresso.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementSummary(HeadMeasurementProfile measurement) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.straighten_outlined,
          size: 18,
          color: _turquoise,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Size starting point: ${measurement.shortLabel}. ${measurement.guidance}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.35,
              color: _espresso.withValues(alpha: 0.72),
            ),
          ),
        ),
      ],
    );
  }

  Color _mapColorNameToColor(String colorName) {
    final name = colorName.toLowerCase().trim();
    if (name.contains('black')) return const Color(0xFF1A1A1A);
    if (name.contains('chocolate') ||
        name.contains('brown') ||
        name.contains('dark brown')) {
      return const Color(0xFF4E3629);
    }
    if (name.contains('silver grey') ||
        name.contains('silver gray') ||
        name.contains('granite') ||
        name.contains('silver-grey') ||
        name.contains('silver-gray')) {
      return const Color(0xFFB0B3B5);
    }
    if (name.contains('grey') ||
        name.contains('gray') ||
        name.contains('sliver grey')) {
      return const Color(0xFF8E8E93);
    }
    if (name.contains('bone') ||
        name.contains('cream') ||
        name.contains('ivory') ||
        name.contains('white')) {
      return const Color(0xFFE5DDCB);
    }
    if (name.contains('stonewash') || name.contains('stone')) {
      return const Color(0xFF8FA1A6);
    }
    if (name.contains('burgundy') || name.contains('wine')) {
      return const Color(0xFF6B1D2F);
    }
    if (name.contains('cognac') || name.contains('chestnut')) {
      return const Color(0xFF8F4A24);
    }
    if (name.contains('sand') ||
        name.contains('natural') ||
        name.contains('tan') ||
        name.contains('fawn') ||
        name.contains('beige')) {
      return const Color(0xFFDFD5C6);
    }
    if (name.contains('pecan')) return const Color(0xFF8B5A2B);
    if (name.contains('caramel') ||
        name.contains('gold') ||
        name.contains('yellow')) {
      return const Color(0xFFC68E17);
    }
    if (name.contains('mist')) return const Color(0xFFE5E7E9);
    if (name.contains('sage') ||
        name.contains('olive') ||
        name.contains('green')) {
      return const Color(0xFF9CAF88);
    }
    if (name.contains('red')) return const Color(0xFFC0392B);
    if (name.contains('blue') || name.contains('navy')) {
      return const Color(0xFF1B4F72);
    }
    return Colors.grey.shade400;
  }

  Widget _buildSummaryChip(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.montserrat(
            fontSize: 10,
            color: _turquoise,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _espresso,
          ),
        ),
      ],
    );
  }
}
