import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_breakpoints.dart';
import '../theme/moon_ridge_logo_sizes.dart';
import '../theme/section_title_style.dart';
import '../theme/wizard_header_spacing.dart';
import '../models/hat.dart';
import '../models/head_measurement_profile.dart';
import '../models/head_shape_profile.dart';
import 'hat_results_screen.dart';
import 'shape_guide_screen.dart';
import 'dart:async';
import 'dart:math' show pi, min;
import '../services/shopify_service.dart';
import '../widgets/shell_tab_bar_footer.dart';

class HatInputScreen extends StatefulWidget {
  const HatInputScreen({
    super.key,
    this.headShapeProfile,
    this.headMeasurementProfile,
    this.onExit,
  });

  final HeadShapeProfile? headShapeProfile;
  final HeadMeasurementProfile? headMeasurementProfile;
  /// Called when BACK is tapped on the first wizard step and there is no route
  /// to pop (e.g. Hat Finder tab inside [AppShell]).
  final VoidCallback? onExit;

  @override
  State<HatInputScreen> createState() => _HatInputScreenState();
}

class _ShapeCardPhoto {
  const _ShapeCardPhoto({this.imageUrl, this.productTitle});

  final String? imageUrl;
  final String? productTitle;
}

class _HatInputScreenState extends State<HatInputScreen> {
  final PageController _pageController = PageController();
  final PageController _styleCarouselController =
      PageController(viewportFraction: 0.76);
  final PageController _crownCarouselController =
      PageController(viewportFraction: 0.76);
  final PageController _brimCarouselController =
      PageController(viewportFraction: 0.76);
  int _currentPageIndex = 0;
  int _currentStyleCarouselIndex = 0;
  int _currentCrownCarouselIndex = 0;
  int _currentBrimCarouselIndex = 0;
  int? _flippedCardIndex; // which crown card is showing history
  int? _flippedBrimCardIndex; // which brim card is showing history
  List<HatShapeInfo>? _sortedCrownShapes;
  List<HatShapeInfo>? _sortedBrimShapes;
  bool _hasAppliedProfileDefaults = false;
  List<HatShapeInfo> _rawCrownShapes = [];
  List<HatShapeInfo> _rawBrimShapes = [];
  List<HatShapeInfo> _materialTypes = [];
  Map<String, String> _materialExampleUrls = {};

  HatShapeInfo? selectedHatType;
  String? selectedWesternStyle;

  HatShapeInfo? selectedCrownShape;

  HatShapeInfo? selectedBrimShape;

  late Future<List<dynamic>> _allProductsFuture;
  List<dynamic>? _allProducts;
  Map<String, List<Map<String, String>>> _crownProductsMap = {};
  Map<String, List<Map<String, String>>> _brimProductsMap = {};
  List<HatShapeInfo>? _cachedAvailableBrimShapes;
  List<dynamic>? _crownFilteredProducts;

  String _metaValue(dynamic entry) {
    final value = ShopifyService.parseMetafieldValue(entry);
    return value.isEmpty ? '—' : value;
  }

  List<HatShapeInfo> get _availableHatTypes =>
      _materialTypes.isNotEmpty ? _materialTypes : hatTypes;

  bool _needsWesternStyleStep(String? typeName) {
    if (typeName == null) return false;
    final n = typeName.toLowerCase();
    return n == 'felt' || n == 'straw';
  }

  bool _skipsShapeWizard(String? typeName) {
    if (typeName == null) return false;
    final n = typeName.toLowerCase();
    return n.contains('ballcap') ||
        n.contains('beanie') ||
        n.contains('flat cap');
  }

  bool _matchShape(String prod, String ui) =>
      ShopifyService.matchShape(prod, ui);

  bool _isWizardCrownShape(HatShapeInfo shape) =>
      !shape.name.toLowerCase().contains('flat cap');

  List<HatShapeInfo> _wizardCrownShapes(Iterable<HatShapeInfo> shapes) =>
      shapes.where(_isWizardCrownShape).toList();

  /// Wizard crown catalog in Shopify admin validation order.
  List<HatShapeInfo> _orderedWizardCrownShapes() {
    final source =
        _rawCrownShapes.isNotEmpty ? _rawCrownShapes : crownShapes;
    return _wizardCrownShapes(source);
  }

  /// Wizard brim catalog in Shopify admin validation order.
  List<HatShapeInfo> _orderedWizardBrimShapes() =>
      _rawBrimShapes.isNotEmpty ? _rawBrimShapes : brimShapes;

  List<HatShapeInfo> _crownShapesForHatType(String? typeName) {
    final shapes = _orderedWizardCrownShapes();
    if (typeName == 'Straw') {
      return shapes.map((shape) {
        final normalized = shape.name.toLowerCase().trim();
        String path = shape.imagePath;
        if (normalized.contains('cattleman')) {
          path = 'assets/images/crowns/cattleman.png';
        } else if (normalized.contains('gus')) {
          path = 'assets/images/crowns/gus.png';
        } else if (normalized.contains('teardrop')) {
          path = 'assets/images/crowns/teardrop.png';
        }
        return HatShapeInfo(
          shape.name,
          path,
          shape.description,
          history: shape.history,
          famousWearers: shape.famousWearers,
          physicalDescription: shape.physicalDescription,
          galleryImages: shape.galleryImages,
        );
      }).toList();
    }
    return shapes;
  }

  /// Returns the correct crown shape list based on the selected hat type.
  List<HatShapeInfo> get _currentCrownShapes =>
      _crownShapesForHatType(selectedHatType?.name);

  HatShapeInfo _mapStringToHatType(String name) {
    final normalized = name.toLowerCase().trim();
    final matched = hatTypes.firstWhere(
      (t) {
        final tName = t.name.toLowerCase();
        return tName == normalized ||
            tName.contains(normalized) ||
            normalized.contains(tName);
      },
      orElse: () {
        if (normalized.contains('beanie') ||
            (normalized.contains('flat') && normalized.contains('cap'))) {
          return hatTypes.firstWhere(
            (t) => t.name.toLowerCase().contains('beanie'),
            orElse: () => hatTypes.last,
          );
        }
        if (normalized.contains('ballcap') || normalized == 'ball cap') {
          return hatTypes.firstWhere(
            (t) => t.name.toLowerCase().contains('ballcap'),
          );
        }
        if (normalized.contains('felt')) {
          return hatTypes.firstWhere((t) => t.name == 'Felt');
        }
        if (normalized.contains('straw')) {
          return hatTypes.firstWhere((t) => t.name == 'Straw');
        }
        return HatShapeInfo(
          name,
          'assets/images/placeholder.png',
          'Hats in this hat type category.',
        );
      },
    );
    return HatShapeInfo(name, matched.imagePath, matched.description);
  }

  HatShapeInfo _mapStringToShapeInfo(String name, {required bool isCrown}) {
    final normalized = name.toLowerCase().trim();

    if (isCrown) {
      final matched = crownShapes.firstWhere(
        (s) {
          final sName = s.name.toLowerCase();
          return sName == normalized ||
              sName.contains(normalized) ||
              normalized.contains(sName);
        },
        orElse: () {
          var lookup = normalized.replaceAll("'s", '').trim();
          if (lookup.contains('cattleman')) {
            lookup = 'cattleman';
          } else if (lookup.contains('texas punch') ||
              lookup.contains('west texas')) {
            lookup = 'texas punch';
          } else if (lookup.contains('cool hand') || lookup == 'chl') {
            lookup = 'brick';
          } else if (lookup.contains('pinch')) {
            lookup = 'pinch front';
          } else if (lookup.contains('rounded brick')) {
            lookup = 'rounded brick';
          } else if (lookup.contains('open crown')) {
            lookup = 'open crown';
          } else if (lookup.contains('flat cap')) {
            lookup = 'flat cap';
          }
          return crownShapes.firstWhere(
            (s) {
              final sName = s.name.toLowerCase();
              return sName.contains(lookup) || lookup.contains(sName);
            },
            orElse: () => HatShapeInfo(
              name,
              'assets/images/placeholder.png',
              'Custom shaped crown.',
              history:
                  'This shape is customized for your individual look and feel. Each hat is meticulously shaped to the customer\'s exact preferences.',
              famousWearers: [],
              physicalDescription: 'Individually creased custom crown.',
            ),
          );
        },
      );
      return HatShapeInfo(
        name,
        matched.imagePath,
        matched.description,
        history: matched.history,
        famousWearers: matched.famousWearers,
        physicalDescription: matched.physicalDescription,
        galleryImages: matched.galleryImages,
      );
    } else {
      final matched = brimShapes.firstWhere(
        (s) {
          final sName = s.name.toLowerCase();
          return sName == normalized ||
              sName.contains(normalized) ||
              normalized.contains(sName);
        },
        orElse: () {
          String lookup = normalized;
          if (normalized == 'wtp' || normalized.contains('west texas')) {
            lookup = 'wtp';
          } else if (normalized == 'chl' || normalized.contains('cool hand')) {
            lookup = 'chl';
          } else if (normalized.contains('george strait') ||
              normalized == 'j' ||
              normalized.startsWith('j ')) {
            lookup = 'j (george strait)';
          } else if (normalized == 'jb') {
            lookup = 'jb';
          } else if (normalized.contains('shovel')) {
            lookup = 'shovel width';
          } else if (normalized.contains('half taco') ||
              normalized.contains('minnick')) {
            lookup = 'half taco';
          } else if (normalized.contains('pencil')) {
            lookup = 'pencil curl';
          } else if (normalized.contains('flanged')) {
            lookup = 'flanged brim';
          } else if (normalized.contains('flip')) {
            lookup = 'flip up';
          } else if (normalized.contains('pulled down') ||
              normalized.contains('downturn')) {
            lookup = 'pulled down';
          } else if (normalized.contains('flat') && normalized.contains('rd')) {
            lookup = 'flat/rd';
          } else if (normalized.contains('slightly curved')) {
            lookup = 'slightly curved';
          } else if (normalized.contains('medium curved')) {
            lookup = 'medium curved';
          } else if (normalized == 'taco') {
            lookup = 'taco';
          }

          return brimShapes.firstWhere(
            (s) {
              final sName = s.name.toLowerCase();
              return sName.contains(lookup) || lookup.contains(sName);
            },
            orElse: () => HatShapeInfo(
              name,
              'assets/images/placeholder.png',
              'Custom shaped brim.',
              history:
                  'A customized brim roll and curve shaped exactly to your preference.',
              famousWearers: [],
              physicalDescription: 'Individually shaped custom brim.',
            ),
          );
        },
      );
      return HatShapeInfo(
        name,
        matched.imagePath,
        matched.description,
        history: matched.history,
        famousWearers: matched.famousWearers,
        physicalDescription: matched.physicalDescription,
        galleryImages: matched.galleryImages,
      );
    }
  }

  HatShapeInfo _defaultHatTypeForProfile(HeadShapeProfile profile) {
    final target = profile.defaultMaterial.toLowerCase();
    return _availableHatTypes.firstWhere(
      (type) => type.name.toLowerCase().contains(target),
      orElse: () => _mapStringToHatType(profile.defaultMaterial),
    );
  }

  void _applyHeadShapeProfileDefaults({bool refreshMaps = false}) {
    final profile = widget.headShapeProfile;
    if (profile == null) return;

    final defaultType = _defaultHatTypeForProfile(profile);
    final canApplyDefaultType = selectedHatType == null ||
        selectedHatType!.name.toLowerCase().contains(
              profile.defaultMaterial.toLowerCase(),
            );

    if (!_hasAppliedProfileDefaults || canApplyDefaultType) {
      selectedHatType = defaultType;
      _hasAppliedProfileDefaults = true;
    }

    if (refreshMaps) {
      _refreshShapeProductMaps();
    }
  }

