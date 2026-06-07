// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:opengraph/src/models/open_graph_entity.dart';
import 'package:opengraph/src/adapters/opengraph_metadata_adapter.dart';
import 'package:opengraph/src/opengraph_cache_store.dart';
import 'package:opengraph/src/opengraph_fetch_base.dart';
import 'package:opengraph/src/utils/util.dart';

/// A cached entity together with the moment it was stored, so entries can
/// expire (see [OpengraphCache.ttl]).
class _CacheEntry {
  _CacheEntry(this.entity, this.storedAt);

  final OpenGraphEntity entity;
  final DateTime storedAt;
}

/// In-memory cache for [opengraph_fetch] results.
///
/// Successfully fetched entities are cached by URL so repeated calls — for
/// example widgets rebuilding inside scrollable lists — do not trigger a new
/// network request. Failed fetches are NOT cached, so transient network
/// errors recover on the next attempt.
///
/// Keys are normalized URLs: `www.example.com` and
/// `https://www.example.com` address the same entry in [get], [put] and
/// [evict].
class OpengraphCache {
  OpengraphCache._();

  static final Map<String, _CacheEntry> _entries = {};

  /// All entry points normalize their key, so callers can pass the same
  /// string they gave to [opengraph_fetch], scheme-less or not.
  static String _key(String url) => normalizeUrl(url) ?? url;

  /// Maximum number of cached entries. The oldest entries are evicted first.
  static int maxEntries = 200;

  /// Whether caching is enabled.
  static bool enabled = true;

  /// How long a cached entry stays fresh. Stale entries are evicted on
  /// access, forcing a refetch. Set to null to keep entries for the whole
  /// session.
  static Duration? ttl = const Duration(hours: 24);

  /// Clock used to timestamp entries; replaceable in tests to simulate the
  /// passage of time without waiting.
  static DateTime Function() clock = DateTime.now;

  /// Optional persistent layer, so previews survive app restarts. Memory
  /// stays the source of truth: [put]/[evict]/[clear] write through to the
  /// store fire-and-forget, and `opengraph_fetch` consults it on memory
  /// misses before hitting the network. Errors thrown by the store are
  /// swallowed — a broken store never breaks fetching.
  static OpengraphCacheStore? store;

  /// Maximum time to wait for [store] reads before falling through to the
  /// network, so a hanging store can never freeze a fetch.
  static Duration storeTimeout = const Duration(seconds: 5);

  /// Runs a store [action] fire-and-forget, ignoring sync and async errors.
  static void _storeGuard(Future<void> Function() action) {
    try {
      unawaited(action().catchError((Object _) {}));
    } catch (_) {
      // Synchronous store errors are ignored too.
    }
  }

  /// Number of entries currently cached.
  static int get length => _entries.length;

  /// Returns the cached entity for [url], or null when it is absent or
  /// older than [maxAge] (which defaults to [ttl]).
  static OpenGraphEntity? get(String url, {Duration? maxAge}) {
    if (!enabled) return null;
    final key = _key(url);
    final entry = _entries[key];
    if (entry == null) return null;
    final limit = maxAge ?? ttl;
    if (limit != null && clock().difference(entry.storedAt) > limit) {
      _entries.remove(key);
      return null;
    }
    return entry.entity;
  }

  /// Stores an [entity] for [url], evicting the oldest entries if needed,
  /// and writes through to [store] when one is configured.
  static void put(String url, OpenGraphEntity entity) {
    if (!enabled) return;
    final key = _key(url);
    final storedAt = clock();
    // Re-inserting moves the key to the end, keeping eviction LRU-like.
    _entries.remove(key);
    _entries[key] = _CacheEntry(entity, storedAt);
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    final s = store;
    if (s != null) {
      _storeGuard(() => s.write(
          key, OpengraphCacheEntry(entity: entity, storedAt: storedAt)));
    }
  }

  /// Removes a single [url] from the cache (memory and [store]).
  static void evict(String url) {
    final key = _key(url);
    _entries.remove(key);
    final s = store;
    if (s != null) _storeGuard(() => s.delete(key));
  }

  /// Clears all cached entries. Pass [memoryOnly] to free memory while
  /// keeping the persisted entries in [store].
  static void clear({bool memoryOnly = false}) {
    _entries.clear();
    if (memoryOnly) return;
    final s = store;
    if (s != null) _storeGuard(s.clear);
  }

