import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/hat.dart';

/// Parsed Shopify metafields for one product (computed once per catalog load).
class _ProductMeta {
  _ProductMeta(this.product);

  final dynamic product;

  late final String crownShape =
      ShopifyService.parseMetafieldValue(product['crownShape']);
  late final String brimShape =
      ShopifyService.parseMetafieldValue(product['brimShape']);
  late final String crownHeight =
      ShopifyService.parseMetafieldValue(product['crownHeight']);
  late final String brimWidth =
      ShopifyService.parseMetafieldValue(product['brimWidth']);
  late final String hatType =
      ShopifyService.parseMetafieldValue(product['feltStrawOrBallcap']);
  late final String stetsonProfile =
      ShopifyService.parseMetafieldValue(product['stetsonProfile']);
  late final String city = ShopifyService.parseMetafieldValue(product['city']);
  late final String outdoors =
      ShopifyService.parseMetafieldValue(product['outdoors']);
}

class ShopifyService {
  static const Duration _cacheTtl = Duration(minutes: 15);
  static const Duration _requestTimeout = Duration(seconds: 12);

  static final Map<String, _ProductMeta> _parsedMetaById = {};

  static List<dynamic>? _cachedLiteProducts;
  static List<dynamic>? _cachedFullProducts;
  static DateTime? _liteCacheTime;
  static DateTime? _cachedFullTime;
  static Future<List<dynamic>>? _inflightLite;
  static Future<List<dynamic>>? _inflightFull;

  static Map<String, List<String>>? _cachedValidationChoices;
  static DateTime? _validationCacheTime;
  static Future<Map<String, List<String>>>? _inflightValidation;

  /// Parse metafield JSON once (shared by filter + UI).
  static String parseMetafieldValue(dynamic entry) {
    if (entry == null) return '';
    // Handle plain string (direct from Storefront API mapping)
    if (entry is String) return entry;
    // Handle wrapped {value: ...} format
    if (entry is Map && entry['value'] == null) return '';
    if (entry is Map) {
      try {
        final parsed = jsonDecode(entry['value'] as String);
        if (parsed is List && parsed.isNotEmpty) {
          return parsed.first.toString();
        }
        return parsed.toString();
      } catch (_) {
        return entry['value'].toString();
      }
    }
    return '';
  }

  /// Parses Shopify boolean metafields (`true` / `false` strings).
  static bool parseBooleanMetafield(dynamic entry) {
    final raw = parseMetafieldValue(entry).trim().toLowerCase();
    return raw == 'true' || raw == '1';
  }

  /// Whether a Shopify product belongs in Hat Finder (and future catalog UIs).
  ///
  /// Requires `custom.felt_straw_or_ballcap` to match a known hat category
  /// (Felt, Straw, Ballcap, Beanie/Flat Cap). If the product has Size variants,
  /// at least one must be a hat head size (excludes baby apparel like 0-3 Month).
  static bool isHatFinderCatalogProduct(dynamic product) {
    final category = parseMetafieldValue(product['feltStrawOrBallcap']).trim();
    if (category.isEmpty) return false;

    final matchesKnownType = hatTypes.any(
      (t) => _matchesHatType(category, t.name),
    );
    if (!matchesKnownType) return false;

    if (_looksLikeNonHatTitle(product['title'])) return false;

    final variantSizes = _variantOptionValues(product, 'size');
    if (variantSizes.isNotEmpty) {
      // Exclude baby apparel (0-3 Month, etc.) but keep hats with S/M/L or numeric sizes.
      return !variantSizes.every(_isBabyApparelSize);
    }
    return true;
  }

  static bool _isBabyApparelSize(String size) {
    final s = size.trim().toLowerCase();
    return RegExp(
      r'month|months|newborn|toddler|infant|\byear\b|\d+\s*-\s*\d+\s*month',
    ).hasMatch(s);
  }

  /// Hat sizing for the results SIZE chip bar (not catalog eligibility).
  static bool isHatHeadSize(String size) {
    final s = size.trim().toLowerCase();
    if (s.isEmpty) return false;
    if (_isBabyApparelSize(s)) return false;
    if (RegExp(r'^\d').hasMatch(s)) return true;
    if (RegExp(
      r'^(xxs|xs|s|m|l|xl|xxl|2xl|3xl|sm|md|lg|one\s*size|osfa|osfm|o/s|standard|adjustable)$',
    ).hasMatch(s)) {
      return true;
    }
    if (RegExp(
      r'^(x-?small|small|medium|med|large|x-?large|xx-?large|xxx-?large|extra\s*small|extra\s*large)$',
    ).hasMatch(s)) {
      return true;
    }
    return false;
  }

