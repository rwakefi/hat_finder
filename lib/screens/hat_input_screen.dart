import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hat.dart';
import '../models/head_measurement_profile.dart';
import '../models/head_shape_profile.dart';
import 'hat_results_screen.dart';
import 'dart:async';
import 'dart:math' show pi, Random;
import '../services/shopify_service.dart';

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
  final PageController _crownCarouselController =
      PageController(viewportFraction: 0.76);
  final PageController _brimCarouselController =
      PageController(viewportFraction: 0.76);
  int _currentPageIndex = 0;
  int _currentCrownCarouselIndex = 0;
  int _currentBrimCarouselIndex = 0;
  int? _flippedCardIndex; // which crown card is showing history
  int? _flippedBrimCardIndex; // which brim card is showing history
  List<HatShapeInfo>? _sortedCrownShapes;
  List<HatShapeInfo>? _sortedBrimShapes;
  bool _isLoadingChoices = false;
  bool _hasAppliedProfileDefaults = false;
  List<HatShapeInfo> _rawCrownShapes = [];
  List<HatShapeInfo> _rawBrimShapes = [];
  List<HatShapeInfo> _materialTypes = [];
  Map<String, String> _materialExampleUrls = {};
  final Random _random = Random();

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

  bool _isOpenRoadProduct(dynamic product) {
    final title = (product['title'] ?? '').toString().toLowerCase();
    final handle = (product['handle'] ?? '').toString().toLowerCase();
    return title.contains('open road') || handle.contains('open-road');
  }

  bool _isWizardCrownShape(HatShapeInfo shape) =>
      !shape.name.toLowerCase().contains('flat cap');

  List<HatShapeInfo> _wizardCrownShapes(Iterable<HatShapeInfo> shapes) =>
      shapes.where(_isWizardCrownShape).toList();

  /// Returns the correct crown shape list based on the selected hat type.
  List<HatShapeInfo> get _currentCrownShapes {
    if (_isLoadingChoices || _rawCrownShapes.isEmpty) {
      final typeName = selectedHatType?.name;
      if (typeName == 'Felt' || typeName == 'Straw') {
        return _wizardCrownShapes(crownShapes);
      }
      final seen = <String>{};
      return _wizardCrownShapes(
        crownShapes.where((s) => seen.add(s.name)),
      );
    }

    final typeName = selectedHatType?.name;
    if (typeName == 'Felt') {
      return _wizardCrownShapes(_rawCrownShapes);
    }
    if (typeName == 'Straw') {
      // Map crown shapes to straw assets where appropriate
      return _wizardCrownShapes(_rawCrownShapes.map((shape) {
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
      }));
    }

    return _wizardCrownShapes(_rawCrownShapes);
  }

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
            lookup = 'cool hand luke';
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

  Map<String, String> _computeMaterialExampleImages() {
    if (_allProducts == null) return {};

    final usedUrls = <String>{};
    final urls = <String, String>{};
    final pendingTypes = {
      for (final type in _availableHatTypes) type.name: type.name.toLowerCase(),
    };

    final candidates = List<dynamic>.from(_allProducts!)..shuffle(_random);
    for (final product in candidates) {
      if (pendingTypes.isEmpty) break;
      final imageUrl = product['featuredImage']?['url'];
      if (imageUrl == null || imageUrl.toString().isEmpty) continue;
      final url = imageUrl as String;
      if (usedUrls.contains(url)) continue;

      final hatType = _metaValue(product['feltStrawOrBallcap']).toLowerCase();
      for (final entry in pendingTypes.entries.toList()) {
        if (hatType.contains(entry.value)) {
          urls[entry.key] = url;
          usedUrls.add(url);
          pendingTypes.remove(entry.key);
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
      setState(_refreshShapeProductMaps);
    });
  }

  void _refreshShapeProductMaps() {
    if (_allProducts == null) return;

    final crownShapes = List<HatShapeInfo>.from(_currentCrownShapes);
    final brimShapeList = _sortedBrimShapes ??
        (_rawBrimShapes.isNotEmpty ? _rawBrimShapes : brimShapes);

    _crownProductsMap = _buildShapeProductMap(crownShapes, isCrown: true);
    _brimProductsMap = _buildShapeProductMap(brimShapeList, isCrown: false);

    final sortedCrown = List<HatShapeInfo>.from(crownShapes);
    sortedCrown.sort((a, b) {
      final profilePriority = _compareByHeadShapePriority(
        a,
        b,
        isCrown: true,
      );
      if (profilePriority != 0) return profilePriority;
      if (selectedWesternStyle == 'City') {
        final priority = _compareByStylePriority(a.name, b.name, const [
          'pinch front',
        ]);
        if (priority != 0) return priority;
      } else if (selectedWesternStyle == 'Outdoor') {
        final priority = _compareByStylePriority(a.name, b.name, const [
          'pinch front',
          'cattleman',
          'telescope',
        ]);
        if (priority != 0) return priority;
      }
      return _compareShapeProductPriority(
        _crownProductsMap[a.name] ?? [],
        _crownProductsMap[b.name] ?? [],
      );
    });
    _sortedCrownShapes = sortedCrown;

    final sortedBrim = List<HatShapeInfo>.from(brimShapeList);
    sortedBrim.sort((a, b) {
      final profilePriority = _compareByHeadShapePriority(
        a,
        b,
        isCrown: false,
      );
      if (profilePriority != 0) return profilePriority;
      if (selectedWesternStyle == 'Western') {
        final priority = _compareByStylePriority(a.name, b.name, const [
          'medium curved',
          'shovel width',
          'chl',
          'wtp',
        ]);
        if (priority != 0) return priority;
      } else if (selectedWesternStyle == 'City') {
        final priority = _compareByStylePriority(a.name, b.name, const [
          'flat/rd',
          'pulled down',
          'cattleman',
          'flip up',
          'pencil curl',
        ]);
        if (priority != 0) return priority;
      }
      return _compareShapeProductPriority(
        _brimProductsMap[a.name] ?? [],
        _brimProductsMap[b.name] ?? [],
      );
    });
    _sortedBrimShapes = sortedBrim;
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
    if (selectedCrownShape!.name.toLowerCase().contains('cattleman')) {
      products =
          products.where((p) => !_isOpenRoadProduct(p)).toList(growable: false);
    }
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

  int _compareByHeadShapePriority(
    HatShapeInfo a,
    HatShapeInfo b, {
    required bool isCrown,
  }) {
    final profile = widget.headShapeProfile;
    if (profile == null) return 0;

    final priorities =
        isCrown ? profile.crownPriorities : profile.brimPriorities;
    return _compareByStylePriority(a.name, b.name, priorities);
  }

  int _compareByStylePriority(
    String aName,
    String bName,
    List<String> priorities,
  ) {
    final aLower = aName.toLowerCase();
    final bLower = bName.toLowerCase();
    final aPriorityIndex = priorities.indexWhere(
      (p) => aLower.contains(p) || p.contains(aLower),
    );
    final bPriorityIndex = priorities.indexWhere(
      (p) => bLower.contains(p) || p.contains(bLower),
    );
    if (aPriorityIndex != -1 && bPriorityIndex != -1) {
      return aPriorityIndex.compareTo(bPriorityIndex);
    } else if (aPriorityIndex != -1) {
      return -1;
    } else if (bPriorityIndex != -1) {
      return 1;
    }
    return 0;
  }

  int _compareShapeProductPriority(
    List<Map<String, String>> aProds,
    List<Map<String, String>> bProds,
  ) {
    final aHasTypeMatch =
        aProds.any((p) => p['matchesMaterial'] == 'true') ? 1 : 0;
    final bHasTypeMatch =
        bProds.any((p) => p['matchesMaterial'] == 'true') ? 1 : 0;
    if (aHasTypeMatch != bHasTypeMatch) {
      return bHasTypeMatch.compareTo(aHasTypeMatch);
    }
    final aHasAny = aProds.isNotEmpty ? 1 : 0;
    final bHasAny = bProds.isNotEmpty ? 1 : 0;
    return bHasAny.compareTo(aHasAny);
  }

  List<HatShapeInfo> get _allBrimShapeOptions =>
      _sortedBrimShapes ??
      (_rawBrimShapes.isNotEmpty ? _rawBrimShapes : brimShapes);

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
    final materialTarget = selectedHatType?.name.toLowerCase();

    for (final product in _allProducts!) {
      if (product['featuredImage']?['url'] == null) continue;
      final meta =
          _metaValue(isCrown ? product['crownShape'] : product['brimShape']);

      for (final shape in shapes) {
        if (!_matchShape(meta, shape.name)) continue;
        if (isCrown &&
            shape.name.toLowerCase().contains('cattleman') &&
            _isOpenRoadProduct(product)) {
          continue;
        }
        final url = product['featuredImage']['url'] as String;
        if (map[shape.name]!.any((entry) => entry['url'] == url)) continue;
        map[shape.name]!.add({
          'url': url,
          'title': (product['title'] ?? '') as String,
          'matchesMaterial': (materialTarget != null &&
                  _metaValue(product['feltStrawOrBallcap'])
                      .toLowerCase()
                      .contains(materialTarget))
              ? 'true'
              : 'false',
        });
      }
    }

    if (materialTarget != null) {
      for (final entries in map.values) {
        entries.sort((a, b) {
          final aMatches = a['matchesMaterial'] == 'true' ? 1 : 0;
          final bMatches = b['matchesMaterial'] == 'true' ? 1 : 0;
          return bMatches.compareTo(aMatches);
        });
      }
    }
    return map;
  }

  /// Generic hat product photo (background removed) when Shopify has no match.
  static const _hatPhotoPlaceholderAsset = 'assets/images/placeholder.png';

  /// Only uses catalog products already matched to this shape (see [_buildShapeProductMap]).
  /// Otherwise shows the generic cutout placeholder — never a random unrelated hat.
  _ShapeCardPhoto _pickShapeCardPhoto({
    required String shapeName,
    required List<Map<String, String>> shopifyProducts,
    required int shapeCarouselIndex,
  }) {
    if (shopifyProducts.isEmpty) {
      return const _ShapeCardPhoto();
    }

    final pickIndex = (shapeName.hashCode.abs() + shapeCarouselIndex) %
        shopifyProducts.length;
    final pick = shopifyProducts[pickIndex];
    final url = pick['url'];
    if (url == null || url.isEmpty) {
      return const _ShapeCardPhoto();
    }

    return _ShapeCardPhoto(
      imageUrl: url,
      productTitle: pick['title'],
    );
  }

  Widget _buildShapeCardHatImage(String? imageUrl) {
    const padding = EdgeInsets.fromLTRB(12, 6, 12, 0);
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Padding(
        padding: padding,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          errorBuilder: (_, __, ___) => Padding(
            padding: padding,
            child: _buildHatPhotoPlaceholder(),
          ),
        ),
      );
    }
    return Padding(
      padding: padding,
      child: _buildHatPhotoPlaceholder(),
    );
  }

  Widget _buildHatPhotoPlaceholder() {
    return Image.asset(
      _hatPhotoPlaceholderAsset,
      fit: BoxFit.contain,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) => Icon(
        Icons.checkroom_outlined,
        size: 88,
        color: Colors.grey.shade400,
      ),
    );
  }

  static const _wizardStepTitlePadding = EdgeInsets.fromLTRB(16, 8, 16, 4);
  static const _shapeCardPagePadding =
      EdgeInsets.only(left: 4, right: 4, top: 0, bottom: 0);

  /// Pro Max class (~932pt logical height). Adjustments below this threshold
  /// are left alone so iPhone 17 / Air layouts stay unchanged.
  bool _isProMaxLayout(BuildContext context) =>
      MediaQuery.sizeOf(context).height >= 920;

  double _shapeCarouselCardHeight(
    BuildContext context, {
    required double maxExpandedHeight,
  }) {
    final screenH = MediaQuery.sizeOf(context).height;
    final hasFitBanner = widget.headShapeProfile != null ||
        widget.headMeasurementProfile != null;

    double preferred;
    if (screenH >= 920) {
      // Pro Max only — trim when fit banners eat vertical space.
      preferred = hasFitBanner ? 465 : 490;
    } else if (screenH >= 780) {
      preferred = 460;
    } else {
      preferred = (screenH * 0.52).clamp(360.0, 480.0);
    }

    return preferred.clamp(360.0, maxExpandedHeight);
  }

  Widget _buildShapeCarouselArea({required Widget stack}) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (!_isProMaxLayout(context)) {
            return stack;
          }

          final cardHeight = _shapeCarouselCardHeight(
            context,
            maxExpandedHeight: constraints.maxHeight,
          );
          return Column(
            children: [
              if (cardHeight < constraints.maxHeight) const Spacer(),
              SizedBox(
                height: cardHeight,
                child: stack,
              ),
            ],
          );
        },
      ),
    );
  }

  TextStyle get _wizardStepTitleStyle => GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: const Color(0xFF2D2926),
      );

  Widget _buildWizardStepTitle(String title) {
    return Padding(
      padding: _wizardStepTitlePadding,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: _wizardStepTitleStyle,
      ),
    );
  }

  Widget _buildExampleProductOverlay(String productTitle) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Example:',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          productTitle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B6058),
            fontStyle: FontStyle.italic,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildShapeCardFrontFooter({
    required HatShapeInfo shape,
    required VoidCallback onSelect,
    required VoidCallback onFlip,
    required String selectLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Column(
        children: [
          Text(
            shape.name.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF2D2926),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            shape.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF559C99),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                selectLabel,
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onFlip,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF559C99),
              side: const BorderSide(color: Color(0xFF559C99), width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(
              'FLIP FOR MORE INFO',
              style: GoogleFonts.montserrat(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShapeCardFrontFace({
    required HatShapeInfo shape,
    required String? imageUrl,
    required String? productTitle,
    required bool isSelected,
    required VoidCallback onSelect,
    required VoidCallback onFlip,
    required String selectLabel,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected ? const Color(0xFF559C99) : Colors.grey.shade200,
          width: isSelected ? 3 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Flexible(
            fit: FlexFit.loose,
            child: Stack(
              children: [
                _buildShapeCardHatImage(imageUrl),
                if (productTitle != null && productTitle.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 12,
                    right: 12,
                    child: _buildExampleProductOverlay(productTitle),
                  ),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -35),
            child: _buildShapeCardFrontFooter(
              shape: shape,
              onSelect: onSelect,
              onFlip: onFlip,
              selectLabel: selectLabel,
            ),
          ),
        ],
      ),
    );
  }

  void _applyFallbackChoices() {
    _materialTypes = List<HatShapeInfo>.from(hatTypes);
    _rawCrownShapes = List<HatShapeInfo>.from(crownShapes);
    _rawBrimShapes = List.from(brimShapes);
    _isLoadingChoices = false;
    if (_allProducts != null) {
      _materialExampleUrls = _computeMaterialExampleImages();
    }
  }

  Future<void> _loadDynamicChoices() async {
    final cached = ShopifyService.peekValidationChoices();
    if (cached != null) {
      _applyChoicesFromApi(cached);
      return;
    }

    try {
      final choices = await ShopifyService.fetchValidationChoices();
      _applyChoicesFromApi(choices);
    } catch (e) {
      debugPrint('Error loading dynamic validation choices: $e');
      if (mounted) {
        setState(_applyFallbackChoices);
      }
    }
  }

  void _applyChoicesFromApi(Map<String, List<String>> choices) {
    final crownStrings = choices['crown_shapes'] ?? [];
    final brimStrings = choices['brim_shapes'] ?? [];
    final materialStrings = choices['material_types'] ?? [];

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
      _isLoadingChoices = false;
      if (_allProducts != null) {
        _materialExampleUrls = _computeMaterialExampleImages();
      }
    });
    if (_allProducts != null) {
      Future.microtask(() {
        if (!mounted) return;
        setState(_refreshShapeProductMaps);
      });
    }
  }

  void _startCatalogLoad() {
    final cached = ShopifyService.peekLiteProducts();
    if (cached != null) {
      _allProducts = cached;
      _allProductsFuture = Future.value(cached);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _onProductsLoaded(cached);
      });
      return;
    }

    _allProductsFuture = ShopifyService.fetchLiteProducts().then((products) {
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
      int crownIndex = hasWestern ? 2 : 1;
      int brimIndex = hasWestern ? 3 : 2;

      if (_currentPageIndex == westernIndex && selectedWesternStyle == null) {
        setState(() {
          selectedWesternStyle = 'Western';
        });
      }
      if (_currentPageIndex == crownIndex && selectedCrownShape == null) {
        setState(() {
          final sorted = _sortedCrownShapes ?? _currentCrownShapes;
          if (sorted.isNotEmpty) {
            if (_currentCrownCarouselIndex < sorted.length) {
              selectedCrownShape = sorted[_currentCrownCarouselIndex];
            } else {
              selectedCrownShape = sorted.first;
            }
            _onCrownSelectionChanged();
          }
        });
      }
      if (_currentPageIndex == brimIndex && selectedBrimShape == null) {
        setState(() {
          final sorted = _availableBrimShapes;
          if (sorted.isNotEmpty) {
            if (_currentBrimCarouselIndex < sorted.length) {
              selectedBrimShape = sorted[_currentBrimCarouselIndex];
            } else {
              selectedBrimShape = sorted.first;
            }
          }
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowRoutePop,
      onPopInvokedWithResult: (didPop, _) => _handleSystemBack(didPop),
      child: Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/Moon Ridge Header Logo.png',
              height: 55.0,
            ),
          ],
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: null,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white, // Clean, airy background
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressBar(),
              if (widget.headShapeProfile != null)
                _buildHeadShapeProfileBanner(widget.headShapeProfile!),
              if (widget.headMeasurementProfile != null)
                _buildHeadMeasurementBanner(widget.headMeasurementProfile!),
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
                        _materialExampleUrls = _computeMaterialExampleImages();
                      }
                    });
                  },
                  children: _pages,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildHeadShapeProfileBanner(HeadShapeProfile profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
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
                  maxLines: 3,
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
    return LinearProgressIndicator(
      value: (_currentPageIndex + 1) / _pages.length.toDouble(),
      backgroundColor: Colors.grey[200],
      valueColor: const AlwaysStoppedAnimation<Color>(
          Color(0xFF559C99)), // Turquoise accent
    );
  }

  String get _navButtonText {
    if (_currentPageIndex >= _pages.length - 1) return 'Find Hats';
    bool hasWestern = _needsWesternStyleStep(selectedHatType?.name);
    if (_currentPageIndex == 0) {
      return hasWestern ? 'Next: Style' : 'Next: Crown Shape';
    }
    int westernIndex = hasWestern ? 1 : -1;
    int crownIndex = hasWestern ? 2 : 1;
    if (_currentPageIndex == westernIndex) return 'Next: Crown Shape';
    if (_currentPageIndex == crownIndex) return 'Next: Brim Shape';
    return 'Find Hats';
  }

  Widget _buildBottomNav() {
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: _currentPageIndex > 0
                    ? _previousPage
                    : _exitWizard,
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _navButtonText.toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _currentPageIndex < _pages.length - 1
                          ? Icons.arrow_forward
                          : Icons.check,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualHatTypeSelection() {
    return Column(
      children: [
        Padding(
          padding: _wizardStepTitlePadding,
          child: Column(
            children: [
              Text(
                'Select a Hat Type:',
                textAlign: TextAlign.center,
                style: _wizardStepTitleStyle,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
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
            ],
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
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: _availableHatTypes.map((typeInfo) {
                        final isSelected = selectedHatType == typeInfo;
                        final imageUrl = _materialExampleUrls[typeInfo.name];

                        return Card(
                          elevation: 0,
                          clipBehavior: Clip.antiAlias,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF559C99)
                                  : Colors.grey.shade200,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () {
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
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: imageUrl != null
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          alignment:
                                              const Alignment(0.0, -0.35),
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Image.asset(
                                            typeInfo.imagePath,
                                            fit: BoxFit.cover,
                                            alignment:
                                                const Alignment(0.0, -0.35),
                                          ),
                                        )
                                      : (typeInfo.imagePath !=
                                              'assets/images/placeholder.png'
                                          ? Image.asset(
                                              typeInfo.imagePath,
                                              fit: BoxFit.cover,
                                              alignment:
                                                  const Alignment(0.0, -0.35),
                                            )
                                          : Container(
                                              color: Colors.grey[50],
                                              child: const Icon(Icons.category,
                                                  size: 48, color: Colors.grey),
                                            )),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16.0),
                                  color: Colors.white,
                                  child: Text(
                                    typeInfo.name.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.montserrat(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF2D2926),
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
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

  Widget _buildVisualWesternSelection() {
    return Column(
      children: [
        Padding(
          padding: _wizardStepTitlePadding,
          child: Column(
            children: [
              Text(
                'Select Style:',
                textAlign: TextAlign.center,
                style: _wizardStepTitleStyle,
              ),
              const SizedBox(height: 8),
              OutlinedButton(
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
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _allProductsFuture,
            builder: (context, snapshot) {
              final styles = [
                {
                  'name': 'Western',
                  'title': 'Western',
                  'desc': 'Classic cowboy styles.',
                  'fallback': 'assets/images/western.jpg'
                },
                {
                  'name': 'City',
                  'title': 'City',
                  'desc': 'Fedoras and dress hats.',
                  'fallback': 'assets/images/city.png'
                },
                {
                  'name': 'Outdoor',
                  'title': 'Outdoor/Sportsman',
                  'desc': 'Sun and adventure hats.',
                  'fallback': 'assets/images/outdoor.png'
                },
              ];

              final imageUrls = <String, String?>{};
              if (snapshot.hasData) {
                try {
                  final List<dynamic> products = List.from(snapshot.data!);
                  if (selectedHatType != null) {
                    final target = selectedHatType!.name.toLowerCase();
                    products.sort((a, b) {
                      final aType =
                          _metaValue(a['feltStrawOrBallcap']).toLowerCase();
                      final bType =
                          _metaValue(b['feltStrawOrBallcap']).toLowerCase();
                      final aMatches = aType.contains(target) ? 1 : 0;
                      final bMatches = bType.contains(target) ? 1 : 0;
                      return bMatches.compareTo(aMatches);
                    });
                  }
                  final Set<String> usedUrls = {};

                  for (int i = 0; i < styles.length; i++) {
                    final styleName = styles[i]['name'] as String;
                    String? foundUrl;

                    if (styleName == 'Western') {
                      final westernProfiles = [
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
                        '9G'
                      ];
                      foundUrl = products.firstWhere((p) {
                        final profile = _metaValue(p['stetsonProfile']);
                        final title =
                            (p['title'] ?? '').toString().toLowerCase();
                        final handle =
                            (p['handle'] ?? '').toString().toLowerCase();
                        final url = p['featuredImage']?['url'] as String?;

                        final isOpenRoad = title.contains('open road') ||
                            handle.contains('open-road');

                        return westernProfiles.contains(profile) &&
                            url != null &&
                            !usedUrls.contains(url) &&
                            !isOpenRoad;
                      }, orElse: () => null)?['featuredImage']?['url'];
                    } else if (styleName == 'City') {
                      foundUrl = products.firstWhere((p) {
                        final url = p['featuredImage']?['url'] as String?;
                        return _metaValue(p['city']).toLowerCase() == 'true' &&
                            url != null &&
                            !usedUrls.contains(url);
                      }, orElse: () => null)?['featuredImage']?['url'];
                    } else if (styleName == 'Outdoor') {
                      foundUrl = products.firstWhere((p) {
                        final url = p['featuredImage']?['url'] as String?;
                        return _metaValue(p['outdoors']).toLowerCase() ==
                                'true' &&
                            url != null &&
                            !usedUrls.contains(url);
                      }, orElse: () => null)?['featuredImage']?['url'];
                    }

                    if (foundUrl != null) {
                      usedUrls.add(foundUrl);
                    }
                    imageUrls[styleName] = foundUrl;
                  }
                } catch (_) {}
              }

              return LayoutBuilder(
                builder: (context, constraints) {
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
                      children: List.generate(styles.length, (index) {
                        final style = styles[index];
                        final name = style['name'] as String;
                        final isSelected = selectedWesternStyle == name;

                        final imageUrl = imageUrls[name];

                        return SizedBox(
                          width: itemWidth,
                          height: itemHeight,
                          child: Card(
                            elevation: 0,
                            clipBehavior: Clip.antiAlias,
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF559C99)
                                    : Colors.grey.shade200,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                            child: InkWell(
                              onTap: () {
                                _onWesternStyleSelected(name);
                                _nextPage();
                              },
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: imageUrl != null
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            alignment: const Alignment(
                                              0.0,
                                              -0.35,
                                            ),
                                          )
                                        : (style['fallback'] != null
                                            ? Image.asset(
                                                style['fallback'] as String,
                                                fit: BoxFit.cover,
                                                alignment: const Alignment(
                                                  0.0,
                                                  -0.35,
                                                ),
                                              )
                                            : Container(
                                                color: Colors.grey[50],
                                                child: const Icon(
                                                  Icons.style,
                                                  size: 48,
                                                  color: Colors.grey,
                                                ),
                                              )),
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
                          ),
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
            // Carousel — image fills the card edge-to-edge, with swipe hint arrows
            _buildShapeCarouselArea(
              stack: Stack(
                children: [
                  PageView.builder(
                    controller: _crownCarouselController,
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
                      final isSelected = selectedCrownShape?.name == shape.name;
                      final shopifyProducts =
                          shopifyProductsMap[shape.name] ?? [];
                      final photo = _pickShapeCardPhoto(
                        shapeName: shape.name,
                        shopifyProducts: shopifyProducts,
                        shapeCarouselIndex: index,
                      );
                      final imageUrl = photo.imageUrl;
                      final productTitle = photo.productTitle;
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
                                                Text(
                                                  shape.name.toUpperCase(),
                                                  textAlign: TextAlign.center,
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
                                                // ── Select button ──
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      _selectCrownAndAdvance(
                                                          shape, index);
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF559C99),
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30),
                                                      ),
                                                      elevation: 0,
                                                    ),
                                                    child: Text(
                                                      'SELECT THIS CROWN',
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
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
                                        shape: shape,
                                        imageUrl: imageUrl,
                                        productTitle: productTitle,
                                        isSelected: isSelected,
                                        onSelect: () => _selectCrownAndAdvance(
                                            shape, index),
                                        onFlip: () {
                                          setState(() {
                                            _flippedCardIndex = index;
                                          });
                                        },
                                        selectLabel: 'SELECT THIS CROWN',
                                      ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  // Left arrow — subtle swipe hint
                  if (_currentCrownCarouselIndex > 0)
                    Positioned(
                      left: 2,
                      top: 0,
                      bottom: 20,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _crownCarouselController.previousPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          },
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
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Right arrow — subtle swipe hint
                  if (_currentCrownCarouselIndex < sortedShapes.length - 1)
                    Positioned(
                      right: 2,
                      top: 0,
                      bottom: 20,
                      child: Center(
                        child: GestureDetector(
                          onTap: () {
                            _crownCarouselController.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut,
                            );
                          },
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
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Dots — hugging the bottom of the card
            Padding(
              padding: EdgeInsets.only(
                top: _isProMaxLayout(context) ? 4.0 : 2.0,
                bottom: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  sortedShapes.length.clamp(0, 8),
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentCrownCarouselIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == _currentCrownCarouselIndex
                          ? const Color(0xFF2D2926)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
            // Next Up + Skip — centered layout
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    // Left spacer — matches SKIP width for centering
                    const SizedBox(width: 50),
                    // Center: Next Up label + hat name
                    Expanded(
                      child: (_currentCrownCarouselIndex + 1 <
                              sortedShapes.length)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'NEXT UP: ',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[500],
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                Text(
                                  sortedShapes[_currentCrownCarouselIndex + 1]
                                      .name,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D2926),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                    // Right: Skip
                    SizedBox(
                      width: 50,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedCrownShape = null);
                          _nextPage(overrideValidation: true);
                        },
                        child: Text(
                          'SKIP',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF559C99),
                            letterSpacing: 1.8,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF559C99),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
        final catalogLoading = _allProducts == null &&
            snapshot.connectionState == ConnectionState.waiting;

        final sortedShapes = _availableBrimShapes;
        final shopifyProductsMap = _brimProductsMap;

        if (sortedShapes.isEmpty) {
          return Column(
            children: [
              _buildWizardStepTitle('Select Brim Shape:'),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      selectedCrownShape == null
                          ? 'Select a crown shape first.'
                          : 'No brim shapes in stock for ${selectedCrownShape!.name} with your current selections.',
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

        return Column(
          children: [
            if (catalogLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF559C99),
              ),
            _buildWizardStepTitle('Select Brim Shape:'),
            // Carousel with swipe arrows
            _buildShapeCarouselArea(
              stack: Stack(
                children: [
                  PageView.builder(
                    controller: _brimCarouselController,
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
                      final isSelected = selectedBrimShape?.name == shape.name;
                      final shopifyProducts =
                          shopifyProductsMap[shape.name] ?? [];
                      final photo = _pickShapeCardPhoto(
                        shapeName: shape.name,
                        shopifyProducts: shopifyProducts,
                        shapeCarouselIndex: index,
                      );
                      final imageUrl = photo.imageUrl;
                      final productTitle = photo.productTitle;
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
                                                Text(
                                                  shape.name.toUpperCase(),
                                                  textAlign: TextAlign.center,
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
                                                // ── Select button ──
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      _selectBrimAndAdvance(
                                                          shape, index);
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                              0xFF559C99),
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 12),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(30),
                                                      ),
                                                      elevation: 0,
                                                    ),
                                                    child: Text(
                                                      'SELECT THIS BRIM',
                                                      style: GoogleFonts
                                                          .montserrat(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
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
                                        shape: shape,
                                        imageUrl: imageUrl,
                                        productTitle: productTitle,
                                        isSelected: isSelected,
                                        onSelect: () =>
                                            _selectBrimAndAdvance(shape, index),
                                        onFlip: () {
                                          setState(() {
                                            _flippedBrimCardIndex = index;
                                          });
                                        },
                                        selectLabel: 'SELECT THIS BRIM',
                                      ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  // Left arrow
                  if (_currentBrimCarouselIndex > 0)
                    Positioned(
                      left: 2,
                      top: 0,
                      bottom: 20,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _brimCarouselController.previousPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut),
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
                                    offset: const Offset(0, 1))
                              ],
                            ),
                            child: Icon(Icons.chevron_left_rounded,
                                size: 18, color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                  // Right arrow
                  if (_currentBrimCarouselIndex < sortedShapes.length - 1)
                    Positioned(
                      right: 2,
                      top: 0,
                      bottom: 20,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _brimCarouselController.nextPage(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeInOut),
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
                                    offset: const Offset(0, 1))
                              ],
                            ),
                            child: Icon(Icons.chevron_right_rounded,
                                size: 18, color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Dots
            Padding(
              padding: EdgeInsets.only(
                top: _isProMaxLayout(context) ? 4.0 : 2.0,
                bottom: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  sortedShapes.length.clamp(0, 9),
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _currentBrimCarouselIndex ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: i == _currentBrimCarouselIndex
                          ? const Color(0xFF2D2926)
                          : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
            // Next Up + Skip — centered layout
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    const SizedBox(width: 50),
                    Expanded(
                      child: (_currentBrimCarouselIndex + 1 <
                              sortedShapes.length)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'NEXT UP: ',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[500],
                                    letterSpacing: 1.8,
                                  ),
                                ),
                                Text(
                                  sortedShapes[_currentBrimCarouselIndex + 1]
                                      .name,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D2926),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            )
                          : const SizedBox(),
                    ),
                    SizedBox(
                      width: 50,
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedBrimShape = null);
                          _submitSearch();
                        },
                        child: Text(
                          'SKIP',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF559C99),
                            letterSpacing: 1.8,
                            decoration: TextDecoration.underline,
                            decorationColor: const Color(0xFF559C99),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
