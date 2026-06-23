import 'package:flutter_test/flutter_test.dart';
import 'package:hat_finder/main.dart' as app;

import 'app_store_helpers.dart';

/// App preview 1: splash → home hero → start hat finder.
void main() {
  initAppStorePreviewBinding();

  testWidgets('app preview 1 — intro and home', (tester) async {
    await markReturningUserForPreview();
    app.main();
    await tester.pump();
    await waitForSplashVisible(tester);
    signalPreviewReady();
    await waitForHomeHero(tester);
    await pause(tester, const Duration(seconds: 3));

    await previewTap(tester, find.text('SEARCH BY HAT TYPE'));
    await pause(tester, const Duration(seconds: 3));

    expect(find.text('Select a Hat Type:'), findsOneWidget);
    await pause(tester, const Duration(seconds: 7));
  });
}
