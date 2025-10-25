import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/analytics_service.dart';

/// Analytics monitoring screen showing comprehensive analytics data and controls
class AnalyticsMonitorScreen extends StatefulWidget {
  const AnalyticsMonitorScreen({super.key});

  @override
  State<AnalyticsMonitorScreen> createState() => _AnalyticsMonitorScreenState();
}

class _AnalyticsMonitorScreenState extends State<AnalyticsMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Track screen view
    _analyticsService.logScreenView('analytics_monitor');
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
        title: const Text(
          'Analytics Monitor',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Overview'),
            Tab(icon: Icon(Icons.event), text: 'Events'),
            Tab(icon: Icon(Icons.speed), text: 'Performance'),
            Tab(icon: Icon(Icons.settings), text: 'Tools'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildEventsTab(),
          _buildPerformanceTab(),
          _buildToolsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusCard(),
          const SizedBox(height: 16),
          _buildSummaryCard(),
          const SizedBox(height: 16),
          _buildSessionInfoCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Analytics Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _analyticsService.isInitialized
                        ? Colors.green
                        : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _analyticsService.isInitialized
                      ? 'Analytics Initialized'
                      : 'Analytics Not Initialized',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Session Duration: ${_formatDuration(_analyticsService.sessionDuration)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _analyticsService.getAnalyticsSummary();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Summary',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Session Duration',
              '${summary['session_duration_minutes']} minutes',
            ),
            _buildSummaryRow('Events Logged', '${summary['events_logged']}'),
            _buildSummaryRow(
              'Total Event Count',
              '${summary['total_event_count']}',
            ),
            _buildSummaryRow('Screens Viewed', '${summary['screens_viewed']}'),
            _buildSummaryRow(
              'Custom Events',
              '${summary['custom_events_count']}',
            ),
            _buildSummaryRow('Active Traces', '${summary['active_traces']}'),
            _buildSummaryRow(
              'Current Screen',
              summary['current_screen'] ?? 'None',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Information',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Text(
              'Current session started: ${DateTime.now().subtract(_analyticsService.sessionDuration).toString().split('.')[0]}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Analytics initialized: ${_analyticsService.isInitialized ? 'Yes' : 'No'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsTab() {
    final statistics = _analyticsService.getEventStatistics();
    final eventCounts = statistics['event_counts'] as Map<String, int>;
    final recentEvents = statistics['recent_events'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Counts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (eventCounts.isEmpty)
                    Text(
                      'No events logged yet',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...eventCounts.entries.map(
                      (entry) =>
                          _buildSummaryRow(entry.key, entry.value.toString()),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Events',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (recentEvents.isEmpty)
                    Text(
                      'No recent events',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    ...recentEvents.map(
                      (event) => Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(event['name']),
                          subtitle: Text(event['timestamp']),
                          trailing: event['parameters'] != null
                              ? const Icon(Icons.info_outline)
                              : null,
                          onTap: event['parameters'] != null
                              ? () => _showEventDetails(event)
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Performance Monitoring',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _testPerformanceTrace,
                    child: const Text('Test Performance Trace'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _testHttpMetric,
                    child: const Text('Test HTTP Metric'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _testCustomEvent,
                    child: const Text('Test Custom Event'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Screen Time Analytics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Screen time tracking is active. Each screen view is automatically tracked.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics Tools',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _flushAnalytics,
                      child: const Text('Flush Analytics Data'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _exportAnalyticsData,
                      child: const Text('Export Analytics Summary'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _testErrorReporting,
                      child: const Text('Test Error Reporting'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _setTestUserProperties(),
                      child: const Text('Set Test User Properties'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Analytics service is running in ${_analyticsService.isInitialized ? 'production' : 'development'} mode.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All analytics events are being tracked and sent to Firebase.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _testPerformanceTrace() async {
    try {
      _analyticsService.startTrace('test_performance_trace');

      // Simulate some work
      await Future.delayed(const Duration(seconds: 2));

      await _analyticsService.stopTrace(
        'test_performance_trace',
        attributes: {'test_type': 'manual', 'success': 'true'},
      );

      _showSnackBar('Performance trace completed successfully');
    } catch (e) {
      _showSnackBar('Error testing performance trace: $e');
    }
  }

  Future<void> _testHttpMetric() async {
    try {
      const url = 'https://httpbin.org/get';
      const method = 'GET';

      _analyticsService.startHttpMetric(url, method);

      // Simulate HTTP request
      await Future.delayed(const Duration(milliseconds: 500));

      await _analyticsService.stopHttpMetric(
        url,
        method,
        responseCode: 200,
        requestPayloadSize: 0,
        responsePayloadSize: 1024,
      );

      _showSnackBar('HTTP metric test completed successfully');
    } catch (e) {
      _showSnackBar('Error testing HTTP metric: $e');
    }
  }

  Future<void> _testCustomEvent() async {
    try {
      await _analyticsService.logEvent(
        'test_custom_event',
        parameters: {
          'source': 'analytics_monitor',
          'test_id': DateTime.now().millisecondsSinceEpoch.toString(),
          'user_action': 'manual_test',
        },
      );

      _showSnackBar('Custom event logged successfully');
    } catch (e) {
      _showSnackBar('Error logging custom event: $e');
    }
  }

  Future<void> _flushAnalytics() async {
    try {
      await _analyticsService.flushAnalytics();
      _showSnackBar('Analytics data flushed successfully');
    } catch (e) {
      _showSnackBar('Error flushing analytics: $e');
    }
  }

  Future<void> _exportAnalyticsData() async {
    try {
      final summary = _analyticsService.getAnalyticsSummary();
      final statistics = _analyticsService.getEventStatistics();

      final exportData = {
        'summary': summary,
        'statistics': statistics,
        'export_timestamp': DateTime.now().toIso8601String(),
      };

      await Clipboard.setData(ClipboardData(text: exportData.toString()));
      _showSnackBar('Analytics data copied to clipboard');
    } catch (e) {
      _showSnackBar('Error exporting analytics data: $e');
    }
  }

  Future<void> _testErrorReporting() async {
    try {
      // Report a test non-fatal error
      await _analyticsService.recordError(
        'Test error from Analytics Monitor',
        StackTrace.current,
        fatal: false,
      );

      _showSnackBar('Test error reported successfully');
    } catch (e) {
      _showSnackBar('Error reporting test error: $e');
    }
  }

  Future<void> _setTestUserProperties() async {
    try {
      await _analyticsService.setUserProperties(
        userId: 'test_user_${DateTime.now().millisecondsSinceEpoch}',
        userRole: 'doctor',
        userType: 'test',
        customProperties: {'test_mode': 'true', 'app_version': '1.0.0'},
      );

      _showSnackBar('Test user properties set successfully');
    } catch (e) {
      _showSnackBar('Error setting user properties: $e');
    }
  }

  void _showEventDetails(Map<String, dynamic> event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timestamp: ${event['timestamp']}'),
            const SizedBox(height: 8),
            if (event['parameters'] != null) ...[
              const Text('Parameters:'),
              const SizedBox(height: 4),
              Text(
                event['parameters'].toString(),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}
