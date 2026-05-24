import 'package:flutter/material.dart';
import 'shop_webview_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/shopify_service.dart';
import '../services/database_service.dart';
import '../models/hat.dart';
import '../models/head_measurement_profile.dart';
import '../models/head_shape_profile.dart';
import '../widgets/fine_tuning_tray.dart';
import '../widgets/shell_tab_bar_footer.dart';

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
  final bool hideFooter;

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
    this.hideFooter = false,
  });

  @override
  State<HatResultsScreen> createState() => _HatResultsScreenState();
}

class _HatResultsScreenState extends State<HatResultsScreen> {
  late Future<List<dynamic>> _hatsFuture;
  String? _selectedColor;
  String? _selectedVariantSize;
  Map<String, List<({String color, String variantGid, String? imageUrl})>>
      _swatchCache = {};
  List<dynamic>? _fullCatalog;
  bool _fineTuningExpanded = false;
  late String? _filterHatType;
  late String? _filterWesternStyle;
  late String? _filterCrownShape;
  late String? _filterBrimShape;
  late List<double> _filterCrownHeights;
  late List<String> _filterBrimWidths;

  static const _westernStyleOptions = ['Western', 'City', 'Outdoor'];

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
    _filterWesternStyle = widget.westernStyle;
    _filterCrownShape = widget.crownShape;
    _filterBrimShape = widget.brimShape;
    _filterCrownHeights = List<double>.from(widget.crownHeights ?? []);
    _filterBrimWidths = List<String>.from(widget.brimWidths ?? []);

