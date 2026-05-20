import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/hat.dart';
import 'hat_results_screen.dart';
import 'dart:convert';
import 'dart:math' show pi, Random;
import '../services/shopify_service.dart';

class HatInputScreen extends StatefulWidget {
  const HatInputScreen({super.key});

  @override
  State<HatInputScreen> createState() => _HatInputScreenState();
}

class _HatInputScreenState extends State<HatInputScreen> {
  final PageController _pageController = PageController();
  final PageController _crownCarouselController = PageController(viewportFraction: 0.76);
  final PageController _brimCarouselController = PageController(viewportFraction: 0.76);
  int _currentPageIndex = 0;
  int _currentCrownCarouselIndex = 0;
  int _currentBrimCarouselIndex = 0;
  int? _flippedCardIndex; // which crown card is showing history
  int? _flippedBrimCardIndex; // which brim card is showing history
  List<HatShapeInfo>? _sortedCrownShapes;
  List<HatShapeInfo>? _sortedBrimShapes;
  bool _isLoadingChoices = true;
  List<HatShapeInfo> _rawCrownShapes = [];
  List<HatShapeInfo> _rawBrimShapes = [];
  List<HatShapeInfo> _materialTypes = [];
  Map<String, String> _materialExampleUrls = {};
  final Random _random = Random();

  HatShapeInfo? selectedHatType;
  String? selectedWesternStyle;

  HatShapeInfo? selectedCrownShape;
  List<double> targetCrownHeights = [];

  HatShapeInfo? selectedBrimShape;
  List<String> targetBrimWidths = [];

  late Future<List<dynamic>> _allProductsFuture;
  List<dynamic>? _allProducts;
  Map<String, List<Map<String, String>>> _crownProductsMap = {};
  Map<String, List<Map<String, String>>> _brimProductsMap = {};

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

  bool _matchShape(String prod, String ui) {
    final pNorm = prod.toLowerCase().replaceAll('-', ' ').replaceAll("'s", '').replaceAll("'", '').trim();
    final uNorm = ui.toLowerCase().replaceAll('-', ' ').replaceAll("'s", '').replaceAll("'", '').trim();
    if (pNorm.isEmpty || uNorm.isEmpty) return false;
    
    final pClean = pNorm.replaceAll(' shape', '').replaceAll(' crease', '').replaceAll(' crown', '').replaceAll(' brim', '').replaceAll(' curl', '').trim();
    final uClean = uNorm.replaceAll(' shape', '').replaceAll(' crease', '').replaceAll(' crown', '').replaceAll(' brim', '').replaceAll(' curl', '').trim();
    
    return pClean == uClean || pClean.contains(uClean) || uClean.contains(pClean);
  }

