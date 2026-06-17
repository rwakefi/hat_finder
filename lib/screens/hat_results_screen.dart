import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_breakpoints.dart';
import '../services/shopify_service.dart';
import '../models/hat.dart';
import '../models/head_measurement_profile.dart';
import '../models/head_shape_profile.dart';
import '../theme/moon_ridge_logo_sizes.dart';
import '../theme/wizard_header_spacing.dart';
import '../utils/storefront_links.dart';
import '../widgets/fine_tuning_tray.dart';
import '../widgets/shell_tab_bar_footer.dart';
import '../widgets/web_content_scope.dart';

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
  final bool showingClosestMatches;
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
    this.showingClosestMatches = false,
    this.crownShapeOptions,
    this.brimShapeOptions,
    this.hideFooter = false,
  });

  @override
  State<HatResultsScreen> createState() => _HatResultsScreenState();
}

class _HatResultsScreenState extends State<HatResultsScreen> {
  String? _selectedColor;
  String? _selectedVariantSize;
  Map<String, List<({String color, String variantGid, String? imageUrl})>>
      _swatchCache = {};
  List<dynamic>? _fullCatalog;
  List<dynamic> _resultHats = [];
  List<String> _resultSizes = [];
  List<String> _resultColors = [];
  List<double>? _cachedCrownHeightOptions;
  bool _resultsLoading = true;
  Object? _resultsError;
  bool _fineTuningExpanded = false;
  bool _summaryFiltersExpanded = true;
  late String? _filterHatType;
  late String? _filterWesternStyle;
  late String? _filterCrownShape;
  late String? _filterBrimShape;
  late List<double> _filterCrownHeights;
  late List<String> _filterBrimWidths;

  static const _westernStyleOptions = ['Western', 'City', 'Outdoor'];
  bool _showingClosestMatches = false;

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
    _showingClosestMatches = widget.showingClosestMatches;

