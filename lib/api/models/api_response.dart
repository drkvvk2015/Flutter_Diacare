/// API Response Model
/// 
/// Generic response wrapper for API responses.
library;

/// Generic API response wrapper
class ApiResponse<T> {

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.metadata,
    this.error,
  });

  /// Create success response
  factory ApiResponse.success({
    required T data,
    String? message,
    Map<String, dynamic>? metadata,
  }) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      metadata: metadata,
    );
  }

  /// Create error response
  factory ApiResponse.error({
    required String message,
    String? code,
    Map<String, dynamic>? details,
  }) {
    return ApiResponse(
      success: false,
      error: ApiError(
        message: message,
        code: code,
        details: details,
      ),
    );
  }

  /// Create from JSON
  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJsonT,
  ) {
    final success = json['success'] as bool? ?? false;

    if (success) {
      return ApiResponse(
        success: true,
        message: json['message'] as String?,
        data: fromJsonT != null ? fromJsonT(json['data']) : json['data'] as T?,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );
    } else {
      return ApiResponse(
        success: false,
        error: ApiError.fromJson(json['error'] as Map<String, dynamic>? ?? {}),
      );
    }
  }
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? metadata;
  final ApiError? error;

  /// Convert to JSON
  Map<String, dynamic> toJson(Object Function(T)? toJsonT) {
    return {
      'success': success,
      if (message != null) 'message': message,
      if (data != null)
        'data': toJsonT != null ? toJsonT(data as T) : data,
      if (metadata != null) 'metadata': metadata,
      if (error != null) 'error': error!.toJson(),
    };
  }
}

/// API error model
class ApiError {

  ApiError({
    required this.message,
    this.code,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      message: json['message'] as String? ?? 'Unknown error',
      code: json['code'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      if (code != null) 'code': code,
      if (details != null) 'details': details,
    };
  }
}

/// Paginated response wrapper
class PaginatedResponse<T> {

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrevious,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    final itemsList = json['items'] as List;
    final total = json['total'] as int;
    final page = json['page'] as int;
    final pageSize = json['pageSize'] as int;
    final totalPages = (total / pageSize).ceil();

    return PaginatedResponse(
      items: itemsList.map((item) => fromJsonT(item)).toList(),
      total: total,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
      hasNext: page < totalPages,
      hasPrevious: page > 1,
    );
  }
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNext;
  final bool hasPrevious;

  Map<String, dynamic> toJson(Object Function(T) toJsonT) {
    return {
      'items': items.map((item) => toJsonT(item)).toList(),
      'total': total,
      'page': page,
      'pageSize': pageSize,
      'totalPages': totalPages,
      'hasNext': hasNext,
      'hasPrevious': hasPrevious,
    };
  }
}
