import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_store_helpers.dart';

/// Re-capture screenshots that need extra load time (03-style, 08-crown-guide).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('re-capture 03-style and 08-crown-guide', (tester) async {
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

    await launchAppShell(tester);

    await openFindWizard(tester);
    await tester.tap(find.text('FELT'));
    await tester.pump();
    await waitForText(tester, 'Select Style:');
    await waitForContentLoad(tester);
    await captureScreenshot(binding, tester, '03-style');

    await tapNavTab(tester, 'Home');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.textContaining('Crown Shape').first);
    await tester.pump();
    await waitForText(tester, 'A Field Guide to Crown Shapes');
    await waitForContentLoad(tester);
    await captureScreenshot(binding, tester, '08-crown-guide');
  });
}
