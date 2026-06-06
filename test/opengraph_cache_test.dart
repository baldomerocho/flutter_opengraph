import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opengraph/opengraph.dart';

OpenGraphEntity _entity(String url, {String title = 'Cached title'}) {
  return OpenGraphEntity(
    title: title,
    description: 'Cached description',
    image: '',
    url: url,
    locale: 'en_US',
    type: 'website',
    siteName: 'Example',
  );
}

void main() {
  setUp(() {
    OpengraphCache.clear();
    OpengraphCache.enabled = true;
    OpengraphCache.maxEntries = 200;
  });

  group('OpengraphCache', () {
    test('put and get roundtrip', () {
      const url = 'https://example.com';
      OpengraphCache.put(url, _entity(url));

      final cached = OpengraphCache.get(url);
      expect(cached, isNotNull);
      expect(cached!.title, 'Cached title');
    });

    test('get returns null for uncached urls', () {
      expect(OpengraphCache.get('https://not-cached.com'), isNull);
    });

    test('evicts oldest entries beyond maxEntries', () {
      OpengraphCache.maxEntries = 2;
      OpengraphCache.put('https://a.com', _entity('https://a.com'));
      OpengraphCache.put('https://b.com', _entity('https://b.com'));
      OpengraphCache.put('https://c.com', _entity('https://c.com'));

      expect(OpengraphCache.length, 2);
      expect(OpengraphCache.get('https://a.com'), isNull);
      expect(OpengraphCache.get('https://b.com'), isNotNull);
      expect(OpengraphCache.get('https://c.com'), isNotNull);
    });

    test('re-inserting a url refreshes its eviction order', () {
      OpengraphCache.maxEntries = 2;
      OpengraphCache.put('https://a.com', _entity('https://a.com'));
      OpengraphCache.put('https://b.com', _entity('https://b.com'));
      // Refresh a.com so b.com becomes the oldest entry
      OpengraphCache.put('https://a.com', _entity('https://a.com'));
      OpengraphCache.put('https://c.com', _entity('https://c.com'));

      expect(OpengraphCache.get('https://a.com'), isNotNull);
      expect(OpengraphCache.get('https://b.com'), isNull);
    });

    test('evict removes a single entry', () {
      OpengraphCache.put('https://a.com', _entity('https://a.com'));
      OpengraphCache.put('https://b.com', _entity('https://b.com'));
      OpengraphCache.evict('https://a.com');

      expect(OpengraphCache.get('https://a.com'), isNull);
      expect(OpengraphCache.get('https://b.com'), isNotNull);
    });

    test('clear removes all entries', () {
      OpengraphCache.put('https://a.com', _entity('https://a.com'));
      OpengraphCache.put('https://b.com', _entity('https://b.com'));
      OpengraphCache.clear();

      expect(OpengraphCache.length, 0);
    });

    test('disabled cache stores and returns nothing', () {
      OpengraphCache.enabled = false;
      OpengraphCache.put('https://a.com', _entity('https://a.com'));

      expect(OpengraphCache.length, 0);
      expect(OpengraphCache.get('https://a.com'), isNull);
    });
  });

  group('opengraph_fetch caching', () {
    test('returns cached entity without performing a network request',
        () async {
      const url = 'https://cached-site.com';
      OpengraphCache.put(url, _entity(url));

      // There is no HTTP mocking here: if the cache were ignored this would
      // attempt a real network call and not resolve with the cached data.
      final result = await opengraph_fetch(url);

      expect(result, isNotNull);
      expect(result!.title, 'Cached title');
      expect(result.description, 'Cached description');
    });

    test('returns null for invalid urls', () async {
      final result = await opengraph_fetch('not a url');
      expect(result, isNull);
    });
  });

  group('OpengraphPreview memoization', () {
    testWidgets('does not refetch nor flash loading on parent rebuilds',
        (WidgetTester tester) async {
      const url = 'https://cached-site.com';
      OpengraphCache.put(url, _entity(url));

      late StateSetter rebuild;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return const OpengraphPreview(url: url);
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Data resolved from cache
      expect(find.text('Cached title'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Force a parent rebuild (same as scrolling rebuilds inside lists)
      rebuild(() {});
      await tester.pump();

      // The memoized future keeps its resolved state: no loading flash
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Cached title'), findsOneWidget);
    });
  });
}