  /// Sort hat sizes for the results chip bar (numeric head sizes, then letter sizes).
  static int compareHatSizes(String a, String b) {
    final order = {
      'xxs': 10,
      'xs': 20,
      'x-small': 25,
      'extra small': 25,
      'small': 30,
      's': 35,
      'sm': 36,
      'medium': 40,
      'med': 41,
      'm': 42,
      'large': 50,
      'l': 51,
      'lg': 52,
      'xl': 60,
      'x-large': 61,
      'extra large': 62,
      'xxl': 70,
      'xx-large': 71,
      '2xl': 72,
      'xxxl': 80,
      '3xl': 81,
      'one size': 90,
      'standard': 91,
      'adjustable': 92,
    };
    final aKey = a.trim().toLowerCase();
    final bKey = b.trim().toLowerCase();
    final aRank = order[aKey];
    final bRank = order[bKey];
    if (aRank != null && bRank != null) return aRank.compareTo(bRank);
    if (aRank != null) return -1;
    if (bRank != null) return 1;

    final aNum = parseInchesFromText(a) ?? double.tryParse(aKey.split(RegExp(r'\s')).first);
    final bNum = parseInchesFromText(b) ?? double.tryParse(bKey.split(RegExp(r'\s')).first);
    if (aNum != null && bNum != null) return aNum.compareTo(bNum);
    if (aNum != null) return -1;
    if (bNum != null) return 1;
    return aKey.compareTo(bKey);
  }

  static bool _looksLikeNonHatTitle(dynamic title) {
    final t = title?.toString().toLowerCase() ?? '';
    if (t.isEmpty) return false;
    return RegExp(
      r'\b(romper|onesie|bodysuit|dress|shirt|jacket|pants|shorts|skirt|blouse)\b',
    ).hasMatch(t);
  }

  static List<String> _variantOptionValues(dynamic product, String optionName) {
    final values = <String>{};
    final optLower = optionName.toLowerCase();
    for (final edge in (product['variants']?['edges'] as List<dynamic>? ?? [])) {
      final node = edge['node'];
      if (node == null) continue;
      for (final opt in (node['selectedOptions'] as List<dynamic>? ?? [])) {
        if (opt['name'].toString().toLowerCase() == optLower) {
          final v = opt['value'].toString().trim();
          if (v.isNotEmpty) values.add(v);
        }
      }
    }
    return values.toList();
  }

  /// Bigalli Hats USA stays in the catalog but trails other suppliers in results.
  static bool isBigalliProduct(dynamic product) {
    final vendor = (product?['vendor'] ?? '').toString().trim().toLowerCase();
    return vendor == 'bigalli hats usa';
  }

  /// Products opted out of wizard, shape-guide, and style example imagery via
  /// `custom.hat_finder_exclude_from_examples` only. Still eligible for results.
  static bool isExcludedFromHatFinderExamples(dynamic product) =>
      parseBooleanMetafield(product['hatFinderExcludeFromExamples']);

  /// Wizard picker cards (hat type, style, crown, brim) never use Bigalli photos.
  static bool isEligibleForPickerExample(dynamic product) {
    if (isExcludedFromHatFinderExamples(product)) return false;
    if (isBigalliProduct(product)) return false;
    return true;
  }

  static List<dynamic> orderBigalliLast(Iterable<dynamic> products) {
    final primary = <dynamic>[];
    final bigalli = <dynamic>[];
    for (final product in products) {
      if (isBigalliProduct(product)) {
        bigalli.add(product);
      } else {
        primary.add(product);
      }
    }
    return [...primary, ...bigalli];
  }

  static List<dynamic> _eligibleCatalogProducts(Iterable<dynamic> products) =>
      orderBigalliLast(products.where(isHatFinderCatalogProduct));

  /// All crown height values on a product metafield (often a JSON list).
  static List<double> parseCrownHeightValues(dynamic entry) {
    return _parseInchesListFromMetafield(entry);
  }

  /// All brim width values on a product metafield (often a JSON list).
  static List<double> parseBrimWidthValues(dynamic entry) {
    return _parseInchesListFromMetafield(entry);
  }

  static List<double> _parseInchesListFromMetafield(dynamic entry) {
    if (entry == null || entry['value'] == null) return [];
    try {
      final parsed = jsonDecode(entry['value'] as String);
      if (parsed is List) {
        return parsed
            .map((e) => parseInchesFromText(e.toString()))
            .whereType<double>()
            .toList();
      }
      final single = parseInchesFromText(parsed.toString());
      return single != null ? [single] : [];
    } catch (_) {
      final single = parseInchesFromText(entry['value'].toString());
      return single != null ? [single] : [];
    }
  }

