import 'package:flutter/foundation.dart';

/// Lightweight logging helper.
/// Usage: logInfo('message'), logError('oops', error, stackTrace)
/// In release mode (kReleaseMode) logs are suppressed by default.
void logInfo(String message) {
  if (kDebugMode) {
    debugPrint('[INFO] $message');
  }
}

void logWarn(String message) {
  if (kDebugMode) {
    debugPrint('[WARN] $message');
  }
}

void logError(String message, [Object? error, StackTrace? stackTrace]) {
  if (kDebugMode) {
    debugPrint('[ERROR] $message');
    if (error != null) {
      debugPrint('  error: $error');
    }
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}

/// Convenience timing helper.
T logTime<T>(String label, T Function() fn) {
  final start = DateTime.now();
  try {
    return fn();
  } finally {
    final ms = DateTime.now().difference(start).inMilliseconds;
    logInfo('$label took ${ms}ms');
  }
}
