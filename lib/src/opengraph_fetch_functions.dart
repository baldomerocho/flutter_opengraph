// ignore_for_file: non_constant_identifier_names

import 'package:opengraph/src/models/open_graph_entity.dart';
import 'package:opengraph/src/adapters/opengraph_metadata_adapter.dart';
import 'package:opengraph/src/opengraph_fetch_base.dart';
import 'package:opengraph/src/utils/util.dart';

/// In-memory cache for [opengraph_fetch] results.
///
/// Successfully fetched entities are cached by URL so repeated calls — for
/// example widgets rebuilding inside scrollable lists — do not trigger a new
/// network request. Failed fetches are NOT cached, so transient network
/// errors recover on the next attempt.
class OpengraphCache {
  OpengraphCache._();

  static final Map<String, OpenGraphEntity> _entries = {};

  /// Maximum number of cached entries. The oldest entries are evicted first.
  static int maxEntries = 200;

  /// Whether caching is enabled.
  static bool enabled = true;

  /// Number of entries currently cached.
  static int get length => _entries.length;

  /// Returns the cached entity for [url], or null if not cached.
  static OpenGraphEntity? get(String url) => enabled ? _entries[url] : null;

  /// Stores an [entity] for [url], evicting the oldest entries if needed.
  static void put(String url, OpenGraphEntity entity) {
    if (!enabled) return;
    // Re-inserting moves the key to the end, keeping eviction LRU-like.
    _entries.remove(url);
    _entries[url] = entity;
    while (_entries.length > maxEntries) {
      _entries.remove(_entries.keys.first);
    }
  }

  /// Removes a single [url] from the cache.
  static void evict(String url) => _entries.remove(url);

  /// Clears all cached entries.
  static void clear() => _entries.clear();
}

/// In-flight requests, deduplicated by URL: concurrent calls for the same
/// URL share a single network request.
final Map<String, Future<OpenGraphEntity?>> _inFlight = {};

/// Fetch OpenGraph data from a URL and return it as an [OpenGraphEntity]
///
/// This is the main entry point for the opengraph_fetch functionality.
/// Results are cached in memory (see [OpengraphCache]) and concurrent
/// requests for the same URL are deduplicated.
///
/// By default network failures return a fallback entity built from the URL
/// (same behavior as previous versions). Pass [throwOnError] to propagate
/// fetch errors to the caller instead.
Future<OpenGraphEntity?> opengraph_fetch(String url,
    {bool throwOnError = false}) {
  final cached = OpengraphCache.get(url);
  if (cached != null) return Future.value(cached);

  final future = _inFlight[url] ??= _fetchAndCache(url);
  if (throwOnError) return future;
  return future.catchError((Object _) => _fallbackEntity(url));
}

Future<OpenGraphEntity?> _fetchAndCache(String url) async {
  try {
    final metadata = await OpengraphFetch.extract(url, throwOnError: true);
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
  return OpenGraphEntity(
    title: getDomain(url) ?? url,
    description: url,
    image: '',
    url: url,
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