  static bool _inchesMatchList(List<double> productValues, List<double> selected) {
    if (selected.isEmpty) return true;
    if (productValues.isEmpty) return false;
    return selected.any(
      (target) => productValues.any((v) => (v - target).abs() < 0.01),
    );
  }

  static List<double> uniqueCrownHeights(Iterable<dynamic> products) {
    final heights = <double>{};
    for (final product in products) {
      heights.addAll(parseCrownHeightValues(product['crownHeight']));
    }
    final list = heights.toList()..sort();
    return list;
  }

  static bool _isCacheValid(DateTime? cachedAt) {
    if (cachedAt == null) return false;
    return DateTime.now().difference(cachedAt) < _cacheTtl;
  }

  static String _productCacheKey(dynamic product) =>
      product['id']?.toString() ?? product.hashCode.toString();

  static _ProductMeta _productMeta(dynamic product) =>
      _parsedMetaById.putIfAbsent(
        _productCacheKey(product),
        () => _ProductMeta(product),
      );

  static void _clearParsedMeta() => _parsedMetaById.clear();

  /// Shared shape matching for wizard UI and filtering.
  static bool matchShape(String prod, String ui) => _matchShape(prod, ui);

  /// Curated wizard/guide photos — Shopify product title substring per UI label.
  static const Map<String, String> preferredShapeExampleTitleTerms = {
    'Brick/Rounded Brick/Minnick': 'amberwood',
  };

  static String? preferredExampleTitleTerm(String shapeName) =>
      preferredShapeExampleTitleTerms[shapeName]?.toLowerCase();

  /// Picks a curated example product when configured for [shapeName].
  /// Used after an exact shape match is unavailable; tries shape metafield
  /// match first, then title + material only.
  static Map<String, String>? pickPreferredShapeExample({
    required String shapeName,
    required Iterable<dynamic> products,
    required String shapeMetaKey,
    String? materialContains,
  }) {
    final term = preferredExampleTitleTerm(shapeName);
    if (term == null) return null;

    Map<String, String>? scan({
      required bool requireShapeMatch,
      String? material,
    }) {
      for (final product in products) {
        if (!isEligibleForPickerExample(product)) continue;
        final title = (product['title'] ?? '').toString().toLowerCase();
        if (!title.contains(term)) continue;

        if (material != null) {
          final prodMaterial =
              parseMetafieldValue(product['feltStrawOrBallcap']).toLowerCase();
          if (prodMaterial.isNotEmpty && !prodMaterial.contains(material)) {
            continue;
          }
        }

        if (requireShapeMatch) {
          final meta = parseMetafieldValue(product[shapeMetaKey]);
          if (meta.isEmpty || !matchShape(meta, shapeName)) continue;
        }

        final url = product['featuredImage']?['url'];
        if (url == null || url.toString().isEmpty) continue;
        return {
          'url': url.toString(),
          'title': (product['title'] ?? '').toString(),
        };
      }
      return null;
    }

    if (materialContains != null) {
      return scan(requireShapeMatch: true, material: materialContains) ??
          scan(requireShapeMatch: true, material: null) ??
          scan(requireShapeMatch: false, material: materialContains) ??
          scan(requireShapeMatch: false, material: null);
    }
    return scan(requireShapeMatch: true, material: null) ??
        scan(requireShapeMatch: false, material: null);
  }

