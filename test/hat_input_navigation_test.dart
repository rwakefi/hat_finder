import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hat_finder/screens/hat_input_screen.dart';
import 'package:hat_finder/screens/hat_results_screen.dart';
import 'package:hat_finder/services/shopify_service.dart';

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  late _RecordingNavigatorObserver observer;

  setUp(() {
    ShopifyService.clearCache();
    observer = _RecordingNavigatorObserver();
  });

  Future<void> bindPhoneViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> openWizard(WidgetTester tester) async {
    await bindPhoneViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const HatInputScreen(),
                    ),
                  );
                },
                child: const Text('OPEN WIZARD'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('OPEN WIZARD'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Select a Hat Type:'), findsOneWidget);
  }

  Future<void> pumpPageTransition(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> tapHatTypeCard(WidgetTester tester, String label) async {
    final labelFinder = find.text(label);
    expect(labelFinder, findsOneWidget);
    await tester.ensureVisible(labelFinder);
    await tester.pump();
    final card = find.ancestor(
      of: labelFinder,
      matching: find.byType(InkWell),
    );
    await tester.tap(card);
    await pumpPageTransition(tester);
  }

  Future<void> tapStyleCard(WidgetTester tester, String label) async {
    final labelFinder = find.text(label);
    expect(labelFinder, findsOneWidget);
    await tester.ensureVisible(labelFinder);
    await tester.pump();
    final card = find.ancestor(
      of: labelFinder,
      matching: find.byType(InkWell),
    );
    await tester.tap(card);
    await pumpPageTransition(tester);
  }

  Future<void> tapSelectCrown(WidgetTester tester) async {
    final description = find.textContaining('industry standard');
    await tester.ensureVisible(description.first);
    await tester.tap(description.first);
    await pumpPageTransition(tester);
  }

  Future<void> tapWizardNext(WidgetTester tester) async {
    final next = find.widgetWithText(ElevatedButton, 'NEXT: CROWN SHAPE');
    if (next.evaluate().isEmpty) {
      await tester.tap(find.textContaining('NEXT').last);
    } else {
      await tester.tap(next);
    }
    await pumpPageTransition(tester);
  }

  Future<void> tapWizardFindHats(WidgetTester tester) async {
    final button = find.widgetWithText(ElevatedButton, 'FIND HATS');
    if (button.evaluate().isEmpty) {
      await tester.tap(find.textContaining('FIND HATS').last);
    } else {
      await tester.tap(button);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> finishBrimStep(WidgetTester tester) async {
    await tapWizardFindHats(tester);
  }

  group('hat type wizard navigation', () {
    testWidgets('Felt navigates Style → Crown → Brim → Results',
        (tester) async {
      await openWizard(tester);

      await tapHatTypeCard(tester, 'FELT');
      expect(find.text('Select Style:'), findsOneWidget);

      await tapStyleCard(tester, 'WESTERN');
      expect(find.text('Select Crown Shape:'), findsOneWidget);

      await tapSelectCrown(tester);
      expect(find.text('Select Brim Shape:'), findsOneWidget);

      await finishBrimStep(tester);
      expect(find.text('RESULTS'), findsOneWidget);
    });

    testWidgets('Straw navigates Style → Crown → Brim → Results',
        (tester) async {
      await openWizard(tester);

      await tapHatTypeCard(tester, 'STRAW');
      expect(find.text('Select Style:'), findsOneWidget);

      await tapStyleCard(tester, 'CITY');
      expect(find.text('Select Crown Shape:'), findsOneWidget);

      await tapSelectCrown(tester);
      expect(find.text('Select Brim Shape:'), findsOneWidget);

      await finishBrimStep(tester);
      expect(find.text('RESULTS'), findsOneWidget);
    });

    testWidgets('Ballcap skips shape wizard and opens Results', (tester) async {
      await openWizard(tester);

      await tapHatTypeCard(tester, 'BALLCAP');

      expect(find.text('Select Crown Shape:'), findsNothing);
      expect(find.text('Select Brim Shape:'), findsNothing);
      expect(find.byType(HatResultsScreen), findsOneWidget);
    });

    testWidgets('Beanie/Flat Cap skips shape wizard and opens Results',
        (tester) async {
      await openWizard(tester);

      await tapHatTypeCard(tester, 'BEANIE/FLAT CAP');

      expect(find.text('Select Crown Shape:'), findsNothing);
      expect(find.text('Select Brim Shape:'), findsNothing);
      expect(find.byType(HatResultsScreen), findsOneWidget);
    });

    testWidgets('Any Hat Type skips style and navigates Crown → Brim → Results',
        (tester) async {
      await openWizard(tester);

      await tester.tap(find.text('ANY HAT TYPE'));
      await pumpPageTransition(tester);
      expect(find.text('Select Style:'), findsNothing);
      expect(find.text('Select Crown Shape:'), findsOneWidget);

      await tapWizardNext(tester);
      expect(find.text('Select Brim Shape:'), findsOneWidget);

      await tapWizardFindHats(tester);
      expect(find.text('RESULTS'), findsOneWidget);
      final results =
          tester.widget<HatResultsScreen>(find.byType(HatResultsScreen));
      expect(results.crownShape, isNull);
      expect(results.brimShape, isNull);
    });

    testWidgets('back navigation returns through wizard steps for Felt',
        (tester) async {
      await openWizard(tester);

      await tapHatTypeCard(tester, 'FELT');
      await tapStyleCard(tester, 'WESTERN');
      expect(find.text('Select Crown Shape:'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'BACK'));
      await pumpPageTransition(tester);
      expect(find.text('Select Style:'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'BACK'));
      await pumpPageTransition(tester);
      expect(find.text('Select a Hat Type:'), findsOneWidget);
    });
  });
}
