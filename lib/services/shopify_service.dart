import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/hat.dart';

class ShopifyService {
  static const String storeUrl = 'https://raftermhatco.com/api/2024-01/graphql.json';
  static const String storefrontToken = 'd094605eefb28f21b4b2be0e1bd2e56c';

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
              variants(first: 1) {
                edges {
                  node {
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
            }
          }
        }
      }
    ''';

    try {
      final response = await http.post(
        Uri.parse(storeUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Shopify-Storefront-Access-Token': storefrontToken,
        },
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['errors'] != null) {
           throw Exception('GraphQL Error: \${data["errors"]}');
        }
        
        final List<dynamic> allProducts = data['data']['products']['edges'].map((p) => p['node']).toList();
        
        final List<String> westernProfiles = ['01', '1', '2', '11', '18', '33', '45', '48', '50', '72', '75', '77', '91', '94', '9G'];
        final List<String> notWesternProfiles = ['0', '0170', '8132', '1040', '2', '16', '18', '40', '41', '50', '9G'];

        // --- Client Side Filtering ---
        final filteredProducts = allProducts.where((product) {
          
          bool matches = false; // We want an OR search. If it matches ANYTHING, include it.
          
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
            } else if (westernStyle == 'Not Western' && notWesternProfiles.contains(prodStetsonProfile)) {
              matchesStyle = true;
            }
            if (!matchesStyle) return false; // Filter strictly by style if selected
          }

          // If ONLY the primary categories were selected (no shapes/heights), include it now that type/style match
          if (crownShape == null && brimShape == null && crownHeights == null && brimWidths == null) {
              return true;
          }

          if (crownShape != null && crownShape.isNotEmpty && prodCrownShape.contains(crownShape)) matches = true;
          if (brimShape != null && brimShape.isNotEmpty && prodBrimShape.contains(brimShape)) matches = true;
          if (crownHeights != null && crownHeights.isNotEmpty && crownHeights.any((ch) => ch > 0 && prodCrownHeight.contains(ch.toString()))) matches = true;
          if (brimWidths != null && brimWidths.isNotEmpty && brimWidths.any((bw) => prodBrimWidth.contains(bw))) matches = true;

          return matches;

        }).toList();

        return filteredProducts;

      } else {
        throw Exception('Failed to load products: \${response.statusCode}');
      }
    } catch (e) {
      print('Error querying Shopify: \$e');
      return [];
    }
  }
}