  /// Picks a catalog photo for [shapeName], preferring [materialContains] when
  /// set. Falls back to the same crown/brim shape in another hat type (e.g.
  /// straw brick when no felt brick) before the wizard uses a placeholder.
  static Map<String, String>? pickShapeExamplePhoto({
    required Iterable<dynamic> products,
    required String shapeName,
    required String shapeMetaKey,
    int shapeCarouselIndex = 0,
    String? materialContains,
    Set<String> avoidUrls = const {},
  }) {
    Map<String, String>? scan({String? material}) {
      final eligible = <dynamic>[];
      for (final product in products) {
        if (!isEligibleForPickerExample(product)) continue;
        if (!isHatFinderCatalogProduct(product)) continue;
        final url = product['featuredImage']?['url'];
        if (url == null || url.toString().isEmpty) continue;
        if (avoidUrls.contains(url.toString())) continue;

        final meta = parseMetafieldValue(product[shapeMetaKey]);
        if (meta.isEmpty || !matchShape(meta, shapeName)) continue;

        if (material != null) {
          final prodMaterial =
              parseMetafieldValue(product['feltStrawOrBallcap']).toLowerCase();
          if (prodMaterial.isNotEmpty && !prodMaterial.contains(material)) {
            continue;
          }
        }
        eligible.add(product);
      }

      if (eligible.isEmpty) return null;

      final sorted = List<dynamic>.from(eligible)
        ..sort((a, b) => (a['title'] ?? '')
            .toString()
            .toLowerCase()
            .compareTo((b['title'] ?? '').toString().toLowerCase()));

      final list = sorted.toList();
      final pickIndex =
          (shapeName.hashCode.abs() + shapeCarouselIndex) % list.length;
      final product = list[pickIndex];
      final pickedUrl = product['featuredImage']?['url'];
      if (pickedUrl == null || pickedUrl.toString().isEmpty) return null;
      return {
        'url': pickedUrl.toString(),
        'title': (product['title'] ?? '').toString(),
      };
    }

    if (materialContains != null) {
      return scan(material: materialContains) ?? scan(material: null);
    }
    return scan(material: null);
  }

  /// Returns cached full catalog if splash/home preload already finished.
  static List<dynamic>? peekFullProducts() {
    if (_cachedFullProducts != null && _isCacheValid(_cachedFullTime)) {
      return _cachedFullProducts;
    }
    return null;
  }

  /// Returns cached lite catalog if splash/home preload already finished.
  static List<dynamic>? peekLiteProducts() {
    if (_cachedLiteProducts != null && _isCacheValid(_liteCacheTime)) {
      return _cachedLiteProducts;
    }
    return null;
  }

  static Map<String, List<String>>? peekValidationChoices() {
    if (_cachedValidationChoices != null &&
        _isCacheValid(_validationCacheTime)) {
      return _cachedValidationChoices;
    }
    return null;
  }

  /// Lightweight catalog for the input wizard (no per-variant inventory).
  static Future<List<dynamic>> fetchLiteProducts({bool forceRefresh = false}) {
    return _fetchProducts(
      lite: true,
      forceRefresh: forceRefresh,
    );
  }

  /// Full catalog for results (variants + inventory for swatches).
  static Future<List<dynamic>> fetchFullProducts({bool forceRefresh = false}) {
    return _fetchProducts(
      lite: false,
      forceRefresh: forceRefresh,
    );
  }

  static Future<List<dynamic>> _fetchProducts({
    required bool lite,
    bool forceRefresh = false,
  }) async {
    final cached = lite ? _cachedLiteProducts : _cachedFullProducts;
    final cachedAt = lite ? _liteCacheTime : _cachedFullTime;

    if (!forceRefresh && cached != null && _isCacheValid(cachedAt)) {
      return cached;
    }

    final inflight = lite ? _inflightLite : _inflightFull;
    if (inflight != null) return inflight;

    final future = _downloadProducts(lite: lite).then((products) {
      _clearParsedMeta();
      if (lite) {
        _cachedLiteProducts = products;
        _liteCacheTime = DateTime.now();
        _inflightLite = null;
      } else {
        _cachedFullProducts = products;
        _cachedFullTime = DateTime.now();
        _inflightFull = null;
      }
      return products;
    }).catchError((Object e) {
      if (lite) {
        _inflightLite = null;
      } else {
        _inflightFull = null;
      }
      throw e;
    });

    if (lite) {
      _inflightLite = future;
    } else {
      _inflightFull = future;
    }
    return future;
  }

  @visibleForTesting
  static List<dynamic> parseProductNodesForTest(String body) =>
      _parseProductNodes(body);