    _loadInitialResults();
  }

  Future<void> _loadInitialResults() async {
    try {
      var catalog = ShopifyService.peekFullProducts();
      if (widget.preloadedHats != null) {
        catalog ??= await ShopifyService.fetchFullProducts();
        if (!mounted) return;
        setState(() {
          _fullCatalog = catalog;
          _syncResultHats(widget.preloadedHats!);
          _cachedCrownHeightOptions = _computeCrownHeightOptions();
          _resultsLoading = false;
        });
        return;
      }

      catalog ??= await ShopifyService.fetchFullProducts();
      if (!mounted) return;
      setState(() {
        _fullCatalog = catalog;
        _syncResultHats(_filterCatalog(catalog!));
        _cachedCrownHeightOptions = _computeCrownHeightOptions();
        _resultsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultsError = e;
        _resultsLoading = false;
      });
    }
  }

  void _syncResultHats(List<dynamic> hats) {
    _resultHats = hats;
    _rebuildSwatchCache(hats);
    final sizes = <String>{};
    final colors = <String>{};
    for (final hat in hats) {
      sizes.addAll(_availableSizesForHat(hat));
      for (final entry in _swatchColorsFor(hat)) {
        colors.add(entry.color);
      }
    }
    _resultSizes = sizes.toList()..sort(ShopifyService.compareHatSizes);
    _resultColors = colors.toList()..sort();
  }

  List<dynamic> get _displayHats {
    var hats = _resultHats;
    if (_selectedVariantSize != null) {
      hats = hats
          .where((hat) => _hatMatchesSelectedSize(hat, _selectedVariantSize!))
          .toList();
    }
    if (_selectedColor != null) {
      hats = hats
          .where(
            (hat) => _swatchColorsFor(hat).any(
              (entry) =>
                  entry.color.toLowerCase() == _selectedColor!.toLowerCase(),
            ),
          )
          .toList();
    }
    return hats;
  }

  List<double> _computeCrownHeightOptions() {
    final baseline = defaultCrownHeightOptions();
    final catalog = _fullCatalog;
    if (catalog == null) return baseline;
    final fromCatalog = ShopifyService.uniqueCrownHeights(catalog);
    if (fromCatalog.isEmpty) return baseline;
    return {...baseline, ...fromCatalog}.toList()..sort();
  }

  List<double> _crownHeightOptionsForFineTuning() {
    return _cachedCrownHeightOptions ?? _computeCrownHeightOptions();
  }

  bool get _showsWesternStyleFilter {
    final type = (_filterHatType ?? widget.hatType ?? '').toLowerCase();
    if (type.contains('ballcap') ||
        type.contains('beanie') ||
        type.contains('flat cap')) {
      return false;
    }
    return true;
  }

  bool get _showsFineTuningTray {
    final type = (_filterHatType ?? widget.hatType ?? '').toLowerCase();
    return !type.contains('ballcap') &&
        !type.contains('beanie') &&
        !type.contains('flat cap');
  }

  /// Shorter cards than before — trims empty space below the CTA without changing width.
  double _resultsCardAspectRatio(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) return 0.68;
    final height = MediaQuery.sizeOf(context).height;
    if (height < 700) return 0.49;
    if (height < 820) return 0.51;
    return 0.52;
  }

  int _resultsCrossAxisCount(BuildContext context) =>
      AppBreakpoints.gridCrossAxisCount(context, laptop: 3, desktop: 4);

  List<dynamic> _filterCatalog(List<dynamic> catalog) {
    final filterArgs = (
      hatType: _filterHatType,
      westernStyle: _showsWesternStyleFilter ? _filterWesternStyle : null,
      crownShape: _filterCrownShape,
      crownHeights: _filterCrownHeights.isEmpty ? null : _filterCrownHeights,
      brimShape: _filterBrimShape,
      brimWidths: _filterBrimWidths.isEmpty ? null : _filterBrimWidths,
    );

    var filtered = ShopifyService.filterProducts(
      catalog,
      hatType: filterArgs.hatType,
      westernStyle: filterArgs.westernStyle,
      crownShape: filterArgs.crownShape,
      crownHeights: filterArgs.crownHeights,
      brimShape: filterArgs.brimShape,
      brimWidths: filterArgs.brimWidths,
    );

    if (filtered.isEmpty) {
      _showingClosestMatches = true;
      filtered = ShopifyService.closestMatchProducts(
        catalog,
        hatType: filterArgs.hatType,
        westernStyle: filterArgs.westernStyle,
        crownShape: filterArgs.crownShape,
        crownHeights: filterArgs.crownHeights,
        brimShape: filterArgs.brimShape,
        brimWidths: filterArgs.brimWidths,
      );
    } else {
      _showingClosestMatches = false;
    }

    return ShopifyService.orderResultsCatalog(filtered);
  }

  void _applyFilters() {
    final source = _fullCatalog;
    if (source == null) return;
    setState(() {
      _selectedColor = null;
      _selectedVariantSize = null;
      _syncResultHats(_filterCatalog(source));
    });
  }

  bool get _hasActiveFilters =>
      _filterHatType != null ||
      _filterWesternStyle != null ||
      _filterCrownShape != null ||
      _filterBrimShape != null ||
      _filterCrownHeights.isNotEmpty ||
      _filterBrimWidths.isNotEmpty ||
      _selectedColor != null ||
      _selectedVariantSize != null;

  void _clearAllFilters() {
    if (!_hasActiveFilters) return;
    setState(() {
      _filterHatType = null;
      _filterWesternStyle = null;
      _filterCrownShape = null;
      _filterBrimShape = null;
      _filterCrownHeights = [];
      _filterBrimWidths = [];
      _selectedColor = null;
      _selectedVariantSize = null;
      _fineTuningExpanded = false;
    });
    _applyFilters();
  }

  void _onFineTuningChanged(FineTuningValues values) {
    _filterCrownHeights = List<double>.from(values.crownHeights);
    _filterBrimWidths = List<String>.from(values.brimWidths);
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
    _filterHatType = picked;
    if (!_showsWesternStyleFilter) _filterWesternStyle = null;
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
    _filterWesternStyle = picked;
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
    _filterCrownShape = picked;
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
    _filterBrimShape = picked;
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
      if (size != null && ShopifyService.isHatHeadSize(size)) {
        sizes.add(size);
      }
    }
    return sizes.toList();
  }

  bool _hatMatchesSelectedSize(dynamic hat, String selectedSize) {
    for (final edge in (hat['variants']?['edges'] as List<dynamic>? ?? [])) {
      final node = edge['node'];
      if (node == null || !_variantIsAvailable(node)) continue;
      final size = _variantOptionValue(node, optionName: 'size');
      if (size != null && size.toLowerCase() == selectedSize.toLowerCase()) {
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
    bool compact = false,
  }) {
    final chipHeight = compact ? 26.0 : 32.0;
    final chipPaddingH = compact ? 10.0 : 14.0;
    final chipPaddingV = compact ? 4.0 : 6.0;
    final chipFontSize = compact ? 10.0 : 11.0;
    final labelFontSize = compact ? 8.0 : 9.0;
    final iconSize = compact ? 14.0 : 16.0;

    return Container(
      color: _white,
      padding: EdgeInsets.fromLTRB(12, compact ? 4 : 8, 12, compact ? 4 : 8),
      child: Row(
        children: [
          Icon(icon, size: iconSize, color: _espresso.withValues(alpha: 0.4)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.montserrat(
              fontSize: labelFontSize,
              fontWeight: FontWeight.w700,
              color: _turquoise,
              letterSpacing: compact ? 1.4 : 2.0,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: chipHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => onSelected(null),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: chipPaddingH,
                          vertical: chipPaddingV,
                        ),
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
                            fontSize: chipFontSize,
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
                          padding: EdgeInsets.symmetric(
                            horizontal: chipPaddingH,
                            vertical: chipPaddingV,
                          ),
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
                              fontSize: chipFontSize,
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

  String _productUrlForVariant(String baseUrl, String variantGid) =>
      StorefrontLinks.withVariant(baseUrl, variantGid);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _offWhite,
      appBar: AppBar(
        backgroundColor: _offWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: MoonRidgeLogoSizes.resultsToolbar,
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
              height: MoonRidgeLogoSizes.results,
            ),
            const SizedBox(height: WizardHeaderSpacing.gap),
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
      body: ShellNavigationHost(
        selectedIndex: 1,
        showNavigation: !widget.hideFooter,
        child: WebContentScope(
          child: Column(
            children: [
              // Turquoise progress accent line
              Container(height: 3, color: _turquoise),
              const SizedBox(height: WizardHeaderSpacing.gap),
              _buildSearchSummary(),
              if (_showingClosestMatches) _buildClosestMatchesBanner(),
              const Divider(height: 1, color: _borderGrey),
              Expanded(
                child: _buildResultsBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsBody() {
    if (_resultsLoading) {
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
    }
    if (_resultsError != null) {
      return Center(
        child: Text(
          'Error: $_resultsError',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_resultHats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded,
                  size: 56, color: _espresso.withValues(alpha: 0.2)),
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

    final displayHats = _displayHats;
    final compactChips = !AppBreakpoints.isDesktop(context);
    return Column(
      children: [
        if (_resultSizes.isNotEmpty)
          _buildChipFilterBar<String>(
            icon: Icons.straighten_outlined,
            label: 'SIZE',
            options: _resultSizes,
            selected: _selectedVariantSize,
            labelFor: (size) => size,
            onSelected: (size) => setState(() => _selectedVariantSize = size),
            compact: compactChips,
          ),
        if (_resultSizes.isNotEmpty && !compactChips)
          const Divider(height: 1, color: _borderGrey),
        if (_resultColors.isNotEmpty)
          _buildChipFilterBar<String>(
            icon: Icons.palette_outlined,
            label: 'COLOR',
            options: _resultColors,
            selected: _selectedColor,
            labelFor: (color) => color,
            onSelected: (color) => setState(() => _selectedColor = color),
            compact: compactChips,
          ),
        if (_resultColors.isNotEmpty)
          const Divider(height: 1, color: _borderGrey),
        Expanded(
          child: displayHats.isEmpty
              ? Center(
                  child: Text(
                    _selectedVariantSize != null
                        ? 'No hats in this size.'
                        : _resultColors.isNotEmpty && _selectedColor != null
                            ? 'No hats in this color.'
                            : 'No hats match these filters.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: _espresso.withValues(alpha: 0.4),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _resultsCrossAxisCount(context),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: _resultsCardAspectRatio(context),
                  ),
                  itemCount: displayHats.length,
                  itemBuilder: (context, index) {
                    return RepaintBoundary(
                      child: _buildHatCard(displayHats[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHatCard(dynamic hat) {
    final title = hat['title'] ?? 'Unknown Hat';

    // Metafield values
    final crownShape = _metaValue(hat['crownShape']);
    final crownHeight = _formatInchesDisplay(hat['crownHeight']);
    final material = _metaValue(hat['feltStrawOrBallcap']);
    final brimShape = _metaValue(hat['brimShape']);
    final brimWidth = _formatInchesDisplay(hat['brimWidth']);
    final hatTypeLower = (widget.hatType ?? _filterHatType ?? '').toLowerCase();
    final prodType = _metaValue(hat['feltStrawOrBallcap']).toLowerCase();
    final isBallcap = hatTypeLower.contains('ballcap') ||
        hatTypeLower.contains('beanie') ||
        hatTypeLower.contains('flat cap') ||
        prodType.contains('ballcap') ||
        prodType.contains('beanie') ||
        prodType.contains('flat cap');

    final swatchColors = _swatchColorsFor(hat);
    final cardSwatches = swatchColors.length > 1
        ? swatchColors
        : <({String color, String variantGid, String? imageUrl})>[];
    final imageUrl = _heroImageForHat(hat, swatchColors);
    final cardImageUrls = _cardImageUrls(hat, imageUrl, swatchColors);
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

    final String? productUrl = StorefrontLinks.productUrlFor(hat);

    Future<void> openProduct({String? variantGid}) async {
      if (productUrl == null || productUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product link is unavailable.')),
        );
        return;
      }
      final url = variantGid != null
          ? _productUrlForVariant(productUrl, variantGid)
          : productUrl;
      await StorefrontLinks.openProductPage(
        context,
        url: url,
        title: title,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _turquoise, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: openProduct,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero image
              Expanded(
                flex: 3,
                child: Container(
                  color: _white,
                  child: Stack(
                    clipBehavior: Clip.antiAlias,
                    children: [
                      Positioned.fill(
                        child: _CardImageGallery(
                          imageUrls: cardImageUrls,
                          cacheWidth: imageCacheWidth,
                        ),
                      ),
                      if (cardSwatches.isNotEmpty)
                        Positioned(
                          top: 6,
                          right: 10,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: cardSwatches.map((entry) {
                              return Tooltip(
                                message: entry.color,
                                preferBelow: false,
                                verticalOffset: 12,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8),
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
                                    onTap: () => openProduct(
                                        variantGid: entry.variantGid),
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
              // Title + Price + pinned footer
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
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
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                      child: Center(
                        child: FilledButton(
                          onPressed: openProduct,
                          style: FilledButton.styleFrom(
                            backgroundColor: _turquoise,
                            foregroundColor: _white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            minimumSize: const Size(0, 28),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'MORE INFO / BUY',
                            style: GoogleFonts.montserrat(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ), // ClipRRect
    );
  }

  Widget _buildAttribute(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.5),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
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
                fontSize: 11,
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
    final isLaptop = AppBreakpoints.isLaptop(context);

    return Container(
      color: _offWhite,
      constraints: BoxConstraints(maxHeight: isLaptop ? 140 : 260),
      child: SingleChildScrollView(
        padding:
            EdgeInsets.fromLTRB(16, isLaptop ? 6 : 8, 16, isLaptop ? 4 : 6),
        child: Column(
          children: [
            if (widget.headShapeProfile != null) ...[
              _buildFitProfileSummary(widget.headShapeProfile!),
              SizedBox(height: isLaptop ? 4 : 8),
            ],
            if (widget.headMeasurementProfile != null) ...[
              _buildMeasurementSummary(widget.headMeasurementProfile!),
              SizedBox(height: isLaptop ? 4 : 8),
            ],
            _buildCollapsibleSummaryFilters(),
            if (_showsFineTuningTray && !isLaptop) ...[
              const SizedBox(height: 4),
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

  Widget _buildClosestMatchesBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _turquoise.withValues(alpha: 0.12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tune_rounded, size: 18, color: _turquoise),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No exact matches — showing the closest options we found. '
              'Adjust filters above to narrow further.',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _espresso.withValues(alpha: 0.82),
                height: 1.45,
              ),
            ),
          ),
        ],
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

    final featured = hat['featuredImage']?['url'] as String? ??
        hat['image']?['url'] as String?;
    if (featured != null &&
        featured.isNotEmpty &&
        _urlMatchesColorName(featured, colorName)) {
      return featured;
    }

    return bestMatch;
  }

  static bool _isRedColorName(String colorName) {
    final c = colorName.toLowerCase().trim();
    return c == 'red' ||
        c.startsWith('red ') ||
        c.endsWith(' red') ||
        c.contains(' red ');
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

    // Prefer a non-red variant image first
    for (final entry in swatchColors) {
      if (!_isRedColorName(entry.color) &&
          entry.imageUrl != null &&
          entry.imageUrl!.isNotEmpty) {
        return entry.imageUrl;
      }
    }

    // Fall back to any swatch image (including red) if no other option
    final featured = hat['featuredImage']?['url'] as String? ??
        hat['image']?['url'] as String?;
    for (final entry in swatchColors) {
      if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
        return entry.imageUrl;
      }
    }
    return featured;
  }

  List<String> _cardImageUrls(
    dynamic hat,
    String? heroUrl,
    List<({String color, String variantGid, String? imageUrl})> swatchColors,
  ) {
    final urls = <String>[];
    final seen = <String>{};

    void add(String? url) {
      if (url == null || url.isEmpty || seen.contains(url)) return;
      seen.add(url);
      urls.add(url);
    }

    add(heroUrl);
    for (final edge in hat['images']?['edges'] as List<dynamic>? ?? []) {
      add(edge['node']?['url'] as String?);
    }
    for (final entry in swatchColors) {
      add(entry.imageUrl);
    }
    return urls;
  }

  Widget _buildColorSwatchCircle({
    required String colorName,
  }) {
    final swatchColor = _mapColorNameToColor(colorName);

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: swatchColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: _espresso.withValues(alpha: 0.22),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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

  Widget _buildCollapsibleSummaryFilters() {
    final isLaptop = AppBreakpoints.isLaptop(context);
    if (isLaptop) {
      return _buildLaptopFilterToolbar();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _summaryFiltersExpanded
                  ? _turquoise.withValues(alpha: 0.1)
                  : _offWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _summaryFiltersExpanded ? _turquoise : _borderGrey,
                width: _summaryFiltersExpanded ? 1.5 : 1,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => setState(
                        () =>
                            _summaryFiltersExpanded = !_summaryFiltersExpanded,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        size: 15,
                        color: _summaryFiltersExpanded
                            ? _turquoise
                            : _espresso.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'FILTERS',
                        style: GoogleFonts.montserrat(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                          color:
                              _summaryFiltersExpanded ? _turquoise : _espresso,
                        ),
                      ),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _summaryFiltersExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 18,
                          color: _summaryFiltersExpanded
                              ? _turquoise
                              : _espresso.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasActiveFilters)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 1,
                          height: 18,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: _borderGrey,
                        ),
                        GestureDetector(
                          onTap: _clearAllFilters,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            child: Text(
                              'CLEAR',
                              style: GoogleFonts.montserrat(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: _turquoise,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: _buildSummaryDropdowns(),
          ),
          crossFadeState: _summaryFiltersExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
          sizeCurve: Curves.easeInOut,
        ),
      ],
    );
  }

  Widget _buildLaptopFilterToolbar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSummaryDropdowns()),
        if (_hasActiveFilters) ...[
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: GestureDetector(
              onTap: _clearAllFilters,
              behavior: HitTestBehavior.opaque,
              child: Text(
                'CLEAR',
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: _turquoise,
                ),
              ),
            ),
          ),
        ],
        if (_showsFineTuningTray) ...[
          const SizedBox(width: 6),
          FineTuningTray(
            compact: true,
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
    );
  }

  Widget _buildSummaryDropdowns() {
    final isLaptop = AppBreakpoints.isLaptop(context);

    if (isLaptop) {
      return Row(
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
          if (_showsFineTuningTray) ...[
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
        ],
      );
    }

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
          const SizedBox(height: 4),
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
    final isLaptop = AppBreakpoints.isLaptop(context);

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
                fontSize: 8,
                color: _turquoise,
                fontWeight: FontWeight.w700,
                letterSpacing: isLaptop ? 1.2 : 1.4,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isLaptop ? 6 : 7,
                vertical: 4,
              ),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _espresso,
                        height: 1.0,
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

class _CardImageGallery extends StatefulWidget {
  const _CardImageGallery({
    required this.imageUrls,
    required this.cacheWidth,
  });

  final List<String> imageUrls;
  final int cacheWidth;

  @override
  State<_CardImageGallery> createState() => _CardImageGalleryState();
}

class _CardImageGalleryState extends State<_CardImageGallery> {
  static const _espresso = Color(0xFF2D2926);
  static const _turquoise = Color(0xFF559C99);

  late final PageController _pageController = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) {
      return Center(
        child: Icon(
          Icons.image_outlined,
          color: _espresso.withValues(alpha: 0.15),
          size: 36,
        ),
      );
    }

    if (widget.imageUrls.length == 1) {
      return _buildImage(widget.imageUrls.first);
    }

    final showNavArrows = AppBreakpoints.isLaptop(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) => setState(() => _pageIndex = index),
          itemBuilder: (context, index) => _buildImage(widget.imageUrls[index]),
        ),
        if (showNavArrows && _pageIndex > 0)
          Positioned(
            left: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildGalleryNavButton(
                icon: Icons.chevron_left_rounded,
                onTap: () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                ),
              ),
            ),
          ),
        if (showNavArrows && _pageIndex < widget.imageUrls.length - 1)
          Positioned(
            right: 4,
            top: 0,
            bottom: 0,
            child: Center(
              child: _buildGalleryNavButton(
                icon: Icons.chevron_right_rounded,
                onTap: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                ),
              ),
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.imageUrls.length, (index) {
              final active = index == _pageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: active ? 6 : 5,
                height: active ? 6 : 5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      active ? _turquoise : _espresso.withValues(alpha: 0.22),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.82),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: _espresso.withValues(alpha: 0.65)),
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.contain,
      alignment: const Alignment(0.0, -0.2),
      cacheWidth: widget.cacheWidth,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Center(
        child: Icon(
          Icons.image_outlined,
          color: _espresso.withValues(alpha: 0.15),
          size: 36,
        ),
      ),
    );
  }
}
