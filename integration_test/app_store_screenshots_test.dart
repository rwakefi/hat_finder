import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_store_helpers.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture 10 iPhone 6.5 inch App Store screenshots', (tester) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

    await launchAppShell(tester);
    await captureScreenshot(binding, tester, '01-home');

    await openFindWizard(tester);
    await captureScreenshot(binding, tester, '02-hat-type');

    await tester.tap(find.text('FELT'));
    await tester.pump();
    expect(find.text('Select Style:'), findsOneWidget);
    await waitForContentLoad(tester);
    await captureScreenshot(binding, tester, '03-style');

    await tester.tap(find.text('WESTERN'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Select Crown Shape:'), findsOneWidget);
    await captureScreenshot(binding, tester, '04-crown');

    await tester.tapAt(tester.getCenter(find.byType(Scaffold).first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('Select Brim Shape:'), findsOneWidget);
    await captureScreenshot(binding, tester, '05-brim');

    await tester.tapAt(tester.getCenter(find.byType(Scaffold).first));
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('RESULTS').evaluate().isNotEmpty) break;
    }
    expect(find.text('RESULTS'), findsOneWidget);
    await captureScreenshot(binding, tester, '06-results');

    await tapNavTab(tester, 'Head');
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('LEARN YOUR HEAD SHAPE'), findsOneWidget);
    await captureScreenshot(binding, tester, '07-head-shape');

    await openCrownGuideFromHome(tester);
    await waitForContentLoad(tester);
    await captureScreenshot(binding, tester, '08-crown-guide');

    await openBrimGuideFromHome(tester);
    await captureScreenshot(binding, tester, '09-brim-guide');

    await popToShell(tester);
    await tapNavTab(tester, 'Connect');
    await tester.pump(const Duration(seconds: 4));
    await captureScreenshot(binding, tester, '10-events-connect');
  });
}