  static List<dynamic> _parseProductNodes(String body) {
    final data = jsonDecode(body);
    if (data['errors'] != null) {
      throw Exception('GraphQL Error: ${data['errors']}');
    }
    final nodes = (data['data']['products']['edges'] as List<dynamic>)
        .map((p) => p['node'] as Map<String, dynamic>)
        .map((node) {
          final metafields = node['metafields'] as List<dynamic>? ?? [];
          final meta = <String, dynamic>{};
          for (final mf in metafields) {
            if (mf == null) continue;
            final key = mf['key']?.toString() ?? '';
            final value = mf['value'];
            switch (key) {
              case 'felt_straw_or_ballcap': meta['feltStrawOrBallcap'] = {'value': value}; break;
              case 'crown_shape': meta['crownShape'] = {'value': value}; break;
              case 'brim_shape': meta['brimShape'] = {'value': value}; break;
              case 'crown_height': meta['crownHeight'] = {'value': value}; break;
              case 'brim_width': meta['brimWidth'] = {'value': value}; break;
              case 'stetson_profile': meta['stetsonProfile'] = {'value': value}; break;
              case 'city': meta['city'] = {'value': value}; break;
              case 'outdoors': meta['outdoors'] = {'value': value}; break;
              case 'hat_finder_exclude_from_examples':
                meta['hatFinderExcludeFromExamples'] = {'value': value};
                break;
            }
          }
          // Flatten first image for app compatibility (UI reads featuredImage).
          final imagesEdges = (node['images']?['edges'] as List<dynamic>?) ?? [];
          if (imagesEdges.isNotEmpty) {
            final imgNode = imagesEdges.first['node'];
            final imagePayload = <String, dynamic>{
              'url': imgNode?['url'],
              'altText': imgNode?['altText'],
            };
            meta['image'] = imagePayload;
            meta['featuredImage'] = imagePayload;
          }
          return {...node, ...meta};
        }).toList();
    return _eligibleCatalogProducts(nodes);
  }

  static Future<List<dynamic>> _downloadProducts({required bool lite}) async {
    final query = lite ? r"""
    {
      products(first: 250) {
        edges {
          node {
            id
            title
            vendor
            productType
            handle
            onlineStoreUrl
            tags
            priceRange {
              minVariantPrice { amount currencyCode }
            }
            images(first: 1) {
              edges { node { url altText } }
            }
            variants(first: 50) {
              edges {
                node {
                  id
                  title
                  price { amount currencyCode }
                  selectedOptions { name value }
                  availableForSale
                }
              }
            }
          }
        }
      }
    }
    """ : r"""
    {
      products(first: 250) {
        edges {
          node {
            id
            title
            vendor
            productType
            handle
            onlineStoreUrl
            tags
            priceRange {
              minVariantPrice { amount currencyCode }
            }
            images(first: 1) {
              edges { node { url altText } }
            }
            variants(first: 50) {
              edges {
                node {
                  id
                  title
                  price { amount currencyCode }
                  selectedOptions { name value }
                  availableForSale
                }
              }
            }
            metafields(identifiers: [
              {namespace: "custom", key: "felt_straw_or_ballcap"},
              {namespace: "custom", key: "crown_shape"},
              {namespace: "custom", key: "brim_shape"},
              {namespace: "custom", key: "crown_height"},
              {namespace: "custom", key: "brim_width"},
              {namespace: "custom", key: "stetson_profile"},
              {namespace: "custom", key: "city"},
              {namespace: "custom", key: "outdoors"},
              {namespace: "custom", key: "hat_finder_exclude_from_examples"}
            ]) {
              key
              value
            }
          }
        }
      }
    }
    """;

    final response = await http.post(
      Uri.parse(AppConfig.storefrontApiUrl),
      headers: {
        'Content-Type': 'application/json',
        'X-Shopify-Storefront-Access-Token': AppConfig.storefrontApiToken,
      },
      body: jsonEncode({'query': query}),
    ).timeout(_requestTimeout);

    if (response.statusCode != 200) {
      throw Exception('Failed to load products: \${response.statusCode}');
    }

    // Web release builds can fail silently in isolates; parse on main thread.
    if (kIsWeb) {
      return _parseProductNodes(response.body);
    }
    return compute(_parseProductNodes, response.body);
  }

  static Future<List<dynamic>> searchHats({
    String? hatType,
    String? westernStyle,
    String? crownShape,
    List<double>? crownHeights,
    String? brimShape,
    List<String>? brimWidths,
    bool useLiteCatalog = false,
  }) async {
    final allProducts =
        useLiteCatalog ? await fetchLiteProducts() : await fetchFullProducts();
    return filterProducts(
      allProducts,
      hatType: hatType,
      westernStyle: westernStyle,
      crownShape: crownShape,
      crownHeights: crownHeights,
      brimShape: brimShape,
      brimWidths: brimWidths,
    );
  }

