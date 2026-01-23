import 'dart:async';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive analytics and monitoring service for Flutter Diacare app
/// Handles Firebase Analytics, Crashlytics, Performance monitoring, and custom metrics
class AnalyticsService {
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  static final AnalyticsService _instance = AnalyticsService._internal();

  // Firebase services
  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;
  late final FirebasePerformance _performance;

  // Custom metrics tracking
  final Map<String, int> _eventCounts = {};
  final Map<String, DateTime> _sessionEvents = {};
  final Map<String, Duration> _screenTimes = {};
  final List<Map<String, dynamic>> _customEvents = [];

  // Performance tracking
  final Map<String, Trace> _activeTraces = {};
  final Map<String, HttpMetric> _activeHttpMetrics = {};

  // User behavior tracking
  DateTime? _sessionStart;
  String? _currentScreen;
  DateTime? _currentScreenStart;

  // Initialization state
  bool _isInitialized = false;

  /// Initialize the analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;
      _crashlytics = FirebaseCrashlytics.instance;
      _performance = FirebasePerformance.instance;

      // Enable collection in release mode
      if (kReleaseMode) {
        await _crashlytics.setCrashlyticsCollectionEnabled(true);
        await _performance.setPerformanceCollectionEnabled(true);
      } else {
        // Enable for debugging in development
        await _crashlytics.setCrashlyticsCollectionEnabled(true);
        await _performance.setPerformanceCollectionEnabled(true);
      }

      // Set up Flutter error handling
      FlutterError.onError = (FlutterErrorDetails details) {
        _crashlytics.recordFlutterFatalError(details);
      };

