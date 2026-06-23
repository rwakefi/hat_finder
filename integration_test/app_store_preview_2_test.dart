import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_store_helpers.dart';

/// App preview 2: full hat finder wizard through results.
void main() {
  initAppStorePreviewBinding();

  testWidgets('app preview 2 — wizard to results', (tester) async {
    await launchAppShell(tester);
    await waitForText(tester, 'SEARCH BY HAT TYPE');
    signalPreviewReady();
    await pause(tester, const Duration(milliseconds: 800));

    await openFindWizard(tester);
    await pause(tester, const Duration(seconds: 2));

    await previewTap(tester, find.text('FELT'));
    await pause(tester, const Duration(seconds: 2));

    await previewTap(tester, find.text('WESTERN'));
    await pause(tester, const Duration(seconds: 2));

    await previewTapAt(tester, tester.getCenter(find.byType(Scaffold).first));
    await pause(tester, const Duration(seconds: 2));

    await previewTapAt(tester, tester.getCenter(find.byType(Scaffold).first));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 500));
      if (find.text('RESULTS').evaluate().isNotEmpty) break;
    }
    await pause(tester, const Duration(seconds: 4));
  });
}
