/// Logger Service
/// 
/// Centralized logging service with multiple log levels.
/// Provides structured logging with timestamps and context.
library;

import 'dart:developer' as developer;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Log levels for categorizing log messages
enum LogLevel {
  /// Verbose/debug information
  debug,
  /// Informational messages
  info,
  /// Warning messages
  warning,
  /// Error messages
  error,
  /// Critical/fatal errors
  fatal,
}

/// Centralized logging service
class LoggerService {
  factory LoggerService() => _instance;
  LoggerService._internal();
  static final LoggerService _instance = LoggerService._internal();

  /// Current minimum log level (logs below this will be ignored)
  LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Set minimum log level
  void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Log a debug message
  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Log an info message
  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Log a warning message
  void warning(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
  }) {
    _log(LogLevel.warning, message, tag: tag, data: data, error: error);
  }

  /// Log an error message
  void error(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.error,
      message,
      tag: tag,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );

    // Report to Crashlytics in production
    if (!kDebugMode && error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
      );
    }
  }

  /// Log a fatal error message
  void fatal(
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      LogLevel.fatal,
      message,
      tag: tag,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );

    // Always report fatal errors to Crashlytics
    if (error != null) {
      FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: true,
      );
    }
  }

  /// Log API request
  void logApiRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? params,
  }) {
    debug(
      'API Request: $method $endpoint',
      tag: 'API',
      data: params,
    );
  }

  /// Log API response
  void logApiResponse({
    required String endpoint,
    required int statusCode,
    Map<String, dynamic>? data,
  }) {
    if (statusCode >= 200 && statusCode < 300) {
      debug(
        'API Response: $endpoint [$statusCode]',
        tag: 'API',
        data: data,
      );
    } else {
      warning(
        'API Response Error: $endpoint [$statusCode]',
        tag: 'API',
        data: data,
      );
    }
  }

  /// Log navigation
  void logNavigation(String from, String to) {
    debug(
      'Navigation: $from → $to',
      tag: 'Navigation',
    );
  }

  /// Log user action
  void logUserAction(String action, {Map<String, dynamic>? data}) {
    info(
      'User Action: $action',
      tag: 'UserAction',
      data: data,
    );
  }

  /// Log performance metric
  void logPerformance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? data,
  }) {
    info(
      'Performance: $operation took ${duration.inMilliseconds}ms',
      tag: 'Performance',
      data: data,
    );
  }

  /// Internal logging method
  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check if log level meets minimum requirement
    if (level.index < _minLevel.index) {
      return;
    }

    // Format the log message
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase();
    final tagStr = tag != null ? '[$tag] ' : '';
    final formattedMessage = '[$timestamp] $levelStr: $tagStr$message';

    // Add data if present
    String fullMessage = formattedMessage;
    if (data != null && data.isNotEmpty) {
      fullMessage += '\nData: $data';
    }
    if (error != null) {
      fullMessage += '\nError: $error';
    }
    if (stackTrace != null) {
      fullMessage += '\nStack: $stackTrace';
    }

    // Output based on platform and level
    if (kDebugMode) {
      // In debug mode, use developer.log for better IDE integration
      developer.log(
        fullMessage,
        name: tag ?? 'DiaCare',
        time: DateTime.now(),
        level: _getLevelValue(level),
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      // In production, only log warnings and above
      if (level.index >= LogLevel.warning.index) {
        debugPrint(fullMessage);
      }
    }

    // Log to custom analytics or remote logging service here
    _logToAnalytics(level, message, tag: tag, data: data);
  }

  /// Get numeric level value for developer.log
  int _getLevelValue(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }

  /// Log to analytics service
  void _logToAnalytics(
    LogLevel level,
    String message, {
    String? tag,
    Map<String, dynamic>? data,
  }) {
    // Only log warnings and above to analytics
    if (level.index >= LogLevel.warning.index) {
      // Integration with analytics service would go here
      // Example: AnalyticsService().logEvent(
      //   name: 'log_${level.name}',
      //   parameters: {
      //     'message': message,
      //     'tag': tag,
      //     ...?data,
      //   },
      // );
    }
  }

  /// Create a tagged logger instance
  TaggedLogger tag(String tag) {
    return TaggedLogger(tag, this);
  }
}

/// Tagged logger for scoped logging
class TaggedLogger {

  TaggedLogger(this._tag, this._logger);
  final String _tag;
  final LoggerService _logger;

  void debug(String message, {Map<String, dynamic>? data}) {
    _logger.debug(message, tag: _tag, data: data);
  }

  void info(String message, {Map<String, dynamic>? data}) {
    _logger.info(message, tag: _tag, data: data);
  }

  void warning(String message, {Map<String, dynamic>? data, Object? error}) {
    _logger.warning(message, tag: _tag, data: data, error: error);
  }

  void error(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.error(
      message,
      tag: _tag,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void fatal(
    String message, {
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.fatal(
      message,
      tag: _tag,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );
  }
}

/// Global logger instance
final logger = LoggerService();
