/// API Exception Classes
/// 
/// Defines custom exception types for API errors.
/// Provides structured error information for better error handling.
library;

/// Base API exception class
class ApiException implements Exception {

  ApiException(
    this.message, {
    this.statusCode,
    this.data,
  });
  final String message;
  final int? statusCode;
  final dynamic data;

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
  NetworkException([super.message = 'No internet connection']);
}

/// Authentication exception
class AuthenticationException extends ApiException {
  AuthenticationException([super.message = 'Authentication failed'])
      : super(statusCode: 401);
}

/// Authorization exception
class AuthorizationException extends ApiException {
  AuthorizationException([super.message = 'Access denied'])
      : super(statusCode: 403);
}

/// Not found exception
class NotFoundException extends ApiException {
  NotFoundException([super.message = 'Resource not found'])
      : super(statusCode: 404);
}

/// Server exception
class ServerException extends ApiException {
  ServerException([super.message = 'Server error occurred'])
      : super(statusCode: 500);
}

/// Validation exception
class ValidationException extends ApiException {

  ValidationException(
    super.message, {
    this.errors,
  }) : super(statusCode: 422);
  final Map<String, List<String>>? errors;

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
