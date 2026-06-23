import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hat_finder/screens/app_shell.dart';
import 'package:hat_finder/services/shopify_service.dart';
import 'package:hat_finder/widgets/responsive_app_frame.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  await previewTap(tester, tab);
  await tester.pump(const Duration(milliseconds: 600));
}

/// Programmatic tap — avoids green integration-test pointer crosshairs in recordings.
Future<void> previewTap(WidgetTester tester, Finder finder) async {
  final elements = finder.evaluate();
  expect(elements, isNotEmpty);
  for (final element in elements) {
    if (_tryInvokeTap(element)) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      return;
    }
  }
  await tester.tap(finder);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
}

/// Programmatic tap at [location] — no synthetic pointer overlay.
Future<void> previewTapAt(WidgetTester tester, Offset location) async {
  final result = HitTestResult();
  tester.binding.hitTestInView(result, location, tester.view.viewId);
  for (final entry in result.path) {
    final target = entry.target;
    if (target is! RenderObject || !target.attached) continue;
    final creator = target.debugCreator;
    if (creator is! Element) continue;
    if (_tryInvokeTap(creator)) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      return;
    }
  }
  await tester.tapAt(location);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 150));
}

bool _tryInvokeTap(Element start) {
  var invoked = false;
  start.visitAncestorElements((element) {
    if (!invoked && _invokeWidgetTap(element.widget)) {
      invoked = true;
    }
    return true;
  });
  return invoked || _invokeWidgetTap(start.widget);
}

bool _invokeWidgetTap(Widget widget) {
  if (widget is GestureDetector && widget.onTap != null) {
    widget.onTap!();
    return true;
  }
  if (widget is InkWell && widget.onTap != null) {
    widget.onTap!();
    return true;
  }
  if (widget is ListTile && widget.onTap != null) {
    widget.onTap!();
    return true;
  }
  if (widget is IconButton && widget.onPressed != null) {
    widget.onPressed!();
    return true;
  }
  if (widget is TextButton && widget.onPressed != null) {
    widget.onPressed!();
    return true;
  }
  if (widget is ElevatedButton && widget.onPressed != null) {
    widget.onPressed!();
    return true;
  }
  if (widget is FilledButton && widget.onPressed != null) {
    widget.onPressed!();
    return true;
  }
  if (widget is OutlinedButton && widget.onPressed != null) {
    widget.onPressed!();
    return true;
  }
  return false;
}

void initAppStorePreviewBinding() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.onlyPumps;
}

/// Shorter splash on preview re-runs (returning-user timing).
Future<void> markReturningUserForPreview() async {
  SharedPreferences.setMockInitialValues({'has_launched_before': true});
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('has_launched_before', true);
}

/// Printed when app UI is on screen — shell scripts grep for this before recording.
void signalPreviewReady() {
  // ignore: avoid_print
  print('+0: capture ready');
}

Future<void> waitForSplashVisible(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.text('FIND YOUR').evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
  }
  expect(find.text('FIND YOUR'), findsOneWidget);
}

Future<void> waitForHomeHero(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 250));
    if (find.text('SEARCH BY HAT TYPE').evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
  }
  expect(find.text('SEARCH BY HAT TYPE'), findsOneWidget);
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
  await previewTap(tester, find.text('FELT'));
  await tester.pump(const Duration(milliseconds: 500));
  expect(find.text('Select Style:'), findsOneWidget);

  await previewTap(tester, find.text('WESTERN'));
  await tester.pump(const Duration(milliseconds: 800));
  expect(find.text('Select Crown Shape:'), findsOneWidget);
}

Future<void> selectFirstCrownAndBrim(WidgetTester tester) async {
  await previewTapAt(tester, tester.getCenter(find.byType(Scaffold).first));
  await tester.pump(const Duration(milliseconds: 800));
  expect(find.text('Select Brim Shape:'), findsOneWidget);

  await previewTapAt(tester, tester.getCenter(find.byType(Scaffold).first));
  for (var i = 0; i < 30; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('RESULTS').evaluate().isNotEmpty) return;
  }
}

Future<void> openCrownGuideFromHome(WidgetTester tester) async {
  await tapNavTab(tester, 'Home');
  await tester.pump(const Duration(milliseconds: 400));
  await previewTap(tester, find.textContaining('Crown Shape').first);
  await tester.pump(const Duration(milliseconds: 800));
  expect(find.text('A Field Guide to Crown Shapes'), findsOneWidget);
}

Future<void> openBrimGuideFromHome(WidgetTester tester) async {
  await popGuideScreen(tester);
  await previewTap(tester, find.textContaining('Brim Shape').first);
  await tester.pump(const Duration(milliseconds: 800));
  expect(find.text('A Field Guide to Brim Shapes'), findsOneWidget);
}

Future<void> popGuideScreen(WidgetTester tester) async {
  final back = find.byIcon(Icons.arrow_back);
  if (back.evaluate().isEmpty) return;
  await tester.ensureVisible(back.first);
  await previewTap(tester, back.first);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> popToShell(WidgetTester tester) async {
  await popGuideScreen(tester);
  if (find.text('RESULTS').evaluate().isNotEmpty) {
    final resultsBack = find.byIcon(Icons.arrow_back_ios_new);
    if (resultsBack.evaluate().isNotEmpty) {
      await previewTap(tester, resultsBack.first);
      await tester.pump(const Duration(milliseconds: 400));
    }
  }
}
