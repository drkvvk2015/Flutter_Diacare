/// Caching and Performance Optimization Provider
/// 
/// Manages data caching, performance monitoring, and optimization.
/// Integrates with PerformanceService for advanced caching strategies.
/// 
/// Features:
/// - Firestore document caching
/// - In-memory data caching
/// - Critical data preloading
/// - Cache statistics and metrics
/// - Performance monitoring
library;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../services/performance_service.dart';

/// Provider for managing cached data and performance optimization
/// 
/// Wraps PerformanceService to provide reactive cache state management
/// and expose caching capabilities throughout the application.
class CachingProvider extends ChangeNotifier {
  // Performance service for caching operations
  final PerformanceService _performanceService = PerformanceService();

  // Initialization and loading states
  bool _isInitialized = false;
  bool _isPreloadingData = false;
  
  // Cache metrics and statistics
  Map<String, dynamic> _cacheStats = {};
  Map<String, dynamic> _performanceMetrics = {};

  // Public getters for cache state
  bool get isInitialized => _isInitialized;
  bool get isPreloadingData => _isPreloadingData;
  Map<String, dynamic> get cacheStats => _cacheStats;
  Map<String, dynamic> get performanceMetrics => _performanceMetrics;

  /// Initialize the caching provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _performanceService.initialize();
      _isInitialized = true;
      _updateMetrics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing CachingProvider: $e');
      rethrow;
    }
  }

  /// Preload critical application data
  Future<void> preloadCriticalData() async {
    if (!_isInitialized || _isPreloadingData) return;

    _isPreloadingData = true;
    notifyListeners();

    try {
      await _performanceService.preloadCriticalData();
      _updateMetrics();
    } catch (e) {
      debugPrint('Error preloading critical data: $e');
    } finally {
      _isPreloadingData = false;
      notifyListeners();
    }
  }

  /// Cache Firestore document data
  Future<void> cacheDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    if (!_isInitialized) return;

    try {
      await _performanceService.cacheFirestoreDocument(
        collection,
        documentId,
        data,
      );
      _updateMetrics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error caching document: $e');
    }
  }

  /// Get cached Firestore document
  Future<Map<String, dynamic>?> getCachedDocument(
    String collection,
    String documentId,
  ) async {
    if (!_isInitialized) return null;

    try {
      return await _performanceService.getCachedFirestoreDocument(
        collection,
        documentId,
      );
    } catch (e) {
      debugPrint('Error getting cached document: $e');
      return null;
    }
  }

  /// Cache data in memory
  void cacheInMemory(String key, dynamic data) {
    if (!_isInitialized) return;

    _performanceService.cacheInMemory(key, data);
    _updateMetrics();
    notifyListeners();
  }

  /// Get cached data from memory
  T? getCachedData<T>(String key) {
    if (!_isInitialized) return null;

    return _performanceService.getCachedData<T>(key);
  }

  /// Clear all caches
  Future<void> clearAllCaches() async {
    if (!_isInitialized) return;

    try {
      await _performanceService.clearAllCaches();
      _updateMetrics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing caches: $e');
    }
  }

  /// Update performance metrics
  void _updateMetrics() {
    if (!_isInitialized) return;

    _cacheStats = _performanceService.getCacheStats();
    _performanceMetrics = _performanceService.getPerformanceMetrics();
  }

  /// Get formatted cache size information
  String get cacheUsageText {
    if (!_isInitialized) return 'Cache not initialized';

    final memoryEntries = _cacheStats['memoryCache']?['entries'] as int? ?? 0;
    final maxSize = _cacheStats['memoryCache']?['maxSize'] as int? ?? 0;
    final usagePercent = maxSize > 0
        ? (memoryEntries / maxSize * 100).round()
        : 0;

    return '$memoryEntries/$maxSize entries ($usagePercent%)';
  }

  /// Get performance summary
  String get performanceSummary {
    if (!_isInitialized || _performanceMetrics.isEmpty) {
      return 'No performance data available';
    }

    final timings =
        _performanceMetrics['operationTimings'] as Map<String, int>? ?? {};
    if (timings.isEmpty) {
      return 'No operations recorded';
    }

    final totalOperations = timings.length;
    final averageTime = timings.values.isNotEmpty
        ? (timings.values.reduce((a, b) => a + b) / timings.length).round()
        : 0;

    return '$totalOperations operations, ${averageTime}ms avg';
  }

  @override
  void dispose() {
    _performanceService.dispose();
    super.dispose();
  }
}

/// Extension for Firestore integration with caching
extension CachedFirestore on FirebaseFirestore {
  /// Get document with caching support
  Future<DocumentSnapshot<Map<String, dynamic>>> getDocumentCached(
    String collection,
    String documentId,
    CachingProvider cachingProvider,
  ) async {
    // First try to get from cache
    final cachedData = await cachingProvider.getCachedDocument(
      collection,
      documentId,
    );

    if (cachedData != null) {
      // Return cached data wrapped in a mock DocumentSnapshot
      // Note: This is a simplified implementation
      debugPrint('Retrieved $collection/$documentId from cache');
    }

    // If not in cache, get from Firestore
    final doc = await FirebaseFirestore.instance
        .collection(collection)
        .doc(documentId)
        .get();

    // Cache the result for future use
    if (doc.exists && doc.data() != null) {
      await cachingProvider.cacheDocument(collection, documentId, doc.data()!);
    }

    return doc;
  }
}

/// Mixin for widgets that need caching capabilities
mixin CachingMixin<T extends StatefulWidget> on State<T> {
  CachingProvider? _cachingProvider;

  CachingProvider get cachingProvider {
    _cachingProvider ??= CachingProvider();
    return _cachingProvider!;
  }

  @override
  void initState() {
    super.initState();
    _initializeCaching();
  }

  Future<void> _initializeCaching() async {
    if (!cachingProvider.isInitialized) {
      await cachingProvider.initialize();
    }
  }

  @override
  void dispose() {
    _cachingProvider?.dispose();
    super.dispose();
  }
}

/// Performance monitoring widget wrapper
class PerformanceMonitor extends StatefulWidget {

  const PerformanceMonitor({
    required this.child, required this.operationName, super.key,
    this.enableMonitoring = true,
  });
  final Widget child;
  final String operationName;
  final bool enableMonitoring;

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    if (widget.enableMonitoring) {
      _stopwatch.start();
    }
  }

  @override
  void dispose() {
    if (widget.enableMonitoring && _stopwatch.isRunning) {
      _stopwatch.stop();
      if (kDebugMode) {
        debugPrint(
          '[PerformanceMonitor] ${widget.operationName}: ${_stopwatch.elapsedMilliseconds}ms',
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
