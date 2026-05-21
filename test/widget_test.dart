import 'package:flutter_test/flutter_test.dart';
import 'package:hat_finder/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('HatFinderApp builds without error', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const HatFinderApp());
    await tester.pump(const Duration(milliseconds: 2600));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME TO HAT FINDER'), findsOneWidget);
  });
}