  static List<dynamic> filterProducts(
    List<dynamic> allProducts, {
    String? hatType,
    String? westernStyle,
    String? crownShape,
    List<double>? crownHeights,
    String? brimShape,
    List<String>? brimWidths,
  }) {
    final catalog = _eligibleCatalogProducts(allProducts);

    if (hatType == null &&
        westernStyle == null &&
        crownShape == null &&
        brimShape == null &&
        crownHeights == null &&
        brimWidths == null) {
      return catalog;
    }

    final filtered = catalog.where((product) {
      final meta = _productMeta(product);

      if (hatType != null && hatType != 'Any Type') {
        if (!_matchesHatType(meta.hatType, hatType)) {
          return false;
        }
      }

      if (westernStyle != null && westernStyle.isNotEmpty) {
        if (!matchesWesternStyle(
          hatType: meta.hatType,
          city: meta.city,
          outdoors: meta.outdoors,
          westernStyle: westernStyle,
        )) {
          return false;
        }
      }

      if (crownShape == null &&
          brimShape == null &&
          crownHeights == null &&
          brimWidths == null) {
        return true;
      }

      var matches = true;

      if (crownShape != null && crownShape.isNotEmpty) {
        if (!_matchShape(meta.crownShape, crownShape)) matches = false;
      }
      if (brimShape != null && brimShape.isNotEmpty) {
        if (!_matchShape(meta.brimShape, brimShape)) matches = false;
      }
      if (crownHeights != null && crownHeights.isNotEmpty) {
        final productHeights = parseCrownHeightValues(product['crownHeight']);
        if (!_inchesMatchList(productHeights, crownHeights)) {
          matches = false;
        }
      }
      if (brimWidths != null && brimWidths.isNotEmpty) {
        final productWidths = parseBrimWidthValues(product['brimWidth']);
        final selectedWidths = brimWidths
            .map(parseInchesFromText)
            .whereType<double>()
            .toList();
        if (!_inchesMatchList(productWidths, selectedWidths)) {
          matches = false;
        }
      }

      return matches;
    }).toList();
    return orderBigalliLast(filtered);
  }

  static const int closestMatchMinimum = 4;

  /// Western / City / Outdoor classification for felt and straw hats.
  static bool matchesWesternStyle({
    required String hatType,
    required String city,
    required String outdoors,
    required String westernStyle,
  }) {
    final lowerHatType = hatType.toLowerCase();
    final isClassicHat =
        lowerHatType.contains('felt') || lowerHatType.contains('straw');
    if (!isClassicHat) return false;

    final isCity = city.toLowerCase() == 'true';
    final isOutdoor = outdoors.toLowerCase() == 'true';
    return switch (westernStyle) {
      'Western' => !isCity && !isOutdoor,
      'City' => isCity,
      'Outdoor' => isOutdoor,
      _ => false,
    };
  }

  /// Higher scores rank closer to the active wizard / filter selections.
  static int productMatchScore(
    dynamic product, {
    String? hatType,
    String? westernStyle,
    String? crownShape,
    List<double>? crownHeights,
    String? brimShape,
    List<String>? brimWidths,
  }) {
    final meta = _productMeta(product);

    final typeFilter = _isActiveHatTypeFilter(hatType);
    if (typeFilter && !_matchesHatType(meta.hatType, hatType!)) {
      return 0;
    }

    var score = 0;
    if (typeFilter) score += 16;

    if (westernStyle != null && westernStyle.isNotEmpty) {
      if (matchesWesternStyle(
        hatType: meta.hatType,
        city: meta.city,
        outdoors: meta.outdoors,
        westernStyle: westernStyle,
      )) {
        score += 4;
      }
    }

    if (crownShape != null && crownShape.isNotEmpty) {
      if (_matchShape(meta.crownShape, crownShape)) score += 8;
    }
    if (brimShape != null && brimShape.isNotEmpty) {
      if (_matchShape(meta.brimShape, brimShape)) score += 8;
    }
    if (crownHeights != null && crownHeights.isNotEmpty) {
      final productHeights = parseCrownHeightValues(product['crownHeight']);
      if (_inchesMatchList(productHeights, crownHeights)) score += 2;
    }
    if (brimWidths != null && brimWidths.isNotEmpty) {
      final productWidths = parseBrimWidthValues(product['brimWidth']);
      final selectedWidths =
          brimWidths.map(parseInchesFromText).whereType<double>().toList();
      if (_inchesMatchList(productWidths, selectedWidths)) score += 2;
    }

    return score;
  }

