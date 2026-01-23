/// Performance Monitor
/// 
/// Wrappers for monitoring performance of operations, functions, and widgets.
/// Integrates with Firebase Performance Monitoring and custom logging.
library;

import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../services/logger_service.dart';

/// Performance monitoring wrapper for async operations
class PerformanceMonitor {
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();

  final FirebasePerformance _performance = FirebasePerformance.instance;
  final LoggerService _logger = LoggerService();

  /// Monitor an async operation
  Future<T> monitor<T>({
    required String name,
    required Future<T> Function() operation,
    Map<String, String>? attributes,
    bool logToConsole = true,
  }) async {
    final trace = _performance.newTrace(name);
    final stopwatch = Stopwatch()..start();

    // Add custom attributes
    if (attributes != null) {
      for (final entry in attributes.entries) {
        trace.putAttribute(entry.key, entry.value);
      }
    }

    await trace.start();

    try {
      final result = await operation();
      trace.putAttribute('success', 'true');
      return result;
    } catch (e) {
      trace.putAttribute('success', 'false');
      trace.putAttribute('error', e.toString());
      rethrow;
    } finally {
      stopwatch.stop();
      await trace.stop();

      if (logToConsole && kDebugMode) {
        _logger.logPerformance(name, stopwatch.elapsed, data: attributes);
      }
    }
  }

  /// Monitor a synchronous operation
  T monitorSync<T>({
    required String name,
    required T Function() operation,
    Map<String, String>? attributes,
    bool logToConsole = true,
  }) {
    final stopwatch = Stopwatch()..start();

    try {
      final result = operation();
      return result;
    } finally {
      stopwatch.stop();

      if (logToConsole && kDebugMode) {
        _logger.logPerformance(name, stopwatch.elapsed, data: attributes);
      }
    }
  }

  /// Monitor widget build performance
  void monitorBuild(String widgetName, Duration duration) {
    if (kDebugMode && duration.inMilliseconds > 16) {
      // Log slow builds (over 16ms = less than 60fps)
      _logger.warning(
        'Slow build detected: $widgetName took ${duration.inMilliseconds}ms',
        tag: 'Performance',
      );
    }
  }

  /// Start a custom trace
  Future<PerformanceTrace> startTrace(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    return PerformanceTrace(trace, name);
  }

  /// Monitor HTTP request
  HttpMetric startHttpMetric(String url, HttpMethod method) {
    return _performance.newHttpMetric(url, method);
  }
}

/// Wrapper for Firebase Performance Trace
class PerformanceTrace {

  PerformanceTrace(this._trace, this._name) {
    _stopwatch.start();
  }
  final Trace _trace;
  final String _name;
  final Stopwatch _stopwatch = Stopwatch();

  /// Add custom attribute
  void setAttribute(String key, String value) {
    _trace.putAttribute(key, value);
  }

  /// Increment metric
  void incrementMetric(String name, int value) {
    _trace.incrementMetric(name, value);
  }

  /// Stop the trace
  Future<void> stop() async {
    _stopwatch.stop();
    await _trace.stop();

    if (kDebugMode) {
      logger.logPerformance(_name, _stopwatch.elapsed);
    }
  }
}

/// Widget wrapper for monitoring widget performance
class PerformanceWidget extends StatelessWidget {

  const PerformanceWidget({
    required this.name,
    required this.child,
    this.enabled = kDebugMode,
    super.key,
  });
  final String name;
  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return _PerformanceTracker(
      name: name,
      child: child,
    );
  }
}

class _PerformanceTracker extends StatefulWidget {

  const _PerformanceTracker({
    required this.name,
    required this.child,
  });
  final String name;
  final Widget child;

  @override
  State<_PerformanceTracker> createState() => _PerformanceTrackerState();
}

class _PerformanceTrackerState extends State<_PerformanceTracker> {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _stopwatch.start();
  }

  @override
  void didUpdateWidget(_PerformanceTracker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _stopwatch.reset();
    _stopwatch.start();
  }

  @override
  Widget build(BuildContext context) {
    _stopwatch.stop();
    PerformanceMonitor().monitorBuild(widget.name, _stopwatch.elapsed);
    _stopwatch.reset();
    _stopwatch.start();

    return widget.child;
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }
}

/// Mixin for monitoring widget lifecycle performance
mixin PerformanceTrackerMixin<T extends StatefulWidget> on State<T> {
  final Stopwatch _buildStopwatch = Stopwatch();
  String get performanceName => T.toString();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      logger.debug('Widget initialized: $performanceName', tag: 'Lifecycle');
    }
  }

  @override
  Widget build(BuildContext context) {
    _buildStopwatch.start();
    final widget = buildWithTracking(context);
    _buildStopwatch.stop();

    if (kDebugMode && _buildStopwatch.elapsedMilliseconds > 16) {
      logger.warning(
        'Slow build: $performanceName took ${_buildStopwatch.elapsedMilliseconds}ms',
        tag: 'Performance',
      );
    }

    _buildStopwatch.reset();
    return widget;
  }

  /// Override this instead of build()
  Widget buildWithTracking(BuildContext context);

  @override
  void dispose() {
    if (kDebugMode) {
      logger.debug('Widget disposed: $performanceName', tag: 'Lifecycle');
    }
    super.dispose();
  }
}

/// Extension for monitoring futures
extension PerformanceMonitorExtension<T> on Future<T> {
  /// Monitor this future's execution time
  Future<T> withPerformanceMonitoring(String name) {
    return PerformanceMonitor().monitor(
      name: name,
      operation: () => this,
    );
  }
}

/// Global performance monitor instance
final performanceMonitor = PerformanceMonitor();