  /// Looks [url] up in [store], validates its freshness against [maxAge]
  /// (defaults to [ttl]) and hydrates the in-memory cache on a hit. Stale
  /// entries are deleted from the store. Used by `opengraph_fetch` on
  /// memory misses, inside the in-flight deduplication.
  ///
  /// The read is bounded by [storeTimeout]; a slow or hanging store falls
  /// through to the network like any other store error. Note an [evict] or
  /// [clear] racing an in-flight read may be undone by the hydration.
  static Future<OpenGraphEntity?> loadPersisted(String url,
      {Duration? maxAge}) async {
    final s = store;
    if (!enabled || s == null) return null;
    final key = _key(url);
    OpengraphCacheEntry? entry;
    try {
      final read = s.read(key);
      // If the timeout below fires, the abandoned read must not surface a
      // late error as uncaught.
      read.ignore();
      entry = await read.timeout(storeTimeout);
    } catch (_) {
      return null;
    }
    if (entry == null) return null;
    final limit = maxAge ?? ttl;
    if (limit != null && clock().difference(entry.storedAt) > limit) {
      _storeGuard(() => s.delete(key));
      return null;
    }
    // Something fresher may have landed in memory while the read was in
    // flight (a direct put); never clobber it with older persisted data.
    final existing = _entries[key];
    if (existing != null && !entry.storedAt.isAfter(existing.storedAt)) {
      return existing.entity;
    }
    // Hydrate memory keeping the original timestamp, without writing the
    // entry back to the store.
    _entries.remove(key);
    _entries[key] = _CacheEntry(entry.entity, entry.storedAt);
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
    return entry.entity;
  }
}

/// In-flight requests, deduplicated by URL: concurrent calls for the same
/// URL share a single network request.
final Map<String, Future<OpenGraphEntity?>> _inFlight = {};

/// Fetch OpenGraph data from a URL and return it as an [OpenGraphEntity]
///
/// This is the main entry point for the opengraph_fetch functionality.
/// The URL is normalized first (a missing scheme gets `https://` prepended)
/// and used as the cache key. Results are cached in memory (see
/// [OpengraphCache]) and concurrent requests for the same URL are
/// deduplicated — note the deduplication is keyed by URL only, so
/// concurrent calls with different [headers] or [timeout] share the first
/// request and its options.
///
/// [headers] are merged over [OpengraphFetch.requestHeaders] and [timeout]
/// overrides [OpengraphFetch.timeout], both for this call only.
/// [maxAge] overrides [OpengraphCache.ttl] for this lookup, e.g. pass
/// [Duration.zero] to force a refetch — note it only bypasses the cache: a
/// request for the same URL already in flight is still shared, not
/// restarted.
///
/// When [OpengraphCache.store] is configured, memory misses are looked up
/// there (with the same freshness rules) before hitting the network.
///
/// By default network failures return a fallback entity built from the URL
/// (same behavior as previous versions). Pass [throwOnError] to propagate
/// fetch errors to the caller instead.
Future<OpenGraphEntity?> opengraph_fetch(String url,
    {bool throwOnError = false,
    Map<String, String>? headers,
    Duration? maxAge,
    Duration? timeout}) {
  final target = normalizeUrl(url) ?? url;
  final cached = OpengraphCache.get(target, maxAge: maxAge);
  if (cached != null) return Future.value(cached);

  final future = _inFlight[target] ??= _fetchAndCache(target,
      headers: headers, maxAge: maxAge, timeout: timeout);
  if (throwOnError) return future;
  return future.catchError((Object _) => _fallbackEntity(target));
}

Future<OpenGraphEntity?> _fetchAndCache(String url,
    {Map<String, String>? headers, Duration? maxAge, Duration? timeout}) async {
  try {
    // The persistent layer answers before the network does; sharing this
    // lookup through _inFlight keeps concurrent callers on one read.
    final persisted = await OpengraphCache.loadPersisted(url, maxAge: maxAge);
    if (persisted != null) return persisted;

    final metadata = await OpengraphFetch.extract(url,
        throwOnError: true, headers: headers, timeout: timeout);
    if (metadata == null) return null;
    final entity = OpengraphMetadataAdapter.toOpenGraphEntity(metadata);
    OpengraphCache.put(url, entity);
    return entity;
  } finally {
    _inFlight.remove(url);
  }
}

/// Same defaults [OpengraphFetch.extract] used to return on fetch errors:
/// the domain as title and the URL itself as description.
OpenGraphEntity _fallbackEntity(String url) {
  final normalized = normalizeUrl(url) ?? url;
  return OpenGraphEntity(
    title: getDomain(normalized) ?? normalized,
    description: normalized,
    image: '',
    url: normalized,
    locale: 'en_US',
    type: 'website',
    siteName: '',
  );
}

/// Fetch OpenGraph data from a URL and return the raw metadata
///
/// This is provided for compatibility with the old API
Future<dynamic> opengraph_fetch_raw(String url) async {
  return await OpengraphFetch.extract(url);
}
