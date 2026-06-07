// ignore_for_file: non_constant_identifier_names

import 'package:opengraph/src/models/open_graph_entity.dart';
import 'package:opengraph/src/adapters/opengraph_metadata_adapter.dart';
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

  /// Stores an [entity] for [url], evicting the oldest entries if needed.
  static void put(String url, OpenGraphEntity entity) {
    if (!enabled) return;
    final key = _key(url);
    // Re-inserting moves the key to the end, keeping eviction LRU-like.
    _entries.remove(key);
    _entries[key] = _CacheEntry(entity, clock());
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Removes a single [url] from the cache.
  static void evict(String url) => _entries.remove(_key(url));

  /// Clears all cached entries.
  static void clear() => _entries.clear();
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
/// concurrent calls with different [headers] share the first request.
///
/// [headers] are merged over [OpengraphFetch.requestHeaders] for this call.
/// [maxAge] overrides [OpengraphCache.ttl] for this lookup, e.g. pass
/// [Duration.zero] to force a refetch — note it only bypasses the cache: a
/// request for the same URL already in flight is still shared, not
/// restarted.
///
/// By default network failures return a fallback entity built from the URL
/// (same behavior as previous versions). Pass [throwOnError] to propagate
/// fetch errors to the caller instead.
Future<OpenGraphEntity?> opengraph_fetch(String url,
    {bool throwOnError = false,
    Map<String, String>? headers,
    Duration? maxAge}) {
  final target = normalizeUrl(url) ?? url;
  final cached = OpengraphCache.get(target, maxAge: maxAge);
  if (cached != null) return Future.value(cached);

  final future = _inFlight[target] ??= _fetchAndCache(target, headers: headers);
  if (throwOnError) return future;
  return future.catchError((Object _) => _fallbackEntity(target));
}

Future<OpenGraphEntity?> _fetchAndCache(String url,
    {Map<String, String>? headers}) async {
  try {
    final metadata =
        await OpengraphFetch.extract(url, throwOnError: true, headers: headers);
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
