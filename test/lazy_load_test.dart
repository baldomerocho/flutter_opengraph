import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opengraph/opengraph.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  setUpAll(() {
    // Make visibility callbacks fire on the next frame instead of after the
    // default 500ms debounce, so the tests can pump deterministically.
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDownAll(() {
    // Each test file runs in its own isolate, but restore the default
    // anyway so this file never leaks state if that changes.
    VisibilityDetectorController.instance.updateInterval =
        const Duration(milliseconds: 500);
  });

  late int calls;

  setUp(() {
    OpengraphCache.clear();
    calls = 0;
    OpengraphFetch.clientFactory = () => MockClient((request) async {
          calls++;
          return http.Response(
              '<html><head><meta property="og:title" content="Lazy title">'
              '</head></html>',
              200,
              headers: {'content-type': 'text/html; charset=utf-8'});
        });
  });

  tearDown(() {
    OpengraphFetch.clientFactory = http.Client.new;
    OpengraphCache.clear();
  });

  Widget scrollable(ScrollController controller, Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          controller: controller,
          // Column builds every child immediately (unlike ListView.builder),
          // so an offscreen preview exists and would fetch if not lazy.
          child: Column(children: [const SizedBox(height: 2000), child]),
        ),
      ),
    );
  }

  group('OpengraphPreview lazyLoad', () {
    testWidgets('defers the fetch until the widget scrolls into view',
        (WidgetTester tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(scrollable(
        controller,
        const OpengraphPreview(url: 'https://lazy.example.com', lazyLoad: true),
      ));
      // Bounded pumps: a mounted VisibilityDetector keeps scheduling frames
      // with updateInterval zero, so pumpAndSettle would never settle.
      await tester.pump();
      await tester.pump();

      // Offscreen: no request fired yet, the placeholder is shown.
      expect(calls, 0);

      controller.jumpTo(1900);
      await tester.pump(); // scrolled frame, visibility callback scheduled
      await tester.pump(); // callback fires -> fetch starts
      await tester.pump(); // FutureBuilder rebuilds with the resolved data

      expect(calls, 1);
      expect(find.text('Lazy title'), findsOneWidget);
    });

    testWidgets('without lazyLoad an offscreen preview fetches immediately',
        (WidgetTester tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(scrollable(
        controller,
        const OpengraphPreview(url: 'https://eager.example.com'),
      ));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('a visible lazy preview starts after the visibility callback',
        (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: OpengraphPreview(
              url: 'https://visible.example.com', lazyLoad: true),
        ),
      ));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(find.text('Lazy title'), findsOneWidget);
    });

    testWidgets('turning lazyLoad off before being visible starts the fetch',
        (WidgetTester tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(scrollable(
        controller,
        const OpengraphPreview(
            url: 'https://toggled.example.com', lazyLoad: true),
      ));
      await tester.pump();
      await tester.pump();
      expect(calls, 0);

      // Same position, lazyLoad switched off -> didUpdateWidget path.
      await tester.pumpWidget(scrollable(
        controller,
        const OpengraphPreview(url: 'https://toggled.example.com'),
      ));
      await tester.pump();
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets('disposing an offscreen lazy preview never fetches',
        (WidgetTester tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(scrollable(
        controller,
        const OpengraphPreview(
            url: 'https://disposed.example.com', lazyLoad: true),
      ));
      await tester.pump();
      await tester.pump();

      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      await tester.pumpAndSettle();

      expect(calls, 0);
    });
  });
}
