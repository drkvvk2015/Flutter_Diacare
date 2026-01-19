/// Error Tracking Screen
/// 
/// Displays application errors and diagnostics for debugging.
/// Available in debug mode only.

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../constants/ui_constants.dart';
import '../utils/logger.dart';

/// Error tracking and monitoring screen
class ErrorTrackingScreen extends StatefulWidget {
  const ErrorTrackingScreen({super.key});

  @override
  State<ErrorTrackingScreen> createState() => _ErrorTrackingScreenState();
}

class _ErrorTrackingScreenState extends State<ErrorTrackingScreen> {
  List<ErrorLog> _errors = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadErrors();
  }

  void _loadErrors() {
    // In a real implementation, this would load from a persistent store
    setState(() {
      _errors = ErrorLogger.instance.errors;
    });
  }

  List<ErrorLog> get _filteredErrors {
    if (_filter == 'all') return _errors;
    return _errors.where((e) => e.severity == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearErrors,
            tooltip: 'Clear all errors',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadErrors,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          _buildErrorStats(),
          Expanded(
            child: _buildErrorList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: EdgeInsets.all(UIConstants.spacingMd),
      child: Wrap(
        spacing: UIConstants.spacingSm,
        children: [
          FilterChip(
            label: Text('All (${_errors.length})'),
            selected: _filter == 'all',
            onSelected: (_) => setState(() => _filter = 'all'),
          ),
          FilterChip(
            label: Text('Errors (${_errors.where((e) => e.severity == 'error').length})'),
            selected: _filter == 'error',
            onSelected: (_) => setState(() => _filter = 'error'),
          ),
          FilterChip(
            label: Text('Warnings (${_errors.where((e) => e.severity == 'warning').length})'),
            selected: _filter == 'warning',
            onSelected: (_) => setState(() => _filter = 'warning'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStats() {
    final errorCount = _errors.where((e) => e.severity == 'error').length;
    final warningCount = _errors.where((e) => e.severity == 'warning').length;

    return Container(
      padding: EdgeInsets.all(UIConstants.spacingMd),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Total', _errors.length, Icons.error_outline),
          _buildStatCard('Errors', errorCount, Icons.error, Colors.red),
          _buildStatCard('Warnings', warningCount, Icons.warning, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color, size: UIConstants.iconSizeLg),
        SizedBox(height: UIConstants.spacingXs),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildErrorList() {
    if (_filteredErrors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: UIConstants.iconSize2Xl,
              color: Colors.green,
            ),
            SizedBox(height: UIConstants.spacingMd),
            Text(
              'No errors found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: UIConstants.spacingSm),
            Text(
              'The application is running smoothly',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(UIConstants.spacingMd),
      itemCount: _filteredErrors.length,
      itemBuilder: (context, index) {
        final error = _filteredErrors[index];
        return _buildErrorCard(error);
      },
    );
  }

  Widget _buildErrorCard(ErrorLog error) {
    final color = error.severity == 'error' ? Colors.red : Colors.orange;

    return Card(
      margin: EdgeInsets.only(bottom: UIConstants.spacingMd),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            error.severity == 'error' ? Icons.error : Icons.warning,
            color: color,
          ),
        ),
        title: Text(
          error.message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: UIConstants.spacingXs),
            Text(error.timestamp.toString()),
            if (error.stackTrace != null) ...[
              SizedBox(height: UIConstants.spacingXs),
              Text(
                'Has stack trace',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: UIConstants.fontSizeXs,
                ),
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _deleteError(error),
        ),
        onTap: () => _showErrorDetails(error),
      ),
    );
  }

  void _showErrorDetails(ErrorLog error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(error.severity.toUpperCase()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Message:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: UIConstants.spacingXs),
              Text(error.message),
              SizedBox(height: UIConstants.spacingMd),
              Text(
                'Time:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: UIConstants.spacingXs),
              Text(error.timestamp.toString()),
              if (error.stackTrace != null) ...[
                SizedBox(height: UIConstants.spacingMd),
                Text(
                  'Stack Trace:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: UIConstants.spacingXs),
                Container(
                  padding: EdgeInsets.all(UIConstants.spacingSm),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(UIConstants.radiusSm),
                  ),
                  child: Text(
                    error.stackTrace!,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: UIConstants.fontSizeXs,
                    ),
                  ),
                ),
              ],
            ],
          ),
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

  void _deleteError(ErrorLog error) {
    setState(() {
      _errors.remove(error);
      ErrorLogger.instance.removeError(error);
    });
  }

  void _clearErrors() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Errors'),
        content: const Text('Are you sure you want to clear all errors?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _errors.clear();
                ErrorLogger.instance.clearAll();
              });
              Navigator.of(context).pop();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

/// Error log model
class ErrorLog {
  final String message;
  final String severity;
  final DateTime timestamp;
  final String? stackTrace;

  ErrorLog({
    required this.message,
    required this.severity,
    required this.timestamp,
    this.stackTrace,
  });
}

/// Error logger singleton
class ErrorLogger {
  static final ErrorLogger instance = ErrorLogger._();
  ErrorLogger._();

  final List<ErrorLog> _errors = [];

  List<ErrorLog> get errors => List.unmodifiable(_errors);

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    if (!kDebugMode) return;

    final errorLog = ErrorLog(
      message: message,
      severity: 'error',
      timestamp: DateTime.now(),
      stackTrace: stackTrace?.toString() ?? error?.toString(),
    );

    _errors.insert(0, errorLog);

    // Keep only last 100 errors
    if (_errors.length > 100) {
      _errors.removeLast();
    }

    logError(message, error);
  }

  void logWarning(String message) {
    if (!kDebugMode) return;

    final errorLog = ErrorLog(
      message: message,
      severity: 'warning',
      timestamp: DateTime.now(),
    );

    _errors.insert(0, errorLog);

    // Keep only last 100 errors
    if (_errors.length > 100) {
      _errors.removeLast();
    }

    logWarning(message);
  }

  void removeError(ErrorLog error) {
    _errors.remove(error);
  }

  void clearAll() {
    _errors.clear();
  }
}
