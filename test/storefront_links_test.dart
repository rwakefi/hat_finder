import 'package:flutter_test/flutter_test.dart';
import 'package:hat_finder/utils/storefront_links.dart';

void main() {
  test('productUrlFor prefers onlineStoreUrl', () {
    expect(
      StorefrontLinks.productUrlFor({
        'onlineStoreUrl': 'https://moonridgecompany.com/products/hat',
        'handle': 'ignored',
      }),
      'https://moonridgecompany.com/products/hat',
    );
  });

  test('productUrlFor falls back to handle', () {
    expect(
      StorefrontLinks.productUrlFor({
        'handle': 'stetson-oak-ridge',
      }),
      'https://moonridgecompany.com/products/stetson-oak-ridge',
    );
  });

  test('withVariant appends variant query param', () {
    expect(
      StorefrontLinks.withVariant(
        'https://moonridgecompany.com/products/hat',
        'gid://shopify/ProductVariant/12345',
      ),
      'https://moonridgecompany.com/products/hat?variant=12345',
    );
  });
}
