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

    test('get, put and evict normalize their keys', () {
      OpengraphCache.put('www.example.com', _entity('https://www.example.com'));

      // Scheme-less and normalized forms address the same entry.
      expect(OpengraphCache.get('https://www.example.com'), isNotNull);
      expect(OpengraphCache.get('www.example.com'), isNotNull);
      expect(OpengraphCache.length, 1);

      OpengraphCache.evict('www.example.com');
      expect(OpengraphCache.get('https://www.example.com'), isNull);
    });
  });

  group('OpengraphCache TTL', () {
    tearDown(() {
      OpengraphCache.ttl = const Duration(hours: 24);
      OpengraphCache.clock = DateTime.now;
    });

    test('expires entries older than ttl on access', () {
      var current = DateTime(2026, 1, 1);
      OpengraphCache.clock = () => current;
      OpengraphCache.ttl = const Duration(minutes: 30);

      OpengraphCache.put('https://a.com', _entity('https://a.com'));
      expect(OpengraphCache.get('https://a.com'), isNotNull);

      current = current.add(const Duration(minutes: 31));
      expect(OpengraphCache.get('https://a.com'), isNull);
      // Stale entries are removed, not just hidden.
      expect(OpengraphCache.length, 0);
    });

    test('null ttl keeps entries for the whole session', () {
      var current = DateTime(2026, 1, 1);
      OpengraphCache.clock = () => current;
      OpengraphCache.ttl = null;

      OpengraphCache.put('https://a.com', _entity('https://a.com'));
      current = current.add(const Duration(days: 365));

      expect(OpengraphCache.get('https://a.com'), isNotNull);
    });

    test('maxAge overrides ttl per lookup', () {
      var current = DateTime(2026, 1, 1);
      OpengraphCache.clock = () => current;
      OpengraphCache.ttl = null;

      OpengraphCache.put('https://a.com', _entity('https://a.com'));
      current = current.add(const Duration(hours: 1));

      expect(
          OpengraphCache.get('https://a.com',
              maxAge: const Duration(minutes: 30)),
          isNull);
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
