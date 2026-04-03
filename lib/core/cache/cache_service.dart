import 'package:hive_flutter/hive_flutter.dart';

/// Service for caching data locally
class CacheService {
  static late Box _cacheBox;

  /// Initialize Hive and open cache box
  static Future<void> init() async {
    await Hive.initFlutter();
    _cacheBox = await Hive.openBox('app_cache');
  }

  /// Cache data with a key
  Future<void> cacheData(String key, dynamic data) async {
    await _cacheBox.put(key, {
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Get cached data by key
  /// Returns null if not found or expired
  T? getCachedData<T>(String key, {Duration? maxAge}) {
    final cached = _cacheBox.get(key);
    if (cached == null) return null;

    // Check if cache has expired
    if (maxAge != null) {
      final timestamp = DateTime.parse(cached['timestamp'] as String);
      if (DateTime.now().difference(timestamp) > maxAge) {
        return null; // Cache expired
      }
    }

    return cached['data'] as T?;
  }

  /// Check if cache exists for a key
  bool hasCache(String key) {
    return _cacheBox.containsKey(key);
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _cacheBox.clear();
  }

  /// Delete specific cache entry
  Future<void> deleteCache(String key) async {
    await _cacheBox.delete(key);
  }

  // ======================
  // Offline write queue
  // ======================

  static const _offlineQueueKey = 'offline_write_queue';

  Future<void> addPendingWrite(Map<String, dynamic> request) async {
    final existing = _cacheBox.get(_offlineQueueKey);
    final queue = existing is List
        ? List<Map<String, dynamic>>.from(existing)
        : <Map<String, dynamic>>[];
    queue.add(request);
    await _cacheBox.put(_offlineQueueKey, queue);
  }

  List<Map<String, dynamic>> getPendingWrites() {
    final existing = _cacheBox.get(_offlineQueueKey);
    if (existing is List) {
      return List<Map<String, dynamic>>.from(existing);
    }
    return <Map<String, dynamic>>[];
  }

  Future<void> clearPendingWrites() async {
    await _cacheBox.delete(_offlineQueueKey);
  }

  Future<void> removePendingWriteAt(int index) async {
    final queue = getPendingWrites();
    if (index < 0 || index >= queue.length) return;
    queue.removeAt(index);
    if (queue.isEmpty) {
      await _cacheBox.delete(_offlineQueueKey);
    } else {
      await _cacheBox.put(_offlineQueueKey, queue);
    }
  }
}