  /// Picks one representative product image per hat type, driven by the Shopify
  /// `custom.felt_straw_or_ballcap` metafield. Selection is deterministic (stable
  /// by title) and restricted to catalog-eligible hats, so each card reliably
  /// shows a product actually tagged with that material.
  Map<String, String> _computeMaterialExampleImages() {
    if (_allProducts == null) return {};

    final products = ShopifyService.sortPickerExampleProducts(_allProducts!);

    final usedUrls = <String>{};
    final urls = <String, String>{};

    for (final type in _availableHatTypes) {
      for (final product in products) {
        if (!ShopifyService.isEligibleForPickerExample(product)) continue;
        final imageUrl = product['featuredImage']?['url'];
        if (imageUrl == null || imageUrl.toString().isEmpty) continue;
        final url = imageUrl as String;
        if (usedUrls.contains(url)) continue;
        if (!ShopifyService.isHatFinderCatalogProduct(product)) continue;

        final prodType = _metaValue(product['feltStrawOrBallcap']);
        if (ShopifyService.matchesHatType(prodType, type.name)) {
          urls[type.name] = url;
          usedUrls.add(url);
          break;
        }
      }
    }
    return urls;
  }

  void _onProductsLoaded(List<dynamic> products) {
    if (!mounted) return;
    setState(() {
      _allProducts = products;
      _materialExampleUrls = _computeMaterialExampleImages();
    });
    Future.microtask(() {
      if (!mounted) return;
      setState(() {
        _refreshShapeProductMaps();
        if (selectedCrownShape != null) {
          _onCrownSelectionChanged();
        }
      });
    });
  }

  void _refreshShapeProductMaps() {
    if (_allProducts == null) return;

    final crownShapes = List<HatShapeInfo>.from(_currentCrownShapes);
    final brimShapeList = _orderedWizardBrimShapes();

    _crownProductsMap = _buildShapeProductMap(crownShapes, isCrown: true);
    _brimProductsMap = _buildShapeProductMap(brimShapeList, isCrown: false);

    _sortedCrownShapes = List<HatShapeInfo>.from(crownShapes);
    _sortedBrimShapes = List<HatShapeInfo>.from(brimShapeList);
    if (selectedCrownShape != null &&
        !_isWizardCrownShape(selectedCrownShape!)) {
      selectedCrownShape = null;
      _currentCrownCarouselIndex = 0;
    }
    _updateCrownFilteredProducts();
    _rebuildAvailableBrimShapes();
    _syncBrimSelectionToAvailable();
  }

  void _updateCrownFilteredProducts() {
    if (_allProducts == null || selectedCrownShape == null) {
      _crownFilteredProducts = null;
      return;
    }
    var products = ShopifyService.filterProducts(
      _allProducts!,
      hatType: selectedHatType?.name,
      westernStyle: selectedWesternStyle,
      crownShape: selectedCrownShape!.name,
    );
    _crownFilteredProducts = products;
  }

  void _rebuildAvailableBrimShapes() {
    final all = _allBrimShapeOptions;
    final crownProducts = _crownFilteredProducts;
    if (crownProducts == null) {
      _cachedAvailableBrimShapes = all;
      return;
    }
    _cachedAvailableBrimShapes = all.where((brim) {
      for (final product in crownProducts) {
        if (_matchShape(_metaValue(product['brimShape']), brim.name)) {
          return true;
        }
      }
      return false;
    }).toList(growable: false);
  }

  List<HatShapeInfo> get _allBrimShapeOptions =>
      _sortedBrimShapes ?? _orderedWizardBrimShapes();

  /// Brim shapes that have at least one catalog product for the selected crown.
  List<HatShapeInfo> get _availableBrimShapes =>
      _cachedAvailableBrimShapes ?? _allBrimShapeOptions;

  void _onCrownSelectionChanged() {
    _updateCrownFilteredProducts();
    _rebuildAvailableBrimShapes();
    _syncBrimSelectionToAvailable();
  }

  void _syncBrimSelectionToAvailable() {
    final available = _availableBrimShapes;
    if (selectedBrimShape != null &&
        !available.any((b) => b.name == selectedBrimShape!.name)) {
      selectedBrimShape = null;
      _currentBrimCarouselIndex = 0;
      if (_brimCarouselController.hasClients) {
        _brimCarouselController.jumpToPage(0);
      }
    }
  }

