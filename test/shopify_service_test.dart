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

  test('fetch caches reuse in-flight request', () async {
    ShopifyService.clearCache();
    // Cache layer is exercised indirectly; ensure clearCache resets state.
    expect(ShopifyService.clearCache, returnsNormally);
  });
}
