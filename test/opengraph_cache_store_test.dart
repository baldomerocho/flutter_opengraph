import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opengraph/opengraph.dart';

/// In-memory [OpengraphCacheStore] with call counters and a failure mode,
/// standing in for shared_preferences/hive/file implementations.
class _FakeStore implements OpengraphCacheStore {
  final Map<String, OpengraphCacheEntry> entries = {};
  int reads = 0;
  int writes = 0;
  int deletes = 0;
  int clears = 0;
  bool failing = false;

  void _maybeFail() {
    if (failing) throw StateError('store down');
  }

  @override
  Future<OpengraphCacheEntry?> read(String url) async {
    reads++;
    _maybeFail();
    return entries[url];
  }

  @override
  Future<void> write(String url, OpengraphCacheEntry entry) async {
    writes++;
    _maybeFail();
    entries[url] = entry;
  }

  @override
  Future<void> delete(String url) async {
    deletes++;
    _maybeFail();
    entries.remove(url);
  }

  @override
  Future<void> clear() async {
    clears++;
    _maybeFail();
    entries.clear();
  }
}

/// A store whose methods throw synchronously (before returning a Future),
/// the worst-behaved implementation the guard must survive.
class _SyncThrowingStore implements OpengraphCacheStore {
  @override
  Future<OpengraphCacheEntry?> read(String url) async => null;

  @override
  Future<void> write(String url, OpengraphCacheEntry entry) =>
      throw StateError('sync failure');

  @override
  Future<void> delete(String url) => throw StateError('sync failure');

  @override
  Future<void> clear() => throw StateError('sync failure');
}

/// A store whose read never completes — the pathological implementation
/// that [OpengraphCache.storeTimeout] must defend against.
class _HangingStore implements OpengraphCacheStore {
  @override
  Future<OpengraphCacheEntry?> read(String url) =>
      Completer<OpengraphCacheEntry?>().future;

  @override
  Future<void> write(String url, OpengraphCacheEntry entry) async {}

  @override
  Future<void> delete(String url) async {}

  @override
  Future<void> clear() async {}
}

/// A slow store that snapshots the value at read START (like a real disk
/// read does) and resolves it after a delay, opening the late-hydration
/// race window.
class _SnapshotSlowStore implements OpengraphCacheStore {
  final Map<String, OpengraphCacheEntry> entries = {};

  @override
  Future<OpengraphCacheEntry?> read(String url) {
    final snapshot = entries[url];
    return Future.delayed(const Duration(milliseconds: 20), () => snapshot);
  }

  @override
  Future<void> write(String url, OpengraphCacheEntry entry) async {
    entries[url] = entry;
  }

  @override
  Future<void> delete(String url) async {
    entries.remove(url);
  }

  @override
  Future<void> clear() async {
    entries.clear();
  }
}

OpenGraphEntity _entity(String title) {
  return OpenGraphEntity(
    title: title,
    description: 'D',
    image: '',
    url: 'https://example.com',
    locale: 'en_US',
    type: 'website',
    siteName: '',
  );
}

