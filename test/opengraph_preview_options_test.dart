import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opengraph/opengraph.dart';

OpenGraphEntity _entity({String image = ''}) {
  return OpenGraphEntity(
    title: 'Cached title',
    description: 'Cached description',
    image: image,
    url: 'https://example.com',
    locale: 'en_US',
    type: 'website',
    siteName: 'Example',
  );
}

OpenGraphEntity _entityWith(String title) {
  return OpenGraphEntity(
    title: title,
    description: 'Description',
    image: '',
    url: 'https://example.com',
    locale: 'en_US',
    type: 'website',
    siteName: 'Example',
  );
}

Widget _app(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  setUp(OpengraphCache.clear);

  group('OpengraphPreview error options', () {
    testWidgets('hideOnError renders nothing when the fetch fails',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(const OpengraphPreview(
        url: 'not a valid url',
        hideOnError: true,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Error on fetch OpenGraph'), findsNothing);
      expect(find.byType(WidgetOpenGraph), findsNothing);
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('childError replaces the default error UI',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(const OpengraphPreview(
        url: 'not a valid url',
        childError: Text('My custom error'),
      )));
      await tester.pumpAndSettle();

      expect(find.text('My custom error'), findsOneWidget);
      expect(find.text('Error on fetch OpenGraph'), findsNothing);
    });

    testWidgets('default error UI is kept when no option is set',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(const OpengraphPreview(
        url: 'not a valid url',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Error on fetch OpenGraph'), findsOneWidget);
    });

    testWidgets('showReloadButton shows a tappable refresh button on error',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(const OpengraphPreview(
        url: 'not a valid url',
        showReloadButton: true,
        refresh: 'Try again',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Tapping retries the fetch (still failing here, error UI remains)
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('retry evicts the normalized cache key for scheme-less urls',
        (WidgetTester tester) async {
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            throw http.ClientException('offline');
          });
      addTearDown(() => OpengraphFetch.clientFactory = http.Client.new);

      await tester.pumpWidget(_app(const OpengraphPreview(
        url: 'www.x.com',
        showReloadButton: true,
      )));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Seed the cache under the normalized key, then retry: _retry must
      // evict that very entry even though the widget url has no scheme —
      // otherwise the refetch below would serve the seeded entity.
      OpengraphCache.put('https://www.x.com', _entity());
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(OpengraphCache.get('https://www.x.com'), isNull);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.text('Cached title'), findsNothing);
    });
  });

  group('OpengraphPreview url updates', () {
    testWidgets('changing the url triggers a new fetch (didUpdateWidget)',
        (WidgetTester tester) async {
      OpengraphCache.put('https://a.example.com', _entityWith('Title A'));
      OpengraphCache.put('https://b.example.com', _entityWith('Title B'));

      // Non-const on purpose: also exercises the constructor at runtime
      // ignore: prefer_const_constructors
      await tester.pumpWidget(_app(OpengraphPreview(
        url: 'https://a.example.com',
      )));
      await tester.pump();
      expect(find.text('Title A'), findsOneWidget);

      // Same widget position with a different url → didUpdateWidget path
      // ignore: prefer_const_constructors
      await tester.pumpWidget(_app(OpengraphPreview(
        url: 'https://b.example.com',
      )));
      await tester.pump();

      expect(find.text('Title B'), findsOneWidget);
      expect(find.text('Title A'), findsNothing);
    });
  });

  group('OpengraphPreview loading options', () {
    testWidgets('childPreview replaces the default progress indicator',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(const OpengraphPreview(
        url: 'https://example.com',
        childPreview: Text('Loading preview...'),
      )));

      expect(find.text('Loading preview...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.pumpAndSettle();
    });
  });

  group('WidgetOpenGraph customization', () {
    testWidgets('fallbackImage replaces the default bundled image',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(WidgetOpenGraph(
        data: _entity(image: ''),
        height: 200,
        isProduction: true,
        borderRadius: 10,
        fallbackImage: const Text('CUSTOM FALLBACK'),
      )));
      await tester.pump();

      expect(find.text('CUSTOM FALLBACK'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('blur overlay is enabled by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(WidgetOpenGraph(
        data: _entity(),
        height: 200,
        isProduction: false,
        borderRadius: 10,
      )));

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('enableBlur false removes the BackdropFilter',
        (WidgetTester tester) async {
      await tester.pumpWidget(_app(WidgetOpenGraph(
        data: _entity(),
        height: 200,
        isProduction: false,
        borderRadius: 10,
        enableBlur: false,
      )));

      expect(find.byType(BackdropFilter), findsNothing);
      // The text overlay still renders
      expect(find.text('Cached title'), findsOneWidget);
    });

    testWidgets('OpengraphPreview forwards fallbackImage and enableBlur',
        (WidgetTester tester) async {
      OpengraphCache.put('https://example.com', _entity(image: ''));

      await tester.pumpWidget(_app(const OpengraphPreview(
        url: 'https://example.com',
        fallbackImage: Text('FORWARDED FALLBACK'),
        enableBlur: false,
      )));
      await tester.pumpAndSettle();

      expect(find.text('FORWARDED FALLBACK'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });
}
