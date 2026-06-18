import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'app_store_helpers.dart';

/// App preview 3: head shape, crown guide, brim guide.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app preview 3 — learn and fit', (tester) async {
    await launchAppShell(tester);
    signalPreviewReady();
    await pause(tester, const Duration(seconds: 1));

    await tapNavTab(tester, 'Head');
    await pause(tester, const Duration(seconds: 3));

    await tapNavTab(tester, 'Home');
    await pause(tester, const Duration(seconds: 1));

    await tester.tap(find.textContaining('Crown Shape').first);
    await tester.pump();
    await pause(tester, const Duration(seconds: 4));

    await popToShell(tester);
    await pause(tester, const Duration(seconds: 1));

    await tester.tap(find.textContaining('Brim Shape').first);
    await tester.pump();
    await pause(tester, const Duration(seconds: 4));
  });
}
