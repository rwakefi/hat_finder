import 'package:flutter_test/flutter_test.dart';

import 'app_store_helpers.dart';

/// App preview 3: head shape, crown guide, brim guide.
void main() {
  initAppStorePreviewBinding();

  testWidgets('app preview 3 — learn and fit', (tester) async {
    await launchAppShell(tester);
    await waitForText(tester, 'SEARCH BY HAT TYPE');
    signalPreviewReady();
    await pause(tester, const Duration(milliseconds: 800));

    await tapNavTab(tester, 'Head');
    await pause(tester, const Duration(seconds: 3));

    await tapNavTab(tester, 'Home');
    await pause(tester, const Duration(seconds: 1));

    await previewTap(tester, find.textContaining('Crown Shape').first);
    await pause(tester, const Duration(seconds: 4));

    await popToShell(tester);
    await pause(tester, const Duration(seconds: 1));

    await previewTap(tester, find.textContaining('Brim Shape').first);
    await pause(tester, const Duration(seconds: 4));
  });
}
