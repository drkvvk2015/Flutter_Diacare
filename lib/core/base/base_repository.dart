/// Base Repository
/// 
/// Abstract base class for all repositories in the application.
/// Provides common error handling and data transformation logic.
library;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../constants/error_messages.dart';
import '../../services/logger_service.dart';

/// Base Repository class
abstract class BaseRepository {
  final LoggerService _logger = LoggerService();

  /// Execute operation with error handling
  Future<T> execute<T>({
    required Future<T> Function() operation,
    String? errorMessage,
    bool reportError = true,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      _handleError(e, stackTrace, errorMessage, reportError);
      rethrow;
    }
  }

  /// Execute operation with result wrapper
  Future<Result<T>> executeWithResult<T>({
    required Future<T> Function() operation,
    String? errorMessage,
  }) async {
    try {
      final data = await operation();
      return Result.success(data);
    } catch (e, stackTrace) {
      _handleError(e, stackTrace, errorMessage, true);
      return Result.failure(
        errorMessage ?? ErrorMessages.genericError,
        e,
      );
    }
  }

  /// Handle errors
  void _handleError(
    Object error,
    StackTrace stackTrace,
    String? message,
    bool reportError,
  ) {
    _logger.error(
      message ?? 'Repository error',
      error: error,
      stackTrace: stackTrace,
    );

    if (reportError) {
      try {
        FirebaseCrashlytics.instance.recordError(
          error,
          stackTrace,
          reason: message,
        );
      } catch (e) {
        // Firebase not initialized, skip crash reporting
      }
    }
  }
}

/// Result wrapper for repository operations
class Result<T> {

  Result._({
    required this.isSuccess, this.data,
    this.error,
    this.exception,
  });

  factory Result.success(T data) {
    return Result._(
      data: data,
      isSuccess: true,
    );
  }

  factory Result.failure(String error, [Object? exception]) {
    return Result._(
      error: error,
      exception: exception,
      isSuccess: false,
    );
  }
  final T? data;
  final String? error;
  final Object? exception;
  final bool isSuccess;

  /// Check if result is failure
  bool get isFailure => !isSuccess;
}
