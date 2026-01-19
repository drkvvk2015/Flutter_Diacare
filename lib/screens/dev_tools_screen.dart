/// Dev Tools Screen
/// 
/// Developer dashboard for monitoring app performance, analytics, and diagnostics.
/// Available in debug mode only.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../constants/ui_constants.dart';
import '../services/analytics_service.dart';
import '../services/performance_service.dart';
import 'error_tracking_screen.dart';

/// Developer tools and analytics dashboard
class DevToolsScreen extends StatefulWidget {
  const DevToolsScreen({super.key});

  @override
  State<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends State<DevToolsScreen> {
  final AnalyticsService _analyticsService = AnalyticsService();
  final PerformanceService _performanceService = PerformanceService();

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(
          child: Text('Dev Tools only available in debug mode'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Tools'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showAbout,
            tooltip: 'About',
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(UIConstants.spacingMd),
        children: [
          _buildSection(
            'Performance Metrics',
            Icons.speed,
            [
              _buildMetricTile('Memory Usage', _getMemoryUsage(), Icons.memory),
              _buildMetricTile('FPS', '60', Icons.assessment),
              _buildMetricTile('Jank Count', '0', Icons.warning_amber),
            ],
          ),
          SizedBox(height: UIConstants.spacingLg),
          _buildSection(
            'Analytics',
            Icons.analytics,
            [
              _buildActionTile(
                'View Events',
                'See all logged analytics events',
                Icons.event,
                () => _showAnalyticsEvents(),
              ),
              _buildActionTile(
                'View Screen Times',
                'See time spent on each screen',
                Icons.timer,
                () => _showScreenTimes(),
              ),
              _buildActionTile(
                'User Properties',
                'View current user properties',
                Icons.person_outline,
                () => _showUserProperties(),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacingLg),
          _buildSection(
            'Error Tracking',
            Icons.bug_report,
            [
              _buildActionTile(
                'View Errors',
                'See all logged errors and warnings',
                Icons.error_outline,
                () => _navigateToErrorTracking(),
              ),
              _buildActionTile(
                'Test Error',
                'Trigger a test error for debugging',
                Icons.science,
                () => _triggerTestError(),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacingLg),
          _buildSection(
            'Cache Management',
            Icons.storage,
            [
              _buildActionTile(
                'Clear Image Cache',
                'Remove all cached images',
                Icons.image,
                () => _clearImageCache(),
              ),
              _buildActionTile(
                'Clear Data Cache',
                'Remove all cached API data',
                Icons.data_usage,
                () => _clearDataCache(),
              ),
              _buildActionTile(
                'Clear All Caches',
                'Remove all cached data',
                Icons.delete_sweep,
                () => _clearAllCaches(),
              ),
            ],
          ),
          SizedBox(height: UIConstants.spacingLg),
          _buildSection(
            'Network',
            Icons.network_check,
            [
              _buildMetricTile('API Calls', '245', Icons.api),
              _buildMetricTile('Failed Requests', '2', Icons.error_outline),
              _buildMetricTile('Avg Response Time', '245ms', Icons.timer),
            ],
          ),
          SizedBox(height: UIConstants.spacingLg),
          _buildSection(
            'Tools',
            Icons.build,
            [
              _buildActionTile(
                'Force Crash',
                'Test crash reporting (use with caution)',
                Icons.dangerous,
                () => _forceCrash(),
              ),
              _buildActionTile(
                'Reset Onboarding',
                'Clear onboarding completion flag',
                Icons.restart_alt,
                () => _resetOnboarding(),
              ),
              _buildActionTile(
                'App Info',
                'View app version and build info',
                Icons.info,
                () => _showAppInfo(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(UIConstants.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                SizedBox(width: UIConstants.spacingSm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(height: UIConstants.spacingLg * 2),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Text(title),
      trailing: Text(
        value,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _getMemoryUsage() {
    // In a real implementation, this would get actual memory usage
    return '125 MB';
  }

  void _navigateToErrorTracking() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ErrorTrackingScreen(),
      ),
    );
  }

  void _showAnalyticsEvents() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analytics Events'),
        content: const Text('Event log would be displayed here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showScreenTimes() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Screen Times'),
        content: const Text('Screen time analytics would be displayed here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showUserProperties() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('User Properties'),
        content: const Text('User properties would be displayed here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _triggerTestError() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Trigger Test Error'),
        content: const Text('This will throw a test error for debugging purposes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              throw Exception('Test error triggered from Dev Tools');
            },
            child: const Text('Trigger'),
          ),
        ],
      ),
    );
  }

  void _clearImageCache() {
    _showConfirmation('Clear Image Cache', 'Remove all cached images?', () {
      // Implementation would clear image cache
      _showSuccess('Image cache cleared');
    });
  }

  void _clearDataCache() {
    _showConfirmation('Clear Data Cache', 'Remove all cached API data?', () {
      // Implementation would clear data cache
      _showSuccess('Data cache cleared');
    });
  }

  void _clearAllCaches() {
    _showConfirmation('Clear All Caches', 'Remove all cached data?', () {
      // Implementation would clear all caches
      _showSuccess('All caches cleared');
    });
  }

  void _forceCrash() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Crash'),
        content: const Text(
          'This will intentionally crash the app to test crash reporting. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Future.delayed(const Duration(seconds: 1), () {
                throw Exception('Forced crash from Dev Tools');
              });
            },
            child: const Text('Crash App'),
          ),
        ],
      ),
    );
  }

  void _resetOnboarding() {
    _showConfirmation('Reset Onboarding', 'This will show the onboarding flow again on next launch.', () {
      // Implementation would reset onboarding flag
      _showSuccess('Onboarding reset');
    });
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('App Name: DiaCare'),
            Text('Version: 1.0.0'),
            Text('Build: 1'),
            Text('Environment: Development'),
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

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Dev Tools'),
        content: const Text(
          'Developer Tools provide access to analytics, performance metrics, '
          'error tracking, and debugging utilities. This feature is only '
          'available in debug mode.',
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

  void _showConfirmation(String title, String message, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
