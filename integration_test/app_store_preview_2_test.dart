import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_store_helpers.dart';

/// App preview 2: full hat finder wizard through results.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app preview 2 — wizard to results', (tester) async {
    await launchAppShell(tester);
    signalPreviewReady();
    await pause(tester, const Duration(seconds: 1));

    await openFindWizard(tester);
    await pause(tester, const Duration(seconds: 2));

    await tester.tap(find.text('FELT'));
    await tester.pump();
    await pause(tester, const Duration(seconds: 2));

    await tester.tap(find.text('WESTERN'));
    await tester.pump();
    await pause(tester, const Duration(seconds: 2));

    await tester.tapAt(tester.getCenter(find.byType(Scaffold).first));
    await tester.pump();
    await pause(tester, const Duration(seconds: 2));

    await tester.tapAt(tester.getCenter(find.byType(Scaffold).first));
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('RESULTS').evaluate().isNotEmpty) break;
    }
    await pause(tester, const Duration(seconds: 4));
  });
}
