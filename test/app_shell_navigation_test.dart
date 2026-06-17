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

  testWidgets('Home tab resets the hat finder wizard', (tester) async {
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
    await tester.tap(findTab);
    await tester.pump();

    await tester.tap(find.text('ANY HAT TYPE'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Select Crown Shape:'), findsOneWidget);

    final homeTab = find.ancestor(
      of: find.text('Home'),
      matching: find.byType(GestureDetector),
    );
    await tester.tap(homeTab);
    await tester.pump();

    expect(find.textContaining('Select a Hat Type'), findsNothing);

    await tester.tap(findTab);
    await tester.pump();

    expect(find.text('Select a Hat Type:'), findsOneWidget);
    expect(find.text('Select Crown Shape:'), findsNothing);
  });
}
