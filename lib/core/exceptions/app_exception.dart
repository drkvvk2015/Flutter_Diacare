/// Application Exceptions
/// 
/// Custom exception classes for the application.
library;

/// Base application exception
abstract class AppException implements Exception {

  AppException(this.message, {this.code, this.details});
  final String message;
  final String? code;
  final dynamic details;

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

  ValidationException(
    super.message, {
    super.code,
    super.details,
    this.fieldErrors,
  });
  final Map<String, String>? fieldErrors;
}

/// Server exceptions
class ServerException extends AppException {

  ServerException(
    super.message, {
    super.code,
    super.details,
    this.statusCode,
  });
  final int? statusCode;
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
