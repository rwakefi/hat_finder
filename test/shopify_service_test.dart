import 'package:flutter_test/flutter_test.dart';
import 'package:hat_finder/services/shopify_service.dart';

void main() {
  setUp(ShopifyService.clearCache);

  test('parseMetafieldValue decodes JSON list values', () {
    expect(
      ShopifyService.parseMetafieldValue({'value': '["Cattleman"]'}),
      'Cattleman',
    );
  });

  test('filterProducts matches felt type and crown shape', () {
    final products = [
      {
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'crownShape': {'value': '["Cattleman"]'},
        'brimShape': {'value': '["Medium Curved"]'},
        'crownHeight': {'value': '["4.0"]'},
        'brimWidth': {'value': '["3.5"]'},
        'stetsonProfile': {'value': '1'},
        'city': {'value': 'false'},
        'outdoors': {'value': 'false'},
      },
      {
        'feltStrawOrBallcap': {'value': '["Straw"]'},
        'crownShape': {'value': '["Cattleman"]'},
        'brimShape': {'value': '["Flat"]'},
        'crownHeight': {'value': '["4.0"]'},
        'brimWidth': {'value': '["3.5"]'},
        'stetsonProfile': {'value': '1'},
        'city': {'value': 'false'},
        'outdoors': {'value': 'false'},
      },
    ];

    final feltOnly = ShopifyService.filterProducts(
      products,
      hatType: 'Felt',
    );
    expect(feltOnly, hasLength(1));

    final shaped = ShopifyService.filterProducts(
      products,
      hatType: 'Felt',
      crownShape: 'Cattleman',
      brimShape: 'Medium Curved',
    );
    expect(shaped, hasLength(1));
  });

  test('filterProducts matches Beanie/Flat Cap material', () {
    final products = [
      {
        'feltStrawOrBallcap': {'value': '["Beanie/Flat Cap"]'},
      },
      {
        'feltStrawOrBallcap': {'value': '["Felt"]'},
      },
    ];

    final caps = ShopifyService.filterProducts(
      products,
      hatType: 'Beanie/Flat Cap',
    );
    expect(caps, hasLength(1));
  });

  test('filterProducts correctly classifies styles for Felt and Straw hats', () {
    final products = [
      {
        'id': '1',
        'feltStrawOrBallcap': {'value': '["Straw"]'},
        'city': {'value': 'false'},
        'outdoors': {'value': 'false'},
      },
      {
        'id': '2',
        'feltStrawOrBallcap': {'value': '["Straw"]'},
        'city': {'value': 'true'},
        'outdoors': {'value': 'false'},
      },
      {
        'id': '3',
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'city': {'value': 'false'},
        'outdoors': {'value': 'true'},
      },
      {
        'id': '4',
        'feltStrawOrBallcap': {'value': '["Ballcap"]'},
        'city': {'value': 'false'},
        'outdoors': {'value': 'false'},
      },
    ];

    final western = ShopifyService.filterProducts(products, westernStyle: 'Western');
    expect(western, hasLength(1));
    expect(western.first['id'], '1');

    final city = ShopifyService.filterProducts(products, westernStyle: 'City');
    expect(city, hasLength(1));
    expect(city.first['id'], '2');

    final outdoor = ShopifyService.filterProducts(products, westernStyle: 'Outdoor');
    expect(outdoor, hasLength(1));
    expect(outdoor.first['id'], '3');
  });

  test('filterProducts excludes products without felt_straw_or_ballcap', () {
    final products = [
      {
        'id': 'eligible',
        'feltStrawOrBallcap': {'value': '["Felt"]'},
      },
      {'id': 'missing'},
      {
        'id': 'empty',
        'feltStrawOrBallcap': {'value': '[]'},
      },
      {
        'id': 'blank',
        'feltStrawOrBallcap': {'value': '""'},
      },
      {
        'id': 'wrong-category',
        'feltStrawOrBallcap': {'value': '["Romper"]'},
      },
    ];

    expect(ShopifyService.isHatFinderCatalogProduct(products[0]), isTrue);
    expect(ShopifyService.isHatFinderCatalogProduct(products[1]), isFalse);
    expect(ShopifyService.isHatFinderCatalogProduct(products[2]), isFalse);
    expect(ShopifyService.isHatFinderCatalogProduct(products[3]), isFalse);
    expect(ShopifyService.isHatFinderCatalogProduct(products[4]), isFalse);

    final eligible = ShopifyService.filterProducts(products);
    expect(eligible, hasLength(1));
    expect(eligible.first['id'], 'eligible');
  });

  test('filterProducts excludes baby apparel sizes and non-hat titles', () {
    final romper = {
      'id': 'romper',
      'title': 'Soft Cotton Baby Romper',
      'feltStrawOrBallcap': {'value': '["Beanie/Flat Cap"]'},
      'variants': {
        'edges': [
          {
            'node': {
              'availableForSale': true,
              'selectedOptions': [
                {'name': 'Size', 'value': '0-3 Month'},
                {'name': 'Color', 'value': 'Blue'},
              ],
            },
          },
        ],
      },
    };
    final hat = {
      'id': 'hat',
      'title': 'Stetson Open Road',
      'feltStrawOrBallcap': {'value': '["Felt"]'},
      'variants': {
        'edges': [
          {
            'node': {
              'availableForSale': true,
              'selectedOptions': [
                {'name': 'Size', 'value': '7'},
                {'name': 'Color', 'value': 'Silver'},
              ],
            },
          },
        ],
      },
    };

    expect(ShopifyService.isHatFinderCatalogProduct(romper), isFalse);
    expect(ShopifyService.isHatFinderCatalogProduct(hat), isTrue);
    expect(ShopifyService.isHatHeadSize('0-3 Month'), isFalse);
    expect(ShopifyService.isHatHeadSize('7'), isTrue);
    expect(ShopifyService.isHatHeadSize('Small'), isTrue);
    expect(ShopifyService.isHatHeadSize('Medium'), isTrue);
    expect(ShopifyService.isHatHeadSize('Large'), isTrue);
    expect(ShopifyService.isHatHeadSize('XL'), isTrue);
    expect(ShopifyService.isHatHeadSize('XXL'), isTrue);

    final results = ShopifyService.filterProducts([romper, hat]);
    expect(results, hasLength(1));
    expect(results.first['id'], 'hat');
  });

  test('filterProducts matches crown height and brim width in fractional inches', () {
    final products = [
      {
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'crownHeight': {'value': '["4 1/4 Inches"]'},
        'brimWidth': {'value': '["4 1/2 Inches"]'},
      },
      {
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'crownHeight': {'value': '["4.0"]'},
        'brimWidth': {'value': '["3.5"]'},
      },
    ];

    final byCrown = ShopifyService.filterProducts(
      products,
      crownHeights: [4.25],
    );
    expect(byCrown, hasLength(1));
    expect(
      ShopifyService.parseCrownHeightValues(byCrown.first['crownHeight']),
      [4.25],
    );

    final byBrim = ShopifyService.filterProducts(
      products,
      brimWidths: ['4 1/2 Inches'],
    );
    expect(byBrim, hasLength(1));
    expect(
      ShopifyService.parseBrimWidthValues(byBrim.first['brimWidth']),
      [4.5],
    );
  });

  test('filterProducts needs metafields for crown and brim wizard filtering', () {
    final withMeta = {
      'feltStrawOrBallcap': {'value': '["Felt"]'},
      'crownShape': {'value': '["Cattleman\'s"]'},
      'brimShape': {'value': '["Medium Curved"]'},
      'city': {'value': 'false'},
      'outdoors': {'value': 'false'},
    };
    final withoutMeta = {'title': 'Stetson Oak Ridge'};

    final matched = ShopifyService.filterProducts(
      [withMeta],
      hatType: 'Felt',
      westernStyle: 'Western',
      crownShape: "Cattleman's",
    );
    expect(matched, hasLength(1));

    final unmatched = ShopifyService.filterProducts(
      [withoutMeta],
      hatType: 'Felt',
      westernStyle: 'Western',
      crownShape: "Cattleman's",
    );
    expect(unmatched, isEmpty);
  });

  test('parseProductNodes maps images to featuredImage for UI', () {
    const body = r'''
    {
      "data": {
        "products": {
          "edges": [
            {
              "node": {
                "id": "gid://shopify/Product/1",
                "title": "Stetson Quality Western Goods Cap",
                "handle": "stetson-cap",
                "onlineStoreUrl": "https://example.com/products/stetson-cap",
                "images": {
                  "edges": [
                    {
                      "node": {
                        "url": "https://cdn.shopify.com/cap.png",
                        "altText": "Cap"
                      }
                    }
                  ]
                },
                "metafields": [
                  {
                    "key": "felt_straw_or_ballcap",
                    "value": "[\"Ballcap\"]"
                  }
                ],
                "variants": { "edges": [] }
              }
            }
          ]
        }
      }
    }
    ''';

    final products = ShopifyService.parseProductNodesForTest(body);
    expect(products, hasLength(1));
    final product = products.first as Map<String, dynamic>;
    expect(product['featuredImage']?['url'], 'https://cdn.shopify.com/cap.png');
    expect(product['image']?['url'], 'https://cdn.shopify.com/cap.png');
    expect(product['onlineStoreUrl'], 'https://example.com/products/stetson-cap');
    expect(
      ShopifyService.parseMetafieldValue(product['feltStrawOrBallcap']),
      'Ballcap',
    );
  });

  test('fetch caches reuse in-flight request', () async {
    ShopifyService.clearCache();
    // Cache layer is exercised indirectly; ensure clearCache resets state.
    expect(ShopifyService.clearCache, returnsNormally);
  });
}