  /// When [filterProducts] finds nothing, return up to [minimum] nearest matches.
  static List<dynamic> closestMatchProducts(
    List<dynamic> allProducts, {
    int minimum = closestMatchMinimum,
    String? hatType,
    String? westernStyle,
    String? crownShape,
    List<double>? crownHeights,
    String? brimShape,
    List<String>? brimWidths,
  }) {
    final catalog = _eligibleCatalogProducts(allProducts);
    if (catalog.isEmpty) return [];

    final scored = <MapEntry<dynamic, int>>[];
    for (final product in catalog) {
      final score = productMatchScore(
        product,
        hatType: hatType,
        westernStyle: westernStyle,
        crownShape: crownShape,
        crownHeights: crownHeights,
        brimShape: brimShape,
        brimWidths: brimWidths,
      );
      if (score > 0) scored.add(MapEntry(product, score));
    }

    scored.sort((a, b) {
      final byScore = b.value.compareTo(a.value);
      if (byScore != 0) return byScore;
      final aTitle = (a.key['title'] ?? '').toString().toLowerCase();
      final bTitle = (b.key['title'] ?? '').toString().toLowerCase();
      return aTitle.compareTo(bTitle);
    });

    Iterable<dynamic> picks;
    if (scored.isNotEmpty) {
      picks = scored.map((e) => e.key);
    } else if (_isActiveHatTypeFilter(hatType)) {
      picks = catalog.where((product) {
        final meta = _productMeta(product);
        return _matchesHatType(meta.hatType, hatType!);
      });
    } else {
      picks = catalog;
    }

    final sorted = picks.toList()
      ..sort((a, b) => (a['title'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b['title'] ?? '').toString().toLowerCase()));

    final count = minimum < sorted.length ? minimum : sorted.length;
    return orderBigalliLast(sorted.take(count));
  }

  static bool _isActiveHatTypeFilter(String? hatType) {
    if (hatType == null || hatType.isEmpty) return false;
    final lower = hatType.toLowerCase();
    return lower != 'any' && lower != 'any type';
  }

  /// Public: does a product's `felt_straw_or_ballcap` value match a UI hat type
  /// (handles the Beanie/Flat Cap synonym group).
  static bool matchesHatType(String prodHatType, String hatType) =>
      _matchesHatType(prodHatType, hatType);

  static bool _matchesHatType(String prodHatType, String hatType) {
    final prod = prodHatType.toLowerCase();
    final target = hatType.toLowerCase();
    if (target.contains('beanie') && target.contains('flat')) {
      return prod.contains('beanie') ||
          prod.contains('flat cap') ||
          prod.contains('flatcap');
    }
    return prod.contains(target);
  }

  static bool _matchShape(String prod, String ui) {
    final pNorm = prod
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll("'s", '')
        .replaceAll("'", '')
        .trim();
    final uNorm = ui
        .toLowerCase()
        .replaceAll('-', ' ')
        .replaceAll("'s", '')
        .replaceAll("'", '')
        .trim();
    if (pNorm.isEmpty || uNorm.isEmpty) return false;

    final pClean = pNorm
        .replaceAll(' shape', '')
        .replaceAll(' crease', '')
        .replaceAll(' crown', '')
        .replaceAll(' brim', '')
        .replaceAll(' curl', '')
        .trim();
    final uClean = uNorm
        .replaceAll(' shape', '')
        .replaceAll(' crease', '')
        .replaceAll(' crown', '')
        .replaceAll(' brim', '')
        .replaceAll(' curl', '')
        .trim();

    return pClean == uClean ||
        pClean.contains(uClean) ||
        uClean.contains(pClean);
  }

  static Future<Map<String, List<String>>> fetchValidationChoices({
    bool forceRefresh = false,
  }) async {
    if (forceRefresh) {
      _cachedValidationChoices = null;
      _validationCacheTime = null;
    }

    if (_cachedValidationChoices != null &&
        _isCacheValid(_validationCacheTime)) {
      return _cachedValidationChoices!;
    }

    if (_inflightValidation != null) return _inflightValidation!;

    _inflightValidation =
        _downloadValidationChoices(forceRefresh: forceRefresh).then((choices) {
      _cachedValidationChoices = choices;
      _validationCacheTime = DateTime.now();
      _inflightValidation = null;
      return choices;
    }).catchError((Object e) {
      _inflightValidation = null;
      throw e;
    });

    return _inflightValidation!;
  }

  static Future<Map<String, List<String>>> _downloadValidationChoices({
    bool forceRefresh = false,
  }) async {
    try {
      final adminChoices = await _downloadAdminValidationChoices();
      if (_hasValidationChoices(adminChoices)) {
        return adminChoices;
      }
    } catch (e) {
      debugPrint('Shopify admin validation choices unavailable: $e');
    }
    return _downloadProductValidationChoices(forceRefresh: forceRefresh);
  }

