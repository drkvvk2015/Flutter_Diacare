/// Error Recovery
/// 
/// Utilities for error recovery and retry logic.
library;

import 'dart:async';
import '../../services/logger_service.dart';

/// Error recovery strategy
enum RecoveryStrategy {
  /// Retry the operation
  retry,

  /// Use cached data
  useCache,

  /// Use default value
  useDefault,

  /// Fail and propagate error
  fail,
}

/// Error recovery manager
class ErrorRecovery {
  factory ErrorRecovery() => _instance;
  ErrorRecovery._internal();
  static final ErrorRecovery _instance = ErrorRecovery._internal();

  final LoggerService _logger = LoggerService();

  /// Execute with exponential backoff retry
  Future<T> executeWithBackoff<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(Object)? retryIf,
  }) async {
    var currentDelay = initialDelay;
    var attempt = 0;

    while (true) {
      try {
        attempt++;
        return await operation();
      } catch (error) {
        final shouldRetry = retryIf?.call(error) ?? true;

        if (attempt >= maxRetries || !shouldRetry) {
          _logger.error(
            'Max retries ($maxRetries) exceeded',
            error: error,
          );
          rethrow;
        }

        _logger.warning(
          'Retry attempt $attempt after ${currentDelay.inMilliseconds}ms',
          error: error,
        );

        await Future<void>.delayed(currentDelay);
        currentDelay *= backoffMultiplier;
      }
    }
  }

  /// Execute with circuit breaker
  Future<T> executeWithCircuitBreaker<T>({
    required Future<T> Function() operation,
    required String circuitName,
    int failureThreshold = 5,
    Duration resetTimeout = const Duration(minutes: 1),
  }) async {
    final breaker = _CircuitBreaker(
      name: circuitName,
      failureThreshold: failureThreshold,
      resetTimeout: resetTimeout,
    );

    return breaker.execute(operation);
  }

  /// Execute with timeout and fallback
  Future<T> executeWithTimeout<T>({
    required Future<T> Function() operation,
    required Duration timeout,
    T? fallbackValue,
    Future<T> Function()? fallbackOperation,
  }) async {
    try {
      return await operation().timeout(timeout);
    } on TimeoutException catch (e) {
      _logger.warning('Operation timed out after $timeout', error: e);

      if (fallbackOperation != null) {
        return fallbackOperation();
      }

      if (fallbackValue != null) {
        return fallbackValue;
      }

      rethrow;
    }
  }

  /// Execute with fallback chain
  Future<T> executeWithFallbacks<T>({
    required List<Future<T> Function()> operations,
    T? defaultValue,
  }) async {
    for (var i = 0; i < operations.length; i++) {
      try {
        return await operations[i]();
      } catch (error) {
        _logger.warning(
          'Operation $i failed, trying next fallback',
          error: error,
        );

        if (i == operations.length - 1) {
          if (defaultValue != null) {
            return defaultValue;
          }
          rethrow;
        }
      }
    }

    throw StateError('No fallback operations provided');
  }

  /// Graceful degradation
  Future<T?> executeGracefully<T>({
    required Future<T> Function() operation,
    T? fallbackValue,
    void Function(Object error)? onError,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      _logger.warning(
        'Operation failed gracefully',
        error: error,
        data: {'stackTrace': stackTrace.toString()},
      );

      onError?.call(error);
      return fallbackValue;
    }
  }
}

/// Circuit breaker implementation
class _CircuitBreaker {

  _CircuitBreaker({
    required this.name,
    required this.failureThreshold,
    required this.resetTimeout,
  });
  final String name;
  final int failureThreshold;
  final Duration resetTimeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  bool _isOpen = false;

  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_isOpen) {
      if (_shouldAttemptReset()) {
        _reset();
      } else {
        throw CircuitBreakerOpenException(
          'Circuit breaker "$name" is open',
        );
      }
    }

    try {
      final result = await operation();
      _onSuccess();
      return result;
    } catch (error) {
      _onFailure();
      rethrow;
    }
  }

  void _onSuccess() {
    _failureCount = 0;
    _lastFailureTime = null;
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _isOpen = true;
      logger.warning(
        'Circuit breaker "$name" opened after $failureThreshold failures',
      );
    }
  }

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;

    final timeSinceLastFailure =
        DateTime.now().difference(_lastFailureTime!);
    return timeSinceLastFailure >= resetTimeout;
  }

  void _reset() {
    _isOpen = false;
    _failureCount = 0;
    _lastFailureTime = null;
    logger.info('Circuit breaker "$name" reset');
  }
}

/// Circuit breaker open exception
class CircuitBreakerOpenException implements Exception {

  CircuitBreakerOpenException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Global error recovery instance
final errorRecovery = ErrorRecovery();
