import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hat_finder/screens/head_shape_screen.dart';

void main() {
  testWidgets('head-shape quiz offers optional no-camera measurement',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HeadShapeScreen(),
      ),
    );

    expect(
      find.textContaining('This is about how hats feel on your head'),
      findsOneWidget,
    );

    await tester.tap(find.text('FOREHEAD & BACK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YES, IT ROCKS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('YES, I SIZE UP FOR COMFORT'));
    await tester.pumpAndSettle();

    expect(find.text('LONG OVAL'), findsOneWidget);
    expect(find.text('ADD SIZE MEASUREMENT'), findsOneWidget);

    await tester.tap(find.text('ADD SIZE MEASUREMENT'));
    await tester.pumpAndSettle();

    expect(find.text('What is your head size?'), findsOneWidget);
    expect(
      find.textContaining('Enter a known hat size, or measure'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField).first, '58');
    await tester.ensureVisible(find.text('SAVE MEASUREMENT'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SAVE MEASUREMENT'));
    await tester.pumpAndSettle();

    expect(find.text('SIZE STARTING POINT'), findsOneWidget);
    expect(find.textContaining('58.0 cm'), findsOneWidget);
  });
}
