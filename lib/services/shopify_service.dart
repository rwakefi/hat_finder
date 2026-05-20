import 'dart:convert';
import 'package:http/http.dart' as http;
import 'database_service.dart';

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
  static const Duration _cacheTtl = Duration(minutes: 5);

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
    if (entry == null || entry['value'] == null) return '';
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

  static Future<List<dynamic>> _downloadProducts({required bool lite}) async {
    final uri = Uri.parse(
      '${DatabaseService.baseUrl}/api/shopify_products?lite=${lite ? 'true' : 'false'}',
    );
    final response = await http.get(
      uri,
      headers: const {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load products: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data['errors'] != null) {
      throw Exception('GraphQL Error: ${data['errors']}');
    }

    return (data['data']['products']['edges'] as List<dynamic>)
        .map((p) => p['node'])
        .toList();
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
    final allProducts = useLiteCatalog
        ? await fetchLiteProducts()
        : await fetchFullProducts();
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
    const westernProfiles = [
      '01', '1', '2', '11', '18', '33', '45', '48', '50', '72', '75', '77', '91', '94', '9G',
    ];

    if (hatType == null &&
        westernStyle == null &&
        crownShape == null &&
        brimShape == null &&
        crownHeights == null &&
        brimWidths == null) {
      return List<dynamic>.from(allProducts);
    }

    return allProducts.where((product) {
      final meta = _productMeta(product);

      if (hatType != null && hatType != 'Any Type') {
        if (!_matchesHatType(meta.hatType, hatType)) {
          return false;
        }
      }

      if (westernStyle != null && westernStyle.isNotEmpty) {
        var matchesStyle = false;
        if (westernStyle == 'Western' &&
            westernProfiles.contains(meta.stetsonProfile)) {
          matchesStyle = true;
        } else if (westernStyle == 'City') {
          if (meta.city.toLowerCase() == 'true') {
            matchesStyle = true;
          }
        } else if (westernStyle == 'Outdoor') {
          if (meta.outdoors.toLowerCase() == 'true') {
            matchesStyle = true;
          }
        }
        if (!matchesStyle) return false;
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
        if (!crownHeights.any(
          (ch) => ch > 0 && meta.crownHeight.contains(ch.toString()),
        )) {
          matches = false;
        }
      }
      if (brimWidths != null && brimWidths.isNotEmpty) {
        if (!brimWidths.any((bw) => meta.brimWidth.contains(bw))) {
          matches = false;
        }
      }

      return matches;
    }).toList();
  }

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

    return pClean == uClean || pClean.contains(uClean) || uClean.contains(pClean);
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

    _inflightValidation = _downloadValidationChoices(forceRefresh: forceRefresh)
        .then((choices) {
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
    final uri = Uri.parse('${DatabaseService.baseUrl}/api/validation_choices')
        .replace(
      queryParameters:
          forceRefresh ? const {'refresh': 'true'} : const <String, String>{},
    );
    final response = await http.get(
      uri,
      headers: const {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'crown_shapes': List<String>.from(data['crown_shapes'] ?? []),
        'brim_shapes': List<String>.from(data['brim_shapes'] ?? []),
        'material_types': List<String>.from(data['material_types'] ?? []),
      };
    }
    throw Exception('Failed to load choices: ${response.statusCode}');
  }

  /// Clears caches (useful for tests or pull-to-refresh later).
  static void clearCache() {
    _cachedLiteProducts = null;
    _cachedFullProducts = null;
    _liteCacheTime = null;
    _cachedFullTime = null;
    _cachedValidationChoices = null;
    _validationCacheTime = null;
    _clearParsedMeta();
  }
}
