import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'dart:async';

/// Global error handler for catching and reporting all Flutter errors
class GlobalErrorHandler {
  static void initialize() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      if (!kIsWeb) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      return true;
    };
  }

  /// Log non-fatal errors to Crashlytics
  static Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
    Map<String, dynamic>? context,
  }) async {
    try {
      if (context != null) {
        context.forEach((key, value) {
          FirebaseCrashlytics.instance.setCustomKey(key, value.toString());
        });
      }

      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace,
        reason: reason,
        fatal: false,
      );
    } catch (e) {
      debugPrint('Failed to log error to Crashlytics: $e');
    }
  }
}

/// Error boundary widget that catches errors in the widget tree
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget Function(FlutterErrorDetails)? errorBuilder;
  final void Function(FlutterErrorDetails)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorBuilder,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  FlutterErrorDetails? _errorDetails;

  @override
  Widget build(BuildContext context) {
    if (_errorDetails != null) {
      if (widget.errorBuilder != null) {
        return widget.errorBuilder!(_errorDetails!);
      }
      return _buildDefaultErrorWidget(_errorDetails!);
    }
    return widget.child;
  }

  Widget _buildDefaultErrorWidget(FlutterErrorDetails details) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('An error occurred'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'We\'re sorry for the inconvenience. The error has been reported to our team.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorDetails = null;
                });
              },
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Safe async operation wrapper with error handling
Future<T?> safeAsync<T>(
  Future<T> Function() operation, {
  String? errorMessage,
  T? defaultValue,
}) async {
  try {
    return await operation();
  } catch (error, stackTrace) {
    await GlobalErrorHandler.logError(
      error,
      stackTrace,
      reason: errorMessage ?? 'Async operation failed',
    );
    debugPrint('Error in safeAsync: $error');
    return defaultValue;
  }
}

/// Safe widget builder with error catching
Widget safeWidget(Widget Function() builder) {
  try {
    return builder();
  } catch (error, stackTrace) {
    GlobalErrorHandler.logError(error, stackTrace, reason: 'Widget build error');
    return const Center(
      child: Icon(Icons.error, color: Colors.red, size: 48),
    );
  }
}