/// Lets the fire-and-forget store writes scheduled by the cache complete.
Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _FakeStore store;

  setUp(() {
    store = _FakeStore();
    OpengraphCache.clear();
    OpengraphCache.store = store;
  });

  tearDown(() {
    OpengraphCache.store = null;
    OpengraphCache.clear();
    OpengraphCache.ttl = const Duration(hours: 24);
    OpengraphCache.clock = DateTime.now;
    OpengraphCache.storeTimeout = const Duration(seconds: 5);
    OpengraphCache.enabled = true;
    OpengraphFetch.clientFactory = http.Client.new;
  });

  group('OpengraphCacheEntry', () {
    test('json roundtrip keeps the entity and the timestamp', () {
      final entry = OpengraphCacheEntry(
        entity: _entity('Persisted'),
        storedAt: DateTime(2026, 6, 6, 12),
      );

      final restored = OpengraphCacheEntry.fromJson(entry.toJson());

      expect(restored.entity.title, 'Persisted');
      expect(restored.storedAt, DateTime(2026, 6, 6, 12));
    });

    test('survives a real jsonEncode/jsonDecode cycle with rich fields', () {
      final entry = OpengraphCacheEntry(
        entity: OpenGraphEntity(
          title: 'Rich',
          description: 'D',
          image: 'https://example.com/a.png',
          url: 'https://example.com',
          locale: 'en_US',
          type: 'article',
          siteName: 'Example',
          images: const [
            OgImage(
                url: 'https://example.com/a.png',
                width: 1200,
                height: 630,
                alt: 'alt'),
          ],
          videos: const [OgVideo(url: 'https://example.com/v.mp4')],
          audios: const [OgAudio(url: 'https://example.com/a.mp3')],
          structuredTags: const {
            'article:tag': ['a', 'b'],
          },
          faviconUrl: 'https://example.com/favicon.ico',
        ),
        storedAt: DateTime(2026, 6, 6, 12),
      );

      // The string round trip is what a real shared_preferences/file
      // store does; decoded maps come back as Map<String, dynamic>.
      final restored =
          OpengraphCacheEntry.fromJson(jsonDecode(jsonEncode(entry.toJson())));

      expect(restored.entity.images.single.width, 1200);
      expect(restored.entity.images.single.alt, 'alt');
      expect(restored.entity.videos.single.url, 'https://example.com/v.mp4');
      expect(restored.entity.audios.single.url, 'https://example.com/a.mp3');
      expect(restored.entity.structuredTags['article:tag'], ['a', 'b']);
      expect(restored.entity.faviconUrl, 'https://example.com/favicon.ico');
      expect(restored.storedAt, DateTime(2026, 6, 6, 12));
    });

    test('tolerates corrupt persisted json', () {
      final restored = OpengraphCacheEntry.fromJson({
        'entity': 'not a map',
        'storedAt': 'not an int',
      });

      expect(restored.entity.title, '');
      // Epoch timestamp: any TTL marks it stale, so it gets dropped.
      expect(restored.storedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });

  group('write-through', () {
    test('put persists the entry under the normalized key', () async {
      OpengraphCache.put('www.example.com', _entity('T'));
      await _flush();

      expect(store.writes, 1);
      expect(store.entries['https://www.example.com']!.entity.title, 'T');
    });

    test('evict deletes from the store', () async {
      OpengraphCache.put('https://a.com', _entity('T'));
      await _flush();

      OpengraphCache.evict('https://a.com');
      await _flush();

      expect(store.deletes, 1);
      expect(store.entries, isEmpty);
    });

    test('clear wipes the store unless memoryOnly is passed', () async {
      OpengraphCache.put('https://a.com', _entity('T'));
      await _flush();

      OpengraphCache.clear(memoryOnly: true);
      await _flush();
      expect(store.entries, hasLength(1));
      expect(OpengraphCache.length, 0);

      OpengraphCache.clear();
      await _flush();
      expect(store.clears, 1);
      expect(store.entries, isEmpty);
    });
  });

  group('persistence across restarts', () {
    test('memory miss is answered from the store without a network call',
        () async {
      var networkCalls = 0;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            networkCalls++;
            return http.Response('<html></html>', 200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      OpengraphCache.put('https://persisted.example.com', _entity('Survives'));
      await _flush();
      // Simulate an app restart: memory gone, store intact.
      OpengraphCache.clear(memoryOnly: true);

      final entity = await opengraph_fetch('https://persisted.example.com');

      expect(entity!.title, 'Survives');
      expect(networkCalls, 0);
      // The hit hydrated the in-memory cache for synchronous reads.
      expect(OpengraphCache.get('https://persisted.example.com'), isNotNull);
    });

    test('stale persisted entries are deleted and refetched', () async {
      var current = DateTime(2026, 1, 1);
      OpengraphCache.clock = () => current;
      var networkCalls = 0;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            networkCalls++;
            return http.Response(
                '<html><head><meta property="og:title" content="Fresh">'
                '</head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      OpengraphCache.put('https://stale.example.com', _entity('Old'));
      await _flush();
      OpengraphCache.clear(memoryOnly: true);
      current = current.add(const Duration(days: 2)); // past the 24h ttl

      final entity = await opengraph_fetch('https://stale.example.com');
      await _flush();

      expect(networkCalls, 1);
      expect(entity!.title, 'Fresh');
      expect(store.deletes, greaterThanOrEqualTo(1));
    });

    test('hydration respects maxEntries', () async {
      OpengraphCache.maxEntries = 1;
      addTearDown(() => OpengraphCache.maxEntries = 200);

      OpengraphCache.put('https://a.com', _entity('A'));
      OpengraphCache.put('https://b.com', _entity('B'));
      await _flush();
      OpengraphCache.clear(memoryOnly: true);

      await OpengraphCache.loadPersisted('https://a.com');
      await OpengraphCache.loadPersisted('https://b.com');

      expect(OpengraphCache.length, 1);
      expect(OpengraphCache.get('https://b.com'), isNotNull);
      expect(OpengraphCache.get('https://a.com'), isNull);
    });

    test('expiry after hydration uses the original storedAt', () async {
      var current = DateTime(2026, 1, 1);
      OpengraphCache.clock = () => current;

      OpengraphCache.put('https://age.example.com', _entity('T')); // t0
      await _flush();
      OpengraphCache.clear(memoryOnly: true);

      // Hydrate at t0+23h: still fresh against the 24h ttl.
      current = current.add(const Duration(hours: 23));
      expect(await OpengraphCache.loadPersisted('https://age.example.com'),
          isNotNull);

      // At t0+25h the hydrated entry expires based on the ORIGINAL
      // timestamp; re-stamping at hydration time would have kept it alive.
      current = current.add(const Duration(hours: 2));
      expect(OpengraphCache.get('https://age.example.com'), isNull);
    });

    test('loadPersisted bails out when caching is disabled', () async {
      OpengraphCache.put('https://disabled.example.com', _entity('T'));
      await _flush();
      OpengraphCache.clear(memoryOnly: true);
      final readsBefore = store.reads;
      OpengraphCache.enabled = false;

      final result =
          await OpengraphCache.loadPersisted('https://disabled.example.com');

      expect(result, isNull);
      // It returns before even touching the store.
      expect(store.reads, readsBefore);
    });

    test('concurrent calls share a single store read', () async {
      var networkCalls = 0;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            networkCalls++;
            return http.Response('<html></html>', 200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      OpengraphCache.put('https://shared.example.com', _entity('Shared'));
      await _flush();
      OpengraphCache.clear(memoryOnly: true);
      final readsBefore = store.reads;

      final results = await Future.wait([
        opengraph_fetch('https://shared.example.com'),
        opengraph_fetch('https://shared.example.com'),
        opengraph_fetch('https://shared.example.com'),
      ]);

      expect(store.reads, readsBefore + 1);
      expect(networkCalls, 0);
      expect(results.every((e) => e!.title == 'Shared'), isTrue);
    });

    test('concurrent misses share one read and one network call', () async {
      var networkCalls = 0;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            networkCalls++;
            return http.Response(
                '<html><head><meta property="og:title" content="Net">'
                '</head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      final results = await Future.wait([
        opengraph_fetch('https://miss.example.com'),
        opengraph_fetch('https://miss.example.com'),
      ]);

      expect(store.reads, 1);
      expect(networkCalls, 1);
      expect(results.every((e) => e!.title == 'Net'), isTrue);
    });

    test('a hanging store read is bounded by storeTimeout', () async {
      OpengraphCache.storeTimeout = const Duration(milliseconds: 50);
      OpengraphCache.store = _HangingStore();
      var networkCalls = 0;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            networkCalls++;
            return http.Response(
                '<html><head><meta property="og:title" content="Rescued">'
                '</head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      // Without the bound this would never resolve and would poison the
      // in-flight map for the URL.
      final entity = await opengraph_fetch('https://hang.example.com');

      expect(entity!.title, 'Rescued');
      expect(networkCalls, 1);
    });

    test('a late hydration never clobbers a fresher direct put', () async {
      var current = DateTime(2026, 1, 1);
      OpengraphCache.clock = () => current;
      final slowStore = _SnapshotSlowStore();
      OpengraphCache.store = slowStore;

      // Persist the OLD entry, then clear memory.
      slowStore.entries['https://race.example.com'] = OpengraphCacheEntry(
          entity: _entity('Old persisted'), storedAt: current);

      final pending = OpengraphCache.loadPersisted('https://race.example.com');
      // While the slow read is in flight, a fresher entity lands in memory.
      current = current.add(const Duration(minutes: 1));
      OpengraphCache.put('https://race.example.com', _entity('Fresh put'));

      final loaded = await pending;

      expect(loaded!.title, 'Fresh put');
      expect(
          OpengraphCache.get('https://race.example.com')!.title, 'Fresh put');
    });

    test('loadPersisted honors a per-call maxAge', () async {
      var current = DateTime(2026, 1, 1);
      OpengraphCache.clock = () => current;
      OpengraphCache.ttl = null; // never stale globally

      OpengraphCache.put('https://maxage.example.com', _entity('T'));
      await _flush();
      OpengraphCache.clear(memoryOnly: true);
      current = current.add(const Duration(hours: 2));

      final hit =
          await OpengraphCache.loadPersisted('https://maxage.example.com');
      expect(hit, isNotNull);

      OpengraphCache.clear(memoryOnly: true);
      final miss = await OpengraphCache.loadPersisted(
          'https://maxage.example.com',
          maxAge: const Duration(hours: 1));
      expect(miss, isNull);
    });
  });

  group('store failures never break fetching', () {
    test('a throwing store falls back to the network', () async {
      store.failing = true;
      var networkCalls = 0;
      OpengraphFetch.clientFactory = () => MockClient((request) async {
            networkCalls++;
            return http.Response(
                '<html><head><meta property="og:title" content="Network">'
                '</head></html>',
                200,
                headers: {'content-type': 'text/html; charset=utf-8'});
          });

      // The fetch succeeds even though read() and write() both throw.
      final entity = await opengraph_fetch('https://broken-store.example.com');
      await _flush();

      expect(networkCalls, 1);
      expect(entity!.title, 'Network');
    });

    test('evict and clear ignore a throwing store', () async {
      store.failing = true;

      expect(() => OpengraphCache.evict('https://a.com'), returnsNormally);
      expect(OpengraphCache.clear, returnsNormally);
      await _flush();
    });

    test('synchronously-throwing store methods are survived too', () async {
      OpengraphCache.store = _SyncThrowingStore();

      expect(() => OpengraphCache.put('https://a.com', _entity('T')),
          returnsNormally);
      expect(() => OpengraphCache.evict('https://a.com'), returnsNormally);
      expect(OpengraphCache.clear, returnsNormally);
      await _flush();
    });
  });
}
