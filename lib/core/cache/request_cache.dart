import 'dart:async';

/// In-memory TTL cache with in-flight request deduplication.
class RequestCache {
  RequestCache({this.defaultTtl = const Duration(minutes: 2)});

  final Duration defaultTtl;
  final _store = <String, _CacheEntry>{};
  final _inFlight = <String, Future<dynamic>>{};

  T? get<T>(String key) {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.expiresAt.isBefore(DateTime.now())) {
      _store.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  void put(String key, Object value, {Duration? ttl}) {
    _store[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl ?? defaultTtl),
    );
  }

  /// Returns cached value or runs [loader] once per key while in flight.
  Future<T> getOrLoad<T>(
    String key,
    Future<T> Function() loader, {
    Duration? ttl,
  }) async {
    final hit = get<T>(key);
    if (hit != null) return hit;

    final pending = _inFlight[key];
    if (pending != null) return pending as Future<T>;

    final future = loader().then((value) {
      put(key, value as Object, ttl: ttl);
      _inFlight.remove(key);
      return value;
    }).catchError((Object e, StackTrace st) {
      _inFlight.remove(key);
      Error.throwWithStackTrace(e, st);
    });

    _inFlight[key] = future;
    return future;
  }

  void invalidate(String key) => _store.remove(key);

  void clear() => _store.clear();
}

class _CacheEntry {
  _CacheEntry({required this.value, required this.expiresAt});
  final Object value;
  final DateTime expiresAt;
}

/// Global caches (session-scoped).
final propertyRequestCache = RequestCache(defaultTtl: const Duration(minutes: 3));
final placesRequestCache = RequestCache(defaultTtl: const Duration(minutes: 10));
