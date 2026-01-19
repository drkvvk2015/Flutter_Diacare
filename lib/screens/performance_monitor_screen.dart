import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/caching_provider.dart';
import '../widgets/optimized_widgets.dart';
import '../services/performance_service.dart';

/// Screen for monitoring and controlling app performance
class PerformanceMonitorScreen extends StatefulWidget {
  const PerformanceMonitorScreen({super.key});

  @override
  State<PerformanceMonitorScreen> createState() =>
      _PerformanceMonitorScreenState();
}

class _PerformanceMonitorScreenState extends State<PerformanceMonitorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PerformanceService _performanceService = PerformanceService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializePerformanceService();
  }

  Future<void> _initializePerformanceService() async {
    try {
      await _performanceService.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing performance service: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Monitor'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Cache Stats', icon: Icon(Icons.storage)),
            Tab(text: 'Performance', icon: Icon(Icons.speed)),
            Tab(text: 'Tools', icon: Icon(Icons.build)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCacheStatsTab(),
          _buildPerformanceTab(),
          _buildToolsTab(),
        ],
      ),
    );
  }

  Widget _buildCacheStatsTab() {
    return Consumer<CachingProvider>(
      builder: (context, cachingProvider, child) {
        if (!cachingProvider.isInitialized) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Initializing cache system...'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh cache stats
            setState(() {});
          },
          child: OptimizedListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCacheOverviewCard(cachingProvider),
              const SizedBox(height: 16),
              _buildMemoryCacheCard(cachingProvider),
              const SizedBox(height: 16),
              _buildImageCacheCard(),
              const SizedBox(height: 16),
              _buildDataCacheCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCacheOverviewCard(CachingProvider cachingProvider) {
    return OptimizedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                'Cache Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Memory Usage', cachingProvider.cacheUsageText),
          _buildStatRow(
            'Status',
            cachingProvider.isInitialized ? 'Active' : 'Inactive',
          ),
          _buildStatRow(
            'Preloading',
            cachingProvider.isPreloadingData ? 'In Progress' : 'Complete',
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryCacheCard(CachingProvider cachingProvider) {
    final cacheStats = cachingProvider.cacheStats;
    final memoryCache =
        cacheStats['memoryCache'] as Map<String, dynamic>? ?? {};

    return OptimizedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text(
                'Memory Cache',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Entries', '${memoryCache['entries'] ?? 0}'),
          _buildStatRow('Max Size', '${memoryCache['maxSize'] ?? 0}'),
          _buildStatRow(
            'Expiration',
            '${cacheStats['cacheExpiration'] ?? 0} minutes',
          ),
        ],
      ),
    );
  }

  Widget _buildImageCacheCard() {
    return OptimizedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, color: Colors.orange[600]),
              const SizedBox(width: 8),
              const Text(
                'Image Cache',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Status', 'Active'),
          _buildStatRow('Max Objects', '200'),
          _buildStatRow('Stale Period', '7 days'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _clearImageCache(),
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Image Cache'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[100],
              foregroundColor: Colors.orange[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCacheCard() {
    return OptimizedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.data_usage, color: Colors.purple[600]),
              const SizedBox(width: 8),
              const Text(
                'Data Cache',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Status', 'Active'),
          _buildStatRow('Max Objects', '100'),
          _buildStatRow('Stale Period', '4 hours'),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _clearDataCache(),
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Data Cache'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[100],
              foregroundColor: Colors.purple[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return Consumer<CachingProvider>(
      builder: (context, cachingProvider, child) {
        final metrics = cachingProvider.performanceMetrics;
        final timings = metrics['operationTimings'] as Map<String, int>? ?? {};

        return OptimizedListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildPerformanceSummaryCard(cachingProvider),
            const SizedBox(height: 16),
            _buildOperationTimingsCard(timings),
            const SizedBox(height: 16),
            _buildMemoryUsageCard(metrics),
          ],
        );
      },
    );
  }

  Widget _buildPerformanceSummaryCard(CachingProvider cachingProvider) {
    return OptimizedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                'Performance Summary',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            cachingProvider.performanceSummary,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _runPerformanceTest(),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Run Performance Test'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[100],
              foregroundColor: Colors.blue[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationTimingsCard(Map<String, int> timings) {
    return OptimizedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: Colors.green[600]),
              const SizedBox(width: 8),
              const Text(
                'Operation Timings',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (timings.isEmpty)
            const Text('No operations recorded yet.')
          else
            ...timings.entries
                .map(
                  (entry) => _buildStatRow(entry.key, '${entry.value}ms'),
                )
                ,
        ],
      ),
    );
  }

  Widget _buildMemoryUsageCard(Map<String, dynamic> metrics) {
    final memoryUsage = metrics['memoryUsage'] as Map<String, dynamic>? ?? {};

    return OptimizedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory, color: Colors.red[600]),
              const SizedBox(width: 8),
              const Text(
                'Memory Usage',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Entries Count', '${memoryUsage['entriesCount'] ?? 0}'),
          _buildStatRow('Max Entries', '${memoryUsage['maxEntries'] ?? 0}'),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _calculateMemoryUsagePercentage(memoryUsage),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.red[400]!),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_calculateMemoryUsagePercentage(memoryUsage) * 100).toStringAsFixed(1)}% used',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsTab() {
    return OptimizedListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCacheControlCard(),
        const SizedBox(height: 16),
        _buildPreloadingCard(),
        const SizedBox(height: 16),
        _buildOptimizationCard(),
      ],
    );
  }

  Widget _buildCacheControlCard() {
    return OptimizedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: Colors.blue[600]),
              const SizedBox(width: 8),
              const Text(
                'Cache Control',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _clearAllCaches(),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear All Caches'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[100],
                foregroundColor: Colors.red[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreloadingCard() {
    return Consumer<CachingProvider>(
      builder: (context, cachingProvider, child) {
        return OptimizedCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.download, color: Colors.green[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Data Preloading',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (cachingProvider.isPreloadingData)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Preloading critical data...'),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => cachingProvider.preloadCriticalData(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Preload Critical Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[100],
                      foregroundColor: Colors.green[800],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptimizationCard() {
    return OptimizedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Colors.purple[600]),
              const SizedBox(width: 8),
              const Text(
                'Optimization Tools',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Performance optimization features:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const _FeatureItem(
            icon: Icons.image_outlined,
            title: 'Image Optimization',
            description: 'Automatic image caching and compression',
            enabled: true,
          ),
          const _FeatureItem(
            icon: Icons.visibility,
            title: 'Lazy Loading',
            description: 'Load content only when visible',
            enabled: true,
          ),
          const _FeatureItem(
            icon: Icons.memory,
            title: 'Memory Management',
            description: 'Automatic cleanup of expired cache',
            enabled: true,
          ),
          const _FeatureItem(
            icon: Icons.speed,
            title: 'Performance Monitoring',
            description: 'Track operation timings and metrics',
            enabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  double _calculateMemoryUsagePercentage(Map<String, dynamic> memoryUsage) {
    final entries = memoryUsage['entriesCount'] as int? ?? 0;
    final maxEntries = memoryUsage['maxEntries'] as int? ?? 1;
    return maxEntries > 0 ? entries / maxEntries : 0.0;
  }

  Future<void> _clearImageCache() async {
    try {
      await _performanceService.imageCache.emptyCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image cache cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing image cache: $e')),
        );
      }
    }
  }

  Future<void> _clearDataCache() async {
    try {
      await _performanceService.dataCache.emptyCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data cache cleared successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error clearing data cache: $e')),
        );
      }
    }
  }

  Future<void> _clearAllCaches() async {
    try {
      await _performanceService.clearAllCaches();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All caches cleared successfully')),
        );
        setState(() {}); // Refresh the UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error clearing caches: $e')));
      }
    }
  }

  Future<void> _runPerformanceTest() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Running performance test...')),
      );

      // Simulate various operations for testing
      await _performanceService.preloadCriticalData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Performance test completed')),
        );
        setState(() {}); // Refresh metrics
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Performance test failed: $e')));
      }
    }
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool enabled;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    this.enabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: enabled ? Colors.green[600] : Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: enabled ? Colors.black : Colors.grey[600],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(
            enabled ? Icons.check_circle : Icons.circle_outlined,
            color: enabled ? Colors.green[600] : Colors.grey[400],
            size: 16,
          ),
        ],
      ),
    );
  }
}
