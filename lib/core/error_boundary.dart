import 'dart:ui';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

import '../services/logger_service.dart';

final logger = LoggerService();

/// Global error boundary widget that catches and handles all unhandled errors
/// 
/// Wraps the entire application to provide centralized error handling,
/// crash reporting, and user-friendly error screens.
class ErrorBoundary extends StatefulWidget {

  const ErrorBoundary({
    required this.child, super.key,
    this.errorWidgetBuilder,
  });
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorWidgetBuilder;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  void initState() {
    super.initState();
    _setupErrorHandlers();
  }

  /// Reset error state and rebuild
  void _resetError() {
    setState(() {
      _errorDetails = null;
    });
  }

  /// Setup global error handlers for Flutter and Dart
  void _setupErrorHandlers() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _handleFlutterError(details);
    };

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _handleAsyncError(error, stack);
      return true;
    };
  }

  /// Handle Flutter framework errors
  void _handleFlutterError(FlutterErrorDetails details) {
    logger.error(
      'Flutter Error: ${details.exception}',
      error: details.exception,
      stackTrace: details.stack,
    );

    // Report to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);

    // Update UI to show error
    if (mounted) {
      setState(() {
        _errorDetails = details;
      });
    }
  }

  /// Handle async/Dart errors
  void _handleAsyncError(Object error, StackTrace stack) {
    logger.error(
      'Async Error: $error',
      error: error,
      stackTrace: stack,
    );

    // Report to Crashlytics
    FirebaseCrashlytics.instance.recordError(error, stack);

    // Store error for UI display
    setState(() {
      _errorDetails = FlutterErrorDetails(
        exception: error,
        stack: stack,
        context: ErrorDescription('Async error in error_boundary'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // If there's an error, show error UI
    if (_errorDetails != null) {
      return widget.errorWidgetBuilder?.call(_errorDetails!) ??
          _buildDefaultErrorWidget(_errorDetails!);
    }

    // Otherwise, show the normal app
    return widget.child;
  }

  /// Build default error widget
  Widget _buildDefaultErrorWidget(FlutterErrorDetails details) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade50,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade700,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Oops! Something went wrong',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'re sorry for the inconvenience. The error has been reported and we\'ll fix it soon.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _resetError,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (details.exception.toString().isNotEmpty)
                    ExpansionTile(
                      title: const Text('Error Details'),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey.shade200,
                          child: SelectableText(
                            details.exception.toString(),
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom error widget for production builds
class CustomErrorWidget extends StatelessWidget {

  const CustomErrorWidget({
    required this.errorDetails, super.key,
  });
  final FlutterErrorDetails errorDetails;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade100,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            const Text(
              'An error occurred',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorDetails.exceptionAsString(),
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper to setup error boundary in main.dart
/// 
/// Usage in main.dart:
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   
///   // Setup error boundary
///   await setupErrorBoundary();
///   
///   runApp(
///     ErrorBoundary(
///       child: MyApp(),
///     ),
///   );
/// }
/// ```
Future<void> setupErrorBoundary() async {
  // Initialize Firebase Crashlytics
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  // Pass all uncaught errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Catch errors outside of Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

/// Retry mechanism for failed operations
class RetryableOperation {
  static Future<T> execute<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 2),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    
    while (true) {
      try {
        attempts++;
        return await operation();
      } catch (e, stack) {
        final canRetry = shouldRetry?.call(e) ?? true;
        final hasRetriesLeft = attempts < maxRetries;

        if (!canRetry || !hasRetriesLeft) {
          logger.error(
            'Operation failed after $attempts attempts',
            error: e,
            stackTrace: stack,
          );
          rethrow;
        }

        logger.warning('Operation failed, retrying ($attempts/$maxRetries)');
        await Future<void>.delayed(retryDelay * attempts); // Exponential backoff
      }
    }
  }
}