  /// Returns the correct crown shape list based on the selected hat type.
  List<HatShapeInfo> get _currentCrownShapes {
    if (_isLoadingChoices || _rawCrownShapes.isEmpty) {
      final typeName = selectedHatType?.name;
      if (typeName == 'Felt' || typeName == 'Straw') return crownShapes;
      final seen = <String>{};
      return [...crownShapes]
          .where((s) => seen.add(s.name))
          .toList();
    }

    final typeName = selectedHatType?.name;
    if (typeName == 'Felt') {
      return _rawCrownShapes;
    }
    if (typeName == 'Straw') {
      // Map crown shapes to straw assets where appropriate
      return _rawCrownShapes.map((shape) {
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
    
    return _rawCrownShapes;
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
          'Hats in this material category.',
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
          return sName == normalized || sName.contains(normalized) || normalized.contains(sName);
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
              history: 'This shape is customized for your individual look and feel. Each hat is meticulously shaped to the customer\'s exact preferences.',
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
          return sName == normalized || sName.contains(normalized) || normalized.contains(sName);
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
              history: 'A customized brim roll and curve shaped exactly to your preference.',
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

  Map<String, String> _computeMaterialExampleImages() {
    if (_allProducts == null) return {};

    final usedUrls = <String>{};
    final urls = <String, String>{};

    for (final type in _availableHatTypes) {
      final matching = ShopifyService.filterProducts(
        _allProducts!,
        hatType: type.name,
      ).where((p) {
        final url = p['featuredImage']?['url'];
        return url != null && url.toString().isNotEmpty;
      }).toList();

      matching.shuffle(_random);
      for (final product in matching) {
        final url = product['featuredImage']['url'] as String;
        if (!usedUrls.contains(url)) {
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
      _refreshShapeProductMaps();
      _materialExampleUrls = _computeMaterialExampleImages();
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
    _syncBrimSelectionToAvailable();
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
  List<HatShapeInfo> get _availableBrimShapes {
    final all = _allBrimShapeOptions;
    if (selectedCrownShape == null || _allProducts == null) return all;
    return all
        .where((brim) => _productCountForCrownAndBrim(brim) > 0)
        .toList();
  }

  int _productCountForCrownAndBrim(HatShapeInfo brim) {
    if (_allProducts == null || selectedCrownShape == null) return 0;
    var products = ShopifyService.filterProducts(
      _allProducts!,
      hatType: selectedHatType?.name,
      westernStyle: selectedWesternStyle,
      crownShape: selectedCrownShape!.name,
      brimShape: brim.name,
    );
    if (selectedCrownShape!.name.toLowerCase().contains('cattleman')) {
      products = products.where((p) {
        final title = (p['title'] ?? '').toString().toLowerCase();
        final handle = (p['handle'] ?? '').toString().toLowerCase();
        return !(title.contains('open road') || handle.contains('open-road'));
      }).toList();
    }
    return products.length;
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
      _syncBrimSelectionToAvailable();
    });
    _nextPage();
  }

  void _selectBrimAndAdvance(HatShapeInfo shape, int index) {
    setState(() {
      selectedBrimShape = shape;
      _currentBrimCarouselIndex = index;
      _flippedBrimCardIndex = null;
    });
    _nextPage();
  }

  Map<String, List<Map<String, String>>> _buildShapeProductMap(
    List<HatShapeInfo> shapes, {
    required bool isCrown,
  }) {
    final map = <String, List<Map<String, String>>>{};
    for (final shape in shapes) {
      var matchedProducts = _allProducts!
          .where((p) {
            final meta = _metaValue(isCrown ? p['crownShape'] : p['brimShape']);
            final isMatch = _matchShape(meta, shape.name);
            if (isMatch && isCrown && shape.name.toLowerCase().contains('cattleman')) {
              final title = (p['title'] ?? '').toString().toLowerCase();
              final handle = (p['handle'] ?? '').toString().toLowerCase();
              final isOpenRoad =
                  title.contains('open road') || handle.contains('open-road');
              return !isOpenRoad;
            }
            return isMatch;
          })
          .where((p) => p['featuredImage']?['url'] != null)
          .toList();

      if (selectedHatType != null) {
        final target = selectedHatType!.name.toLowerCase();
        matchedProducts.sort((a, b) {
          final aType = _metaValue(a['feltStrawOrBallcap']).toLowerCase();
          final bType = _metaValue(b['feltStrawOrBallcap']).toLowerCase();
          final aMatches = aType.contains(target) ? 1 : 0;
          final bMatches = bType.contains(target) ? 1 : 0;
          return bMatches.compareTo(aMatches);
        });
      }

      map[shape.name] = matchedProducts
          .map((p) => {
                'url': p['featuredImage']['url'] as String,
                'title': (p['title'] ?? '') as String,
                'matchesMaterial': (selectedHatType != null &&
                        _metaValue(p['feltStrawOrBallcap'])
                            .toLowerCase()
                            .contains(selectedHatType!.name.toLowerCase()))
                    ? 'true'
                    : 'false',
              })
          .toList();
    }
    return map;
  }

  Map<String, String>? _getFallbackProduct(List<dynamic> products, HatShapeInfo shape, {required bool isCrown}) {
    if (products.isEmpty) return null;
    
    // 1. Try keyword matching
    try {
      final chosenName = shape.name.toLowerCase();
      String? keyword;
      if (isCrown) {
        if (chosenName.contains('cattleman')) keyword = 'cattleman';
        else if (chosenName.contains('gus')) keyword = 'gus';
        else if (chosenName.contains('teardrop')) keyword = 'teardrop';
        else if (chosenName.contains('brick')) keyword = 'brick';
        else if (chosenName.contains('gambler')) keyword = 'gambler';
        else if (chosenName.contains('punch')) keyword = 'punch';
      } else {
        if (chosenName.contains('curved') || chosenName.contains('curve')) keyword = 'curved';
        else if (chosenName.contains('flat')) keyword = 'flat';
        else if (chosenName.contains('curl')) keyword = 'curl';
        else if (chosenName.contains('downturned') || chosenName.contains('pulled')) keyword = 'downturned';
      }

      if (keyword != null) {
        final matched = products.firstWhere(
          (p) {
            final val = _metaValue(isCrown ? p['crownShape'] : p['brimShape']).toLowerCase();
            final isMatch = val.contains(keyword!) && p['featuredImage']?['url'] != null;
            if (isMatch && isCrown && keyword == 'cattleman') {
              final title = (p['title'] ?? '').toString().toLowerCase();
              final handle = (p['handle'] ?? '').toString().toLowerCase();
              final isOpenRoad = title.contains('open road') || handle.contains('open-road');
              return !isOpenRoad;
            }
            return isMatch;
          }
        );
        return {
          'url': matched['featuredImage']['url'] as String,
          'title': matched['title'] as String,
        };
      }
    } catch (_) {}

    // 2. Try material-matched fallback (Disabled to prevent unrelated matches like Flat Cap showing Stetson Kings Row)
    return null;
  }

  Future<void> _loadDynamicChoices() async {
    try {
      final choices =
          await ShopifyService.fetchValidationChoices(forceRefresh: true);
      final List<String> crownStrings = choices['crown_shapes'] ?? [];
      final List<String> brimStrings = choices['brim_shapes'] ?? [];
      final List<String> materialStrings = choices['material_types'] ?? [];

      setState(() {
        _materialTypes = materialStrings.map(_mapStringToHatType).toList();
        _rawCrownShapes = crownStrings.map((name) {
          return _mapStringToShapeInfo(name, isCrown: true);
        }).toList();

        _rawBrimShapes = brimStrings.map((name) {
          return _mapStringToShapeInfo(name, isCrown: false);
        }).toList();

        _isLoadingChoices = false;
        _refreshShapeProductMaps();
        _materialExampleUrls = _computeMaterialExampleImages();
      });
    } catch (e) {
      print('Error loading dynamic validation choices: $e');
      setState(() {
        _materialTypes = [];
        _rawCrownShapes = List<HatShapeInfo>.from(crownShapes);
        _rawBrimShapes = List.from(brimShapes);
        _isLoadingChoices = false;
        _refreshShapeProductMaps();
        _materialExampleUrls = _computeMaterialExampleImages();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _allProductsFuture = ShopifyService.fetchLiteProducts().then((products) {
      _onProductsLoaded(products);
      return products;
    });
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
      _buildDetailsSelection(),
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
            _syncBrimSelectionToAvailable();
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

  void _submitSearch() {
    final preloaded = _allProducts == null
        ? null
        : ShopifyService.filterProducts(
            _allProducts!,
            hatType: selectedHatType?.name,
            westernStyle: selectedWesternStyle,
            crownShape: selectedCrownShape?.name,
            crownHeights:
                targetCrownHeights.isNotEmpty ? targetCrownHeights : null,
            brimShape: selectedBrimShape?.name,
            brimWidths: targetBrimWidths.isNotEmpty ? targetBrimWidths : null,
          );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HatResultsScreen(
          hatType: selectedHatType?.name,
          westernStyle: selectedWesternStyle,
          crownShape: selectedCrownShape?.name,
          crownHeights: targetCrownHeights.isNotEmpty ? targetCrownHeights : null,
          brimShape: selectedBrimShape?.name,
          brimWidths: targetBrimWidths.isNotEmpty ? targetBrimWidths : null,
          preloadedHats: preloaded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              const SizedBox(height: 2),
              Text(
                'FINE TUNING',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  color: const Color(0xFF2D2926),
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w600,
                ),
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
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swipe to force using buttons
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
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: (_currentPageIndex + 1) / _pages.length.toDouble(),
      backgroundColor: Colors.grey[200],
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF559C99)), // Turquoise accent
    );
  }

  String get _navButtonText {
    if (_currentPageIndex >= _pages.length - 1) return 'Find Hats';
    bool hasWestern = _needsWesternStyleStep(selectedHatType?.name);
    if (_currentPageIndex == 0) return hasWestern ? 'Next: Style' : 'Next: Crown Shape';
    int westernIndex = hasWestern ? 1 : -1;
    int crownIndex = hasWestern ? 2 : 1;
    if (_currentPageIndex == westernIndex) return 'Next: Crown Shape';
    if (_currentPageIndex == crownIndex) return 'Next: Brim Shape';
    return 'Next: Details';
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                onPressed: _currentPageIndex > 0 ? _previousPage : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D2926),
                  side: const BorderSide(color: Color(0xFF2D2926), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
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
               onPressed: _currentPageIndex < _pages.length - 1 ? _nextPage : _submitSearch,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: const Color(0xFF2D2926),
                   foregroundColor: Colors.white,
                   padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Text(
                'Select a Material:',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2926),
                ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: Text(
                  'ANY MATERIAL',
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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF559C99)),
                );
              }

              return GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                                    alignment: const Alignment(0.0, -0.35),
                                    errorBuilder: (context, error, stackTrace) =>
                                        Image.asset(
                                      typeInfo.imagePath,
                                      fit: BoxFit.cover,
                                      alignment: const Alignment(0.0, -0.35),
                                    ),
                                  )
                                : (typeInfo.imagePath !=
                                        'assets/images/placeholder.png'
                                    ? Image.asset(
                                        typeInfo.imagePath,
                                        fit: BoxFit.cover,
                                        alignment: const Alignment(0.0, -0.35),
                                      )
                                    : Container(
                                        color: Colors.grey[50],
                                        child: const Icon(Icons.category,
                                            size: 48, color: Colors.grey),
                                      )),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Text(
                'Select Style:',
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D2926),
                ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
                {'name': 'Western', 'title': 'Western', 'desc': 'Classic cowboy styles.', 'fallback': 'assets/images/western.jpg'},
                {'name': 'City', 'title': 'City', 'desc': 'Fedoras and dress hats.', 'fallback': 'assets/images/city.png'},
                {'name': 'Outdoor', 'title': 'Outdoor/Sportsman', 'desc': 'Sun and adventure hats.', 'fallback': 'assets/images/outdoor.png'},
              ];

              return GridView.builder(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 40.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: styles.length,
                itemBuilder: (context, index) {
                  final style = styles[index];
                  final name = style['name'] as String;
                  final isSelected = selectedWesternStyle == name;
                  
                  String? imageUrl;
                  if (snapshot.hasData) {
                    try {
                      final List<dynamic> products = List.from(snapshot.data!);
                      if (selectedHatType != null) {
                        final target = selectedHatType!.name.toLowerCase();
                        products.sort((a, b) {
                          final aType = _metaValue(a['feltStrawOrBallcap']).toLowerCase();
                          final bType = _metaValue(b['feltStrawOrBallcap']).toLowerCase();
                          final aMatches = aType.contains(target) ? 1 : 0;
                          final bMatches = bType.contains(target) ? 1 : 0;
                          return bMatches.compareTo(aMatches);
                        });
                      }
                      final Set<String> usedUrls = {};
                      
                      // Pre-process to find unique images for each style in the list
                      for (int i = 0; i < styles.length; i++) {
                        final styleName = styles[i]['name'];
                        String? foundUrl;
                        
                        if (styleName == 'Western') {
                          final westernProfiles = ['01', '1', '2', '11', '18', '33', '45', '48', '50', '72', '75', '77', '91', '94', '9G'];
                          foundUrl = products.firstWhere((p) {
                            final profile = _metaValue(p['stetsonProfile']);
                            final title = (p['title'] ?? '').toString().toLowerCase();
                            final handle = (p['handle'] ?? '').toString().toLowerCase();
                            final url = p['featuredImage']?['url'] as String?;
                            
                            // EXCLUDE OPEN ROADS from Western representative image
                            final isOpenRoad = title.contains('open road') || handle.contains('open-road');
                            
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
                            return _metaValue(p['outdoors']).toLowerCase() == 'true' && 
                                   url != null && 
                                   !usedUrls.contains(url);
                          }, orElse: () => null)?['featuredImage']?['url'];
                        }
                        
                        if (foundUrl != null) {
                          usedUrls.add(foundUrl);
                          if (i == index) imageUrl = foundUrl;
                        }
                      }
                    } catch (_) {}
                  }

                  return Card(
                    elevation: 0,
                    clipBehavior: Clip.antiAlias,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF559C99) : Colors.grey.shade200,
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
                                    alignment: const Alignment(0.0, -0.35), // Keep hat crown beautifully in center allocation
                                  )
                                : (style['fallback'] != null
                                    ? Image.asset(
                                        style['fallback'] as String,
                                        fit: BoxFit.cover,
                                        alignment: const Alignment(0.0, -0.35), // Keep hat crown beautifully in center allocation
                                      )
                                    : Container(
                                        color: Colors.grey[50],
                                        child: const Icon(Icons.style, size: 48, color: Colors.grey),
                                      )),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
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
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStyleCard(String name, String description, {String? fallbackImagePath, String? imageUrl, IconData? icon}) {
    final isSelected = selectedWesternStyle == name;
    return Card(
      elevation: isSelected ? 0 : 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8), // Soft rounded
        side: BorderSide(
          color: isSelected ? const Color(0xFF559C99) : Colors.grey.shade300, // Turquoise selection
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(2),
        onTap: () {
          _onWesternStyleSelected(name);
          _nextPage();
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Full-bleed Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2)),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        errorBuilder: (_, __, ___) => _buildFallbackImage(fallbackImagePath, icon),
                      )
                    : _buildFallbackImage(fallbackImagePath, icon),
              ),
            ),
            // Text at the bottom
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                name.toUpperCase(),
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: const Color(0xFF2D2926),
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackImage(String? fallbackImagePath, IconData? icon) {
    return fallbackImagePath != null
        ? Image.asset(
            fallbackImagePath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.white,
              child: const Icon(Icons.category, size: 48, color: Colors.grey),
            ),
          )
        : Container(
            color: Colors.white,
            child: Icon(icon ?? Icons.category, size: 48, color: Colors.grey),
          );
  }

  void _showShapeDetailSheet(BuildContext context, HatShapeInfo shape, String type) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
                        Container(width: 40, height: 2, color: const Color(0xFF559C99)),
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
                        : _buildPhysicalDescriptionContent(shape, scrollController),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFamousWearersContent(HatShapeInfo shape, ScrollController controller) {
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
      separatorBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
                    color: const Color(0xFF559C99).withOpacity(0.15),
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

  Widget _buildPhysicalDescriptionContent(HatShapeInfo shape, ScrollController controller) {
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
              color: const Color(0xFF559C99).withOpacity(0.15),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.straighten, color: Color(0xFF559C99), size: 28),
          ),
          const SizedBox(height: 20),
          Text(
            shape.physicalDescription.isNotEmpty
                ? shape.physicalDescription
                : shape.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 17,
              color: Colors.white.withOpacity(0.85),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF559C99)),
          );
        }

        final sortedShapes = _sortedCrownShapes ?? List<HatShapeInfo>.from(_currentCrownShapes);
        final shopifyProductsMap = _crownProductsMap;

        return Column(
          children: [
            // Header — minimal to maximize card space
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                'Select Crown Shape:',
                style: GoogleFonts.playfairDisplay(fontSize: 22, color: const Color(0xFF2D2926)),
              ),
            ),
            // Carousel — image fills the card edge-to-edge, with swipe hint arrows
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                controller: _crownCarouselController,
                onPageChanged: (index) {
                  setState(() {
                    _currentCrownCarouselIndex = index;
                    _flippedCardIndex = null;
                    final sorted = _sortedCrownShapes ?? _currentCrownShapes;
                    if (index < sorted.length) {
                      selectedCrownShape = sorted[index];
                      _syncBrimSelectionToAvailable();
                    }
                  });
                },
                itemCount: sortedShapes.length,
                itemBuilder: (context, index) {
                  final shape = sortedShapes[index];
                  final isSelected = selectedCrownShape?.name == shape.name;
                  final shopifyProducts = shopifyProductsMap[shape.name] ?? [];
                  String? imageUrl = shopifyProducts.isNotEmpty ? shopifyProducts.first['url'] : null;
                  String? productTitle = shopifyProducts.isNotEmpty ? shopifyProducts.first['title'] : null;
                  
                  if (imageUrl == null && snapshot.hasData) {
                    final fallback = _getFallbackProduct(snapshot.data!, shape, isCrown: true);
                    if (fallback != null) {
                      imageUrl = fallback['url'];
                      productTitle = '${fallback['title']} (Representative)';
                    }
                  }
                  final bool isFlipped = _flippedCardIndex == index;
                  final bool isCentered = index == _currentCrownCarouselIndex;

                  return Padding(
                    padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 3.0, bottom: 20.0),
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
                        tween: Tween<double>(begin: 0, end: isFlipped ? pi : 0),
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
                                    transform: Matrix4.identity()..rotateY(pi), // un-mirror text
                                    child: Card(
                                      clipBehavior: Clip.antiAlias,
                                      elevation: 0,
                                      color: const Color(0xFF2D2926),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        side: BorderSide(
                                          color: isSelected ? const Color(0xFF559C99) : const Color(0xFF3D3936),
                                          width: isSelected ? 3 : 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
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
                                              color: const Color(0xFF559C99),
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              'THE HISTORY',
                                              style: GoogleFonts.montserrat(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF559C99),
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
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.playfairDisplay(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.white.withOpacity(0.9),
                                                    height: 1.6,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            // ── Two info buttons ──
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => _showShapeDetailSheet(context, shape, 'wearers'),
                                                    icon: const Icon(Icons.people_outline, size: 18),
                                                    label: Text(
                                                      'FAMOUS\nWEARERS',
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.montserrat(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 1.5,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.white70,
                                                      side: const BorderSide(color: Colors.white24),
                                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: OutlinedButton.icon(
                                                    onPressed: () => _showShapeDetailSheet(context, shape, 'physical'),
                                                    icon: const Icon(Icons.straighten, size: 18),
                                                    label: Text(
                                                      'THE\nSHAPE',
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.montserrat(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.w700,
                                                        letterSpacing: 1.5,
                                                        height: 1.3,
                                                      ),
                                                    ),
                                                    style: OutlinedButton.styleFrom(
                                                      foregroundColor: Colors.white70,
                                                      side: const BorderSide(color: Colors.white24),
                                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                                  _selectCrownAndAdvance(shape, index);
                                                },
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
                                                  'SELECT THIS CROWN',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
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
                                                style: GoogleFonts.montserrat(
                                                  fontSize: 8,
                                                  color: Colors.white30,
                                                  letterSpacing: 2.0,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                // ── FRONT FACE (image) ──
                                : Card(
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
                                        // Image — naturally sized to sit at the top
                                        Flexible(
                                          fit: FlexFit.loose,
                                          child: Stack(
                                            children: [
                                              Transform.translate(
                                                offset: const Offset(0, 0),
                                                child: imageUrl != null
                                                    ? Image.network(imageUrl, fit: BoxFit.contain, alignment: Alignment.topCenter)
                                                    : Image.asset(shape.imagePath, fit: BoxFit.contain, alignment: Alignment.topCenter),
                                              ),
                                              if (productTitle != null && productTitle.isNotEmpty)
                                                Positioned(
                                                  top: 10, left: 12, right: 12,
                                                  child: Column(
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
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Text section pulled up tight
                                        Transform.translate(
                                          offset: const Offset(0, -35),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
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
                                                  style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.3),
                                                ),
                                                const SizedBox(height: 12),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton(
                                                    onPressed: () => _selectCrownAndAdvance(shape, index),
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
                                                      'SELECT THIS CROWN',
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
                                                  onPressed: () {
                                                    setState(() {
                                                      _flippedCardIndex = index;
                                                    });
                                                  },
                                                  style: OutlinedButton.styleFrom(
                                                    foregroundColor: const Color(0xFF559C99),
                                                    side: const BorderSide(color: Color(0xFF559C99), width: 1),
                                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                          ),
                                        ),
                                      ],
                                    ),
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
                              color: Colors.white.withOpacity(0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
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
                              color: Colors.white.withOpacity(0.7),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
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
              padding: const EdgeInsets.only(top: 2.0, bottom: 0),
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
              padding: const EdgeInsets.only(top: 6.0, bottom: 10.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    // Left spacer — matches SKIP width for centering
                    const SizedBox(width: 50),
                    // Center: Next Up label + hat name
                    Expanded(
                      child: (_currentCrownCarouselIndex + 1 < sortedShapes.length)
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
                                  sortedShapes[_currentCrownCarouselIndex + 1].name,
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

  Widget _buildDetailsSelection() {
    return FutureBuilder<List<dynamic>>(
      future: _allProductsFuture,
      builder: (context, snapshot) {
        // Dynamically find matching image from Shopify products
        String? crownImageUrl;
        if (snapshot.hasData && selectedCrownShape != null) {
          try {
            final product = snapshot.data!.firstWhere(
              (p) => _matchShape(_metaValue(p['crownShape']), selectedCrownShape!.name) && p['featuredImage']?['url'] != null,
            );
            crownImageUrl = product['featuredImage']['url'];
          } catch (_) {
            final fallback = _getFallbackProduct(snapshot.data!, selectedCrownShape!, isCrown: true);
            if (fallback != null) {
              crownImageUrl = fallback['url'];
            }
          }
        }

        String? brimImageUrl;
        if (snapshot.hasData && selectedBrimShape != null) {
          try {
            final product = snapshot.data!.firstWhere(
              (p) => _matchShape(_metaValue(p['brimShape']), selectedBrimShape!.name) && p['featuredImage']?['url'] != null,
            );
            brimImageUrl = product['featuredImage']['url'];
          } catch (_) {
            final fallback = _getFallbackProduct(snapshot.data!, selectedBrimShape!, isCrown: false);
            if (fallback != null) {
              brimImageUrl = fallback['url'];
            }
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Crown', Icons.architecture),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: selectedCrownShape != null 
                      ? (crownImageUrl != null 
                          ? Image.network(crownImageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)))
                          : Image.asset(selectedCrownShape!.imagePath, fit: BoxFit.cover))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Crown Shape:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      DropdownButton<HatShapeInfo?>(
                        value: _currentCrownShapes.contains(selectedCrownShape) ? selectedCrownShape : null,
                        isExpanded: false,
                        isDense: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                        hint: const Text('Any', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        selectedItemBuilder: (BuildContext context) {
                          return <HatShapeInfo?>[null, ..._currentCrownShapes].map<Widget>((HatShapeInfo? item) {
                            return Text(
                              item?.name ?? 'Any',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            );
                          }).toList();
                        },
                        items: [
                          const DropdownMenuItem<HatShapeInfo?>(
                            value: null,
                            child: Text('Any', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ..._currentCrownShapes.map((shape) {
                            return DropdownMenuItem<HatShapeInfo?>(
                              value: shape,
                              child: Text(shape.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedCrownShape = val;
                            _syncBrimSelectionToAvailable();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildMeasurementDropdown(
            label: 'Crown Height',
            selectedItems: targetCrownHeights,
            min: 4.25,
            max: 5.0,
            onChanged: (val) => setState(() => targetCrownHeights = val),
          ),
          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 24),
          _buildSectionHeader('Brim', Icons.waves),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: selectedBrimShape != null 
                      ? (brimImageUrl != null 
                          ? Image.network(brimImageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey)))
                          : Image.asset(selectedBrimShape!.imagePath, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[200], child: const Icon(Icons.image, color: Colors.grey))))
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Brim Shape:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      DropdownButton<HatShapeInfo?>(
                        value: _availableBrimShapes.contains(selectedBrimShape) ? selectedBrimShape : null,
                        isExpanded: false,
                        isDense: true,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                        hint: const Text('Any', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        selectedItemBuilder: (BuildContext context) {
                          return <HatShapeInfo?>[null, ..._availableBrimShapes].map<Widget>((HatShapeInfo? item) {
                            return Text(
                              item?.name ?? 'Any',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            );
                          }).toList();
                        },
                        items: [
                          const DropdownMenuItem<HatShapeInfo?>(
                            value: null,
                            child: Text('Any', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          ..._availableBrimShapes.map((shape) {
                            return DropdownMenuItem<HatShapeInfo?>(
                              value: shape,
                              child: Text(shape.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setState(() => selectedBrimShape = val);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildDropdown(
            label: 'Brim Width',
            selectedItems: targetBrimWidths,
            items: brimWidths,
            onChanged: (val) => setState(() => targetBrimWidths = val),
          ),
          const SizedBox(height: 50), // Padding to prevent the button from covering the last item
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> selectedItems,
    required List<String> items,
    required ValueChanged<List<String>> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16.0,
          runSpacing: 4.0,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: selectedItems.isEmpty,
                  onChanged: (val) {
                    if (val == true) {
                      onChanged([]);
                    }
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                GestureDetector(
                  onTap: () => onChanged([]),
                  child: const Text('Any', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...items.map((item) {
              final isSelected = selectedItems.contains(item);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      final newItems = List<String>.from(selectedItems);
                      if (val == true) {
                        newItems.add(item);
                      } else {
                        newItems.remove(item);
                      }
                      onChanged(newItems);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  GestureDetector(
                    onTap: () {
                      final newItems = List<String>.from(selectedItems);
                      if (isSelected) {
                        newItems.remove(item);
                      } else {
                        newItems.add(item);
                      }
                      onChanged(newItems);
                    },
                    child: Text(item, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildMeasurementDropdown({
    required String label,
    required List<double> selectedItems,
    required double min,
    required double max,
    required ValueChanged<List<double>> onChanged,
  }) {
    final List<double> increments = [];
    for (double i = min; i <= max + 0.01; i += 0.25) {
      increments.add(i);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16.0,
          runSpacing: 4.0,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: selectedItems.isEmpty,
                  onChanged: (val) {
                    if (val == true) {
                      onChanged([]);
                    }
                  },
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
                GestureDetector(
                  onTap: () => onChanged([]),
                  child: const Text('Any', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            ...increments.map((val) {
              final isSelected = selectedItems.contains(val);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (checked) {
                      final newItems = List<double>.from(selectedItems);
                      if (checked == true) {
                        newItems.add(val);
                      } else {
                        newItems.remove(val);
                      }
                      onChanged(newItems);
                    },
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  GestureDetector(
                    onTap: () {
                      final newItems = List<double>.from(selectedItems);
                      if (isSelected) {
                        newItems.remove(val);
                      } else {
                        newItems.add(val);
                      }
                      onChanged(newItems);
                    },
                    child: Text(formatMeasurement(val), style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  ),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }
  Widget _buildVisualBrimSelection() {
    return FutureBuilder<List<dynamic>>(
      future: _allProductsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF559C99)),
          );
        }

        final sortedShapes = _availableBrimShapes;
        final shopifyProductsMap = _brimProductsMap;

        if (sortedShapes.isEmpty) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
                child: Text(
                  'Select Brim Shape:',
                  style: GoogleFonts.playfairDisplay(fontSize: 22, color: const Color(0xFF2D2926)),
                ),
              ),
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
              child: Text(
                'Select Brim Shape:',
                style: GoogleFonts.playfairDisplay(fontSize: 22, color: const Color(0xFF2D2926)),
              ),
            ),
            // Carousel with swipe arrows
            Expanded(
              child: Stack(
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
                      final shopifyProducts = shopifyProductsMap[shape.name] ?? [];
                      String? imageUrl = shopifyProducts.isNotEmpty ? shopifyProducts.first['url'] : null;
                      String? productTitle = shopifyProducts.isNotEmpty ? shopifyProducts.first['title'] : null;
                      
                      if (imageUrl == null && snapshot.hasData) {
                        final fallback = _getFallbackProduct(snapshot.data!, shape, isCrown: false);
                        if (fallback != null) {
                          imageUrl = fallback['url'];
                          productTitle = '${fallback['title']} (Representative)';
                        }
                      }
                      final bool isFlipped = _flippedBrimCardIndex == index;
                      final bool isCentered = index == _currentBrimCarouselIndex;

                      return Padding(
                        padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 3.0, bottom: 20.0),
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
                                    // ── BACK FACE (history) ──
                                    ? Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()..rotateY(pi),
                                        child: Card(
                                          clipBehavior: Clip.antiAlias,
                                          elevation: 0,
                                          color: const Color(0xFF2D2926),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                            side: BorderSide(
                                              color: isSelected ? const Color(0xFF559C99) : const Color(0xFF3D3936),
                                              width: isSelected ? 3 : 1,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                                  color: const Color(0xFF559C99),
                                                ),
                                                const SizedBox(height: 14),
                                                Text(
                                                  'THE HISTORY',
                                                  style: GoogleFonts.montserrat(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: const Color(0xFF559C99),
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
                                                      textAlign: TextAlign.center,
                                                      style: GoogleFonts.playfairDisplay(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w400,
                                                        color: Colors.white.withOpacity(0.9),
                                                        height: 1.6,
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                // ── Two info buttons ──
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        onPressed: () => _showShapeDetailSheet(context, shape, 'wearers'),
                                                        icon: const Icon(Icons.people_outline, size: 18),
                                                        label: Text(
                                                          'FAMOUS\nWEARERS',
                                                          textAlign: TextAlign.center,
                                                          style: GoogleFonts.montserrat(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700,
                                                            letterSpacing: 1.5,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: Colors.white70,
                                                          side: const BorderSide(color: Colors.white24),
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: OutlinedButton.icon(
                                                        onPressed: () => _showShapeDetailSheet(context, shape, 'physical'),
                                                        icon: const Icon(Icons.straighten, size: 18),
                                                        label: Text(
                                                          'THE\nSHAPE',
                                                          textAlign: TextAlign.center,
                                                          style: GoogleFonts.montserrat(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700,
                                                            letterSpacing: 1.5,
                                                            height: 1.3,
                                                          ),
                                                        ),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor: Colors.white70,
                                                          side: const BorderSide(color: Colors.white24),
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                                                      _selectBrimAndAdvance(shape, index);
                                                    },
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
                                                      'SELECT THIS BRIM',
                                                      style: GoogleFonts.montserrat(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w700,
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
                                    : Card(
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
                                            // Image — naturally sized to sit at the top
                                            Flexible(
                                              fit: FlexFit.loose,
                                              child: Stack(
                                                children: [
                                                  Transform.translate(
                                                    offset: const Offset(0, 0),
                                                    child: imageUrl != null
                                                        ? Image.network(imageUrl, fit: BoxFit.contain, alignment: Alignment.topCenter)
                                                        : Container(
                                                            color: Colors.white,
                                                            child: Image.asset(shape.imagePath, fit: BoxFit.contain, alignment: Alignment.topCenter),
                                                          ),
                                                  ),
                                                  if (productTitle != null && productTitle.isNotEmpty)
                                                    Positioned(
                                                      top: 10, left: 12, right: 12,
                                                      child: Column(
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
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            // Text section pulled up tight
                                            Transform.translate(
                                              offset: const Offset(0, -35),
                                              child: Padding(
                                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
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
                                                      style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.3),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton(
                                                        onPressed: () => _selectBrimAndAdvance(shape, index),
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
                                                          'SELECT THIS BRIM',
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
                                                      onPressed: () {
                                                        setState(() {
                                                          _flippedBrimCardIndex = index;
                                                        });
                                                      },
                                                      style: OutlinedButton.styleFrom(
                                                        foregroundColor: const Color(0xFF559C99),
                                                        side: const BorderSide(color: Color(0xFF559C99), width: 1),
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                                              ),
                                            ),
                                          ],
                                        ),
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
                      left: 2, top: 0, bottom: 20,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _brimCarouselController.previousPage(
                            duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.7),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))],
                            ),
                            child: Icon(Icons.chevron_left_rounded, size: 18, color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                  // Right arrow
                  if (_currentBrimCarouselIndex < sortedShapes.length - 1)
                    Positioned(
                      right: 2, top: 0, bottom: 20,
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _brimCarouselController.nextPage(
                            duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.7),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 1))],
                            ),
                            child: Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Dots
            Padding(
              padding: const EdgeInsets.only(top: 2.0, bottom: 0),
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
                      color: i == _currentBrimCarouselIndex ? const Color(0xFF2D2926) : Colors.grey.shade300,
                    ),
                  ),
                ),
              ),
            ),
            // Next Up + Skip — centered layout
            Padding(
              padding: const EdgeInsets.only(top: 6.0, bottom: 10.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    const SizedBox(width: 50),
                    Expanded(
                      child: (_currentBrimCarouselIndex + 1 < sortedShapes.length)
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'NEXT UP: ',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: Colors.grey[500], letterSpacing: 1.8,
                                  ),
                                ),
                                Text(
                                  sortedShapes[_currentBrimCarouselIndex + 1].name,
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 20, fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2D2926), fontStyle: FontStyle.italic,
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
                          _nextPage(overrideValidation: true);
                        },
                        child: Text(
                          'SKIP',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.montserrat(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: const Color(0xFF559C99), letterSpacing: 1.8,
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
