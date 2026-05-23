import 'package:flutter_test/flutter_test.dart';
import 'package:hat_finder/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveHat stores bookmarks locally and deduplicates by URL', () async {
    final firstSave = await DatabaseService.saveHat(
      name: 'Cattleman Felt',
      brand: 'Moon Ridge',
      price: '\$120',
      size: '7 1/4',
      url: 'https://example.com/hats/cattleman',
    );
    final secondSave = await DatabaseService.saveHat(
      name: 'Cattleman Felt - Updated',
      brand: 'Moon Ridge',
      price: '\$110',
      size: '7 1/4',
      url: 'https://example.com/hats/cattleman',
    );

    final savedHats = await DatabaseService.getSavedHats();
    final savedHat = savedHats.single as Map<String, dynamic>;

    expect(firstSave, isTrue);
    expect(secondSave, isTrue);
    expect(savedHats, hasLength(1));
    expect(savedHat['name'], 'Cattleman Felt - Updated');
    expect(savedHat['price'], '\$110');
    expect(savedHat['url'], 'https://example.com/hats/cattleman');
    expect(savedHat['created_at'], isNotEmpty);
  });

  test('clearSavedHats removes local bookmarks', () async {
    await DatabaseService.saveHat(
      name: 'Open Road',
      url: 'https://example.com/hats/open-road',
    );

    expect(await DatabaseService.getSavedHats(), hasLength(1));
    expect(await DatabaseService.clearSavedHats(), isTrue);
    expect(await DatabaseService.getSavedHats(), isEmpty);
  });
}
