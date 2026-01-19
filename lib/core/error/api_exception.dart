/// API Exception Classes
/// 
/// Defines custom exception types for API errors.
/// Provides structured error information for better error handling.

/// Base API exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(
    this.message, {
    this.statusCode,
    this.data,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException ($statusCode): $message';
    }
    return 'ApiException: $message';
  }

  /// Check if error is due to network connectivity
  bool get isNetworkError => statusCode == null;

  /// Check if error is due to authentication
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  /// Check if error is due to server issues
  bool get isServerError => statusCode != null && statusCode! >= 500;

  /// Check if error is due to client issues
  bool get isClientError => 
      statusCode != null && statusCode! >= 400 && statusCode! < 500;
}

/// Network connectivity exception
class NetworkException extends ApiException {
  NetworkException([String message = 'No internet connection'])
      : super(message);
}

/// Authentication exception
class AuthenticationException extends ApiException {
  AuthenticationException([String message = 'Authentication failed'])
      : super(message, statusCode: 401);
}

/// Authorization exception
class AuthorizationException extends ApiException {
  AuthorizationException([String message = 'Access denied'])
      : super(message, statusCode: 403);
}

/// Not found exception
class NotFoundException extends ApiException {
  NotFoundException([String message = 'Resource not found'])
      : super(message, statusCode: 404);
}

/// Server exception
class ServerException extends ApiException {
  ServerException([String message = 'Server error occurred'])
      : super(message, statusCode: 500);
}

/// Validation exception
class ValidationException extends ApiException {
  final Map<String, List<String>>? errors;

  ValidationException(
    String message, {
    this.errors,
  }) : super(message, statusCode: 422);

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorMessages = errors!.entries
          .map((e) => '${e.key}: ${e.value.join(", ")}')
          .join('\n');
      return 'ValidationException: $message\n$errorMessages';
    }
    return super.toString();
  }
}
