import 'package:flutter_test/flutter_test.dart';
import 'package:hat_finder/main.dart' as app;
import 'package:integration_test/integration_test.dart';

import 'app_store_helpers.dart';

/// App preview 1: splash → home hero → start hat finder.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app preview 1 — intro and home', (tester) async {
    app.main();
    await tester.pump();
    signalPreviewReady();
    await pause(tester, const Duration(seconds: 3));
    await pause(tester, const Duration(seconds: 4));

    expect(find.text('SEARCH BY HAT TYPE'), findsOneWidget);
    await pause(tester, const Duration(seconds: 2));

    await tester.tap(find.text('SEARCH BY HAT TYPE'));
    await tester.pump();
    await pause(tester, const Duration(seconds: 2));

    expect(find.text('Select a Hat Type:'), findsOneWidget);
    await pause(tester, const Duration(seconds: 3));
  });
}