      // Handle async errors
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };

      // Start session tracking
      _startSession();

      _isInitialized = true;
      _log('AnalyticsService initialized successfully');

      // Log initialization event
      await logEvent(
        'app_initialized',
        parameters: {
          'platform': Platform.operatingSystem,
          'debug_mode': kDebugMode,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      _log('Error initializing AnalyticsService: $e');
      await recordError(e, stackTrace);
    }
  }

  /// Start a new user session
  void _startSession() {
    _sessionStart = DateTime.now();
    _sessionEvents.clear();
    logEvent(
      'session_start',
      parameters: {'timestamp': _sessionStart!.toIso8601String()},
    );
  }

  /// Log a custom analytics event
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    if (!_isInitialized) return;

    try {
      // Convert parameters to Map<String, Object>? for Firebase Analytics
      Map<String, Object>? analyticsParameters;
      if (parameters != null) {
        analyticsParameters = <String, Object>{};
        parameters.forEach((key, value) {
          if (value != null) {
            analyticsParameters![key] = value as Object;
          }
        });
      }

      // Log to Firebase Analytics
      await _analytics.logEvent(name: name, parameters: analyticsParameters);

      // Track custom metrics
      _eventCounts[name] = (_eventCounts[name] ?? 0) + 1;
      _sessionEvents[name] = DateTime.now();

      // Store custom event
      _customEvents.add({
        'name': name,
        'parameters': parameters,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Limit custom events storage
      if (_customEvents.length > 100) {
        _customEvents.removeRange(0, _customEvents.length - 100);
      }

      _log(
        'Event logged: $name ${parameters != null ? 'with parameters' : ''}',
      );
    } catch (e, stackTrace) {
      _log('Error logging event $name: $e');
      await recordError(e, stackTrace);
    }
  }

  /// Log screen view
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    if (!_isInitialized) return;

    try {
      // End previous screen timing
      if (_currentScreen != null && _currentScreenStart != null) {
        final duration = DateTime.now().difference(_currentScreenStart!);
        _screenTimes[_currentScreen!] = duration;

        await logEvent(
          'screen_time',
          parameters: {
            'screen_name': _currentScreen,
            'duration_seconds': duration.inSeconds,
          },
        );
      }

      // Start new screen timing
      _currentScreen = screenName;
      _currentScreenStart = DateTime.now();

      // Log screen view to Firebase Analytics
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );

      await logEvent(
        'screen_view',
        parameters: {
          'screen_name': screenName,
          'screen_class': screenClass ?? screenName,
        },
      );
    } catch (e, stackTrace) {
      _log('Error logging screen view $screenName: $e');
      await recordError(e, stackTrace);
    }
  }

  /// Start performance trace
  Trace? startTrace(String name) {
    if (!_isInitialized) return null;

    try {
      final trace = _performance.newTrace(name);
      trace.start();
      _activeTraces[name] = trace;

      _log('Performance trace started: $name');
      return trace;
    } catch (e, stackTrace) {
      _log('Error starting trace $name: $e');
      recordError(e, stackTrace);
      return null;
    }
  }

  /// Stop performance trace
  Future<void> stopTrace(String name, {Map<String, String>? attributes}) async {
    if (!_isInitialized) return;

    try {
      final trace = _activeTraces.remove(name);
      if (trace != null) {
        if (attributes != null) {
          attributes.forEach(trace.putAttribute);
        }
        await trace.stop();
        _log('Performance trace stopped: $name');
      }
    } catch (e, stackTrace) {
      _log('Error stopping trace $name: $e');
      await recordError(e, stackTrace);
    }
  }

  /// Start HTTP metric
  HttpMetric? startHttpMetric(String url, String method) {
    if (!_isInitialized) return null;

    try {
      final httpMetric = _performance.newHttpMetric(
        url,
        HttpMethod.values.firstWhere(
          (m) => m.name.toUpperCase() == method.toUpperCase(),
          orElse: () => HttpMethod.Get,
        ),
      );

      final key = '${method.toUpperCase()}_$url';
      _activeHttpMetrics[key] = httpMetric;
      httpMetric.start();

      _log('HTTP metric started: $method $url');
      return httpMetric;
    } catch (e, stackTrace) {
      _log('Error starting HTTP metric: $e');
      recordError(e, stackTrace);
      return null;
    }
  }

  /// Stop HTTP metric
  Future<void> stopHttpMetric(
    String url,
    String method, {
    int? responseCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
  }) async {
    if (!_isInitialized) return;

    try {
      final key = '${method.toUpperCase()}_$url';
      final httpMetric = _activeHttpMetrics.remove(key);

      if (httpMetric != null) {
        if (responseCode != null) {
          httpMetric.httpResponseCode = responseCode;
        }
        if (requestPayloadSize != null) {
          httpMetric.requestPayloadSize = requestPayloadSize;
        }
        if (responsePayloadSize != null) {
          httpMetric.responsePayloadSize = responsePayloadSize;
        }

        await httpMetric.stop();
        _log(
          'HTTP metric stopped: $method $url (${responseCode ?? 'unknown'})',
        );
      }
    } catch (e, stackTrace) {
      _log('Error stopping HTTP metric: $e');
      await recordError(e, stackTrace);
    }
  }

  /// Record non-fatal error
  Future<void> recordError(
    dynamic error,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) async {
    if (!_isInitialized) return;

    try {
      await _crashlytics.recordError(error, stackTrace, fatal: fatal);
      _log('Error recorded: $error');

      // Also log as analytics event for non-fatal errors
      if (!fatal) {
        await logEvent(
          'non_fatal_error',
          parameters: {
            'error_type': error.runtimeType.toString(),
            'error_message': error.toString(),
          },
        );
      }
    } catch (e) {
      _log('Error recording error: $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperties({
    String? userId,
    String? userRole,
    String? userType,
    Map<String, String>? customProperties,
  }) async {
    if (!_isInitialized) return;

    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
        await _crashlytics.setUserIdentifier(userId);
      }

      if (userRole != null) {
        await _analytics.setUserProperty(name: 'user_role', value: userRole);
      }

      if (userType != null) {
        await _analytics.setUserProperty(name: 'user_type', value: userType);
      }

      if (customProperties != null) {
        for (final entry in customProperties.entries) {
          await _analytics.setUserProperty(name: entry.key, value: entry.value);
        }
      }

      _log('User properties set successfully');
    } catch (e, stackTrace) {
      _log('Error setting user properties: $e');
      await recordError(e, stackTrace);
    }
  }

  /// Log user action with context
  Future<void> logUserAction(
    String action, {
    Map<String, dynamic>? context,
  }) async {
    await logEvent(
      'user_action',
      parameters: {
        'action': action,
        'timestamp': DateTime.now().toIso8601String(),
        if (context != null) ...context,
      },
    );
  }

  /// Log app performance metrics
  Future<void> logPerformanceMetrics(Map<String, dynamic> metrics) async {
    await logEvent('performance_metrics', parameters: metrics);
  }

  /// Log business metrics (appointments, consultations, etc.)
  Future<void> logBusinessEvent(
    String eventType, {
    Map<String, dynamic>? data,
  }) async {
    await logEvent(
      'business_event',
      parameters: {
        'event_type': eventType,
        'timestamp': DateTime.now().toIso8601String(),
        if (data != null) ...data,
      },
    );
  }

  /// Get analytics summary
  Map<String, dynamic> getAnalyticsSummary() {
    final sessionDuration = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!)
        : Duration.zero;

    return {
      'session_duration_minutes': sessionDuration.inMinutes,
      'events_logged': _eventCounts.length,
      'total_event_count': _eventCounts.values.fold(0, (a, b) => a + b),
      'screens_viewed': _screenTimes.length,
      'custom_events_count': _customEvents.length,
      'active_traces': _activeTraces.length,
      'active_http_metrics': _activeHttpMetrics.length,
      'current_screen': _currentScreen,
    };
  }

  /// Get detailed event statistics
  Map<String, dynamic> getEventStatistics() {
    return {
      'event_counts': Map<String, int>.from(_eventCounts),
      'session_events': _sessionEvents.map(
        (k, v) => MapEntry(k, v.toIso8601String()),
      ),
      'screen_times': _screenTimes.map((k, v) => MapEntry(k, v.inSeconds)),
      'recent_events': _customEvents.take(10).toList(),
    };
  }

  /// Force send pending analytics data
  Future<void> flushAnalytics() async {
    if (!_isInitialized) return;

    try {
      // Firebase Analytics doesn't have a public flush method
      // But we can send a flush event to trigger sending
      await logEvent(
        'analytics_flush',
        parameters: {'timestamp': DateTime.now().toIso8601String()},
      );

      _log('Analytics data flushed');
    } catch (e, stackTrace) {
      _log('Error flushing analytics: $e');
      await recordError(e, stackTrace);
    }
  }

  /// Log session end
  Future<void> endSession() async {
    if (_sessionStart != null) {
      final duration = DateTime.now().difference(_sessionStart!);

      await logEvent(
        'session_end',
        parameters: {
          'session_duration_seconds': duration.inSeconds,
          'events_in_session': _sessionEvents.length,
          'screens_viewed': _screenTimes.length,
        },
      );

      // Log final screen time
      if (_currentScreen != null && _currentScreenStart != null) {
        final screenDuration = DateTime.now().difference(_currentScreenStart!);
        _screenTimes[_currentScreen!] = screenDuration;
      }
    }
  }

  /// Check if analytics is initialized
  bool get isInitialized => _isInitialized;

  /// Get current session duration
  Duration get sessionDuration {
    return _sessionStart != null
        ? DateTime.now().difference(_sessionStart!)
        : Duration.zero;
  }

  /// Clean up and dispose resources
  void dispose() {
    endSession();
    _activeTraces.clear();
    _activeHttpMetrics.clear();
    _customEvents.clear();
    _eventCounts.clear();
    _sessionEvents.clear();
    _screenTimes.clear();
  }

  /// Log debug messages
  void _log(String message) {
    if (kDebugMode) {
      print('[AnalyticsService] $message');
    }
  }
}

/// Extension for easy analytics tracking on Futures
extension AnalyticsFuture<T> on Future<T> {
  /// Track the performance of a Future operation with analytics
  Future<T> trackPerformance(
    String traceName, {
    Map<String, String>? attributes,
  }) async {
    final analyticsService = AnalyticsService();
    analyticsService.startTrace(traceName);

    try {
      final result = await this;
      await analyticsService.stopTrace(traceName, attributes: attributes);
      return result;
    } catch (e, stackTrace) {
      await analyticsService.stopTrace(
        traceName,
        attributes: {
          'error': 'true',
          'error_type': e.runtimeType.toString(),
          ...?attributes,
        },
      );
      await analyticsService.recordError(e, stackTrace);
      rethrow;
    }
  }
}