  static Future<Map<String, List<String>>> _downloadAdminValidationChoices() async {
    final uri = Uri.parse('${AppConfig.hatFinderApiBaseUrl}/api/validation_choices');
    final response = await http.get(uri).timeout(_requestTimeout);
    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load validation choices: HTTP ${response.statusCode}',
      );
    }
    return parseValidationChoicesPayload(jsonDecode(response.body));
  }

  @visibleForTesting
  static Map<String, List<String>> parseValidationChoicesPayload(dynamic body) {
    if (body is! Map) {
      throw const FormatException('validation_choices payload must be a map');
    }
    return {
      'crown_shapes': _parseValidationChoiceList(body['crown_shapes']),
      'brim_shapes': _parseValidationChoiceList(body['brim_shapes']),
      'material_types': _parseValidationChoiceList(body['material_types']),
    };
  }

  static List<String> _parseValidationChoiceList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  static bool _hasValidationChoices(Map<String, List<String>> choices) {
    return (choices['crown_shapes']?.isNotEmpty ?? false) ||
        (choices['brim_shapes']?.isNotEmpty ?? false) ||
        (choices['material_types']?.isNotEmpty ?? false);
  }

  static Future<Map<String, List<String>>> _downloadProductValidationChoices({
    bool forceRefresh = false,
  }) async {
    final products = await fetchFullProducts(forceRefresh: forceRefresh);
    final apiCrownValues = <String>{};
    final apiBrimValues = <String>{};
    final materialTypes = <String>{};

    for (final product in products) {
      final crown = parseMetafieldValue(product['crownShape'] ?? '').trim();
      final brim = parseMetafieldValue(product['brimShape'] ?? '').trim();
      final material = parseMetafieldValue(product['feltStrawOrBallcap'] ?? '').trim();
      if (crown.isNotEmpty) apiCrownValues.add(crown);
      if (brim.isNotEmpty) apiBrimValues.add(brim);
      if (material.isNotEmpty) materialTypes.add(material);
    }

    // Material types use a preferred order (Felt, Straw first), not alphabetical
    const materialOrder = ['Felt', 'Straw', 'Ballcap', 'Beanie/Flat Cap'];
    final sortedMaterials = materialTypes.toList()
      ..sort((a, b) {
        final ai = materialOrder.indexOf(a);
        final bi = materialOrder.indexOf(b);
        if (ai == -1 && bi == -1) return a.compareTo(b);
        if (ai == -1) return 1;
        if (bi == -1) return -1;
        return ai.compareTo(bi);
      });

    return {
      'crown_shapes': _orderedValidationChoices(
        apiValues: apiCrownValues,
        canonicalNames: crownShapes.map((shape) => shape.name),
      ),
      'brim_shapes': _orderedValidationChoices(
        apiValues: apiBrimValues,
        canonicalNames: brimShapes.map((shape) => shape.name),
      ),
      'material_types': sortedMaterials,
    };
  }

  /// Keeps Shopify admin order for wizard options; appends unseen API values.
  static List<String> _orderedValidationChoices({
    required Set<String> apiValues,
    required Iterable<String> canonicalNames,
  }) {
    final ordered = <String>[];
    final usedApi = <String>{};

    for (final canonical in canonicalNames) {
      String? match;
      for (final api in apiValues) {
        if (usedApi.contains(api)) continue;
        if (matchShape(api, canonical)) {
          match = api;
          break;
        }
      }
      if (match != null) {
        ordered.add(match);
        usedApi.add(match);
      } else {
        ordered.add(canonical);
      }
    }

    final extras = apiValues.where((api) => !usedApi.contains(api)).toList()
      ..sort();
    ordered.addAll(extras);
    return ordered;
  }

  /// Call during splash so the hat wizard opens with catalog already in memory.
  static void preloadWizardCatalog({bool includeFullCatalog = false}) {
    _preload('validation choices', fetchValidationChoices());
    if (includeFullCatalog) {
      _preload('full catalog', fetchFullProducts());
    } else {
      _preload('lite catalog', fetchLiteProducts());
    }
  }

  static void _preload<T>(String label, Future<T> future) {
    unawaited(
      future.then<void>(
        (_) {},
        onError: (Object error, StackTrace _) {
          debugPrint('Shopify preload failed for $label: $error');
        },
      ),
    );
  }

  /// Clears caches (useful for tests or pull-to-refresh later).
  static void clearCache() {
    _cachedLiteProducts = null;
    _cachedFullProducts = null;
    _liteCacheTime = null;
    _cachedFullTime = null;
    _cachedValidationChoices = null;
    _validationCacheTime = null;
    _inflightLite = null;
    _inflightFull = null;
    _inflightValidation = null;
    _clearParsedMeta();
  }
}