  void _applyCrownCarouselDefaults() {
    _currentCrownCarouselIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_crownCarouselController.hasClients) {
        _crownCarouselController.jumpToPage(0);
      }
    });
  }

  void _applyCityBrimCarouselDefaults() {
    if (selectedWesternStyle != 'City') return;
    _currentBrimCarouselIndex = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_brimCarouselController.hasClients) {
        _brimCarouselController.jumpToPage(0);
      }
    });
  }

  void _onWesternStyleSelected(String name) {
    setState(() {
      selectedWesternStyle = name;
      selectedCrownShape = null;
      selectedBrimShape = null;
      _refreshShapeProductMaps();
      if (name == 'City' || name == 'Outdoor') {
        _applyCrownCarouselDefaults();
      }
      if (name == 'City') {
        _applyCityBrimCarouselDefaults();
      }
    });
  }

  void _selectCrownAndAdvance(HatShapeInfo shape, int index) {
    setState(() {
      selectedCrownShape = shape;
      _currentCrownCarouselIndex = index;
      _flippedCardIndex = null;
      _onCrownSelectionChanged();
    });
    _nextPage();
  }

  void _selectBrimAndAdvance(HatShapeInfo shape, int index) {
    setState(() {
      selectedBrimShape = shape;
      _currentBrimCarouselIndex = index;
      _flippedBrimCardIndex = null;
    });
    _advanceWizardOrFinish();
  }

  bool get _isOnLastWizardPage => _currentPageIndex >= _pages.length - 1;

  void _advanceWizardOrFinish() {
    if (_isOnLastWizardPage) {
      _submitSearch();
      return;
    }
    _nextPage();
  }

  List<HatShapeInfo> _uniqueShapeOptions(Iterable<HatShapeInfo> sources) {
    final seen = <String>{};
    final options = <HatShapeInfo>[];
    for (final shape in sources) {
      if (seen.add(shape.name)) options.add(shape);
    }
    return options;
  }

  List<HatShapeInfo> _crownOptionsForResults() {
    return _uniqueShapeOptions([
      if (selectedCrownShape != null &&
          _isWizardCrownShape(selectedCrownShape!))
        selectedCrownShape!,
      ..._wizardCrownShapes(_sortedCrownShapes ?? _currentCrownShapes),
      ..._wizardCrownShapes(crownShapes),
    ]);
  }

  List<HatShapeInfo> _brimOptionsForResults() {
    return _uniqueShapeOptions([
      if (selectedBrimShape != null) selectedBrimShape!,
      ..._availableBrimShapes,
      ..._allBrimShapeOptions,
      ...brimShapes,
    ]);
  }

  Map<String, List<Map<String, String>>> _buildShapeProductMap(
    List<HatShapeInfo> shapes, {
    required bool isCrown,
  }) {
    final map = <String, List<Map<String, String>>>{
      for (final shape in shapes) shape.name: <Map<String, String>>[],
    };
    final seenUrls = <String, Set<String>>{
      for (final shape in shapes) shape.name: <String>{},
    };
    final materialTarget = selectedHatType?.name.toLowerCase();

    for (final product in _allProducts!) {
      if (!ShopifyService.isEligibleForPickerExample(product)) continue;
      if (product['featuredImage']?['url'] == null) continue;

      // Respect the active hat type and style when ranking shape inventory.
      if (materialTarget != null) {
        final prodMaterial =
            _metaValue(product['feltStrawOrBallcap']).toLowerCase();
        if (!prodMaterial.contains(materialTarget)) {
          continue;
        }
      }
      final styleTarget = selectedWesternStyle;
      if (styleTarget != null && styleTarget.isNotEmpty) {
        if (!ShopifyService.matchesWesternStyle(
          hatType: _metaValue(product['feltStrawOrBallcap']),
          city: _metaValue(product['city']),
          outdoors: _metaValue(product['outdoors']),
          westernStyle: styleTarget,
        )) {
          continue;
        }
      }

      final meta =
          _metaValue(isCrown ? product['crownShape'] : product['brimShape']);

      for (final shape in shapes) {
        if (!_matchShape(meta, shape.name)) continue;
        final url = product['featuredImage']['url'] as String;
        if (!seenUrls[shape.name]!.add(url)) continue;
        map[shape.name]!.add({
          'url': url,
          'title': (product['title'] ?? '') as String,
          'matchesMaterial': 'true',
        });
      }
    }

    if (materialTarget != null) {
      for (final entries in map.values) {
        entries.sort((a, b) {
          final aMatches = a['matchesMaterial'] == 'true' ? 1 : 0;
          final bMatches = b['matchesMaterial'] == 'true' ? 1 : 0;
          if (aMatches != bMatches) return bMatches.compareTo(aMatches);
          return _compareShapeExampleEntries(a, b);
        });
      }
    } else {
      for (final entries in map.values) {
        entries.sort(_compareShapeExampleEntries);
      }
    }
    return map;
  }

  dynamic? _productForExampleTitle(String? title) {
    if (_allProducts == null || title == null || title.isEmpty) return null;
    for (final product in _allProducts!) {
      if ((product['title'] ?? '').toString() == title) return product;
    }
    return null;
  }

  int _compareShapeExampleEntries(
    Map<String, String> a,
    Map<String, String> b,
  ) {
    final productA = _productForExampleTitle(a['title']);
    final productB = _productForExampleTitle(b['title']);
    if (productA == null && productB == null) return 0;
    if (productA == null) return 1;
    if (productB == null) return -1;
    return ShopifyService.comparePickerExampleProducts(productA, productB);
  }

  /// Generic hat product photo (background removed) when Shopify has no match.
  static const _hatPhotoPlaceholderAsset = 'assets/images/placeholder.png';

  /// Shape-tagged catalog photo when available.
  ///
  /// Priority: exact shape + hat type, curated example, same shape in another
  /// hat type, then asset placeholder.
  _ShapeCardPhoto _pickShapeCardPhoto({
    required String shapeName,
    required List<Map<String, String>> shopifyProducts,
    required int shapeCarouselIndex,
    required bool isCrown,
  }) {
    final shapeMetaKey = isCrown ? 'crownShape' : 'brimShape';
    final material = selectedHatType?.name.toLowerCase();

    // 1. Exact match — same shape and selected hat type (felt/straw/etc.).
    if (shopifyProducts.isNotEmpty) {
      final pickIndex = (shapeName.hashCode.abs() + shapeCarouselIndex) %
          shopifyProducts.length;
      final pick = shopifyProducts[pickIndex];
      final url = pick['url'];
      if (url != null && url.isNotEmpty) {
        return _ShapeCardPhoto(
          imageUrl: url,
          productTitle: pick['title'],
        );
      }
    }

    // 2. Curated example (e.g. Amberwood for Brick).
    if (_allProducts != null &&
        ShopifyService.preferredExampleTitleTerm(shapeName) != null) {
      final preferred = ShopifyService.pickPreferredShapeExample(
        shapeName: shapeName,
        products: _allProducts!,
        shapeMetaKey: shapeMetaKey,
        materialContains: material,
      );
      if (preferred != null) {
        return _ShapeCardPhoto(
          imageUrl: preferred['url'],
          productTitle: preferred['title'],
        );
      }
    }

    // 3. Same shape in another hat type, then placeholder.
    if (_allProducts != null) {
      final fallback = ShopifyService.pickShapeExamplePhoto(
        products: _allProducts!,
        shapeName: shapeName,
        shapeMetaKey: shapeMetaKey,
        shapeCarouselIndex: shapeCarouselIndex,
        materialContains: material,
      );
      if (fallback != null) {
        return _ShapeCardPhoto(
          imageUrl: fallback['url'],
          productTitle: fallback['title'],
        );
      }
    }

    return const _ShapeCardPhoto();
  }

  Widget _buildShapeCardHatImage(String? imageUrl, {String? fallbackAsset}) {
    const padding = EdgeInsets.fromLTRB(2, 0, 2, 0);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Padding(
        padding: padding,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          alignment: Alignment.center,
          errorBuilder: (_, __, ___) => Padding(
            padding: padding,
            child: _buildHatPhotoPlaceholder(fallbackAsset: fallbackAsset),
          ),
        ),
      );
    }
    return Padding(
      padding: padding,
      child: _buildHatPhotoPlaceholder(fallbackAsset: fallbackAsset),
    );
  }

  Widget _buildHatPhotoPlaceholder({String? fallbackAsset}) {
    final asset = fallbackAsset ?? _hatPhotoPlaceholderAsset;
    return Image.asset(
      asset,
      fit: BoxFit.contain,
      alignment: Alignment.center,
      errorBuilder: (_, __, ___) => Icon(
        Icons.checkroom_outlined,
        size: 88,
        color: Colors.grey.shade400,
      ),
    );
  }

  /// Hat-type grid photos — full hat visible inside the 2×2 grid (no brim crop).
  Widget _buildHatTypeCardImage({
    required String? imageUrl,
    required String imagePath,
    bool compact = false,
  }) {
    final inset = compact
        ? const EdgeInsets.fromLTRB(4, 2, 4, 0)
        : const EdgeInsets.fromLTRB(10, 10, 10, 6);
    Widget buildImage(Widget image) {
      return Padding(padding: inset, child: image);
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ColoredBox(
        color: Colors.white,
        child: buildImage(
          Image.network(
            imageUrl,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) =>
                _buildHatPhotoPlaceholder(fallbackAsset: imagePath),
          ),
        ),
      );
    }
    if (imagePath != 'assets/images/placeholder.png') {
      return ColoredBox(
        color: Colors.white,
        child: buildImage(
          _buildHatPhotoPlaceholder(fallbackAsset: imagePath),
        ),
      );
    }
    return const ColoredBox(
      color: Colors.white,
      child: Center(
        child: Icon(Icons.category, size: 48, color: Colors.grey),
      ),
    );
  }

  static const _shapeCardPagePadding =
      EdgeInsets.only(left: 4, right: 4, top: 0, bottom: 0);
  static const _webWizardGridMaxWidth = 1040.0;
  static const _webWizardGridColumns = 4;
  static const int _shapeCardTitleMaxLines = 3;
  static const double _shapeCardTitlePrimarySize = 17;
  static const double _shapeCardTitleAliasSize = 14;
  static const double _shapeCardTitleLineHeight = 1.15;
  static const double _shapeCardTitleLineGap = 1;
  static const double _shapeCardFeaturedBlockHeight = 44;
  static const double _shapeCardTextLift = 10;

  double get _shapeCardTitleBlockHeight =>
      _shapeCardTitlePrimarySize * _shapeCardTitleLineHeight +
      _shapeCardTitleLineGap +
      _shapeCardTitleAliasSize * _shapeCardTitleLineHeight +
      _shapeCardTitleLineGap +
      _shapeCardTitleAliasSize * _shapeCardTitleLineHeight;

  /// Pro Max class (~932pt logical height). Adjustments below this threshold
  /// are left alone so iPhone 17 / Air layouts stay unchanged.
  bool _isProMaxLayout(BuildContext context) =>
      MediaQuery.sizeOf(context).height >= 920;

  /// Shopify slash-separated names (e.g. Gambler/Telescope) as separate lines.
  /// When there are more than three segments, extras join the third line (e.g.
  /// Brick/Rounded Brick/Minnick/CHL → MINNICK/CHL).
  List<String> _shapeCardTitleParts(String name) {
    if (!name.contains('/')) return [name.toUpperCase()];
    final rawParts = name
        .split('/')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (rawParts.length <= 3) {
      return rawParts.map((part) => part.toUpperCase()).toList();
    }
    return [
      rawParts[0].toUpperCase(),
      rawParts[1].toUpperCase(),
      rawParts.sublist(2).join('/').toUpperCase(),
    ];
  }

  /// Title size scales down for long Shopify validation names (e.g. brim CHL).
  double _shapeCardTitleFontSize(String name) {
    final len = name.length;
    if (len > 48) return 11;
    if (len > 38) return 12;
    if (len > 30) return 13;
    if (len > 24) return 15;
    if (len > 18) return 17;
    return 19;
  }

  double _shapeCardTitleLetterSpacing(String name) {
    final len = name.length;
    if (len > 38) return 0.3;
    if (len > 28) return 0.6;
    if (len > 20) return 0.9;
    return 1.2;
  }

  double _shapeCardImageScale(BuildContext context) {
    const mobileReduction = 0.95;
    if (_isProMaxLayout(context)) return 1.21 * mobileReduction;
    return 1.16 * mobileReduction;
  }

  Widget _buildStackedShapeTitle({
    required String name,
    required Color primaryColor,
    required Color aliasColor,
    bool fixedThreeLineSlot = false,
  }) {
    final parts = _shapeCardTitleParts(name);
    if (fixedThreeLineSlot) {
      const lineBoxPrimary =
          _shapeCardTitlePrimarySize * _shapeCardTitleLineHeight;
      const lineBoxAlias = _shapeCardTitleAliasSize * _shapeCardTitleLineHeight;
      return SizedBox(
        height: _shapeCardTitleBlockHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            for (var i = 0; i < _shapeCardTitleMaxLines; i++)
              Padding(
                padding: EdgeInsets.only(
                  top: i == 0 ? 0 : _shapeCardTitleLineGap,
                ),
                child: SizedBox(
                  height: i == 0 ? lineBoxPrimary : lineBoxAlias,
                  width: double.infinity,
                  child: i < parts.length
                      ? Align(
                          alignment: Alignment.center,
                          child: Text(
                            parts[i],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: i == 0
                                  ? _shapeCardTitlePrimarySize
                                  : _shapeCardTitleAliasSize,
                              fontWeight:
                                  i == 0 ? FontWeight.w800 : FontWeight.w600,
                              color: i == 0 ? primaryColor : aliasColor,
                              letterSpacing: i == 0 ? 1.0 : 0.65,
                              height: _shapeCardTitleLineHeight,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      );
    }

    final baseSize = _shapeCardTitleFontSize(name);
    final baseSpacing = _shapeCardTitleLetterSpacing(name);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < parts.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 1),
            child: Text(
              parts[i],
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: i == 0 ? baseSize : baseSize * 0.84,
                fontWeight: i == 0 ? FontWeight.w800 : FontWeight.w600,
                color: i == 0 ? primaryColor : aliasColor,
                letterSpacing: i == 0 ? baseSpacing : baseSpacing * 0.65,
                height: 1.15,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildShapeCardBackTitle(String name) {
    return _buildStackedShapeTitle(
      name: name,
      primaryColor: Colors.white,
      aliasColor: Colors.white.withValues(alpha: 0.62),
    );
  }

  double _shapeCarouselCardHeight({
    required double maxExpandedHeight,
  }) {
    if (maxExpandedHeight <= 0) return 0;
    // Fill the carousel slot so the card uses all space above the dots.
    return maxExpandedHeight;
  }

  static const _webShapeCarouselMaxWidth = 460.0;
  static const _webShapeCardMaxHeight = 500.0;
  static const _webShapeActionButtonMaxWidth = 230.0;

  Widget _wrapWebShapeActionButton(BuildContext context, Widget button) {
    if (!_isWebDesktopWizard(context)) {
      return SizedBox(width: double.infinity, child: button);
    }
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: _webShapeActionButtonMaxWidth),
        child: SizedBox(width: double.infinity, child: button),
      ),
    );
  }

  // Width of the tap target gutter on each side of the carousel where the
  // chevron arrows live. Reserved from the available width so the carousel
  // never overflows and arrows never overlap the cards.
  static const double _carouselNavGutter = 44.0;

  Widget _buildWizardCarouselArea({
    required Widget pageView,
    required PageController controller,
    required int currentIndex,
    required int itemCount,
  }) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final webDesktop = _isWebDesktopWizard(context);
          var cardHeight = _shapeCarouselCardHeight(
            maxExpandedHeight: constraints.maxHeight,
          );
          if (webDesktop) {
            cardHeight = cardHeight.clamp(0, _webShapeCardMaxHeight);
          }

          final available = constraints.maxWidth;
          // Total block (card area + both gutters) is capped on desktop and
          // never exceeds the available width on any platform.
          final blockWidth = webDesktop
              ? min(available, _webShapeCarouselMaxWidth + _carouselNavGutter * 2)
              : available;

          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: blockWidth,
              height: cardHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildCarouselArrowSlot(
                    visible: currentIndex > 0,
                    icon: Icons.chevron_left_rounded,
                    onTap: () => controller.previousPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  Expanded(
                    child: SizedBox(height: cardHeight, child: pageView),
                  ),
                  _buildCarouselArrowSlot(
                    visible: currentIndex < itemCount - 1,
                    icon: Icons.chevron_right_rounded,
                    onTap: () => controller.nextPage(
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCarouselArrowSlot({
    required bool visible,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: _carouselNavGutter,
      child: Center(
        child: visible
            ? _buildCarouselNavButton(icon: icon, onTap: onTap)
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildCarouselNavButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.7),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: Colors.grey[600]),
      ),
    );
  }

  Widget _buildCarouselDots({
    required int itemCount,
    required int currentIndex,
    int maxDots = 9,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          itemCount.clamp(0, maxDots),
          (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == currentIndex ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: i == currentIndex
                  ? const Color(0xFF2D2926)
                  : Colors.grey.shade300,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselNextUp({
    required int currentIndex,
    required int itemCount,
    required String nextLabel,
  }) {
    if (currentIndex + 1 >= itemCount) {
      return const SizedBox(height: 20);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 2.0, bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            'NEXT UP: ',
            style: GoogleFonts.montserrat(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[500],
              letterSpacing: 1.4,
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                nextLabel,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D2926),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardCarouselFooter({
    required int itemCount,
    required int currentIndex,
    required String nextLabel,
    int maxDots = 9,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCarouselDots(
          itemCount: itemCount,
          currentIndex: currentIndex,
          maxDots: maxDots,
        ),
        _buildCarouselNextUp(
          currentIndex: currentIndex,
          itemCount: itemCount,
          nextLabel: nextLabel,
        ),
      ],
    );
  }

  Widget _buildWizardCardTitleSection(
    String title, {
    EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(14, 10, 14, 4),
  }) {
    final compactWeb = _isWebDesktopWizard(context);
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: compactWeb ? 15 : 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D2926),
              letterSpacing: compactWeb ? 1.0 : 1.2,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 2,
            color: const Color(0xFF559C99),
          ),
        ],
      ),
    );
  }

  Widget _buildWizardSelectionCard({
    required String title,
    required Widget image,
    required bool isSelected,
    required VoidCallback onSelect,
    String? description,
  }) {
    final compactWeb = _isWebDesktopWizard(context);
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF559C99)
                : const Color(0xFF559C99).withValues(alpha: 0.35),
            width: isSelected ? 2.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.03),
              blurRadius: 16,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: image),
              _buildWizardCardTitleSection(
                title,
                padding: EdgeInsets.fromLTRB(
                  14,
                  10,
                  14,
                  description == null || description.isEmpty ? 12 : 4,
                ),
              ),
              if (description != null && description.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    14,
                    0,
                    14,
                    compactWeb ? 10 : 12,
                  ),
                  child: Text(
                    description,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compactWeb ? 10 : 11,
                      color: const Color(0xFF4A4541),
                      height: 1.25,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectHatTypeAndAdvance(HatShapeInfo typeInfo, int index) {
    setState(() {
      selectedHatType = typeInfo;
      selectedWesternStyle = null;
      selectedCrownShape = null;
      selectedBrimShape = null;
      _refreshShapeProductMaps();
    });
    if (_skipsShapeWizard(typeInfo.name)) {
      _submitSearch();
    } else {
      _nextPage();
    }
  }

  Widget _buildHatTypeWizardCard({
    required HatShapeInfo typeInfo,
    required int index,
    required String? imageUrl,
  }) {
    return _buildWizardSelectionCard(
      title: typeInfo.name,
      description: typeInfo.description,
      image: _buildHatTypeCardImage(
        imageUrl: imageUrl,
        imagePath: typeInfo.imagePath,
        compact: true,
      ),
      isSelected: selectedHatType == typeInfo,
      onSelect: () => _selectHatTypeAndAdvance(typeInfo, index),
    );
  }

  Widget _buildStyleCardImage({
    required String? imageUrl,
    required String? fallbackAsset,
    bool compact = false,
  }) {
    if (imageUrl != null) {
      return Image.network(
        imageUrl,
        fit: compact ? BoxFit.contain : BoxFit.cover,
        alignment:
            compact ? Alignment.center : const Alignment(0.0, -0.35),
        errorBuilder: (_, __, ___) => fallbackAsset != null
            ? Image.asset(
                fallbackAsset,
                fit: compact ? BoxFit.contain : BoxFit.cover,
                alignment:
                    compact ? Alignment.center : const Alignment(0.0, -0.35),
              )
            : Container(
                color: Colors.grey[50],
                child: const Icon(Icons.style, size: 48, color: Colors.grey),
              ),
      );
    }
    if (fallbackAsset != null) {
      return Image.asset(
        fallbackAsset,
        fit: compact ? BoxFit.contain : BoxFit.cover,
        alignment: compact ? Alignment.center : const Alignment(0.0, -0.35),
      );
    }
    return Container(
      color: Colors.grey[50],
      child: const Icon(Icons.style, size: 48, color: Colors.grey),
    );
  }

  List<Map<String, String>> get _westernStyleOptions => const [
        {
          'name': 'Western',
          'title': 'Western',
          'desc': 'Classic cowboy styles.',
          'fallback': 'assets/images/western.jpg',
        },
        {
          'name': 'City',
          'title': 'City',
          'desc': 'Fedoras and dress hats.',
          'fallback': 'assets/images/city.png',
        },
        {
          'name': 'Outdoor',
          'title': 'Outdoor/Sportsman',
          'desc': 'Sun and adventure hats.',
          'fallback': 'assets/images/outdoor.png',
        },
      ];

  Map<String, String?> _westernStyleImageUrls(List<dynamic>? products) {
    final styles = _westernStyleOptions;
    final imageUrls = <String, String?>{};
    if (products == null) return imageUrls;

    try {
      var filtered = ShopifyService.sortPickerExampleProducts(
        products.where(
          (p) =>
              ShopifyService.isEligibleForPickerExample(p) &&
              ShopifyService.isHatFinderCatalogProduct(p),
        ),
      );
      if (selectedHatType != null) {
        final target = selectedHatType!.name.toLowerCase();
        filtered = filtered.where((p) {
          final type = _metaValue(p['feltStrawOrBallcap']).toLowerCase();
          return type.contains(target);
        }).toList();
      }
      final usedUrls = <String>{};

      for (final style in styles) {
        final styleName = style['name']!;
        String? foundUrl;

        if (styleName == 'Western') {
          const westernProfiles = [
            '01',
            '1',
            '2',
            '11',
            '18',
            '33',
            '45',
            '48',
            '50',
            '72',
            '75',
            '77',
            '91',
            '94',
            '9G',
          ];
          for (final product in filtered) {
            final profile = _metaValue(product['stetsonProfile']);
            final url = product['featuredImage']?['url'] as String?;
            if (westernProfiles.contains(profile) &&
                url != null &&
                !usedUrls.contains(url)) {
              foundUrl = url;
              break;
            }
          }
        } else if (styleName == 'City') {
          for (final product in filtered) {
            final url = product['featuredImage']?['url'] as String?;
            if (_metaValue(product['city']).toLowerCase() == 'true' &&
                url != null &&
                !usedUrls.contains(url)) {
              foundUrl = url;
              break;
            }
          }
        } else if (styleName == 'Outdoor') {
          for (final product in filtered) {
            final url = product['featuredImage']?['url'] as String?;
            if (_metaValue(product['outdoors']).toLowerCase() == 'true' &&
                url != null &&
                !usedUrls.contains(url)) {
              foundUrl = url;
              break;
            }
          }
        }

        if (foundUrl != null) {
          usedUrls.add(foundUrl);
        }
        imageUrls[styleName] = foundUrl;
      }
    } catch (_) {}

    return imageUrls;
  }

  void _selectWesternStyleAndAdvance(String name, int index) {
    _onWesternStyleSelected(name);
    setState(() => _currentStyleCarouselIndex = index);
    _nextPage();
  }

  Widget _buildStyleWizardCard({
    required Map<String, String> style,
    required int index,
    required Map<String, String?> imageUrls,
    bool carouselActive = false,
  }) {
    final name = style['name']!;
    final title = style['title'] ?? name;
    final isSelected = selectedWesternStyle == name ||
        (carouselActive && index == _currentStyleCarouselIndex);
    final imageUrl = imageUrls[name];

    return _buildWizardSelectionCard(
      title: title,
      description: style['desc'],
      image: _buildStyleCardImage(
        imageUrl: imageUrl,
        fallbackAsset: style['fallback'],
        compact: true,
      ),
      isSelected: isSelected,
      onSelect: () => _selectWesternStyleAndAdvance(name, index),
    );
  }

  Widget _buildWizardRowPager({
    required int itemCount,
    required Widget Function(BuildContext context, int index) itemBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var cardHeight = _shapeCarouselCardHeight(
          maxExpandedHeight: constraints.maxHeight,
        );
        if (_isWebDesktopWizard(context)) {
          cardHeight = cardHeight.clamp(0, _webShapeCardMaxHeight);
        }
        final maxBlockWidth =
            min(constraints.maxWidth - 24, _webWizardGridMaxWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
            child: _WizardRowPager(
              itemCount: itemCount,
              maxBlockWidth: maxBlockWidth,
              cardHeight: cardHeight,
              itemBuilder: itemBuilder,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStyleWebRowPager(Map<String, String?> imageUrls) {
    final styles = _westernStyleOptions;
    return _buildWizardRowPager(
      itemCount: styles.length,
      itemBuilder: (context, index) => _buildStyleWizardCard(
        style: styles[index],
        index: index,
        imageUrls: imageUrls,
      ),
    );
  }

  Widget _buildStyleWebCarousel(Map<String, String?> imageUrls) {
    final styles = _westernStyleOptions;
    return Column(
      children: [
        _buildWizardCarouselArea(
          controller: _styleCarouselController,
          currentIndex: _currentStyleCarouselIndex,
          itemCount: styles.length,
          pageView: PageView.builder(
            controller: _styleCarouselController,
            clipBehavior: Clip.hardEdge,
            onPageChanged: (index) {
              setState(() {
                _currentStyleCarouselIndex = index;
                if (index < styles.length) {
                  selectedWesternStyle = styles[index]['name'];
                }
              });
            },
            itemCount: styles.length,
            itemBuilder: (context, index) {
              final style = styles[index];

              return Padding(
                padding: _shapeCardPagePadding,
                child: _buildStyleWizardCard(
                  style: style,
                  index: index,
                  imageUrls: imageUrls,
                  carouselActive: true,
                ),
              );
            },
          ),
        ),
        _buildWizardCarouselFooter(
          itemCount: styles.length,
          currentIndex: _currentStyleCarouselIndex,
          nextLabel: _currentStyleCarouselIndex + 1 < styles.length
              ? (styles[_currentStyleCarouselIndex + 1]['title'] ??
                  styles[_currentStyleCarouselIndex + 1]['name']!)
              : '',
        ),
      ],
    );
  }

  TextStyle get _wizardStepTitleStyle =>
      SectionTitleStyle.playfairBold(fontSize: SectionTitleStyle.wizard);

  Widget _buildWizardStepTitle(String title) {
    final compactWeb = _isWebDesktopWizard(context);
    return Padding(
      padding: compactWeb
          ? WizardHeaderSpacing.stepTitleWeb
          : WizardHeaderSpacing.stepTitle,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: compactWeb
            ? _wizardStepTitleStyle.copyWith(
                fontSize: SectionTitleStyle.wizardCompactWeb,
              )
            : _wizardStepTitleStyle,
      ),
    );
  }

  Widget _buildWizardEmptyState({
    required String message,
    bool showFindHats = false,
  }) {
    return Expanded(
      child: Align(
        alignment: const Alignment(0, -0.12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.55,
                  ),
                ),
                if (showFindHats) ...[
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF559C99),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Find Hats With As Many of Your Choices As Possible',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.15,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Brim shape stays open — refine filters on the results page.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.45,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShapeGuideLink({
    required String label,
    required WidgetBuilder builder,
  }) {
    // Compact subtitle directly under the step title — minimal vertical
    // footprint so the cards keep the same height as the Hat Type step.
    final compactWeb = _isWebDesktopWizard(context);
    return Padding(
      padding: compactWeb
          ? const EdgeInsets.only(bottom: WizardHeaderSpacing.gap)
          : WizardHeaderSpacing.guideLink,
      child: Center(
        child: TextButton.icon(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: builder),
          );
        },
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF559C99),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        icon: const Icon(Icons.menu_book_outlined, size: 14),
        label: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildBrimGuideLink() => _buildShapeGuideLink(
        label: 'What do these mean? View the brim guide',
        builder: (_) => ShapeGuideScreen.brim(),
      );

  Widget _buildCrownGuideLink() => _buildShapeGuideLink(
        label: 'What do these mean? View the crown guide',
        builder: (_) => ShapeGuideScreen.crown(),
      );

  Widget _buildExampleProductOverlay(String productTitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Featured:',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF5A5551),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 1),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            productTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF3C3530),
              fontStyle: FontStyle.italic,
              letterSpacing: 0.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShapeCardFeaturedSection(String? productTitle) {
    final hasTitle = productTitle != null && productTitle.isNotEmpty;
    return SizedBox(
      height: _shapeCardFeaturedBlockHeight,
      child: hasTitle
          ? Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 2),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildExampleProductOverlay(productTitle),
              ),
            )
          : null,
    );
  }

  /// Shape name below the hat photo — primary line plus muted alias lines and a teal accent rule.
  Widget _buildShapeCardTitleBar(String name) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStackedShapeTitle(
            name: name,
            primaryColor: const Color(0xFF2D2926),
            aliasColor: const Color(0xFF5A5551),
            fixedThreeLineSlot: true,
          ),
          const SizedBox(height: 6),
          Container(
            width: 40,
            height: 2,
            color: const Color(0xFF559C99),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeCardFrontFooter({
    required HatShapeInfo shape,
    required VoidCallback onFlip,
  }) {
    final compactWeb = _isWebDesktopWizard(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compactWeb ? 12 : 14,
        compactWeb ? 4 : 6,
        compactWeb ? 12 : 14,
        compactWeb ? 8 : 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            shape.description,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compactWeb ? 10 : 11,
              color: const Color(0xFF4A4541),
              height: 1.25,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: compactWeb ? 6 : 8),
          _wrapWebShapeActionButton(
            context,
            OutlinedButton(
              onPressed: onFlip,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF559C99),
                side: const BorderSide(color: Color(0xFF559C99), width: 1.2),
                padding: EdgeInsets.symmetric(
                  horizontal: compactWeb ? 10 : 12,
                  vertical: compactWeb ? 4 : 5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'FLIP FOR MORE INFO',
                style: GoogleFonts.montserrat(
                  fontSize: compactWeb ? 8 : 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeCardBackFace({
    required BuildContext context,
    required HatShapeInfo shape,
    required bool isSelected,
    required VoidCallback onUnflip,
    bool compact = false,
    double borderRadius = 14,
  }) {
    final padding = compact
        ? const EdgeInsets.fromLTRB(10, 8, 10, 6)
        : const EdgeInsets.fromLTRB(20, 16, 20, 12);
    final historyLabelSize = compact ? 8.0 : 10.0;
    final historyBodySize = compact ? 11.0 : 16.0;
    final infoIconSize = compact ? 14.0 : 18.0;
    final infoLabelSize = compact ? 7.0 : 10.0;
    final infoButtonPadding =
        compact ? const EdgeInsets.symmetric(vertical: 8) : const EdgeInsets.symmetric(vertical: 14);
    final flipBackFontSize = compact ? 7.0 : 8.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: const Color(0xFF2D2926),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFF559C99)
              : const Color(0xFF3D3936),
          width: isSelected ? 3 : 1,
        ),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildShapeCardBackTitle(shape.name),
            SizedBox(height: compact ? 4 : 6),
            Container(
              width: 40,
              height: 2,
              color: const Color(0xFF559C99),
            ),
            SizedBox(height: compact ? 8 : 14),
            Text(
              'THE HISTORY',
              style: GoogleFonts.montserrat(
                fontSize: historyLabelSize,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF559C99),
                letterSpacing: compact ? 2.0 : 3.0,
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  shape.history.isNotEmpty ? shape.history : shape.description,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: historyBodySize,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 6 : 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showShapeDetailSheet(context, shape, 'wearers'),
                    icon: Icon(Icons.people_outline, size: infoIconSize),
                    label: Text(
                      'FAMOUS\nWEARERS',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: infoLabelSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: compact ? 1.0 : 1.5,
                        height: 1.3,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: infoButtonPadding,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(compact ? 8 : 10),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: compact ? 6 : 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        _showShapeDetailSheet(context, shape, 'physical'),
                    icon: Icon(Icons.straighten, size: infoIconSize),
                    label: Text(
                      'THE\nSHAPE',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: infoLabelSize,
                        fontWeight: FontWeight.w700,
                        letterSpacing: compact ? 1.0 : 1.5,
                        height: 1.3,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      padding: infoButtonPadding,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(compact ? 8 : 10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: compact ? 6 : 10),
            TextButton(
              onPressed: onUnflip,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'TAP TO FLIP BACK',
                style: GoogleFonts.montserrat(
                  fontSize: flipBackFontSize,
                  color: Colors.white30,
                  letterSpacing: compact ? 1.5 : 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShapeFourUpFlipFooter({
    required HatShapeInfo shape,
    required VoidCallback onFlip,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            shape.description,
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              fontSize: 8,
              color: const Color(0xFF4A4541),
              height: 1.2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            height: 26,
            child: OutlinedButton(
              onPressed: onFlip,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF559C99),
                side: const BorderSide(color: Color(0xFF559C99), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'FLIP FOR MORE INFO',
                style: GoogleFonts.montserrat(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeCardFrontFace({
    required BuildContext context,
    required HatShapeInfo shape,
    required String? imageUrl,
    required String? featuredProductTitle,
    required bool isSelected,
    required VoidCallback onFlip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF559C99)
              : const Color(0xFF559C99).withValues(alpha: 0.35),
          width: isSelected ? 2.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSelected ? 0.06 : 0.03),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildShapeCardFeaturedSection(featuredProductTitle),
            Expanded(
              child: ClipRect(
                child: Align(
                  alignment: Alignment.center,
                  child: Transform.scale(
                    scale: _shapeCardImageScale(context),
                    child: _buildShapeCardHatImage(
                      imageUrl,
                      fallbackAsset: shape.imagePath,
                    ),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -_shapeCardTextLift),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildShapeCardTitleBar(shape.name),
                  _buildShapeCardFrontFooter(
                    shape: shape,
                    onFlip: onFlip,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _applyFallbackChoices() {
    _materialTypes = List<HatShapeInfo>.from(hatTypes);
    _rawCrownShapes = List<HatShapeInfo>.from(crownShapes);
    _rawBrimShapes = List.from(brimShapes);
    if (_allProducts != null) {
      _materialExampleUrls = _computeMaterialExampleImages();
    }
  }

  Future<void> _loadDynamicChoices() async {
    final cached = ShopifyService.peekValidationChoices();
    if (cached != null) {
      _applyChoicesFromApi(cached);
    }

    try {
      // Always refresh from Shopify admin so crown/brim order stays current
      // (splash may have preloaded an older cached list).
      final choices =
          await ShopifyService.fetchValidationChoices(forceRefresh: true);
      if (!mounted) return;
      _applyChoicesFromApi(choices);
    } catch (e) {
      debugPrint('Error loading dynamic validation choices: $e');
      if (cached == null && mounted) {
        setState(_applyFallbackChoices);
      }
    }
  }

  void _syncCrownCarouselToSelection() {
    if (selectedCrownShape == null) return;
    final shapes = _currentCrownShapes;
    final index = shapes.indexWhere((s) => s.name == selectedCrownShape!.name);
    if (index < 0) return;
    _currentCrownCarouselIndex = index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_crownCarouselController.hasClients) return;
      _crownCarouselController.jumpToPage(index);
    });
  }

  void _applyChoicesFromApi(Map<String, List<String>> choices) {
    final crownStrings = choices['crown_shapes'] ?? [];
    final brimStrings = choices['brim_shapes'] ?? [];
    final materialStrings = choices['material_types'] ?? [];
    final previousCrown = selectedCrownShape?.name;
    final previousBrim = selectedBrimShape?.name;

    if (!mounted) return;
    setState(() {
      _materialTypes = materialStrings.map(_mapStringToHatType).toList();
      _rawCrownShapes = crownStrings
          .map((name) => _mapStringToShapeInfo(name, isCrown: true))
          .toList();
      _rawBrimShapes = brimStrings
          .map((name) => _mapStringToShapeInfo(name, isCrown: false))
          .toList();
      _applyHeadShapeProfileDefaults();
      if (_allProducts != null) {
        _materialExampleUrls = _computeMaterialExampleImages();
      }

      if (previousCrown != null) {
        final match = _rawCrownShapes
            .where((shape) => shape.name == previousCrown)
            .firstOrNull;
        if (match != null) {
          selectedCrownShape = match;
        }
      }
      if (previousBrim != null) {
        final match =
            _rawBrimShapes.where((s) => s.name == previousBrim).firstOrNull;
        if (match != null) {
          selectedBrimShape = match;
        }
      }
    });
    if (_allProducts != null) {
      Future.microtask(() {
        if (!mounted) return;
        setState(() {
          _refreshShapeProductMaps();
          _syncCrownCarouselToSelection();
        });
      });
    } else {
      _syncCrownCarouselToSelection();
    }
  }

  void _startCatalogLoad() {
    // Wizard crown/brim filtering requires metafields — use full catalog, not lite.
    final cached = ShopifyService.peekFullProducts();
    if (cached != null) {
      _allProducts = cached;
      _allProductsFuture = Future.value(cached);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onProductsLoaded(cached);
      });
      return;
    }

    _allProductsFuture = ShopifyService.fetchFullProducts().then((products) {
      if (mounted) _onProductsLoaded(products);
      return products;
    });
  }

  @override
  void initState() {
    super.initState();
    _applyHeadShapeProfileDefaults();
    _applyFallbackChoices();
    _startCatalogLoad();
    _loadDynamicChoices();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _styleCarouselController.dispose();
    _crownCarouselController.dispose();
    _brimCarouselController.dispose();
    super.dispose();
  }

  List<Widget> get _pages {
    final pages = <Widget>[_buildVisualHatTypeSelection()];
    if (_needsWesternStyleStep(selectedHatType?.name)) {
      pages.add(_buildVisualWesternSelection());
    }
    pages.addAll([
      _buildVisualCrownSelection(),
      _buildVisualBrimSelection(),
    ]);
    return pages;
  }

  void _nextPage({bool overrideValidation = false}) {
    FocusScope.of(context).unfocus();
    if (!overrideValidation) {
      if (_currentPageIndex == 0 && selectedHatType == null) {
        setState(() {
          selectedHatType = _availableHatTypes.first;
        });
      }
      bool hasWestern = _needsWesternStyleStep(selectedHatType?.name);
      int westernIndex = hasWestern ? 1 : -1;

      if (_currentPageIndex == westernIndex && selectedWesternStyle == null) {
        setState(() {
          selectedWesternStyle = 'Western';
        });
      }
      // Crown and brim pages: null selection = Any — just advance without forcing a pick
    }

    if (_currentPageIndex >= _pages.length - 1) {
      _submitSearch();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousPage() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Discrete top-left back button. Overlaid so it never shifts the layout:
  /// goes to the previous wizard step, or exits the wizard from step one.
  Widget _buildDiscreteBackButton(BuildContext context) {
    const espresso = Color(0xFF2D2926);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 10, top: 6),
        child: Semantics(
          button: true,
          label: 'Back',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _handleSystemBack(false),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: espresso.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 19,
                  color: espresso.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _exitWizard() {
    FocusScope.of(context).unfocus();
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    widget.onExit?.call();
  }

  void _submitSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HatResultsScreen(
          headShapeProfile: widget.headShapeProfile,
          headMeasurementProfile: widget.headMeasurementProfile,
          hatType: selectedHatType?.name,
          westernStyle: selectedWesternStyle,
          crownShape: selectedCrownShape?.name,
          brimShape: selectedBrimShape?.name,
          crownShapeOptions: _crownOptionsForResults(),
          brimShapeOptions: _brimOptionsForResults(),
        ),
      ),
    );
  }

  void _handleSystemBack(bool didPop) {
    if (didPop) return;
    if (_currentPageIndex > 0) {
      _previousPage();
      return;
    }
    _exitWizard();
  }

  bool get _allowRoutePop =>
      _currentPageIndex == 0 && Navigator.of(context).canPop();

  bool get _isOverlayRoute => Navigator.of(context).canPop();

  /// App shell embed and Pro Max: BACK/NEXT live in the body column.
  bool _useInlineWizardFooter(BuildContext context) =>
      !_isOverlayRoute || _isProMaxLayout(context);

  Widget? _buildScaffoldFooter(BuildContext context) {
    // When embedded in AppShell (not a pushed overlay), the shell renders
    // the nav bar — returning anything here causes a double nav bar.
    if (!_isOverlayRoute) return null;

    if (_useInlineWizardFooter(context)) {
      return const ShellTabBarFooter(selectedIndex: 1);
    }
    return ShellTabBarWithFooter(
      selectedIndex: 1,
      footer: _buildBottomNav(includeBottomSafeArea: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowRoutePop,
      onPopInvokedWithResult: (didPop, _) => _handleSystemBack(didPop),
      child: Scaffold(
      extendBodyBehindAppBar: !_useWebCompactWizardHeader(context),
      appBar: _useWebCompactWizardHeader(context)
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 0,
              automaticallyImplyLeading: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: _buildProgressBar(),
              ),
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight:
                  MoonRidgeLogoSizes.wizardAppBar + WizardHeaderSpacing.gap,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/Moon Ridge Header Logo.png',
                    height: MoonRidgeLogoSizes.wizardAppBar,
                  ),
                  const SizedBox(height: WizardHeaderSpacing.gap),
                ],
              ),
              centerTitle: true,
              automaticallyImplyLeading: false,
              leading: null,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: _buildProgressBar(),
              ),
            ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white, // Clean, airy background
            ),
            child: SafeArea(
              bottom: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: kIsWeb
                        ? AppBreakpoints.webAppMaxWidth(context)
                        : 1040,
                  ),
                  child: Column(
                    children: [
                      if (_useWebCompactWizardHeader(context))
                        _buildWizardCenterLogo(context),
                      if (widget.headShapeProfile != null)
                        _buildHeadShapeProfileBanner(widget.headShapeProfile!),
                      if (widget.headMeasurementProfile != null)
                        _buildHeadMeasurementBanner(
                            widget.headMeasurementProfile!),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics:
                              const NeverScrollableScrollPhysics(), // Disable swipe to force using buttons
                          onPageChanged: (index) {
                            setState(() {
                              _currentPageIndex = index;
                              _flippedCardIndex = null;
                              _flippedBrimCardIndex = null;
                              if (index == 0) {
                                _materialExampleUrls =
                                    _computeMaterialExampleImages();
                              }
                            });
                          },
                          children: _pages,
                        ),
                      ),
                      if (_useInlineWizardFooter(context))
                        _buildBottomNav(includeBottomSafeArea: false),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: _buildDiscreteBackButton(context),
          ),
        ],
      ),
      bottomNavigationBar: _buildScaffoldFooter(context),
      ),
    );
  }

  Widget _buildHeadShapeProfileBanner(HeadShapeProfile profile) {
    final compact = _isProMaxLayout(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, compact ? 8 : 10, 18, compact ? 8 : 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F1EA),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4DED1)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.face_retouching_natural_outlined,
            color: Color(0xFF559C99),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${profile.shortLabel} fit profile',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2D2926),
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile.fitGuidance,
                  maxLines: compact ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF2D2926).withValues(alpha: 0.82),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadMeasurementBanner(HeadMeasurementProfile measurement) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 9, 18, 11),
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        border: Border(
          bottom: BorderSide(color: Color(0xFFE4DED1)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.straighten_outlined,
            color: Color(0xFF559C99),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Size starting point: ${measurement.shortLabel}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: const Color(0xFF2D2926).withValues(alpha: 0.82),
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return SizedBox(
      height: 3,
      width: double.infinity,
      child: LinearProgressIndicator(
        value: (_currentPageIndex + 1) / _pages.length.toDouble(),
        minHeight: 3,
        backgroundColor: Colors.grey[200],
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF559C99)),
      ),
    );
  }

  String get _navButtonText {
    bool hasWestern = _needsWesternStyleStep(selectedHatType?.name);
    if (_currentPageIndex == 0) {
      return hasWestern ? 'Next: Style' : 'Next: Crown Shape';
    }
    int westernIndex = hasWestern ? 1 : -1;
    int crownIndex = hasWestern ? 2 : 1;
    int brimIndex = hasWestern ? 3 : 2;
    if (_currentPageIndex == westernIndex) return 'Next: Crown Shape';
    if (_currentPageIndex == crownIndex) {
      return selectedCrownShape != null
          ? '✓ Next: Brim Shape'
          : 'Any Crown · Next';
    }
    if (_currentPageIndex == brimIndex) {
      return selectedBrimShape != null
          ? '✓ Find Hats'
          : 'Any Brim · Find Hats';
    }
    return 'Find Hats';
  }

  Widget _buildBottomNav({bool includeBottomSafeArea = true}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: includeBottomSafeArea,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed:
                    _currentPageIndex > 0 ? _previousPage : _exitWizard,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D2926),
                  side: const BorderSide(color: Color(0xFF2D2926), width: 1.5),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'BACK',
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _currentPageIndex < _pages.length - 1
                    ? _nextPage
                    : _submitSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D2926),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: _buildNextButtonContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the inner Row for the Next/Find button, with a teal checkmark
  /// when the current wizard step has an active selection.
  Widget _buildNextButtonContent() {
    bool hasWestern = _needsWesternStyleStep(selectedHatType?.name);
    int crownIndex = hasWestern ? 2 : 1;
    int brimIndex = hasWestern ? 3 : 2;

    bool showTealCheck = false;
    if (_currentPageIndex == crownIndex && selectedCrownShape != null) {
      showTealCheck = true;
    } else if (_currentPageIndex == brimIndex && selectedBrimShape != null) {
      showTealCheck = true;
    }

    final label = _navButtonText;
    // Strip the leading '✓ ' from label — we render it as an icon
    final displayLabel = label.startsWith('✓ ')
        ? label.substring(2).toUpperCase()
        : label.toUpperCase();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTealCheck) ...[
          const Icon(Icons.check_circle_rounded,
              size: 18, color: Color(0xFF559C99)),
          const SizedBox(width: 6),
        ],
        Text(
          displayLabel,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(width: 8),
        const Icon(
          Icons.arrow_forward,
          size: 18,
          color: Colors.white,
        ),
      ],
    );
  }

  Widget _buildVisualHatTypeSelection() {
    return Column(
      children: [
        _buildWizardStepTitle('Select a Hat Type:'),
        Padding(
          padding: WizardHeaderSpacing.actionRow,
          child: OutlinedButton(
            onPressed: () {
              setState(() => selectedHatType = null);
              _nextPage(overrideValidation: true);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2D2926),
              side: const BorderSide(color: Color(0xFF2D2926), width: 1.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: Text(
              'ANY HAT TYPE',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _allProductsFuture,
            builder: (context, snapshot) {
              final catalogLoading = _allProducts == null &&
                  snapshot.connectionState == ConnectionState.waiting;

              return Column(
                children: [
                  if (catalogLoading)
                    const LinearProgressIndicator(
                      minHeight: 2,
                      color: Color(0xFF559C99),
                    ),
                  Expanded(
                    child: LayoutBuilder(
                          builder: (context, c) {
                            final fourUp = _isWebWizardFourUp(c.maxWidth);
                            final crossAxisCount =
                                fourUp ? _webWizardGridColumns : 2;
                            const useStyleCards = kIsWeb;
                            final aspect = fourUp
                                ? 0.72
                                : useStyleCards
                                    ? 0.58
                                    : (_isProMaxLayout(context) ? 0.92 : 0.85);

                            Widget buildGrid({required EdgeInsets padding}) {
                              return GridView.count(
                                crossAxisCount: crossAxisCount,
                                shrinkWrap: fourUp,
                                physics: fourUp
                                    ? const NeverScrollableScrollPhysics()
                                    : null,
                                padding: padding,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: aspect,
                                children:
                                    _availableHatTypes.map((typeInfo) {
                                  final imageUrl =
                                      _materialExampleUrls[typeInfo.name];
                                  final index =
                                      _availableHatTypes.indexOf(typeInfo);

                                  if (useStyleCards) {
                                    return _buildHatTypeWizardCard(
                                      typeInfo: typeInfo,
                                      index: index,
                                      imageUrl: imageUrl,
                                    );
                                  }

                                  final isSelected =
                                      selectedHatType == typeInfo;

                                  return Card(
                                    elevation: 0,
                                    clipBehavior: Clip.antiAlias,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: isSelected
                                            ? const Color(0xFF559C99)
                                            : const Color(0xFF559C99)
                                                .withValues(alpha: 0.35),
                                        width: isSelected ? 3 : 1,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () => _selectHatTypeAndAdvance(
                                        typeInfo,
                                        index,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(
                                            child: ClipRect(
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Transform.scale(
                                                  scale: 1.1,
                                                  child: _buildHatTypeCardImage(
                                                    imageUrl: imageUrl,
                                                    imagePath:
                                                        typeInfo.imagePath,
                                                    compact: fourUp,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              vertical:
                                                  fourUp ? 10.0 : 12.0,
                                              horizontal: fourUp ? 4.0 : 0,
                                            ),
                                            color: Colors.white,
                                            child: Text(
                                              typeInfo.name.toUpperCase(),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.montserrat(
                                                fontSize: fourUp ? 11 : 14,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF2D2926),
                                                letterSpacing:
                                                    fourUp ? 1.2 : 2.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            }

                            if (fourUp) {
                              return _buildWizardRowPager(
                                itemCount: _availableHatTypes.length,
                                itemBuilder: (context, index) {
                                  final typeInfo =
                                      _availableHatTypes[index];
                                  final imageUrl =
                                      _materialExampleUrls[typeInfo.name];
                                  return _buildHatTypeWizardCard(
                                    typeInfo: typeInfo,
                                    index: index,
                                    imageUrl: imageUrl,
                                  );
                                },
                              );
                            }

                            return buildGrid(
                              padding: EdgeInsets.fromLTRB(
                                12,
                                12,
                                12,
                                _isProMaxLayout(context) ? 4 : 12,
                              ),
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
    );
  }

  bool _isWebDesktopWizard(BuildContext context) =>
      kIsWeb && AppBreakpoints.isDesktop(context);

  /// Web tablet+: logo lives in page body; header is text-only + progress bar.
  bool _useWebCompactWizardHeader(BuildContext context) =>
      kIsWeb && AppBreakpoints.isTablet(context);

  Widget _buildWizardCenterLogo(BuildContext context) {
    final height = AppBreakpoints.isDesktop(context)
        ? MoonRidgeLogoSizes.wizardWebDesktop
        : MoonRidgeLogoSizes.wizardWebTablet;
    return Padding(
      padding: WizardHeaderSpacing.webLogo,
      child: Center(
        child: Image.asset(
          'assets/images/Moon Ridge Header Logo.png',
          height: height,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  /// Web laptop+: hat type / style show four cards in one row.
  bool _isWebWizardFourUp(double layoutWidth) =>
      kIsWeb && layoutWidth >= AppBreakpoints.laptop;

  /// Web tablet+: style step uses the crown-sized carousel.
  bool _useWebWizardCarousel(double layoutWidth) =>
      kIsWeb && layoutWidth >= AppBreakpoints.tablet;

  Widget _buildVisualWesternSelection() {
    return Column(
      children: [
        _buildWizardStepTitle('Select Style:'),
        Padding(
          padding: WizardHeaderSpacing.actionRow,
          child: OutlinedButton(
            onPressed: () {
              setState(() => selectedWesternStyle = null);
              _nextPage(overrideValidation: true);
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2D2926),
              side: const BorderSide(color: Color(0xFF2D2926), width: 1.0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: Text(
              'ANY STYLE',
              style: GoogleFonts.montserrat(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _allProductsFuture,
            builder: (context, snapshot) {
              final styles = _westernStyleOptions;
              final imageUrls = _westernStyleImageUrls(
                snapshot.hasData ? snapshot.data : null,
              );

              return LayoutBuilder(
                builder: (context, constraints) {
                  if (_isWebWizardFourUp(constraints.maxWidth)) {
                    return _buildStyleWebRowPager(imageUrls);
                  }
                  if (_useWebWizardCarousel(constraints.maxWidth)) {
                    return _buildStyleWebCarousel(imageUrls);
                  }

                  final cards = List.generate(styles.length, (index) {
                    final style = styles[index];
                    final name = style['name']!;
                    final isSelected = selectedWesternStyle == name;
                    final imageUrl = imageUrls[name];

                    return Card(
                      elevation: 0,
                      clipBehavior: Clip.antiAlias,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF559C99)
                              : const Color(0xFF559C99).withValues(alpha: 0.35),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () =>
                            _selectWesternStyleAndAdvance(name, index),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _buildStyleCardImage(
                                imageUrl: imageUrl,
                                fallbackAsset: style['fallback'],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 8.0,
                              ),
                              color: Colors.white,
                              child: Text(
                                (style['title'] ?? name).toUpperCase(),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.montserrat(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2D2926),
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });

                  const horizontalPadding = 12.0;
                  const crossAxisSpacing = 12.0;
                  final itemWidth = (constraints.maxWidth -
                          horizontalPadding * 2 -
                          crossAxisSpacing) /
                      2;
                  final itemHeight = itemWidth / 0.85;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(
                      left: horizontalPadding,
                      right: horizontalPadding,
                      top: 12,
                      bottom: 40,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: crossAxisSpacing,
                      runSpacing: crossAxisSpacing,
                      children: List.generate(cards.length, (index) {
                        return SizedBox(
                          width: itemWidth,
                          height: itemHeight,
                          child: cards[index],
                        );
                      }),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showShapeDetailSheet(
      BuildContext context, HatShapeInfo shape, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF2D2926),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                      children: [
                        Text(
                          shape.name.toUpperCase(),
                          style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 3.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                            width: 40,
                            height: 2,
                            color: const Color(0xFF559C99)),
                        const SizedBox(height: 12),
                        Text(
                          type == 'wearers' ? 'FAMOUS WEARERS' : 'THE SHAPE',
                          style: GoogleFonts.montserrat(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF559C99),
                            letterSpacing: 3.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Content
                  Expanded(
                    child: type == 'wearers'
                        ? _buildFamousWearersContent(shape, scrollController)
                        : _buildPhysicalDescriptionContent(
                            shape, scrollController),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFamousWearersContent(
      HatShapeInfo shape, ScrollController controller) {
    if (shape.famousWearers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Famous wearers coming soon...',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      itemCount: shape.famousWearers.length,
      separatorBuilder: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Divider(color: Colors.white12, height: 1),
      ),
      itemBuilder: (context, index) {
        final wearer = shape.famousWearers[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF559C99).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      wearer['name']?.substring(0, 1) ?? '?',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF559C99),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    wearer['name'] ?? '',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 48),
              child: Text(
                wearer['context'] ?? '',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 14,
                  color: Colors.white70,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPhysicalDescriptionContent(
      HatShapeInfo shape, ScrollController controller) {
    return SingleChildScrollView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF559C99).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.straighten,
                color: Color(0xFF559C99), size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            shape.physicalDescription.isNotEmpty
                ? shape.physicalDescription
                : shape.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.7,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebWizardShapeCard({
    required BuildContext context,
    required HatShapeInfo shape,
    required String? imageUrl,
    required bool isSelected,
    required bool isFlipped,
    required VoidCallback onSelect,
    required VoidCallback onFlip,
    required VoidCallback onUnflip,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isFlipped ? onUnflip : null,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: isFlipped ? pi : 0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
        builder: (context, angle, _) {
          final showBack = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: showBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _buildShapeCardBackFace(
                      context: context,
                      shape: shape,
                      isSelected: isSelected,
                      onUnflip: onUnflip,
                      compact: true,
                      borderRadius: 12,
                    ),
                  )
                : Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF559C99)
                            : const Color(0xFF559C99).withValues(alpha: 0.35),
                        width: isSelected ? 3 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: onSelect,
                            child: _buildHatTypeCardImage(
                              imageUrl: imageUrl,
                              imagePath: shape.imagePath,
                              compact: true,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: onSelect,
                          child: _buildWizardCardTitleSection(
                            shape.name,
                            padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                          ),
                        ),
                        _buildShapeFourUpFlipFooter(
                          shape: shape,
                          onFlip: onFlip,
                        ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildWizardShapeGrid({
    required List<HatShapeInfo> shapes,
    required Map<String, List<Map<String, String>>> productsMap,
    required HatShapeInfo? selectedShape,
    required void Function(HatShapeInfo shape, int index) onSelect,
    required bool isCrown,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _webWizardGridColumns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.60,
      ),
      itemCount: shapes.length,
      itemBuilder: (context, index) {
        final shape = shapes[index];
        final shopifyProducts = productsMap[shape.name] ?? [];
        final photo = _pickShapeCardPhoto(
          shapeName: shape.name,
          shopifyProducts: shopifyProducts,
          shapeCarouselIndex: index,
          isCrown: isCrown,
        );
        final isFlipped = isCrown
            ? _flippedCardIndex == index
            : _flippedBrimCardIndex == index;
        return _buildWebWizardShapeCard(
          context: context,
          shape: shape,
          imageUrl: photo.imageUrl,
          isSelected: selectedShape?.name == shape.name,
          isFlipped: isFlipped,
          onSelect: () => onSelect(shape, index),
          onFlip: () {
            setState(() {
              if (isCrown) {
                _flippedCardIndex = index;
              } else {
                _flippedBrimCardIndex = index;
              }
            });
          },
          onUnflip: () {
            setState(() {
              if (isCrown) {
                _flippedCardIndex = null;
              } else {
                _flippedBrimCardIndex = null;
              }
            });
          },
        );
      },
    );
  }

  Widget _buildWizardShapeRowPager({
    required List<HatShapeInfo> shapes,
    required Map<String, List<Map<String, String>>> productsMap,
    required HatShapeInfo? selectedShape,
    required void Function(HatShapeInfo shape, int index) onSelect,
    required bool isCrown,
  }) {
    return _buildWizardRowPager(
      itemCount: shapes.length,
      itemBuilder: (context, index) {
        final shape = shapes[index];
        final shopifyProducts = productsMap[shape.name] ?? [];
        final photo = _pickShapeCardPhoto(
          shapeName: shape.name,
          shopifyProducts: shopifyProducts,
          shapeCarouselIndex: index,
          isCrown: isCrown,
        );
        final isFlipped = isCrown
            ? _flippedCardIndex == index
            : _flippedBrimCardIndex == index;
        return _buildWebWizardShapeCard(
          context: context,
          shape: shape,
          imageUrl: photo.imageUrl,
          isSelected: selectedShape?.name == shape.name,
          isFlipped: isFlipped,
          onSelect: () => onSelect(shape, index),
          onFlip: () {
            setState(() {
              if (isCrown) {
                _flippedCardIndex = index;
              } else {
                _flippedBrimCardIndex = index;
              }
            });
          },
          onUnflip: () {
            setState(() {
              if (isCrown) {
                _flippedCardIndex = null;
              } else {
                _flippedBrimCardIndex = null;
              }
            });
          },
        );
      },
    );
  }

  Widget _buildVisualCrownSelection() {
    return FutureBuilder<List<dynamic>>(
      future: _allProductsFuture,
      builder: (context, snapshot) {
        final catalogLoading = _allProducts == null &&
            snapshot.connectionState == ConnectionState.waiting;

        final sortedShapes =
            _sortedCrownShapes ?? List<HatShapeInfo>.from(_currentCrownShapes);
        final shopifyProductsMap = _crownProductsMap;

        return Column(
          children: [
            if (catalogLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF559C99),
              ),
            _buildWizardStepTitle('Select Crown Shape:'),
            _buildCrownGuideLink(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_isWebWizardFourUp(constraints.maxWidth)) {
                    return _buildWizardShapeGrid(
                      shapes: sortedShapes,
                      productsMap: shopifyProductsMap,
                      selectedShape: selectedCrownShape,
                      onSelect: _selectCrownAndAdvance,
                      isCrown: true,
                    );
                  }
                  return Column(
                    children: [
                      _buildWizardCarouselArea(
              controller: _crownCarouselController,
              currentIndex: _currentCrownCarouselIndex,
              itemCount: sortedShapes.length,
              pageView: PageView.builder(
                    controller: _crownCarouselController,
                    clipBehavior: Clip.hardEdge,
                    onPageChanged: (index) {
                      setState(() {
                        _currentCrownCarouselIndex = index;
                        _flippedCardIndex = null;
                        final sorted =
                            _sortedCrownShapes ?? _currentCrownShapes;
                        if (index < sorted.length) {
                          selectedCrownShape = sorted[index];
                          _onCrownSelectionChanged();
                        }
                      });
                    },
                    itemCount: sortedShapes.length,
                    itemBuilder: (context, index) {
                      final shape = sortedShapes[index];
                      final isSelected = selectedCrownShape != null
                          ? selectedCrownShape!.name == shape.name
                          : index == _currentCrownCarouselIndex;
                      final shopifyProducts =
                          shopifyProductsMap[shape.name] ?? [];
                      final photo = _pickShapeCardPhoto(
                        shapeName: shape.name,
                        shopifyProducts: shopifyProducts,
                        shapeCarouselIndex: index,
                        isCrown: true,
                      );
                      final imageUrl = photo.imageUrl;
                      final bool isFlipped = _flippedCardIndex == index;

                      return Padding(
                        padding: _shapeCardPagePadding,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (isFlipped) {
                              setState(() {
                                _flippedCardIndex = null;
                              });
                              return;
                            }
                            _selectCrownAndAdvance(shape, index);
                          },
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                                begin: 0, end: isFlipped ? pi : 0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                            builder: (context, angle, _) {
                              // Determine which face to show
                              final showBack = angle > pi / 2;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001) // perspective
                                  ..rotateY(angle),
                                child: showBack
                                    // ── BACK FACE (history) ──
                                    ? Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateY(pi), // un-mirror text
                                        child: Card(
                                          clipBehavior: Clip.antiAlias,
                                          elevation: 0,
                                          color: const Color(0xFF2D2926),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            side: BorderSide(
                                              color: isSelected
                                                  ? const Color(0xFF559C99)
                                                  : const Color(0xFF3D3936),
                                              width: isSelected ? 3 : 1,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                20, 16, 20, 12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                _buildShapeCardBackTitle(shape.name),
                                                const SizedBox(height: 6),
                                                Container(
                                                  width: 40,
                                                  height: 2,
                                                  color:
                                                      const Color(0xFF559C99),
                                                ),
                                                const SizedBox(height: 14),
                                                Text(
                                                  'THE HISTORY',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xFF559C99),
                                                    letterSpacing: 3.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    child: Text(
                                                      shape.history.isNotEmpty
                                                          ? shape.history
                                                          : shape.description,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: GoogleFonts
                                                          .playfairDisplay(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.9),
                                                        height: 1.6,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                // ── Two info buttons ──
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          OutlinedButton.icon(
                                                        onPressed: () =>
                                                            _showShapeDetailSheet(
                                                                context,
                                                                shape,
                                                                'wearers'),
                                                        icon: const Icon(
                                                            Icons
                                                                .people_outline,
                                                            size: 18),
                                                        label: Text(
                                                          'FAMOUS\nWEARERS',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            letterSpacing: 1.5,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                        style: OutlinedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.white70,
                                                          side:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .white24),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 14),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10)),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child:
                                                          OutlinedButton.icon(
                                                        onPressed: () =>
                                                            _showShapeDetailSheet(
                                                                context,
                                                                shape,
                                                                'physical'),
                                                        icon: const Icon(
                                                            Icons.straighten,
                                                            size: 18),
                                                        label: Text(
                                                          'THE\nSHAPE',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            letterSpacing: 1.5,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                        style: OutlinedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.white70,
                                                          side:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .white24),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 14),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10)),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                TextButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      _flippedCardIndex = null;
                                                    });
                                                  },
                                                  child: Text(
                                                    'TAP TO FLIP BACK',
                                                    style:
                                                        GoogleFonts.montserrat(
                                                      fontSize: 8,
                                                      color: Colors.white30,
                                                      letterSpacing: 2.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    // ── FRONT FACE (image) ──
                                    : _buildShapeCardFrontFace(
                                        context: context,
                                        shape: shape,
                                        imageUrl: imageUrl,
                                        featuredProductTitle: photo.productTitle,
                                        isSelected: isSelected,
                                        onFlip: () {
                                          setState(() {
                                            _flippedCardIndex = index;
                                          });
                                        },
                                      ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
            ),
            _buildWizardCarouselFooter(
              itemCount: sortedShapes.length,
              currentIndex: _currentCrownCarouselIndex,
              nextLabel: _currentCrownCarouselIndex + 1 < sortedShapes.length
                  ? sortedShapes[_currentCrownCarouselIndex + 1].name
                  : '',
              maxDots: 8,
            ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVisualBrimSelection() {
    return FutureBuilder<List<dynamic>>(
      future: _allProductsFuture,
      builder: (context, snapshot) {
        final catalogLoading = _allProducts == null;

        final sortedShapes = _availableBrimShapes;
        final shopifyProductsMap = _brimProductsMap;

        if (selectedCrownShape != null && catalogLoading) {
          return Column(
            children: [
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF559C99),
              ),
              _buildWizardStepTitle('Select Brim Shape:'),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Loading hat catalog…',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        if (sortedShapes.isEmpty) {
          return Column(
            children: [
              _buildWizardStepTitle('Select Brim Shape:'),
              _buildWizardEmptyState(
                message: selectedCrownShape == null
                    ? 'Select a crown shape first.'
                    : 'No brim shapes in stock for\n${selectedCrownShape!.name}\nwith your current selections.',
                showFindHats: selectedCrownShape != null,
              ),
            ],
          );
        }

        return Column(
          children: [
            if (catalogLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF559C99),
              ),
            _buildWizardStepTitle('Select Brim Shape:'),
            _buildBrimGuideLink(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_isWebWizardFourUp(constraints.maxWidth)) {
                    return _buildWizardShapeRowPager(
                      shapes: sortedShapes,
                      productsMap: shopifyProductsMap,
                      selectedShape: selectedBrimShape,
                      onSelect: _selectBrimAndAdvance,
                      isCrown: false,
                    );
                  }
                  return Column(
                    children: [
                      _buildWizardCarouselArea(
              controller: _brimCarouselController,
              currentIndex: _currentBrimCarouselIndex,
              itemCount: sortedShapes.length,
              pageView: PageView.builder(
                    controller: _brimCarouselController,
                    clipBehavior: Clip.hardEdge,
                    onPageChanged: (index) {
                      setState(() {
                        _currentBrimCarouselIndex = index;
                        _flippedBrimCardIndex = null;
                        if (index < sortedShapes.length) {
                          selectedBrimShape = sortedShapes[index];
                        }
                      });
                    },
                    itemCount: sortedShapes.length,
                    itemBuilder: (context, index) {
                      final shape = sortedShapes[index];
                      final isSelected = selectedBrimShape != null
                          ? selectedBrimShape!.name == shape.name
                          : index == _currentBrimCarouselIndex;
                      final shopifyProducts =
                          shopifyProductsMap[shape.name] ?? [];
                      final photo = _pickShapeCardPhoto(
                        shapeName: shape.name,
                        shopifyProducts: shopifyProducts,
                        shapeCarouselIndex: index,
                        isCrown: false,
                      );
                      final imageUrl = photo.imageUrl;
                      final bool isFlipped = _flippedBrimCardIndex == index;

                      return Padding(
                        padding: _shapeCardPagePadding,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (isFlipped) {
                              setState(() {
                                _flippedBrimCardIndex = null;
                              });
                              return;
                            }
                            _selectBrimAndAdvance(shape, index);
                          },
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                                begin: 0, end: isFlipped ? pi : 0),
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                            builder: (context, angle, _) {
                              final showBack = angle > pi / 2;
                              return Transform(
                                alignment: Alignment.center,
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001)
                                  ..rotateY(angle),
                                child: showBack
                                    // ── BACK FACE (history) ──
                                    ? Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..rotateY(pi),
                                        child: Card(
                                          clipBehavior: Clip.antiAlias,
                                          elevation: 0,
                                          color: const Color(0xFF2D2926),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            side: BorderSide(
                                              color: isSelected
                                                  ? const Color(0xFF559C99)
                                                  : const Color(0xFF3D3936),
                                              width: isSelected ? 3 : 1,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                20, 16, 20, 12),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                _buildShapeCardBackTitle(shape.name),
                                                const SizedBox(height: 6),
                                                Container(
                                                  width: 40,
                                                  height: 2,
                                                  color:
                                                      const Color(0xFF559C99),
                                                ),
                                                const SizedBox(height: 14),
                                                Text(
                                                  'THE HISTORY',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color:
                                                        const Color(0xFF559C99),
                                                    letterSpacing: 3.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Expanded(
                                                  child: SingleChildScrollView(
                                                    child: Text(
                                                      shape.history.isNotEmpty
                                                          ? shape.history
                                                          : shape.description,
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: GoogleFonts
                                                          .playfairDisplay(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.9),
                                                        height: 1.6,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                // ── Two info buttons ──
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child:
                                                          OutlinedButton.icon(
                                                        onPressed: () =>
                                                            _showShapeDetailSheet(
                                                                context,
                                                                shape,
                                                                'wearers'),
                                                        icon: const Icon(
                                                            Icons
                                                                .people_outline,
                                                            size: 18),
                                                        label: Text(
                                                          'FAMOUS\nWEARERS',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            letterSpacing: 1.5,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                        style: OutlinedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.white70,
                                                          side:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .white24),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 14),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10)),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child:
                                                          OutlinedButton.icon(
                                                        onPressed: () =>
                                                            _showShapeDetailSheet(
                                                                context,
                                                                shape,
                                                                'physical'),
                                                        icon: const Icon(
                                                            Icons.straighten,
                                                            size: 18),
                                                        label: Text(
                                                          'THE\nSHAPE',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: GoogleFonts
                                                              .montserrat(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                            letterSpacing: 1.5,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                        style: OutlinedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.white70,
                                                          side:
                                                              const BorderSide(
                                                                  color: Colors
                                                                      .white24),
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  vertical: 14),
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10)),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'TAP TO FLIP BACK',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 8,
                                                    color: Colors.white30,
                                                    letterSpacing: 2.0,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      )
                                    // ── FRONT FACE (image) ──
                                    : _buildShapeCardFrontFace(
                                        context: context,
                                        shape: shape,
                                        imageUrl: imageUrl,
                                        featuredProductTitle: photo.productTitle,
                                        isSelected: isSelected,
                                        onFlip: () {
                                          setState(() {
                                            _flippedBrimCardIndex = index;
                                          });
                                        },
                                      ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
            ),
            _buildWizardCarouselFooter(
              itemCount: sortedShapes.length,
              currentIndex: _currentBrimCarouselIndex,
              nextLabel: _currentBrimCarouselIndex + 1 < sortedShapes.length
                  ? sortedShapes[_currentBrimCarouselIndex + 1].name
                  : '',
            ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Laptop/desktop wizard picker: one row per page (max 4 cards), side arrows,
/// and a peek of the next page when there are more than four options.
class _WizardRowPager extends StatefulWidget {
  const _WizardRowPager({
    required this.itemCount,
    required this.maxBlockWidth,
    required this.cardHeight,
    required this.itemBuilder,
  });

  static const int cardsPerPage = 4;
  static const double spacing = 12.0;
  static const double peekViewportFraction = 0.9;

  final int itemCount;
  final double maxBlockWidth;
  final double cardHeight;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  State<_WizardRowPager> createState() => _WizardRowPagerState();
}

class _WizardRowPagerState extends State<_WizardRowPager> {
  static const _navGutter = 44.0;

  late final PageController _pageController;
  int _pageIndex = 0;

  int get _pageCount =>
      (widget.itemCount + _WizardRowPager.cardsPerPage - 1) ~/
      _WizardRowPager.cardsPerPage;

  bool get _multiPage => _pageCount > 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      viewportFraction:
          _multiPage ? _WizardRowPager.peekViewportFraction : 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  double _cardWidthForPage(int countOnPage, double contentWidth) {
    if (countOnPage <= 0 || contentWidth <= 0) return 0;
    if (_multiPage) {
      return (contentWidth -
              _WizardRowPager.spacing * (_WizardRowPager.cardsPerPage - 1)) /
          _WizardRowPager.cardsPerPage;
    }
    return (contentWidth -
            _WizardRowPager.spacing * (countOnPage - 1)) /
        countOnPage;
  }

  Widget _buildPage(int pageIndex, double contentWidth) {
    final start = pageIndex * _WizardRowPager.cardsPerPage;
    final end = min(
      start + _WizardRowPager.cardsPerPage,
      widget.itemCount,
    );
    final countOnPage = end - start;
    final cardWidth = _cardWidthForPage(countOnPage, contentWidth);

    return SizedBox(
      width: contentWidth,
      height: widget.cardHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = start; i < end; i++) ...[
            if (i > start) const SizedBox(width: _WizardRowPager.spacing),
            SizedBox(
              width: cardWidth,
              child: widget.itemBuilder(context, i),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPageArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        if (!_multiPage) {
          return _buildPage(0, viewportWidth);
        }
        // PageView gives each page only `viewportFraction` of the viewport
        // (the remainder is the peek). Size content to that slot so the row
        // of cards fits exactly instead of overflowing the page.
        final pageExtent =
            viewportWidth * _WizardRowPager.peekViewportFraction;
        return PageView.builder(
          controller: _pageController,
          clipBehavior: Clip.hardEdge,
          onPageChanged: (index) => setState(() => _pageIndex = index),
          itemCount: _pageCount,
          itemBuilder: (context, page) => Align(
            alignment: Alignment.center,
            child: _buildPage(page, pageExtent),
          ),
        );
      },
    );
  }

  Widget _navButton({
    required bool visible,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    if (!visible) return const SizedBox.shrink();
    return SizedBox(
      width: _navGutter,
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 18, color: Colors.grey.shade700),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.maxBlockWidth,
      height: widget.cardHeight,
      child: ClipRect(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _navButton(
              visible: _multiPage && _pageIndex > 0,
              icon: Icons.chevron_left_rounded,
              onTap: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              ),
            ),
            Expanded(child: _buildPageArea()),
            _navButton(
              visible: _multiPage && _pageIndex < _pageCount - 1,
              icon: Icons.chevron_right_rounded,
              onTap: () => _pageController.nextPage(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
