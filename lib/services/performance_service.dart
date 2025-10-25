import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Performance optimization service for Flutter Diacare app
/// Handles caching, lazy loading, image optimization, and memory management
class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Cache managers for different data types
  late final CacheManager _imageCache;
  late final CacheManager _dataCache;
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};

  // Performance metrics
  final Map<String, Duration> _operationTimings = {};
  final List<String> _performanceLogs = [];

  // Memory management
  Timer? _memoryCleanupTimer;
  static const int _maxMemoryCacheSize = 50; // MB
  static const Duration _cacheExpiration = Duration(hours: 1);

  /// Initialize the performance service
  Future<void> initialize() async {
    try {
      // Initialize image cache with optimized settings
      _imageCache = CacheManager(
        Config(
          'diacare_images',
          stalePeriod: const Duration(days: 7),
          maxNrOfCacheObjects: 200,
          repo: JsonCacheInfoRepository(databaseName: 'diacare_images'),
        ),
      );

      // Initialize data cache for API responses and Firestore data
      _dataCache = CacheManager(
        Config(
          'diacare_data',
          stalePeriod: const Duration(hours: 4),
          maxNrOfCacheObjects: 100,
          repo: JsonCacheInfoRepository(databaseName: 'diacare_data'),
        ),
      );

      // Start memory cleanup timer
      _startMemoryCleanup();

      _log('PerformanceService initialized successfully');
    } catch (e) {
      _log('Error initializing PerformanceService: $e');
      rethrow;
    }
  }

  /// Start memory cleanup timer
  void _startMemoryCleanup() {
    _memoryCleanupTimer?.cancel();
    _memoryCleanupTimer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => _cleanupMemoryCache(),
    );
  }

  /// Clean up expired memory cache entries
  void _cleanupMemoryCache() {
    final now = DateTime.now();
    final keysToRemove = <String>[];

    for (final entry in _cacheTimestamps.entries) {
      if (now.difference(entry.value) > _cacheExpiration) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      _log('Cleaned up ${keysToRemove.length} expired cache entries');
    }
  }

  /// Cache data in memory with expiration
  void cacheInMemory(String key, dynamic data) {
    _memoryCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();

    // Check memory usage and cleanup if needed
    if (_memoryCache.length > _maxMemoryCacheSize) {
      _cleanupOldestEntries();
    }
  }

  /// Get cached data from memory
  T? getCachedData<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null) return null;

    if (DateTime.now().difference(timestamp) > _cacheExpiration) {
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }

    return _memoryCache[key] as T?;
  }

  /// Clean up oldest cache entries when memory limit is reached
  void _cleanupOldestEntries() {
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final entriesToRemove = sortedEntries.take(10);
    for (final entry in entriesToRemove) {
      _memoryCache.remove(entry.key);
      _cacheTimestamps.remove(entry.key);
    }
  }

  /// Optimize image for display
  Future<Uint8List> optimizeImage(
    Uint8List imageData, {
    int? targetWidth,
    int? targetHeight,
    int quality = 85,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // For web platform, return original data as image optimization
      // libraries may not be available
      if (kIsWeb) {
        stopwatch.stop();
        _recordOperation('optimizeImage_web', stopwatch.elapsed);
        return imageData;
      }

      // On mobile platforms, we could use image processing libraries
      // For now, return the original data
      // TODO: Implement actual image compression using image library

      stopwatch.stop();
      _recordOperation('optimizeImage', stopwatch.elapsed);
      return imageData;
    } catch (e) {
      stopwatch.stop();
      _log('Error optimizing image: $e');
      return imageData;
    }
  }

  /// Cache Firestore document data
  Future<void> cacheFirestoreDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    final key = 'firestore_${collection}_$documentId';
    final jsonData = data.toString();

    try {
      await _dataCache.putFile(
        key,
        Uint8List.fromList(jsonData.codeUnits),
        maxAge: const Duration(hours: 2),
      );

      // Also cache in memory for faster access
      cacheInMemory(key, data);
    } catch (e) {
      _log('Error caching Firestore document: $e');
    }
  }

  /// Get cached Firestore document
  Future<Map<String, dynamic>?> getCachedFirestoreDocument(
    String collection,
    String documentId,
  ) async {
    final key = 'firestore_${collection}_$documentId';

    // First check memory cache
    final memoryData = getCachedData<Map<String, dynamic>>(key);
    if (memoryData != null) {
      return memoryData;
    }

    // Then check file cache
    try {
      final file = await _dataCache.getFileFromCache(key);
      if (file?.file != null) {
        final content = await file!.file.readAsString();
        // TODO: Implement proper JSON parsing for cached Firestore data
        _log('Retrieved cached Firestore document: $key');
        return null; // Placeholder for actual implementation
      }
    } catch (e) {
      _log('Error retrieving cached Firestore document: $e');
    }

    return null;
  }

  /// Preload critical app data
  Future<void> preloadCriticalData() async {
    final stopwatch = Stopwatch()..start();

    try {
      // Preload user profile data
      await _preloadUserData();

      // Preload recent appointments
      await _preloadRecentAppointments();

      // Preload notification preferences
      await _preloadNotificationSettings();

      stopwatch.stop();
      _recordOperation('preloadCriticalData', stopwatch.elapsed);
      _log('Critical data preloaded successfully');
    } catch (e) {
      stopwatch.stop();
      _log('Error preloading critical data: $e');
    }
  }

  /// Preload user data
  Future<void> _preloadUserData() async {
    // Implementation would fetch and cache user profile data
    // This is a placeholder for the actual implementation
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Preload recent appointments
  Future<void> _preloadRecentAppointments() async {
    // Implementation would fetch and cache recent appointments
    // This is a placeholder for the actual implementation
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Preload notification settings
  Future<void> _preloadNotificationSettings() async {
    // Implementation would fetch and cache notification preferences
    // This is a placeholder for the actual implementation
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Get image cache manager
  CacheManager get imageCache => _imageCache;

  /// Get data cache manager
  CacheManager get dataCache => _dataCache;

  /// Clear all caches
  Future<void> clearAllCaches() async {
    try {
      await _imageCache.emptyCache();
      await _dataCache.emptyCache();
      _memoryCache.clear();
      _cacheTimestamps.clear();
      _log('All caches cleared successfully');
    } catch (e) {
      _log('Error clearing caches: $e');
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'memoryCache': {
        'entries': _memoryCache.length,
        'maxSize': _maxMemoryCacheSize,
      },
      'performance': {
        'operationTimings': _operationTimings,
        'logs': _performanceLogs.take(20).toList(), // Last 20 logs
      },
      'cacheExpiration': _cacheExpiration.inMinutes,
    };
  }

  /// Record operation timing for performance monitoring
  void _recordOperation(String operation, Duration duration) {
    _operationTimings[operation] = duration;
    _log('Operation $operation completed in ${duration.inMilliseconds}ms');
  }

  /// Log performance events
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _performanceLogs.add('[$timestamp] $message');

    // Keep only last 50 logs to prevent memory leaks
    if (_performanceLogs.length > 50) {
      _performanceLogs.removeRange(0, _performanceLogs.length - 50);
    }

    if (kDebugMode) {
      print('[PerformanceService] $message');
    }
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'operationTimings': Map<String, int>.fromEntries(
        _operationTimings.entries.map(
          (e) => MapEntry(e.key, e.value.inMilliseconds),
        ),
      ),
      'cacheStats': getCacheStats(),
      'memoryUsage': {
        'entriesCount': _memoryCache.length,
        'maxEntries': _maxMemoryCacheSize,
      },
    };
  }

  /// Dispose resources
  void dispose() {
    _memoryCleanupTimer?.cancel();
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _performanceLogs.clear();
    _operationTimings.clear();
  }
}

/// Extension for performance monitoring on any Future
extension PerformanceFuture<T> on Future<T> {
  /// Monitor the performance of a Future operation
  Future<T> withPerformanceMonitoring(
    String operationName, {
    Map<String, String>? attributes,
  }) async {
    final trace = FirebasePerformance.instance.newTrace(operationName);
    await trace.start();
    attributes?.forEach((key, value) {
      trace.putAttribute(key, value);
    });

    try {
      final result = await this;
      await trace.stop();
      return result;
    } catch (e) {
      await trace.stop();
      rethrow;
    }
  }
}
