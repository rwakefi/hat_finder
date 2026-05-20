import 'package:flutter_test/flutter_test.dart';
import 'package:hat_finder/main.dart';

void main() {
  testWidgets('HatFinderApp builds without error', (WidgetTester tester) async {
    await tester.pumpWidget(const HatFinderApp());
    await tester.pump();
    expect(find.text('FIND YOUR'), findsNothing);
  });
}
