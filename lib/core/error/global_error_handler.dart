/// Global Error Handler
/// 
/// Centralized error handling for the entire application.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../services/logger_service.dart';
import '../constants/error_messages.dart';
import '../core/exceptions/app_exception.dart';

/// Global error handler
class GlobalErrorHandler {
  static final GlobalErrorHandler _instance = GlobalErrorHandler._internal();
  factory GlobalErrorHandler() => _instance;
  GlobalErrorHandler._internal();

  final LoggerService _logger = LoggerService();

  /// Initialize error handling
  void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      _handleFlutterError(details);
    };

    // Catch errors outside Flutter framework (async errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      _handlePlatformError(error, stack);
      return true;
    };

    _logger.info('Global error handler initialized');
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    _logger.fatal(
      'Flutter Error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );

    FirebaseCrashlytics.instance.recordFlutterFatalError(details);

    // In debug mode, show the error on screen
    if (details.context != null) {
      FlutterError.dumpErrorToConsole(details);
    }
  }

  /// Handle platform errors
  void _handlePlatformError(Object error, StackTrace stackTrace) {
    _logger.fatal(
      'Platform Error: $error',
      error: error,
      stackTrace: stackTrace,
    );

    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: true,
    );
  }

  /// Handle and display error to user
  Future<void> handleError(
    BuildContext context,
    Object error, {
    StackTrace? stackTrace,
    bool showDialog = true,
  }) async {
    final errorMessage = _getErrorMessage(error);

    _logger.error(
      'Error handled: $errorMessage',
      error: error,
      stackTrace: stackTrace,
    );

    // Report non-fatal error
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      reason: errorMessage,
    );

    if (showDialog && context.mounted) {
      await _showErrorDialog(context, errorMessage);
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }

    if (error is NetworkException) {
      return ErrorMessages.networkNoConnection;
    }

    if (error is ServerException) {
      return ErrorMessages.getNetworkErrorMessage(
        error.statusCode ?? 500,
      );
    }

    if (error is AuthException) {
      return error.message;
    }

    if (error is ValidationException) {
      return error.message;
    }

    if (error is TimeoutException) {
      return ErrorMessages.networkTimeout;
    }

    if (error is UnauthorizedException) {
      return ErrorMessages.authSessionExpired;
    }

    // Default error message
    return ErrorMessages.genericError;
  }

  /// Show error dialog
  Future<void> _showErrorDialog(
    BuildContext context,
    String message,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Handle and retry operation
  Future<T?> handleWithRetry<T>({
    required Future<T> Function() operation,
    required BuildContext context,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    var retries = 0;

    while (retries < maxRetries) {
      try {
        return await operation();
      } catch (error, stackTrace) {
        retries++;

        if (retries >= maxRetries) {
          await handleError(context, error, stackTrace: stackTrace);
          return null;
        }

        _logger.warning(
          'Retry attempt $retries of $maxRetries',
          error: error,
        );

        await Future.delayed(retryDelay);
      }
    }

    return null;
  }
}

/// Mixin for error handling in widgets
mixin ErrorHandlerMixin<T extends StatefulWidget> on State<T> {
  final GlobalErrorHandler _errorHandler = GlobalErrorHandler();

  /// Handle error and show to user
  Future<void> handleError(
    Object error, {
    StackTrace? stackTrace,
    bool showDialog = true,
  }) async {
    if (mounted) {
      await _errorHandler.handleError(
        context,
        error,
        stackTrace: stackTrace,
        showDialog: showDialog,
      );
    }
  }

  /// Show error snackbar
  void showError(String message) {
    if (mounted) {
      _errorHandler.showErrorSnackBar(context, message);
    }
  }

  /// Show success snackbar
  void showSuccess(String message) {
    if (mounted) {
      _errorHandler.showSuccessSnackBar(context, message);
    }
  }

  /// Execute operation with error handling
  Future<T?> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? errorMessage,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      await handleError(error, stackTrace: stackTrace);
      return null;
    }
  }
}

/// Global error handler instance
final globalErrorHandler = GlobalErrorHandler();
