import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hat_finder/screens/app_shell.dart';
import 'package:hat_finder/services/shopify_service.dart';
import 'package:hat_finder/widgets/responsive_app_frame.dart';
import 'package:integration_test/integration_test.dart';

/// Pumps [AppShell] with the same theme chrome as production (no splash).
Future<void> launchAppShell(WidgetTester tester) async {
  ShopifyService.clearCache();
  ShopifyService.preloadWizardCatalog(includeFullCatalog: true);

  await tester.pumpWidget(
    MaterialApp(
      title: 'Moon Ridge Hat Finder',
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        return ResponsiveAppFrame(child: child);
      },
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF559C99),
          primary: const Color(0xFF2D2926),
          secondary: const Color(0xFF559C99),
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.montserratTextTheme(
          ThemeData.light().textTheme,
        ).apply(
          bodyColor: const Color(0xFF2D2926),
          displayColor: const Color(0xFF2D2926),
        ),
      ),
      home: AppShell(),
    ),
  );

  await tester.pump();
  await _waitForCatalog(tester);
}

Future<void> _waitForCatalog(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('FELT').evaluate().isNotEmpty ||
        find.text('SEARCH BY HAT TYPE').evaluate().isNotEmpty) {
      return;
    }
  }
}

Future<void> tapNavTab(WidgetTester tester, String label) async {
  final tab = find.ancestor(
    of: find.text(label),
    matching: find.byType(GestureDetector),
  );
  expect(tab, findsOneWidget);
  await tester.tap(tab);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// Printed when app UI is on screen — shell scripts grep for this before recording.
void signalPreviewReady() {
  // ignore: avoid_print
  print('+0: capture ready');
}

Future<void> pause(WidgetTester tester, Duration duration) async {
  final steps = duration.inMilliseconds ~/ 200;
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

Future<void> waitForContentLoad(
  WidgetTester tester, {
  Duration extra = const Duration(seconds: 7),
}) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(LinearProgressIndicator).evaluate().isEmpty &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      break;
    }
  }
  await pause(tester, extra);
}

Future<void> captureScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  WidgetTester tester,
  String name,
) async {
  if (!kIsWeb && Platform.isAndroid) {
    await binding.convertFlutterSurfaceToImage();
  }
  await tester.pump();
  await binding.takeScreenshot(name);
}

Future<void> openFindWizard(WidgetTester tester) async {
  await tapNavTab(tester, 'Find');
  await tester.pump(const Duration(milliseconds: 400));
  expect(find.text('Select a Hat Type:'), findsOneWidget);
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('FELT').evaluate().isNotEmpty) return;
  }
}

Future<void> waitForText(WidgetTester tester, String text) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text(text).evaluate().isNotEmpty) return;
  }
  expect(find.text(text), findsOneWidget);
}

Future<void> selectFeltAndWestern(WidgetTester tester) async {
  await tester.tap(find.text('FELT'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.text('Select Style:'), findsOneWidget);

  await tester.tap(find.text('WESTERN'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  expect(find.text('Select Crown Shape:'), findsOneWidget);
}

Future<void> selectFirstCrownAndBrim(WidgetTester tester) async {
  await tester.tapAt(tester.getCenter(find.byType(Scaffold).first));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  expect(find.text('Select Brim Shape:'), findsOneWidget);

  await tester.tapAt(tester.getCenter(find.byType(Scaffold).first));
  await tester.pump();
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('RESULTS').evaluate().isNotEmpty) return;
  }
}

Future<void> openCrownGuideFromHome(WidgetTester tester) async {
  await tapNavTab(tester, 'Home');
  await tester.pump(const Duration(milliseconds: 400));
  await tester.tap(find.textContaining('Crown Shape').first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  expect(find.text('A Field Guide to Crown Shapes'), findsOneWidget);
}

Future<void> openBrimGuideFromHome(WidgetTester tester) async {
  await popGuideScreen(tester);
  await tester.tap(find.textContaining('Brim Shape').first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
  expect(find.text('A Field Guide to Brim Shapes'), findsOneWidget);
}

Future<void> popGuideScreen(WidgetTester tester) async {
  final back = find.byIcon(Icons.arrow_back);
  if (back.evaluate().isEmpty) return;
  await tester.ensureVisible(back.first);
  await tester.tap(back.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> popToShell(WidgetTester tester) async {
  await popGuideScreen(tester);
  if (find.text('RESULTS').evaluate().isNotEmpty) {
    final resultsBack = find.byIcon(Icons.arrow_back_ios_new);
    if (resultsBack.evaluate().isNotEmpty) {
      await tester.tap(resultsBack.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
  }
}
