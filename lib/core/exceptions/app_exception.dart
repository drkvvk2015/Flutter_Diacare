/// Application Exceptions
/// 
/// Custom exception classes for the application.

/// Base application exception
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

/// Network-related exceptions
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.details});
}

/// Authentication exceptions
class AuthException extends AppException {
  AuthException(super.message, {super.code, super.details});
}

/// Validation exceptions
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  ValidationException(
    super.message, {
    super.code,
    super.details,
    this.fieldErrors,
  });
}

/// Server exceptions
class ServerException extends AppException {
  final int? statusCode;

  ServerException(
    super.message, {
    super.code,
    super.details,
    this.statusCode,
  });
}

/// Cache exceptions
class CacheException extends AppException {
  CacheException(super.message, {super.code, super.details});
}

/// Permission exceptions
class PermissionException extends AppException {
  PermissionException(super.message, {super.code, super.details});
}

/// Not found exceptions
class NotFoundException extends AppException {
  NotFoundException(super.message, {super.code, super.details});
}

/// Timeout exceptions
class TimeoutException extends AppException {
  TimeoutException(super.message, {super.code, super.details});
}

/// Unauthorized exceptions
class UnauthorizedException extends AppException {
  UnauthorizedException(super.message, {super.code, super.details});
}