    // Always load the full catalog — lite preloads lack color variants for swatches.
    _hatsFuture = _fetchFilteredHats();
  }

  bool get _showsWesternStyleFilter {
    final type = (_filterHatType ?? widget.hatType ?? '').toLowerCase();
    return type.contains('felt');
  }

  bool get _showsFineTuningTray {
    final type = (_filterHatType ?? widget.hatType ?? '').toLowerCase();
    return !type.contains('ballcap') &&
        !type.contains('beanie') &&
        !type.contains('flat cap');
  }

  Future<List<dynamic>> _fetchFilteredHats() async {
    final all = await ShopifyService.fetchFullProducts();
    if (!mounted) return [];
    _fullCatalog = all;
    final filtered = _filterCatalog(all);
    _rebuildSwatchCache(filtered);
    return filtered;
  }

  List<double> _crownHeightOptionsForFineTuning() {
    final baseline = defaultCrownHeightOptions();
    final catalog = _fullCatalog;
    if (catalog == null) return baseline;
    final fromCatalog = ShopifyService.uniqueCrownHeights(catalog);
    if (fromCatalog.isEmpty) return baseline;
    return {...baseline, ...fromCatalog}.toList()..sort();
  }

  List<dynamic> _filterCatalog(List<dynamic> catalog) {
    return ShopifyService.filterProducts(
      catalog,
      hatType: _filterHatType,
      westernStyle: _showsWesternStyleFilter ? _filterWesternStyle : null,
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
      _selectedVariantSize = null;
      _rebuildSwatchCache(filtered);
      _hatsFuture = Future.value(filtered);
    });
  }

  void _onFineTuningChanged(FineTuningValues values) {
    setState(() {
      _filterCrownHeights = List<double>.from(values.crownHeights);
      _filterBrimWidths = List<String>.from(values.brimWidths);
    });
    _applyFilters();
  }

  Future<void> _pickHatType() async {
    final picked = await showShapeFilterSheet(
      context,
      title: 'Hat type',
      current: _filterHatType,
      options: hatTypes,
    );
    if (!mounted || picked == _filterHatType) return;
    setState(() {
      _filterHatType = picked;
      if (!_showsWesternStyleFilter) _filterWesternStyle = null;
    });
    _applyFilters();
  }

  Future<void> _pickWesternStyle() async {
    final picked = await showStringFilterSheet(
      context,
      title: 'Hat Style',
      current: _filterWesternStyle,
      options: _westernStyleOptions,
    );
    if (!mounted || picked == _filterWesternStyle) return;
    setState(() => _filterWesternStyle = picked);
    _applyFilters();
  }

  Future<void> _pickCrownShape() async {
    final picked = await showShapeFilterSheet(
      context,
      title: 'Crown shape',
      current: _filterCrownShape,
      options: widget.crownShapeOptions ?? crownShapes,
    );
    if (!mounted || picked == _filterCrownShape) return;
    setState(() => _filterCrownShape = picked);
    _applyFilters();
  }

  Future<void> _pickBrimShape() async {
    final picked = await showShapeFilterSheet(
      context,
      title: 'Brim shape',
      current: _filterBrimShape,
      options: widget.brimShapeOptions ?? brimShapes,
    );
    if (!mounted || picked == _filterBrimShape) return;
    setState(() => _filterBrimShape = picked);
    _applyFilters();
  }

  String _crownSummaryLabel() {
    return _filterCrownShape ?? 'Any';
  }

  String _brimSummaryLabel() {
    return _filterBrimShape ?? 'Any';
  }

  String _metaValue(dynamic entry) {
    final value = ShopifyService.parseMetafieldValue(entry);
    return value.isEmpty ? '—' : value;
  }

  String _formatInchesDisplay(dynamic entry) {
    final raw = _metaValue(entry);
    if (raw == '—') return raw;
    if (raw.toLowerCase().contains('inch')) return raw;
    final parsed = double.tryParse(raw);
    if (parsed != null) return formatMeasurement(parsed);
    return raw;
  }

  String? _variantOptionValue(
    dynamic node, {
    required String optionName,
  }) {
    for (final opt in (node['selectedOptions'] as List<dynamic>? ?? [])) {
      if (opt['name'].toString().toLowerCase() == optionName.toLowerCase()) {
        final value = opt['value'].toString().trim();
        return value.isEmpty ? null : value;
      }
    }
    return null;
  }

  List<String> _availableSizesForHat(dynamic hat) {
    final sizes = <String>{};
    for (final edge in (hat['variants']?['edges'] as List<dynamic>? ?? [])) {
      final node = edge['node'];
      if (node == null || !_variantIsAvailable(node)) continue;
      final size = _variantOptionValue(node, optionName: 'size');
      if (size != null) sizes.add(size);
    }
    return sizes.toList();
  }

  bool _hatMatchesSelectedSize(dynamic hat, String selectedSize) {
    for (final edge in (hat['variants']?['edges'] as List<dynamic>? ?? [])) {
      final node = edge['node'];
      if (node == null || !_variantIsAvailable(node)) continue;
      final size = _variantOptionValue(node, optionName: 'size');
      if (size != null &&
          size.toLowerCase() == selectedSize.toLowerCase()) {
        return true;
      }
    }
    return false;
  }

  Widget _buildChipFilterBar<T>({
    required IconData icon,
    required String label,
    required List<T> options,
    required T? selected,
    required String Function(T) labelFor,
    required ValueChanged<T?> onSelected,
  }) {
    return Container(
      color: _white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _espresso.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Text(
            label,
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
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onSelected(null),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected == null ? _turquoise : _white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected == null ? _turquoise : _borderGrey,
                          ),
                        ),
                        child: Text(
                          'All',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: selected == null ? _white : _espresso,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ...options.map((option) {
                    final isSelected = selected == option;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () => onSelected(option),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected ? _turquoise : _white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? _turquoise : _borderGrey,
                            ),
                          ),
                          child: Text(
                            labelFor(option),
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? _white : _espresso,
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
    );
  }

  void _rebuildSwatchCache(List<dynamic> hats) {
    _swatchCache = {
      for (final hat in hats) (hat['id'] as String): _computeSwatchColors(hat),
    };
  }

  List<({String color, String variantGid, String? imageUrl})> _swatchColorsFor(
      dynamic hat) {
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
  List<({String color, String variantGid, String? imageUrl})>
      _computeSwatchColors(dynamic hat) {
    if (!_shouldShowColorSwatches(hat)) return [];

    final variants = hat['variants']?['edges'] as List<dynamic>? ?? [];
    final availableByColor = <String, bool>{};
    final variantByColor = <String, String>{};
    final imageByColor = <String, String?>{};

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
        final imageUrl = node['image']?['url'] as String?;
        if (imageUrl != null &&
            imageUrl.isNotEmpty &&
            (imageByColor[colorName] == null ||
                imageByColor[colorName]!.isEmpty)) {
          imageByColor[colorName] = imageUrl;
        } else {
          imageByColor.putIfAbsent(colorName, () => null);
        }
      }
    }

    for (final colorName in availableByColor.keys) {
      if (imageByColor[colorName] != null &&
          imageByColor[colorName]!.isNotEmpty) {
        continue;
      }
      final matched = _findProductImageForColor(hat, colorName);
      if (matched != null) {
        imageByColor[colorName] = matched;
      }
    }

    var colors = availableByColor.keys
        .map(
          (c) => (
            color: c,
            variantGid: variantByColor[c]!,
            imageUrl: imageByColor[c],
          ),
        )
        .toList()
      ..sort((a, b) => a.color.compareTo(b.color));

    if (colors.isNotEmpty) return colors;

    // Metafield color when there is no Color option (uncommon on felt).
    final colorMeta = _metaValue(hat['color']);
    if (colorMeta != '—' && colorMeta.isNotEmpty) {
      for (final edge in variants) {
        final node = edge['node'];
        if (node != null && _variantIsAvailable(node) && node['id'] != null) {
          final imageUrl = (node['image']?['url'] as String?) ??
              _findProductImageForColor(hat, colorMeta);
          return [
            (
              color: colorMeta,
              variantGid: node['id'] as String,
              imageUrl: imageUrl,
            ),
          ];
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
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

                // Extract unique in-stock sizes from returned products
                final Set<String> availableSizes = {};
                for (final hat in hats) {
                  availableSizes.addAll(_availableSizesForHat(hat));
                }
                final sortedSizes = availableSizes.toList()..sort();

                // Extract unique in-stock colors from returned products
                final Set<String> availableColors = {};
                for (final hat in hats) {
                  for (final entry in _swatchColorsFor(hat)) {
                    availableColors.add(entry.color);
                  }
                }
                final sortedColors = availableColors.toList()..sort();

                // Filter by selected size, then color
                final sizeFilteredHats = _selectedVariantSize == null
                    ? hats
                    : hats
                        .where((hat) =>
                            _hatMatchesSelectedSize(hat, _selectedVariantSize!))
                        .toList();

                final filteredHats = _selectedColor == null
                    ? sizeFilteredHats
                    : sizeFilteredHats.where((hat) {
                        return _swatchColorsFor(hat).any(
                          (entry) =>
                              entry.color.toLowerCase() ==
                              _selectedColor!.toLowerCase(),
                        );
                      }).toList();

                return Column(
                  children: [
                    if (sortedSizes.isNotEmpty)
                      _buildChipFilterBar<String>(
                        icon: Icons.straighten_outlined,
                        label: 'SIZE',
                        options: sortedSizes,
                        selected: _selectedVariantSize,
                        labelFor: (size) => size,
                        onSelected: (size) =>
                            setState(() => _selectedVariantSize = size),
                      ),
                    if (sortedSizes.isNotEmpty)
                      const Divider(height: 1, color: _borderGrey),
                    if (sortedColors.isNotEmpty)
                      _buildChipFilterBar<String>(
                        icon: Icons.palette_outlined,
                        label: 'COLOR',
                        options: sortedColors,
                        selected: _selectedColor,
                        labelFor: (color) => color,
                        onSelected: (color) =>
                            setState(() => _selectedColor = color),
                      ),
                    if (sortedColors.isNotEmpty)
                      const Divider(height: 1, color: _borderGrey),
                    // Grid
                    Expanded(
                      child: filteredHats.isEmpty
                          ? Center(
                              child: Text(
                                _selectedVariantSize != null
                                    ? 'No hats in this size.'
                                    : sortedColors.isNotEmpty &&
                                            _selectedColor != null
                                        ? 'No hats in this color.'
                                        : 'No hats match these filters.',
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
                                childAspectRatio: 0.38,
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
      bottomNavigationBar: widget.hideFooter ? null : const ShellTabBarFooter(selectedIndex: 1),
    );
  }

  Widget _buildHatCard(dynamic hat) {
    final title = hat['title'] ?? 'Unknown Hat';

    // Metafield values
    final crownShape = _metaValue(hat['crownShape']);
    final crownHeight = _formatInchesDisplay(hat['crownHeight']);
    final material = _metaValue(hat['material']);
    final brimShape = _metaValue(hat['brimShape']);
    final brimWidth = _formatInchesDisplay(hat['brimWidth']);
    final hatTypeLower = (widget.hatType ?? '').toLowerCase();
    final isBallcap = hatTypeLower.contains('ballcap') ||
        hatTypeLower.contains('beanie') ||
        hatTypeLower.contains('flat cap');

    final swatchColors = _swatchColorsFor(hat);
    final cardSwatches =
        swatchColors.length > 1 ? swatchColors : <({String color, String variantGid, String? imageUrl})>[];
    final imageUrl = _heroImageForHat(hat, swatchColors);
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
                    if (cardSwatches.isNotEmpty)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: cardSwatches.map((entry) {
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
                                    child: _buildColorSwatchCircle(
                                      colorName: entry.color,
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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                      _buildAttribute('Crown Height', crownHeight),
                      _buildAttribute('Brim', brimShape),
                      _buildAttribute('Brim Width', brimWidth),
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
                              brand: _filterWesternStyle,
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
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
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
                fontSize: 12,
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
      constraints: const BoxConstraints(maxHeight: 300),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: Column(
          children: [
            if (widget.headShapeProfile != null) ...[
              _buildFitProfileSummary(widget.headShapeProfile!),
              const SizedBox(height: 8),
            ],
            if (widget.headMeasurementProfile != null) ...[
              _buildMeasurementSummary(widget.headMeasurementProfile!),
              const SizedBox(height: 8),
            ],
            _buildSummaryDropdowns(),
            if (_showsFineTuningTray) ...[
              const SizedBox(height: 6),
              FineTuningTray(
                expanded: _fineTuningExpanded,
                onExpandedChanged: (open) =>
                    setState(() => _fineTuningExpanded = open),
                crownHeights: _filterCrownHeights,
                brimWidths: _filterBrimWidths,
                crownHeightOptions: _crownHeightOptionsForFineTuning(),
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

  bool _urlMatchesColorName(String url, String colorName) {
    final normalized = colorName.toLowerCase().trim();
    final slug = normalized.replaceAll(RegExp(r'[\s-]+'), '_');
    final compact = normalized.replaceAll(RegExp(r'[\s_-]+'), '');
    final haystack = url.toLowerCase();
    final words =
        normalized.split(RegExp(r'[\s_-]+')).where((w) => w.isNotEmpty);

    if (haystack.contains(slug) || haystack.contains(compact)) {
      return true;
    }
    return words.isNotEmpty && words.every((w) => haystack.contains(w));
  }

  String? _findProductImageForColor(dynamic hat, String colorName) {
    final images = hat['images']?['edges'] as List<dynamic>? ?? [];
    final normalized = colorName.toLowerCase().trim();
    final slug = normalized.replaceAll(RegExp(r'[\s-]+'), '_');
    final compact = normalized.replaceAll(RegExp(r'[\s_-]+'), '');
    final words =
        normalized.split(RegExp(r'[\s_-]+')).where((w) => w.isNotEmpty);

    String? bestMatch;
    var bestScore = 0;

    for (final edge in images) {
      final node = edge['node'];
      if (node == null) continue;
      final url = (node['url'] as String? ?? '').toLowerCase();
      final alt = (node['altText'] as String? ?? '').toLowerCase();
      if (url.isEmpty) continue;
      final haystack = '$url $alt';

      if (haystack.contains(slug) || haystack.contains(compact)) {
        return node['url'] as String;
      }

      final matchedWords = words.where((w) => haystack.contains(w)).length;
      if (matchedWords > bestScore && matchedWords == words.length) {
        bestScore = matchedWords;
        bestMatch = node['url'] as String;
      }
    }

    final featured = hat['featuredImage']?['url'] as String?;
    if (featured != null &&
        featured.isNotEmpty &&
        _urlMatchesColorName(featured, colorName)) {
      return featured;
    }

    return bestMatch;
  }

  String? _heroImageForHat(
    dynamic hat,
    List<({String color, String variantGid, String? imageUrl})> swatchColors,
  ) {
    if (_selectedColor != null) {
      for (final entry in swatchColors) {
        if (entry.color.toLowerCase() == _selectedColor!.toLowerCase()) {
          if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
            return entry.imageUrl;
          }
        }
      }
    }

    final featured = hat['featuredImage']?['url'] as String?;
    for (final entry in swatchColors) {
      if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
        return entry.imageUrl;
      }
    }
    return featured;
  }

  Widget _buildColorSwatchCircle({
    required String colorName,
  }) {
    final swatchColor = _mapColorNameToColor(colorName);
    final borderColor = swatchColor.computeLuminance() > 0.8
        ? _espresso.withValues(alpha: 0.2)
        : Colors.white30;

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: swatchColor,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }

  Color _mapColorNameToColor(String colorName) {
    final name = colorName.toLowerCase().trim();
    if (name.contains('black')) return const Color(0xFF1A1A1A);
    if (name.contains('mushroom')) return const Color(0xFFC4B5A5);
    if (name.contains('steel')) return const Color(0xFF8A939C);
    if (name.contains('light brown')) return const Color(0xFFB8956A);
    if (name.contains('silverbelly')) return const Color(0xFFD4CFC4);
    if (name.contains('sahara')) return const Color(0xFFC4A574);
    if (name.contains('granite')) return const Color(0xFF9A9A96);
    if (name.contains('chocolate') || name.contains('dark brown')) {
      return const Color(0xFF4E3629);
    }
    if (name.contains('brown')) return const Color(0xFF6B4423);
    if (name.contains('silver grey') ||
        name.contains('silver gray') ||
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

  Widget _buildSummaryDropdowns() {
    return Column(
      children: [
        Row(
          children: [
            _buildSummaryDropdown(
              label: 'Type',
              value: _filterHatType ?? 'Any',
              onTap: _pickHatType,
            ),
            if (_showsWesternStyleFilter)
              _buildSummaryDropdown(
                label: 'Style',
                value: _filterWesternStyle ?? 'Any',
                onTap: _pickWesternStyle,
              ),
          ],
        ),
        if (_showsFineTuningTray) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              _buildSummaryDropdown(
                label: 'Crown',
                value: _crownSummaryLabel(),
                onTap: _pickCrownShape,
              ),
              _buildSummaryDropdown(
                label: 'Brim',
                value: _brimSummaryLabel(),
                onTap: _pickBrimShape,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryDropdown({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: _buildSummaryDropdownField(
          label: label,
          value: value,
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildSummaryDropdownField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.montserrat(
                fontSize: 9,
                color: _turquoise,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _borderGrey),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _espresso,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: _espresso.withValues(alpha: 0.45),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
