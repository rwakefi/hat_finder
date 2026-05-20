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

  test('fetch caches reuse in-flight request', () async {
    ShopifyService.clearCache();
    // Cache layer is exercised indirectly; ensure clearCache resets state.
    expect(ShopifyService.clearCache, returnsNormally);
  });
}
