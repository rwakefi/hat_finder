import 'package:flutter_test/flutter_test.dart';
import 'package:hat_finder/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('HatFinderApp builds without error', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'has_launched_before': true});

    await tester.pumpWidget(const HatFinderApp());
    await _pumpUntilFound(tester, find.text('SEARCH BY HAT TYPE'));

    expect(find.text('FIND YOUR PERFECT HAT'), findsOneWidget);
    expect(find.text('SEARCH BY HAT TYPE'), findsOneWidget);
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  const step = Duration(milliseconds: 100);
  var elapsed = Duration.zero;
  while (elapsed < timeout) {
    await tester.pump(step);
    if (tester.any(finder)) {
      await tester.pumpAndSettle();
      return;
    }
    elapsed += step;
  }
}
