import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hat.dart';
import 'database_service.dart';


class ShopifyService {
  static const String storeUrl = 'https://moonridgecompany.com/api/2024-01/graphql.json';
  static const String storefrontToken = '3f15b1c10825b9bf7ed36d09141b7534';

  static Future<List<dynamic>> searchHats({
    String? hatType,
    String? westernStyle,
    String? crownShape,
    List<double>? crownHeights,
    String? brimShape,
    List<String>? brimWidths,
  }) async {
    // Shopify's Storefront Search API does not allow querying custom metafields 
    // directly unless they are specifically whitelisted in the admin settings.
    // Instead, we will fetch the first 100 active products and filter them locally.

    final String query = '''
      query {
        products(first: 250, query: "status:active") {
          edges {
            node {
              id
              title
              description
              onlineStoreUrl
              featuredImage {
                url
              }
              variants(first: 250) {
                edges {
                  node {
                    id
                    inventoryQuantity
                    availableForSale
                    selectedOptions {
                      name
                      value
                    }
                    price {
                      amount
                      currencyCode
                    }
                  }
                }
              }
              crownShape: metafield(namespace: "custom", key: "crown_shape") { value }
              brimShape: metafield(namespace: "custom", key: "brim_shape") { value }
              crownHeight: metafield(namespace: "custom", key: "crown_height") { value }
              brimWidth: metafield(namespace: "custom", key: "brim_width") { value }
              material: metafield(namespace: "custom", key: "material") { value }
              feltStrawOrBallcap: metafield(namespace: "custom", key: "felt_straw_or_ballcap") { value }
              backstrap: metafield(namespace: "custom", key: "backstrap") { value }
              stetsonProfile: metafield(namespace: "custom", key: "stetson_profile") { value }
              outdoors: metafield(namespace: "custom", key: "outdoors") { value }
              city: metafield(namespace: "custom", key: "city") { value }
              color: metafield(namespace: "custom", key: "color") { value }
              options {
                name
                values
              }
            }
          }
        }
      }
    ''';

    try {
      // Call our Railway backend instead of Shopify directly
      final response = await http.get(
        Uri.parse('${DatabaseService.baseUrl}/api/shopify_products'),
        headers: {
          'Content-Type': 'application/json',
        },
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errors'] != null) {
           throw Exception('GraphQL Error: ${data["errors"]}');
        }
        
        final List<dynamic> allProducts = data['data']['products']['edges'].map((p) => p['node']).toList();
        
        final List<String> westernProfiles = ['01', '1', '2', '11', '18', '33', '45', '48', '50', '72', '75', '77', '91', '94', '9G'];
        final List<String> notWesternProfiles = ['0', '0170', '8132', '1040', '2', '16', '18', '40', '41', '50', '9G'];

        // --- Client Side Filtering ---
        final filteredProducts = allProducts.where((product) {
          
          // If the user selected "Any" for everything (or first load), return all
          if (hatType == null && westernStyle == null && crownShape == null && brimShape == null && crownHeights == null && brimWidths == null) {
            return true;
          }

          // Helper to safely extract metafield string value from JSON array
          String getMetafieldValue(dynamic metafieldEntry) {
            if (metafieldEntry == null || metafieldEntry['value'] == null) return "";
            try {
              // Values are often stored as '["Cattlemen"]'
              var parsed = jsonDecode(metafieldEntry['value']);
              if (parsed is List && parsed.isNotEmpty) {
                 return parsed.first.toString();
              }
              return parsed.toString();
            } catch (e) {
               return metafieldEntry['value'].toString();
            }
          }

          final prodCrownShape = getMetafieldValue(product['crownShape']);
          final prodBrimShape = getMetafieldValue(product['brimShape']);
          final prodCrownHeight = getMetafieldValue(product['crownHeight']);
          final prodBrimWidth = getMetafieldValue(product['brimWidth']);
          final prodHatType = getMetafieldValue(product['feltStrawOrBallcap']);
          final prodStetsonProfile = getMetafieldValue(product['stetsonProfile']);

          // If a hat type is selected (and it's not "Any Type"), filter strictly by type first
          if (hatType != null && hatType != 'Any Type') {
             // We do a strict contain because it is a primary categorization
             if (!prodHatType.toLowerCase().contains(hatType.toLowerCase())) {
                 return false; // Skip this product immediately if it's the wrong type
             }
          }

          if (westernStyle != null && westernStyle.isNotEmpty) {
            bool matchesStyle = false;
            if (westernStyle == 'Western' && westernProfiles.contains(prodStetsonProfile)) {
              matchesStyle = true;
            } else if (westernStyle == 'City') {
              final prodCity = getMetafieldValue(product['city']).toLowerCase();
              if (prodCity == 'true') {
                matchesStyle = true;
              }
            } else if (westernStyle == 'Outdoor') {
              final prodOutdoors = getMetafieldValue(product['outdoors']).toLowerCase();
              if (prodOutdoors == 'true') {
                matchesStyle = true;
              }
            }
            if (!matchesStyle) return false; // Filter strictly by style if selected
          }

          // If ONLY the primary categories were selected (no shapes/heights), include it now that type/style match
          if (crownShape == null && brimShape == null && crownHeights == null && brimWidths == null) {
              return true;
          }

          // --- Categorical AND logic ---
          // A product must match ALL selected filters. 
          // (Within a multi-select list like crownHeights, matching ANY chosen height is sufficient).
          bool matches = true;

          bool matchShape(String prod, String ui) {
            final pNorm = prod.toLowerCase().replaceAll('-', ' ').replaceAll("'s", '').replaceAll("'", '').trim();
            final uNorm = ui.toLowerCase().replaceAll('-', ' ').replaceAll("'s", '').replaceAll("'", '').trim();
            if (pNorm.isEmpty || uNorm.isEmpty) return false;
            
            final pClean = pNorm.replaceAll(' shape', '').replaceAll(' crease', '').replaceAll(' crown', '').replaceAll(' brim', '').replaceAll(' curl', '').trim();
            final uClean = uNorm.replaceAll(' shape', '').replaceAll(' crease', '').replaceAll(' crown', '').replaceAll(' brim', '').replaceAll(' curl', '').trim();
            
            return pClean == uClean || pClean.contains(uClean) || uClean.contains(pClean);
          }

          if (crownShape != null && crownShape.isNotEmpty) {
            if (!matchShape(prodCrownShape, crownShape)) matches = false;
          }
          if (brimShape != null && brimShape.isNotEmpty) {
            if (!matchShape(prodBrimShape, brimShape)) matches = false;
          }
          if (crownHeights != null && crownHeights.isNotEmpty) {
            if (!crownHeights.any((ch) => ch > 0 && prodCrownHeight.contains(ch.toString()))) matches = false;
          }
          if (brimWidths != null && brimWidths.isNotEmpty) {
            if (!brimWidths.any((bw) => prodBrimWidth.contains(bw))) matches = false;
          }

          return matches;

        }).toList();

        return filteredProducts;

      } else {
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('Error querying Shopify: $e');
      return [];
    }
  }
  static Future<Map<String, List<String>>> fetchValidationChoices() async {
    try {
      final response = await http.get(
        Uri.parse('${DatabaseService.baseUrl}/api/validation_choices'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final crownShapes = List<String>.from(data['crown_shapes'] ?? []);
        final brimShapes = List<String>.from(data['brim_shapes'] ?? []);
        return {
          'crown_shapes': crownShapes,
          'brim_shapes': brimShapes,
        };
      } else {
        throw Exception('Failed to load choices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching validation choices: $e');
      return {
        'crown_shapes': [],
        'brim_shapes': [],
      };
    }
  }
}
