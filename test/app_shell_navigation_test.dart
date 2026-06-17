import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hat_finder/screens/app_shell.dart';
import 'package:hat_finder/screens/hat_input_screen.dart';
import 'package:hat_finder/screens/hat_results_screen.dart';
import 'package:hat_finder/services/shopify_service.dart';

void main() {
  setUp(() {
    ShopifyService.clearCache();
  });

  testWidgets('Find Hats nav opens the wizard instead of bare results',
      (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AppShell(),
      ),
    );
    await tester.pump();

    final findTab = find.ancestor(
      of: find.text('Find'),
      matching: find.byType(GestureDetector),
    );
    expect(findTab, findsOneWidget);

    await tester.tap(findTab);
    await tester.pump();

    expect(find.byType(HatInputScreen), findsOneWidget);
    expect(find.byType(HatResultsScreen), findsNothing);
    expect(find.text('Select a Hat Type:'), findsOneWidget);
  });
}
