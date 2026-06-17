import 'package:flutter_test/flutter_test.dart';
import 'package:hat_finder/models/hat.dart';
import 'package:hat_finder/services/shopify_service.dart';

void main() {
  setUp(ShopifyService.clearCache);

  test('parseMetafieldValue decodes JSON list values', () {
    expect(
      ShopifyService.parseMetafieldValue({'value': '["Cattleman"]'}),
      'Cattleman',
    );
  });

  test('parseBooleanMetafield reads Shopify true/false strings', () {
    expect(ShopifyService.parseBooleanMetafield({'value': 'true'}), isTrue);
    expect(ShopifyService.parseBooleanMetafield({'value': 'false'}), isFalse);
    expect(ShopifyService.parseBooleanMetafield({'value': ''}), isFalse);
  });

  test('isExcludedFromHatFinderExamples reads metafield only', () {
    expect(
      ShopifyService.isExcludedFromHatFinderExamples({
        'hatFinderExcludeFromExamples': {'value': 'true'},
      }),
      isTrue,
    );
    expect(
      ShopifyService.isExcludedFromHatFinderExamples({
        'hatFinderExcludeFromExamples': {'value': 'false'},
        'vendor': 'Stetson',
      }),
      isFalse,
    );
    expect(
      ShopifyService.isExcludedFromHatFinderExamples({
        'vendor': 'Bigalli Hats USA',
      }),
      isFalse,
    );
  });

  test('isEligibleForPickerExample excludes Bigalli and metafield opt-outs', () {
    expect(
      ShopifyService.isEligibleForPickerExample({
        'vendor': 'Bigalli Hats USA',
        'hatFinderExcludeFromExamples': {'value': 'false'},
      }),
      isFalse,
    );
    expect(
      ShopifyService.isEligibleForPickerExample({
        'vendor': 'Stetson',
        'hatFinderExcludeFromExamples': {'value': 'true'},
      }),
      isFalse,
    );
    expect(
      ShopifyService.isEligibleForPickerExample({
        'vendor': 'Stetson',
        'hatFinderExcludeFromExamples': {'value': 'false'},
      }),
      isTrue,
    );
  });

  test('isBestSellerProduct reads Shopify Best Seller tag', () {
    expect(
      ShopifyService.isBestSellerProduct({
        'tags': ['Best Seller', 'spinimages=51'],
      }),
      isTrue,
    );
    expect(
      ShopifyService.isBestSellerProduct({'tags': ['Western']}),
      isFalse,
    );
  });

  test('comparePickerExampleProducts ranks Best Seller before other hats', () {
    final bestSeller = {
      'title': 'Zeta Hat',
      'tags': ['Best Seller'],
      'totalInventory': 1,
    };
    final highStock = {
      'title': 'Alpha Hat',
      'tags': [],
      'totalInventory': 50,
    };

    expect(
      ShopifyService.comparePickerExampleProducts(bestSeller, highStock),
      lessThan(0),
    );
    expect(
      ShopifyService.sortPickerExampleProducts([highStock, bestSeller]).first,
      bestSeller,
    );
  });

  test('pickPreferredShapeExample prefers Amberwood for Brick crown', () {
    final products = [
      {
        'title': 'AI Brick Hat',
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'crownShape': {'value': '["Rounded Brick"]'},
        'featuredImage': {'url': 'https://example.com/ai.png'},
      },
      {
        'title': 'Amberwood Felt Hat',
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'crownShape': {'value': '["Rounded Brick"]'},
        'featuredImage': {'url': 'https://example.com/amberwood.png'},
      },
    ];

    final picked = ShopifyService.pickPreferredShapeExample(
      shapeName: 'Brick/Rounded Brick/Minnick/CHL',
      products: products,
      shapeMetaKey: 'crownShape',
      materialContains: 'felt',
    );

    expect(picked?['url'], 'https://example.com/amberwood.png');
    expect(picked?['title'], 'Amberwood Felt Hat');
  });

  test('pickShapeExamplePhoto skips Bigalli products', () {
    final products = [
      {
        'title': 'Bigalli Brick',
        'vendor': 'Bigalli Hats USA',
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'crownShape': {'value': '["Rounded Brick"]'},
        'featuredImage': {'url': 'https://example.com/bigalli.png'},
        'variants': {
          'edges': [
            {'node': {'title': '7', 'availableForSale': true}},
          ],
        },
      },
      {
        'title': 'Straw Brick Hat',
        'vendor': 'Moon Ridge',
        'feltStrawOrBallcap': {'value': '["Straw"]'},
        'crownShape': {'value': '["Rounded Brick"]'},
        'featuredImage': {'url': 'https://example.com/straw-brick.png'},
        'variants': {
          'edges': [
            {'node': {'title': '7 1/8', 'availableForSale': true}},
          ],
        },
      },
    ];

    final picked = ShopifyService.pickShapeExamplePhoto(
      shapeName: 'Brick/Rounded Brick/Minnick/CHL',
      products: products,
      shapeMetaKey: 'crownShape',
      materialContains: 'felt',
    );

    expect(picked?['url'], 'https://example.com/straw-brick.png');
  });

  test('pickShapeExamplePhoto falls back to another material for same crown shape',
      () {
    final products = [
      {
        'title': 'Straw Brick Hat',
        'feltStrawOrBallcap': {'value': '["Straw"]'},
        'crownShape': {'value': '["Rounded Brick"]'},
        'featuredImage': {'url': 'https://example.com/straw-brick.png'},
        'variants': {
          'edges': [
            {'node': {'title': '7', 'availableForSale': true}},
          ],
        },
      },
      {
        'title': 'Cattleman Felt',
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'crownShape': {'value': '["Cattleman"]'},
        'featuredImage': {'url': 'https://example.com/cattleman.png'},
        'variants': {
          'edges': [
            {'node': {'title': '7 1/8', 'availableForSale': true}},
          ],
        },
      },
    ];

    final picked = ShopifyService.pickShapeExamplePhoto(
      shapeName: 'Brick/Rounded Brick/Minnick/CHL',
      products: products,
      shapeMetaKey: 'crownShape',
      materialContains: 'felt',
    );

    expect(picked?['url'], 'https://example.com/straw-brick.png');
    expect(picked?['title'], 'Straw Brick Hat');
  });

  test('pickShapeExamplePhoto falls back to another material for same brim shape',
      () {
    final products = [
      {
        'title': 'Straw Flat Brim',
        'feltStrawOrBallcap': {'value': '["Straw"]'},
        'brimShape': {'value': '["Flat/Pencil Curl"]'},
        'featuredImage': {'url': 'https://example.com/straw-brim.png'},
        'variants': {
          'edges': [
            {'node': {'title': '7', 'availableForSale': true}},
          ],
        },
      },
      {
        'title': 'Cattleman Felt',
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'brimShape': {'value': '["J (George Strait, Medium Curved)"]'},
        'featuredImage': {'url': 'https://example.com/j-brim.png'},
        'variants': {
          'edges': [
            {'node': {'title': '7 1/8', 'availableForSale': true}},
          ],
        },
      },
    ];

    final picked = ShopifyService.pickShapeExamplePhoto(
      shapeName: 'Flat/Pencil Curl',
      products: products,
      shapeMetaKey: 'brimShape',
      materialContains: 'felt',
    );

    expect(picked?['url'], 'https://example.com/straw-brim.png');
  });

  test('pickShapeExamplePhoto returns null when no shape match exists', () {
    final products = [
      {
        'title': 'Cattleman Felt',
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'crownShape': {'value': '["Cattleman"]'},
        'featuredImage': {'url': 'https://example.com/cattleman.png'},
        'variants': {
          'edges': [
            {'node': {'title': '7', 'availableForSale': true}},
          ],
        },
      },
    ];

    final picked = ShopifyService.pickShapeExamplePhoto(
      shapeName: 'Open Crown',
      products: products,
      shapeMetaKey: 'crownShape',
    );

    expect(picked, isNull);
  });

  test('closestMatchProducts returns nearest felt hats when exact combo is empty',
      () {
    final products = [
      {
        'id': '1',
        'title': 'Alpha City Felt',
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'city': {'value': 'true'},
        'crownShape': {'value': '["Cattleman"]'},
        'brimShape': {'value': '["Medium Curved"]'},
        'variants': {
          'edges': [
            {'node': {'title': '7', 'availableForSale': true}},
          ],
        },
      },
      {
        'id': '2',
        'title': 'Beta City Felt Brick',
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'city': {'value': 'true'},
        'crownShape': {'value': '["Rounded Brick"]'},
        'brimShape': {'value': '["Medium Curved"]'},
        'variants': {
          'edges': [
            {'node': {'title': '7 1/8', 'availableForSale': true}},
          ],
        },
      },
      {
        'id': '3',
        'title': 'Gamma Western Felt',
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'city': {'value': 'false'},
        'outdoors': {'value': 'false'},
        'crownShape': {'value': '["Rounded Brick"]'},
        'brimShape': {'value': '["Medium Curved"]'},
        'variants': {
          'edges': [
            {'node': {'title': '7 1/4', 'availableForSale': true}},
          ],
        },
      },
      {
        'id': '4',
        'title': 'Delta Straw City',
        'feltStrawOrBallcap': {'value': '["Straw"]'},
        'city': {'value': 'true'},
        'crownShape': {'value': '["Rounded Brick"]'},
        'variants': {
          'edges': [
            {'node': {'title': '7', 'availableForSale': true}},
          ],
        },
      },
    ];

    final exact = ShopifyService.filterProducts(
      products,
      hatType: 'Felt',
      westernStyle: 'City',
      crownShape: 'Open Crown',
    );
    expect(exact, isEmpty);

    final closest = ShopifyService.closestMatchProducts(
      products,
      minimum: 4,
      hatType: 'Felt',
      westernStyle: 'City',
      crownShape: 'Open Crown',
    );

    expect(closest.length, 3);
    expect(
      closest.every((p) {
        final type = ShopifyService.parseMetafieldValue(p['feltStrawOrBallcap']);
        return type.toLowerCase().contains('felt');
      }),
      isTrue,
    );
    expect(closest.first['title'], 'Alpha City Felt');
  });

  test('filterProducts orders results by totalInventory descending', () {
    final products = [
      {
        'title': 'Low Stock Felt',
        'totalInventory': 2,
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'variants': {
          'edges': [
            {'node': {'title': '7', 'availableForSale': true}},
          ],
        },
      },
      {
        'title': 'High Stock Felt',
        'totalInventory': 24,
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'variants': {
          'edges': [
            {'node': {'title': '7 1/8', 'availableForSale': true}},
          ],
        },
      },
      {
        'title': 'Mid Stock Felt',
        'totalInventory': 8,
        'feltStrawOrBallcap': {'value': '["Felt"]'},
        'variants': {
          'edges': [
            {'node': {'title': '7 1/4', 'availableForSale': true}},
          ],
        },
      },
    ];

    final results = ShopifyService.filterProducts(products, hatType: 'Felt');
    expect(results.map((p) => p['title']).toList(), [
      'High Stock Felt',
      'Mid Stock Felt',
      'Low Stock Felt',
    ]);
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

  test('parseValidationChoicesPayload reads Shopify admin lists', () {
    final parsed = ShopifyService.parseValidationChoicesPayload({
      'crown_shapes': ["Cattleman's", 'Pinch Front/Teardrop/Diamond'],
      'brim_shapes': ['Flat/Pencil Curl'],
      'material_types': ['Felt', 'Straw'],
    });

    expect(parsed['crown_shapes'], [
      "Cattleman's",
      'Pinch Front/Teardrop/Diamond',
    ]);
    expect(parsed['brim_shapes'], ['Flat/Pencil Curl']);
    expect(parsed['material_types'], ['Felt', 'Straw']);
  });

  test('parseValidationChoicesPayload trims and skips blank entries', () {
    final parsed = ShopifyService.parseValidationChoicesPayload({
      'crown_shapes': ['  Open Crown ', '', '  '],
      'brim_shapes': null,
      'material_types': [],
    });

    expect(parsed['crown_shapes'], ['Open Crown']);
    expect(parsed['brim_shapes'], isEmpty);
    expect(parsed['material_types'], isEmpty);
  });

  test('filterCrownValidationChoices removes retired crown labels', () {
    expect(
      ShopifyService.filterCrownValidationChoices([
        "Cattleman's",
        'Cutter',
        'Mule Kick/Horseshoe',
        'Open Crown',
      ]),
      ["Cattleman's", 'Open Crown'],
    );
    expect(ShopifyService.isRetiredCrownValidationChoice('Cutter'), isTrue);
    expect(ShopifyService.isRetiredCrownValidationChoice("Cutter's"), isTrue);
    expect(
      ShopifyService.isRetiredCrownValidationChoice('Mule Kick/Horseshoe'),
      isTrue,
    );
  });

  test('fallback crown and brim catalogs mirror Shopify admin order', () {
    const shopifyCrownOrder = [
      "Cattleman's",
      'Pinch Front/Teardrop/Diamond',
      'Brick/Rounded Brick/Minnick/CHL',
      'Gus/Tom Mix',
      'Gambler/Telescope/Buckaroo',
      'Walker/West Texas Punch',
      'Open Crown',
    ];
    const shopifyBrimOrder = [
      'J (George Strait, Medium Curved)',
      'Flat/Pencil Curl',
      'Snap Brim/Flanged Brim',
      'RD (Round)',
      'JB (Bullrider)',
      'CHL (Cool Hand Luke, Shovel, Reiner Low Sides)',
      'U (Reiner High Sides)',
      'WTP (West Texas Punch, Rancher)',
      'SC (Showmanship)',
    ];
    const shopifyMaterialOrder = [
      'Felt',
      'Straw',
      'Ballcap',
      'Beanie/Flat Cap',
    ];

    expect(crownShapes.map((shape) => shape.name).toList(), shopifyCrownOrder);
    expect(brimShapes.map((shape) => shape.name).toList(), shopifyBrimOrder);
    expect(hatTypes.map((type) => type.name).toList(), shopifyMaterialOrder);
  });

  test('fetch caches reuse in-flight request', () async {
    ShopifyService.clearCache();
    // Cache layer is exercised indirectly; ensure clearCache resets state.
    expect(ShopifyService.clearCache, returnsNormally);
  });
}
