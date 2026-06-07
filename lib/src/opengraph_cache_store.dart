import 'package:opengraph/src/models/open_graph_entity.dart';

/// A cached entity together with the moment it was stored, as exchanged
/// with an [OpengraphCacheStore]. Serializable, so stores can persist it
/// as JSON.
class OpengraphCacheEntry {
  /// The cached entity.
  final OpenGraphEntity entity;

  /// When the entity was fetched; freshness is validated against
  /// `OpengraphCache.ttl` (or a per-call `maxAge`) on every read.
  final DateTime storedAt;

  const OpengraphCacheEntry({required this.entity, required this.storedAt});

  /// Tolerant of corrupt persisted JSON: a non-map entity decodes to an
  /// empty entity and a non-int timestamp to the epoch, which any TTL
  /// marks as stale so the bad key gets dropped from the store.
  factory OpengraphCacheEntry.fromJson(Map<String, dynamic> json) {
    final entity = json['entity'];
    final storedAt = json['storedAt'];
    return OpengraphCacheEntry(
      entity: OpenGraphEntity.fromJson(
          entity is Map ? Map<String, dynamic>.from(entity) : const {}),
      storedAt:
          DateTime.fromMillisecondsSinceEpoch(storedAt is int ? storedAt : 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'entity': entity.toJson(),
        'storedAt': storedAt.millisecondsSinceEpoch,
      };
}

/// Pluggable persistence for `OpengraphCache`, so previews survive app
/// restarts instead of living only in memory.
///
/// The package ships no storage dependency: implement this interface over
/// whatever your app already uses (shared_preferences, hive, sqflite, a
/// file…) and assign it to `OpengraphCache.store`. Keys are normalized
/// URLs. Writes happen fire-and-forget after a successful fetch; reads
/// happen on memory misses before hitting the network. Any error thrown
/// by a store is swallowed — a broken store never breaks fetching.
abstract class OpengraphCacheStore {
  /// Returns the persisted entry for [url], or null when absent.
  Future<OpengraphCacheEntry?> read(String url);

  /// Persists [entry] for [url], overwriting any previous value.
  Future<void> write(String url, OpengraphCacheEntry entry);

  /// Removes the entry for [url], if any.
  Future<void> delete(String url);

  /// Removes every entry.
  Future<void> clear();
}
